#!/usr/bin/env perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Tabs';

Test::Tabs->import();
all_perl_files_ok();
done_testing();
