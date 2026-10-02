#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Clone qw(clone);
use Scalar::Util qw(refaddr);

# Regression: rv_clone_iterative() walked the RV chain with no hseen check,
# so a scalar-ref cycle reached only past MAX_DEPTH would loop forever and
# OOM (chain[] doubled via Renew until allocation aborted).
#
# A cycle reached BEFORE MAX_DEPTH is caught by the recursive sv_clone path
# via hseen, so the only way to reproduce is to build a long enough linear
# chain to push rdepth past MAX_DEPTH first, then close a back-edge.

my $is_limited_stack = ($^O eq 'MSWin32' || $^O eq 'cygwin');
my $max_depth_val    = $is_limited_stack ? 2000 : 4000;
my $chain_len        = $max_depth_val + 1000;

plan tests => 6;

# Build a linear chain of $chain_len RVs whose leaf is a scalar, then
# splice in a back-edge so the chain becomes cyclic past MAX_DEPTH.
sub build_cyclic_chain {
    my @slots;
    $slots[0] = \"leaf";                       # leaf SV (anchor for slot 0)
    my $r = \$slots[0];                        # RV -> slot 0
    for my $i (1 .. $chain_len) {
        $slots[$i] = $r;                       # slot i holds previous RV
        $r = \$slots[$i];                      # RV -> slot i
    }
    # Close the cycle deep in the chain: slot 0 now points back into slot N/2.
    # Walking SvRV from $r eventually reaches slot 0, which now resolves to
    # slot N/2, looping forever absent a cycle guard.
    $slots[0] = \$slots[ int($chain_len / 2) ];
    return ($r, \@slots);  # return @slots too so it stays alive
}

# Test 1: cyclic deep scalar-ref chain must not hang or OOM
{
    my ($r, $keepalive) = build_cyclic_chain();

    my $clone_ok = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(15);
        my $c = clone($r);
        alarm(0);
        defined $c ? 1 : 0;
    };
    alarm(0);

    ok($clone_ok, "cyclic scalar-ref chain past MAX_DEPTH does not hang/OOM")
        or diag("Error: " . ($@ || "clone returned undef"));
}

# Test 2: clone is a different top-level SV from the original
{
    my ($r, $keepalive) = build_cyclic_chain();
    my $c = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(15);
        my $x = clone($r);
        alarm(0);
        $x;
    };
    alarm(0);

    SKIP: {
        skip "clone failed", 1 unless defined $c;
        isnt(refaddr($c), refaddr($r),
             "cloned cyclic chain top-level RV is a distinct SV");
    }
}

# Test 3: original is unaffected (no in-place mutation during clone)
{
    my ($r, $keepalive) = build_cyclic_chain();
    my $orig_addr = refaddr($r);

    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(15);
        clone($r);
        alarm(0);
    };
    alarm(0);

    is(refaddr($r), $orig_addr, "original chain head SV identity unchanged");
}

# Tests 4-6: a *short* scalar-ref cycle hanging off a deep container spine.
# The spine pushes rdepth past MAX_DEPTH, so the cycle is first seen by the
# iterative path and never gets registered in hseen by the recursive one.
# Before the chain-walk guard was corrected these OOM'd the process.
{
    my $spine_depth = int($max_depth_val / 2) + 1000;

    my %shapes = (
        'self-referential ref'        => sub { my $x; $x = \$x; $x },
        'ref to a self-referential ref' => sub { my $x; $x = \$x; \$x },
        'two-node ref cycle'          => sub { my ($a, $b); $a = \$b; $b = \$a; $a },
    );

    for my $name (sort keys %shapes) {
        my $root = {};
        my $curr = $root;
        for (1 .. $spine_depth) {
            my $next = {};
            $curr->{n} = $next;
            $curr = $next;
        }
        $curr->{cyc} = $shapes{$name}->();

        my $cloned = eval { clone($root) };
        ok(defined($cloned) && ref($cloned) eq 'HASH',
           "$name past MAX_DEPTH clones without OOM")
            or diag("Error: " . ($@ || 'clone returned undef'));
    }
}
