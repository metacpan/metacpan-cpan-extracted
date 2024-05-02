#!perl -T

use strict;
use warnings;

use Test::More;

use_ok('Alien::libversion');
done_testing();

diag("Alien::libversion $Alien::libversion::VERSION, Perl $], $^X");

