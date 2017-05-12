#!/usr/bin/perl -w

use strict;
use Test::More;
use Adam::Logger::Default;

ok( my $l = Adam::Logger::Default->new );

done_testing();
