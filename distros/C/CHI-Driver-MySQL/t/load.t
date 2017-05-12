#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('CHI::Driver::MySQL');
}

diag(
    "Testing CHI::Driver::MySQL $CHI::Driver::MySQL::VERSION, Perl $], $^X"
);
