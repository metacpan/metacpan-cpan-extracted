########################################
# retrieve and update objects for testing updates
# this set (04, 05, ...) test updates to some objects to prove that we're not 
# storing extraneous objects 
#   like 'thaw' test. scheme is to create a 'matrix' of objects that point to
#   each other. update some and put the updated objects back. show that objects
#   not put remain unchanged
#   at end, make sure there's only one copy of each object.
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Mechanics;

my($num_objects,$get_type,$put_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $get_type or $get_type='get';
defined $put_type or $put_type='put';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,get_type=>$get_type,put_type=>$put_type);

# make the objects
my @correct_objects=
  map {new Mechanics (name=>"update $num_objects object $_",id=>id_next(),
		      num_objects=>$num_objects,list_count=>0)} (0..$num_objects);
# connect 'em up
map {$_->object_list([@correct_objects[0..$num_objects-1]])} @correct_objects;
# repeat earlier updates, leaving each object in expected state
map {$correct_objects[$_]->string_key("string update $_")} (0..$num_objects);

# test the database objects
my @actual_objects=$test->do_get({collection=>'Mechanics'},$get_type,$num_objects+1);
$test->test_get(labelprefix=>"$get_type/$put_type update 3:",
		actual_objects=>\@actual_objects,correct_objects=>\@correct_objects);

# create another new object and link to others
my $new_object=
  new Mechanics (name=>"update $num_objects object ".($num_objects+1),id=>id_next(),
		 num_objects=>$num_objects,list_count=>0);
# connect new object to others
$new_object->object_list($actual_objects[0]->object_list);
# update strings in all objects but only put the new one
map {$_->string_key('string update 4')} (@actual_objects,$new_object);
$test->test_put(labelprefix=>"$get_type/$put_type update 4:",object=>$new_object,
		correct_diffs=>{Mechanics=>1,Mechanics_object_list=>$num_objects});

done_testing();
