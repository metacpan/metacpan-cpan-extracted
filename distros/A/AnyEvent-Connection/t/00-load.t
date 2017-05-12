#!/usr/bin/env perl

use common::sense;
use lib::abs '../lib';
use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
	use_ok( 'AnyEvent::Connection' );
}

diag( "Testing AnyEvent::Connection $AnyEvent::Connection::VERSION, Perl $], $^X" );
