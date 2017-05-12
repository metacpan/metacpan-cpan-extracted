#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Printer::Filter::JSON' ) || print "Bail out!\n";
}

diag( "Testing Data::Printer::Filter::JSON $Data::Printer::Filter::JSON::VERSION, Perl $], $^X" );
