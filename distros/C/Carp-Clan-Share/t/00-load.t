#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Carp::Clan::Share' );
}

diag( "Testing Carp::Clan::Share $Carp::Clan::Share::VERSION, Perl $], $^X" );
