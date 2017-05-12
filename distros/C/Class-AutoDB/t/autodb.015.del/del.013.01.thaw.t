########################################
# create and put some objects for testing deferred thawing of deleted objects
# scheme is to create a root object pointing to a '3x3 matrix' of objects:
#   3 objects each of which points to all 3. 
# put objects, then del the other objects
# retrieve root and fetch others one-by-one
#  at end, make sure matrix objects are OidDeleteds
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Mechanics;

my($num_objects,$get_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $get_type or $get_type='get';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,get_type=>$get_type);

# get root
my($root)=$test->do_get({collection=>'Mechanics'},$get_type,1);
my @matrix=@{$root->object_list};
is(scalar @matrix,$num_objects,'matrix is expected size - sanity test');
# confirm that matrix objects start as Oids
my $ok=1;
map {$ok&&=ok_objcache($_,'Oid','Mechanics',"matrix object starts as Oid",
		       __FILE__,__LINE__,'no_report_pass')} @matrix;
report_pass($ok,"matrix objects start as Oids - sanity test");

# fetch one-by-one and test
for my $i (0..$num_objects-1) {
  my $object=$matrix[$i];
  my $ok=$object? 0: 1;		# force fetch
  report_fail($ok,"'bool' of matrix object $i returned correct value (false)");
  # object 0..$i should be OidDeleteds, rest should be Oids
  my $ok=1;
  for my $j (0..$i) {
    my $object=$matrix[$j];
    $ok&&=ok_objcache($object,'OidDeleted','Mechanics',
		      "after fetching object $i, object $j changed to OidDeleted",
		      __FILE__,__LINE__,'no_report_pass');
  }
  for my $j ($i+1..$num_objects-1) {
    my $object=$matrix[$j];
    $ok&&=ok_objcache($object,'Oid','Mechanics',
		      "after fetching object $i, object $j is still Oid",
		      __FILE__,__LINE__,'no_report_pass');
  }
  report_pass($ok,"object $i");
}

done_testing();
