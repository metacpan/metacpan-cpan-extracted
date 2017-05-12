#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('Crypt::Salsa20');
}

diag(sprintf("Testing Crypt::Salsa20 %s (%d-bit)",
             $Crypt::Salsa20::VERSION, Crypt::Salsa20::IS32BIT() ? 32 : 64));
