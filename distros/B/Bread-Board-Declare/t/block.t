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
        is      => 'ro',
        isa     => 'Str',
        default => 'FOO',
    );

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        value => 'BAR',
    );

    has baz => (
        is           => 'ro',
        isa          => 'Str',
        block        => sub {
            my ($s, $self) = @_;
            return $s->param('bar') . $self->foo;
        },
        dependencies => ['bar'],
    );
}

with_immutable {
    my $foo = Foo->new;
    is($foo->baz, 'BARFOO', "self is passed properly");
} 'Foo';

done_testing;
