########################################
# fetch deleted objects when OidDeleted already in object cache
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

# conjure up Oids for the stored objects
id_next(); id_next();		# skip ids of non-peristent objects
my $p0_oid=$id2oid{id_next()};
my $p1_oid=$id2oid{id_next()};
conjure_oid($p0_oid,'OidDeleted','Persistent');
conjure_oid($p1_oid,'OidDeleted','Persistent');

# fetch persistent ones.
my $actual_p0=eval{Class::AutoDB::Serialize->fetch($p0_oid);};
is($@,'','p0 fetch when OidDeleted exists');
my $actual_p1=eval{Class::AutoDB::Serialize->fetch($p1_oid);};
is($@,'','p1 fetch when OidDeleted exists');

ok_objcache($actual_p0,$p0_oid,'OidDeleted','Persistent',
	    'p0 fetched as OidDeleted when OidDeleted exists',__FILE__,__LINE__);
ok_objcache($actual_p1,$p1_oid,'OidDeleted','Persistent',
	    'p1 fetched as OidDeleted when OidDeleted exists',__FILE__,__LINE__);

done_testing();
