########################################
# test schema alterations. add Person
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil; use Person;

my $autodb=eval {new Class::AutoDB(database=>testdb)};
is($@,'','add Person: new');
my $correct_tables=correct_tables(qw(Person));
ok_dbtables($correct_tables,'add Person: tables');
my $correct_columns=correct_columns(qw(Person));
ok_dbcolumns($correct_columns,'add Person: columns');

done_testing();

