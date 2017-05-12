use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('Dancer2::Plugin::UnicodeNormalize') || print "Bail out";
}

diag("Testing Dancer2::Plugin::UnicodeNormalize $Dancer2::Plugin::UnicodeNormalize::VERSION, Perl $], $^X");

