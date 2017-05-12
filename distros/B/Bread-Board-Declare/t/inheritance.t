#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Fatal;

{
    package Parent;
    use Moose;
    use Bread::Board::Declare;

    has foo => (
        is    => 'ro',
        isa   => 'Str',
        value => 'FOO',
    );

    has bar => (
        is    => 'ro',
        isa   => 'Str',
        block => sub {
            my $s = shift;
            return $s->param('foo') . 'BAR';
        },
        dependencies => ['foo'],
    );
}

{
    package Child;
    use Moose;
    use Bread::Board::Declare;

    extends 'Parent';

    has baz => (
        is    => 'ro',
        isa   => 'Str',
        value => 'BAZ',
    );

    has quux => (
        is    => 'ro',
        isa   => 'Str',
        block => sub {
            my $s = shift;
            return $s->param('foo')
                 . $s->param('bar')
                 . $s->param('baz')
                 . 'QUUX';
        },
        dependencies => ['foo', 'bar', 'baz'],
    );
}

with_immutable {
{
    my $parent = Parent->new;
    ok($parent->has_service('foo'), "parent has foo");
    ok($parent->has_service('bar'), "parent has bar");

    my $child = Child->new;
    ok($child->has_service('foo'), "child has foo");
    ok($child->has_service('bar'), "child has bar");
    ok($child->has_service('baz'), "child has baz");
    ok($child->has_service('quux'), "child has quux");
}

{
    my $parent = Parent->new;
    isa_ok($parent, 'Bread::Board::Container');
    is($parent->foo, 'FOO');
    is($parent->bar, 'FOOBAR');
}

{
    my $parent = Parent->new(foo => 'OOF', bar => 'RAB');
    isa_ok($parent, 'Bread::Board::Container');
    is($parent->foo, 'OOF');
    is($parent->bar, 'RAB');
}

{
    my $parent = Parent->new(foo => 'OOF');
    isa_ok($parent, 'Bread::Board::Container');
    is($parent->foo, 'OOF');
    is($parent->bar, 'OOFBAR');
}

{
    my $child = Child->new;
    is($child->foo, 'FOO');
    is($child->bar, 'FOOBAR');
    is($child->baz, 'BAZ');
    is($child->quux, 'FOOFOOBARBAZQUUX');
}

{
    my $child = Child->new(
        foo  => 'OOF',
        bar  => 'RAB',
        baz  => 'ZAB',
        quux => 'XUUQ',
    );
    is($child->foo, 'OOF');
    is($child->bar, 'RAB');
    is($child->baz, 'ZAB');
    is($child->quux, 'XUUQ');
}

{
    my $child = Child->new(
        foo  => 'OOF',
        baz  => 'ZAB',
    );
    is($child->foo, 'OOF');
    is($child->bar, 'OOFBAR');
    is($child->baz, 'ZAB');
    is($child->quux, 'OOFOOFBARZABQUUX');
}
} 'Parent', 'Child';

{
    package FromDisk::Sub;
    use Moose;
    use Bread::Board::Declare;
    use lib 't/lib';

    ::is(::exception { extends 'FromDisk' }, undef);
}

done_testing;
