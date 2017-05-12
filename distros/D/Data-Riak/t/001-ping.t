#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Data::Riak;

use Data::Riak;

BEGIN {
    skip_unless_riak;
}

my $riak = riak_transport;
ok($riak->ping, 'Riak server to test against');

done_testing;
