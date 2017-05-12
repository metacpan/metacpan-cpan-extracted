########################################
# this series tests OidDeleted overloaded operations
# create and store some objects.
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbUtil;

use Class::AutoDB::Serialize;
use Persistent;

my $errstr=create_autodb_table;
is($errstr,undef,'create _AutoDB table');
tie_oid('create');

my $dbh=DBI->connect("dbi:mysql:database=".testdb,undef,undef,
		     {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,});
is($DBI::errstr,undef,'connect');
Class::AutoDB::Serialize->dbh($dbh);
my($old_count)=$dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB;));

# make some persistent objects & store them
# NG 10-09-17: need 6 more objects for testing numeric comparisons
# my $NUMOBJS=8;
my $NUMOBJS=14;
my @objs=map {new Persistent(name=>"p$_",id=>id_next())} (0..$NUMOBJS-1);
map {Class::AutoDB::Serialize->store($_)} @objs;

# make sure they were really stored
my($new_count)=$dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB;));
my $actual_diff=$new_count-$old_count;
is($actual_diff,$NUMOBJS,'store correct number of objects');

# remember oids for next test
my @oids=map {obj2oid($_)} @objs;
my @ids=map {$_->id} @objs;
@oid{@oids}=@oids;
@oid2id{@oids}=@ids;
@id2oid{@ids}=@oids;

# for sanity, fetch them back. should get same objects since already in memory
for (0..$#oids) {
  my $p_actual=Class::AutoDB::Serialize->fetch($oids[$_]);
  report_fail($p_actual==$objs[$_],'bad news: fetch failed',__FILE__,__LINE__);
}

done_testing();
