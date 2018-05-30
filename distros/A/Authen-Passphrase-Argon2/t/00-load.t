#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Authen::Passphrase::Argon2' ) || print "Bail out!\n";
}

diag( "Testing Authen::Passphrase::Argon2 $Authen::Passphrase::Argon2::VERSION, Perl $], $^X" );
