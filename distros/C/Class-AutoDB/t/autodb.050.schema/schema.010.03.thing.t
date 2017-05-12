########################################
# test schema alterations. add Thing
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil; use Thing;

my $autodb=eval {new Class::AutoDB(database=>testdb)};
is($@,'','add Thing: new');
my $correct_tables=correct_tables(qw(Person Place Thing));
ok_dbtables($correct_tables,'add Thing: tables');
my $correct_columns=correct_columns(qw(Person Place Thing));
ok_dbcolumns($correct_columns,'add Thing: columns');

done_testing();
