#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok('DNS::Unbound');

my $dns = DNS::Unbound->new();

$dns->DESTROY();

undef $dns;

ok 1, 'No segfault on multiple DESTROYs';

done_testing();
