########################################
# this series tests objects containing Oids to deleted objects and OidDeleteds
# this script gets object containing Oids to deleted objects, then deletes Oids
# objects created and stored by del.011.00.put
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Person; use Student; use Place; use School; use Thing;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
my $test=new autodbTestObject(%test_args);

my($barb)=$autodb->get(collection=>'Person',name=>'Barb');
report_fail
  (ref $barb,'objects exist - probably have to rerun put script',__FILE__,__LINE__);
# test contained objects before fetch
my $mit=$barb->school;		# mit should be Oid
ok_objcache($mit,'Oid','School','school starts as Oid',__FILE__,__LINE__);
my @hobbies=@{$barb->hobbies};
ok_objcache($hobbies[0],'Oid','Thing',
	    '1st hobby starts as Oid', __FILE__,__LINE__);
ok_objcache($hobbies[1],'Oid','Thing',
	    '2nd hobby starts as Oid', __FILE__,__LINE__);
# del contained Oids. should have no effect on database
$test->old_counts;		# remember table counts before update
$autodb->del($mit,$hobbies[0]);
my $actual_diffs=$test->diff_counts;
my $correct_diffs={};
cmp_deeply($actual_diffs,$correct_diffs,'del of Oids leaves database unchanged');

# retest contained objects
ok_objcache($mit,'OidDeleted','School','after del: school is OidDeleted',__FILE__,__LINE__);
ok_objcache($hobbies[0],'OidDeleted','Thing',
	    'after del: 1st hobby is OidDeleted', __FILE__,__LINE__);
ok_objcache($hobbies[1],'Oid','Thing',
	    'after del: 2nd hobby still Oid', __FILE__,__LINE__);

done_testing();
