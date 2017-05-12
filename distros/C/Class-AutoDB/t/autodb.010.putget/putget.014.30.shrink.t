########################################
# create and put some objects for testing updates
# this set (30, 31, ...) test updates that shrink all list fields 
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
  map {new Mechanics (name=>"shrink $num_objects object $_",id=>id_next(),
		      num_objects=>$num_objects,list_count=>2*$num_objects)} (0..$num_objects-1);
# store and test them
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>"$put_type:",put_type=>$put_type,objects=>\@objects,
		correct_diffs=>Mechanics->correct_diffs(2*$num_objects));

# update and store and test them again
for my $i (0..$num_objects-1) {
  my $object=$objects[$i];
  $object->string_list([map {"string shrink 30 object $i element $_"} (0..(2*$num_objects)-1)]);
  $object->integer_list([(30)x(2*$num_objects)]);
  $object->float_list([map {30.30+(($i/100)+($_/1000))} (0..(2*$num_objects)-1)]);
  $object->object_list([map {$objects[($i+$_)%$num_objects]} (0..(2*$num_objects)-1)]);
}
$test->test_put(labelprefix=>"$put_type after update:",put_type=>$put_type,objects=>\@objects,
		old_objects=>\@objects,
		correct_diffs=>0);

done_testing();
