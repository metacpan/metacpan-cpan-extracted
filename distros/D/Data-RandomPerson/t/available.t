#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('Data::RandomPerson');

my @available = Data::RandomPerson::available_types();

cmp_ok(scalar @available, '>=', 5, 'at least 5 types');

my %values = map { $_ => 1 } @available;

ok($values{Dutch},    'Dutch is on the list');
ok($values{Spanish},  'Spanish is on the list');
ok(!$values{Klingon}, 'Klingon is not on the list');

done_testing();
