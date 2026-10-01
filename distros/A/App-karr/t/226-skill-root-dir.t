use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr ();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use JSON::MaybeXS qw( decode_json );

# Ticket #226: `karr --dir PATH skill install` accepted --dir, threw it away,
# and installed into the current directory instead -- reporting success with a
# relative path that names no tree at all. Measured before the fix, from skA
# with --dir pointing at skB (back when one skill, kanban-issues-karr-cli,
# shipped; the checks below look for the ticket skill of the pair that
# replaced it):
#
#   karr --dir .../skB skill install --agent claude-code
#   -> claude-code  installed to .claude/skills/kanban-issues-karr-cli/SKILL.md
#   (exit 0)
#   find skA skB -type f
#   -> .../skA/.claude/skills/kanban-issues-karr-cli/SKILL.md
#
# --dir is declared on App::karr::Role::BoardDiscovery, the root command
# composes it, MooX::Cmd parses the value and leaves it on the root instance in
# the command chain -- and App::karr::Cmd::Skill, which composes neither
# BoardDiscovery nor BoardAccess, never looked there. Unlike `dashboard`
# (#225), this one writes: a file landed in a repository the caller never
# named, and the message read like it had done what was asked.
#
# Refused rather than adopted, and the reason is the last subtest here:
# `skill`'s project-local target is the current directory, whether or not that
# directory is a repository at all -- it is the counterpart of --global's
# $HOME, not a board root. --dir means the seed of a search UPWARD for one
# repository's root (BoardDiscovery::_build_git_root), so honouring it would
# have meant either breaking every install outside a repository or giving the
# option a second, private meaning here. `karr init --claude-skill` writes the
# very same file through git_root and does honour --dir; that command needs a
# repository anyway, this one does not.
#
# Everything below runs inside File::Temp directories, with HOME redirected
# into one of them: `skill install` creates files, and none of them may ever
# land in the developer's own tree or home.

my $tmp  = path( tempdir( CLEANUP => 1 ) );
my $home = $tmp->child('home');
$home->mkpath;

# In-process runner (t/lib/TestKarr.pm), wrapped to keep this file's own env
# setup: HOME redirected so `skill install` never lands in the developer's
# real one, plus the two env vars every CLI test here has always pinned.
# KARR_TEST_SUBPROC=1 restores the old open3 path.
sub run_karr {
    my ( $cwd, @argv ) = @_;
    local $ENV{HOME}               = "$home";   # never the real one: this writes
    local $ENV{NO_COLOR}           = 1;
    local $ENV{KARR_NO_AUTO_FETCH} = 1;
    return TestKarr::run_karr( $cwd, @argv );
}

sub git_repo {
    my ($dir) = @_;
    $dir->mkpath;
    system( 'git', 'init', '-q', "$dir" ) == 0 or BAIL_OUT('git init failed');
    return $dir;
}

# Two repositories that cannot be mistaken for one another: the command runs
# from HERE and --dir points at THERE.
my $here  = git_repo( $tmp->child('skA') );
my $there = git_repo( $tmp->child('skB') );

sub skill_file {
    my ($tree) = @_;
    return $tree->child('.claude/skills/kanban-issues-karr-ticket/SKILL.md');
}

subtest 'the root placement is refused instead of writing into the wrong tree' => sub {
    my $r = run_karr( $here, '--dir', "$there",
                      'skill', 'install', '--agent', 'claude-code' );

    is $r->{exit}, 2, 'exit 2 -- a usage error, not a reported success (ADR 0002)'
        or diag "stderr: $r->{stderr}";
    like $r->{stderr}, qr/--dir/, 'the message names the option it refused';
    like $r->{stderr}, qr/karr skill install/,
        'and says how to install into another directory instead';
    is $r->{stdout}, '', 'nothing claiming an install happened';

    # The heart of #226: before the fix a file appeared in the tree the caller
    # was standing in, not the one they named -- and neither is right here.
    ok !skill_file($here)->exists,  'no skill was written into the current tree';
    ok !skill_file($there)->exists, 'and none into the tree --dir named either';
};

subtest 'every skill action refuses it the same way' => sub {
    for my $action (qw( install check update show )) {
        my $r = run_karr( $here, '--dir', "$there",
                          'skill', $action, '--agent', 'claude-code' );
        is $r->{exit}, 2, "skill $action: exit 2" or diag "stderr: $r->{stderr}";
        like $r->{stderr}, qr/--dir/, "skill $action: names the refused option";
        is $r->{stdout}, '', "skill $action: no answer on stdout";
    }

    # --global targets $HOME and never looks at a directory at all, so --dir is
    # just as meaningless there. One rule, both placements, every action.
    my $g = run_karr( $here, '--dir', "$there", 'skill', 'check', '--global',
                      '--agent', 'claude-code' );
    is $g->{exit}, 2, 'and with --global as well';

    ok !skill_file($here)->exists,  'still nothing written into the current tree';
    ok !skill_file($there)->exists, 'still nothing written into the named one';
};

subtest 'the placement behind the command stays an unknown option' => sub {
    # Never accepted, and this pins that the refusal above did not accidentally
    # turn it into a real option on the subcommand.
    my $r = run_karr( $here, 'skill', 'install',
                      '--dir', "$there", '--agent', 'claude-code' );
    is $r->{exit}, 2, 'exit 2, same as the root placement';
    like $r->{stderr}, qr/[Uu]nknown option/, 'rejected by MooX::Options itself';
    ok !skill_file($there)->exists, 'and nothing was written';
};

subtest 'the success message names the tree the file landed in' => sub {
    my $r = run_karr( $there, 'skill', 'install', '--agent', 'claude-code' );

    is $r->{exit}, 0, 'the ordinary install still works' or diag "stderr: $r->{stderr}";
    my $file = skill_file($there);
    ok $file->exists, 'the skill is installed under the current directory';

    # #226 point 3: `installed to .claude/skills/...` was true of every tree at
    # once, which is what made the wrong-tree install read like the right one.
    like $r->{stdout}, qr/\Qinstalled to $file\E/,
        'the message names the absolute path it wrote'
        or diag "stdout: $r->{stdout}";
    unlike $r->{stdout}, qr/^\S+\s+\S+\s+installed to \.claude/m,
        'not a relative path that fits every tree';

    # The same path is what --json hands the agents that parse it.
    my $j = run_karr( $there, 'skill', 'install', '--agent', 'claude-code', '--json' );
    is $j->{exit}, 0, '--json exits 0' or diag "stderr: $j->{stderr}";
    my $data = eval { decode_json( $j->{stdout} ) };
    ok $data, 'and prints JSON' or diag "stdout: $j->{stdout}";
    my ($entry) = grep { $_->{skill} eq 'kanban-issues-karr-ticket' } @{ $data || [] };
    is $entry->{path}, "$file", 'whose path field is absolute too';
};

subtest 'project-local means the current directory, repository or not' => sub {
    # Why --dir is refused rather than honoured: this command is board-less and
    # works where there is no repository to discover, so the seed of an upward
    # repository search cannot be its target. A later "fix" that routes the
    # project-local path through git_root breaks exactly this.
    my $plain = $tmp->child('no-repo');
    $plain->mkpath;
    my $r = run_karr( $plain, 'skill', 'install', '--agent', 'claude-code' );

    is $r->{exit}, 0, 'install outside any Git repository still succeeds'
        or diag "stderr: $r->{stderr}";
    ok skill_file($plain)->exists, 'and writes into the directory it was run from';
};

done_testing;
