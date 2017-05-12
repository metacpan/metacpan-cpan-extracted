use strict;
use warnings;
use Test::More tests => 1;

# Stolen from Amon2

$INC{ "My/Component/$_.pm" }++ for 1..4;

my @got;

package My::Component;

sub init {
    my ( $class, $caller, $config ) = @_;
    push @got, [ $class, $caller, $config ];
}

package My::Component::1;
use parent -norequire, 'My::Component';

sub init {
    my ( $class, $caller, $config ) = @_;
    $caller->add_component( '+My::Component::2' );
    $class->SUPER::init( $caller, $config );
}

package My::Component::2;
use parent -norequire, 'My::Component';

sub init {
    my ( $class, $caller, $config ) = @_;
    $caller->add_component( '+My::Component::1' );
    $class->SUPER::init( $caller, $config );
}

package My::Component::3;
use parent -norequire, 'My::Component';

package MyPlugin;
use parent 'Blosxom::Plugin';

__PACKAGE__->load_components(
    '+My::Component::1',
    '+My::Component::2' => +{ opt => 2 },
    '+My::Component::3',
);

package main;

is_deeply \@got, [
    [ 'My::Component::1', 'MyPlugin', undef        ],
    [ 'My::Component::2', 'MyPlugin', { opt => 2 } ],
    [ 'My::Component::3', 'MyPlugin', undef        ],
];
