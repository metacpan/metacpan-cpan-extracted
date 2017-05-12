########################################
# retrieve objects w/ all types of keys stored by previous test
# this set (10, 11, ...) test values that are easy to query
# this one does queries with growing numbers of keys
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

# do basekeys
for my $i (0..1) {
  my %full_query=query($i);
  my @query;
  for my $key1 (@basekeys) {
    push(@query,$key1=>$full_query{$key1});
    do_test(@query);
  }
}
# do listkeys separately. else, count would be 1 throughout, since object_key is unique
for my $i (0..1) {
  my %full_query=query($i);
  my @query;
  for my $key1 (@listkeys) {
    push(@query,$key1=>$full_query{$key1});
    do_test(@query);
  }
}
# do them interleaved
for my $i (0..1) {
  my %full_query=query($i);
  my @query;
  for my $key1 (@interkeys) {
    push(@query,$key1=>$full_query{$key1});
    do_test(@query);
  }
}

done_testing();
