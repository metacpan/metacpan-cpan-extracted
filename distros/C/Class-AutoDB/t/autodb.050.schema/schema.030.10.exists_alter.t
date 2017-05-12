########################################
# test various settings of 'alter': param missing, or set to undef, 0, or 1
# driver must call each test with arg 'setup' then with arg 'test'
# this set (10, 11, ...) starts with non-empty database and does 'alter' that
#   doesn't change the schema
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil; use Place;
my $labelprefix='alter default';

# %test_args, exported by schemaUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,labelprefix=>"$labelprefix:");
my $object=new Place(name=>'test object',id=>id_next());

my($action)=@ARGV;
if ($action=~/^s/i) {
  report_pass(drop_all(),"$labelprefix: database empty");
  my $autodb=eval {new Class::AutoDB(database=>testdb)};
  is($@,'',"$labelprefix: database created");
  $test->test_put(object=>$object,correct_diffs=>1);
} elsif ($action=~/^t/i) {
  my $autodb=eval {new Class::AutoDB(database=>testdb)};
  is($@,'',"$labelprefix: new");
  my $correct_tables=correct_tables(qw(Place));
  ok_dbtables($correct_tables,"$labelprefix: tables");
  my $correct_columns=correct_columns(qw(Place));
  ok_dbcolumns($correct_columns,"$labelprefix: columns");
  $test->test_get(get_args=>{collection=>'Place'},correct_object=>$object);
} else {
  fail("test requires 'action' parameter to be 'setup' or 'test'");
}

done_testing();

