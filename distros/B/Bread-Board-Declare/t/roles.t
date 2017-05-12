#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package Role1;
    use Moose::Role;
    use Bread::Board::Declare;

    has role1 => (
        is     => 'ro',
        isa    => 'Str',
        value  => 'ROLE1',
    );
}

{
    package Parent;
    use Moose;
    use Bread::Board::Declare;

    with 'Role1';

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
            return $s->param('foo') . 'BAR' . $s->param('role1');
        },
        dependencies => ['foo', 'role1'],
    );
}

{
    package Role2;
    use Moose::Role;
    use Bread::Board::Declare;

    has role2 => (
        is     => 'ro',
        isa    => 'Str',
        value  => 'ROLE2',
    );
}

{
    package Child;
    use Moose;
    use Bread::Board::Declare;

    extends 'Parent';
    with 'Role2';

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
                 . $s->param('role1')
                 . $s->param('role2')
                 . 'QUUX';
        },
        dependencies => ['foo', 'bar', 'baz', 'role1', 'role2'],
    );
}

with_immutable {
{
    my $parent = Parent->new;
    ok($parent->has_service('role1'), "parent has role1");
    ok($parent->has_service('foo'), "parent has foo");
    ok($parent->has_service('bar'), "parent has bar");

    my $child = Child->new;
    ok($child->has_service('role1'), "child has role1");
    ok($child->has_service('foo'), "child has foo");
    ok($child->has_service('bar'), "child has bar");
    ok($child->has_service('role2'), "child has role2");
    ok($child->has_service('baz'), "child has baz");
    ok($child->has_service('quux'), "child has quux");
}

{
    my $parent = Parent->new;
    isa_ok($parent, 'Bread::Board::Container');
    is($parent->role1, 'ROLE1');
    is($parent->foo, 'FOO');
    is($parent->bar, 'FOOBARROLE1');
}

{
    my $parent = Parent->new(role1 => '1ELOR', foo => 'OOF', bar => 'RAB');
    isa_ok($parent, 'Bread::Board::Container');
    is($parent->role1, '1ELOR');
    is($parent->foo, 'OOF');
    is($parent->bar, 'RAB');
}

{
    my $parent = Parent->new(role1 => '1ELOR', foo => 'OOF');
    isa_ok($parent, 'Bread::Board::Container');
    is($parent->role1, '1ELOR');
    is($parent->foo, 'OOF');
    is($parent->bar, 'OOFBAR1ELOR');
}

{
    my $child = Child->new;
    is($child->role1, 'ROLE1');
    is($child->foo, 'FOO');
    is($child->bar, 'FOOBARROLE1');
    is($child->role2, 'ROLE2');
    is($child->baz, 'BAZ');
    is($child->quux, 'FOOFOOBARROLE1BAZROLE1ROLE2QUUX');
}

{
    my $child = Child->new(
        role1 => '1ELOR',
        foo   => 'OOF',
        bar   => 'RAB',
        role2 => '2ELOR',
        baz   => 'ZAB',
        quux  => 'XUUQ',
    );
    is($child->role1, '1ELOR');
    is($child->foo, 'OOF');
    is($child->bar, 'RAB');
    is($child->role2, '2ELOR');
    is($child->baz, 'ZAB');
    is($child->quux, 'XUUQ');
}

{
    my $child = Child->new(
        role1 => '1ELOR',
        foo   => 'OOF',
        role2 => '2ELOR',
        baz   => 'ZAB',
    );
    is($child->role1, '1ELOR');
    is($child->foo, 'OOF');
    is($child->bar, 'OOFBAR1ELOR');
    is($child->role2, '2ELOR');
    is($child->baz, 'ZAB');
    is($child->quux, 'OOFOOFBAR1ELORZAB1ELOR2ELORQUUX');
}
} 'Parent', 'Child';

done_testing;
