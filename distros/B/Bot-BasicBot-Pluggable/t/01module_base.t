#!/usr/bin/perl
use warnings;
use strict;
use lib qw(./lib);

use Test::More tests => 13;

use Bot::BasicBot::Pluggable;
use Bot::BasicBot::Pluggable::Module;

our $store;
no warnings 'redefine';

sub Bot::BasicBot::Pluggable::Module::store {
    $store ||= Bot::BasicBot::Pluggable::Store->new;
}

ok( my $base = Bot::BasicBot::Pluggable::Module->new(), "created base module" );
ok( $base->var( 'test', 'value' ), "set variable" );
ok( $base->var('test') eq 'value', 'got variable' );

ok( $base = Bot::BasicBot::Pluggable::Module->new(),
    "created new base module" );
ok( $base->var('test') eq 'value', 'got old variable' );

ok( $base->unset('test'),           'unset variable' );
ok( !defined( $base->var('test') ), "it's gone" );

# very hard to do anything but check existence of these methods
ok( $base->can($_), "'$_' exists" ) for (qw(said connected tick emoted init));

ok( $base->help, "help returns something" );
