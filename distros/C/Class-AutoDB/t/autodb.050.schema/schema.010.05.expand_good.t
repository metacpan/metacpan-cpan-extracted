########################################
# test schema alterations. alter Person and add Expand
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil; use Expand; 
 
my $autodb=eval {new Class::AutoDB(database=>testdb,alter=>1)};
is($@,'','alter Person and add Expand');
expand_coll('Person',[qw(expand)],[qw(expand_list)]);

my $correct_tables=correct_tables(qw(Person Place Thing Expand));
ok_dbtables($correct_tables,'alter Person and add Expand: tables');
my $correct_columns=correct_columns(qw(Person Place Thing Expand));
ok_dbcolumns($correct_columns,'alter Person and add Expand: columns');

done_testing();

