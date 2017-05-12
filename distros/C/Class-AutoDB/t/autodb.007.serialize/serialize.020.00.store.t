########################################
# create and store some objects, then delete them by setting object=NULL
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

# store the persistent ones & make sure they were really stored
my $ok=1;
eval{$p0->store; $p1->store;};
$ok&=report_fail($@ eq '','p0 & p1 store');
my($new_count)=$dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB;));
my $actual_diff=$new_count-$old_count;
$ok&=report_fail($actual_diff==2,'store correct number of objects');
report_pass($ok,'store');

# remember oids for next test
my @oids=map {$_->oid} ($p0,$p1);
my @ids=map {$_->id} ($p0,$p1);
@oid{@oids}=@oids;
@oid2id{@oids}=@ids;
@id2oid{@ids}=@oids;

# delete objects from database by setting object=NULL
my $oids=join(', ',@oids);
$dbh->do(qq(UPDATE _AutoDB SET object=NULL WHERE oid IN ($oids)));
$ok=report_fail(!$dbh->err,$dbh->errstr);

# make sure it really happened
my($count)=$dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid IN ($oids) AND object IS NULL;));
ok($count==2,'objects deleted from database by setting object=NULL');

done_testing();
