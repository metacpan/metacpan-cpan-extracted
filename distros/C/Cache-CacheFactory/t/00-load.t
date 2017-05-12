#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Cache::CacheFactory' );
}

diag( "Testing Cache::CacheFactory $Cache::CacheFactory::VERSION, Perl $], $^X" );
