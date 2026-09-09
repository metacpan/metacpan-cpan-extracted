#!perl
# The runtime path: a non-constant operand becomes an immutable copy.
use 5.038;
use strict;
use warnings;
use Test::More;
use Confold;

plan tests => 9;

# Perl aliases @_ to the caller's variables, so an ordinary argument can be
# modified by the sub it is passed to. One marked with <: cannot.
sub clobber { $_[0] = "changed" }

{
    my $open = "original";
    clobber($open);
    is $open, "changed", 'control: a plain argument is modifiable through @_';
}

{
    my $shut = "original";
    my $err = !eval { clobber(<: $shut); 1 } ? $@ : '';
    like $err, qr/read-only/i, '<: argument dies on modification';
    is $shut, "original", '<: argument left the original untouched';
}

{
    my $v = "value";
    my $c = <: $v;
    is $c, "value", 'the copy carries the value';
    $v = "moved on";
    is $c, "value", 'the copy is independent of the original';
}

{
    # Assigning the copy onward yields an ordinary modifiable variable: the
    # immutability belongs to the value produced, not to whatever it lands in.
    my $v = "value";
    my $c = <: $v;
    my $ok = eval { $c = "reassigned"; 1 };
    ok $ok, 'assigning the copy into a lexical leaves that lexical writable';
}

{
    # newSVsv() gets magic itself, so an explicit SvGETMAGIC before it would
    # FETCH twice where a plain copy FETCHes once.
    package Confold::Test::Tied;
    sub TIESCALAR { bless { n => 0 }, shift }
    sub FETCH     { my $s = shift; $s->{n}++; "fetched" }

    package main;
    tie my $t, 'Confold::Test::Tied';
    my $got = <: $t;
    is $got, "fetched", 'a tied operand reads correctly';
    is tied($t)->{n}, 1, 'a tied operand is FETCHed exactly once';
}

{
    my $undef;
    no warnings 'uninitialized';
    my $c = <: $undef;
    ok !defined $c, 'an undefined operand copies as undef';
}
