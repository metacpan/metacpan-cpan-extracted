#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

use_ok('Class::Simple::Readonly::Cached');
new_ok('Class::Simple::Readonly::Cached');
plan(tests => 2);
