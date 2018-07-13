#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::Random;

my $rand = CellBIS::Random->new();
$rand->set_string('string testing random');
my $random = $rand->random(2, 3);

$rand->set_string($random);
my $unrandom = $rand->unrandom(2, 3);
is($unrandom, 'string testing random', "Result of unrandom : [$unrandom] is true");

done_testing();
