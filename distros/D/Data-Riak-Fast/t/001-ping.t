#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Data::Riak::Fast;

use Data::Riak::Fast;

BEGIN {
    skip_unless_riak;
}

my $riak = Data::Riak::Fast->new(transport => Data::Riak::Fast::HTTP->new);
ok($riak->ping, 'Riak server to test against');

done_testing;
