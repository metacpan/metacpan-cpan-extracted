# ABSTRACT: karr must work inside git worktrees, not only in the main work-tree
#
# A git worktree shares the object database and refs with the main repo but
# lives in a different directory and uses a `.git` *file* (not directory)
# pointing at `.git/worktrees/<name>` inside the main repo. karr stores its
# state in `refs/karr/*` which are shared refs, so all operations should work
# transparently from inside a worktree.
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use YAML::XS qw( Load );

use App::karr::Git;

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is( $rc, 0, "@cmd" );
}

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid    = open3(
        undef,
        my $stdout_fh,
        $stderr,
        $^X,
        "-I$ROOT/lib",
        $BIN,
        @argv,
    );

    my $stdout      = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";
    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _setup_main_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', '-b', 'main', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );

    # Worktrees require at least one commit to branch from.
    open my $fh, '>', "$repo/README.md" or die "open: $!";
    print {$fh} "main\n";
    close $fh;
    _git_ok( 'git', '-C', $repo, 'add',    'README.md' );
    _git_ok( 'git', '-C', $repo, 'commit', '-q', '-m', 'initial' );
    return $repo;
}

subtest 'karr init works inside a worktree' => sub {
    my $main = _setup_main_repo();
    my $wt   = tempdir( CLEANUP => 1 );
    # Add a worktree on a new branch off main.
    _git_ok( 'git', '-C', $main, 'worktree', 'add', '-b', 'feature', $wt );

    # Sanity: .git in the worktree is a *file* pointing at gitdir.
    ok( -f "$wt/.git", '.git in worktree is a file, not a directory' );

    my $rv = _run_karr( $wt, 'init', '--name', 'Worktree Board' );
    is( $rv->{exit}, 0, 'init exits 0 inside worktree' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    like( $rv->{stdout}, qr/Initialized karr board/i, 'init reports success' );
};

subtest 'refs written in worktree are visible from main work-tree' => sub {
    my $main = _setup_main_repo();
    my $wt   = tempdir( CLEANUP => 1 );
    _git_ok( 'git', '-C', $main, 'worktree', 'add', '-b', 'feature', $wt );

    my $rv = _run_karr( $wt, 'init', '--name', 'Shared Refs' );
    is( $rv->{exit}, 0, 'init in worktree exits 0' )
        or diag "stderr: $rv->{stderr}";

    # Read the config ref from the *main* repo — refs/karr/* are shared.
    my $git_main = App::karr::Git->new( dir => $main );
    ok( $git_main->ref_exists('refs/karr/config'),
        'refs/karr/config visible from main repo' );

    my $config = Load( $git_main->read_ref('refs/karr/config') );
    is(
        $config->{board}{name}, 'Shared Refs',
        'config written from worktree is readable from main repo'
    );
};

subtest 'create + list work inside a worktree' => sub {
    my $main = _setup_main_repo();
    my $wt   = tempdir( CLEANUP => 1 );
    _git_ok( 'git', '-C', $main, 'worktree', 'add', '-b', 'feature', $wt );

    my $init = _run_karr( $wt, 'init', '--name', 'CRUD in WT' );
    is( $init->{exit}, 0, 'init OK' ) or diag $init->{stderr};

    my $create
        = _run_karr( $wt, 'create', 'Fix worktree bug', '--priority', 'high' );
    is( $create->{exit}, 0, 'create OK in worktree' )
        or diag "stderr: $create->{stderr}\nstdout: $create->{stdout}";

    my $list = _run_karr( $wt, 'list' );
    is( $list->{exit}, 0, 'list OK in worktree' )
        or diag "stderr: $list->{stderr}";
    like(
        $list->{stdout}, qr/Fix worktree bug/,
        'task created in worktree shows up in worktree list'
    );

    my $list_main = _run_karr( $main, 'list' );
    is( $list_main->{exit}, 0, 'list OK in main work-tree' )
        or diag "stderr: $list_main->{stderr}";
    like(
        $list_main->{stdout}, qr/Fix worktree bug/,
        'task created in worktree is visible from main work-tree (shared refs)'
    );
};

subtest 'create in main work-tree is visible from worktree' => sub {
    my $main = _setup_main_repo();

    my $init = _run_karr( $main, 'init', '--name', 'Main First' );
    is( $init->{exit}, 0, 'init in main OK' ) or diag $init->{stderr};
    my $create = _run_karr( $main, 'create', 'Task from main' );
    is( $create->{exit}, 0, 'create in main OK' ) or diag $create->{stderr};

    my $wt = tempdir( CLEANUP => 1 );
    _git_ok( 'git', '-C', $main, 'worktree', 'add', '-b', 'feature', $wt );

    my $list = _run_karr( $wt, 'list' );
    is( $list->{exit}, 0, 'list in worktree OK' )
        or diag "stderr: $list->{stderr}";
    like(
        $list->{stdout}, qr/Task from main/,
        'task created in main repo visible from worktree'
    );
};

subtest 'commands work in a subdirectory of a worktree' => sub {
    my $main = _setup_main_repo();
    my $wt   = tempdir( CLEANUP => 1 );
    _git_ok( 'git', '-C', $main, 'worktree', 'add', '-b', 'feature', $wt );

    mkdir "$wt/sub"      or die "mkdir: $!";
    mkdir "$wt/sub/deep" or die "mkdir: $!";

    my $init = _run_karr( "$wt/sub/deep", 'init', '--name', 'Sub Worktree' );
    is( $init->{exit}, 0, 'init OK in worktree subdir' )
        or diag "stderr: $init->{stderr}\nstdout: $init->{stdout}";

    my $list = _run_karr( "$wt/sub/deep", 'list' );
    is( $list->{exit}, 0, 'list OK in worktree subdir' )
        or diag "stderr: $list->{stderr}";
};

done_testing;
