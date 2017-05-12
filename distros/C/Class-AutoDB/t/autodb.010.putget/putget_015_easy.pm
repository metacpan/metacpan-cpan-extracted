########################################
# utility functions for putget.015 easy series
########################################
package putget_015_easy;
use t::lib;
use strict;
use Carp;
use Scalar::Util qw(refaddr);
use List::Util qw(reduce);
use List::MoreUtils qw(uniq);
use Test::More;
use Test::Deep;
# Test::Deep doesn't export cmp_details, deep_diag until recent version (0.104)
# so we import them "by hand"
*cmp_details=\&Test::Deep::cmp_details;
*deep_diag=\&Test::Deep::deep_diag;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use AllTypes;

our @ISA=qw(Exporter);
our @EXPORT=qw(init_test do_test query ok_query $test @basekeys @listkeys @keys @interkeys);
our($get_type,$num_objects,$autodb,$test,
    %factors,@all_actual_objects,@all_actual_refaddrs,@all_correct_objects);
our $list_count=3;
our @basekeys=qw(string_key integer_key float_key object_key);
our @listkeys=qw(string_list integer_list float_list object_list);
our @keys=(@basekeys,@listkeys);
our @interkeys=qw(string_key string_list integer_list integer_key 
		 float_key float_list object_list object_key);

sub init_test {
  ($get_type,$num_objects)=@_;
  defined $get_type or $get_type='get';
  defined $num_objects or $num_objects=2*3*5*2; # to cover the moduli adequately
  %factors=(string=>2,integer=>3,float=>5,object=>$num_objects);
  $autodb=new Class::AutoDB(database=>testdb); # open database
  isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

  # get the objects. need them to set object_key in 'correct' objects
  @all_actual_objects=$autodb->get(collection=>'AllTypes');
  @all_actual_refaddrs=map {refaddr($_)} @all_actual_objects;
  # check oids mostly to set %oid2obj 
  ok_oldoids(\@all_actual_objects,"$get_type all objects: oids");
  is(scalar @all_actual_objects,$num_objects,"$get_type all objects: count");

  # make the objects. 
  # first make 'blank frames'
  @all_correct_objects=
    map {new AllTypes(name=>"all_types object $_",id=>id_next())} (0..$num_objects-1);
  # then set base values, followed by list values
  map {$all_correct_objects[$_]->init_base_mods($_,@all_correct_objects)} (0..$num_objects-1);
  map {$all_correct_objects[$_]->init_lists($list_count)} (0..$num_objects-1);

  # %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
  $test=new autodbTestObject(%test_args,get_type=>$get_type);
}

sub do_test {
  my @query=@_;
  my($package,$file,$line)=caller; # for fails
  my @correct_objects=correct_objects(@query);
  my $correct_count=correct_count(@query);
  my $actual_objects=$test->do_get({collection=>'AllTypes',@query},$get_type,$correct_count);
  ok_query($actual_objects,\@correct_objects,$correct_count,$file,$line,@query);
}

sub ok_query {
  my($actual_objects,$correct_objects,$correct_count,$file,$line,@query)=@_;
  my $labelprefix="$get_type ".emit(@query).':';
  my @actual_refaddrs=map {refaddr($_)} @$actual_objects;
  my($ok,$details)=cmp_details(\@actual_refaddrs,subsetof(@all_actual_refaddrs));
  report_fail($ok,"$labelprefix retrieved objects not duplicated",$file,$line,$details)
    or return 0;
  # my $correct_count=correct_count(@query);
  my $actual_count=scalar @$actual_objects;
  my($ok,$details)=cmp_details($actual_count,$correct_count);
  report_fail($ok,"$labelprefix count",$file,$line,$details) or return 0;
  my($ok,$details)=cmp_details($actual_objects,$correct_objects);
  report($ok,"$labelprefix $actual_count objects",$file,$line,$details);
}

sub correct_objects {
  my %query=@_;
  my @correct_objects=@all_correct_objects;
  while(my($key,$query_value)=each %query) {
    @correct_objects=grep {_correct1($key,$query_value,$_->$key)} @correct_objects;
  }
  @correct_objects;
}
# have to fiddle with the object keys because query refers to database objects
# and this sub is addressing 'correct' objects
sub _correct1 {
  my($key,$query_value,$value)=@_;
  my $cmp;
  if (defined $query_value) {
    $cmp=$key=~/string/? sub {$query_value eq $_}: 
      ($key=~/object/? sub {defined($_) && $query_value->id == $_->id}: sub {$query_value == $_});
  } else {
    $cmp=sub {!defined $_};
  }
  $value=[$value] unless 'ARRAY' eq ref $value;
  grep &$cmp(),@$value;
}
# correct_count easy to compute because values generated via mod
sub correct_count {
  my %query=@_;
  my @factors=@factors{uniq(map {/^(.*)_/} keys %query)};
  my $correct_count=$num_objects/(reduce {$a*$b} @factors);
  $correct_count=1 if $correct_count<1;
  $correct_count;
} 
# returns hash of query values for index $i. 
# have to fiddle with the object keys so they will refer to database objects
sub query { 
  # my($i,@objects)=@_;
  my %query=base_mods(@_);
  $query{object_key}=$oid2obj{$id2oid{$query{object_key}->id}} if defined $query{object_key};
  @query{qw(string_list integer_list float_list object_list)}=
    @query{qw(string_key integer_key float_key object_key)};
  %query;
}
sub base_mods {
  my($i,@objects)=@_;
  my $i=shift;
  my @objects=@_? @_: @all_correct_objects;
  (string_key=>($i%2)? ('string '.($i%2)): undef,
   integer_key=>$i%3 || undef,
   float_key=>($i%5)? ($i%5+(($i%5)/10)): undef,
   object_key=>$i? $objects[$i]: undef,);
}

sub emit {			# emit keys in order given
  my @emit;
  while(my($key,$value)=splice(@_,0,2)) {
    push(@emit,"$key=>undef"), next unless defined $value;
    push(@emit,"$key=>\'$value\'"), next if $key=~/string/;
    push(@emit,"$key=>".$value->id), next if $key=~/object/;
    push(@emit,"$key=>$value");
  }
  join(',',@emit);
}
# sub emit {
#   my $args=new Hash::AutoHash::Args(@_); # make args to deal with repeated search keys
#   my @emit;
#   for my $key (@keys) {		# do it this way to get output in canonical order
#     next unless exists $args->{$key};
#     my $value=$args->$key;
#     push(@emit,"$key=>undef"), next unless defined $value;
#     my @values='ARRAY' eq ref $value? @$value: ($value);
#     for my $value (@values) {
#       push(@emit,"$key=>undef"), next unless defined $value;
#       push(@emit,"$key=>\'$value\'"), next if $key=~/string/;
#       # push(@emit,"$key=>\'".$hash{$key}->name.'\''), next if $key=~/object/;
#       push(@emit,"$key=>".$value->id), next if $key=~/object/;
#       push(@emit,"$key=>$value");
#     }}
#   join(',',@emit);
# }
    
