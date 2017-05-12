#!/usr/bin/env perl
use warnings;
use strict;
use lib qw/lib/;
use Test::More tests => 4;

use_ok('Acme::GILLIGAN::Utils');
ok (defined &Acme::GILLIGAN::Utils::sum, 'sum() is deinfed');

my @good = (1..10);
is (&Acme::GILLIGAN::Utils::sum(@good), 55, 'good is 55');

my @weird = qw/a b c 1 2 3 123abc/;
is (&Acme::GILLIGAN::Utils::sum(@weird), 129, 'weird list is 129');

done_testing();