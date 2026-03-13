use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}

use Test::LeakTrace;
use POSIX ();

use Data::HashMap::II;
use Data::HashMap::IS;
use Data::HashMap::SS;
use Data::HashMap::SI;
use Data::HashMap::I32;
use Data::HashMap::I32S;
use Data::HashMap::SI32;
use Data::HashMap::I16;
use Data::HashMap::I16S;
use Data::HashMap::SI16;
use Data::HashMap::IA;
use Data::HashMap::SA;
use Data::HashMap::I32A;
use Data::HashMap::I16A;

# ---- Integer-key/integer-value variants ----

no_leaks_ok {
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 1..100;
    hm_ii_get $m, 50;
    hm_ii_remove $m, 50;
    hm_ii_keys $m;
    hm_ii_values $m;
    hm_ii_items $m;
    hm_ii_clear $m;
} 'II: basic lifecycle';

no_leaks_ok {
    my $m = Data::HashMap::I32->new();
    hm_i32_put $m, $_, $_ for 1..100;
    hm_i32_incr $m, 1;
    hm_i32_decr $m, 2;
    hm_i32_incr_by $m, 3, 10;
    hm_i32_clear $m;
} 'I32: lifecycle + counters';

no_leaks_ok {
    my $m = Data::HashMap::I16->new();
    hm_i16_put $m, $_, $_ for 1..100;
    hm_i16_incr $m, 1;
    hm_i16_remove $m, 50;
    hm_i16_to_hash $m;
    hm_i16_clear $m;
} 'I16: lifecycle + counters';

# ---- String-value variants ----

no_leaks_ok {
    my $m = Data::HashMap::IS->new();
    hm_is_put $m, $_, "val$_" for 1..100;
    hm_is_get $m, 50;
    hm_is_remove $m, 50;
    hm_is_keys $m;
    hm_is_values $m;
    hm_is_to_hash $m;
    hm_is_clear $m;
} 'IS: string values lifecycle';

no_leaks_ok {
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "k$_", "v$_" for 1..100;
    hm_ss_get $m, "k50";
    hm_ss_remove $m, "k50";
    hm_ss_keys $m;
    hm_ss_values $m;
    hm_ss_to_hash $m;
    hm_ss_clear $m;
} 'SS: string/string lifecycle';

no_leaks_ok {
    my $m = Data::HashMap::I32S->new();
    hm_i32s_put $m, $_, "val$_" for 1..100;
    hm_i32s_get $m, 50;
    hm_i32s_remove $m, 50;
    hm_i32s_clear $m;
} 'I32S: lifecycle';

no_leaks_ok {
    my $m = Data::HashMap::I16S->new();
    hm_i16s_put $m, $_, "val$_" for 1..50;
    hm_i16s_get $m, 25;
    hm_i16s_remove $m, 25;
    hm_i16s_clear $m;
} 'I16S: lifecycle';

# ---- String-key/integer-value variants ----

no_leaks_ok {
    my $m = Data::HashMap::SI->new();
    hm_si_put $m, "k$_", $_ for 1..100;
    hm_si_incr $m, "k1";
    hm_si_get $m, "k50";
    hm_si_remove $m, "k50";
    hm_si_clear $m;
} 'SI: lifecycle + counters';

no_leaks_ok {
    my $m = Data::HashMap::SI32->new();
    hm_si32_put $m, "k$_", $_ for 1..100;
    hm_si32_incr $m, "k1";
    hm_si32_remove $m, "k50";
    hm_si32_clear $m;
} 'SI32: lifecycle + counters';

no_leaks_ok {
    my $m = Data::HashMap::SI16->new();
    hm_si16_put $m, "k$_", $_ for 1..50;
    hm_si16_incr $m, "k1";
    hm_si16_remove $m, "k25";
    hm_si16_clear $m;
} 'SI16: lifecycle + counters';

# ---- SV* variants (refcount-sensitive) ----

no_leaks_ok {
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, $_, [1, 2, $_] for 1..50;
    hm_ia_get $m, 25;
    hm_ia_remove $m, 25;
    hm_ia_keys $m;
    hm_ia_values $m;
    hm_ia_clear $m;
} 'IA: SV* values lifecycle';

no_leaks_ok {
    my $m = Data::HashMap::SA->new();
    hm_sa_put $m, "k$_", { n => $_ } for 1..50;
    hm_sa_get $m, "k25";
    hm_sa_remove $m, "k25";
    hm_sa_keys $m;
    hm_sa_values $m;
    hm_sa_clear $m;
} 'SA: SV* values lifecycle';

no_leaks_ok {
    my $m = Data::HashMap::I32A->new();
    hm_i32a_put $m, $_, \$_ for 1..50;
    hm_i32a_get $m, 25;
    hm_i32a_remove $m, 25;
    hm_i32a_clear $m;
} 'I32A: SV* values lifecycle';

no_leaks_ok {
    my $m = Data::HashMap::I16A->new();
    hm_i16a_put $m, $_, [1..$_] for 1..20;
    hm_i16a_get $m, 10;
    hm_i16a_remove $m, 10;
    hm_i16a_clear $m;
} 'I16A: SV* values lifecycle';

# ---- Overwrite: old values must be freed ----

no_leaks_ok {
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "key", "first";
    hm_ss_put $m, "key", "second";
    hm_ss_put $m, "key", "third";
} 'SS: overwrite frees old string values';

no_leaks_ok {
    my $m = Data::HashMap::IS->new();
    hm_is_put $m, 1, "a" x 1000;
    hm_is_put $m, 1, "b" x 1000;
    hm_is_put $m, 1, "c" x 1000;
} 'IS: overwrite frees old string values';

no_leaks_ok {
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, [1..100];
    hm_ia_put $m, 1, [200..300];
    hm_ia_put $m, 1, {a => 1};
} 'IA: overwrite decrements old SV* refcount';

no_leaks_ok {
    my $m = Data::HashMap::SA->new();
    hm_sa_put $m, "k", [1..100];
    hm_sa_put $m, "k", [200..300];
    hm_sa_put $m, "k", {a => 1};
} 'SA: overwrite decrements old SV* refcount';

# ---- LRU eviction must free evicted entries ----

no_leaks_ok {
    my $m = Data::HashMap::SS->new(10);
    hm_ss_put $m, "k$_", "v$_" for 1..100;
} 'SS LRU: evicted string keys+values freed';

no_leaks_ok {
    my $m = Data::HashMap::IS->new(10);
    hm_is_put $m, $_, "val$_" for 1..100;
} 'IS LRU: evicted string values freed';

no_leaks_ok {
    my $m = Data::HashMap::IA->new(10);
    hm_ia_put $m, $_, [$_] for 1..100;
} 'IA LRU: evicted SV* values freed';

no_leaks_ok {
    my $m = Data::HashMap::SA->new(10);
    hm_sa_put $m, "k$_", { n => $_ } for 1..100;
} 'SA LRU: evicted SV* values freed';

no_leaks_ok {
    my $m = Data::HashMap::II->new(10);
    hm_ii_put $m, $_, $_ for 1..100;
} 'II LRU: no leaks on eviction cycle';

no_leaks_ok {
    my $m = Data::HashMap::I32S->new(10);
    hm_i32s_put $m, $_, "v$_" for 1..100;
} 'I32S LRU: evicted string values freed';

no_leaks_ok {
    my $m = Data::HashMap::I16S->new(10);
    hm_i16s_put $m, $_, "v$_" for 1..100;
} 'I16S LRU: evicted string values freed';

# ---- Destroy: map destruction frees all entries ----

no_leaks_ok {
    for (1..5) {
        my $m = Data::HashMap::SS->new();
        hm_ss_put $m, "k$_", "v$_" for 1..50;
    }
} 'SS: destroy frees all string entries';

no_leaks_ok {
    for (1..5) {
        my $m = Data::HashMap::IA->new();
        hm_ia_put $m, $_, { data => [1..10] } for 1..50;
    }
} 'IA: destroy frees all SV* entries';

no_leaks_ok {
    for (1..5) {
        my $m = Data::HashMap::SA->new();
        hm_sa_put $m, "k$_", sub { $_ * 2 } for 1..50;
    }
} 'SA: destroy frees coderefs';

no_leaks_ok {
    for (1..5) {
        my $m = Data::HashMap::IS->new();
        hm_is_put $m, $_, "x" x 100 for 1..50;
    }
} 'IS: destroy frees all string entries';

# ---- Tombstone compaction must not leak ----

no_leaks_ok {
    my $m = Data::HashMap::SS->new();
    for my $round (1..5) {
        hm_ss_put $m, "k$_", "v$_" for 1..50;
        hm_ss_remove $m, "k$_" for 1..50;
    }
} 'SS: tombstone compaction no leak';

no_leaks_ok {
    my $m = Data::HashMap::IA->new();
    for my $round (1..5) {
        hm_ia_put $m, $_, [$round, $_] for 1..50;
        hm_ia_remove $m, $_ for 1..50;
    }
} 'IA: tombstone compaction no SV* leak';

no_leaks_ok {
    my $m = Data::HashMap::SA->new();
    for my $round (1..5) {
        hm_sa_put $m, "k$_", { r => $round } for 1..50;
        hm_sa_remove $m, "k$_" for 1..50;
    }
} 'SA: tombstone compaction no SV* leak';

# ---- get_or_set must not leak ----

no_leaks_ok {
    my $m = Data::HashMap::II->new();
    hm_ii_get_or_set $m, 1, 10;
    hm_ii_get_or_set $m, 1, 20;  # should return existing, not leak
    hm_ii_get_or_set $m, 2, 30;
} 'II: get_or_set no leak';

no_leaks_ok {
    my $m = Data::HashMap::SS->new();
    hm_ss_get_or_set $m, "a", "first";
    hm_ss_get_or_set $m, "a", "second";  # should return existing
    hm_ss_get_or_set $m, "b", "new";
} 'SS: get_or_set no leak';

no_leaks_ok {
    my $m = Data::HashMap::IS->new();
    hm_is_get_or_set $m, 1, "first";
    hm_is_get_or_set $m, 1, "second";
    hm_is_get_or_set $m, 2, "new";
} 'IS: get_or_set no leak';

no_leaks_ok {
    my $m = Data::HashMap::SI->new();
    hm_si_get_or_set $m, "a", 10;
    hm_si_get_or_set $m, "a", 20;
    hm_si_get_or_set $m, "b", 30;
} 'SI: get_or_set no leak';

# ---- each iterator must not leak ----

no_leaks_ok {
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "k$_", "v$_" for 1..20;
    while (my ($k, $v) = hm_ss_each $m) { }
} 'SS: each iterator no leak';

no_leaks_ok {
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, $_, [$_] for 1..20;
    while (my ($k, $v) = hm_ia_each $m) { }
} 'IA: each iterator no leak';

no_leaks_ok {
    my $m = Data::HashMap::SA->new();
    hm_sa_put $m, "k$_", { n => $_ } for 1..20;
    while (my ($k, $v) = hm_sa_each $m) { }
} 'SA: each iterator no leak';

# ---- to_hash must not leak ----

no_leaks_ok {
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "k$_", "v$_" for 1..20;
    my $h = hm_ss_to_hash $m;
} 'SS: to_hash no leak';

no_leaks_ok {
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, $_, [$_] for 1..20;
    my $h = hm_ia_to_hash $m;
} 'IA: to_hash no leak';

# ---- UTF-8 strings must not leak ----

no_leaks_ok {
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "\x{100}k$_", "\x{200}v$_" for 1..50;
    hm_ss_get $m, "\x{100}k25";
    hm_ss_remove $m, "\x{100}k25";
    hm_ss_clear $m;
} 'SS: UTF-8 keys and values no leak';

no_leaks_ok {
    my $m = Data::HashMap::IS->new();
    hm_is_put $m, $_, "\x{263A}" x $_ for 1..50;
    hm_is_remove $m, $_ for 1..50;
} 'IS: UTF-8 values no leak';

# ---- Resize/rehash must not leak ----

no_leaks_ok {
    my $m = Data::HashMap::SS->new();
    # Force multiple resizes (initial cap 16, resize at 75%)
    hm_ss_put $m, "key$_", "val$_" for 1..200;
} 'SS: multiple resizes no leak';

no_leaks_ok {
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, $_, { x => $_ } for 1..200;
} 'IA: multiple resizes no leak';

# ---- put_ttl must not leak ----

no_leaks_ok {
    my $m = Data::HashMap::II->new();
    hm_ii_put_ttl $m, $_, $_ * 10, 60 for 1..50;
    hm_ii_clear $m;
} 'II: put_ttl no leak';

no_leaks_ok {
    my $m = Data::HashMap::SS->new();
    hm_ss_put_ttl $m, "k$_", "v$_", 60 for 1..50;
    hm_ss_clear $m;
} 'SS: put_ttl no leak';

no_leaks_ok {
    my $m = Data::HashMap::IA->new();
    hm_ia_put_ttl $m, $_, [$_], 60 for 1..50;
    hm_ia_clear $m;
} 'IA: put_ttl no leak';

# ---- Map with default TTL lifecycle ----

no_leaks_ok {
    my $m = Data::HashMap::SS->new(0, 60);
    hm_ss_put $m, "k$_", "v$_" for 1..50;
    hm_ss_clear $m;
} 'SS: default TTL lifecycle no leak';

no_leaks_ok {
    my $m = Data::HashMap::IA->new(0, 60);
    hm_ia_put $m, $_, [$_] for 1..50;
    hm_ia_clear $m;
} 'IA: default TTL lifecycle no leak';

# ---- LRU + TTL combined ----

no_leaks_ok {
    my $m = Data::HashMap::SS->new(20, 60);
    hm_ss_put $m, "k$_", "v$_" for 1..100;
} 'SS: LRU+TTL combined no leak';

no_leaks_ok {
    my $m = Data::HashMap::SA->new(20, 60);
    hm_sa_put $m, "k$_", { n => $_ } for 1..100;
} 'SA: LRU+TTL combined no leak';

# ---- RSS reclamation: verify memory returned to OS after map destroy ----
# Each variant runs in its own forked child for clean RSS baselines.
# Uses /proc/PID/status (Linux-only); skipped on other platforms.

SKIP: {
    skip 'RSS reclamation test requires /proc (Linux)', 8
        unless -r "/proc/$$/status";

    my sub get_rss {
        open my $fh, '<', "/proc/$$/status" or return 0;
        while (<$fh>) {
            return $1 if /^VmRSS:\s+(\d+)\s+kB/;
        }
        return 0;
    }

    # Run a single RSS test in an isolated child process.
    # $fill_code populates a map stored in $_[0] (an outer ref slot).
    # Returns ($baseline, $peak, $after) in kB, or () on fork failure.
    my sub rss_test {
        my ($fill_code) = @_;
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            close $rd;
            my $map;
            my $baseline = get_rss();
            $fill_code->(\$map);
            my $peak = get_rss();
            undef $map;  # trigger DESTROY — free all C memory
            my $after = get_rss();
            print $wr "$baseline|$peak|$after\n";
            close $wr;
            POSIX::_exit(0);
        }
        close $wr;
        my $line = <$rd>;
        close $rd;
        waitpid($pid, 0);
        return () if $? >> 8;
        chomp $line;
        return split /\|/, $line;
    }

    # Integer-only variants: the node array is one large calloc (above
    # glibc's mmap threshold), so free() returns it to the OS immediately.
    # These are the variants where we can reliably measure RSS reclamation.
    my @tests = (
        ['II', sub {
            my $ref = $_[0];
            $$ref = Data::HashMap::II->new();
            hm_ii_put $$ref, $_, $_ for 1..1_000_000;
        }],
        ['I32', sub {
            my $ref = $_[0];
            $$ref = Data::HashMap::I32->new();
            hm_i32_put $$ref, $_, $_ for 1..500_000;
        }],
    );

    for my $t (@tests) {
        my ($variant, $code) = @$t;
        my ($baseline, $peak, $after) = rss_test($code);
        unless (defined $baseline) {
            fail("$variant RSS: child fork/exec failed");
            fail("$variant RSS: (skipped)");
            next;
        }
        my $grew = $peak - $baseline;
        my $reclaimed = $peak - $after;

        cmp_ok($grew, '>', 5_000,
            "$variant RSS: map allocation visible (grew ${grew} kB)");

        # Node array is a single large allocation — glibc uses mmap for
        # allocations above MMAP_THRESHOLD (~128 KB), returned on free.
        my $pct = $grew > 0 ? int(100 * $reclaimed / $grew) : 0;
        cmp_ok($pct, '>=', 75,
            "$variant RSS: reclaimed ${pct}% after destroy (${reclaimed}/${grew} kB)");
    }

    # String/SV* variants: per-entry mallocs are small (sbrk-based),
    # glibc retains them in its free pool after free() — RSS won't drop.
    # Instead, we verify no unbounded growth: run N fill/destroy cycles
    # and assert RSS after cycle N is not significantly larger than after
    # cycle 1 (freed memory is reused by the allocator on subsequent fills).
    my sub rss_cycle_test {
        my ($fill_code, $cycles) = @_;
        $cycles //= 5;
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            close $rd;
            my $map;
            my @rss;
            for my $i (1..$cycles) {
                $fill_code->(\$map);
                push @rss, get_rss();
                undef $map;
            }
            print $wr join("|", @rss), "\n";
            close $wr;
            POSIX::_exit(0);
        }
        close $wr;
        my $line = <$rd>;
        close $rd;
        waitpid($pid, 0);
        return () if $? >> 8;
        chomp $line;
        return split /\|/, $line;
    }

    # SS: 5 cycles of 100K entries with 200-byte values
    {
        my @rss = rss_cycle_test(sub {
            my $ref = $_[0];
            $$ref = Data::HashMap::SS->new();
            hm_ss_put $$ref, "key$_", "x" x 200 for 1..100_000;
        }, 5);
        if (@rss >= 2) {
            cmp_ok($rss[0], '>', 0, 'SS RSS cycle: first fill uses memory');
            # If we were leaking, RSS at cycle 5 would be ~5x cycle 1.
            # With proper free, allocator reuses freed regions and RSS stays flat.
            # Allow 25% growth for allocator fragmentation.
            my $growth_pct = int(100 * ($rss[-1] - $rss[0]) / $rss[0]);
            cmp_ok($growth_pct, '<', 25,
                "SS RSS cycle: ${growth_pct}% growth over 5 cycles (expect <25%)");
        } else {
            fail("SS RSS cycle: fork failed"); fail("SS RSS cycle: (skipped)");
        }
    }

    # IA: 5 cycles of 200K SV* entries
    {
        my @rss = rss_cycle_test(sub {
            my $ref = $_[0];
            $$ref = Data::HashMap::IA->new();
            hm_ia_put $$ref, $_, [$_, $_ + 1] for 1..200_000;
        }, 5);
        if (@rss >= 2) {
            cmp_ok($rss[0], '>', 0, 'IA RSS cycle: first fill uses memory');
            my $growth_pct = int(100 * ($rss[-1] - $rss[0]) / $rss[0]);
            cmp_ok($growth_pct, '<', 25,
                "IA RSS cycle: ${growth_pct}% growth over 5 cycles (expect <25%)");
        } else {
            fail("IA RSS cycle: fork failed"); fail("IA RSS cycle: (skipped)");
        }
    }
}

done_testing;
