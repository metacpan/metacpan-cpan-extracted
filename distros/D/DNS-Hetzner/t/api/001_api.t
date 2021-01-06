#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use t::api::Test;
my $t = t::api::Test->new;

can_ok $t, qw/server client2/;

done_testing();
