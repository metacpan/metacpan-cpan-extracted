#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;

    has bar => (
        is  => 'rw',
        isa => 'Bar',
    );
}

{
    package Bar;
    use Moose;

    has foo => (
        is       => 'rw',
        isa      => 'Foo',
        weak_ref => 1,
    );
}

{
    package MyApp;
    use Moose;
    use Bread::Board::Declare;

    has foo => (
        is    => 'ro',
        isa   => 'Foo',
        block => sub {
            my ($s, $self) = @_;
            Foo->new(bar => $s->param('bar'));
        },
        lifecycle    => 'Singleton',
        dependencies => ['bar'],
    );
    has bar => (
        is    => 'ro',
        isa   => 'Bar',
        block => sub {
            my ($s, $self) = @_;
            Bar->new(foo => $s->param('foo'));
        },
        lifecycle    => 'Singleton',
        dependencies => ['foo'],
    );
}


is exception { MyApp->new->foo->bar }, undef,
    'circular block-injection deps should survive';

done_testing();
