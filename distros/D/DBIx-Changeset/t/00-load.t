#!perl -T

use Test::More tests => 2;

### test we can load the Exception Class
BEGIN {
	use_ok( 'DBIx::Changeset::Exception' );
}

BEGIN {
	use_ok( 'DBIx::Changeset' );
}

diag( "Testing DBIx::Changeset $DBIx::Changeset::VERSION, Perl $], $^X" );

