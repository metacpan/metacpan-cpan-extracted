########################################
# test overloaded operations on real objects, Oid, OidDeleteds
# test objects that start life as real objects, Oids, and OidDeleted
# objects created and stored by del.030.00.put
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Person; use Student; use Place; use School; use Thing;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

my @persons=$autodb->get(collection=>'Person');
report_fail
  (scalar(@persons),'objects exist - probably have to rerun put script',__FILE__,__LINE__);
my($jane)=grep {$_->name eq 'Jane'} @persons;
my($mike)=grep {$_->name eq 'Mike'} @persons;
my($barb)=grep {$_->name eq 'Barb'} @persons;
my $mit=$jane->school;		# mit should be OidDeleted
ok_objcache($mit,'OidDeleted','School',
	    'MIT starts as OidDeleted - sanity check',__FILE__,__LINE__);
is("$mit",'','deleted object that starts as OidDeleted (MIT) stringifies to empty string');
ok(!$mit,'deleted object that starts as OidDeleted (MIT) tests as false');
my $ucl=$mike->school;
ok_objcache($ucl,'Oid','School',
	    'UCL starts as Oid - sanity check',__FILE__,__LINE__);
$autodb->del($ucl);
is("$ucl",'','deleted object that starts as Oid (UCL) stringifies to empty string');
ok(!$ucl,'deleted object that starts as OidDeleted (UCL) tests as false');

my($wsu)=$autodb->get(collection=>'Place',name=>'WSU');
ok_objcache($wsu,'obj','School',
	    'WSU starts as object - sanity check',__FILE__,__LINE__);
$autodb->del($wsu);
is("$wsu",'','deleted object that starts as object (WSU) stringifies to empty string');
ok(!$wsu,'deleted object that starts as OidDeleted (WSU) tests as false');

ok($mit eq $ucl,'deleted objects (MIT, UCL) eq each other');
is($mit cmp $wsu,0,'deleted objects (MIT, WSU) cmp to 0');

done_testing();
