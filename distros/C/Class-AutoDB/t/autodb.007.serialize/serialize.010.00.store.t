########################################
# create and store some objects
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
my($old_count)=$dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB;));

# make some non persistent objects
my $np0=new NonPersistent(name=>'np0',id=>id_next());
my $np1=new NonPersistent(name=>'np1',id=>id_next());

# make some persistent objects
my $p0=new Persistent(name=>'p0',id=>id_next());
my $p1=new Persistent(name=>'p1',id=>id_next());

# link them together
$np0->p0($p0); $np0->p1($p1); $np0->np0($np0); $np0->np1($np1);
$np1->p0($p0); $np1->p1($p1); $np1->np0($np0); $np1->np1($np1);
$p0->p0($p0); $p0->p1($p1); $p0->np0($np0); $p0->np1($np1);
$p1->p0($p0); $p1->p1($p1); $p1->np0($np0); $p1->np1($np1);

# store the persistent ones
eval{$p0->store;};
is($@,'','p0 store');
eval{$p1->store;};
is($@,'','p1 store');

# make sure they were really stored
my($new_count)=$dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB;));
my $actual_diff=$new_count-$old_count;
is($actual_diff,2,'store correct number of objects');

# remember oids for next test
my @oids=map {$_->oid} ($p0,$p1);
my @ids=map {$_->id} ($p0,$p1);
@oid{@oids}=@oids;
@oid2id{@oids}=@ids;
@id2oid{@ids}=@oids;

# fetch them back. should get same objects since already in memory
my $actual_p0=Class::AutoDB::Serialize->fetch($p0->oid);
my $actual_p1=Class::AutoDB::Serialize->fetch($p1->oid);
is($actual_p0,$p0,'p0 fetch');
is($actual_p1,$p1,'p1 fetch');

done_testing();
