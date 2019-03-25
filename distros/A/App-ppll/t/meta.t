#!/usr/bin/env perl

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use Test::DescribeMe qw( author );
use Test::Most;

use Test::CPAN::Meta;

plan skip_all => 'No META.yml'
  unless -f 'META.yml';

meta_yaml_ok();
