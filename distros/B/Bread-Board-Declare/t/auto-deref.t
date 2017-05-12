#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    has foo => (
        is         => 'ro',
        isa        => 'ArrayRef',
        auto_deref => 1,
        block      => sub { ['foo', 'bar'] },
    );

    has bar => (
        is         => 'ro',
        isa        => 'HashRef',
        auto_deref => 1,
        block      => sub { {'foo' => 'bar'} },
    );
}

with_immutable {
{
    my $foo = Foo->new;

    is_deeply(scalar($foo->foo), ['foo', 'bar'], "scalar array");
    is_deeply([$foo->foo], ['foo', 'bar'], "list array");
    is_deeply(scalar($foo->bar), {'foo', 'bar'}, "scalar hash");
    is_deeply({$foo->foo}, {'foo', 'bar'}, "list hash");
}

{
    my $foo = Foo->new(foo => ['foo', 'bar'], bar => {'foo' => 'bar'});

    is_deeply(scalar($foo->foo), ['foo', 'bar'], "scalar array");
    is_deeply([$foo->foo], ['foo', 'bar'], "list array");
    is_deeply(scalar($foo->bar), {'foo', 'bar'}, "scalar hash");
    is_deeply({$foo->foo}, {'foo', 'bar'}, "list hash");
}
} 'Foo';

done_testing;
