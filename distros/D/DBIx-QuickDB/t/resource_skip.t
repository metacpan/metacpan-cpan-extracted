use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use QDB::Installs qw/skip_remaining_on_resource_error is_resource_unavailable/;

use Test2::V0;
use Test2::Tools::QuickDB qw/get_db skipall_on_resource_error/;
use Test2::API qw/context intercept/;

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

my $shm_err = "DETAIL:  Failed system call was shmget(key=5432001, size=56, 03600).\nFATAL: could not create shared memory segment: No space left on device";

my $sem_permission_err = <<'ERR';
FATAL:  could not create semaphores: Permission denied
DETAIL:  Failed system call was semget(5432015, 17, 03600).
ERR

my $mariadb_sem_enospc = <<'ERR';
2026-08-01 12:00:00 0 [ERROR] InnoDB: semget(IPC_PRIVATE, 1, 0600) failed: errno: 28 No space left on device
2026-08-01 12:00:00 0 [ERROR] Plugin 'InnoDB' registration as a STORAGE ENGINE failed.
ERR

my $mariadb_sem_eacces = <<'ERR';
2026-08-01 12:00:00 0 [ERROR] InnoDB: semget(IPC_PRIVATE, 1, 0600) failed: errno: 13 Permission denied
2026-08-01 12:00:00 0 [ERROR] Plugin 'InnoDB' registration as a STORAGE ENGINE failed.
ERR

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

subtest actionable_semget_error_does_not_skip => sub {
    my $got = 1;
    my $events = intercept { $got = skipall_on_resource_error($sem_permission_err) };
    ok(!$got, 'does not classify a semget permission failure as resource exhaustion');
    ok(!(grep { $_->isa('Test2::Event::Plan') } @$events),
        'did not emit a skip plan for the actionable failure');
};

subtest mariadb_semget_enospc_skips => sub {
    my $events = intercept { skipall_on_resource_error($mariadb_sem_enospc) };
    my ($plan) = grep { $_->isa('Test2::Event::Plan') } @$events;
    ok($plan, 'MariaDB-shaped semget ENOSPC emitted a plan');
    is($plan->facet_data->{plan}{skip}, 1, 'MariaDB-shaped semget ENOSPC is a skip_all');
    like($plan->facet_data->{plan}{details}, qr/semaphore/i, 'reason names semaphores');
};

subtest mariadb_semget_eacces_does_not_skip => sub {
    my $got = 1;
    my $events = intercept { $got = skipall_on_resource_error($mariadb_sem_eacces) };
    ok(!$got, 'does not classify a MariaDB semget permission failure as resource exhaustion');
    ok(!(grep { $_->isa('Test2::Event::Plan') } @$events),
        'did not emit a skip plan for the MariaDB permission failure');
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

subtest partial_pool_body_records_skip_and_sentinel => sub {
    my $caught;
    my $events = intercept {
        my $ctx = context();
        $ctx->pass('Pool assertions completed before resource exhaustion');
        $ctx->release;

        eval { skip_remaining_on_resource_error($sem_err); 1 };
        $caught = $@;
        die "resource helper did not throw its sentinel\n"
            unless is_resource_unavailable($caught);
    };

    ok(is_resource_unavailable($caught), 'threw the dedicated resource-unavailable sentinel');

    my ($skip) = grep { $_->isa('Test2::Event::Skip') } @$events;
    ok($skip, 'emitted one ordinary skip after an earlier assertion');
    like($skip->facet_data->{assert}->{details}, qr/remaining Pool checks unavailable/,
        'skip makes the unavailable remainder visible');
    ok(!(grep { $_->isa('Test2::Event::Plan') } @$events),
        'did not emit an invalid mid-test skip-all plan');
};

done_testing;
