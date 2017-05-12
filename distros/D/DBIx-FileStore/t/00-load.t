#!perl 
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::FileStore' ) || print "Bail out!\n";
}

diag( "Testing DBIx::FileStore $DBIx::FileStore::VERSION, Perl $], $^X" );

