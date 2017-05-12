use strict;
use warnings;

use Test::DBO ExampleP => 'ExampleP';
use Test::DBO Sponge => 'Sponge', tests => 45;

MySponge::db::setup([qw(id name age)], [123, 'vlyon', 77]);

{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn .= join '', @_;
    };
    local $Carp::Verbose = 0;
    DBIx::DBO->import(
        DebugSQL => 0,
        QuoteIdentifier => 1,
        CacheQuery => 0,
        UseHandle => 0,
        'NoValue'
    );
    is $warn =~ s/^(Import option 'NoValue' passed without a value|Unknown import option 'UseHandle') at .* line \d+\.?\n//mg, 2, 'DBIx::DBO->import validation';
    is $warn, '', 'DBIx::DBO->import options';
}

eval { DBIx::DBO->new(1, 2, 3, 4) };
like $@, qr/^Too many arguments for (DBIx::DBO::new|\(eval\)) /, 'DBIx::DBO->new takes only 3 args';

eval { DBIx::DBO->new(1, 2, \3) };
like $@, qr/^3rd argument to (DBIx::DBO::new|\(eval\)) is not a HASH reference /, 'DBIx::DBO->new 3rd arg must be a HASH';

eval { DBIx::DBO->new(undef, undef, {dbd => ''}) };
like $@, qr/^Can't create the DBO, unknown database driver /, 'DBIx::DBO->new requires a DBD';

eval { DBIx::DBO->new(123, undef) };
like $@, qr/^Invalid read-write database handle /, 'DBIx::DBO->new validate read-write $dbh';

eval { DBIx::DBO->new(undef, 123) };
like $@, qr/^Invalid read-only database handle /, 'DBIx::DBO->new validate read-only $dbh';

my $dbh1 = MySponge->connect('DBI:Sponge:') or die $DBI::errstr;
my $dbh2 = DBI->connect('DBI:ExampleP:') or die $DBI::errstr;

eval { DBIx::DBO->new($dbh1, $dbh1, {dbd => 'NoDBD'}) };
is $@, '', 'DBD class is overridable';

eval { DBIx::DBO->new($dbh1, $dbh2, {dbd => 'NoDBD'}) };
like $@, qr/^The read-write and read-only connections must use the same DBI driver /, 'Validate both $dbh drivers';

my $dbo = DBIx::DBO->new($dbh2, undef, {dbd => 'NoDBD'}) or die $DBI::errstr;
eval { $dbo->connect_readonly('DBI:Sponge:') };
like $@, qr/^The read-write and read-only connections must use the same DBI driver /m, 'Check extra connection driver';

eval { $dbo->connect('DBI:Sponge:') };
like $@, qr/^DBO is already connected /, 'DBO is already connected';

$dbo = DBIx::DBO->connect_readonly('DBI:Sponge:');
eval { $dbo->connect_readonly('DBI:Sponge:') };
is $@, '', 'DBO can replace the readonly connection';

$dbo = DBIx::DBO->new(undef, $dbh1);
my($q, $t) = $dbo->query($Test::DBO::test_tbl);
my $t2 = $dbo->table($Test::DBO::test_tbl);

eval { $t->new('no_dbo_object') };
like $@, qr/^Invalid DBO Object /, 'Requires DBO object';

eval { $dbo->table('no_such_table') };
like $@, qr/^Invalid table: "no_such_table" /, 'Ensure table exists';

eval { $q->where('id', '=', {FUNC => '(?,?)', VAL => [1,2,3]}) };
like $@, qr/^The number of params \(3\) does not match the number of placeholders \(2\) /,
    'Number of params must equal placeholders';

eval { $q->where('id', '<', [1,2,3]) };
like $@, qr/^Wrong number of fields\/values, called with 3 while needing 1 /, 'Wrong number of fields/values';

eval { $q->where('id', 'BETWEEN', [1,2,3]) };
like $@, qr/^Invalid value argument, BETWEEN requires 2 values /, 'BETWEEN requires 2 values';

eval { $q->show($t2) };
like $@, qr/^Invalid table to show /, 'Validate table in show';

eval { $q->join_table($t) };
like $@, qr/^This table is already in this query /, 'Check duplicate Table objects in join';

eval { $q->join_on($t2) };
like $@, qr/^Invalid table object to join onto /, 'Validate table in JOIN ON';

eval { $q->open_join_on_bracket };
like $@, qr/^Invalid table object for join on clause /, 'Require table in open_join_on_bracket';

eval { $q->open_join_on_bracket($t2) };
like $@, qr/^No such table object in the join /, 'Validate table in open_join_on_bracket';

eval { $q->close_join_on_bracket };
like $@, qr/^Invalid table object for join on clause /, 'Require table in close_join_on_bracket';

eval { $q->close_join_on_bracket($t2) };
like $@, qr/^No such table object in the join /, 'Validate table in close_join_on_bracket';

eval { $t->column('WrongColumn') };
like $@, qr/^Invalid column "WrongColumn" in table /, 'Invalid column';

eval { $t->delete($t2 ** 'name' => undef) };
like $@, qr/^Invalid column, the column is from a table not included in this query /, 'Invalid column (another table)';

eval { $t->delete(name => [qw(doesnt exist)]) };
like $@, qr/^No read-write handle connected /, 'No read-write handle connected (Table)';

eval { $q->update('id', 'oops') };
like $@, qr/^No read-write handle connected /, 'No read-write handle connected (Query)';

my $dbo2 = DBIx::DBO->new(undef, $dbh2);
eval { $dbo2->table($t) };
like $@, qr/^This table is from a different DBO connection /, 'Mismatching Table DBO in new Table';

eval { $dbo2->query($t) };
like $@, qr/^This table is from a different DBO connection /, 'Mismatching Table DBO in new Query';

eval { $dbo2->row($t) };
like $@, qr/^This table is from a different DBO connection /, 'Mismatching Table DBO in new Row';

eval { $dbo2->row($q) };
like $@, qr/^This query is from a different DBO connection /, 'Mismatching Query DBO in new Row';

(my $r, $t) = DBIx::DBO::Row->new($dbo, $t->{Name});
$r->config(LimitRowDelete => 0);
$r->config(LimitRowDelete => 1);

eval { $r->value('id') };
like $@, qr/^The row is empty /, 'Empty row';

eval { $r->update };
like $@, qr/^Can't update an empty row /, 'No row to update';

eval { $r->delete };
like $@, qr/^Can't delete an empty row /, 'No row to delete';

eval { $r->column('WrongColumn') };
like $@, qr/^No such column: "WrongColumn" /, 'No such column object';

eval { DBIx::DBO::Row->new };
like $@, qr/^Invalid DBO Object for new Row /, 'Row requires a DBO';

eval { $r->new($dbo) };
like $@, qr/^Missing parent for new Row /, 'Row requires a parent';

eval { $dbo->row($r) };
like $@, qr/^Invalid parent for new Row /, 'Row requires a valid parent';

$r = $t->fetch_row;
eval { $r->value('WrongColumn') };
like $@, qr/^No such column: "WrongColumn" /, 'Empty row';

$dbo->disconnect;
eval { $dbo->connect_readonly };
like $@, qr/^Can't auto-connect as AutoReconnect was not set /, 'AutoReconnect is off by default';

$dbo->config(AutoReconnect => 1);
$dbo->connect_readonly('DBI:Sponge:');
eval { $dbo->connect_readonly };
is $@, '', 'AutoReconnect is on';

$dbo->config(AutoReconnect => 0);
$dbo->connect_readonly('DBI:Sponge:');
eval { $dbo->connect_readonly };
like $@, qr/Can't auto-connect as AutoReconnect was not set /, 'AutoReconnect is off';

eval { $dbo->connect('') };
like $@, qr/^Can't connect to data source '' /, 'Empty DSN';

eval { $dbo->connect_readonly('DBI:ExampleP:') };
like $@, qr/The read-write and read-only connections must use the same DBI driver /, 'Check replaced connection driver';

