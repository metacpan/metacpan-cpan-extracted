#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Data::Random::Weighted;

use_ok('Data::Random::Weighted') || BAIL_OUT('Library cannot be used all is dooom!');

my $rand = Data::Random::Weighted->new({ this => 1, });

is ( $rand->roll, 'this', 'roll function test' );

done_testing;
