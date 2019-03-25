#!/usr/bin/env perl

# Test that Changes has an entry for current version

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use Test::DescribeMe qw( author );
use Test::Most;

use Test::CPAN::Changes;

changes_ok();
