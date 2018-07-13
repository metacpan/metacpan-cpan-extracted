#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::Random;

my $rand = CellBIS::Random->random('string testing random', 2, 3);
is($rand, 'i nrga ntdeosmtsitnrg', "Result of Random : [$rand] is true");

done_testing();
