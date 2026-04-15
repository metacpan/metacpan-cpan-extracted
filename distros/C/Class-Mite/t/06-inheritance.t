#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# ----------------------------------------------------------------------
# Test 1: Multi-level BUILD execution (linear inheritance)
# ----------------------------------------------------------------------
{
    package BaseA;
    use Class;
    our @CALLS;
    sub BUILD { push @CALLS, 'A' }
}

{
    package BaseB;
    use Class;
    our @CALLS;
    sub BUILD { push @CALLS, 'B' }
}

{
    package Derived;
    use Class;
    extends 'BaseA';
    extends 'BaseB';
    our @CALLS;
    sub BUILD { push @CALLS, 'Derived' }
}

my $obj = Derived->new;
is_deeply(
    [@BaseA::CALLS, @BaseB::CALLS, @Derived::CALLS],
    ['A','B','Derived'],
    'BUILD hooks called once in proper MRO order'
);

# ----------------------------------------------------------------------
# Test 2: Diamond inheritance (no duplicate BUILD calls)
# ----------------------------------------------------------------------
{
    package Top;
    use Class;
    our @CALLS;
    sub BUILD { push @CALLS, 'Top' }
}

{
    package Left;
    use Class;
    extends 'Top';
    our @CALLS;
    sub BUILD { push @CALLS, 'Left' }
}

{
    package Right;
    use Class;
    extends 'Top';
    our @CALLS;
    sub BUILD { push @CALLS, 'Right' }
}

{
    package Bottom;
    use Class;
    extends 'Left';
    extends 'Right';
    our @CALLS;
    sub BUILD { push @CALLS, 'Bottom' }
}

my $bottom = Bottom->new;
is_deeply(
    [@Top::CALLS, @Left::CALLS, @Right::CALLS, @Bottom::CALLS],
    ['Top','Left','Right','Bottom'],
    'Diamond inheritance calls BUILD once per class'
);

# ----------------------------------------------------------------------
# Test 3: Inline package without .pm file
# ----------------------------------------------------------------------
{
    package InlineParent;
    use Class;
    sub BUILD { $_[0]->{x} = 42 }
}

{
    package InlineChild;
    use Class;
    extends 'InlineParent';
}

my $child = InlineChild->new;
is($child->{x}, 42, 'Inline parent BUILD executed without .pm file');

# ----------------------------------------------------------------------
# Test 4: Recursive inheritance prevention
# ----------------------------------------------------------------------
{
    package SelfExtend;
    use Class;
    eval { extends 'SelfExtend' };
}
like($@, qr/Recursive inheritance detected/, 'Cannot extend itself');

# ----------------------------------------------------------------------
# Test 5: Multi-parent inheritance (multiple inheritance)
# ----------------------------------------------------------------------
{
    package Parent1;
    use Class;
    sub BUILD { $_[0]->{a} = 1 }
}

{
    package Parent2;
    use Class;
    sub BUILD { $_[0]->{b} = 2 }
}

{
    package ChildMulti;
    use Class;
    extends 'Parent1';
    extends 'Parent2';
}

my $c = ChildMulti->new;
is($c->{a}, 1, 'Parent1 BUILD executed');
is($c->{b}, 2, 'Parent2 BUILD executed');

done_testing();
