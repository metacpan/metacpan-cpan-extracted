#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok('Crypt::Trifid')        || print "Bail out!";
    use_ok('Crypt::Trifid::Utils') || print "Bail out!";
}
diag("Testing Crypt::Trifid $Crypt::Trifid::VERSION, Perl $], $^X");
