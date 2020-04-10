#!perl

use lib './lib';
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Dancer2::Plugin::Argon2') or print "Bail out!\n";
}

diag("Testing Dancer2::Plugin::Argon2 $Dancer2::Plugin::Argon2::VERSION, Perl $], $^X");
