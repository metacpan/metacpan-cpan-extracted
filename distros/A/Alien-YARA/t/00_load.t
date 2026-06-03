#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Alien::YARA') || print "Bail out!\n";
}

diag("Testing Alien::YARA $Alien::YARA::VERSION, Perl $], $^X");
