#!perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use DBIx::Spreadsheet;

my @testcases = (
    ['10/04/17', 1 ],
);

my $testcount = 0+1*@testcases;

plan tests => $testcount;

for my $case (@testcases) {
    my( $input, $expected, $name ) = @$case;
    $name ||= "$input => $expected";

    my $res = $input =~ /$DBIx::Spreadsheet::looks_like_date/;
    is $res, $expected, $name
}
