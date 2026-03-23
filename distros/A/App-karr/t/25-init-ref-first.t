use strict;
use warnings;
use Test::More;
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
    is($rc, 0, "@cmd");
}

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3(
        undef,
        my $stdout_fh,
        $stderr,
        $^X,
        "-I$ROOT/lib",
        $BIN,
        @argv,
    );

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

subtest 'init fails outside git repositories' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $rv = _run_karr( $dir, 'init', '--name', 'No Git' );
    isnt( $rv->{exit}, 0, 'init fails outside git repos' );
    like( $rv->{stderr}, qr/git repository/i, 'stderr explains the git requirement' );
};

subtest 'init writes refs instead of creating karr/' => sub {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );

    my $rv = _run_karr( $repo, 'init', '--name', 'Ref Init' );
    is( $rv->{exit}, 0, 'init exits successfully in git repos' );
    like( $rv->{stdout}, qr/Initialized karr board/i, 'stdout reports successful init' );

    ok( !-d "$repo/karr", 'no persistent karr directory is created' );

    my $git = App::karr::Git->new( dir => $repo );
    my $config = Load( $git->read_ref('refs/karr/config') );
    is( $config->{board}{name}, 'Ref Init', 'board name is stored in refs' );
    is( $git->read_next_id_ref, 1, 'next-id metadata ref is initialized' );
};

done_testing;
