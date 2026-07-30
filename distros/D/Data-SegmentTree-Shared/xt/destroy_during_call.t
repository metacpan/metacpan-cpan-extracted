use strict; use warnings; use Test::More; use Config; use POSIX ();
use Data::SegmentTree::Shared;

# Adversarial re-entrancy coverage for the identity guard in Shared.xs
# (EXTRACT captures h0 + pins the RV; REEXTRACT re-reads and identity-checks h).
#
# Every instance method fetches its position/range arguments through the POS
# macro, which does SvUV(arg) and *then* dereferences h->n. A tied/overloaded
# argument runs arbitrary Perl during that SvUV; if that Perl DESTROYs the
# invocant (frees the C handle, zeroes the IV) or REPLACES it with a different
# tree, the old code would dereference a freed/foreign handle. REEXTRACT (run
# inside POS, right after the SvUV and before the h->n deref) must instead croak
# cleanly.
#
# Each case runs in a forked child: a signal death (SIGSEGV/SIGBUS) is a crash
# the guard failed to prevent; a non-death (exit 7) means the method ran on
# through without croaking; a croak with the wrong message (exit 8) means the
# guard misfired. Exit 0 = the expected clean croak.
plan skip_all => 'fork required' unless $Config{d_fork};

our $victim;

# (a) argument magic that DESTROYs the invocant mid-SvUV (frees the handle)
{ package Evil::Destroy; use overload
    '0+' => sub { $main::victim->DESTROY; 1 },
    '""' => sub { $main::victim->DESTROY; '1' }, fallback => 1; }

# (b) argument magic that REPLACEs the invocant with a fresh, different tree
{ package Evil::Replace; use overload
    '0+' => sub { $main::victim = Data::SegmentTree::Shared->new(undef, 32); 1 },
    '""' => sub { $main::victim = Data::SegmentTree::Shared->new(undef, 32); '1' }, fallback => 1; }

my $re = qr/replaced or destroyed during the call|replaced during the call/;

# [ name, want-regex, call (reads/writes the package global $victim) ]
my @cases = (
    # --- single-position POS methods, evil as the index arg ---
    ['get(evil): index magic destroys the tree',   $re,
        sub { my $e = bless {}, 'Evil::Destroy'; $victim->get($e) }],
    ['get(evil): index magic replaces the tree',   $re,
        sub { my $e = bless {}, 'Evil::Replace'; $victim->get($e) }],
    ['set(evil,v): index magic destroys the tree', $re,
        sub { my $e = bless {}, 'Evil::Destroy'; $victim->set($e, 5) }],
    ['set(evil,v): index magic replaces the tree', $re,
        sub { my $e = bless {}, 'Evil::Replace'; $victim->set($e, 5) }],
    ['add(evil,d): index magic destroys the tree', $re,
        sub { my $e = bless {}, 'Evil::Destroy'; $victim->add($e, 1) }],

    # --- range methods, evil as the FIRST range bound (first POS/SvUV) ---
    ['range_add(evil,r,d): l magic destroys the tree', $re,
        sub { my $e = bless {}, 'Evil::Destroy'; $victim->range_add($e, 5, 1) }],
    ['sum(evil,r): l magic replaces the tree',         $re,
        sub { my $e = bless {}, 'Evil::Replace'; $victim->sum($e, 5) }],

    # --- range methods, evil as the SECOND range bound (second POS/SvUV) ---
    ['range_assign(l,evil,v): r magic destroys the tree', $re,
        sub { my $e = bless {}, 'Evil::Destroy'; $victim->range_assign(0, $e, 7) }],
    ['query(l,evil): r magic replaces the tree',          $re,
        sub { my $e = bless {}, 'Evil::Replace'; $victim->query(0, $e) }],
    ['gcd(l,evil): r magic destroys the tree',            $re,
        sub { my $e = bless {}, 'Evil::Destroy'; $victim->gcd(0, $e) }],
);

for my $c (@cases) {
    my ($name, $want, $call) = @$c;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    unless ($pid) {
        $victim = Data::SegmentTree::Shared->new(undef, 64);
        my $ok  = eval { $call->(); 1 };
        my $err = $@ // '';
        POSIX::_exit($ok ? 7 : ($err =~ $want ? 0 : 8));
    }
    waitpid $pid, 0;
    my $st = $?;
    ok !($st & 127), "no crash: $name"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "clean croak: $name"
        or diag($st >> 8 == 7 ? 'ran on through the freed/foreign handle'
              : $st >> 8 == 8 ? 'croaked with an unexpected message'
              :                 'unexpected exit ' . ($st >> 8));
}

done_testing;
