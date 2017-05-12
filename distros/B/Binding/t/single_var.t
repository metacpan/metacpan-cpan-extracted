#!/usr/bin/env perl -w
use strict;
use Test::More tests => 3;

use Binding;

package Foo;
use UNIVERSAL::isa;

sub new { return bless {} };

sub foo {
    my $self = shift;
    my $x = 3;
    my $y = "How are you";

    bar();
}

sub bar {
    my $caller_self = Binding->of_caller->var('$self');

    Test::More::ok $caller_self->isa("Foo");
}

package main;

sub foo {
    my $x = 3;
    my $y = "How are you";

    bar();
}

sub bar {
    # cab: caller binding.
    my $cab = Binding->of_caller;

    my $x = $cab->var('$x');
    my $y = $cab->var('$y');

    is $x, 3;
    is $y, "How are you";
}

foo();

my $o = Foo->new;
$o->foo();
