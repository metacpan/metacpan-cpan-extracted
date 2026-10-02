#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Clone qw(clone);

# Tests for correct handling of shared SVs during cloning.
# When the same SV is reachable from multiple paths in a data structure,
# Clone must detect this (via the "seen" hash) and return the same cloned
# copy for both paths — otherwise the clone's internal topology differs
# from the original.

# --- Shared scalar references ---
{
    my $val = "shared";
    my $ref = \$val;
    my $data = { a => $ref, b => $ref };

    my $c = clone($data);
    is($c->{a}, $c->{b}, "shared scalar ref: both paths get same clone");
    isnt($c->{a}, $data->{a}, "shared scalar ref: clone differs from original");
    is(${$c->{a}}, "shared", "shared scalar ref: value preserved");

    # Mutating one path affects the other in the clone (same underlying SV)
    ${$c->{a}} = "modified";
    is(${$c->{b}}, "modified", "shared scalar ref: mutation visible via both paths");
    is($$ref, "shared", "shared scalar ref: original unchanged");
}

# --- Shared hash reference ---
{
    my $inner = { x => 1 };
    my $data = [ $inner, $inner ];

    my $c = clone($data);
    is($c->[0], $c->[1], "shared hash ref: both array slots get same clone");
    isnt($c->[0], $data->[0], "shared hash ref: clone differs from original");

    $c->[0]{x} = 99;
    is($c->[1]{x}, 99, "shared hash ref: mutation visible via both slots");
    is($inner->{x}, 1, "shared hash ref: original unchanged");
}

# --- Shared array reference ---
{
    my $arr = [10, 20, 30];
    my $data = { first => $arr, second => $arr };

    my $c = clone($data);
    is($c->{first}, $c->{second}, "shared array ref: same clone");
    push @{$c->{first}}, 40;
    is(scalar @{$c->{second}}, 4, "shared array ref: mutation visible");
    is(scalar @$arr, 3, "shared array ref: original unchanged");
}

# --- Shared blessed object ---
{
    package SharedObj;
    sub new { bless { id => $_[1] }, $_[0] }
    package main;

    my $obj = SharedObj->new(42);
    my $data = { ref1 => $obj, ref2 => $obj, nested => { deep => $obj } };

    my $c = clone($data);
    is($c->{ref1}, $c->{ref2}, "shared blessed obj: ref1 == ref2 in clone");
    is($c->{ref1}, $c->{nested}{deep}, "shared blessed obj: nested path too");
    isa_ok($c->{ref1}, "SharedObj");
    is($c->{ref1}{id}, 42, "shared blessed obj: value preserved");
}

# --- Shared SV with weak references ---
# The target HV has one strong ref and one weak ref from within the
# structure.  Both must resolve to the same cloned HV.
BEGIN {
    eval 'use Scalar::Util qw(weaken isweak); 1'
        or plan skip_all => "Scalar::Util required for weak ref tests";
}

{
    my $target = { payload => "data" };
    my $data = { strong => $target, weak => $target };
    weaken($data->{weak});

    my $c = clone($data);
    ok(defined $c->{weak}, "shared + weak: weak ref survives (strong ref in clone)");
    is($c->{strong}, $c->{weak}, "shared + weak: both paths resolve to same clone");
    ok(!isweak($c->{strong}), "shared + weak: strong remains strong");
    ok(isweak($c->{weak}), "shared + weak: weak remains weak");
}

# --- Weak-ref target reachable via strong ref from deeper path ---
# The parent HV is the target of a weak ref and also reachable via
# a strong ref chain.  Clone must detect the HV in the seen-hash
# even though HV weakref backrefs use HvAUX (SvOOK), not MAGIC.
{
    my $parent = bless { tag => "parent" }, "Node";
    my $child  = bless { up => $parent, tag => "child" }, "Node";
    weaken($child->{up});
    $parent->{down} = $child;

    my $c = clone($parent);
    ok(defined $c->{down}{up}, "HV weakref target: weak ref survives");
    is($c->{down}{up}, $c, "HV weakref target: weak ref points to cloned parent");
    ok(isweak($c->{down}{up}), "HV weakref target: ref is still weak");
    is($c->{tag}, "parent", "HV weakref target: parent data preserved");
    is($c->{down}{tag}, "child", "HV weakref target: child data preserved");
}

# --- Array as weakref target ---
# Unlike HVs, arrays store backrefs via PERL_MAGIC_backref (SvMAGICAL).
{
    my $arr = [1, 2, 3];
    my $data = { strong => $arr, weak => $arr };
    weaken($data->{weak});

    my $c = clone($data);
    ok(defined $c->{weak}, "array weakref target: weak ref survives");
    is($c->{strong}, $c->{weak}, "array weakref target: same clone");
    ok(isweak($c->{weak}), "array weakref target: still weak");
}

# --- Scalar as weakref target ---
{
    my $obj = bless \(my $x = 42), "ScalarObj";
    my $data = { strong => $obj, weak => $obj };
    weaken($data->{weak});

    my $c = clone($data);
    ok(defined $c->{weak}, "scalar weakref target: weak ref survives");
    is($c->{strong}, $c->{weak}, "scalar weakref target: same clone");
    ok(isweak($c->{weak}), "scalar weakref target: still weak");
}

done_testing;
