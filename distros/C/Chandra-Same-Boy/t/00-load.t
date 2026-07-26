#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Chandra::Same::Boy' )      || print "Bail out!\n";
    use_ok( 'Chandra::Same::Boy::App' ) || print "Bail out!\n";
}

diag( "Testing Chandra::Same::Boy $Chandra::Same::Boy::VERSION, Perl $], $^X" );
