########################################
# create and put some objects for testing deferred thawing of deleted objects
# scheme is to create a root object pointing to a '3x3 matrix' of objects:
#  3 objects each of which points to all 3. 
# del the matrix objects then put root
# retrieve root and fetch others one-by-one
#  make sure matrix objects are OidDeleteds at start and end
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Mechanics;

my($num_objects)=@ARGV;
defined $num_objects or $num_objects=3;

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

# del matrix, then put root
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$autodb->del(@matrix);
$test->old_counts;		# remember table counts before update
$autodb->put($root);
my $actual_diffs=$test->diff_counts;
my $correct_diffs={_AutoDB=>1,Mechanics=>1,Mechanics_object_list=>$num_objects};
cmp_deeply($actual_diffs,$correct_diffs,'table counts at end');

done_testing();
