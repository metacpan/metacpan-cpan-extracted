use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );

use App::karr::Cmd::Init;
use App::karr::Cmd::Skill;

# Where `karr` gets the bundled skill file from, for both commands that need it.
#
# There are two places to look and they are tried in order: File::ShareDir,
# which is where share/claude-skill.md lands once the dist is installed, and --
# when it is not, i.e. a checkout being run with -Ilib -- share/ in that
# checkout. Both are exercised below, because the second one is the half that
# can fail invisibly: `karr skill show` would print a stale or missing file
# rather than say anything, and `karr init --claude-skill` would install one.
#
# Until ticket #146 this file pinned two names, App::karr::Cmd::Init's
# _find_skill_source and App::karr::Cmd::Skill's _skill_content, which were the
# same sub twice over: byte-identical apart from the $INC key each used to find
# its own source tree for the development fallback. They are one method on
# App::karr::Role::SkillFile now, next to the _write_skill that ticket #145
# collapsed the same way, and the anchor is the role's own file -- the one file
# of this dist that is certain to be loaded whenever either command asks.
# The tests still ask through both classes: one implementation is the claim
# being made, not a reason to stop checking that both commands get it.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# The anchor the development fallback climbs from. Named here on purpose: if it
# is ever renamed without the fallback being re-derived, this file says so
# instead of quietly testing a lookup nothing uses.
my $ANCHOR = 'App/karr/Role/SkillFile.pm';

# Non-ASCII on purpose: the skill file is Markdown prose full of em dashes, and
# both lookups must hand back characters (slurp_utf8), not octets -- t/65 pins
# what happens to them afterwards. Spelled with \x{} so this file needs no
# source encoding of its own.
my $SHARED_SKILL = "# karr \x{2014} from the installed share dir\n";
my $DEV_SKILL    = "# karr \x{2014} from the checkout\n\nBl\x{00f6}cke \x{2026}\n";

# A share dir as File::ShareDir would report one: a directory with the bundled
# file in it.
sub share_dir_holding {
    my ($content) = @_;
    my $dir = path( tempdir( CLEANUP => 1 ) );
    $dir->child('claude-skill.md')->spew_utf8($content) if defined $content;
    return $dir;
}

# A checkout that is not this one: the role's own file where the fallback
# expects it, and (optionally) a share/ next to lib/. Nothing is ever loaded
# out of it -- the fallback does path arithmetic on the anchor, so pointing
# %INC at that file is what moves the lookup into this tree.
sub checkout_holding {
    my ($content) = @_;
    my $root = path( tempdir( CLEANUP => 1 ) );
    $root->child( 'lib', $ANCHOR )->parent->mkpath;
    $root->child( 'lib', $ANCHOR )->spew_utf8("# located, never loaded\n");
    if ( defined $content ) {
        $root->child('share')->mkpath;
        $root->child('share/claude-skill.md')->spew_utf8($content);
    }
    return $root;
}

subtest 'both commands look the file up through one implementation' => sub {
    # The copy is what ticket #146 was about: the same lookup in two commands,
    # differing only in which $INC key it read. If someone re-inlines a private
    # one into either command, this fails.
    ok( App::karr::Cmd::Init->does('App::karr::Role::SkillFile'),
        'karr init composes the shared skill-file role' );
    ok( App::karr::Cmd::Skill->does('App::karr::Role::SkillFile'),
        'karr skill composes it too' );
    is( App::karr::Cmd::Init->can('_skill_content'),
        App::karr::Cmd::Skill->can('_skill_content'),
        'and both reach the same code, so the lookup cannot be fixed in one of them only' );

    ok( !App::karr::Cmd::Init->can('_find_skill_source'),
        'the second copy is gone rather than left behind as an alias' );

    ok( exists $INC{$ANCHOR},
        "the fallback's anchor, $ANCHOR, is a file that really is loaded" );
};

subtest 'installed dist: the content comes from File::ShareDir' => sub {
    my $dir = share_dir_holding($SHARED_SKILL);

    require File::ShareDir;
    no warnings 'redefine';
    local *File::ShareDir::dist_dir = sub { return "$dir" };

    is( App::karr::Cmd::Init->new->_skill_content, $SHARED_SKILL,
        'init reads skill content from the share dir' );
    is( App::karr::Cmd::Skill->new->_skill_content, $SHARED_SKILL,
        'skill command reads skill content from the share dir' );
};

subtest 'not installed: the content comes from the checkout the code was loaded from' => sub {
    my $checkout = checkout_holding($DEV_SKILL);

    require File::ShareDir;
    no warnings 'redefine';
    # What an uninstalled dist actually does: File::ShareDir finds no
    # auto/share/dist/App-karr anywhere in @INC and dies.
    local *File::ShareDir::dist_dir = sub { die "Failed to find share dir for dist 'App-karr'\n" };
    local $INC{$ANCHOR} = $checkout->child( 'lib', $ANCHOR )->stringify;

    # Equality here is also what pins the decode: $DEV_SKILL has an em dash in
    # it, so a fallback that slurped raw would come back three octets longer
    # and fail rather than quietly hand octets on to print.
    is( App::karr::Cmd::Init->new->_skill_content, $DEV_SKILL,
        'init falls back to share/claude-skill.md in that tree' );
    is( App::karr::Cmd::Skill->new->_skill_content, $DEV_SKILL,
        'and so does the skill command' );
};

subtest 'the same fallback when the share dir is there but the file is not' => sub {
    my $empty    = share_dir_holding(undef);
    my $checkout = checkout_holding($DEV_SKILL);

    require File::ShareDir;
    no warnings 'redefine';
    # The other way the first lookup comes up empty: dist_dir answers, but
    # nothing is in it. It must fall through rather than return nothing.
    local *File::ShareDir::dist_dir = sub { return "$empty" };
    local $INC{$ANCHOR} = $checkout->child( 'lib', $ANCHOR )->stringify;

    is( App::karr::Cmd::Init->new->_skill_content, $DEV_SKILL,
        'init falls through to the checkout' );
    is( App::karr::Cmd::Skill->new->_skill_content, $DEV_SKILL,
        'and so does the skill command' );
};

subtest 'neither: it says so instead of returning nothing' => sub {
    my $bare = checkout_holding(undef);

    require File::ShareDir;
    no warnings 'redefine';
    local *File::ShareDir::dist_dir = sub { die "Failed to find share dir for dist 'App-karr'\n" };
    local $INC{$ANCHOR} = $bare->child( 'lib', $ANCHOR )->stringify;

    for my $class (qw( App::karr::Cmd::Init App::karr::Cmd::Skill )) {
        my $content = eval { $class->new->_skill_content };
        is( $content, undef, "$class returns nothing usable" );
        like( $@, qr/Could not find claude-skill\.md/,
            "$class names the file it could not find" );
        unlike( $@, qr/ at \S+ line \d+/, "$class adds no source location" );
    }
};

# In-process, the fallback above runs against a %INC entry this file set. That
# proves the arithmetic; it does not prove the CLI ever reaches it. Below, both
# commands are run as `karr` really runs, against a File::ShareDir that cannot
# answer -- the situation of anyone working from a checkout without the dist
# installed -- and have to come back with this checkout's share file.
my $SHARE = path($ROOT)->child('share/claude-skill.md');

# A File::ShareDir that fails the way an uninstalled dist makes it fail, ahead
# of the real one in the child's @INC. Cheaper and far more reliable than
# arranging for App-karr not to be installed on the machine running the tests:
# here it usually is, which is exactly why this path needs forcing to be seen
# at all.
sub stub_sharedir_lib {
    my $lib = path( tempdir( CLEANUP => 1 ) );
    $lib->child('File')->mkpath;
    $lib->child('File/ShareDir.pm')->spew_utf8( <<'PERL' );
package File::ShareDir;
sub dist_dir { die "Failed to find share dir for dist 'App-karr'\n" }
1;
PERL
    return $lib;
}

# Raw bytes on both sides: the child writes UTF-8 to its stdout, the file holds
# UTF-8, and comparing them undecoded keeps this check about which file was
# found rather than about encoding (t/65 owns that).
sub run_karr {
    my ( $cwd, $lib, @args ) = @_;
    my $old_cwd = getcwd();
    chdir $cwd or die "chdir $cwd: $!";
    my $err_fh = gensym;
    my $pid = open3( my $in, my $out_fh, $err_fh,
        $^X, "-I$lib", "-I$ROOT/lib", $BIN, @args );
    close $in;
    binmode $out_fh;
    binmode $err_fh;
    my $out = do { local $/; <$out_fh> };
    my $err = do { local $/; <$err_fh> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    chdir $old_cwd or die "chdir $old_cwd: $!";
    return { stdout => $out, stderr => $err, exit => $exit };
}

subtest 'karr skill show through the real CLI, with nothing installed' => sub {
    plan skip_all => "$SHARE not found - not a source checkout"
        unless $SHARE->exists;

    # Run from somewhere else entirely: the fallback has to find the tree the
    # code was loaded from, not the directory the user happens to stand in.
    my $elsewhere = tempdir( CLEANUP => 1 );
    my $r = run_karr( $elsewhere, stub_sharedir_lib(), 'skill', 'show' );

    is( $r->{exit}, 0, 'it exits 0' ) or diag "stderr: $r->{stderr}";
    is( $r->{stdout}, $SHARE->slurp_raw,
        'and prints this checkout\'s share/claude-skill.md, byte for byte' );
};

subtest 'karr init --claude-skill through the real CLI, with nothing installed' => sub {
    plan skip_all => "$SHARE not found - not a source checkout"
        unless $SHARE->exists;

    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0
        or plan skip_all => 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );

    my $r = run_karr( $repo, stub_sharedir_lib(), 'init', '--claude-skill' );

    is( $r->{exit}, 0, 'it exits 0' ) or diag "stderr: $r->{stderr}";
    like( $r->{stdout}, qr/Installed Claude Code skill/, 'and reports the install' );

    my $installed = path($repo)->child('.claude/skills/karr/SKILL.md');
    ok( $installed->exists, 'the skill is there' ) or return;
    is( $installed->slurp_raw, $SHARE->slurp_raw,
        'and it is this checkout\'s share/claude-skill.md, byte for byte' );
};

done_testing;
