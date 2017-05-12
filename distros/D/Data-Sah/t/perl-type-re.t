#!perl

use 5.010;
use strict;
use warnings;

use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.96;

# just testing that bool in perl can accept numbers and strings
my @tests = (
    {schema=>["re*"], input=>""  , valid=>1},
    {schema=>["re*"], input=>"x" , valid=>1},
    {schema=>["re*"], input=>qr//, valid=>1},
    {schema=>["re*"], input=>"(" , valid=>0},
    {schema=>["re*"], input=>[]  , valid=>0},
    {schema=>["re*"], input=>{}  , valid=>0},
);

test_sah_cases(\@tests);
done_testing();
