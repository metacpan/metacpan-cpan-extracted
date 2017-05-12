########################################
# test schema alterations. try to alter Person and add Expand
########################################
use t::lib;
use strict;
use Test::More;

use Class::AutoDB;
use schemaUtil; use Expand; 

my $autodb=eval {new Class::AutoDB(database=>testdb)};
like($@,qr/expand/,'alter Person and add Expand: new failed as expected');
my $correct_tables=correct_tables(qw(Person Place Thing));
ok_dbtables($correct_tables,'alter Person and add Expand: tables unchanged as expected');
my $correct_columns=correct_columns(qw(Person Place Thing));
ok_dbcolumns($correct_columns,'alter Person and add Expand: columns unchanged as expected');

done_testing();
