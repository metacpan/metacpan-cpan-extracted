use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

# Loaded here, before anything below localizes $INC{$ANCHOR}: a key that is
# already in %INC is never loaded again, so localizing it for a role nobody
# had loaded yet would stop the role from ever compiling in this process.
use App::karr::Cmd::Init;
use App::karr::Cmd::Skill;
use File::ShareDir ();

# Ticket k316. `karr init --claude-skill` created .claude/skills/NAME/ before
# it asked App::karr::Role::SkillFile for the shipped files of NAME, one skill
# at a time, and all of that after the board refs were written. When the lookup
# failed -- an install whose share dir is missing, like the single binary
# before k308 packed share/ into it -- the user was left with an initialized
# board, an empty skill directory (or one skill written and the next one
# empty) and exit 1; and running the same command again, once the install was
# fixed, only said "Board already exists".
#
#   $ karr init --claude-skill      # share dir not found
#   Initialized karr board in refs/karr/
#   Added .gitignore entries for the file view: tasks/, config.yml
#   Could not find kanban-issues-karr-coordination/SKILL.md. Is App::karr properly installed?
#   $ ls .claude/skills
#   kanban-issues-karr-coordination        # empty
#
# Now every shipped file of every skill is resolved before init writes
# anything at all, so a failed lookup leaves the repository as it found it --
# no board refs, no .gitignore entries, no .claude -- with the same message
# and the same exit 1, and the retry works. `karr skill install` and `update`
# already resolved the whole set before their first write; the last subtests
# pin that, so it cannot regress into the ordering init had.
#
# Everything runs in File::Temp repositories and directories, against share
# dirs of this file's own making, never against the developer's tree or board.

my $ANCHOR = 'App/karr/Role/SkillFile.pm';
my @PAIR   = qw( kanban-issues-karr-coordination kanban-issues-karr-ticket );

my %SHIPPED = (
    'kanban-issues-karr-coordination' => {
        'SKILL.md'            => "---\nname: kanban-issues-karr-coordination\n---\n# board \x{2014} all of it\n",
        'references/cards.md' => "# cards \x{2026}\n",
    },
    'kanban-issues-karr-ticket' => {
        'SKILL.md' => "---\nname: kanban-issues-karr-ticket\n---\n# one card \x{2014} yours\n",
    },
);

# A checkout without share/: the development fallback climbs from the role's
# file in %INC to the tree around lib/ and finds nothing there.
my $BARE = path( tempdir( CLEANUP => 1 ) );

# Runs $code with the skill lookup answering only for @found: File::ShareDir
# reports a share dir holding just those skills (or fails outright when there
# are none), and the checkout fallback behind it has no share/ at all.
sub with_lookup {
    my ( $found, $code ) = @_;
    my $share = path( tempdir( CLEANUP => 1 ) );
    for my $name (@$found) {
        for my $rel ( sort keys %{ $SHIPPED{$name} } ) {
            my $file = $share->child( $name, $rel );
            $file->parent->mkpath;
            $file->spew_utf8( $SHIPPED{$name}{$rel} );
        }
    }

    no warnings 'redefine';
    local *File::ShareDir::dist_dir = @$found
        ? sub { "$share" }
        : sub { die "Failed to find share dir for dist 'App-karr'\n" };
    local $INC{$ANCHOR} = $BARE->child( 'lib', $ANCHOR )->stringify;
    return $code->();
}

sub new_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

sub board_refs {
    my ($repo) = @_;
    return grep { length } split /\n/,
        `git -C '$repo' for-each-ref --format='%(refname)' refs/karr/`;
}

sub children {
    my ($dir) = @_;
    return [] unless $dir->is_dir;
    return [ sort map { $_->basename } $dir->children ];
}

# The failure itself is what it always was: the lookup's own line, exit 1
# (a runtime failure, ADR 0002), and no karr source location.
sub failed_like {
    my ( $r, $missing, $label ) = @_;
    is( $r->{exit}, 1, "$label: exits 1" ) or diag "stderr: $r->{stderr}";
    like( $r->{stderr},
        qr{^Could not find \Q$missing\E/SKILL\.md\. Is App::karr properly installed\?$}m,
        "$label: names the skill it could not find" );
    unlike( $r->{stderr}, qr/ at \S+ line \d+/, "$label: no source location" );
}

subtest 'init --claude-skill with no skill to be found leaves the repository as it was' => sub {
    my $repo = new_repo();

    my $r = with_lookup( [], sub { run_karr( $repo, 'init', '--claude-skill' ) } );
    failed_like( $r, $PAIR[0], 'init' );

    ok( !path($repo)->child('.claude')->exists, 'no .claude was created' )
        or diag 'left behind: ' . join ', ', map { "$_" }
            path($repo)->child('.claude')->children;
    is_deeply( [ board_refs($repo) ], [], 'and no board refs were written' );
    ok( !path($repo)->child('.gitignore')->exists, 'nor any .gitignore entry' );
    unlike( $r->{stdout}, qr/Initialized/, 'so init does not claim a board it did not make' );

    # Nothing half-done is left to trip over: once the install can find its
    # skills, the very same command goes through.
    my $retry = with_lookup( \@PAIR, sub { run_karr( $repo, 'init', '--claude-skill' ) } );
    is( $retry->{exit}, 0, 'the retry succeeds' ) or diag "stderr: $retry->{stderr}";
    like( $retry->{stdout}, qr/Initialized karr board/, 'and initializes the board' );
    for my $name (@PAIR) {
        for my $rel ( sort keys %{ $SHIPPED{$name} } ) {
            my $file = path($repo)->child( '.claude/skills', $name, $rel );
            ok( $file->exists, "retry: $name/$rel was installed" ) or next;
            is( $file->slurp_utf8, $SHIPPED{$name}{$rel}, "retry: $name/$rel has the shipped content" );
        }
    }
};

subtest 'init --claude-skill with one skill found and the other not writes neither' => sub {
    my $repo = new_repo();

    my $r = with_lookup( [ $PAIR[0] ], sub { run_karr( $repo, 'init', '--claude-skill' ) } );
    failed_like( $r, $PAIR[1], 'init' );

    ok( !path($repo)->child('.claude')->exists,
        "no .claude was created -- not even $PAIR[0], which was found" )
        or diag 'left behind: ' . join ', ', @{ children( path($repo)->child('.claude/skills') ) };
    is_deeply( [ board_refs($repo) ], [], 'and no board refs were written' );
};

subtest 'init --claude-skill into an existing .claude/skills adds no directory to it' => sub {
    my $repo = new_repo();
    my $base = path($repo)->child('.claude/skills');
    $base->child('some-other-skill')->mkpath;
    $base->child('some-other-skill/SKILL.md')->spew_utf8("# not karr's\n");
    $base->child('kanban-issues-karr-cli')->mkpath;
    $base->child('kanban-issues-karr-cli/SKILL.md')->spew_utf8("# the retired skill\n");
    my $before = children($base);

    my $r = with_lookup( [], sub { run_karr( $repo, 'init', '--claude-skill' ) } );
    failed_like( $r, $PAIR[0], 'init' );

    is_deeply( children($base), $before,
        '.claude/skills holds what it held: no new skill directory, the retired one not removed' );
    is( $base->child('kanban-issues-karr-cli/SKILL.md')->slurp_utf8, "# the retired skill\n",
        'the retired skill is untouched' );
};

subtest 'karr skill install resolves every skill before it writes one' => sub {
    for my $found ( [], [ $PAIR[0] ] ) {
        my $label   = @$found ? 'one skill found' : 'none found';
        my $missing = @$found ? $PAIR[1] : $PAIR[0];
        my $dir     = path( tempdir( CLEANUP => 1 ) );

        my $r = with_lookup( $found,
            sub { run_karr( $dir, 'skill', 'install', '--agent', 'claude-code' ) } );
        failed_like( $r, $missing, "install, $label" );
        ok( !$dir->child('.claude')->exists, "install, $label: no .claude was created" )
            or diag 'left behind: ' . join ', ', @{ children( $dir->child('.claude/skills') ) };
    }
};

subtest 'karr skill update resolves every skill before it writes one' => sub {
    my $dir  = path( tempdir( CLEANUP => 1 ) );
    my $base = $dir->child('.claude/skills');
    $base->child('kanban-issues-karr-cli')->mkpath;
    $base->child('kanban-issues-karr-cli/SKILL.md')->spew_utf8("# the retired skill\n");

    my $r = with_lookup( [ $PAIR[0] ],
        sub { run_karr( $dir, 'skill', 'update', '--agent', 'claude-code' ) } );
    failed_like( $r, $PAIR[1], 'update' );
    is_deeply( children($base), ['kanban-issues-karr-cli'],
        'update wrote no skill directory and removed nothing' );
};

done_testing;
