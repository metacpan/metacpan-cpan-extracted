#! /usr/bin/env perl

use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use Test::More;
use Test::Deep;
use Data::DPath 'dpath';
use Data::Dumper;

# local $Data::DPath::DEBUG = 1;

BEGIN {
        if ($] < 5.010) {
                plan skip_all => "Perl 5.010 required for the smartmatch overloaded tests. This is ".$];
        }
}

use feature 'say';

my $data = {
    aList => [qw/aa bb cc dd ee ff gg hh ii jj/],
    aHash => {
        apple  => 'pie',
        banana => 'split',
        potato => [qw(baked chips fries fish&chips mashed)],
    },
};

my $strange_data = {
    aList => [qw/aa bb cc dd ee ff gg hh ii jj/],
    aHash => {
        apple0 => "pie",
        apple1 => "apple pie",
        apple2 => "apple\npie",
        banana => 'split',
        potato => [qw(baked chips fries fish&chips mashed)],
    },
};

my $res = $data ~~ dpath '//*[ value =~ /i/ ]';
my $expected = [ qw/split pie ii chips fries fish&chips/ ];
unlike ($data->{aHash}, qr/i/, "RT-68882 - aHash does not match the regex");
cmp_bag($res, $expected, "RT-68882 - elements with letter 'i' but not aHash");
# diag "res      = ".Dumper($res);
# diag "expected = ".Dumper($expected);

local $Data::DPath::USE_SAFE;
$res = $data ~~ dpath '//*[ value =~ /i/ ]';
unlike ($data->{aHash}, qr/i/, "RT-68882 - aHash does not match the regex - again without Safe.pm");
cmp_bag($res, $expected, "RT-68882 - elements with letter 'i' but not aHash - again without Safe.pm");

# To clarify confusion I once had here:
#  $data is not found with '//*' because
#  the '*' always gets a *sub* element and
#  therefore can never be the root element.
$res = $data ~~ dpath '//*[ Scalar::Util::reftype(value) eq "HASH" ]';
$expected = [ $data->{aHash} ];
cmp_bag($res, $expected, "RT-68882 related - value filter function still works for hash");

$res = $data ~~ dpath '//*[ Scalar::Util::reftype(value) eq "ARRAY" ]';
$expected = [ $data->{aList}, $data->{aHash}{potato} ];
cmp_bag($res, $expected, "RT-68882 related - value filter function still works for array");

# github #24 - filter expressions with newlines
$res = $strange_data ~~ dpath '/aHash/apple0[ value eq "pie" ]';
$expected = [ $strange_data->{aHash}{apple0} ];
cmp_bag($res, $expected, "github 24 - filter expressions with newlines");
$res = $strange_data ~~ dpath '/aHash/apple1[ value eq "apple pie" ]';
$expected = [ $strange_data->{aHash}{apple1} ];
cmp_bag($res, $expected, "github 24 - filter expressions with newlines");
$res = $strange_data ~~ dpath '/aHash/apple2[ value eq "apple
pie" ]';
$expected = [ $strange_data->{aHash}{apple2} ];
cmp_bag($res, $expected, "github 24 - filter expressions with newlines");

done_testing;
