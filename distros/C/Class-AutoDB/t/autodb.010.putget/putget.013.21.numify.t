########################################
# this set (20, 21) tests overloaded 'numify' operations, ie, numeric comparisons
#   double quotes, and string comparison ops (cmp, eq, etc)
# scheme is to create a root object pointing to test objects: 
#   2 for each binary op.
#   compare the pairs. check result and make sure not thawed
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Mechanics;

my($get_type)=@ARGV;
# NG 10-09-17: added bool
my @object_names=qw(root cmp cmp lt lt le le eq eq ge ge gt gt ne ne);
my $num_objects=scalar @object_names;
defined $get_type or $get_type='get';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make the objects
my @correct_objects=
  map {new Mechanics (name=>$_,id=>id_next(),
		      num_objects=>$num_objects,list_count=>0)} @object_names;
# connect 'em up. root points to rest
map {$_->object_list(\@correct_objects)} @correct_objects;

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,labelprefix=>"$get_type:",get_type=>$get_type);
my $label="$get_type:";
# get root and use it to obtain list of remaining object (but don't 'get' them!)
my($root)=$test->do_get({collection=>'Mechanics',name=>'root'},$get_type,1);
my @actual_objects=@{$root->object_list};
my @test_objects=@actual_objects[1..$num_objects-1];
# face validity. correct number of objects
is(scalar(@actual_objects),scalar(@correct_objects),
   "$label ".(scalar(@correct_objects)).' objects - sanity test');

# confirm that test objects present as Oids
my $ok=1;
map {$ok&&=ok_objcache($_,'Oid','Mechanics',"$label object starts as Oid",
		       __FILE__,__LINE__,'no_report_pass')} @test_objects;
report_pass($ok,"$label objects start as Oids - sanity test");

# CAUTION: @correct_thawed in 'thaw' tests refers to actual objects
my @correct_thawed=($root);
cmp_thawed(\@actual_objects,\@correct_thawed,"$label thawed root");

# main tests
for my $op (qw(<=> < <= == >= > !=)) {
  my($object0,$object1)=splice(@test_objects,0,2);
  eval "\$object0 $op \$object1"; # should not thaw
  my $ok=ok_objcache($object0,'Oid','Mechanics',"$label object0 not thawed",
		     __FILE__,__LINE__,'no_report_pass');
  $ok&&=ok_objcache($object1,'Oid','Mechanics',"$label object1 not thawed",
		    __FILE__,__LINE__,'no_report_pass');
  report_pass($ok,"$label not thawed $op");
}
done_testing();
