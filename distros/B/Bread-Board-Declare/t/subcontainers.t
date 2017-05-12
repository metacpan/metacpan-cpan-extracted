#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package SubContainer;
    use Moose;
    use Bread::Board::Declare;

    has foo_sub => (
        is    => 'ro',
        isa   => 'Str',
        value => 'FOOSUB',
    );
}

{
    package Container;
    use Moose;
    use Bread::Board::Declare;

    has subcontainer => (
        traits => ['Container'],
        is     => 'ro',
        isa    => 'SubContainer',
    );
}

{
    package InlineSubContainers;
    use Moose;
    use Bread::Board::Declare;
    use Bread::Board;

    has subcontainer => (
        traits  => ['Container'],
        is      => 'ro',
        isa     => 'Bread::Board::Container',
        default => sub {
            container Foo => as {
                service bar => 'BAR';
            };
        },
    );

    has other_subcontainer => (
        traits  => ['Container'],
        is      => 'ro',
        isa     => 'Bread::Board::Container',
        default => sub {
            container Foo => as {
                service baz => (
                    block => sub {
                        my $s = shift;
                        "other " . $s->param('other_bar');
                    },
                    dependencies => {
                        other_bar => '../subcontainer/bar',
                    },
                );
            },
        },
    );
}

{
    package WithDeps;
    use Moose;
    use Bread::Board::Declare;

    has thing => (
        is    => 'ro',
        isa   => 'Str',
        value => 'THING',
    );

    has other_thing => (
        is           => 'ro',
        isa          => 'Str',
        block        => sub {
            my $s = shift;
            $s->param('foo_sub');
        },
        dependencies => ['sub/foo_sub'],
    );

    has sub => (
        traits       => ['Container'],
        is           => 'ro',
        isa          => 'SubContainer',
        dependencies => {
            foo_sub => 'thing',
        },
    );
}

with_immutable {
    {
        my $c = Container->new;
        is($c->resolve(service => 'subcontainer/foo_sub'), 'FOOSUB');
        isa_ok($c->subcontainer, 'SubContainer');
        is($c->subcontainer->foo_sub, 'FOOSUB');

        my $c2 = Container->new;
        isnt($c->subcontainer, $c2->subcontainer);
    }

    {
        my $c = Container->new(subcontainer => SubContainer->new(foo_sub => 'SUBFOO'));
        is($c->resolve(service => 'subcontainer/foo_sub'), 'SUBFOO');
        isa_ok($c->subcontainer, 'SubContainer');
        is($c->subcontainer->foo_sub, 'SUBFOO');
    }

    {
        my $c = InlineSubContainers->new;

        is($c->resolve(service => 'subcontainer/bar'), 'BAR');
        isa_ok($c->subcontainer, 'Bread::Board::Container');
        is($c->subcontainer->resolve(service => 'bar'), 'BAR');

        is($c->resolve(service => 'other_subcontainer/baz'), 'other BAR');
        isa_ok($c->other_subcontainer, 'Bread::Board::Container');
        is($c->other_subcontainer->resolve(service => 'baz'), 'other BAR');
    }

    {
        my $c = WithDeps->new;
        is($c->resolve(service => 'sub/foo_sub'), 'THING');
        is($c->thing, 'THING');
        is($c->sub->foo_sub, 'THING');
        is($c->other_thing, 'THING');
    }

    {
        my $c = WithDeps->new(thing => 'GNIHT');
        is($c->resolve(service => 'sub/foo_sub'), 'GNIHT');
        is($c->thing, 'GNIHT');
        is($c->sub->foo_sub, 'GNIHT');
        is($c->other_thing, 'GNIHT');
    }
} 'SubContainer', 'Container', 'InlineSubContainers', 'WithDeps';

done_testing;
