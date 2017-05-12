#!perl -T

use strict;
use warnings;

use lib q(lib);

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Pmhack' );
}

diag( "Testing App::Pmhack $App::Pmhack::VERSION, Perl $], $^X" );
