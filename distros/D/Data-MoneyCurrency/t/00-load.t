use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::MoneyCurrency' ) || print "Bail out!\n";
}

diag( "Testing Data::MoneyCurrency $Data::MoneyCurrency::VERSION, Perl $], $^X" );
