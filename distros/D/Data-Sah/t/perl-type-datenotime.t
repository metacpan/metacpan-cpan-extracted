#!perl

# minimal and temporary tests, pending real datenotime spectest from Sah

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

plan skip_all => "DateTime not available" unless eval { require DateTime; 1 };

use Test::Data::Sah qw(test_sah_cases);

my @tests = (
    {schema=>["datenotime"], input=>"2014-01-25", valid=>1},
    {schema=>["datenotime"], input=>"2014-01-25T23:59:59Z", valid=>0}, # but valid datetime
    {schema=>["datenotime"], input=>"2014-02-30", valid=>0},
    {schema=>["datenotime"], input=>"2014-01-25T23:59:70Z", valid=>0},
    {schema=>["datenotime"], input=>"x", valid=>0},
    {schema=>["datenotime"], input=>100_000_000, valid=>1}, # XXX should we check hour, minute, second, nanosecond are 0?
    {schema=>["datenotime"], input=>100_000, valid=>1}, # but invalid when x.perl.coerce_to is DateTime
    {schema=>["datenotime"], input=>DateTime->now, valid=>1}, # XXX should we check hour, minute, second, nanosecond are 0?

    {schema=>["datenotime", min=>"2014-01-01"], input=>"2013-12-12", valid=>0},
    {schema=>["datenotime", min=>"2014-01-02"], input=>"2014-01-02", valid=>1},
    {schema=>["datenotime", min=>"2014-01-02"], input=>"2014-02-01", valid=>1},

    {schema=>["datenotime", min=>"2014-01-02"], input=>1_000_000_000, valid=>0},
    {schema=>["datenotime", min=>"2014-01-02"], input=>2_000_000_000, valid=>1},
);

test_sah_cases(\@tests);
done_testing();
