########################################
# test schema alterations. add Place
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil; use Place;

my $autodb=eval {new Class::AutoDB(database=>testdb)};
is($@,'','add Place: new');
my $correct_tables=correct_tables(qw(Person Place));
ok_dbtables($correct_tables,'add Place: tables');
my $correct_columns=correct_columns(qw(Person Place));
ok_dbcolumns($correct_columns,'add Place: columns');

done_testing();

