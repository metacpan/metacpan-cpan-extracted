########################################
# create and put some objects w/ all types of keys
# this set (10, 11, ...) test values that are easy to query
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use AllTypes;

my($put_type,$num_objects)=@ARGV;
defined $put_type or $put_type='put';
defined $num_objects or $num_objects=2*3*5*2; # to cover the moduli adequately
my $list_count=3;

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make the objects. 
# base values are undef, 0, 1, ... (more or less). object & list values initialized later
# my @objects=
#     (new AllTypes(name=>'all_types object undef',id=>id_next()),
#      map {new AllTypes(name=>"all_types object $_",id=>id_next(),
# 		       string_key=>"string $_",
# 		       integer_key=>$_,
# 		       float_key=>($_+$_/100),)} (1..$num_objects-1));
# # set object key to self, except for 'undef' (0th object)
# map {$_->object_key($_)} @objects[1..$num_objects-1];

# first make 'blank frames'
my @objects=map {new AllTypes(name=>"all_types object $_",id=>id_next())} (0..$num_objects-1);

# then set base values, followed by list values
map {$objects[$_]->init_base_mods($_,@objects)} (0..$num_objects-1);
map {$objects[$_]->init_lists($list_count)} (0..$num_objects-1);

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);

# test the objects. do it one-by-one so correct_diffs can be set
for my $object (@objects) {
  my $correct_diffs=$object->correct_diffs;
  $test->test_put(labelprefix=>"$put_type:",object=>$object,correct_diffs=>$correct_diffs);
}

done_testing();
