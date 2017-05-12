########################################
# test various settings of 'alter': param missing, or set to undef, 0, or 1
# driver must call each test with arg 'setup' then with arg 'test'
# this set (20, 21, ...) starts with non-empty database and does 'alter' that
#   adds collection
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil; use Place; 
my $labelprefix='add collection, alter=>undef';

# %test_args, exported by schemaUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,labelprefix=>"$labelprefix:");
my $object=new Place(name=>'test object original',id=>id_next());

my($action)=@ARGV;
if ($action=~/^s/i) {
  report_pass(drop_all(),"$labelprefix: database empty");
  my $autodb=eval {new Class::AutoDB(database=>testdb)};
  is($@,'',"$labelprefix: database created");
  my $correct_tables=correct_tables(qw(Place));
  ok_dbtables($correct_tables,"$labelprefix: NewColl not there, as expected");
  $test->test_put(object=>$object,correct_diffs=>1);
} elsif ($action=~/^t/i) {
  eval {require NewColl};		# do it here so 'test' will alter 'setup'
  my $autodb=eval {new Class::AutoDB(database=>testdb,alter=>undef)};
  is($@,'',"$labelprefix: new");
  my $correct_tables=correct_tables(qw(Place NewColl));
  ok_dbtables($correct_tables,"$labelprefix: tables");
  my $correct_columns=correct_columns(qw(Place NewColl));
  ok_dbcolumns($correct_columns,"$labelprefix: columns");
  $test->test_get(get_args=>{collection=>'Place'},correct_object=>$object);
  my $object=new NewColl(name=>'test object expanded',id=>id_next());
  $test->test_put(object=>$object);
} else {
  fail("test requires 'action' parameter to be 'setup' or 'test'");
}

done_testing();

