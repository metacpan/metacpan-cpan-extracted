use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );
use JSON::MaybeXS qw( decode_json );

# The single bundled skill kanban-issues-karr-cli was split into
# kanban-issues-karr-coordination and kanban-issues-karr-ticket. A project that
# installed the old one still has .claude/skills/kanban-issues-karr-cli/, and
# left there it briefs an agent with the old text next to the new pair. So:
#
#   install  writes the pair and removes the retired directory, reported
#            `removed` (plain and --json, with the directory's path);
#   update   treats the retired directory as an install: writes the pair and
#            removes it -- `karr skill update` alone migrates an old install;
#   check    reports it `stale` and exits 1 (ADR 0002: the check ran and
#            found work for update -- a runtime answer, not a usage error),
#            and calls the missing pair members `outdated`, not `not installed`;
#   init --claude-skill removes it the way install does.
#
# Removal unlinks: a hardlinked file in the retired directory loses only this
# project's link, a symlinked directory loses the link and not its target.
#
# Everything runs in File::Temp directories against a share dir of this
# file's own making (a -I ahead of @INC so File::ShareDir resolves to it, the
# t/65 trick), never against the developer's tree, the real share/ or a board.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

my @PAIR    = qw( kanban-issues-karr-coordination kanban-issues-karr-ticket );
my $RETIRED = 'kanban-issues-karr-cli';

my %SHIPPED = (
    'kanban-issues-karr-coordination' => {
        'SKILL.md'            => "---\nname: kanban-issues-karr-coordination\n---\n# board \x{2014} all of it\n",
        'references/cards.md' => "# cards \x{2026}\n",
    },
    'kanban-issues-karr-ticket' => {
        'SKILL.md' => "---\nname: kanban-issues-karr-ticket\n---\n# one card \x{2014} yours\n",
    },
);

my $SHARE_LIB = path( tempdir( CLEANUP => 1 ) );
for my $name (@PAIR) {
    my $share = $SHARE_LIB->child( qw( auto share dist App-karr ), $name );
    for my $rel ( sort keys %{ $SHIPPED{$name} } ) {
        my $file = $share->child($rel);
        $file->parent->mkpath;
        $file->spew_utf8( $SHIPPED{$name}{$rel} );
    }
}

sub run_karr {
    my ( $cwd, @args ) = @_;
    my $old_cwd = getcwd();
    chdir $cwd or die "chdir $cwd: $!";
    my $err_fh = gensym;
    my $pid = open3( my $in, my $out_fh, $err_fh,
        $^X, "-I$SHARE_LIB", "-I$ROOT/lib", $BIN, @args );
    close $in;
    my $out = do { local $/; <$out_fh> };
    my $err = do { local $/; <$err_fh> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    chdir $old_cwd or die "chdir $old_cwd: $!";
    return { exit => $exit, stdout => $out // '', stderr => $err // '' };
}

sub skills_base { path( $_[0] )->child('.claude/skills') }
sub retired_dir { skills_base( $_[0] )->child($RETIRED) }

# A target holding what an earlier release installed: the retired skill, with
# a reference under it, and nothing of the pair.
sub old_install {
    my $dir = path( tempdir( CLEANUP => 1 ) );
    my $old = retired_dir($dir);
    $old->child('references')->mkpath;
    $old->child('SKILL.md')->spew_utf8("---\nname: $RETIRED\n---\n# the old single skill\n");
    $old->child('references/cards.md')->spew_utf8("# old cards\n");
    return $dir;
}

sub pair_is_installed {
    my ( $dir, $label ) = @_;
    for my $name (@PAIR) {
        for my $rel ( sort keys %{ $SHIPPED{$name} } ) {
            my $file = skills_base($dir)->child( $name, $rel );
            ok( $file->exists, "$label: $name/$rel is there" ) or next;
            is( $file->slurp_utf8, $SHIPPED{$name}{$rel}, "$label: $name/$rel has the shipped content" );
        }
    }
}

sub by_skill {
    my ($data) = @_;
    return { map { ( $_->{skill} => $_ ) } @{ $data || [] } };
}

subtest 'check reports the retired directory as stale and exits 1' => sub {
    my $dir = old_install();

    my $c = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 1, 'check exits 1' ) or diag "stderr: $c->{stderr}";
    like( $c->{stdout}, qr/^claude-code\s+\Q$RETIRED\E\s+stale/m,
        'the retired skill is named and called stale' );
    like( $c->{stdout}, qr/\Q${\ retired_dir($dir) }\E/, 'with the directory it found' );
    like( $c->{stdout}, qr/karr skill update/, 'and what to run about it' );
    for my $name (@PAIR) {
        like( $c->{stdout}, qr/^claude-code\s+\Q$name\E\s+outdated$/m,
            "$name is outdated, not 'not installed': the target has the karr skill" );
    }

    my $j = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code', '--json' );
    is( $j->{exit}, 1, '--json: same exit' );
    my $data = eval { decode_json( $j->{stdout} ) };
    ok( $data, '--json: parses' ) or diag "stdout: $j->{stdout}";
    my $by = by_skill($data);
    is( $by->{$RETIRED}{status}, 'stale', '--json: the retired skill is stale' );
    is( $by->{$RETIRED}{path}, retired_dir($dir)->stringify, '--json: with its absolute path' );
    is( $by->{$RETIRED}{agent}, 'claude-code', '--json: and its agent' );
    is( $by->{$_}{status}, 'outdated', "--json: $_ outdated" ) for @PAIR;

    ok( retired_dir($dir)->child('SKILL.md')->exists, 'check removed nothing' );

    # Stale alone is enough: with the pair current, the leftover still fails.
    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    is( $u->{exit}, 0, 'update exits 0' ) or diag "stderr: $u->{stderr}";
    retired_dir($dir)->child('SKILL.md')->parent->mkpath;
    retired_dir($dir)->child('SKILL.md')->spew_utf8("# back again\n");
    $c = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 1, 'a current pair plus the leftover still exits 1' );
    like( $c->{stdout}, qr/^claude-code\s+\Q$_\E\s+current$/m, "$_ current" ) for @PAIR;
};

subtest 'update migrates an old install: writes the pair, removes the retired directory' => sub {
    my $dir = old_install();

    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code', '--json' );
    is( $u->{exit}, 0, 'update exits 0' ) or diag "stderr: $u->{stderr}";
    my $data = eval { decode_json( $u->{stdout} ) };
    ok( $data, 'and prints JSON' ) or diag "stdout: $u->{stdout}";
    my $by = by_skill($data);
    is( $by->{$RETIRED}{status}, 'removed', 'the retired skill is reported removed' );
    is( $by->{$RETIRED}{path}, retired_dir($dir)->stringify, 'with the directory it removed' );
    is( $by->{$_}{status}, 'updated', "$_ updated" ) for @PAIR;

    ok( !retired_dir($dir)->exists, 'the retired directory is gone' );
    pair_is_installed( $dir, 'update' );

    my $c = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 0, 'check is clean afterwards' ) or diag "stdout: $c->{stdout}";
    unlike( $c->{stdout}, qr/\Q$RETIRED\E/, 'and has nothing to say about the retired skill' );

    my $again = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    unlike( $again->{stdout}, qr/removed/, 'a second update removes nothing' );
    like( $again->{stdout}, qr/already current/, 'and finds the pair current' );
};

subtest 'update, plain output, names the removal' => sub {
    my $dir = old_install();
    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    is( $u->{exit}, 0, 'update exits 0' ) or diag "stderr: $u->{stderr}";
    like( $u->{stdout}, qr/^claude-code\s+\Q$RETIRED\E\s+removed \Q${\ retired_dir($dir) }\E/m,
        'one line: agent, retired skill, removed, the directory' );
};

subtest 'update leaves an agent with none of them alone' => sub {
    my $dir = path( tempdir( CLEANUP => 1 ) );
    skills_base($dir)->child('something-else')->mkpath;
    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    is( $u->{exit}, 0, 'update exits 0' );
    like( $u->{stdout}, qr/not installed/, 'not installed' );
    ok( !skills_base($dir)->child($_)->exists, "$_ was not written" ) for @PAIR;
    ok( skills_base($dir)->child('something-else')->exists, 'another skill is untouched' );
};

subtest 'install writes the pair and removes the retired directory' => sub {
    my $dir = old_install();

    my $i = run_karr( $dir, 'skill', 'install', '--agent', 'claude-code' );
    is( $i->{exit}, 0, 'install exits 0' ) or diag "stderr: $i->{stderr}";
    like( $i->{stdout}, qr/^claude-code\s+\Q$RETIRED\E\s+removed /m, 'and says it removed the retired skill' );
    ok( !retired_dir($dir)->exists, 'which is gone' );
    pair_is_installed( $dir, 'install' );

    # Pair already there, leftover back: install without --force leaves the
    # pair alone and still removes the leftover.
    retired_dir($dir)->mkpath;
    retired_dir($dir)->child('SKILL.md')->spew_utf8("# back again\n");
    my $j = run_karr( $dir, 'skill', 'install', '--agent', 'claude-code', '--json' );
    is( $j->{exit}, 0, 'a second install exits 0' ) or diag "stderr: $j->{stderr}";
    my $by = by_skill( eval { decode_json( $j->{stdout} ) } );
    is( $by->{$_}{status}, 'exists', "$_ exists" ) for @PAIR;
    is( $by->{$RETIRED}{status}, 'removed', 'the leftover is removed all the same' );
    is( $by->{$RETIRED}{path}, retired_dir($dir)->stringify, 'reported with its path' );
    ok( !retired_dir($dir)->exists, 'and gone' );
};

subtest 'a hardlinked retired skill loses only this link' => sub {
    my $dir   = old_install();
    my $old   = retired_dir($dir)->child('SKILL.md');
    my $other = path( tempdir( CLEANUP => 1 ) )->child('SKILL.md');
    plan skip_all => 'filesystem does not support hardlinks' unless link( "$old", "$other" );
    my $content = $other->slurp_utf8;

    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    is( $u->{exit}, 0, 'update exits 0' ) or diag "stderr: $u->{stderr}";
    ok( !retired_dir($dir)->exists, 'the retired directory is gone here' );
    ok( $other->exists, 'the other project still has its link' );
    is( $other->slurp_utf8, $content, 'with the content it had' );
    is( ( stat "$other" )[3], 1, 'now the only link' );
};

subtest 'a symlinked retired directory is unlinked, not emptied' => sub {
    my $dir  = path( tempdir( CLEANUP => 1 ) );
    my $real = path( tempdir( CLEANUP => 1 ) )->child($RETIRED);
    $real->mkpath;
    $real->child('SKILL.md')->spew_utf8("# kept elsewhere\n");
    skills_base($dir)->mkpath;
    plan skip_all => 'no symlinks here'
        unless eval { symlink( "$real", retired_dir($dir)->stringify ) };

    my $i = run_karr( $dir, 'skill', 'install', '--agent', 'claude-code' );
    is( $i->{exit}, 0, 'install exits 0' ) or diag "stderr: $i->{stderr}";
    ok( !-l retired_dir($dir)->stringify, 'the symlink is gone' );
    is( $real->child('SKILL.md')->slurp_utf8, "# kept elsewhere\n", 'and what it pointed to is untouched' );
};

subtest 'a retired directory that cannot be removed is one clean error' => sub {
    plan skip_all => 'running as root: permissions are not enforced' if $> == 0;

    my $dir = old_install();
    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    is( $u->{exit}, 0, 'first, a normal migration' ) or diag "stderr: $u->{stderr}";

    # The pair is current and writable; only the directory holding the skills
    # refuses a removal.
    retired_dir($dir)->child('SKILL.md')->parent->mkpath;
    retired_dir($dir)->child('SKILL.md')->spew_utf8("# back again\n");
    chmod 0500, skills_base($dir)->stringify;
    my $r = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    chmod 0700, skills_base($dir)->stringify;

    is( $r->{exit}, 1, 'exit 1: a runtime failure (ADR 0002)' );
    like( $r->{stderr}, qr/^Could not remove \Q${\ retired_dir($dir) }\E/m, 'naming the directory' );
    unlike( $r->{stderr}, qr/ at \S+ line \d+/, 'with no source location' ) or diag $r->{stderr};
    my @lines = grep { length } split /\n/, $r->{stderr};
    is( scalar(@lines), 1, 'on one line' ) or diag $r->{stderr};
};

subtest 'init --claude-skill removes the retired directory like install' => sub {
    my $repo = old_install();
    system( 'git', 'init', '-q', "$repo" ) == 0
        or plan skip_all => 'git init failed';
    system( 'git', '-C', "$repo", 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', "$repo", 'config', 'user.name',  'Test User' );

    my $r = run_karr( $repo, 'init', '--new-board', '--claude-skill' );
    is( $r->{exit}, 0, 'init --claude-skill exits 0' ) or diag "stderr: $r->{stderr}";
    ok( !retired_dir($repo)->exists, 'the retired directory is gone' );
    like( $r->{stdout}, qr/\QRemoved retired Claude Code skill ${\ retired_dir($repo) }\E/,
        'and init says so' );
    pair_is_installed( $repo, 'init --claude-skill' );
};

done_testing;
