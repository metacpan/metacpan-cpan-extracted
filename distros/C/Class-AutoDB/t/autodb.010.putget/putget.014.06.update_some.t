########################################
# retrieve and update objects for testing updates
# this set (04, 05, ...) test updates to some objects to prove that we're not 
# storing extraneous objects 
#   like 'thaw' test. scheme is to create a 'matrix' of objects that point to
#   each other. update some and put the updated objects back. show that objects
#   not put remain unchanged
#   at end, make sure there's only one copy of each object.
# this one creates an object that points to objects not retrieved
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

# get one object
my($object0)=$test->do_get
  ({collection=>'Mechanics',name=>"update $num_objects object 0"},$get_type,1);
my @old_objects=@{$object0->object_list};
is(scalar @old_objects,$num_objects,"$get_type/$put_type: object_list count");
my @thawed=grep {'Mechanics' eq ref $old_objects[$_]} (0..$num_objects-1);
cmp_deeply(\@thawed,[0],"$get_type/$put_type: object 0 thawed");
my @unthawed=grep {'Class::AutoDB::Oid' eq ref $old_objects[$_]} (0..$num_objects-1);
cmp_deeply(\@unthawed,[1..$num_objects-1],"$get_type/$put_type: other objects unthawed");

# create a new object and link to others
id_restore();
my $new_object=
  new Mechanics (name=>"update $num_objects object $num_objects",id=>id_next(),
		 num_objects=>$num_objects,list_count=>0);
# connect new object to others
$new_object->object_list($object0->object_list);
# update string, then store and test
$new_object->string_key('string update 3');
$test->test_put(labelprefix=>"$get_type/$put_type update 3: put",object=>$new_object,
		correct_diffs=>{Mechanics=>1,Mechanics_object_list=>$num_objects});

done_testing();
