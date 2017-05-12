########################################
# create and put some objects for testing deferred thawing of deleted objects
# scheme is to create a root object pointing to a '3x3 matrix' of objects:
#   3 objects each of which points to all 3. 
# put objects, then del the matrix objects
# retrieve root and fetch others one-by-one
#  at end, make sure matrix objects are OidDeleteds
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Mechanics;

my($num_objects,$del_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $del_type or $del_type='del';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make the objects
my $root=new Mechanics(name=>'root',id=>id_next(),list_count=>0);
my @matrix=
  map {new Mechanics (name=>"object $_",id=>id_next(),list_count=>0)} (0..$num_objects-1);
# connect 'em up
$root->object_list(\@matrix);
map {$_->object_list(\@matrix)} @matrix;

# put all, then del matrix
$autodb->put_objects;
# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,del_type=>$del_type);
$test->test_del(labelprefix=>"$del_type matrix",del_type=>$del_type,objects=>\@matrix,
		correct_diffs=>{Mechanics=>1,Mechanics_object_list=>$num_objects});

done_testing();
