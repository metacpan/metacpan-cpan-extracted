#!perl -T

use Test::More qw(no_plan);

BEGIN {
  use_ok( 'Color::TupleEncode' ) || print "Bail out!";
  use_ok( 'Color::TupleEncode', qw(:all) ) || print "Bail out!";
}

diag( "Testing Color::TupleEncode $Color::TupleEncode::VERSION" );
