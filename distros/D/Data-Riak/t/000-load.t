#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok('Data::Riak');
	use_ok('Data::Riak::HTTP');
}

use Test::Data::Riak;
diag 'Testing against ' . riak_transport->transport->base_uri;

done_testing;
