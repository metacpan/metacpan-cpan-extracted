########################################
# create and put some objects for testing updates
# this set (04, 05, ...) test updates to some objects to prove that we're not 
# storing extraneous objects 
#   like 'thaw' test. scheme is to create a 'matrix' of objects that point to
#   each other. update some and put the updated objects back. show that objects
#   not put remain unchanged.
#   at end, make sure there's only one copy of each object.
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Mechanics;

my($num_objects,$put_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $put_type or $put_type='put';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make the objects
my @objects=
  map {new Mechanics (name=>"update $num_objects object $_",id=>id_next(),
		      num_objects=>$num_objects,list_count=>0)} (0..$num_objects-1);
# connect 'em up
map {$_->object_list(\@objects)} @objects;
# update strings, then store and test
map {$_->string_key('string update 0')} @objects;
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>"$put_type update 0:",put_type=>$put_type,objects=>\@objects,
		correct_diffs=>{Mechanics=>1,Mechanics_object_list=>$num_objects});

# update strings again, but don't put object 0
map {$_->string_key('string update 1')} @objects;
$test->test_put(labelprefix=>"$put_type update 1:",put_type=>$put_type,
		objects=>[@objects[1..$num_objects-1]],old_objects=>\@objects);
# update strings again, but don't put objects 0,1
map {$_->string_key('string update 2')} @objects;
$test->test_put(labelprefix=>"$put_type update 2:",put_type=>$put_type,
		objects=>[@objects[2..$num_objects-1]],old_objects=>\@objects);

done_testing();
