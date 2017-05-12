#!perl

use strict;
use warnings;
use Test::More;

use_ok('Async::Hooks');
diag("Testing Async::Hooks $Async::Hooks::VERSION, Perl $], $^X");


done_testing();
