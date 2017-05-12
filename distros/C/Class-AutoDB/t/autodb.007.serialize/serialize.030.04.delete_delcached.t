########################################
# delete objects when OidDeleted already in object cache
# have to rerun 030.00.store before running this to recreate objects
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
my $oids=join(', ',$p0_oid,$p1_oid);

# for sanity, make sure objects in database
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
report_fail(!$dbh->err,$dbh->errstr,__FILE__,__LINE__);
report_fail($count==2,'bad news: objects not in database at start of test',__FILE__,__LINE__);

# conjure up Oids for the stored objects
conjure_oid($p0_oid,'OidDeleted','Persistent');
conjure_oid($p1_oid,'OidDeleted','Persistent');

# delete the objects
my $ok=Class::AutoDB::Serialize->del($p0_oid);
ok(!$ok,'p0 del');
my $ok=Class::AutoDB::Serialize->del($p1_oid);
ok(!$ok,'p1 del');

ok_objcache($p0_oid,'OidDeleted','Persistent','p0 still OidDeleted after del',__FILE__,__LINE__);
ok_objcache($p1_oid,'OidDeleted','Persistent','p1 still OidDeleted after del',__FILE__,__LINE__);

# objects should not be deleted from database, since we lied to the code and said
# they were already deleted
my($count_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
my($count_not_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
ok($count_null==0 && $count_not_null==2,'objects not deleted from database');

# do it again to test deleting deleted object
my $ok=Class::AutoDB::Serialize->del($p0_oid);
ok(!$ok,'p0 del again');
my $ok=Class::AutoDB::Serialize->del($p1_oid);
ok(!$ok,'p1 del again');

ok_objcache($p0_oid,'OidDeleted','Persistent',
	    'p0 still OidDeleted after del again',__FILE__,__LINE__);
ok_objcache($p1_oid,'OidDeleted','Persistent',
	    'p1 still OidDeleted after del again',__FILE__,__LINE__);

# make sure objects still not deleted from database
my($count_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
my($count_not_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
ok($count_null==0 && $count_not_null==2,'objects still not deleted from database after del again');

done_testing();
