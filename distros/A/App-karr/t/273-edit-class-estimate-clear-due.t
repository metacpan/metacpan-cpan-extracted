use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

use App::karr::Git;
use App::karr::ActivityLog;

# Ticket #273: karr edit could not change --class or --estimate and had no
# --clear-due. karr create takes all three; the only way to clear a due date
# was to rewrite the card by hand (materialize, edit the file, import).
# kanban-md's edit has --class, --estimate and --clear-due (cmd/edit.go).
#
# The class matters most: karr pick orders candidates by class of service
# before priority (expedite > fixed-date > standard > intangible, k233), so a
# card that turns out to be an expedite after creation could not be promoted,
# and a fixed-date card whose date went away could not drop back.
#
# kanban-md additionally has --started/--clear-started and
# --completed/--clear-completed; those stay out of scope (ticket #273) -- they
# are lifecycle stamps karr maintains itself (Task/update_timestamps), and
# letting a caller hand-set them would fight the lifecycle rules.

# In-process runner (t/lib/TestKarr.pm): same ($cwd, @argv) signature and
# { exit, stdout, stderr } return as the open3 helper this file used to carry,
# dispatched through the shared App::karr::Dispatch path. KARR_TEST_SUBPROC=1
# restores the old open3 path.
sub _run_karr { return run_karr(@_) }

# Fresh isolated temp repo per subtest, never the developer's real board.
sub _setup_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
      or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
      or die 'git config';

    is( _run_karr( $repo, 'init', '--name', 'Edit Class Board' )->{exit}, 0,
        'setup: karr init exits 0' );
    is( _run_karr( $repo, 'create', '--title', 'Card A',
            '--class', 'standard', '--estimate', '1d', '--due', '2026-09-15' )->{exit}, 0,
        'setup: card 1 created with class, estimate and due' );

    return $repo;
}

sub _task {
    my ( $repo, $id ) = @_;
    return App::karr::Git->new( dir => $repo )->load_task_ref( $id // 1 );
}

# Count edit entries in the activity log. The seeded card's creation is the
# only entry before any test command runs, so any extra one is a write that
# landed -- the field change has to be logged like every other edit.
sub _edit_count {
    my ($repo) = @_;
    my $log = App::karr::ActivityLog->new(
        git  => App::karr::Git->new( dir => $repo ),
        role => 'user',
    );
    return scalar grep { $_->{action} eq 'edit' } $log->entries;
}

subtest 'edit --class promotes the card and is logged' => sub {
    my $repo = _setup_repo();
    my $before_logs = _edit_count($repo);

    my $rv = _run_karr( $repo, 'edit', 1, '--class', 'expedite' );
    is( $rv->{exit}, 0, 'edit --class expedite succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stdout}, qr/Updated task 1: Card A/, 'and reports the update' );

    is( _task($repo)->class, 'expedite',
        'and the class landed in the ref' );
    like( _run_karr( $repo, 'show', 1 )->{stdout}, qr/^Class:\s+expedite$/m,
        'and show prints the new class' );
    is( _edit_count($repo), $before_logs + 1,
        'and exactly one activity-log entry was appended (a real write)' );
};

subtest 'edit --class validates against the board classes, exit 2 (#273)' => sub {
    my $repo = _setup_repo();
    my $before_logs = _edit_count($repo);

    my $rv = _run_karr( $repo, 'edit', 1, '--class', 'bogus' );
    is( $rv->{exit}, 2, 'edit --class bogus exits 2 (usage error)' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/Usage error: invalid class "bogus"/,
        '...with the same message create gives' );
    like( $rv->{stderr}, qr/valid: expedite, fixed-date, standard, intangible/,
        '...naming the board classes' );
    unlike( $rv->{stdout}, qr/Updated task/, '...and reports no update' );

    is( _task($repo)->class, 'standard', 'the class was not changed' );
    is( _edit_count($repo), $before_logs,
        'and no activity-log entry was appended' );
};

subtest 'a batch edit with an invalid class is rejected before any id is touched' => sub {
    my $repo = _setup_repo();
    is( _run_karr( $repo, 'create', 'Card B' )->{exit}, 0, 'setup: card 2 created' );
    is( _run_karr( $repo, 'create', 'Card C' )->{exit}, 0, 'setup: card 3 created' );
    my $before_logs = _edit_count($repo);

    my $rv = _run_karr( $repo, 'edit', '1,2,3', '--class', 'bogus' );
    is( $rv->{exit}, 2, 'edit 1,2,3 --class bogus exits 2' )
        or diag $rv->{stdout} . $rv->{stderr};

    is( _task( $repo, 1 )->class, 'standard', 'card 1 untouched' );
    is( _task( $repo, 2 )->class, 'standard', 'card 2 untouched' );
    is( _task( $repo, 3 )->class, 'standard', 'card 3 untouched' );
    is( _edit_count($repo), $before_logs,
        'and no activity-log entry was appended' );
};

subtest 'edit --estimate replaces the estimate and is logged' => sub {
    my $repo = _setup_repo();
    my $before_logs = _edit_count($repo);

    my $rv = _run_karr( $repo, 'edit', 1, '--estimate', '3d' );
    is( $rv->{exit}, 0, 'edit --estimate 3d succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};

    is( _task($repo)->estimate, '3d', 'and the estimate landed in the ref' );
    like( _run_karr( $repo, 'show', 1 )->{stdout}, qr/^Estimate:\s+3d$/m,
        'and show prints the new estimate' );
    is( _edit_count($repo), $before_logs + 1,
        'and exactly one activity-log entry was appended' );
};

subtest 'edit --estimate 0 lands the literal "0" (#153 rule)' => sub {
    my $repo = _setup_repo();

    # The #78/#153 rule: a literal "0" is one character long and a meaningful
    # estimate, so the guard has to be `defined && length`, not truth.
    my $rv = _run_karr( $repo, 'edit', 1, '--estimate', '0' );
    is( $rv->{exit}, 0, 'edit --estimate 0 succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};

    is( _task($repo)->estimate, '0',
        'and the literal "0" landed as the estimate' );
};

subtest 'edit --clear-due removes the due date and is logged' => sub {
    my $repo = _setup_repo();
    my $before_logs = _edit_count($repo);
    ok( _task($repo)->has_due, 'setup: the card has a due date' );

    my $rv = _run_karr( $repo, 'edit', 1, '--clear-due' );
    is( $rv->{exit}, 0, 'edit --clear-due succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stdout}, qr/Updated task 1: Card A/, 'and reports the update' );

    my $task = _task($repo);
    ok( !$task->has_due, 'and the due date is gone from the ref' );
    unlike( _run_karr( $repo, 'show', 1 )->{stdout}, qr/^Due:/m,
        'and show no longer prints a due line' );
    is( _edit_count($repo), $before_logs + 1,
        'and exactly one activity-log entry was appended' );
};

subtest 'edit --due with --clear-due is a usage error, nothing written' => sub {
    my $repo = _setup_repo();
    my $before      = _task($repo);
    my $before_logs = _edit_count($repo);

    my $rv = _run_karr( $repo, 'edit', 1, '--due', '2026-10-01', '--clear-due' );
    is( $rv->{exit}, 2, '--due with --clear-due exits 2 (ADR 0002 usage error)' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/cannot use --due and --clear-due together/,
        '...and says which pair it refused' );
    unlike( $rv->{stdout}, qr/Updated task/, '...and reports no update' );

    my $after = _task($repo);
    is( $after->due, '2026-09-15', 'the due date is the one it had before' );
    is( $after->updated, $before->updated, 'and `updated` was not stamped' );
    is( _edit_count($repo), $before_logs,
        'and no activity-log entry was appended' );
};

subtest 'edit --clear-due alone is a change, not a usage error' => sub {
    my $repo = _setup_repo();

    # --clear-due carries no value, so it has to count as a field in its own
    # right -- `edit ID --clear-due` is how a due date is removed and must not
    # become "no changes specified" (the #231 guard).
    my $rv = _run_karr( $repo, 'edit', 1, '--clear-due' );
    is( $rv->{exit}, 0, 'edit --clear-due on its own is not a usage error' )
        or diag $rv->{stdout} . $rv->{stderr};
    ok( !_task($repo)->has_due, 'and the due date is gone' );
};

subtest 'the batch form edits every id and logs each one' => sub {
    my $repo = _setup_repo();
    is( _run_karr( $repo, 'create', 'Card B' )->{exit}, 0, 'setup: card 2 created' );
    is( _run_karr( $repo, 'create', 'Card C' )->{exit}, 0, 'setup: card 3 created' );
    my $before_logs = _edit_count($repo);

    my $rv = _run_karr( $repo, 'edit', '1,2,3', '--class', 'expedite' );
    is( $rv->{exit}, 0, 'edit 1,2,3 --class expedite succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stdout}, qr/Updated task 3: Card C/, 'and reports the last id' );

    is( _task( $repo, 1 )->class, 'expedite', 'card 1 promoted' );
    is( _task( $repo, 2 )->class, 'expedite', 'card 2 promoted' );
    is( _task( $repo, 3 )->class, 'expedite', 'card 3 promoted' );
    is( _edit_count($repo), $before_logs + 3,
        'and each of the three writes has its own activity-log entry' );
};

done_testing;
