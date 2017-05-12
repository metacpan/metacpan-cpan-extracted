#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    require_ok('Config::Files::Simple')   || print "Bail out!\n";
}

diag("Testing Config::Files::Simple $Config::Files::Simple::VERSION, Perl $], $^X");
