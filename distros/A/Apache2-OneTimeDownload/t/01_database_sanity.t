#!/usr/bin/perl
#
# Check we can open the database

# Load our database

use strict;
use MLDBM qw(DB_File);
use Test::More tests => 9;

my %db; 

ok( (tie %db, "MLDBM", 't/db.db'), "t/db.db appears to have been tied"); 

delete $db{'test'};

ok( !$db{'test'}, "'test' is empty" );

$db{'test'} = 'asdf';

is( $db{'test'}, 'asdf', "'test' holds a value for the short-term");

untie %db;

ok( !$db{'test'}, "'test' has lost its value on untie" );

ok( (tie %db, "MLDBM", 't/db.db'), "t/db.db appears to have been tied");

is( $db{'test'}, 'asdf', "'test' holds a value for the long-term");

delete $db{'test'};

ok( !$db{'test'}, "'test' is empty" );

untie %db;

ok( (tie %db, "MLDBM", 't/db.db'), "t/db.db appears to have been tied");

ok( !$db{'test'}, "'test' is empty" );


END {

	if ( $ENV{'USER'} eq 'sheriff' ) {

		diag("Blanking the db file...");
		`rm t/db.db; touch t/db.db`;

	}

}

