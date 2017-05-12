########################################
# this series tests deletion of objects and Oids while cursor active
# this script creates and stores the objects
# these tests vary 3 params
# 1) the items being deleted can start as objects or Oids
# 2) the active cursor can be 'open' or 'running' 
#    open means 'find' executed but no get or get_next
#    running means 'find' and 1 or more 'get_next', but cursor not exhausted
# 3) post-del, the cursor can be accessed via 'get' (ie, get all) or 'get_next'
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use FindDel;

my($num_objects)=@ARGV;
defined $num_objects or $num_objects=5;

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make the objects - _init_self does all the work
my $top=new FindDel(name=>"top num_objects=$num_objects",id=>id_next(),num_objects=>$num_objects);
my @objects=$top->objects;

# store and test them
# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>"put",put_type=>'multi',objects=>\@objects);

done_testing();
