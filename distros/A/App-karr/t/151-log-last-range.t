use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use Cwd qw( abs_path getcwd );
use File::Temp qw( tempdir );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

# Regression tests for ticket #151 -- karr log --last 0 and --last -N were
# silently mishandled by a truthiness guard inside App::karr::Cmd::Log:
#   if ($self->last && @entries > $self->last)
# 0 is falsy, so the one option whose job is to bound the output removed the
# bound; a negative passed the guard and sliced an empty range, so the command
# reported an empty log with exit 0 -- indistinguishable from "the board has
# no activity". Same defect, same fix as ticket #76 (Show.pm:161-162,
# Context.pm:97-99), which has already been applied twice in this tree.
# ADR 0002 classifies an invalid option value as a usage error (2).

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

    binmode $stdout_fh;
    binmode $stderr;
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
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

sub _board_repo_with_log {
    my ($label) = @_;
    my $repo = _git_repo();
    is( _run_karr( $repo, 'init', '--name', "Board $label" )->{exit},
        0, "setup: karr init succeeds for board $label" );

    # Six entries is enough to make "--last 0" visibly wrong (unbounded dump)
    # and to keep the test identical in shape to the repro in #151.
    my @lines;
    for my $i ( 1 .. 6 ) {
        my $ts = sprintf '2026-01-01T00:0%d:00Z', $i;
        push @lines,
            qq({"ts":"$ts","agent":"fox-owl","action":"move","task_id":$i});
    }
    my $rc = system(
        $^X, "-I$ROOT/lib", '-e',
        'use App::karr::Git; '
            . 'my $g = App::karr::Git->new(dir => $ARGV[0]); '
            . '$g->write_ref("refs/karr/log/fox-owl", join("\n", @ARGV[1..$#ARGV])) '
            . 'or die "write_ref failed";',
        $repo, @lines,
    );
    is( $rc, 0, 'setup: wrote six log entries to refs/karr/log/fox-owl' );
    return $repo;
}

subtest 'log --last 0 is a usage error, not a silent bound removal' => sub {
    my $repo = _board_repo_with_log('Last0');

    my $rv = _run_karr( $repo, 'log', '--last', 0 );
    is( $rv->{exit}, 2, 'log --last 0 is a usage error (2), not an unbounded dump' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    is( $rv->{stdout}, '', 'log --last 0 prints no entries' );
    like( $rv->{stderr}, qr/--last/, 'log --last 0 names the offending option' );
};

subtest 'log --last -N is a usage error, not an empty log' => sub {
    my $repo = _board_repo_with_log('LastNeg');

    for my $bad ( -1, -3, -10 ) {
        my $rv = _run_karr( $repo, 'log', '--last', $bad );
        is( $rv->{exit}, 2, "log --last $bad is a usage error (2), not an empty log" )
            or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
        is( $rv->{stdout}, '',
            "log --last $bad prints no entries (no false \"No log entries.\")" );
        like( $rv->{stderr}, qr/--last/,
            "log --last $bad names the offending option" );
    }
};

subtest 'log --last 0 --json still exits 2' => sub {
    # --json must not turn a usage error into a silent success. The pre-fix
    # behaviour printed "[]" with exit 0 (ticket #151), so this pins the
    # ADR-0002 contract that --json is orthogonal to usage-error exit codes.
    my $repo = _board_repo_with_log('Last0Json');

    my $rv = _run_karr( $repo, 'log', '--last', 0, '--json' );
    is( $rv->{exit}, 2, 'log --last 0 --json still exits 2' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    is( $rv->{stdout}, '', 'log --last 0 --json prints no JSON array' );
    like( $rv->{stderr}, qr/--last/, 'names the offending option' );
};

subtest 'log --last 1 still works' => sub {
    # Pin that the range check did not break the normal path -- six entries,
    # --last 1, expect exactly one line.
    my $repo = _board_repo_with_log('Last1');

    my $rv = _run_karr( $repo, 'log', '--last', 1 );
    is( $rv->{exit}, 0, 'log --last 1 exits 0' ) or diag $rv->{stderr};
    my @lines = grep { /\S/ } split /\n/, $rv->{stdout};
    is( scalar @lines, 1, 'log --last 1 prints exactly one entry' );
};

done_testing;