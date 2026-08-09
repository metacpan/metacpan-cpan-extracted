use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use QDB::Installs qw{
    skip_remaining_on_resource_error is_resource_unavailable
    resource_unavailable_reason subtest_or_resource_skip
};

use Test2::V0;
use Test2::Tools::QuickDB qw/get_db skipall_on_resource_error/;
use Test2::API qw/context intercept/;
use File::Temp qw/tempdir/;
use Capture::Tiny qw/capture/;

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

subtest partial_pool_body_records_skip => sub {
    my $caught;
    my $events = intercept {
        my $ctx = context();
        $ctx->pass('Pool assertions completed before resource exhaustion');
        $ctx->release;

        capture { eval { skip_remaining_on_resource_error($sem_err); 1 }; $caught = $@ };
        die "resource helper did not throw\n"
            unless is_resource_unavailable($caught);
    };

    ok(is_resource_unavailable($caught), 'threw a recognizable resource skip');
    like(resource_unavailable_reason($caught), qr/semaphore/i, 'the reason rides along');

    my ($skip) = grep { $_->isa('Test2::Event::Skip') } @$events;
    ok($skip, 'emitted one ordinary skip after an earlier assertion');
    like($skip->facet_data->{assert}->{details}, qr/remaining Pool checks unavailable/,
        'skip makes the unavailable remainder visible');
    ok(!(grep { $_->isa('Test2::Event::Plan') } @$events),
        'did not emit an invalid mid-test skip-all plan');
};

subtest survives_a_require_boundary => sub {
    # How the Pool bodies are really loaded, and perl rewrites an exception
    # thrown while a file is being required.
    my $dir  = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $file = "$dir/ResourceBoom.pm";

    (my $quoted = $sem_err) =~ s/([\\'])/\\$1/g;
    open(my $fh, '>', $file) or die "Could not write '$file': $!";
    print $fh "QDB::Installs::skip_remaining_on_resource_error('$quoted');\n1;\n";
    close($fh);

    my ($ok, $err);
    my (undef, $stderr) = capture {
        intercept { $ok = eval { require $file; 1 }; $err = $@ };
    };

    ok(!$ok, 'the require failed');
    like($err, qr/Compilation failed in require/, 'perl rewrote the exception on the way out')
        or diag("got: $err");

    ok(is_resource_unavailable($err), 'still recognized as a resource skip');
    like(resource_unavailable_reason($err), qr/semaphore/i, 'the reason is kept');
    like($stderr, qr/Skipping the remaining Pool checks:.*semaphore/i,
        'and reaches stderr, where a smoker report shows it');
};

subtest survives_a_subtest_boundary => sub {
    # subtest fails itself on an exception rather than rethrowing, so a skip
    # raised inside one would read as a fault and the body would keep going.
    my ($ok, $err);
    my $events;
    capture {
        $events = intercept {
            $ok = eval {
                subtest_or_resource_skip(allocating => sub {
                    ok(1, 'assertion before exhaustion');
                    skip_remaining_on_resource_error($sem_err);
                });
                1;
            };
            $err = $@;
        };
    };

    ok(!$ok, 'the body unwinds past the subtest');
    ok(is_resource_unavailable($err), 'carrying the resource signal');

    my ($st) = grep { $_->isa('Test2::Event::Subtest') } @$events;
    ok($st, 'the subtest completed');
    ok($st && $st->pass, 'and passed rather than failing on the skip');
};

subtest failures_report_at_the_call_site => sub {
    # Without a context of its own the wrapper would put every Pool subtest at
    # one line inside QDB::Installs, and a report could not tell them apart.
    my $events = intercept {
        subtest_or_resource_skip(located => sub { ok(0, 'deliberate failure') });
    };

    my ($st) = grep { $_->isa('Test2::Event::Subtest') } @$events;
    ok($st, 'the subtest ran');
    is($st && $st->trace->frame->[1], __FILE__, 'and reports against the caller, not the wrapper');
};

subtest ordinary_exceptions_still_fail_their_subtest => sub {
    my ($ok, $err);
    my $events = intercept {
        $ok = eval {
            # An assertion first: an empty subtest fails on its own, which
            # would hide whether the exception was rethrown.
            subtest_or_resource_skip(ordinary => sub { ok(1, 'ran'); die "deliberate failure\n" });
            1;
        };
        $err = $@;
    };

    ok($ok, 'the body continues, as it always did for a failing subtest');

    my ($st) = grep { $_->isa('Test2::Event::Subtest') } @$events;
    ok($st && !$st->pass, 'the subtest failed');
};

done_testing;
