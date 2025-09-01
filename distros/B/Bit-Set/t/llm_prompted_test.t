#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl

# test generated via initial vibe coding prompt
use strict;
use warnings;
use Test::More tests => 1;

use Bit::Set qw( :all );
use Bit::Set::DB qw( :all );

my $bitset = Bit_new(1024);

Bit_bset($bitset, 0);
Bit_bset($bitset, 1);
Bit_bset($bitset, 4);


is(Bit_count($bitset), 3, 'Popcount should be 3');

Bit_free(\$bitset);