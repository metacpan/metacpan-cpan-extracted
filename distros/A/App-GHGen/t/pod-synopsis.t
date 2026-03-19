#!/usr/bin/perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Synopsis';

Test::Synopsis->import();
all_synopsis_ok();
