use strict;
use warnings;

use Test2::V0;
use Test2::Tools::QuickDB qw/get_db skipall_on_resource_error/;
use Test2::API qw/intercept/;

# get_db()/Pool builds turn a host that has run out of System V IPC (semaphore
# or shared-memory table exhaustion) into a skip_all rather than a failure --
# that is an environment limit, not a fault in this distribution. Any other
# error must still propagate.

imported_ok qw/skipall_on_resource_error/;

# A real PostgreSQL "out of semaphores" initdb failure, as captured into the
# run_command exception text on the failing CPAN smoke hosts.
my $sem_err = <<'ERR';
Failed to run command '/usr/local/bin/initdb -E UTF8 --no-locale -A trust -D /tmp/DB-QUICK-x/data' (256)
running bootstrap script ... FATAL:  could not create semaphores: No space left on device
DETAIL:  Failed system call was semget(104612, 17, 03600).
HINT:  ... the system limit for the maximum number of semaphore sets (SEMMNI), or the system wide maximum number of semaphores (SEMMNS), would be exceeded.
ERR

my $shm_err = "DETAIL:  Failed system call was shmget(key=5432001, size=56, 03600).\nFATAL: could not create shared memory segment";

subtest semaphore_error_skips => sub {
    my $events = intercept { skipall_on_resource_error($sem_err) };
    my ($plan) = grep { $_->isa('Test2::Event::Plan') } @$events;
    ok($plan, "emitted a plan");
    is($plan->facet_data->{plan}{skip}, 1, "it is a skip_all");
    like($plan->facet_data->{plan}{details}, qr/semaphore/i, "reason names semaphores");
};

subtest shared_memory_error_skips => sub {
    my $events = intercept { skipall_on_resource_error($shm_err) };
    my ($plan) = grep { $_->isa('Test2::Event::Plan') } @$events;
    ok($plan, "emitted a plan");
    is($plan->facet_data->{plan}{skip}, 1, "it is a skip_all");
    like($plan->facet_data->{plan}{details}, qr/shared memory/i, "reason names shared memory");
};

subtest unrelated_error_does_not_skip => sub {
    my $got = 1;
    my $events = intercept { $got = skipall_on_resource_error("some ordinary failure") };
    ok(!$got, "returns false for a non-resource error");
    ok(!(grep { $_->isa('Test2::Event::Plan') } @$events), "no skip plan emitted");
};

subtest get_db_rethrows_real_errors => sub {
    no warnings 'redefine';
    local *DBIx::QuickDB::build_db = sub { die "deliberate non-resource failure\n" };

    my $err;
    my $events = intercept { eval { get_db(); 1 } or $err = $@ };

    is($err, "deliberate non-resource failure\n", "get_db rethrows a non-resource error");
    ok(!(grep { $_->isa('Test2::Event::Plan') && $_->facet_data->{plan}{skip} } @$events),
        "get_db did not skip for an unrelated error");
};

subtest get_db_skips_on_resource_error => sub {
    no warnings 'redefine';
    local *DBIx::QuickDB::build_db = sub { die $sem_err };

    # Under intercept the skip plan is captured instead of terminating the
    # process, so control returns and get_db rethrows; we only assert the skip
    # plan was emitted (in real use that plan exits the test before the rethrow).
    my $events = intercept { eval { get_db() } };
    my ($plan) = grep { $_->isa('Test2::Event::Plan') && $_->facet_data->{plan}{skip} } @$events;
    ok($plan, "get_db emitted a skip_all on a semaphore-exhaustion build failure");
    like($plan->facet_data->{plan}{details}, qr/semaphore/i, "skip reason names semaphores");
};

done_testing;
