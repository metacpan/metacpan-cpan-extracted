#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $pkg = 'DNS::Hetzner::Schema';
use_ok $pkg;
can_ok $pkg, qw/validate/;

done_testing();