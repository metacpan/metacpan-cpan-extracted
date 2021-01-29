#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
	use_ok( 'AnyEvent::Discord' );
}

diag( "Testing AnyEvent::Discord $AnyEvent::Discord::VERSION, Perl $], $^X" );
