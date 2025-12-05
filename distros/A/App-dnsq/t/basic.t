#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use_ok('DNSQuery::Resolver');
use_ok('DNSQuery::Output');
use_ok('DNSQuery::Interactive');

done_testing();
