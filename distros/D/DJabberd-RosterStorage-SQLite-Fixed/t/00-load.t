#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DJabberd::RosterStorage::SQLite::Fixed' );
}

diag( "Testing DJabberd::RosterStorage::SQLite::Fixed $DJabberd::RosterStorage::SQLite::Fixed::VERSION, Perl $], $^X" );
