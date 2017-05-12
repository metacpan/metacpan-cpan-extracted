#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('CHI::Driver::BerkeleyDB');
}

diag(
    "Testing CHI::Driver::BerkeleyDB $CHI::Driver::BerkeleyDB::VERSION, Perl $], $^X"
);
