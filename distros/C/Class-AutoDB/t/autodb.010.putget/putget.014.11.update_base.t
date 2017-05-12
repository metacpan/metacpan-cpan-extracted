########################################
# retrieve and update objects for testing updates
# second set (10, 11, ...) test updates that change all base keys
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
my $test=new autodbTestObject(%test_args,labelprefix=>"$get_type/$put_type:",
			      get_type=>$get_type,put_type=>$put_type);
# get objects. update. put back
my @actual_objects=$autodb->get(collection=>'Mechanics');
for my $i (0..$num_objects-1) {
  my @objects=$test->do_get
    ({collection=>'Mechanics',name=>"update $num_objects object $i"},$get_type,1);
  is(scalar @objects,1,"$get_type/$put_type: object $i");
  my $object=$objects[0];
  $object->string_key('string update 1');
  $object->integer_key(456);
  $object->float_key(456.789);
  $object->object_key($actual_objects[($i+1)%$num_objects]);
  $test->do_put($object,$put_type);
}
my @reach=reach(@actual_objects);
is(scalar @reach,$num_objects,"$get_type/$put_type: one copy of each object at end");

# test the usual way for sanity
# make the objects
my @objects=
  map {new Mechanics (name=>"update $num_objects object $_",id=>id_next(),
		      num_objects=>$num_objects,list_count=>$num_objects)} (0..$num_objects-1);
for my $i (0..$num_objects-1) {
  my $object=$objects[$i];
  $object->string_key('string update 1');
  $object->integer_key(456);
  $object->float_key(456.789);
  $object->object_key($objects[($i+1)%$num_objects]);
}
# test them
$test->test_get(labelprefix=>"$get_type: usual test (for sanity)",
		get_args=>{collection=>'Mechanics'},correct_objects=>\@objects);

done_testing();
