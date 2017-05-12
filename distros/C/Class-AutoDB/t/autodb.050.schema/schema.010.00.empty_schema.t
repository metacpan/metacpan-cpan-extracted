########################################
# test schema alterations. this one creates empty db
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil;

drop_all();			# start clean. drop all tables
my $autodb=eval {new Class::AutoDB(database=>testdb,create=>1)};
is($@,'','no collections: new');
my $correct_tables=correct_tables();
ok_dbtables($correct_tables,'no collections: tables');
my $correct_columns=correct_columns();
ok_dbcolumns($correct_columns,'no collections: columns');

done_testing();

