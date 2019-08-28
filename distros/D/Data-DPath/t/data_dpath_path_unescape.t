#! /usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More tests => 6;

use_ok('Data::DPath::Path');

my $FIXTURES = [
    {
        name   => 'double quote',
        string => '\\"',
        result => '"',
    },
    {
        name   => 'backslash',
        string => '\\\\',
        result => '\\',
    },
    {
        name   => 'backslash with double quote',
        string => '\\\\\\"',
        result => '\\"',
    },
    {
        name   => 'two backslash with double quote',
        string => '\\\\\\\\\\"',
        result => '\\\\"',
    },
    {
        name   => 'example from documentations',
        string => '\"EE\E5\\\\\\"',
        result => '"EE\E5\"',
    },
];

foreach my $test (@$FIXTURES) {
    is(Data::DPath::Path::unescape($test->{'string'}), $test->{'result'}, $test->{'name'});
}
