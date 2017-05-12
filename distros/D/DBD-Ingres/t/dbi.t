use DBI qw(:sql_types);
use vars qw($num_test);

$verbose = 1 unless defined $verbose;
my $testtable = "testhththt";

my $t = 0;
sub ok ($$$;$) {
    my ($n, $ok, $expl, $warn) = @_;
    ++$t;
    die "sequence error, expected $n but actually $t"
	if $n and $n!=$t;
    print "Testing $expl\n" if $verbose;
    ($ok) ? print "ok $t\n" : print "not ok $t\n";
    if (!$ok && $warn) {
	$warn = $DBI::errstr if $warn eq '1';
	$warn = "" unless $warn;
	warn "$expl $warn\n";
    }
}

sub openingres {
    # Returns whether this is an OpenIngres installation or not -
    # should possibly be set from Makefile.PL ??
    # better tests are needed. This fails on OpenVMS!
    $ENV{"OPENINGRES"} || (-f "$ENV{II_SYSTEM}/ingres/lib/libcompat.1.so");
}

sub get_dbname {
    # find the name of a database on which test are to be performed
    # Should ask the user if it can't find a name.
    $dbname = $ENV{DBI_DBNAME} || $ENV{DBI_DSN};
    unless ($dbname) {
        warn "No databasename specified";
        print "1..0\n";
        exit 0;
    }
    $dbname = "dbi:Ingres:$dbname" unless $dbname =~ /^dbi:Ingres/;
    $dbname;
}

sub connect_db($$) {
    # Connects to the database.
    # If this fails everything else is in vain!
    my ($num_test, $dbname) = @_;

    print "Testing: DBI->connect('$dbname'):\n"
 	if $verbose;
    my $dbh = DBI->connect($dbname, "", "",
	{ AutoCommit => 0,
#          RaiseError => 1,
	   PrintError => 0,
        });
    $dbh->{ChopBlanks} = 1;
    if ($dbh) {
        print("1..$num_test\nok 1\n");
    } else {
        print("1..0\n");
        warn("Cannot connect to database $dbname: $DBI::errstr\n");
        exit 0;
    }
    $dbh;
}

my $dbname = get_dbname;
my $openingres = openingres;
my $dbh = connect_db($num_test, $dbname);
$t = 1;

ok(2, $dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name CHAR(64))"),
     "Create table", 1);
ok(0, $dbh->do("INSERT INTO $testtable VALUES(1, 'Alligator Descartes')"),
     "Insert(value)", 1);
ok(0, $dbh->do("DELETE FROM $testtable WHERE id = 1"),
     "Delete", 1);

ok(0, $cursor = $dbh->prepare("SELECT * FROM $testtable WHERE id = ? ORDER BY id"),
     "prepare(Select)", 1);
ok(0, $cursor->bind_param(1, 1, {TYPE => SQL_INTEGER}),
     "Bind param 1 as 1", 1);
ok(0, $cursor->execute, "Execute(select)", 1);
$row = $cursor->fetchrow_arrayref;
ok(0, !defined($row), "Fetch from empty table",
     "Row is returned as: ".($row ? DBI->neat_list($row) : "''"));
ok(0, $cursor->finish, "Finish(select)", 1);

ok(0, lc($cursor->{NAME}[0]) eq "id", "Column 1 name",
     "should be 'id' is '$cursor->{NAME}[0]'");
my $null = join  ':', map int($_), @{$cursor->{NULLABLE}};
ok(0, $null eq '0:1',
     "Column nullablility",
     "Should be '0:1' is '$null'");
ok(0, $cursor->{TYPE}[0] == SQL_INTEGER,
     "Column TYPE",
     "should be '".SQL_INTEGER."' is '$cursor->{TYPE}[0]'");

# test on ing_type, ing_ingtypes, ing_lengths..
my $ingtypes=$cursor->{ing_type};
ok(0, scalar @{$ingtypes} == 2, "Special Ingres attribute 'ing_type'","wrong number of parameters");
my $ingingtypes=$cursor->{ing_ingtypes};
ok(0, scalar @{$ingingtypes} == 2, "Special Ingres attribute 'ing_ingtypes'","wrong number of parameters");
my $inglengths=$cursor->{ing_lengths};
ok(0, scalar @{$inglengths} == 2, "Special Ingres attribute 'ing_lengths'","wrong number of parameters");

# test on ing_ph_ingtypes, ing_ph_inglengths
ok(0, $sth = $dbh->prepare("INSERT INTO $testtable(id, name) VALUES(?, ?)"),
     "Prepare(insert with ?)", 1);
my $ingphtypes=$cursor->{ing_ph_ingtypes};
ok(0, scalar @{$ingtypes} == 2, "Special Ingres attribute 'ing_ph_ingtypes'","wrong number of parameters");
my $ingphlengths=$cursor->{ing_ph_inglengths};
ok(0, scalar @{$ingingtypes} == 2, "Special Ingres attribute 'ing_ph_inglengths'","wrong number of parameters");


ok(0, $sth = $dbh->prepare("INSERT INTO $testtable(id, name) VALUES(?, ?)"),
     "Prepare(insert with ?) (again...)", 1);
ok(0, $sth->bind_param(1, 1, {TYPE => SQL_INTEGER}),
     "Bind param 1 as 1", 1);
ok(0, $sth->bind_param(2, "Henrik Tougaard", {TYPE => SQL_CHAR}),
     "Bind param 2 as string" ,1);
ok(0, $sth->execute, "Execute(insert) with params", 1);
ok(0, $sth->execute( 2, 'Aligator Descartes'),
     "Re-executing(insert)with params", 1);

ok(0, $cursor->execute, "Re-execute(select)", 1);
ok(0, $row = $cursor->fetchrow_arrayref, "Fetching row", 1); 
ok(0, $row->[0] == 1, "Column 1 value",
     "Should be '1' is '$row->[0]'");
ok(0, $row->[1] eq 'Henrik Tougaard', "Column 2 value",
     "Should be 'Henrik Tougaard' is '$row->[1]'");
ok(0, !defined($row = $cursor->fetchrow_arrayref),
     "Fetching past end of data", 
     "Row is returned as: ".($row ? DBI->neat_list($row) : "''"));
ok(0, $cursor->finish, "finish(cursor)", 1);

ok(0, $cursor->execute(2), "Re-execute[select(2)] for chopblanks", 1);
ok(0, $cursor->{ChopBlanks}, "ChopBlanks on by default", 1);
$cursor->{ChopBlanks} = 0;
ok(0, !$cursor->{ChopBlanks}, "ChopBlanks switched off", 1);
ok(0, $row = $cursor->fetchrow_arrayref, "Fetching row", 1); 
ok(0, $row->[1] =~ /^Aligator Descartes\s+/, "Column 2 value",
     "Should be 'Henrik Tougaard   ...  ' is '$row->[1]'");
ok(0, $cursor->finish, "finish(cursor)", 1);

ok(0, $dbh->do(
        "UPDATE $testtable SET id = 3 WHERE name = 'Alligator Descartes'"),
     "do(Update) one row", 1);
my $numrows;
ok(0, $numrows = $dbh->do( "UPDATE $testtable SET id = id+1" ),
     "do(Update) all rows", 1);
ok(0, $numrows == 2, "Number of rows", "should be '2' is '$numrows'");

### Displays all records (for test of the test!)
###$sth=$dbh->prepare("select id, name FROM $testtable");
###$sth->execute;
###while (1) {
###  $row=$sth->fetchrow_arrayref or last;
###  print(DBI::neat_list($row), "\n");
###}
ok(0, $sth=$dbh->prepare("SELECT id, name FROM $testtable WHERE id=3 FOR UPDATE OF name"),
      "prepare for update", 1);
ok(0, $sth->execute, "execute select for update", 1);
ok(0, $row = $sth->fetchrow_arrayref, "Fetching row for update", 1);
ok(0, $dbh->do("UPDATE $testtable SET name='Larry Wall' WHERE CURRENT OF $sth->{CursorName}"), "do cursor update", 1);
ok(0, $sth->finish, "finish select", 1);
ok(0, $sth=$dbh->prepare("SELECT id, name FROM $testtable WHERE id=3"),
      "prepare select after update", 1);
ok(0, $sth->execute, "after update select execute", 1);
ok(0, $row = $sth->fetchrow_arrayref, "fetching row for select_after_update", 1);
ok(0, $row->[1] =~ /^Larry Wall/, "Col 2 value after update",
      "Should be 'Larry Wall...' is '$row->[1]'");
ok(0, $sth->finish, "finish", 1);

### Displays all records (for test of the test!)
###$sth=$dbh->prepare("select id, name FROM $testtable");
###$sth->execute;
###while (1) {
###  $row=$sth->fetchrow_arrayref or last;
###  print(DBI::neat_list($row), "\n");
###}

ok(0, $dbh->do( "DROP TABLE $testtable" ), "Dropping table", 1);
ok(0, $dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name LONG VARCHAR, bin BYTE VARYING(64))"), "Create long varchar table", 1);
ok(0, $dbh->do("INSERT INTO $testtable (id, name) VALUES(1, '')"),
    "Long varchar zero-length insert", 1);
ok(0, $dbh->do("DELETE FROM $testtable WHERE id = 1"),
    "Long varchar delete", 1);
$cursor = $dbh->prepare("INSERT INTO $testtable (id, name) VALUES (?, ?)");
$cursor->bind_param(1, 1);
$cursor->bind_param(2, "AaBb" x 1024, DBI::SQL_LONGVARCHAR);
ok(0, $cursor->execute, "Long varchar insert of 4096 bytes", 1);
$cursor->finish;
$cursor = $dbh->prepare("UPDATE $testtable SET name = ? WHERE ID = 1");
$cursor->bind_param(1, "CcDd" x 512, DBI::SQL_LONGVARCHAR);
ok(0, $cursor->execute, "Long varchar update of 2048 bytes", 1);
$cursor->finish;
ok(0, $cursor = $dbh->prepare("SELECT name FROM $testtable"),
     "Long varchar prepare(select)", 1);
ok(0, $cursor->execute, "Long varchar execute(select)", 1);
$row = $cursor->fetchrow_arrayref;
ok(0, ${$row}[0] eq 'CcDd' x 512, "Long varchar fetch", 1);
ok(0, $cursor->finish, "Long varchar finish", 1);

# Reading a long varchar with LongReadLen = 0 should always return undef.
$dbh->{LongReadLen} = 0;
ok(0, $dbh->{LongReadLen} == 0, "Set LongReadLen = 0", 1);
$cursor = $dbh->prepare("SELECT name FROM $testtable");
$cursor->execute;
$row = $cursor->fetchrow_arrayref;
ok(0, !defined $row->[0], "Long varchar fetch with LongReadLen=0", 1);
$cursor->finish;

# Reading a long varchar longer than LongReadLen with TruncOk set to 1
# should return the truncated value.
$dbh->{LongReadLen} = 5;
$dbh->{LongTruncOk} = 1;
$cursor = $dbh->prepare("SELECT name FROM $testtable");
$cursor->execute;
$row = $cursor->fetchrow_arrayref;
ok(0, $row->[0] eq 'CcDdC',
     "Long varchar fetch with LongReadLen=5 LongTruncOk=1", 1);
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
ok(0, !defined $row, "Long varchar fetch with LongReadLen=5 LongTruncOk=0", 1);
$cursor->finish;

# Binary data testing
$dbh->do("DELETE FROM $testtable");
$cursor = $dbh->prepare("INSERT INTO $testtable (id, bin) VALUES (?, ?)");
$cursor->bind_param(1, 1);
$cursor->bind_param(2, "\0\1\2\3\0\1\2\3\0\1\2\3", DBI::SQL_VARBINARY);
ok(0, $cursor->execute, "Insert of binary data", 0);
$cursor->finish;
$cursor = $dbh->prepare("SELECT bin FROM $testtable WHERE id = 1");
$cursor->execute;
$row = $cursor->fetchrow_arrayref;
ok(0, ${$row}[0] eq "\0\1\2\3\0\1\2\3\0\1\2\3", "Binary data fetch", 1);
$cursor->finish;

#get_info
use DBI::Const::GetInfoType;
ok(0, $dbh->get_info($GetInfoType{SQL_DBMS_NAME}) eq "Ingres", "get_info(DBMS name)", 1);

#table_info
$sth = $dbh->table_info('','',$testtable);
my $href = $sth->fetchrow_hashref;
ok (0, ${$href}{table_name} eq $testtable, "table_info($testtable)", 1);
$sth = $dbh->table_info('','',"%".substr($testtable,2,4)."%");
$href = $sth->fetchrow_hashref;
ok (0, ${$href}{table_name} eq $testtable, "table_info(Wildcards)", 1);
$sth = $dbh->column_info('','',$testtable,"bin");
$href = $sth->fetchrow_hashref;

#column_info
ok (0, ${$href}{type_name} eq "BYTE VARYING", "column_info(type name)", 1);
$sth = $dbh->column_info('','',$testtable,"bin");
$href = $sth->fetchrow_hashref;
ok (0, ${$href}{column_size} == 64, "column_info(column size)", 1);

#type_info
# number of supported datatypes (supported by type_info, that means)
my @type_info = $dbh->type_info(DBI::SQL_ALL_TYPES);
ok (0, @type_info == 12, "type_info(count)", 1);
$sth->finish;

ok(0, $dbh->do( "DROP TABLE $testtable" ), "Dropping table", 1);
ok(0, $dbh->rollback, "Rolling back", 1);
#   What else??
ok(0, !$dbh->{AutoCommit}, "AutoCommit switched off upon connect time", 1);
$dbh->{AutoCommit}=1;
ok(0, $dbh->{AutoCommit}, "AutoCommit switched on", 1);
$dbh->{AutoCommit}=1;
ok(0, $dbh->{AutoCommit}, "AutoCommit switched on again", 1);

ok(0, $dbh->disconnect, "Disconnecting", 1);

$dbh = DBI->connect("$dbname") or die "not ok 999 - died due to $DBI::errstr";
ok(0, $dbh->{AutoCommit}, "AutoCommit switched on by default", 1);
$dbh and $dbh->{AutoCommit}=0;
ok(0, !$dbh->{AutoCommit}, "AutoCommit switched off explicitly", 1);
$dbh and $dbh->commit;
$dbh and $dbh->disconnect;

# Missing:
#   test of outerjoin and nullability
#   what else?

BEGIN { $num_test = 78; }

