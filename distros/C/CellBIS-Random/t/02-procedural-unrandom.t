#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::Random;

my $random = CellBIS::Random->random('string testing random', 2, 3);
my $unrandom = CellBIS::Random->unrandom($random, 2, 3);
is($unrandom, 'string testing random', "Result of unrandom : [$unrandom] is true");

done_testing();
