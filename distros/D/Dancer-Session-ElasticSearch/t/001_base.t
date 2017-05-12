#!/usr/bin/env perl

use Test::More;

use strict;
use warnings;

BAIL_OUT 'Requires perl 5.10.0 or higher' if $] < 5.010;

use_ok 'Dancer::Session::ElasticSearch';

done_testing;