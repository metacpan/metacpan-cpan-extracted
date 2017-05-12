#!perl

use 5.010001;
use strict;
use warnings;

use Nodejs::Util qw(get_nodejs_path);
use Test::Data::Sah::Format;
use Test::More 0.98;
use Test::Needs;

plan skip_all => 'Node.js not available'
    unless get_nodejs_path();

test_format(
    compiler => 'js',
    format   => 'iso8601_date',
    data     => [1465789176*1000       , "foo", []],
    fdata    => ["2016-06-13"          , "foo", []],
);

test_format(
    compiler => 'js',
    format   => 'iso8601_datetime',
    data     => [1465789176*1000       , "foo", []],
    fdata    => ["2016-06-13T03:39:36Z", "foo", []],
);

done_testing;
