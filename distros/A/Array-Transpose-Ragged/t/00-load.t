use warnings;
use strict;
use Test::More tests => 1;

use Array::Transpose::Ragged qw/transpose_ragged/;

my @array = (
    [qw /00 01/],
    [qw /10 11 12/],
    [qw /20 21/],
    [qw /30 31 32 33 34/],
);

my @test_result = (['00','10','20','30'],['01','11','21','31'],[undef,'12',undef,'32'],[undef,undef,undef,'33'],[undef,undef,undef,'34']);

my @result = transpose_ragged(\@array);
is_deeply(\@result, \@test_result, "returns correct data");

