#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer::Logger::Hourlyfile' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Logger::Hourlyfile $Dancer::Logger::Hourlyfile::VERSION, Perl $], $^X" );
