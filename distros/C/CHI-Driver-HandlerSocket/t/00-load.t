#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('CHI::Driver::HandlerSocket');
}

diag("Testing CHI::Driver::HandlerSocket $CHI::Driver::HandlerSocket::VERSION, Perl $], $^X");
