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

# Ticket #31, Bug A: App::karr::Cmd::Sync::execute calls $git->pull and
# $git->push but ignores their return values and unconditionally prints
# "Done." with an implicit exit 0 — even when pull/push actually failed. This
# is the TDD red step: `karr sync` against a repo with a broken remote must
# exit 1, must NOT print "Done." on stdout, and must surface the failure on
# stderr.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

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

sub _git_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

# A git repo with an initialized board.
sub _board_repo {
    my $repo = _git_repo();
    is( _run_karr( $repo, 'init', '--name', 'Sync Error Board' )->{exit},
        0, 'setup: karr init exits 0' );
    return $repo;
}

subtest 'karr sync exits 1 and skips "Done." when pull/push fail' => sub {
    my $repo = _board_repo();

    # A remote that cannot possibly be reached, offline and deterministic.
    system( 'git', '-C', $repo, 'remote', 'add', 'origin', '/nonexistent/karr-bogus.git' );

    my $r = _run_karr( $repo, 'sync' );

    is( $r->{exit}, 1, 'karr sync fails with exit 1 on a broken remote' );
    unlike( $r->{stdout}, qr/Done\./, 'no "Done." on stdout when sync fails' );
    like( $r->{stderr}, qr/fail/i, 'the failure is surfaced on stderr' );
};

subtest 'karr sync with no remote configured is a no-op success' => sub {
    my $repo = _board_repo();

    my $r = _run_karr( $repo, 'sync' );

    is( $r->{exit}, 0, 'karr sync exits 0 when there is no remote to sync with' );
    like( $r->{stdout}, qr/Done\./, '"Done." appears on stdout' );
};

done_testing;
