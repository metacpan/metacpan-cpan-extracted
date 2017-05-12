use strict;
use warnings;
use Test::More 0.98;
use Test::Synopsis::Expectation;
Test::Synopsis::Expectation::prepare('no warnings "void";');

synopsis_ok('lib/Data/Queue/Batch.pm');

done_testing;

