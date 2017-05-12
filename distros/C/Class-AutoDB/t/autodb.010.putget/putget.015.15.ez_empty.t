########################################
# retrieve objects w/ all types of keys stored by previous test
# this set (10, 11, ...) test values that are easy to query
# this one does queries which produce empty results
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

# make a pass  that should yield empty results
my %full_query=query(1);
my $key1='string_key';
for my $key2 (@keys) {
  next if $key1 eq $key2 && $key1=~/key/; # duplicate base keys illegal
  my @query=($key1=>'empty',$key2=>$full_query{$key2});
  # can't use do_test: assumes correct values
  # do_test(@query);
  my @correct_objects=();
  my $correct_count=0;
  my $actual_objects=$test->do_get({collection=>'AllTypes',@query},$get_type,$correct_count);
  ok_query($actual_objects,\@correct_objects,$correct_count,undef,undef,@query);
}

done_testing();
