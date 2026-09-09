#!perl
# The behaviour originally covered by perl's own t/op/confold.t.
use 5.038;
use strict;
use warnings;
use Test::More;
use Confold;

plan tests => 12;

{
    my $x = <: 42;
    is $x, 42, '<: with integer literal';
}

{
    my $s = <: "hello";
    is $s, "hello", '<: with string literal';
}

{
    my $f = <: 3.14159;
    is $f, 3.14159, '<: with float literal';
}

{
    my $var = "dynamic";
    my $c = <: $var;
    is $c, "dynamic", '<: with variable (runtime path)';
}

{
    my $x = <: 100;
    is $x, 100, '<: literal is folded at compile time';
}

{
    my $a = <: 1;
    my $b = <: 2;
    my $c = <: 3;
    is $a + $b + $c, 6, 'multiple <: expressions';
}

{
    my $a = 10;
    my $b = 20;
    my $sum = <: ($a + $b);
    is $sum, 30, '<: with expression (runtime path)';
}

{
    my @arr = (<: 1, <: 2, <: 3);
    is "@arr", "1 2 3", '<: in list context';
}

{
    my $neg = <: -42;
    is $neg, -42, '<: with negative literal';
}

{
    my $empty = <: "";
    is $empty, "", '<: with empty string';
}

{
    my $zero = <: 0;
    is $zero, 0, '<: with zero';
    ok defined($zero), '<: zero is defined';
}
