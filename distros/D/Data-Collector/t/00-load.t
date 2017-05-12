#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Collector' ) || print "Bail out!
";
}

diag( "Testing Data::Collector $Data::Collector::VERSION, Perl $], $^X" );
