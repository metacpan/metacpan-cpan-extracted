#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::CouchDB' ) || print "Bail out!\n";
}

diag( "Testing Data::CouchDB $Data::CouchDB::VERSION, Perl $], $^X" );
