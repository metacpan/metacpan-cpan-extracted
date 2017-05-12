#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Persist' ) || print "Bail out!
";
}

diag( "Testing Data::Persist $Data::Persist::VERSION, Perl $], $^X" );
