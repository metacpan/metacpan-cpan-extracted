#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::Random;
my $rand;
my $result_random;
$rand = CellBIS::Random->new();
$rand->set_string('string testing random');
$result_random = $rand->random(2, 3);

is($result_random, 'i nrga ntdeosmtsitnrg', "Result of Random with set_string : [$result_random] is true");

$rand = CellBIS::Random->new();
$result_random = $rand->random('string testing random', 2, 3);

is($result_random, 'i nrga ntdeosmtsitnrg', "Result of Random without set_string : [$result_random] is true");

done_testing();

