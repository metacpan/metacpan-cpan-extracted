#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Chandra::EPUB' ) || print "Bail out!\n";
}

diag( "Testing Chandra::EPUB $Chandra::EPUB::VERSION, Perl $], $^X" );
