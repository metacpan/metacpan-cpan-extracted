use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use Cwd qw( abs_path );
use File::Temp qw( tempdir );

# Regression tests for ticket #278 -- `karr log` had no way to ask for a
# period or a kind of action. `--since YYYY-MM-DD` keeps entries timestamped
# on or after the date (string comparison against the RFC3339 ts, matching
# kanban-md's entry.Timestamp.Before(opts.Since)); `--action KIND` keeps one
# action kind, validated against App::karr::ActivityLog/ACTIONS -- the same
# constant the writers' actions are checked against, so the vocabulary cannot
# drift. A bad --since or --action used to be answered with "No log entries."
# and exit 0, which reads as "no activity" when the truth is "no such
# date/action"; both are now usage errors (2, ADR 0002).

my $ROOT = abs_path('.');

sub _run_karr { return run_karr(@_) }

sub _git_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

# A board whose log holds entries across two dates and two action kinds:
#   move on 2026-01-01 (tasks 1, 2), create on 2026-01-02 (task 3),
#   move on 2026-01-03 (task 4).
sub _board_repo_with_log {
    my ($label) = @_;
    my $repo = _git_repo();
    is( _run_karr( $repo, 'init', '--name', "Board $label" )->{exit},
        0, "setup: karr init succeeds for board $label" );

    my @lines = (
        qq({"ts":"2026-01-01T10:00:00Z","agent":"fox-owl","action":"move","task_id":1}),
        qq({"ts":"2026-01-01T11:00:00Z","agent":"fox-owl","action":"move","task_id":2}),
        qq({"ts":"2026-01-02T10:00:00Z","agent":"fox-owl","action":"create","task_id":3}),
        qq({"ts":"2026-01-03T10:00:00Z","agent":"fox-owl","action":"move","task_id":4}),
    );
    my $rc = system(
        $^X, "-I$ROOT/lib", '-e',
        'use App::karr::Git; '
            . 'my $g = App::karr::Git->new(dir => $ARGV[0]); '
            . '$g->write_ref("refs/karr/log/fox-owl", join("\n", @ARGV[1..$#ARGV])) '
            . 'or die "write_ref failed";',
        $repo, @lines,
    );
    is( $rc, 0, 'setup: wrote four log entries to refs/karr/log/fox-owl' );
    return $repo;
}

subtest 'log --since keeps entries on or after the date' => sub {
    my $repo = _board_repo_with_log('Since');

    my $rv = _run_karr( $repo, 'log', '--since', '2026-01-02' );
    is( $rv->{exit}, 0, 'log --since 2026-01-02 exits 0' ) or diag $rv->{stderr};
    my @lines = grep { /\S/ } split /\n/, $rv->{stdout};
    is( scalar @lines, 2, 'log --since 2026-01-02 keeps the two later entries' );
    like( $rv->{stdout}, qr/2026-01-02/, 'keeps the entry from the --since day itself' );
    unlike( $rv->{stdout}, qr/2026-01-01/, 'drops the earlier entries' );
};

subtest 'log --since with a bad date is a usage error' => sub {
    my $repo = _board_repo_with_log('SinceBad');

    for my $bad ( 'bogus', '2026-02-30', '2026-1-1' ) {
        my $rv = _run_karr( $repo, 'log', '--since', $bad );
        is( $rv->{exit}, 2, "log --since $bad is a usage error (2), not an empty log" )
            or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
        is( $rv->{stdout}, '', "log --since $bad prints no entries" );
        like( $rv->{stderr}, qr/invalid --since date/,
            "log --since $bad names the offending option" );
    }
};

subtest 'log --action keeps one action kind' => sub {
    my $repo = _board_repo_with_log('Action');

    my $rv = _run_karr( $repo, 'log', '--action', 'create' );
    is( $rv->{exit}, 0, 'log --action create exits 0' ) or diag $rv->{stderr};
    my @lines = grep { /\S/ } split /\n/, $rv->{stdout};
    is( scalar @lines, 1, 'log --action create keeps the single create entry' );
    like( $rv->{stdout}, qr/create/, 'the kept entry is the create' );
    unlike( $rv->{stdout}, qr/move/, 'drops the move entries' );
};

subtest 'log --action with an unknown kind is a usage error listing the valid ones' => sub {
    my $repo = _board_repo_with_log('ActionBad');

    my $rv = _run_karr( $repo, 'log', '--action', 'bogus' );
    is( $rv->{exit}, 2, 'log --action bogus is a usage error (2), not an empty log' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    is( $rv->{stdout}, '', 'log --action bogus prints no entries' );
    like( $rv->{stderr}, qr/invalid --action "bogus"/,
        'log --action bogus names the offending value' );
    like( $rv->{stderr}, qr/valid: archive, create, delete, edit, handoff, move, needs, pick/,
        'log --action bogus lists the actions the log can actually hold' );
};

subtest 'log --since and --action combine' => sub {
    my $repo = _board_repo_with_log('Combined');

    my $rv = _run_karr( $repo, 'log', '--since', '2026-01-02', '--action', 'move' );
    is( $rv->{exit}, 0, 'log --since 2026-01-02 --action move exits 0' )
        or diag $rv->{stderr};
    my @lines = grep { /\S/ } split /\n/, $rv->{stdout};
    is( scalar @lines, 1, 'keeps only the move on or after the date' );
    like( $rv->{stdout}, qr/task#4/, 'the kept entry is task 4' );
};

subtest 'log --since --json still filters' => sub {
    my $repo = _board_repo_with_log('SinceJson');

    my $rv = _run_karr( $repo, 'log', '--since', '2026-01-03', '--json' );
    is( $rv->{exit}, 0, 'log --since 2026-01-03 --json exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/"task_id":4/, 'the JSON payload holds only task 4' );
    unlike( $rv->{stdout}, qr/"task_id":1/, 'the JSON payload drops task 1' );
};

done_testing;
