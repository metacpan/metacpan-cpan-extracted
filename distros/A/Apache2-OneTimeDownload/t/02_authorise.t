#!/usr/bin/perl
#
# Check we can open the database

# Load our database

use strict;
use MLDBM qw(DB_File);
use Apache2::OneTimeDownload;
use Test::More tests => 4;

my %db; 

my $key = Apache2::OneTimeDownload::authorize( 't/db.db', 'Comm3nt', 'filename', '1075322690');

ok( (tie %db, "MLDBM", 't/db.db'), "t/db.db appears to have been tied"); 

is( $db{$key}->{'file'}, 'filename', "'file' is correct" );
is( $db{$key}->{'comments'}, 'Comm3nt', "'comments' is correct" );
is( $db{$key}->{'expires'}, '1075322690', "'expires' is correct" );

delete $db{$key};

untie %db;

END {

	if ( $ENV{'USER'} eq 'sheriff' ) {

		diag("Blanking the db file...");
		`rm t/db.db; touch t/db.db`;

	}

}

