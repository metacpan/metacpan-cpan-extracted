########################################
# fetch deleted objects when object already in object cache
# different pattern than other tests
#   have to create & delete objects here rather than use ones stored by previous test
#   since that's the only way we can get the objects into cache...
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

# make some non persistent objects
my $np0=new NonPersistent(name=>'np0',id=>id_next());
my $np1=new NonPersistent(name=>'np1',id=>id_next());

# make some persistent objects
# these have identical content to previously stored objects but different oids, of course
my $p0=new Persistent(name=>'p0',id=>id_next());
my $p1=new Persistent(name=>'p1',id=>id_next());

# link them together
$np0->p0($p0); $np0->p1($p1); $np0->np0($np0); $np0->np1($np1);
$np1->p0($p0); $np1->p1($p1); $np1->np0($np0); $np1->np1($np1);
$p0->p0($p0); $p0->p1($p1); $p0->np0($np0); $p0->np1($np1);
$p1->p0($p0); $p1->p1($p1); $p1->np0($np0); $p1->np1($np1);

# the code below for storing and deleting objects adapted from 00.store
# store the persistent ones & make sure they were really stored
my $ok=1;
my($old_count)=$dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB;));
eval{$p0->store; $p1->store;};
$ok&=report_fail($@ eq '','p0 & p1 store');
my($new_count)=$dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB;));
my $actual_diff=$new_count-$old_count;
$ok&=report_fail($actual_diff==2,'store correct number of objects');
my @oids=map {$_->oid} ($p0,$p1);
my $oids=join(', ',@oids);
# delete objects from database by setting object=NULL
my($old_count)=$dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB WHERE object IS NULL;));
$dbh->do(qq(UPDATE _AutoDB SET object=NULL WHERE oid in ($oids)));
$ok&=report_fail(!$dbh->err,$dbh->errstr);
# make sure it really happened
my($new_count)=$dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB WHERE object IS NULL;));
my $actual_diff=$new_count-$old_count;
$ok&=$actual_diff==2;
report($ok,'objects stored and deleted');

# now on the real tests
my $p0_oid=$p0->oid;
my $p1_oid=$p1->oid;

ok_objcache($p0,$p0_oid,'object','Persistent','p0 cache entry before fetch',__FILE__,__LINE__);
ok_objcache($p1,$p1_oid,'object','Persistent','p1 cache entry before fetch',__FILE__,__LINE__);

# fetch persistent ones. 
my $actual_p0=eval{Class::AutoDB::Serialize->fetch($p0_oid);};
is($@,'','p0 fetch when object exists');
my $actual_p1=eval{Class::AutoDB::Serialize->fetch($p1_oid);};
is($@,'','p1 fetch when object exists');

# should get same object frames since already in memory
is($actual_p0,$p0,'p0 fetch when object exists got same object');
is($actual_p1,$p1,'p1 fetch when object exists got same object');

ok_objcache($actual_p0,$p0_oid,'OidDeleted','Persistent',
	    'p0 fetched as OidDeleted when object exists',__FILE__,__LINE__);
ok_objcache($actual_p1,$p1_oid,'OidDeleted','Persistent',
	    'p1 fetched as OidDeleted when object exists',__FILE__,__LINE__);

done_testing();
