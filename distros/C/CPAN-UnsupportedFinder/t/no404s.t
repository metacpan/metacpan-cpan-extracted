#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Pod::No404s';

Test::Pod::No404s->import();
all_pod_files_ok();
