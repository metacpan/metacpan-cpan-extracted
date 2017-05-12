########################################
# create and put some objects for testing deferred thawing of deleted objects
# this set (10, 11) checks that stringification causes thaw. this includes
#   double quotes, bool, and string comparison ops (cmp, eq, etc)
# scheme is to create a root object pointing to 'matrix' of deleted test objects: 
#   1 test object each for double quotes and bool, 2 for each binary op.
#   thaw them one-by-one. at end, make sure all are OidDeleteds.
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Mechanics;

my($get_type)=@ARGV;
my @object_names=qw(quotes bool cmp cmp lt lt le le eq eq ge ge gt gt ne ne);
my $num_objects=scalar @object_names;
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

# confirm that test objects start as Oids
my $ok=1;
map {$ok&&=ok_objcache($_,'Oid','Mechanics',"object starts as Oid",
		       __FILE__,__LINE__,'no_report_pass')} @matrix;
report_pass($ok,"objects start as Oids - sanity test");

# test double quotes
my $object=shift @matrix;
my $stringify="$object";	# force thaw
ok_objcache($object,'OidDeleted','Mechanics',"thawed quotes into OidDeleted");

# test bool
my $object=shift @matrix;
my $bool=$object? 1: 0;	# force thaw
ok_objcache($object,'OidDeleted','Mechanics',"thawed bool into OidDeleted");

# test the rest
for my $op (qw(cmp lt le eq ge gt ne)) {
  my($object0,$object1)=splice(@matrix,0,2);
  eval "\$object0 $op \$object1"; # force thaw

  my $ok=ok_objcache($object0,'OidDeleted','Mechanics',"object0 thawed into OidDeleted",
                     __FILE__,__LINE__,'no_report_pass');
  $ok&&=ok_objcache($object1,'OidDeleted','Mechanics',"object1 thawed into OidDeleted",
                    __FILE__,__LINE__,'no_report_pass');
  report_pass($ok,"thawed $op into OidDeleted");
}

done_testing();
