#!/usr/bin/env perl -w

use lib::abs "../lib";
use Test::More tests => 3;
use Test::NoWarnings;

BEGIN {
	use_ok( 'AnyEvent::Worker' );
	use_ok( 'AnyEvent::Worker::Pool' );
}

diag( "Testing AnyEvent::Worker $AnyEvent::Worker::VERSION, using AnyEvent $AnyEvent::VERSION, Perl $], $^X" );
