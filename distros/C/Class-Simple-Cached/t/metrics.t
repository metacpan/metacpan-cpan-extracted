#!/usr/bin/env perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Perl::Metrics::Simple';

Test::Perl::Metrics::Simple->import(-complexity => 30);
all_metrics_ok();
