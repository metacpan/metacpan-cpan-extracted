#!perl

# this file tests clauses that generate 'grep { ... }' perl code where the
# data_term contains $_ so it conflicts with the topic variable inside the grep.

use 5.010001;
use strict;
use warnings;
use Test::More tests => 1+1;
use Test::NoWarnings;
use Test::Data::Sah qw(test_sah_cases);

my @tests = (
    # will generate data_term '$data->[$_]'
    {schema=>["array*", of=>['bool', in=>[1]]], input=>[1], valid=>1},
);

test_sah_cases(\@tests);
