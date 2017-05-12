#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ActiveRecord::Simple' ) || print "Bail out!\n";
}

diag( "Testing ActiveRecord::Simple $ActiveRecord::Simple::VERSION, Perl $], $^X" );
