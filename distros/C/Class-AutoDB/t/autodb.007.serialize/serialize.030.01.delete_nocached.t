########################################
# delete objects stored by previous test
# tests delete by oid (as number) when object and Oid not yet in object cache
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbUtil;

use Class::AutoDB::Serialize;
use Persistent; use NonPersistent;

tie_oid;
my $dbh=DBI->connect("dbi:mysql:database=".testdb,undef,undef,
		     {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,});
is($DBI::errstr,undef,'connect');
Class::AutoDB::Serialize->dbh($dbh);

my $p0_oid=$id2oid{id_next()};
my $p1_oid=$id2oid{id_next()};

# for sanity, make sure objects in database
my $oids=join(', ',$p0_oid,$p1_oid);
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
report_fail(!$dbh->err,$dbh->errstr,__FILE__,__LINE__);
report_fail($count==2,'bad news: objects not in database at start of test',__FILE__,__LINE__);

# delete the objects
my $ok=Class::AutoDB::Serialize->del($p0_oid);
ok($ok,'p0 del');
my $ok=Class::AutoDB::Serialize->del($p1_oid);
ok($ok,'p1 del');

# make sure delete didn't put objects or oids in cache
ok_objcache($p0_oid,undef,undef,'p0 not in cache after del',__FILE__,__LINE__);
ok_objcache($p1_oid,undef,undef,'p1 not in cache after del',__FILE__,__LINE__);

# make sure objects actually deleted from database
my($count_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
my($count_not_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
 ok($count_null==2 && $count_not_null==0,'objects deleted from database');

# do it again to test deleting deleted object
my $ok=Class::AutoDB::Serialize->del($p0_oid);
ok($ok,'p0 del again');
my $ok=Class::AutoDB::Serialize->del($p1_oid);
ok($ok,'p1 del again');

# make sure delete didn't put objects or oids in cache
ok_objcache($p0_oid,undef,undef,'p0 not in cache after del again',__FILE__,__LINE__);
ok_objcache($p1_oid,undef,undef,'p1 not in cache after del again',__FILE__,__LINE__);

# make sure objects actually deleted from database
my($count_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
my($count_not_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
 ok($count_null==2 && $count_not_null==0,'objects still deleted from database after del again');

done_testing();
