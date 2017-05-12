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

# make the objects
my @correct_objects=
  map {new Mechanics (name=>"update $num_objects object $_",id=>id_next(),
		      num_objects=>$num_objects,list_count=>0)} (0..$num_objects+1);
# connect 'em up
map {$_->object_list([@correct_objects[0..$num_objects-1]])} @correct_objects;
# repeat 0th updates, leaving each object in expected state
map {$correct_objects[$_]->string_key("string update $_")} (0..$num_objects+1);

# test them
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,get_type=>$get_type,put_type=>$put_type);
my @actual_objects=$test->do_get({collection=>'Mechanics'},$get_type,$num_objects+2);
$test->test_get(labelprefix=>"$get_type/$put_type update 4:",
		actual_objects=>\@actual_objects,correct_objects=>\@correct_objects);

my @reach=reach(@actual_objects);
is(scalar @reach,$num_objects+2,"$get_type: one copy of each object at end");

done_testing();
