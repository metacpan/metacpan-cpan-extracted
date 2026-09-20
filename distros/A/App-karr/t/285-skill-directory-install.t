use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );
use JSON::MaybeXS qw( decode_json );

# Ticket #285: the bundled skill is a directory, not a file.
#
# kanban-issues-karr-cli/SKILL.md had grown to 666 lines / 30 KB and was
# loaded whole on every trigger, so it was split: a short SKILL.md that names
# the everyday commands and a table of which references/*.md to read when,
# plus those references. share/claude-skill.md became
# share/kanban-issues-karr-cli/ with SKILL.md and references/*.md under it,
# and `karr skill install/check/update` and `karr init --claude-skill` have
# to ship the whole directory -- every file, each written in place (t/144 and
# t/146 own the inode property; this file owns the set).
#
# The contract pinned here, against a shipped set this file controls:
#   install  writes SKILL.md and every reference; "already installed" is
#            keyed on SKILL.md alone; --force rewrites everything; the
#            reported path is still the absolute SKILL.md.
#   check    is `outdated` (exit 1) when any shipped file is missing from the
#            target or differs from it; `not installed` when SKILL.md is
#            absent, whatever else is there.
#   update   rewrites exactly the missing/differing files, in place, and
#            leaves files the target has that are not shipped alone.
#   init --claude-skill writes the same set.
#
# Everything runs in File::Temp directories against a share dir of this
# file's own making (a -I ahead of @INC so File::ShareDir resolves to it,
# the t/65 trick), never against the developer's tree or the real share/.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# Non-ASCII on purpose: the round trip has to stay character-level in every
# file, not only SKILL.md. Spelled with \x{} so this file needs no source
# encoding.
my %SHIPPED = (
    'SKILL.md'              => "---\nname: kanban-issues-karr-cli\n---\n# karr \x{2014} entry point\n",
    'references/cards.md'   => "# cards \x{2014} Bl\x{00f6}cke\n",
    'references/queries.md' => "# queries \x{2026}\n",
);

# A lib dir whose auto/share/dist/App-karr/ holds the shipped set above, to go
# in front of @INC in every child below.
my $SHARE_LIB = path( tempdir( CLEANUP => 1 ) );
{
    my $share = $SHARE_LIB->child(qw( auto share dist App-karr kanban-issues-karr-cli ));
    for my $rel ( sort keys %SHIPPED ) {
        my $file = $share->child($rel);
        $file->parent->mkpath;
        $file->spew_utf8( $SHIPPED{$rel} );
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

sub ino { my @st = stat "$_[0]" or return; return $st[1] }

sub target_dir { path( $_[0] )->child('.claude/skills/kanban-issues-karr-cli') }

# Every shipped file is present under $dir with the shipped content.
sub is_installed_set {
    my ( $dir, $label ) = @_;
    for my $rel ( sort keys %SHIPPED ) {
        my $file = $dir->child($rel);
        ok( $file->exists, "$label: $rel is there" ) or next;
        is( $file->slurp_utf8, $SHIPPED{$rel}, "$label: $rel has the shipped content" );
    }
}

sub fresh_install {
    my $dir = tempdir( CLEANUP => 1 );
    my $r = run_karr( $dir, 'skill', 'install', '--agent', 'claude-code' );
    is( $r->{exit}, 0, 'install exits 0' ) or diag "stderr: $r->{stderr}";
    return $dir;
}

subtest 'install writes SKILL.md and every reference' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $r = run_karr( $dir, 'skill', 'install', '--agent', 'claude-code', '--json' );
    is( $r->{exit}, 0, 'install exits 0' ) or diag "stderr: $r->{stderr}";

    my $data = eval { decode_json( $r->{stdout} ) };
    ok( $data, 'and prints JSON' ) or diag "stdout: $r->{stdout}";
    is( $data->[0]{status}, 'installed', 'status is installed' );
    is( $data->[0]{path}, target_dir($dir)->child('SKILL.md')->stringify,
        'path is still the absolute SKILL.md, as before #285' );

    is_installed_set( target_dir($dir), 'install' );

    my $c = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 0, 'check exits 0 right after install' ) or diag "stderr: $c->{stderr}";
    like( $c->{stdout}, qr/current/, 'and says current' );

    my $again = run_karr( $dir, 'skill', 'install', '--agent', 'claude-code' );
    is( $again->{exit}, 0, 'a second install exits 0' );
    like( $again->{stdout}, qr/already installed/, 'and leaves an installed target alone' );
};

subtest 'check: a missing reference is outdated; update puts it back in place' => sub {
    my $dir       = fresh_install();
    my $target    = target_dir($dir);
    my $skill     = $target->child('SKILL.md');
    my $ref       = $target->child('references/queries.md');
    my $skill_ino = ino($skill);

    $ref->remove or die "remove $ref: $!";

    my $c = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 1, 'check exits 1 with one reference missing' ) or diag "stderr: $c->{stderr}";
    like( $c->{stdout}, qr/outdated/, 'and says outdated' );

    my $j = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code', '--json' );
    is( $j->{exit}, 1, '--json: same exit' );
    my $data = eval { decode_json( $j->{stdout} ) };
    is( $data->[0]{status}, 'outdated', '--json: status outdated' );

    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    is( $u->{exit}, 0, 'update exits 0' ) or diag "stderr: $u->{stderr}";
    like( $u->{stdout}, qr/updated/, 'and reports an update' );
    ok( $ref->exists, 'the reference is back' );
    is( $ref->slurp_utf8, $SHIPPED{'references/queries.md'}, 'with the shipped content' );
    is( ino($skill), $skill_ino, 'SKILL.md kept its inode' );
    is_installed_set( $target, 'after update' );

    $c = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 0, 'check is current again' );
};

subtest 'check: a differing reference is outdated; update rewrites it in place' => sub {
    my $dir     = fresh_install();
    my $target  = target_dir($dir);
    my $ref     = $target->child('references/cards.md');
    my $ref_ino = ino($ref);
    # Changed in place, so the inode compared against below is the one that
    # was there.
    $ref->append_utf8( { truncate => 1 }, "# stale \x{2014} an older release's copy\n" );

    my $c = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 1, 'check exits 1 with one reference differing' ) or diag "stderr: $c->{stderr}";
    like( $c->{stdout}, qr/outdated/, 'and says outdated' );

    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    is( $u->{exit}, 0, 'update exits 0' ) or diag "stderr: $u->{stderr}";
    like( $u->{stdout}, qr/updated/, 'and reports an update' );
    is( $ref->slurp_utf8, $SHIPPED{'references/cards.md'}, 'the reference carries the shipped content again' );
    is( ino($ref), $ref_ino, 'written through its existing inode' );

    $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    like( $u->{stdout}, qr/already current/, 'a second update has nothing to do' );
};

subtest 'a file in the target that is not shipped survives update' => sub {
    my $dir       = fresh_install();
    my $target    = target_dir($dir);
    my $stray_ref = $target->child('references/dropped.md');
    my $stray_txt = $target->child('notes.txt');
    $stray_ref->spew_utf8("# a reference a later release dropped\n");
    $stray_txt->spew_utf8("someone's notes\n");

    my $c = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 0, 'check ignores files that are not shipped' ) or diag "stderr: $c->{stderr}";
    like( $c->{stdout}, qr/current/, 'and says current' );

    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    like( $u->{stdout}, qr/already current/, 'update has nothing to do either' );
    ok( $stray_ref->exists, 'the stray reference is still there' );

    # And when there IS something to update, the strays still stay.
    $target->child('references/queries.md')->remove or die "remove: $!";
    $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    like( $u->{stdout}, qr/updated/, 'a real update happened' );
    is( $stray_ref->slurp_utf8, "# a reference a later release dropped\n", 'the stray reference is untouched' );
    is( $stray_txt->slurp_utf8, "someone's notes\n", 'and so is the stray text file' );
    is_installed_set( $target, 'after update' );
};

subtest 'not installed stays keyed on SKILL.md' => sub {
    my $dir    = tempdir( CLEANUP => 1 );
    my $target = target_dir($dir);
    # References without a SKILL.md: not an install, whatever is under it.
    $target->child('references')->mkpath;
    $target->child('references/cards.md')->spew_utf8( $SHIPPED{'references/cards.md'} );

    my $c = run_karr( $dir, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 0, 'check exits 0' ) or diag "stderr: $c->{stderr}";
    like( $c->{stdout}, qr/not installed/, 'and says not installed' );

    my $u = run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' );
    like( $u->{stdout}, qr/not installed/, 'update says the same' );
    ok( !$target->child('SKILL.md')->exists, 'and writes nothing' );

    my $i = run_karr( $dir, 'skill', 'install', '--agent', 'claude-code' );
    like( $i->{stdout}, qr/installed to/, 'install, without --force, installs' );
    is_installed_set( $target, 'install' );
};

subtest 'install --force rewrites everything; without it, nothing' => sub {
    my $dir       = fresh_install();
    my $target    = target_dir($dir);
    my $skill     = $target->child('SKILL.md');
    my $skill_ino = ino($skill);
    $skill->append_utf8( { truncate => 1 }, "# an old SKILL.md\n" );
    $target->child('references/cards.md')->remove or die "remove: $!";

    my $i = run_karr( $dir, 'skill', 'install', '--agent', 'claude-code' );
    like( $i->{stdout}, qr/already installed/, 'without --force: left alone' );
    is( $skill->slurp_utf8, "# an old SKILL.md\n", 'SKILL.md untouched' );
    ok( !$target->child('references/cards.md')->exists, 'the missing reference stays missing' );

    $i = run_karr( $dir, 'skill', 'install', '--force', '--agent', 'claude-code' );
    is( $i->{exit}, 0, '--force exits 0' ) or diag "stderr: $i->{stderr}";
    like( $i->{stdout}, qr/installed to/, 'and installs' );
    is_installed_set( $target, 'install --force' );
    is( ino($skill), $skill_ino, 'SKILL.md kept its inode' );
};

subtest 'init --claude-skill writes the references too' => sub {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0
        or plan skip_all => 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );

    my $r = run_karr( $repo, 'init', '--claude-skill' );
    is( $r->{exit}, 0, 'init --claude-skill exits 0' ) or diag "stderr: $r->{stderr}";
    my $skill = target_dir($repo)->child('SKILL.md');
    like( $r->{stdout}, qr/\QInstalled Claude Code skill to $skill\E/,
        'and still names the SKILL.md it wrote' );
    is_installed_set( target_dir($repo), 'init --claude-skill' );

    my $c = run_karr( $repo, 'skill', 'check', '--agent', 'claude-code' );
    is( $c->{exit}, 0, 'karr skill check agrees the install is current' ) or diag "stderr: $c->{stderr}";
};

done_testing;
