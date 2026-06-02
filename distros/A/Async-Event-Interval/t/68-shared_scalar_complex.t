use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;

use Async::Event::Interval;

# Tests for shared_scalar holding complex data structures (refs, nested
# structs, type mutation) shared between the parent process and events.
#
#  1  Parent assigns hashref in-process; type changes from undef to HASH ref
#  2  Event writes hashref; parent reads all fields after event completes
#  3  Event writes arrayref; parent reads elements and length
#  4  Parent writes hashref; event reads it and reports results via 2nd scalar
#  5  Two events share one scalar: A writes, B reads and augments
#  6  Parent seeds hashref; two events each extend it via direct mutation; all three keys survive
#  7  3-level nested hashref round-trips through parent STORE/FETCH (no fork)
#  8  Event writes 3-level nested hashref; parent dereferences all three levels
#  9  Two events exchange 3-level structures: B reads A's leaf, embeds it in its own
# 10  Type mutation: undef -> string -> arrayref -> hashref -> number
# 11  Direct dereferenced mutation: $$s->{key} = $val (alternative to spread)
# 12  Mixed nesting: hash of arrays of hashes
# 13  5-level nesting (segment-per-node cost doesn't break at depth)
# 14  interval > 0: event writes periodically while parent reads
# 15  Storing a blessed object: blessing not preserved cross-process (POD warning)
# 16  Storing a code ref: not retrievable cross-process (POD warning)
# 17  Mutate-then-store: pins the broken pattern documented in POD
# 18  Event crash mid-write: shared_scalar remains readable and writable
#
# Capacity-aware execution: each event + shared_scalar pair holds 3-7 SysV
# semaphore identifier sets (events hash entry, lock semaphore, scalar
# segment, plus one per nested ref). The full 18-subtest battery peaks above
# 50 sem sets cumulatively within a single perl process (block-exit DESTROY
# releases only 1-2 sets per block). On platforms with tight kernel limits
# (FreeBSD default semmni=50, OpenBSD default semmni=10), running the full
# battery hits ENOSPC mid-run. We branch on available headroom:
#
#   * Full     (headroom >= 65 or unknown): all 18 subtests
#   * Reduced  (headroom >= 45): skips the heaviest 5 subtests (4, 8, 9, 12, 13)
#   * Skip-all (headroom < 45): plan skip_all with a remediation diag
#
# Each shared_scalar event consumes ~15-20 SysV semaphores; the 65/45
# thresholds were derived empirically on FreeBSD to stay under
# kern.ipc.semmni while leaving headroom for other IPC consumers. The
# reduced subset still exercises basic shared_scalar semantics, event-driven
# writes, two-event exchange, type mutation, interval mode, blessed/code ref
# limitations, the mutate-then-store edge case, and crash-during-write
# recovery — only the deep-nesting and two-event-with-deep-nesting cases drop.

my $headroom    = TestHelper::available_sem_headroom();
my $can_full    = ! defined($headroom) || $headroom >= 65;
my $can_reduced = ! defined($headroom) || $headroom >= 45;

unless ($can_reduced) {
    TestHelper::note_skip_all();
    plan skip_all =>
        "Insufficient SysV semaphore headroom for this test "
      . "(have " . (defined $headroom ? $headroom : 'unknown')
      . ", need >= 45). Raise kern.ipc.semmni (FreeBSD) or "
      . "/proc/sys/kernel/sem field 4 (Linux).";
}

if (! $can_full) {
    diag "Low IPC headroom ($headroom < 65): running reduced subset "
       . "(skipping subtests 4, 8, 9, 12, 13).";
}

my $mod = 'Async::Event::Interval';

# 1. Assigning a hashref to a shared_scalar changes the dereferenced
#    value from undef to a HASH ref. No fork needed.
{
    my $e = $mod->new(0, sub {});
    my $s = $e->shared_scalar;

    ok ! defined($$s), "initial dereferenced value is undef";

    $$s = { language => 'Perl', version => 5 };

    is ref($$s),        'HASH', "hashref assignment: dereferenced ref() is HASH";
    is $$s->{language}, 'Perl', "hashref field 'language' readable after assignment";
    is $$s->{version},  5,      "hashref field 'version' readable after assignment";
}

# 2. Event writes a hashref; parent reads all fields once the one-shot
#    event completes (interval=0, wait() blocks until dormant).
{
    my $s;
    my $e = $mod->new(0, sub {
        $$s = { name => 'alice', score => 42, active => 1 };
    });
    $s = $e->shared_scalar;

    $e->start;
    $e->wait;

    is ref($$s),      'HASH',  "event-written hashref: ref() is HASH in parent";
    is $$s->{name},   'alice', "event-written hashref: 'name' field correct";
    is $$s->{score},  42,      "event-written hashref: 'score' field correct";
    is $$s->{active}, 1,       "event-written hashref: 'active' field correct";
}

# 3. Event writes an arrayref; parent reads elements and verifies length.
{
    my $s;
    my $e = $mod->new(0, sub {
        $$s = ['red', 'green', 'blue'];
    });
    $s = $e->shared_scalar;

    $e->start;
    $e->wait;

    is ref($$s),       'ARRAY', "event-written arrayref: ref() is ARRAY in parent";
    is $$s->[0],       'red',   "arrayref element [0] correct";
    is $$s->[2],       'blue',  "arrayref element [2] correct";
    is scalar @{$$s},  3,       "arrayref has correct element count";
}

# 4. Parent writes a hashref before the event starts; event reads fields
#    and reports results via a second shared_scalar on the same event.
#    SKIPPED in reduced mode: two shared_scalars on one event allocates
#    extra child segments.
if ($can_full) {
    my ($s_input, $s_result);
    my $e = $mod->new(0, sub {
        $$s_result = {
            greeting_ok => ($$s_input->{greeting} eq 'hello' ? 1 : 0),
            count_ok    => ($$s_input->{count}    == 7       ? 1 : 0),
        };
    });
    $s_input  = $e->shared_scalar;
    $s_result = $e->shared_scalar;

    $$s_input = { greeting => 'hello', count => 7 };

    $e->start;
    $e->wait;

    is $$s_result->{greeting_ok}, 1, "event correctly read parent-written 'greeting' field";
    is $$s_result->{count_ok},    1, "event correctly read parent-written 'count' field";
}

# 5. Two events share one shared_scalar: event A writes a hashref,
#    event B reads it and augments it; parent reads the final state.
{
    my $s;
    my $event_a = $mod->new(0, sub {
        $$s = { source => 'A', value => 100 };
    });
    $s = $event_a->shared_scalar;

    my $event_b = $mod->new(0, sub {
        my $current = $$s;
        $$s = { %$current, source => 'B', doubled => $current->{value} * 2 };
    });

    $event_a->start;
    $event_a->wait;

    $event_b->start;
    $event_b->wait;

    is ref($$s),        'HASH', "two-event exchange: result is a HASH ref";
    is $$s->{source},   'B',    "event B's 'source' overwrote event A's";
    is $$s->{value},    100,    "original field from event A preserved";
    is $$s->{doubled},  200,    "event B doubled event A's value correctly";
}

# 6. Parent writes a seed hashref; two events each extend it via direct
#    dereferenced mutation (the alternative idiom to the spread used in
#    test 5 - see shared_scalar POD). Direct mutation adds a single key to
#    the existing tied hash rather than replacing the entire stored value,
#    so it avoids the nested-segment STORE path that older IPC::Shareable
#    versions don't always handle reliably across forks. All three parties'
#    keys coexist in the final snapshot.
{
    my $s;
    my $event_a = $mod->new(0, sub {
        $$s->{event_a} = 'done';
    });
    $s = $event_a->shared_scalar;

    my $event_b = $mod->new(0, sub {
        $$s->{event_b} = 'done';
    });

    $$s = { written_by => 'parent' };

    $event_a->start;
    $event_a->wait;

    $event_b->start;
    $event_b->wait;

    is $$s->{written_by}, 'parent', "parent's initial key survives both events";
    is $$s->{event_a},    'done',   "event A's key is present in final hashref";
    is $$s->{event_b},    'done',   "event B's key is present in final hashref";
}

# 7. A 3-level nested hashref round-trips through parent-side STORE/FETCH on
#    the shared scalar. Under the hood, each nested hashref allocates its own
#    child shared-memory segment; cleanup is automatic on reassign and on
#    event destruction. No fork needed.
{
    my $e = $mod->new(0, sub {});
    my $s = $e->shared_scalar;

    $$s = { level1 => { level2 => { level3 => 'deep_value' } } };

    is ref($$s),                      'HASH',       "3-level (parent): level 1 is HASH ref";
    is ref($$s->{level1}),            'HASH',       "3-level (parent): level 2 is HASH ref";
    is ref($$s->{level1}{level2}),    'HASH',       "3-level (parent): level 3 is HASH ref";
    is $$s->{level1}{level2}{level3}, 'deep_value', "3-level (parent): leaf value correct";
}

# 8. Event writes a 3-level nested hashref; parent reads and dereferences
#    all three levels after the event completes.
#    SKIPPED in reduced mode: 3-level event-side nesting is redundant with
#    subtest 7's parent-side 3-level coverage.
if ($can_full) {
    my $s;
    my $e = $mod->new(0, sub {
        $$s = {
            config => {
                database => {
                    host => 'db.example.com',
                    port => 5432,
                }
            }
        };
    });
    $s = $e->shared_scalar;

    $e->start;
    $e->wait;

    is ref($$s),                     'HASH',           "3-level (event): level 1 is HASH ref";
    is ref($$s->{config}),           'HASH',           "3-level (event): level 2 is HASH ref";
    is ref($$s->{config}{database}), 'HASH',           "3-level (event): level 3 is HASH ref";
    is $$s->{config}{database}{host},'db.example.com', "3-level (event): host leaf value correct";
    is $$s->{config}{database}{port}, 5432,            "3-level (event): port leaf value correct";
}

# 9. Two events exchange 3-level nested structures through one shared
#    scalar: event A writes {a=>{b=>{c=>'from_A'}}}; event B reads
#    that leaf, then replaces the scalar with its own 3-level struct
#    that embeds the value it read.
#    SKIPPED in reduced mode: this is the heaviest single block (two
#    events + 3-level structures = ~7 sem sets cumulative).
if ($can_full) {
    my $s;
    my $event_a = $mod->new(0, sub {
        $$s = { a => { b => { c => 'from_A' } } };
    });
    $s = $event_a->shared_scalar;

    my $event_b = $mod->new(0, sub {
        my $leaf = $$s->{a}{b}{c};
        $$s = { x => { y => { z => "got:$leaf" } } };
    });

    $event_a->start;
    $event_a->wait;

    is $$s->{a}{b}{c}, 'from_A', "before event B: event A's 3-level leaf readable in parent";

    $event_b->start;
    $event_b->wait;

    is ref($$s),       'HASH',       "after event B: result is a HASH ref";
    is $$s->{x}{y}{z}, 'got:from_A', "event B's 3-level leaf reflects value it read from event A";
}

# 10. A shared_scalar can hold different types across sequential
#     assignments in the parent: undef -> string -> arrayref -> hashref
#     -> plain number, with correct round-trips at each step.
{
    my $e = $mod->new(0, sub {});
    my $s = $e->shared_scalar;

    ok ! defined($$s),  "type mutation: initial value is undef";

    $$s = 'plain string';
    is $$s,    'plain string', "type mutation: string assignment round-trips correctly";
    ok ! ref($$s),              "type mutation: string has no ref";

    $$s = [10, 20, 30];
    is ref($$s), 'ARRAY', "type mutation: arrayref assignment";
    is $$s->[1], 20,      "type mutation: arrayref element [1] correct";

    $$s = { a => 1, b => 2 };
    is ref($$s), 'HASH',  "type mutation: hashref assignment";
    is $$s->{b}, 2,       "type mutation: hashref element {b} correct";

    $$s = 99;
    is $$s,    99,  "type mutation: back to plain number";
    ok ! ref($$s),   "type mutation: no longer a reference";
}

# 11. Direct dereferenced mutation $$s->{key} = $val is the only other safe
#     pattern documented in the POD alongside the spread idiom.
{
    my $e = $mod->new(0, sub {});
    my $s = $e->shared_scalar;

    $$s = { initial => 'seed' };

    $$s->{added}   = 'val';
    $$s->{another} = 42;

    is $$s->{initial}, 'seed', "direct mutation: existing key preserved";
    is $$s->{added},   'val',  "direct mutation: new string key added";
    is $$s->{another}, 42,     "direct mutation: new numeric key added";
}

# 12. Mixed nesting: hashref containing an arrayref of hashrefs, with inner
#     arrayrefs at the leaves. Confirms heterogeneous nesting round-trips.
#     SKIPPED in reduced mode: 5+ nested refs = 5+ child sem sets.
if ($can_full) {
    my $e = $mod->new(0, sub {});
    my $s = $e->shared_scalar;

    $$s = {
        users => [
            { name => 'alice', tags => ['admin', 'staff'] },
            { name => 'bob',   tags => ['guest'] },
        ],
    };

    is ref($$s->{users}),          'ARRAY', "mixed nesting: top-level 'users' is ARRAY";
    is ref($$s->{users}[0]),       'HASH',  "mixed nesting: array element is HASH";
    is $$s->{users}[0]{name},      'alice', "mixed nesting: 1st user name correct";
    is ref($$s->{users}[0]{tags}), 'ARRAY', "mixed nesting: inner 'tags' is ARRAY";
    is $$s->{users}[0]{tags}[0],   'admin', "mixed nesting: 1st tag of 1st user correct";
    is $$s->{users}[1]{name},      'bob',   "mixed nesting: 2nd user name correct";
    is $$s->{users}[1]{tags}[0],   'guest', "mixed nesting: 2nd user 1st tag correct";
}

# 13. 5-level nesting: each nested ref allocates its own child shm segment
#     (see shared_scalar POD), so this also exercises deeper segment-per-node
#     allocation and cleanup.
#     SKIPPED in reduced mode: 5-level = 5 child sem sets in one block.
if ($can_full) {
    my $e = $mod->new(0, sub {});
    my $s = $e->shared_scalar;

    $$s = { l1 => { l2 => { l3 => { l4 => { l5 => 'deep_value' } } } } };

    is ref($$s),                       'HASH',       "5-level: level 1 is HASH";
    is ref($$s->{l1}),                 'HASH',       "5-level: level 2 is HASH";
    is ref($$s->{l1}{l2}),             'HASH',       "5-level: level 3 is HASH";
    is ref($$s->{l1}{l2}{l3}),         'HASH',       "5-level: level 4 is HASH";
    is ref($$s->{l1}{l2}{l3}{l4}),     'HASH',       "5-level: level 5 is HASH";
    is $$s->{l1}{l2}{l3}{l4}{l5},      'deep_value', "5-level: leaf value correct";
}

# 14. interval > 0: event writes a counter periodically; parent reads the
#     latest value via shared_scalar while the event runs in the background.
{
    my $s;
    my $e = $mod->new(0.02, sub {
        my $prev = ($$s && $$s->{count}) || 0;
        $$s = { count => $prev + 1 };
    });
    $s = $e->shared_scalar;

    $e->start;

    my $observed = 0;
    my $tries    = 0;
    while ($tries++ < 500) {
        $observed = ($$s && $$s->{count}) || 0;
        last if $observed >= 3;
        select(undef, undef, undef, 0.01);
    }

    $e->stop;

    cmp_ok $observed, '>=', 3,
        "interval mode: parent observed >=3 ticks via shared_scalar (got $observed)";
}

# 15. JSON serializer (IPC::Shareable default) cannot preserve a blessing on
#     cross-process round-trip; the value comes back as a plain HASH ref.
#     Pins the POD warning so we notice if this ever changes upstream.
{
    my $s;
    my $e = $mod->new(0, sub {
        $$s = bless { x => 42 }, 'MyTestClass';
    });
    $s = $e->shared_scalar;

    $e->start;
    $e->wait;

    my $r = eval { ref($$s) } // 'fetch_died';
    isnt $r, 'MyTestClass',
        "blessed object: blessing not preserved cross-process (got=$r) - POD warning";
}

# 16. JSON cannot serialize a CODE ref; either the child callback dies during
#     STORE, or the segment ends up unusable. Either way, the parent cannot
#     get a usable CODE back. Pins the POD warning.
{
    my $s;
    my $e = $mod->new(0, sub {
        $$s = sub { 42 };
    });
    $s = $e->shared_scalar;

    $e->start;
    $e->wait;

    my $r = eval { ref($$s) } // 'fetch_died';
    isnt $r, 'CODE',
        "code ref: not retrievable as CODE cross-process (got=$r, error=" .
        ($e->error ? 1 : 0) . ") - POD warning";
}

# 17. The "Unreliable" pattern documented in the shared_scalar POD: fetch a
#     hashref into a lexical, mutate it, and store it back. Re-storing a
#     tied value into its own parent corrupts the segment; current behavior
#     leaves the hash empty. This test pins that observed behavior so we
#     notice if/when IPC::Shareable changes it.
{
    my $e = $mod->new(0, sub {});
    my $s = $e->shared_scalar;

    $$s = { a => 1, b => 2 };

    my $h = $$s;
    $h->{c} = 3;
    $$s = $h;

    is ref($$s),                          'HASH',
        'mutate-then-store: scalar is still a HASH ref';
    is scalar(keys %{ ref($$s) eq 'HASH' ? $$s : {} }), 0,
        'mutate-then-store: hash ends up empty (pins POD-documented broken pattern)';
}

# 18. Event crash mid-write: the callback writes partial data, then dies.
#     The shared_scalar segment is owned by the event object (still alive),
#     so the partial write survives and the segment remains readable and
#     writable from the parent.
{
    my $s;
    my $e = $mod->new(0, sub {
        $$s = { phase => 'partial' };
        die "callback died after partial write\n";
    });
    $s = $e->shared_scalar;

    $e->start;
    $e->wait;

    ok $e->error,                "crash mid-write: error flag set after callback died";
    is ref($$s),       'HASH',   "crash mid-write: shared_scalar still readable in parent";
    is $$s->{phase},   'partial',"crash mid-write: partial write preserved in segment";

    $$s = { recovered => 1 };
    is $$s->{recovered}, 1,      "crash mid-write: shared_scalar still writable from parent";
}
