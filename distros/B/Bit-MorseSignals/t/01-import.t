#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

require Bit::MorseSignals;

for (qw<BM_DATA_AUTO BM_DATA_PLAIN BM_DATA_UTF8 BM_DATA_STORABLE>) {
 eval { Bit::MorseSignals->import($_) };
 ok(!$@, 'import ' . $_);
}
