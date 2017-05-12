#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('Crypt::Affine')         || print "Bail out!";
    use_ok('Crypt::Affine::Params') || print "Bail out!";
}

diag( "Testing Crypt::Affine $Crypt::Affine::VERSION, Perl $], $^X" );
