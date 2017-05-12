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
        is    => 'ro',
        isa   => 'Str',
        value => 'FOO',
    );

    has bar => (
        is => 'ro',
        isa => 'Str',
        block => sub {
            my $s = shift;
            return $s->param('foo') . 'BAR';
        },
        dependencies => ['foo'],
    );
}

with_immutable {
    my $foo = Foo->new;
    my $foo_attr = $foo->meta->get_attribute('foo');
    my $bar_attr = $foo->meta->get_attribute('bar');
    is($foo_attr->get_value($foo), 'FOO', "right value");
    is($bar_attr->get_value($foo), 'FOOBAR', "right value");
    ok(!$foo_attr->has_value($foo), "no value");
    ok(!$bar_attr->has_value($foo), "no value");
} 'Foo';

done_testing;
