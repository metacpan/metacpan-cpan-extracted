#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Clone qw(clone);

# Regression: rv_clone_iterative() called newSVsv() unconditionally for any
# non-AV/HV leaf.  When the leaf was a non-cloneable type (CV, GV, IO, FM,
# LV, BM/REGEXP), sv_setsv croaked ("Bizarre copy of CODE in subroutine
# entry") or produced nonsense.  These types should be shared via
# SvREFCNT_inc, mirroring the regular sv_clone() switch (Clone.xs, the
# PVCV/PVGV/PVFM/PVIO branch).

my $is_limited_stack = ($^O eq 'MSWin32' || $^O eq 'cygwin');
my $max_depth_val    = $is_limited_stack ? 2000 : 4000;
my $chain_len        = $max_depth_val + 1000;

plan tests => 4;

# Build a linear chain of $chain_len RVs ending at $leaf, returning the
# top-of-chain RV plus a keepalive for the slot array.
sub build_chain {
    my ($leaf) = @_;
    my @slots;
    $slots[0] = $leaf;
    my $r = \$slots[0];
    for my $i (1 .. $chain_len) {
        $slots[$i] = $r;
        $r = \$slots[$i];
    }
    return ($r, \@slots);
}

# Test 1+2: deep chain to a CODE ref must not croak
{
    my $cv = sub { 42 };
    my ($r, $keep) = build_chain($cv);

    my $c = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(15);
        my $x = clone($r);
        alarm(0);
        $x;
    };
    alarm(0);

    ok(!$@, "RV chain with CODE leaf clones without croaking")
        or diag("Error: $@");
    ok(defined $c, "CODE-leaf chain clone result is defined");
}

# Test 3: deep chain to a GLOB must not croak
{
    my $gv = \*main::STDERR;
    my ($r, $keep) = build_chain($gv);

    my $ok = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(15);
        my $c = clone($r);
        alarm(0);
        defined $c;
    };
    alarm(0);

    ok($ok, "RV chain with GLOB leaf clones without croaking")
        or diag("Error: $@");
}

# Test 4: deep chain to an IO handle must not croak
{
    open my $fh, '<', $0 or die "open self: $!";
    my $io = *$fh{IO};
    my ($r, $keep) = build_chain(\$io);

    my $ok = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(15);
        my $c = clone($r);
        alarm(0);
        defined $c;
    };
    alarm(0);
    close $fh;

    ok($ok, "RV chain with IO-handle leaf clones without croaking")
        or diag("Error: $@");
}
