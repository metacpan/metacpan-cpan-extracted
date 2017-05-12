########################################
# retrieve objects for testing deferred thawing
# scheme is to create a '3x3 matrix' of objects: 3 objects each of which points 
#  to all 3. retrieve them one-by-one and make sure the ones not yet retrieved
#  remain Oids. at end, make sure there's only one copy of each object.
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
# get them one-by-one and test
my @actual_objects;
for my $i (0..$num_objects-1) {
  my @objects=$test->do_get
    ({collection=>'Mechanics',name=>"thaw $num_objects object $i"},$get_type,1);
  is(scalar @objects,1,"$get_type: object $i");
  my $object=$objects[0];
  my @objects=@{$object->object_list};
  is(scalar @objects,$num_objects,"$get_type: object $i object_list count");
  my @thawed=grep {'Mechanics' eq ref $objects[$_]} (0..$num_objects-1);
  cmp_deeply(\@thawed,[0..$i],"$get_type: object $i  object_list thawed");
  my @unthawed=grep {'Class::AutoDB::Oid' eq ref $objects[$_]} (0..$num_objects-1);
  cmp_deeply(\@unthawed,[$i+1..$num_objects-1],"$get_type: object $i  object_list unthawed");
  push(@actual_objects,$object);
}
my @reach=reach(@actual_objects);
is(scalar @reach,$num_objects,"$get_type: one copy of each object at end");

# test the usual way for sanity
# make the objects
my @objects=
  map {new Mechanics (name=>"thaw $num_objects object $_",id=>id_next(),
		      num_objects=>$num_objects,list_count=>0)} (0..$num_objects-1);
# connect 'em up
map {$_->object_list(\@objects)} @objects;

# get and test them
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
$test->test_get(labelprefix=>"$get_type: usual test (for sanity)",
		get_args=>{collection=>'Mechanics'},correct_objects=>\@objects);

done_testing();
