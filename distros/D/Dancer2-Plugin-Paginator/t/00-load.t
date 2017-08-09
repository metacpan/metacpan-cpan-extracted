#!perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('Dancer2::Plugin::Paginator') || print "Bail out!\n";
}

diag(
        "Testing Dancer2::Plugin::Paginator "
      . $Dancer2::Plugin::Paginator::VERSION
      . " , Perl $], $^X"
);
