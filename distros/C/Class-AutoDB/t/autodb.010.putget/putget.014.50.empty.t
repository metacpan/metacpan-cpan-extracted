########################################
# create and put some objects for testing updates
# this set (50, 51, ...) test updates that empty all list fields 
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

my @objects=
  map {new Mechanics (name=>"empty $num_objects object $_",id=>id_next(),
		      num_objects=>$num_objects,list_count=>$num_objects)} (0..$num_objects-1);
# store and test them
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>"$put_type:",put_type=>$put_type,objects=>\@objects,
		correct_diffs=>Mechanics->correct_diffs($num_objects));

# update and store and test them again
for my $i (0..$num_objects-1) {
  my $object=$objects[$i];
  $object->string_list([('string empty 50')x$num_objects]);
  $object->integer_list([(50)x$num_objects]);
  $object->float_list([(50.50)x$num_objects]);
  $object->object_list([($objects[($i+1)%$num_objects])x$num_objects]);
}
$test->test_put(labelprefix=>"$put_type after update:",put_type=>$put_type,objects=>\@objects,
		old_objects=>\@objects,
		correct_diffs=>0);

done_testing();
