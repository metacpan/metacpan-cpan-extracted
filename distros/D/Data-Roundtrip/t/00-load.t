#!perl -T

use 5.008;
use strict;
use warnings;

our $VERSION='0.30';

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Roundtrip' ) || print "Bail out!\n";
}

diag( "Testing Data::Roundtrip $Data::Roundtrip::VERSION, Perl $], $^X" );
