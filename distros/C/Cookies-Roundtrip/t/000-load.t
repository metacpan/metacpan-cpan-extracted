#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.01';

BEGIN {
    use_ok( 'Cookies::Roundtrip' ) || print "Bail out!\n";
}

diag( "Testing Cookies::Roundtrip $Cookies::Roundtrip::VERSION, Perl $], $^X" );

done_testing;
