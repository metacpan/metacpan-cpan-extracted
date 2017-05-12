#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    has foo => (
        is    => 'ro',
        isa   => 'Inferred::Foo',
        infer => 1,
    );

    has bar => (
        is  => 'ro',
        isa => 'Inferred::Bar',
    );
}

{
    my $c = Foo->new;
    isa_ok($c->foo, 'Inferred::Foo');
    isa_ok($c->foo->bar, 'Inferred::Bar');
    isa_ok($c->bar, 'Inferred::Bar');
}

done_testing;
