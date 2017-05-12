#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package Baz;
    use Moose;
}

my $i;
{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    use Bread::Board::Declare;

    has foo => (
        is      => 'ro',
        isa     => 'Str',
        default => 'FOO',
    );

    subtype 'ArrayRefOfStr', as 'ArrayRef[Str]';
    coerce 'ArrayRefOfStr', from 'Str', via { [$_] };

    has bar => (
        is     => 'ro',
        isa    => 'ArrayRefOfStr',
        coerce => 1,
        value  => 'BAR',
    );

    has baz => (
        is  => 'ro',
        isa => 'Baz',
    );

    has baz2 => (
        is      => 'ro',
        isa     => 'Baz',
        service => 0,
    );

    has quux => (
        is    => 'ro',
        isa   => 'Str',
        block => sub { 'QUUX' . $i++ },
    );
}

with_immutable {
$i = 0;
{
    my $foo = Foo->new;
    isa_ok($foo, 'Bread::Board::Container');
    ok($foo->has_service($_), "has service $_")
        for qw(foo bar baz quux);
    ok(!$foo->has_service($_), "doesn't have service $_")
        for qw(baz2);
    isa_ok($foo->fetch('bar'), 'Bread::Board::Declare::Literal');
    isa_ok($foo->fetch('baz'), 'Bread::Board::Declare::ConstructorInjection');
    isa_ok($foo->fetch('quux'), 'Bread::Board::Declare::BlockInjection');
}

{
    my $foo = Foo->new;
    is($foo->foo, 'FOO', "normal attrs work");
    is_deeply($foo->bar, ['BAR'], "literals work");
    isa_ok($foo->baz, 'Baz');
    isnt($foo->baz, $foo->baz, "new instance each time");
    is($foo->quux, 'QUUX0', "block injections work");
    is($foo->quux, 'QUUX1', "and they are run on each access");
}

{
    my $baz = Baz->new;
    my $foo = Foo->new(
        foo  => 'OOF',
        bar  => 'RAB',
        baz  => $baz,
        quux => 'XUUQ',
    );
    is($foo->foo, 'OOF', "normal attrs work from constructor");
    is_deeply($foo->bar, ['RAB'], "constructor overrides literals");
    isa_ok($foo->baz, 'Baz');
    is($foo->baz, $baz, "constructor overrides constructor injections");
    is($foo->baz, $foo->baz, "and returns the same thing each time");
    is($foo->quux, 'XUUQ', "constructor overrides block injections");
    is($foo->quux, 'XUUQ', "and returns the same thing each time");
}
} 'Foo';

done_testing;
