use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

use App::karr::Git;

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is($rc, 0, "@cmd");
}

sub _run_karr {
    my ( $cwd, $stdin, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3(
        my $stdin_fh,
        my $stdout_fh,
        $stderr,
        $^X,
        "-I$ROOT/lib",
        $BIN,
        @argv,
    );

    if ( defined $stdin ) {
        print {$stdin_fh} $stdin;
    }
    close $stdin_fh;

    my $stdout = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";
    return {
        exit   => $exit,
        stdout => defined $stdout ? $stdout : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
    return $repo;
}

sub _init_remote_pair {
    my $remote = tempdir( CLEANUP => 1 );
    my $local  = _init_repo();

    _git_ok( 'git', 'init', '--bare', '-q', $remote );
    _git_ok( 'git', '-C', $local, 'remote', 'add', 'origin', $remote );

    return ($local, $remote);
}

subtest 'destroy requires --yes' => sub {
    my $repo = _init_repo();
    is( _run_karr( $repo, undef, 'init', '--name', 'Destroy Board' )->{exit}, 0, 'board initialized' );

    my $rv = _run_karr( $repo, undef, 'destroy' );
    isnt( $rv->{exit}, 0, 'destroy without --yes fails' );
    like( $rv->{stderr}, qr/destructive/i, 'stderr warns about destructive destroy' );

    my $git = App::karr::Git->new( dir => $repo );
    ok( $git->ref_exists('refs/karr/config'), 'board refs remain after refused destroy' );
};

subtest 'destroy removes local and remote board refs' => sub {
    my ( $repo, $remote ) = _init_remote_pair();
    is( _run_karr( $repo, undef, 'init', '--name', 'Destroy Board' )->{exit}, 0, 'board initialized' );
    is( _run_karr( $repo, undef, 'create', 'First task' )->{exit}, 0, 'task created' );
    is( _run_karr( $repo, undef, 'sync' )->{exit}, 0, 'board synced to remote' );

    my $rv = _run_karr( $repo, undef, 'destroy', '--yes' );
    is( $rv->{exit}, 0, 'destroy succeeds with --yes' );
    like( $rv->{stderr}, qr/Deleted refs\/karr/, 'destroy reports success on stderr' );

    my $git = App::karr::Git->new( dir => $repo );
    is_deeply( [ $git->list_refs('refs/karr/') ], [], 'local board refs are gone' );

    my $remote_git = App::karr::Git->new( dir => $remote );
    is_deeply( [ $remote_git->list_refs('refs/karr/') ], [], 'remote board refs are pruned too' );
};

done_testing;
