########################################
# create and store some objects, as a preamble to deleting them
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

# make some persistent objects
my $p0=new Persistent(name=>'p0',id=>id_next());
my $p1=new Persistent(name=>'p1',id=>id_next());

# store the persistent objects & make sure they were really stored
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

done_testing();
