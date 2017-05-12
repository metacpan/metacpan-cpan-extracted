#!/usr/bin/env perl

use common::sense;
use lib::abs '../lib';
use Test::More tests => 1;

BEGIN {
	use_ok( 'AnyEvent::DBD::Pg' );
}

diag( "Testing AnyEvent::DBD::Pg $AnyEvent::DBD::Pg::VERSION, Perl $], $^X" );

exit 0;
require Test::NoWarnings;
