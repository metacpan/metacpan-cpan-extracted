########################################
# fetch objects stored by previous test
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

# fetch persistent ones
my $p0_oid=$id2oid{$p0->id};
my $p1_oid=$id2oid{$p1->id};
my $actual_p0=eval{Class::AutoDB::Serialize->fetch($p0_oid);};
is($@,'','p0 fetch');
my $actual_p1=eval{Class::AutoDB::Serialize->fetch($p1_oid);};
is($@,'','p1 fetch');

ok_objcache($actual_p0,$p0_oid,'object','Persistent','p0 fetched as object (not just Oid)',
	    __FILE__,__LINE__);
ok_objcache($actual_p1,$p1_oid,'object','Persistent','p1 fetched as object (not just Oid)',
	    __FILE__,__LINE__);

cmp_deeply($actual_p0,$p0,'p0 contents');
cmp_deeply($actual_p1,$p1,'p1 contents');

my @actual_reach=reach($actual_p0,$actual_p1);
my @actual_ps=grep {'Persistent' eq ref $_} @actual_reach;
my @actual_nps=grep {'NonPersistent' eq ref $_} @actual_reach;
my %actual_id2p=group {$_->id} @actual_ps;
my %actual_id2np=group {$_->id} @actual_nps;

is((grep {@$_==1} values %actual_id2p),2,'persistent objects: 1 copy each');
is((grep {@$_==2} values %actual_id2np),2,'non-persistent objects: 2 copies each');

done_testing();
