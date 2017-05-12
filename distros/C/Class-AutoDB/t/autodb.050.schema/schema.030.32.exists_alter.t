########################################
# test various settings of 'alter': param missing, or set to undef, 0, or 1
# driver must call each test with arg 'setup' then with arg 'test'
# this set (30, 31, ...) starts with non-empty database and does 'alter' that
#   adds collection and expands existing collection
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil; use Person; 
my $labelprefix='add collection, alter=>0';

# %test_args, exported by schemaUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,labelprefix=>"$labelprefix:");
my $object=new Person(name=>'test object original',id=>id_next());

my($action)=@ARGV;
if ($action=~/^s/i) {
  report_pass(drop_all(),"$labelprefix: database empty");
  my $autodb=eval {new Class::AutoDB(database=>testdb)};
  is($@,'',"$labelprefix: database created");
  my $correct_tables=correct_tables(qw(Person));
  ok_dbtables($correct_tables,"$labelprefix: Expand not there, as expected");
  $test->test_put(object=>$object,correct_diffs=>{Person=>1,HasName=>1});
} elsif ($action=~/^t/i) {
  eval {require Expand};		# do it here so 'test' will alter 'setup'
  my $autodb=eval {new Class::AutoDB(database=>testdb, alter=>0)};
  like($@,qr/memory registry adds/,"$labelprefix: new failed as expected");
  my $correct_tables=correct_tables(qw(Person));
  ok_dbtables($correct_tables,"$labelprefix: tables. Expand not added as expected");
  my $correct_columns=correct_columns(qw(Person));
  ok_dbcolumns($correct_columns,"$labelprefix: columns");
  $test->test_get(get_args=>{collection=>'Person'},correct_object=>$object);
} else {
  fail("test requires 'action' parameter to be 'setup' or 'test'");
}

done_testing();

