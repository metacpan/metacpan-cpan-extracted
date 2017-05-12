########################################
# test deletion of objects that are not yet stored
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbUtil;

use Class::AutoDB::Serialize;
use Persistent; use NonPersistent;

my $errstr=create_autodb_table;
is($errstr,undef,'create _AutoDB table');
tie_oid('create');

my $dbh=DBI->connect("dbi:mysql:database=".testdb,undef,undef,
		     {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,});
is($DBI::errstr,undef,'connect');
Class::AutoDB::Serialize->dbh($dbh);

# make some persistent objects
my $p0=new Persistent(name=>'p0',id=>id_next());
my $p1=new Persistent(name=>'p1',id=>id_next());
my $p0_oid=$p0->oid; my $p1_oid=$p1->oid; 
my $oids=join(', ',$p0_oid,$p1_oid);
ok_objcache($p0,$p0_oid,'object','Persistent',
	    'p0 cache entry at start of test',__FILE__,__LINE__);
ok_objcache($p1,$p1_oid,'object','Persistent',
	    'p1 cache entry at start of test',__FILE__,__LINE__);

# for sanity, make sure objects not in database
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids);));
report_fail(!$dbh->err,$dbh->errstr,__FILE__,__LINE__);
report_fail($count==0,'bad news: objects in database at start of test',__FILE__,__LINE__);

my $ok=Class::AutoDB::Serialize->del($p0_oid);
ok($ok,'p0 del with cached object');
my $ok=Class::AutoDB::Serialize->del($p1_oid);
ok($ok,'p1 del with cached object');

ok_objcache($p0,$p0_oid,'OidDeleted','Persistent',
	    'p0 changed to OidDeleted by del with cached object',__FILE__,__LINE__);
ok_objcache($p1,$p1_oid,'OidDeleted','Persistent',
	    'p1 changed to OidDeleted by del with cached object',__FILE__,__LINE__);

# make sure objects actually deleted from database
my($count_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
my($count_not_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
 ok($count_null==2 && $count_not_null==0,'objects deleted from database');

# do it again with Oids in object cache
# conjure up the Oids
conjure_oid($p0_oid,'Oid','Persistent');
conjure_oid($p1_oid,'Oid','Persistent');

my $ok=Class::AutoDB::Serialize->del($p0_oid);
ok($ok,'p0 del with cached Oid');
my $ok=Class::AutoDB::Serialize->del($p1_oid);
ok($ok,'p1 del with cached Oid');

# make sure objects still deleted from database
my($count_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
my($count_not_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
 ok($count_null==2 && $count_not_null==0,'objects still deleted from database');

# note: at this point $p0_oid, $p1_oid no longer 'match' $p0, $p1, because we
#       conjured up new oids a few lines above
ok_objcache($p0_oid,'OidDeleted','Persistent',
	    'p0 still OidDeleted after del with cached Oid',__FILE__,__LINE__);
ok_objcache($p1_oid,'OidDeleted','Persistent',
	    'p1 still OidDeleted after del with cached Oid',__FILE__,__LINE__);

# do it again with OidDeleteds in object cache
conjure_oid($p0_oid,'OidDeleted','Persistent');
conjure_oid($p1_oid,'OidDeleted','Persistent');

my $ok=Class::AutoDB::Serialize->del($p0_oid);
ok(!$ok,'p0 del with cached OidDeleted');
my $ok=Class::AutoDB::Serialize->del($p1_oid);
ok(!$ok,'p1 del with cached OidDeleted');

# note: at this point $p0_oid, $p1_oid no longer 'match' $p0, $p1, because we
#       conjured up new oids a few lines above
ok_objcache($p0_oid,'OidDeleted','Persistent',
	    'p0 still OidDeleted after del with cached OidDeleted',__FILE__,__LINE__);
ok_objcache($p1_oid,'OidDeleted','Persistent',
	    'p1 still OidDeleted after del with cached OidDeleted',__FILE__,__LINE__);

# make sure objects still deleted from database
my($count_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
my($count_not_null)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NOT NULL;));
 ok($count_null==2 && $count_not_null==0,'objects still deleted from database');

done_testing();
