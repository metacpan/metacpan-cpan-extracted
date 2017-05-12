#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Apache2::ASP::ConfigFinder');

my $path = Apache2::ASP::ConfigFinder->config_path;


