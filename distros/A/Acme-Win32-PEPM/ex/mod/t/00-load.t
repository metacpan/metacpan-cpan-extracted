#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Win32::PET' ) || print "Bail out!\n";
}

diag( "Testing Win32::PET $Win32::PET::VERSION, Perl $], $^X" );

Win32::PET::hello_world();
