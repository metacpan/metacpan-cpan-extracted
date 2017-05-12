#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Class::Monkey' ) || print "Bail out!\n";
}

diag( "Testing Class::Monkey $Class::Monkey::VERSION, Perl $], $^X" );
