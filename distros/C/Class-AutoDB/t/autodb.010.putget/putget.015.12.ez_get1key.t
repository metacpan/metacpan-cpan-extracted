########################################
# retrieve objects w/ all types of keys stored by previous test
# this set (10, 11, ...) test values that are easy to query
# this one does queries with 1 key
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use putget_015_easy; use AllTypes;

my($get_type,$num_objects)=@ARGV;
defined $get_type or $get_type='get';
defined $num_objects or $num_objects=2*3*5*2; # to cover the moduli adequately
init_test($get_type,$num_objects);

# overkill and infeasible to test all values
# for my $i (0..$num_objects-1) {
for my $i (0..1) {
  my %full_query=query($i);
  for my $key1 (@keys) {
    my @query=($key1=>$full_query{$key1});
    do_test(@query);
  }}

done_testing();
