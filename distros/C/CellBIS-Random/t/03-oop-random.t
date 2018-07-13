#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::Random;

my $rand = CellBIS::Random->new();
$rand->set_string('string testing random');
my $result_random = $rand->random(2, 3);

is($result_random, 'i nrga ntdeosmtsitnrg', "Result of Random : [$result_random] is true");

done_testing();

