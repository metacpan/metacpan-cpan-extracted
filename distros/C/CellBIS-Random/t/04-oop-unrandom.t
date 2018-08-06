#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::Random;

my $rand;
my $random;
my $unrandom;

$rand = CellBIS::Random->new();
$rand->set_string('string testing random');
$random = $rand->random(2, 3);

$rand->set_string($random);
$unrandom = $rand->unrandom(2, 3);
is($unrandom, 'string testing random', "Result of unrandom with set_string : [$unrandom] is true");

$rand = CellBIS::Random->new();
$random = $rand->random('string testing random', 2, 3);

$rand->set_string($random);
$unrandom = $rand->unrandom(2, 3);
is($unrandom, 'string testing random', "Result of unrandom without set_string : [$unrandom] is true");

done_testing();
