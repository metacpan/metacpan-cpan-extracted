#!/usr/bin/perl

# Test Clone thread safety with Class::DBI-like patterns (GH #14)
#
# See: https://github.com/garu/Clone/issues/14
#      https://www.perlmonks.org/?node_id=665353
#      (migrated from rt.cpan.org #32848)
#
# Original report (2008): Class::DBI uses Clone::clone on blessed
# hashrefs containing closures (triggers) and class-level metadata
# (see Class::DBI::_extend_meta, line ~1040). Under mod_perl/Win32
# with ThreadsPerChild > 1, this caused "Free to wrong pool" and
# "Attempt to free non-existent shared string" errors.
#
# Class::DBI::_extend_meta calls:
#   Clone::clone($class->__meta_info || {})
# where __meta_info is a class-level data accessor containing
# relationship metadata (has_a, has_many, etc.) with closures.
#
# The root cause is Clone's XS code creating SVs that may reference
# memory from the wrong interpreter's pool when used across ithread
# boundaries. Storable::dclone handles this correctly but can't
# clone closures (which Class::DBI needs for triggers).
#
# NOTE ON TEST LIMITATIONS:
# The original "Free to wrong pool" crash requires mod_perl's
# interpreter pool model, where multiple interpreter instances share
# the same process and pre-cloned Perl data. Plain threads->create()
# does a full perl_clone() of the interpreter, so each child thread
# gets its own copy of all SVs in its own memory pool — Clone then
# operates entirely within one pool, avoiding the cross-pool issue.
#
# These tests exercise the closest approximation we can achieve:
# - Clone::clone in child threads (tests 1-7)
# - Clone::clone on actual Class::DBI objects in threads (test 8)
# - Stress tests with concurrent threads (test 3)
# - Hash key stress (PL_strtab interaction, test 4)
# - Destruction across thread boundaries (test 5)

use strict;
use warnings;
use Test::More;

# threads must be loaded before anything else
BEGIN {
    my $has_threads = eval {
        require Config;
        $Config::Config{useithreads};
    };

    unless ($has_threads) {
        plan skip_all => 'Perl not compiled with thread support (useithreads)';
        exit 0;
    }

    eval { require threads };
    if ($@) {
        plan skip_all => "threads module not available: $@";
        exit 0;
    }
}

use threads;
use Clone qw(clone);

# --- Helper: run a closure in a child thread with error capture ---
sub clone_in_thread {
    my ($sub) = @_;
    my $thr = threads->create(sub {
        my $result = eval { $sub->() };
        return $@ ? { ok => 0, error => "$@" } : $result;
    });
    return $thr->join();
}

# --- Helper: build a Class::DBI-like object ---
# Class::DBI objects are blessed hashrefs containing closures (triggers),
# nested data, and hash keys from the shared string table.
sub make_cdbi_like_object {
    my $trigger_log = [];
    my $obj = bless {
        # Typical Class::DBI columns
        id         => 42,
        name       => "test record",
        email      => 'user@example.com',
        created_at => "2008-02-01",

        # Class::DBI stores closures as triggers
        __triggers => {
            before_create => sub { push @$trigger_log, "before_create" },
            after_create  => sub { push @$trigger_log, "after_create" },
            before_update => sub { push @$trigger_log, "before_update" },
        },

        # Nested column groups (Class::DBI Essential/All)
        __column_groups => {
            Essential => [qw(id name)],
            All       => [qw(id name email created_at)],
        },

        # Meta-info about relationships
        __meta => {
            has_a  => { company_id => 'Company' },
            has_many => { orders => 'Order' },
        },

        # Internal cache
        __data_cache => {
            name  => "test record",
            email => 'user@example.com',
        },
    }, "FakeClassDBI";

    return ($obj, $trigger_log);
}


# --- Test 1: Clone a Class::DBI-like object in the main thread ---
# Baseline: this should always work.

subtest 'clone Class::DBI-like object in main thread' => sub {
    my ($obj, $trigger_log) = make_cdbi_like_object();

    my $cloned = clone($obj);

    is(ref($cloned), 'FakeClassDBI', 'clone preserves blessing');
    is($cloned->{id}, 42, 'clone preserves scalar values');
    is($cloned->{name}, "test record", 'clone preserves string values');
    is(ref($cloned->{__triggers}{before_create}), 'CODE',
        'clone preserves closures');
    is_deeply($cloned->{__column_groups}{Essential}, [qw(id name)],
        'clone preserves nested arrays');

    # Closures in clone are the same refs (Clone does SvREFCNT_inc on PVCV)
    is($cloned->{__triggers}{before_create}, $obj->{__triggers}{before_create},
        'closures share the same coderef (expected behavior)');

    # But data is independent
    $cloned->{name} = "modified";
    is($obj->{name}, "test record", 'original unchanged after clone mutation');
};


# --- Test 2: Clone inside a child thread ---
# This is the core GH #14 scenario: Clone::clone called in a different
# interpreter thread. The cloned SVs should belong to the child thread's
# memory pool, not the parent's.

subtest 'clone in child thread (GH #14 core scenario)' => sub {
    my ($obj) = make_cdbi_like_object();

    my $result = clone_in_thread(sub {
        my $cloned = clone($obj);
        return {
            ok       => 1,
            ref      => ref($cloned),
            id       => $cloned->{id},
            name     => $cloned->{name},
            has_triggers => (ref($cloned->{__triggers}) eq 'HASH' ? 1 : 0),
            has_code => (ref($cloned->{__triggers}{before_create}) eq 'CODE' ? 1 : 0),
        };
    });

    ok($result->{ok}, 'clone() in child thread does not crash')
        or diag("Error: $result->{error}");
    is($result->{ref}, 'FakeClassDBI', 'blessing preserved across threads');
    is($result->{id}, 42, 'scalar value correct in thread clone');
    is($result->{name}, "test record", 'string value correct in thread clone');
    ok($result->{has_triggers}, 'triggers hash present in thread clone');
    ok($result->{has_code}, 'closure present in thread clone');
};


# --- Test 3: Multiple threads cloning the same object simultaneously ---
# mod_perl with ThreadsPerChild > 1 means multiple threads hit Clone::clone
# concurrently. This test stresses the "Free to wrong pool" scenario.

subtest 'concurrent cloning in multiple threads' => sub {
    my ($obj) = make_cdbi_like_object();

    my $num_threads = 5;
    my @threads;

    for my $i (1 .. $num_threads) {
        push @threads, threads->create(sub {
            my $result = eval {
                my @clones;
                for my $j (1 .. 10) {
                    push @clones, clone($obj);
                }
                my $last = $clones[-1];
                return {
                    ok   => 1,
                    id   => $last->{id},
                    name => $last->{name},
                    count => scalar @clones,
                };
            };
            return $@ ? { ok => 0, error => "$@" } : $result;
        });
    }

    for my $i (0 .. $#threads) {
        my $result = $threads[$i]->join();
        ok($result->{ok}, "thread ${\($i+1)} clone succeeded")
            or diag("Thread ${\($i+1)} error: $result->{error}");
        is($result->{id}, 42, "thread ${\($i+1)} clone has correct id")
            if $result->{ok};
        is($result->{count}, 10, "thread ${\($i+1)} produced 10 clones")
            if $result->{ok};
    }
};


# --- Test 4: Clone object with hash keys from shared string table ---
# Hash keys in Perl are stored in PL_strtab (shared string table).
# Under ithreads, each interpreter has its own PL_strtab.
# "Attempt to free non-existent shared string" comes from Clone
# creating hash entries that reference the wrong PL_strtab.

subtest 'clone with many hash keys across threads' => sub {
    my $obj = bless {}, "KeyHeavy";
    for my $i (1 .. 50) {
        $obj->{"column_$i"} = "value_$i";
        $obj->{"meta_$i"} = { type => "varchar", length => $i * 10 };
    }

    my $result = clone_in_thread(sub {
        my $cloned = clone($obj);

        my $ok = 1;
        for my $i (1, 25, 50) {
            $ok = 0 unless $cloned->{"column_$i"} eq "value_$i";
            $ok = 0 unless ref($cloned->{"meta_$i"}) eq 'HASH';
            $ok = 0 unless $cloned->{"meta_$i"}{type} eq "varchar";
        }

        # Mutate clone to force string deallocation
        delete $cloned->{"column_$_"} for 1 .. 50;

        return { ok => $ok };
    });
    ok($result->{ok}, 'clone with many hash keys works across threads')
        or diag("Error: " . ($result->{error} // 'value mismatch'));
};


# --- Test 5: Clone object then destroy in different thread ---
# The "Free to wrong pool" crash typically happens during cleanup:
# the thread that destroys the cloned SVs isn't the one that allocated them.

subtest 'clone created in parent, destroyed in child' => sub {
    my ($obj) = make_cdbi_like_object();
    my $cloned = clone($obj);

    # Pass the clone to a child thread for destruction
    my $result = clone_in_thread(sub {
        my $local_ref = $cloned;
        my $name = $local_ref->{name};
        my $id = $local_ref->{id};
        # Thread exit will destroy $local_ref
        return { ok => 1, name => $name, id => $id };
    });
    ok($result->{ok}, 'clone can be passed to and destroyed in child thread');
    is($result->{name}, "test record", 'value accessible in child thread');
};


# --- Test 6: Repeated clone-in-thread cycles ---
# mod_perl serves many requests; each request may clone.
# Memory pool corruption often manifests after multiple cycles.

subtest 'repeated clone cycles across threads (mod_perl simulation)' => sub {
    my ($obj) = make_cdbi_like_object();

    my $num_cycles = 10;
    my $all_ok = 1;

    for my $cycle (1 .. $num_cycles) {
        my $result = clone_in_thread(sub {
            my $cloned = clone($obj);
            my $id = $cloned->{id};
            $cloned->{name} = "request_$cycle";
            $cloned->{__data_cache} = {};
            return { ok => 1, id => $id };
        });
        unless ($result->{ok}) {
            $all_ok = 0;
            diag("Cycle $cycle failed: $result->{error}");
            last;
        }
    }

    ok($all_ok, "all $num_cycles clone-in-thread cycles succeeded");
};


# --- Test 7: Clone with Class::DBI-like closures that capture variables ---
# Class::DBI triggers are closures that capture column accessors.
# The captured variables reference the parent thread's memory.

subtest 'clone closures that capture variables' => sub {
    my $obj = bless {
        id   => 1,
        name => "closures",
        _on_update => sub { "updated: $_[0]" },
        _validator => sub { length($_[0]) > 0 },
    }, "ClosureObj";

    my $result = clone_in_thread(sub {
        my $cloned = clone($obj);
        # Closures in clone are shared refs (PVCV gets SvREFCNT_inc)
        # but accessing them shouldn't crash
        return {
            ok             => 1,
            has_update     => (ref($cloned->{_on_update}) eq 'CODE' ? 1 : 0),
            has_validator  => (ref($cloned->{_validator}) eq 'CODE' ? 1 : 0),
        };
    });
    ok($result->{ok}, 'clone with closures works in child thread')
        or diag("Error: $result->{error}");
    ok($result->{has_update}, 'update closure preserved');
    ok($result->{has_validator}, 'validator closure preserved');
};


# --- Test 8: With actual Class::DBI if available ---
# Full reproduction of the original bug report. Requires Class::DBI
# (and its dependency chain) which is rarely installed.

SKIP: {
    # Class::DBI has a deep dependency chain and is essentially abandoned.
    # This test is a best-effort reproduction of the original report.
    eval { require Class::DBI; require DBD::SQLite; 1 }
        or skip "Class::DBI + DBD::SQLite required for full reproduction", 4;

    # Set up the Class::DBI subclasses via string eval (compile-time 'use base'
    # would fail at parse time if Class::DBI is not installed).
    my $setup_ok = eval q{
        package TestDB::DBI;
        use base 'Class::DBI';
        TestDB::DBI->connection("dbi:SQLite:dbname=:memory:");
        TestDB::DBI->db_Main->do(
            "CREATE TABLE test_record (id INTEGER PRIMARY KEY, name TEXT, email TEXT)"
        );

        package TestDB::Record;
        use base 'TestDB::DBI';
        TestDB::Record->table('test_record');
        TestDB::Record->columns(All => qw(id name email));

        # Add a trigger — this creates the closure that Class::DBI clones
        TestDB::Record->add_trigger(before_create => sub {
            my $self = shift;
            $self->_attribute_set(email => lc($self->email))
                if $self->email;
        });

        1;
    };
    skip "Failed to set up Class::DBI: $@", 4 unless $setup_ok;

    # Create a record
    my $record = eval { TestDB::Record->create({
        name  => "Test User",
        email => "Test\@Example.COM",
    }) };
    skip "Failed to create record: $@", 4 unless $record;

    ok(defined $record, 'Class::DBI record created');
    is($record->email, 'test@example.com', 'trigger fired correctly');

    # Now clone it in a child thread — this is the GH #14 crash scenario
    my $result = clone_in_thread(sub {
        my $cloned = clone($record);
        return {
            ok   => 1,
            id   => $cloned->{id},
            name => $cloned->{name},
        };
    });
    ok($result->{ok}, 'GH #14: clone of Class::DBI record in thread does not crash')
        or diag("Error: $result->{error}");
    is($result->{name}, "Test User", 'cloned record data correct')
        if $result->{ok};
}


done_testing();
