#!/usr/bin/env perl

# Test that our declared minimum Perl version matches our syntax

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use Test::DescribeMe qw( author );

use Perl::MinimumVersion;
use Test::MinimumVersion;

all_minimum_version_from_metayml_ok();
