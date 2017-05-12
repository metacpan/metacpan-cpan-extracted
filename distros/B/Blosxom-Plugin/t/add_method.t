use strict;
use warnings;
use Test::More tests => 2;

$INC{'MyComponent.pm'}++;

package MyComponent;

sub init {
    my ( $class, $c ) = @_;
    $c->add_method( foo => \&_foo );
    $c->add_method( bar => \&_bar );
}

sub _foo { 'MyComponent foo' }
sub _bar { 'MyComponent bar' }

package my_plugin;
use parent 'Blosxom::Plugin';
__PACKAGE__->load_components( '+MyComponent' );

sub foo { 'my_plugin foo' }

package main;

my $plugin = 'my_plugin';
is $plugin->foo, 'my_plugin foo', 'cannot override methods';
is $plugin->bar, 'MyComponent bar', 'add method';
