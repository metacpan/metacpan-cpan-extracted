use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

$INC{'Foo.pm'}++;
$INC{'Bar.pm'}++;

package Foo;

sub init {
    my ( $class, $c ) = @_;
    $c->add_method( foo => \&_foo );
}

sub _foo { 'Foo foo' }

package Bar;

sub init {
    my ( $class, $c ) = @_;
    $c->add_method( foo => \&_foo );
}

sub _foo { 'Foo foo' }

package my_plugin;
use parent 'Blosxom::Plugin';

package main;

throws_ok { my_plugin->load_components('+Foo', '+Bar') }
    qr/^Due to a method name conflict between components/;
