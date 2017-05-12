#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package Baz;
    use Moose;

    has bar => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );
}

my $i;
{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        block => sub { $i++ },
    );

    has baz => (
        is           => 'ro',
        isa          => 'Baz',
        dependencies => ['bar'],
    );
}

with_immutable {
    $i = 0;
    my $foo = Foo->new;
    my $baz = $foo->baz;
    is($baz->bar, '0', "deps resolved correctly");
    is($baz->bar, '0', "doesn't re-resolve, since Baz is a normal class");
    is($foo->baz->bar, '1', "re-resolves since the baz attr isn't a singleton");
} 'Foo';

done_testing;
