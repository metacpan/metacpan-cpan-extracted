#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok('Data::Riak::Fast');
	use_ok('Data::Riak::Fast::HTTP');
}

done_testing;
