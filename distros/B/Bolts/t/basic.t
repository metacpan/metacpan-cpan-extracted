#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 17;

use Bolts::Util qw( locator_for );

{
    package Foo;
    use Moose;

    has id => (
        is          => 'ro',
        isa         => 'Int',
        lazy_build  => 1,
    );

    my $counter = 1;
    sub _build_id { $counter++ }

    __PACKAGE__->meta->make_immutable;
}

{
    package Bar;
    use Moose;
}

{
    package Artifacts;
    use Bolts;
    
    artifact 'acquired';

    artifact literal => 42;

    artifact class => (
        class => 'Foo',
    );

    artifact singleton_class => (
        class => 'Foo',
        scope => 'singleton',
    );

    bag 'bag' => contains {
        artifact class => (
            class => 'Foo',
        );
        
        artifact bad_class => (
            class => 'Bar',
        );
    } such_that_each {
        isa => 'Foo',
    };

    __PACKAGE__->meta->make_immutable;
}

my $locator = Artifacts->new( acquired => 'something' );;
#diag explain $locator;
ok($locator);

ok($locator->meta);

my %artifacts = $locator->meta->list_artifacts;
is(scalar keys %artifacts, 5);
isa_ok($artifacts{$_}, 'Bolts::Artifact') for qw(
    acquired literal class singleton_class
);
isa_ok($artifacts{bag}, 'Bolts::Artifact::Thunk');

# Via the acquire method
is($locator->acquire('acquired'), 'something');
is($locator->acquire('literal'), 42);
is($locator->acquire('class')->id, 1);
is($locator->acquire('class')->id, 2);
is($locator->acquire('singleton_class')->id, 3);
is($locator->acquire('singleton_class')->id, 3);
is($locator->acquire('bag', 'class')->id, 4);
is($locator->acquire('bag', 'class')->id, 5);

eval {
    $locator->acquire('bag', 'bad_class');
};

like($@, qr{^Constructed artifact .*? has the wrong type}, 'bad class is bad');

