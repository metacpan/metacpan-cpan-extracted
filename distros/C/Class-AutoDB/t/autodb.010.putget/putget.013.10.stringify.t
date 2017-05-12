########################################
# create and put some objects for testing deferred thawing
# this set (10, 11) checks that stringification causes thaw. this includes
#   double quotes, bool, and string comparison ops (cmp, eq, etc)
# scheme is to create a root object pointing to test objects: 
#   1 test object each for double quotes and bool, 2 for each binary op.
#   thaw them one-by-one. at end, make sure there's only one copy of each object.
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Mechanics;

my($put_type)=@ARGV;
# NG 10-09-17: added bool
my @object_names=qw(root quotes bool cmp cmp lt lt le le eq eq ge ge gt gt ne ne);
my $num_objects=scalar @object_names;
defined $put_type or $put_type='put';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make the objects
my @objects=
  map {new Mechanics (name=>$_,id=>id_next(),
		      num_objects=>$num_objects,list_count=>0)} @object_names;
# connect 'em up. root points to rest
map {$_->object_list(\@objects)} @objects;

# store and test them
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>"$put_type:",put_type=>$put_type,objects=>\@objects,
		correct_diffs=>{Mechanics=>1,Mechanics_object_list=>$num_objects});

done_testing();
