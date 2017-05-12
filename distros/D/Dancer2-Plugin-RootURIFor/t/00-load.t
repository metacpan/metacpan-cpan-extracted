use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('Dancer2::Plugin::RootURIFor') || print "Bail out";
}

diag("Testing Dancer2::Plugin::RootURIFor $Dancer2::Plugin::RootURIFor::VERSION, Perl $], $^X");
