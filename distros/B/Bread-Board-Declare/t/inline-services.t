#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    has foo => (
        is  => 'ro',
        isa => 'Str',
        block => sub {
            my ($s) = @_;
            return 'foo' . $s->param('bar') . $s->param('baz');
        },
        dependencies => {
            bar => dep('bar'),
            baz => dep(value => 'zab'),
        },
    );

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        value => 'BAR',
    );
}

is(Foo->new->foo, 'fooBARzab', "inline dependencies resolved properly");

done_testing;
