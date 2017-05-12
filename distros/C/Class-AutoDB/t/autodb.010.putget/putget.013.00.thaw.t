########################################
# create and put some objects for testing deferred thawing
# scheme is to create a '3x3 matrix' of objects: 3 objects each of which points 
#  to all 3. retrieve them one-by-one and make sure the ones not yet retrieved
#  remain Oids. at end, make sure there's only one copy of each object.
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
  map {new Mechanics (name=>"thaw $num_objects object $_",id=>id_next(),
		      num_objects=>$num_objects,list_count=>0)} (0..$num_objects-1);
# connect 'em up
map {$_->object_list(\@objects)} @objects;

# store and test them
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>"$put_type:",put_type=>$put_type,objects=>\@objects,
		correct_diffs=>{Mechanics=>1,Mechanics_object_list=>$num_objects});

done_testing();
