########################################
# this series tests binary overloaded operations on combinations of Oids and OidDeleted
# this script tests the case in which objects do not exist in database
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
my @objs;
# alternate Oids and OidDeleteds in @objs
for (my $i=0; $i<@oids; $i+=2) {
  push(@objs,conjure_oid($oids[$i],'Oid','Persistent'),
       conjure_oid($oids[$i+1],'OidDeleted','Persistent'));
}
my $oids=join(', ',@oids);

# delete objects from database by setting object=NULL. note that some may already be deleted
$dbh->do(qq(UPDATE _AutoDB SET object=NULL WHERE oid IN ($oids)));
report_fail(!$dbh->err,$dbh->errstr);

# make sure it really happened
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
ok($count==scalar @oids,'objects deleted from database by setting object=NULL');

# the binary ops that Oid & OidDeleted overload are eq, ne, ==, !=
# eq
my $i=0; my $obj0=$objs[$i]; my $oid0=$oids[$i];
$i++; my $obj1=$objs[$i]; my $oid1=$oids[$i];
my $ok=$obj0 eq $obj1? 1: 0;
ok($ok,'eq returned correct value (true)');
ok_objcache($obj0,$oid0,'OidDeleted','Persistent','eq fetched 1st object as OidDeleted',
	    __FILE__,__LINE__);
ok_objcache($obj1,$oid1,'OidDeleted','Persistent','eq did not fetch 2nd object',
	    __FILE__,__LINE__);

$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $ok=$obj eq $obj? 1: 0;
ok($ok,'eq of Oid with self returned correct value (true)');
ok_objcache($obj,$oid,'OidDeleted','Persistent','eq with self fetched object as OidDeleted',
	    __FILE__,__LINE__);

$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $ok=$obj eq $obj? 1: 0;
ok($ok,'eq of OidDeleted with self returned correct value (true)');
ok_objcache($obj,$oid,'OidDeleted','Persistent','eq with self did not fetch object',
	    __FILE__,__LINE__);

# ne
$i++; my $obj0=$objs[$i]; my $oid0=$oids[$i];
$i++; my $obj1=$objs[$i]; my $oid1=$oids[$i];
my $ok=$obj0 ne $obj1? 0: 1;
ok($ok,'ne returned correct value (false)');
ok_objcache($obj0,$oid0,'OidDeleted','Persistent','ne fetched 1st object as OidDeleted',
	    __FILE__,__LINE__);
ok_objcache($obj1,$oid1,'OidDeleted','Persistent','ne did not fetch 2nd object',
	    __FILE__,__LINE__);

$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $ok=$obj ne $obj? 0: 1;
ok($ok,'ne of Oid with self returned correct value (false)');
ok_objcache($obj,$oid,'OidDeleted',
	    'Persistent','ne of Oid with self fetched object as OidDeleted',__FILE__,__LINE__);

$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $ok=$obj ne $obj? 0: 1;
ok($ok,'ne of OidDeleted with self returned correct value (false)');
ok_objcache($obj,$oid,'OidDeleted','Persistent','ne of OidDeleted with self did not fetch object',
	    __FILE__,__LINE__);

# ==
my $i=0; my $obj0=$objs[$i]; my $oid0=$oids[$i];
$i++; my $obj1=$objs[$i]; my $oid1=$oids[$i];
my $ok=$obj0 == $obj1? 0: 1;
ok($ok,'== returned correct value (false)');
ok_objcache($obj0,$oid0,'OidDeleted','Persistent','== fetched 1st object as OidDeleted',
	    __FILE__,__LINE__);
ok_objcache($obj1,$oid1,'OidDeleted','Persistent','== did not fetch 2nd object',
	    __FILE__,__LINE__);

$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $ok=$obj == $obj? 1: 0;
ok($ok,'== of Oid with self returned correct value (true)');
ok_objcache($obj,$oid,'OidDeleted','Persistent','== with self fetched object as OidDeleted',
	    __FILE__,__LINE__);

$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $ok=$obj == $obj? 1: 0;
ok($ok,'== of OidDeleted with self returned correct value (true)');
ok_objcache($obj,$oid,'OidDeleted','Persistent','== with self did not fetch object',
	    __FILE__,__LINE__);

# !=
$i++; my $obj0=$objs[$i]; my $oid0=$oids[$i];
$i++; my $obj1=$objs[$i]; my $oid1=$oids[$i];
my $ok=$obj0 != $obj1? 1: 0;
ok($ok,'!= returned correct value (true)');
ok_objcache($obj0,$oid0,'OidDeleted','Persistent','!= fetched 1st object as OidDeleted',
	    __FILE__,__LINE__);
ok_objcache($obj1,$oid1,'OidDeleted','Persistent','!= did not fetch 2nd object',
	    __FILE__,__LINE__);

$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $ok=$obj != $obj? 0: 1;
ok($ok,'!= of Oid with self returned correct value (false)');
ok_objcache($obj,$oid,'OidDeleted',
	    'Persistent','!= of Oid with self fetched object as OidDeleted',__FILE__,__LINE__);

$i++; my $obj=$objs[$i]; my $oid=$oids[$i];
my $ok=$obj != $obj? 0: 1;
ok($ok,'!= of OidDeleted with self returned correct value (false)');
ok_objcache($obj,$oid,'OidDeleted','Persistent','!= of OidDeleted with self did not fetch object',
	    __FILE__,__LINE__);

done_testing();
