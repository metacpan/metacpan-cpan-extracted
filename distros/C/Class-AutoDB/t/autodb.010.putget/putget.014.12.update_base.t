########################################
# retrieve objects for testing updates
# this set (10, 11, 12) test updates that change all scalar fields. 
#   this one does clean 'get' tests and ok_collection tests to make sure 
#   previous updates were persistent
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Mechanics;

my($num_objects,$get_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $get_type or $get_type='get';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,labelprefix=>"$get_type:",get_type=>$get_type);

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

# test them the usual way
my @actual_objects=$autodb->get(collection=>'Mechanics');
$test->test_get(labelprefix=>"$get_type:",
		actual_objects=>\@actual_objects,correct_objects=>\@objects);

# test collection
map {ok_collection($_,'collection Mechanics: '.$_->name,'Mechanics',@{$coll2keys->{Mechanics}})} 
  @actual_objects;

done_testing();
