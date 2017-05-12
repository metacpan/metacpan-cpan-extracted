#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Moose;

{
    package Bar;
    use Moose;
}

{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    has foo => (
        is  => 'ro',
        isa => 'Str',
    );

    has bar => (
        is      => 'ro',
        isa     => 'Bar',
        service => 0,
    );

    has baz => (
        is           => 'ro',
        isa          => 'Str',
        block        => sub { shift->param('foo') },
        dependencies => ['foo'],
    );

    has quux => (
        is           => 'ro',
        isa          => 'Bar',
        block        => sub { shift->param('bar') },
        dependencies => ['bar'],
    );
}

with_immutable {
{
    my $foo = Foo->new;
    ok($foo->has_service($_), "has service $_") for qw(foo baz);
    ok(!$foo->has_service($_), "doesn't have service $_") for qw(bar);
}

{
    my $foo = Foo->new;
    like(
        exception { $foo->baz },
        qr/^Attribute foo did not specify a service\. It must be given a value through the constructor or writer method before it can be resolved\./,
        "got the right error when foo isn't set"
    );
}

{
    my $foo = Foo->new(foo => 'bar');
    is($foo->baz, 'bar', "didn't get an error when foo is set");
}

{
    my $foo = Foo->new;
    like(
        exception { $foo->quux },
        qr/^Could not find container or service for bar in Foo/,
        "can't depend on attrs with no service"
    );
}
} 'Foo';

done_testing;
