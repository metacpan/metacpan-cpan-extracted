#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Moose;

{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    has foo => (
        is    => 'ro',
        isa   => 'Ref',
        value => 'FOO',
    );

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        block => sub { { foo => 'bar' } },
    );

    has baz => (
        is           => 'ro',
        isa          => 'HashRef',
        block        => sub { shift->param('bar') },
        dependencies => ['bar'],
    );
}

with_immutable {
    my $foo = Foo->new;
    like(exception { $foo->foo },
        qr/^Attribute \(foo\) does not pass the type constraint because: Validation failed for 'Ref' with value .*FOO/,
         "error when service returns invalid value");
    like(exception { $foo->bar },
        qr/^Attribute \(bar\) does not pass the type constraint because: Validation failed for 'Str' with value .*(?:HASH|foo.*bar)/,
         "error when service returns invalid value");
    like(exception { $foo->baz },
        qr/^Attribute \(bar\) does not pass the type constraint because: Validation failed for 'Str' with value .*(?:HASH|foo.*bar)/,
         "error when service returns invalid value, even as a dependency");
} 'Foo';

done_testing;
