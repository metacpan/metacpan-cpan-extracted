#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ascii::Text::Chandra' ) || print "Bail out!\n";
}

diag( "Testing Ascii::Text::Chandra $Ascii::Text::Chandra::VERSION, Perl $], $^X" );
