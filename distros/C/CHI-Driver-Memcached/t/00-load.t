#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('CHI::Driver::Memcached');
}

diag(
    "Testing CHI::Driver::Memcached $CHI::Driver::Memcached::VERSION, Perl $], $^X"
);
