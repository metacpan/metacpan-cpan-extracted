#
# Test various functions for each data type supported.
#

use DBI qw(:sql_types);
use Test::Harness qw($verbose);
require DBD::Ingres;

my $num_test = 5 + ($#{DBD::Ingres::db->type_info_all()}) * 23;

$verbose = $Test::Harness::verbose || 1;
my $testtable = "testhththt";
my $t = 1;

sub ok ($$) {
    my ($ok, $expl) = @_;
    print "Testing $expl\n" if $verbose;
    ($ok) ? print "ok $t\n" : print "not ok $t\n";
    if (!$ok && $warn) {
	$warn = $DBI::errstr if $warn eq '1';
	$warn = "" unless $warn;
	warn "$expl $warn\n";
    }
    ++$t;
    $ok;
}

sub get_dbname {
    # find the name of a database on which test are to be performed
    # Should ask the user if it can't find a name.
    my $dbname = $ENV{DBI_DBNAME} || $ENV{DBI_DSN};
    if (defined $dbname && $dbname !~ /^dbi:Ingres/) {
	$dbname = "dbi:Ingres:$dbname";
    }
    $dbname;
}

sub connect_db ($) {
    # Connects to the database.
    # If this fails everything else is in vain!
    my ($dbname) = @_;
    $ENV{II_DATE_FORMAT}="SWEDEN";       # yyyy-mm-dd

    my $dbh = DBI->connect($dbname, "", "",
		    { AutoCommit => 0, RaiseError => 0, PrintError => 1, ShowErrorStatement=>1 })
	or return undef;
    $dbh->{ChopBlanks} = 0;

    $dbh;
}

my $dbname = get_dbname();

if (!defined $dbname) {
    print "1..0\n";
    print "ok 1 # skipped\n";
    warn "\nSkipping tests, DBI_DBNAME/DBI_DSN environment variable not set.\n";
    exit 0;
}

print "1..$num_test\n";

my $dbh;

unless (ok($dbh = connect_db($dbname), "Connecting to database: $dbname")) {
    while ($t <= $num_test) {
	print "not ok $t # skipped\n";
	++$t;
    }
    exit 0;
}
	
#
# Table creation/destruction.  Can't do much else if this isn't working.
#
eval { local $dbh->{RaiseError}=0;
       local $dbh->{PrintError}=0;
       $dbh->do("DROP TABLE $testtable"); };
ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name CHAR(64))"),
      "Basic create table");
ok($dbh->do("INSERT INTO $testtable VALUES(1, 'Alligator Descartes')"),
      "Basic insert(value)");
ok($dbh->do("DELETE FROM $testtable WHERE id = 1"),
      "Basic Delete");
ok($dbh->do( "DROP TABLE $testtable" ),
      "Basic drop table");

#
# For each supported data type, we need to test
#
#   1. inserting into a table using a bind_param of that type as a value
#   2. selecting from a table a field with that type
#   3. selecting from a table using a bind_param of that type as a selector
#   4. inserting into a table using a null bind_param of that type as a value
#   5. selecting from a table a null field with that type
#
# For extra paranoia we undef the variable after binding but before
# executing to make sure we aren't core dumping due to referencing things
# without updating their reference counts.
#

my %testvals = (
    'SMALLINT'		=> 32511,
    'INTEGER'		=> 1234567,
    'MONEY'		=> 49711.39,
    'FLOAT'		=> 3.1415926,
    'DATE'		=> "1963-03-15 04:55:22",
    'DECIMAL'		=> 98,
    'VARCHAR'		=> "Apricot" x 3,
    'BYTE VARYING'	=> "Ab\0" x 10,
    'CHAR'		=> "AaBb",
    'BYTE'		=> "\3\0\2\1",
    'LONG VARCHAR'	=> "CcDd" x 4096,
    'LONG BYTE'		=> "Ee\0Ff\1Gg\2Hh\0" x 2048,
);

my $types = $dbh->type_info_all();

for (my $i=1; $i <= $#{$types}; ++$i) {
    my $name = $types->[$i]->[$types->[0]->{TYPE_NAME}];
    my $sqltype = $types->[$i]->[$types->[0]->{DATA_TYPE}];
    my $searchable = $types->[$i]->[$types->[0]->{SEARCHABLE}];
    my $nullable = $types->[$i]->[$types->[0]->{NULLABLE}];
    my $params = $types->[$i]->[$types->[0]->{CREATE_PARAMS}];
    my $val = $testvals{$name};

    unless ($val) {
	warn "No default value for type $name\n";
	next;
    }

    # Update the type based on the create params
    if ($params && $params =~ /max length/) {
	$name .= "(2000)";
    } elsif ($params && $params =~ /length/) {
	$name .= "(64)";
	$val = sprintf("%-64s", $val);
    } elsif ($params && $params =~ /size=/) {
	$params =~ s/.*size=([0-9,]*).*/$1/;
	my @sizes = split(/,/, $params);
	$name .= $sizes[-1];
    }

    # CREATE TABLE OF APPROPRIATE TYPE
    ok($dbh->do("CREATE TABLE $testtable (val $name)"),
	  "Create table ($name)");

    # INSERT BOUND VALUE
    ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
	  "Insert prepare ($name)");
    {
	# By allowing the bind param to go out of scope we make sure the driver
	# has either copied it or has all its ref counting on it right.
	my $destroyval = $val;
	ok($cursor->bind_param(1, $destroyval, { TYPE => $sqltype }),
	      "Insert bind param ($name)");
    }
    ok($cursor->execute,
	  "Insert execute ($name)");
    ok($cursor->finish,
	  "Insert finish ($name)");

    # SELECT VALUE
    ok($cursor = $dbh->prepare("SELECT val FROM $testtable"),
	  "Select prepare ($name)");
    ok($cursor->execute,
	  "Select execute ($name)");
    my $ar = $cursor->fetchrow_arrayref; 
    ok($ar && $ar->[0] eq $val,
	  "Select fetch ($name)")
	or print STDERR "Got '$ar->[0]', expected '$val'.\n";
    ok($cursor->finish,
	  "Select finish ($name)");

    # FETCH BOUND SELECTOR
    if ($searchable) {

	ok($cursor = $dbh->prepare("SELECT * FROM $testtable WHERE val = ?"),
	      "Select with bound selector prepare ($name)");
	my $destroyval = $val;
	ok($cursor->bind_param(1, $destroyval, { TYPE => $sqltype }),
	      "Select with bound selector bind_param ($name)");
	undef $destroyval;
	ok($cursor->execute,
	      "Select with bound selector execute ($name)");
	$ar = $cursor->fetchrow_arrayref; 
	ok($ar && "$ar->[0]" eq "$val",
	      "Select with bound selector fetch ($name)")
	    or print STDERR "Got '$ar->[0]', expected '$val'.\n";
	ok($cursor->finish,
	      "Select with bound selector finish ($name)");
    } else {
	# These dummies make it easier to set num_tests.  We have to skip
	# these tests because you can't select on some types.
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
    }

    # CLEAN UP FOR NULL STUFF
    $dbh->do("DELETE FROM $testtable");

    # INSERT NULL VALUE
    if ($nullable) {
	ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
	      "Insert null prepare ($name)");
	ok($cursor->bind_param(1, undef, { TYPE => $sqltype }),
	      "Insert null bind param ($name)");
	ok($cursor->execute,
	      "Insert null execute ($name)");
	ok($cursor->finish,
	      "Insert null finish ($name)");

	# SELECT NULL VALUE
	ok($cursor = $dbh->prepare("SELECT val FROM $testtable"),
	      "Select null prepare ($name)");
	ok($cursor->execute,
	      "Select null execute ($name)");
	ok(!defined ($cursor->fetchrow_arrayref->[0]),
	      "Select null fetch ($name)");
	ok($cursor->finish,
	      "Select null finish ($name)");
    } else {
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
	ok(1, "Dummy test.");
    }

    # DROP TABLE AGAIN
    ok($dbh->do("DROP TABLE $testtable"),
	  "Drop table ($name)");
}

$dbh and $dbh->commit;
$dbh and $dbh->disconnect;
	  
exit(0);
