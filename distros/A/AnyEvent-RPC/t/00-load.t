#!/usr/bin/env perl

use common::sense;
use Test::More tests => 2;
use Test::NoWarnings;
use lib::abs '../lib';
BEGIN {
	use_ok( 'AnyEvent::RPC' );
}

diag( "Testing AnyEvent::RPC $AnyEvent::RPC::VERSION, using AnyEvent $AnyEvent::VERSION, Perl $], $^X" );
