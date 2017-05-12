########################################
# this series tests Object methods 
# this script tests the case in which objects do not exist in database
# have to rerun oid.030.00.store to recreate objects before running this script
#   this is accomplished by ln'ing 030.02.restore to 030.00.store
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbUtil;

use Persistent;

tie_oid;
my $dbh=DBI->connect("dbi:mysql:database=".testdb,undef,undef,
		     {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,});
is($DBI::errstr,undef,'connect');
Class::AutoDB::Serialize->dbh($dbh);

my @ids=keys %id2oid;;
my @oids=values %id2oid;
my $oids=join(', ',@oids);

# for sanity, make sure objects in database
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
report_fail(!$dbh->err,$dbh->errstr,__FILE__,__LINE__);
report_fail($count==scalar @oids,
	    'bad news: objects not in database at start of test',__FILE__,__LINE__);

# fetch objects into memory
my @objs=map {Class::AutoDB::Serialize->fetch($_)} @oids;

# for sanity, make sure fetches worked
for (0..@oids-1) {
  ok_objcache($objs[$_],$oids[$_],'object','Persistent',
	      "bad news: fetch did not get object $_ into cache",__FILE__,__LINE__,
	      'no_report_pass');
}

# delete objects from database by setting object=NULL.
$dbh->do(qq(UPDATE _AutoDB SET object=NULL WHERE oid IN ($oids)));
report_fail(!$dbh->err,$dbh->errstr);

# make sure it really happened
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
ok($count==scalar @oids,'objects deleted from database by setting object=NULL');

# now on to the real tests

# NG 10-09-16: decided some time ago to remove is_extant, is_deleted, del to avoid polluting 
#              namespace further, but just now getting around to fixing tests
# Object methods are oid, put. make sure these don't hit AUTOLOAD
# # Object methods are oid, is_extant, is_deleted, put, del. 
my $i=0; my $obj=$objs[$i]; my $oid=$oids[$i];
my $actual=eval{$obj->oid;};
report_fail($@ eq '',$@,__FILE__,__LINE__);
is($actual,$oid,'oid method returned correct value');
ok_objcache($obj,$oid,'object','Persistent','oid method did not change cache',
	    __FILE__,__LINE__);

# $i++; my $obj=$objs[$i]; my $oid=$oids[$i];
# my $actual=eval{$obj->is_extant;};
# report_fail($@ eq '',$@,__FILE__,__LINE__);
# ok($actual,'is_extant method returned correct value (true)');
# ok_objcache($obj,$oid,'object','Persistent','is_extant method did not change cache',
# 	    __FILE__,__LINE__);

# $i++; my $obj=$objs[$i]; my $oid=$oids[$i];
# my $actual=eval{$obj->is_deleted;};
# report_fail($@ eq '',$@,__FILE__,__LINE__);
# ok(!$actual,'is_deleted method returned correct value (false)');
# ok_objcache($obj,$oid,'object','Persistent','is_deleted method did not change cache',
# 	    __FILE__,__LINE__);

$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $actual=eval{$obj->put;};	       # should store object. POD doesn't define return value
report_fail($@ eq '',$@,__FILE__,__LINE__);
ok($actual,'put method returned correct value (something true)');
ok_objcache($obj,$oid,'object','Persistent','put method did not change cache',
	    __FILE__,__LINE__);
# make sure object actually stored
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid AND object IS NOT NULL;));
is($count,1,'put method stored object in database');

# $i++; my $obj=$objs[$i]; my $oid=$oids[$i];
# my $actual=eval{$obj->del;};	# should delete object in memory, do nothing to database
# report_fail($@ eq '',$@,__FILE__,__LINE__);
# is($actual,1,'del method returned correct value (1)');
# ok_objcache($obj,$oid,'OidDeleted','Persistent','del method deleted object in memory',
# 	    __FILE__,__LINE__);
# # make sure object still deleted from database
# my($count)=$dbh->selectrow_array
#   (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid AND object IS NULL;));
# report_fail($count==1,
# 	    "bad news: del method did something strange to object in database (oid=$oid), expected \$count=1, got $count",
# 	     __FILE__,__LINE__);

# now call application method.
$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $actual=$obj->name;
is($actual,"p$i",'application method (name) returned correct value');
ok_objcache($obj,$oid,'object','Persistent','application method (name) did not change cache',
	    __FILE__,__LINE__);

done_testing();

