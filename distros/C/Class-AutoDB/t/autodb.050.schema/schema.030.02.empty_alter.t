########################################
# test various settings of 'alter': param missing, or set to undef, 0, or 1
# driver must call each test with arg 'setup' then with arg 'test'
# this set (00, 01, ...) starts with empty database
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil; use Person;
my $labelprefix='alter=>0';

my($action)=@ARGV;
if ($action=~/^s/i) {
  report_pass(drop_all(),"$labelprefix: database empty");
} elsif ($action=~/^t/i) {
  my $autodb=eval {new Class::AutoDB(database=>testdb,alter=>0)};
  like($@,qr/memory registry adds/,"$labelprefix: new failed as expected");
  my $correct_tables=[];
  ok_dbtables($correct_tables,"$labelprefix: tables");
  my $correct_columns={};
  ok_dbcolumns($correct_columns,"$labelprefix: columns");
} else {
  fail("test requires 'action' parameter to be 'setup' or 'test'");
}

done_testing();
