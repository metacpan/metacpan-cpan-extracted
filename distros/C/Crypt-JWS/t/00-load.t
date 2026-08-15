#!perl
use 5.016;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Crypt::JWS')      || print "Bail out!\n";
    use_ok('Crypt::JWS::Key') || print "Bail out!\n";
}

diag("Testing Crypt::JWS $Crypt::JWS::VERSION, Perl $], $^X");
done_testing();
