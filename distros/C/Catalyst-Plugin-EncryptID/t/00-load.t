#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::EncryptID' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::EncryptID $Catalyst::Plugin::EncryptID::VERSION, Perl $], $^X" );
