########################################
# this series tests OidDeleted methods 
# this script tests the case in which objects exist in database
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
my @objs=map {conjure_oid($_,'OidDeleted','Persistent')} @oids;
my $oids=join(', ',@oids);

# for sanity, make sure objects in database
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
report_fail(!$dbh->err,$dbh->errstr,__FILE__,__LINE__);
report_fail($count==scalar @oids,
	    'bad news: objects not in database at start of test',__FILE__,__LINE__);

# NG 10-09-16: decided some time ago to remove is_extant, is_deleted, del to avoid polluting 
#              namespace further, but just now getting around to fixing tests
# OidDeleted methods are oid, put. make sure these don't hit AUTOLOAD
# # OidDeleted methods are oid, is_extant, is_deleted, put, del
my $i=0; my $obj=$objs[$i]; my $oid=$oids[$i];
my $actual=eval{$obj->oid;};
report_fail($@ eq '',$@,__FILE__,__LINE__);
is($actual,$oid,'oid method returned correct value');
ok_objcache($obj,$oid,'OidDeleted','Persistent','oid method did not fetch object',
	    __FILE__,__LINE__);

# $i++; my $obj=$objs[$i]; my $oid=$oids[$i];
# my $actual=eval{$obj->is_extant;};
# report_fail($@ eq '',$@,__FILE__,__LINE__);
# ok(!$actual,'is_extant method returned correct value (false)');
# ok_objcache($obj,$oid,'OidDeleted','Persistent','is_extant method did not fetch object'
# 	    ,__FILE__,__LINE__);

# $i++; my $obj=$objs[$i]; my $oid=$oids[$i];
# my $actual=eval{$obj->is_deleted;};
# report_fail($@ eq '',$@,__FILE__,__LINE__);
# ok($actual,'is_deleted method returned correct value (true)');
# ok_objcache($obj,$oid,'OidDeleted','Persistent','is_deleted method did not fetch object'
# 	    ,__FILE__,__LINE__);


# NG 10-09-16: decided some time ago to change semantics of 'put' to be nop, but just now 
#              getting around to fixing tests
# $i++; my $obj=$objs[$i]; my $oid=$oids[$i];
# my $actual=eval{$obj->put;};		# should confess
# if ($@) {
#   like($@,qr/Trying to access deleted object of class Persistent via method put \(oid=$oid\)/,
#        'put method confessed with the expected message');
# } else {
#   report_fail(0,"put method was supposed to confess but did not",__FILE__,__LINE__);
# }
$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
# NG 10-09-16: delete object before 'put' so we can later make sure it's really a nop
$dbh->do(qq(UPDATE _AutoDB SET object=NULL WHERE oid=$oid));
report_fail(!$dbh->err,$dbh->errstr);
my $actual=eval{$obj->put;};		# should be nop.
report_fail($@ eq '',$@,__FILE__,__LINE__);
is($actual,undef,'put method returned correct value (undef)');
ok_objcache($obj,$oid,'OidDeleted','Persistent','put method did not fetch object',__FILE__,__LINE__);
# NG 10-09-16: check database after 'put' to make sure it's really a nop
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid AND object IS NULL;));
report_fail(!$dbh->err,$dbh->errstr,__FILE__,__LINE__);
is($count,1,'put method was nop on database');

# $i++; my $obj=$objs[$i]; my $oid=$oids[$i];
# my $actual=eval{$obj->del;};	# nop
# report_fail($@ eq '',$@,__FILE__,__LINE__);
# is($actual,0,'del method returned correct value (0)');
# ok_objcache($obj,$oid,'OidDeleted','Persistent','del method did not fetch object',
# 	    __FILE__,__LINE__);

# # objects should not be deleted from database, since we lied to the code and said
# # it was already deleted
# my($count_null)=$dbh->selectrow_array
#   (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
# my($count_not_null)=$dbh->selectrow_array
#   (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
# ok($count_null==0 && $count_not_null==scalar @oids,
#    'del did not delete object from database as expected');

# now call application method. should confess
$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $actual=eval{$obj->name;};
if ($@) {
  like($@,qr/Trying to access deleted object of class Persistent via method name \(oid=$oid\)/,
       'application method confessed with the expected message');
} else {
  report_fail(0,"application method was supposed to confess but did not",__FILE__,__LINE__);
}
ok_objcache($obj,$oid,'OidDeleted','Persistent',
	    'application method (name) did not fetch object',__FILE__,__LINE__);

done_testing();

