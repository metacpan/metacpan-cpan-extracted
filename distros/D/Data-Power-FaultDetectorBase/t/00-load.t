#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Power::FaultDetectorBase' ) || print "Bail out!\n";
}

diag( "Testing Data::Power::FaultDetectorBase $Data::Power::FaultDetectorBase::VERSION, Perl $], $^X" );
