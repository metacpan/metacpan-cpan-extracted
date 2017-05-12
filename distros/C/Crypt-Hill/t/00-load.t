#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('Crypt::Hill')        || print "Bail out!";
    use_ok('Crypt::Hill::Utils') || print "Bail out!";
}

diag( "Testing Crypt::Hill $Crypt::Hill::VERSION, Perl $], $^X" );
