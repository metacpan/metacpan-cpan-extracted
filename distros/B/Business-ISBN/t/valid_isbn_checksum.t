#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

require_ok( 'Business::ISBN' );

ok( defined &Business::ISBN::valid_isbn_checksum, "Defined in module" );

Business::ISBN->import( 'valid_isbn_checksum' );

ok( defined &valid_isbn_checksum, "Defined in main" );

is( valid_isbn_checksum( '0596527241'    ), 1, "Good ISBN10 passes" );
is( valid_isbn_checksum( '9780596527242' ), 1, "Good ISBN13 passes" );

is( valid_isbn_checksum( '059652724X'    ), 0, "Bad ISBN10 fails (good)" );
is( valid_isbn_checksum( '9780596527243' ), 0, "Bad ISBN13 fails (good)" );
