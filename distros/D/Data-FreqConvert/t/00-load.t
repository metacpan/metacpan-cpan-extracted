
use Test::More tests => 1;
use blib;
BEGIN {
    use_ok( 'Data::FreqConvert' ) || print "Bail out!\n";
}

diag( "Testing Data::FreqConvert $Data::FreqConvert::VERSION, Perl $], $^X" );
1;
