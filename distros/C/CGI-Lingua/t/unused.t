#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

use_ok('CGI::Lingua');
new_ok('CGI::Lingua' => [ supported => ['en-gb'] ]);
plan(tests => 2);
