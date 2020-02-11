#!perl

use 5.010001;
use strict;
use warnings;
use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.98;

# Str::check filter rule currently is only implemented for perl, not js. so we
# don't put these tests in the spectest yet.

my @tests = (
    {schema=>["str", prefilters=>[ ["Str::check",{min_len=>2}] ]], input=>"f", valid=>0},
    {schema=>["str", prefilters=>[ ["Str::check",{min_len=>2}] ]], input=>"f ", valid=>1},
    {schema=>["str", prefilters=>[ "Str::trim", ["Str::check",{min_len=>2}] ]], input=>"f ", valid=>0},
);

test_sah_cases(\@tests);
done_testing;
