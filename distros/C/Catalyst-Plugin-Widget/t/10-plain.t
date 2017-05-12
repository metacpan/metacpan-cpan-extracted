#!/usr/bin/env perl

use strict;
use warnings qw(all);

use FindBin '$Bin';
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';
use Test::More tests => 1;


like( get( '/plain' ), qr'^ok' );

