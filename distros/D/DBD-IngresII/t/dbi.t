use strict;
use warnings;
use utf8;

use Test::More;
use DBD::IngresII;
use DBI qw(:sql_types);

my $testtable = 'testhththt';

sub get_dbname {
    # find the name of a database on which test are to be performed
    my $dbname = $ENV{DBI_DBNAME} || $ENV{DBI_DSN};
    if (defined $dbname && $dbname !~ /^dbi:IngresII/) {
	    $dbname = "dbi:IngresII:$dbname";
    }
    return $dbname;
}

sub connect_db {
    # Connects to the database.
    # If this fails everything else is in vain!
    my ($dbname) = @_;
    $ENV{II_DATE_FORMAT}='SWEDEN';       # yyyy-mm-dd

    my $dbh = DBI->connect($dbname, '', '',
		    { AutoCommit => 0, RaiseError => 0, PrintError => 0, ShowErrorStatement=>1 })
	or die 'Unable to connect to database!';
    $dbh->{ChopBlanks} = 1;

    return $dbh;
}

my $dbname = get_dbname();

############################
# BEGINNING OF TESTS       #
############################

unless (defined $dbname) {
    plan skip_all => 'DBI_DBNAME and DBI_DSN aren\'t present';
}
else {
    plan tests => 77;
}

my $dbh = connect_db($dbname);
my($cursor, $sth);

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name CHAR(64)) WITH STRUCTURE=HEAP"),
        'Create table');
}
else {
    ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name CHAR(64))"),
        'Create table');
}
ok($dbh->do("INSERT INTO $testtable VALUES(1, 'Alligator Descartes')"),
     'Insert(value)');
ok($dbh->do("DELETE FROM $testtable WHERE id = 1"),
     'Delete');

ok($cursor = $dbh->prepare("SELECT * FROM $testtable WHERE id = ? ORDER BY id"),
     'prepare(Select)');
ok($cursor->bind_param(1, 1, {TYPE => SQL_INTEGER}),
     'Bind param 1 as 1');
ok($cursor->execute, 'Execute(select)');
my $row = $cursor->fetchrow_arrayref;
ok(!defined($row), 'Fetch from empty table');
ok($cursor->finish, 'Finish(select)');

ok(lc($cursor->{NAME}[0]) eq 'id', 'Column 1 name');
my $null = join  ':', map int($_), @{$cursor->{NULLABLE}};
ok($null eq '0:1', 'Column nullablility');
ok($cursor->{TYPE}[0] == SQL_INTEGER, 'Column TYPE');

# test on ing_type, ing_ingtypes, ing_lengths..
my $ingtypes=$cursor->{ing_type};
ok(scalar @{$ingtypes} == 2, 'Special Ingres attribute "ing_type"');
my $ingingtypes=$cursor->{ing_ingtypes};
ok(scalar @{$ingingtypes} == 2, 'Special Ingres attribute "ing_ingtypes"');
my $inglengths=$cursor->{ing_lengths};
ok(scalar @{$inglengths} == 2, 'Special Ingres attribute "ing_lengths"');

# test on ing_ph_ingtypes, ing_ph_inglengths
ok($sth = $dbh->prepare("INSERT INTO $testtable(id, name) VALUES(?, ?)"),
     'Prepare(insert with ?)');
my $ingphtypes=$cursor->{ing_ph_ingtypes};
ok(scalar @{$ingtypes} == 2, 'Special Ingres attribute "ing_ph_ingtypes"');
my $ingphlengths=$cursor->{ing_ph_inglengths};
ok(scalar @{$ingingtypes} == 2, 'Special Ingres attribute "ing_ph_inglengths"');


ok($sth = $dbh->prepare("INSERT INTO $testtable(id, name) VALUES(?, ?)"),
     'Prepare(insert with ?) (again...)');
ok($sth->bind_param(1, 1, {TYPE => SQL_INTEGER}),
     'Bind param 1 as 1');
ok($sth->bind_param(2, 'Henrik Tougaard', {TYPE => SQL_CHAR}),
     'Bind param 2 as string');
ok($sth->execute, 'Execute(insert) with params');
ok($sth->execute( 2, 'Aligator Descartes'),
     'Re-executing(insert)with params');

ok($cursor->execute, 'Re-execute(select)');
ok($row = $cursor->fetchrow_arrayref, 'Fetching row');
ok($row->[0] == 1, 'Column 1 value');
ok($row->[1] eq 'Henrik Tougaard', 'Column 2 value');
ok(!defined($row = $cursor->fetchrow_arrayref),
     'Fetching past end of data');
ok($cursor->finish, 'finish(cursor)');

ok($cursor->execute(2), 'Re-execute[select(2)] for chopblanks');
ok($cursor->{ChopBlanks}, 'ChopBlanks on by default');
$cursor->{ChopBlanks} = 0;
ok(!$cursor->{ChopBlanks}, 'ChopBlanks switched off');
ok($row = $cursor->fetchrow_arrayref, 'Fetching row');
ok($row->[1] =~ /^Aligator Descartes\s+/, 'Column 2 value');
ok($cursor->finish, 'finish(cursor)');

ok($dbh->do(
        "UPDATE $testtable SET id = 3 WHERE name = 'Alligator Descartes'"),
     'do(Update) one row');
my $numrows;
ok($numrows = $dbh->do( "UPDATE $testtable SET id = id+1" ),
     'do(Update) all rows');
ok($numrows == 2, 'Number of rows');

### Displays all records (for test of the test!)
###$sth=$dbh->prepare("select id, name FROM $testtable");
###$sth->execute;
###while (1) {
###  $row=$sth->fetchrow_arrayref or last;
###  print(DBI::neat_list($row), "\n");
###}
ok($sth=$dbh->prepare("SELECT id, name FROM $testtable WHERE id=3 FOR UPDATE OF name"),
      'prepare for update');
ok($sth->execute, 'execute select for update');
ok($row = $sth->fetchrow_arrayref, 'Fetching row for update');
ok($dbh->do("UPDATE $testtable SET name='Larry Wall' WHERE CURRENT OF $sth->{CursorName}"), 'do cursor update');
ok($sth->finish, 'finish select');
ok($sth=$dbh->prepare("SELECT id, name FROM $testtable WHERE id=3"),
      'prepare select after update');
ok($sth->execute, 'after update select execute');
ok($row = $sth->fetchrow_arrayref, 'fetching row for select_after_update');
ok($row->[1] =~ /^Larry Wall/, 'Col 2 value after update');
ok($sth->finish, 'finish');

### Displays all records (for test of the test!)
###$sth=$dbh->prepare("select id, name FROM $testtable");
###$sth->execute;
###while (1) {
###  $row=$sth->fetchrow_arrayref or last;
###  print(DBI::neat_list($row), "\n");
###}

ok($dbh->do( "DROP TABLE $testtable" ), 'Dropping table');

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name LONG VARCHAR, bin BYTE VARYING(64)) WITH STRUCTURE=HEAP"), 'Create long varchar table');
}
else {
    ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name LONG VARCHAR, bin BYTE VARYING(64))"), 'Create long varchar table');
}

ok($dbh->do("INSERT INTO $testtable (id, name) VALUES(1, '')"),
    'Long varchar zero-length insert');
ok($dbh->do("DELETE FROM $testtable WHERE id = 1"),
    'Long varchar delete');
$cursor = $dbh->prepare("INSERT INTO $testtable (id, name) VALUES (?, ?)");
$cursor->bind_param(1, 1);
$cursor->bind_param(2, 'AaBb' x 1024, DBI::SQL_LONGVARCHAR);
ok($cursor->execute, 'Long varchar insert of 4096 bytes');
$cursor->finish;
$cursor = $dbh->prepare("UPDATE $testtable SET name = ? WHERE ID = 1");
$cursor->bind_param(1, 'CcDd' x 512, DBI::SQL_LONGVARCHAR);
ok($cursor->execute, 'Long varchar update of 2048 bytes');
$cursor->finish;
ok($cursor = $dbh->prepare("SELECT name FROM $testtable"),
     'Long varchar prepare(select)');
ok($cursor->execute, 'Long varchar execute(select)');
$row = $cursor->fetchrow_arrayref;
ok(${$row}[0] eq 'CcDd' x 512, 'Long varchar fetch');
ok($cursor->finish, 'Long varchar finish');

# Reading a long varchar with LongReadLen = 0 should always return undef.
$dbh->{LongReadLen} = 0;
ok($dbh->{LongReadLen} == 0, 'Set LongReadLen = 0');
$cursor = $dbh->prepare("SELECT name FROM $testtable");
$cursor->execute;
$row = $cursor->fetchrow_arrayref;
ok(!defined $row->[0], 'Long varchar fetch with LongReadLen=0');
$cursor->finish;

# Reading a long varchar longer than LongReadLen with TruncOk set to 1
# should return the truncated value.
$dbh->{LongReadLen} = 5;
$dbh->{LongTruncOk} = 1;
$cursor = $dbh->prepare("SELECT name FROM $testtable");
$cursor->execute;
$row = $cursor->fetchrow_arrayref;
ok($row->[0] eq 'CcDdC',
     'Long varchar fetch with LongReadLen=5 LongTruncOk=1');
$cursor->finish;

# Reading a long varchar longer than LongReadLen with TrunkOk set to 0
# should fail with an error.
$dbh->{LongReadLen} = 5;
$dbh->{LongTruncOk} = 0;
$cursor = $dbh->prepare("SELECT name FROM $testtable");
$cursor->execute;
eval {
	$row = $cursor->fetchrow_arrayref;
};
ok(!defined $row, 'Long varchar fetch with LongReadLen=5 LongTruncOk=0');
$cursor->finish;

# Binary data testing
$dbh->do("DELETE FROM $testtable");
$cursor = $dbh->prepare("INSERT INTO $testtable (id, bin) VALUES (?, ?)");
$cursor->bind_param(1, 1);
$cursor->bind_param(2, "\0\1\2\3\0\1\2\3\0\1\2\3", DBI::SQL_VARBINARY);
ok($cursor->execute, 'Insert of binary data');
$cursor->finish;
$cursor = $dbh->prepare("SELECT bin FROM $testtable WHERE id = 1");
$cursor->execute;
$row = $cursor->fetchrow_arrayref;
ok(${$row}[0] eq "\0\1\2\3\0\1\2\3\0\1\2\3", 'Binary data fetch');
$cursor->finish;

#get_info
use DBI::Const::GetInfoType;
if ($dbh->ing_is_vectorwise) {
    ok($dbh->get_info($GetInfoType{SQL_DBMS_NAME}) eq 'Vectorwise', 'get_info(DBMS name)');
}
else {
    ok($dbh->get_info($GetInfoType{SQL_DBMS_NAME}) eq 'Ingres', 'get_info(DBMS name)');
}

#table_info
$sth = $dbh->table_info('','',$testtable);
my $href = $sth->fetchrow_hashref;
ok (${$href}{table_name} eq $testtable, "table_info($testtable)");
$sth = $dbh->table_info('','','%'.substr($testtable,2,4).'%');
$href = $sth->fetchrow_hashref;
ok (${$href}{table_name} eq $testtable, 'table_info(Wildcards)');
$sth = $dbh->column_info('','',$testtable,'bin');
$href = $sth->fetchrow_hashref;

#column_info
ok (${$href}{type_name} eq 'BYTE VARYING', 'column_info(type name)');
$sth = $dbh->column_info('','',$testtable,'bin');
$href = $sth->fetchrow_hashref;
ok (${$href}{column_size} == 64, 'column_info(column size)');

#type_info
# number of supported datatypes (supported by type_info, that means)
my @type_info = $dbh->type_info(DBI::SQL_ALL_TYPES);
ok (@type_info == 24, 'type_info(count)');
$sth->finish;

ok($dbh->do( "DROP TABLE $testtable" ), 'Dropping table');
ok($dbh->rollback, 'Rolling back');
#   What else??
ok(!$dbh->{AutoCommit}, 'AutoCommit switched off upon connect time');
$dbh->{AutoCommit}=1;
ok($dbh->{AutoCommit}, 'AutoCommit switched on');
$dbh->{AutoCommit}=1;
ok($dbh->{AutoCommit}, 'AutoCommit switched on again');

ok($dbh->disconnect, 'Disconnecting');

$dbh = DBI->connect("$dbname") or die "not ok 999 - died due to $DBI::errstr";
ok($dbh->{AutoCommit}, 'AutoCommit switched on by default');
$dbh and $dbh->{AutoCommit}=0;
ok(!$dbh->{AutoCommit}, 'AutoCommit switched off explicitly');
$
dbh and $dbh->commit;
$dbh and $dbh->disconnect;