#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('CHI::Driver::Ping');
}

diag("Testing CHI::Driver::Ping $CHI::Driver::Ping::VERSION, Perl $], $^X");
