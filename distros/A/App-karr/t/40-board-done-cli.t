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

# Ticket #10: `karr board` (and bare `karr`, which routes through
# App::karr::execute -> App::karr::Cmd::Board->new, App/karr.pm:230-237)
# should hide `done` tasks by default and reveal them with --done. This
# file exercises the real CLI/option-parsing layer (bin/karr as a
# subprocess) specifically to pin the bare-`karr --done` plumbing, which
# t/37-board-render.t cannot reach since it drives Cmd::Board directly.

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

sub _setup_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );

    my $init = _run_karr( $repo, 'init', '--name', 'CLI Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    for my $spec (
        [ 'Open work',    'todo' ],
        [ 'In flight',    'in-progress' ],
        [ 'Shipped thing', 'done' ],
    ) {
        my ( $title, $status ) = @$spec;
        my $rv = _run_karr( $repo, 'create', '--title', $title, '--status', $status );
        is( $rv->{exit}, 0, "karr create '$title' --status $status succeeds" ) or diag $rv->{stderr};
    }

    return $repo;
}

sub _assert_hides_done {
    my ( $rv, $label ) = @_;
    is( $rv->{exit}, 0, "$label exits successfully" ) or diag $rv->{stderr};
    unlike( $rv->{stdout}, qr/^## Done$/m,        "$label: Done section omitted by default" );
    unlike( $rv->{stdout}, qr/Shipped thing/,     "$label: done task title is hidden" );
    like( $rv->{stdout}, qr/^3 tasks \(1 done hidden\)/m,
        "$label: footer reports the hidden done count" );
}

sub _assert_shows_done {
    my ( $rv, $label ) = @_;
    is( $rv->{exit}, 0, "$label exits successfully" ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^## Done$/m,      "$label: Done section is rendered" );
    like( $rv->{stdout}, qr/Shipped thing/,   "$label: done task title is visible" );
    unlike( $rv->{stdout}, qr/done hidden/,   "$label: no hidden-count hint" );
}

subtest 'karr board hides done by default; karr board --done reveals it' => sub {
    my $repo = _setup_repo();
    _assert_hides_done( _run_karr( $repo, 'board' ),            'karr board' );
    _assert_shows_done( _run_karr( $repo, 'board', '--done' ),  'karr board --done' );
};

subtest 'bare karr matches karr board, including --done plumbing (App/karr.pm:230-237)' => sub {
    my $repo = _setup_repo();
    _assert_hides_done( _run_karr($repo),              'bare karr' );
    _assert_shows_done( _run_karr( $repo, '--done' ),  'bare karr --done' );
};

done_testing;
