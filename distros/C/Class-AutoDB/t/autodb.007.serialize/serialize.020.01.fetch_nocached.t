########################################
# fetch deleted objects stored by previous test
# tests fetch by oid (as number) when object and Oid not yet in object cache
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

# fetch persistent objects
id_next(); id_next();		# skip ids of non-peristent objects
my $p0_oid=$id2oid{id_next()};
my $p1_oid=$id2oid{id_next()};
my $p0=eval{Class::AutoDB::Serialize->fetch($p0_oid);};
is($@,'','p0 fetch');
my $p1=eval{Class::AutoDB::Serialize->fetch($p1_oid);};
is($@,'','p1 fetch');

ok_objcache($p0,$p0_oid,'OidDeleted','Persistent','p0 fetched as deleted Oid',__FILE__,__LINE__);
ok_objcache($p1,$p1_oid,'OidDeleted','Persistent','p1 fetched as deleted Oid',__FILE__,__LINE__);

done_testing();
