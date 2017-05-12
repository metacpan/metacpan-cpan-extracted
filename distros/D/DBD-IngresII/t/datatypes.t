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
		    { AutoCommit => 0, RaiseError => 0, PrintError => 1, ShowErrorStatement=>1 })
	or die 'Unable to connect to database!';
    $dbh->{ChopBlanks} = 0;

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
    #plan tests => 4;
    plan tests => (4 + ($#{DBD::IngresII::db->type_info_all()} - 3) * 23);
}

my $dbh = connect_db($dbname);

#
# Table creation/destruction.  Can't do much else if this isn't working.
#
eval { local $dbh->{RaiseError}=0;
       local $dbh->{PrintError}=0;
       $dbh->do("DROP TABLE $testtable"); };

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name CHAR(64)) WITH STRUCTURE=HEAP"), "Basic create table");
}
else {
    ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name CHAR(64))"), "Basic create table");
}

ok($dbh->do("INSERT INTO $testtable VALUES(1, 'Alligator Descartes')"), "Basic insert(value)");
ok($dbh->do("DELETE FROM $testtable WHERE id = 1"), "Basic Delete");
ok($dbh->do("DROP TABLE $testtable" ), "Basic drop table");

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
    'SMALLINT'                       => 32511,
    'INTEGER'                        => 1234567,
    'MONEY'                          => 49711.39,
    'FLOAT'                          => 3.1415926,
    'ANSIDATE'                       => '1963-03-15',
    'DECIMAL'                        => 98,
    'VARCHAR'                        => 'Apricot' x 3,
    'BYTE VARYING'                   => "Ab\0" x 10,
    'C'                              => 'aBc',
    'CHAR'                           => 'AaBb',
    'BYTE'                           => "\3\0\2\1",
    'LONG VARCHAR'                   => 'CcDd' x 4096,
    'LONG BYTE'                      => "Ee\0Ff\1Gg\2Hh\0" x 2048,
    'TIMESTAMP'                      => '1963-03-15 04:55:22.000100',
    'TIMESTAMP WITH TIME ZONE'       => '2005-01-12 12:47:32.244561-04:00',
    'TIMESTAMP WITH LOCAL TIME ZONE' => '2006-01-12 10:56:12.245562',
    'TIME'                           => '12:45:11',
    'TIME WITH TIME ZONE'            => '12:47:32-04:00',
    'TIME WITH LOCAL TIME ZONE'      => '12:45:02',
    'INTERVAL YEAR TO MONTH'         => '55-04',
    'INTERVAL DAY TO SECOND'         => '-18 12:02:23'

);

my $types = $dbh->type_info_all();

for (1..$#{$types}) {
    my $name = $types->[$_]->[$types->[0]->{TYPE_NAME}];
    my $sqltype = $types->[$_]->[$types->[0]->{DATA_TYPE}];
    my $searchable = $types->[$_]->[$types->[0]->{SEARCHABLE}];
    my $nullable = $types->[$_]->[$types->[0]->{NULLABLE}];
    my $params = $types->[$_]->[$types->[0]->{CREATE_PARAMS}];
    my $val = $testvals{$name};
    my $cursor;

    next if (($name eq 'NCHAR') || ($name eq 'NVARCHAR'));
    next if ($name eq 'BOOLEAN');

    unless ($val) {
	    die "No default value for type $name\n";
    }

    # Update the type based on the create params
    if ($params && $params =~ /max length/) {
	    $name .= '(2000)';
    }
    elsif ($params && $params =~ /length/) {
	    $name .= '(64)';
	    $val = sprintf('%-64s', $val);
    }
    elsif ($params && $params =~ /size=/) {
	    $params =~ s/.*size=([0-9,]*).*/$1/;
	    my @sizes = split(/,/, $params);
	    $name .= $sizes[-1];
    }

    # CREATE TABLE OF APPROPRIATE TYPE
    if ($dbh->ing_is_vectorwise) {
        ok($dbh->do("CREATE TABLE $testtable (val $name) WITH STRUCTURE=HEAP"),
	      "Create table ($name)");
    }
    else {
        ok($dbh->do("CREATE TABLE $testtable (val $name)"),
	      "Create table ($name)");
    }

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
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
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
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    	ok(1, 'Dummy test.');
    }

    # DROP TABLE AGAIN
    ok($dbh->do("DROP TABLE $testtable"),
	  "Drop table ($name)");
}

$dbh and $dbh->commit;
$dbh and $dbh->disconnect;

exit(0);