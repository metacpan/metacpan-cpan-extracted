#!/usr/bin/perl
#
#   @(#)$Id: t00basic.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Initial test script for DBD::Informix
#
# Copyright 1996-99 Jonathan Leffler
# Copyright 2000    Informix Software
# Copyright 2002-03 IBM
# Copyright 2005-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

my $testtable = "dbd_ix_test01";

stmt_note("1..41\n");

my $dbh = connect_to_test_database();
stmt_ok(0);

print "# DBI Information\n";
print "#     Version:                $DBI::VERSION\n";
print "# Generic Driver Handle Information\n";
print "#     Type:                   $dbh->{Driver}->{Type}\n";
print "#     Name:                   $dbh->{Driver}->{Name}\n";
print "#     Version:                $dbh->{Driver}->{Version}\n";
print "#     Attribution:            $dbh->{Driver}->{Attribution}\n";

# NB: The code in dbd_ix_db_FETCH_attrib (in dbdattr.ec) relays these
#     driver requests to dbd_ix_dr_FETCH_attrib, because there isn't
#     an easy way to get the information otherwise.
print  "# Informix Driver Handle Information\n";
print  "#     Product:               $dbh->{ix_ProductName}\n";
print  "#     Product Version:       $dbh->{ix_ProductVersion}\n";
print  "#     Server  Version:       $dbh->{ix_ServerVersion}\n";
printf "#     Blob Support:          %d\n", $dbh->{ix_BlobSupport};
printf "#     Stored Procedures:     %d\n", $dbh->{ix_StoredProcedures};
printf "#     Multiple Connections:  %d\n", $dbh->{ix_MultipleConnections};
printf "#     Active Connections:    %d\n", $dbh->{ix_ActiveConnections};
print  "#     Current Connection:    $dbh->{ix_CurrentConnection}\n";
print  "#\n";

stmt_note("# Testing: \$dbh->disconnect()\n");
stmt_fail() unless ($dbh->disconnect);
stmt_ok();

stmt_note("# Re-testing: \$dbh->disconnect()\n");
stmt_fail() unless ($dbh->disconnect);
stmt_ok();

# Now reconnect to database!
$dbh = connect_to_test_database();
stmt_ok(0);

$dbh->{ChopBlanks} = 1;     # Force chopping of trailing blanks

print  "# Generic Database Handle Information\n";
print  "#     Type:                    $dbh->{Type}\n";
print  "#     Database Name:           $dbh->{Name}\n";
printf "#     AutoCommit:              %d\n", $dbh->{AutoCommit};
printf "#     PrintError:              %d\n", $dbh->{PrintError};
printf "#     RaiseError:              %d\n", $dbh->{RaiseError};
print  "# Informix Database Handle Information\n";
printf "#     Informix-OnLine:         %d\n", $dbh->{ix_InformixOnLine};
printf "#     Logged Database:         %d\n", $dbh->{ix_LoggedDatabase};
printf "#     Mode ANSI Database:      %d\n", $dbh->{ix_ModeAnsiDatabase};
printf "#     Transaction Active:      %d\n", $dbh->{ix_InTransaction};
print  "#\n";

# Remove table if it already exists, warning (not failing) if it doesn't
my $oldmode = $dbh->{PrintError};
$dbh->{PrintError} = 0;
my $stmt1 = "DROP TABLE $testtable";
stmt_test($dbh, $stmt1, 1);
$dbh->{PrintError} = $oldmode;

# Create table (now that it does not exist)...
my $stmt2 = "CREATE TEMP TABLE $testtable (id INTEGER NOT NULL, name CHAR(64))";
stmt_test($dbh, $stmt2, 0);

# Drop it (again)
stmt_test($dbh, $stmt1, 0);

# Create it again!
stmt_retest($dbh, $stmt2, 0);

my $stmt3 = "INSERT INTO $testtable VALUES(1, 'Alligator Descartes')";
stmt_test($dbh, $stmt3, 0);

my $stmt4 = "DELETE FROM $testtable WHERE id = 1";
stmt_test($dbh, $stmt4, 0);

# Test SELECT of empty data set
my $stmt5 = "SELECT * FROM $testtable WHERE id = 1";
stmt_note("# Testing: \$cursor = \$dbh->prepare('$stmt5')\n");
my $cursor;
stmt_fail() unless ($cursor = $dbh->prepare($stmt5));
stmt_ok();

# Print statement...
stmt_note("# Statement: $cursor->{Statement}\n");

stmt_note("# Testing: \$cursor->execute\n");
stmt_fail() unless ($cursor->execute);
stmt_ok();

stmt_note("# Statement: $cursor->{Statement}\n");
stmt_note("# Testing: \$cursor->fetch\n");

my $i = 0;
my @row;
while ((@row = $cursor->fetch) and $#row > 0)
{
    $i++;
    stmt_note("# Row $i: $row[0] => $row[1]\n");
    stmt_note("# FETCH succeeded but should have failed!\n");
    stmt_fail();
}

stmt_fail() unless ($#row == 0);
stmt_note("# OK (nothing found)\n");
stmt_ok(0);

print_sqlca($cursor);

stmt_note("# Testing: \$cursor->finish\n");
stmt_fail() unless ($cursor->finish);
stmt_ok(0);

# FREE the cursor and asociated data
undef $cursor;

# Insert some data
stmt_retest($dbh, $stmt3, 0);

# Verify that inserted data can be returned
stmt_note("# Re-testing: \$cursor = \$dbh->prepare('$stmt5')\n");
stmt_fail() unless ($cursor = $dbh->prepare($stmt5));
stmt_ok(0);

stmt_note("# Re-testing: \$cursor->execute\n");
stmt_fail() unless ($cursor->execute);
stmt_ok(0);

stmt_note("# Re-testing: \$cursor->fetch\n");
# Fetch returns a reference to an array!
my $j = 0;
my $ref;
while ($ref = $cursor->fetch)
{
    $j++;
    @row = @{$ref};
    # Verify returned data!
    my @exp = (1, "Alligator Descartes");
    stmt_note("# Values returned: ", $#row + 1, "\n");
    for ($i = 0; $i <= $#row; $i++)
    {
        stmt_note("# Row value $i: $row[$i]\n");
        stmt_fail("Incorrect value returned: got $row[$i]; wanted $exp[$i]\n")
            unless ($exp[$i] eq $row[$i]);
    }
}
stmt_fail("FAIL: $j rows selected when 1 expected\n") unless ($j == 1);

# Verify data attributes!
my @type = @{$cursor->{TYPE}};
for ($i = 0; $i <= $#type; $i++) { print ("# Type      $i: $type[$i]\n"); }
my @name = @{$cursor->{NAME}};
for ($i = 0; $i <= $#name; $i++) { print ("# Name      $i: <<$name[$i]>>\n"); }
my @null = @{$cursor->{NULLABLE}};
for ($i = 0; $i <= $#null; $i++) { print ("# Nullable  $i: $null[$i]\n"); }
my @prec = @{$cursor->{PRECISION}};
for ($i = 0; $i <= $#prec; $i++) { print ("# Precision $i: $prec[$i]\n"); }
my @scal = @{$cursor->{SCALE}};
for ($i = 0; $i <= $#scal; $i++) { print ("# Scale     $i: $scal[$i]\n"); }

my $nfld = $cursor->{NUM_OF_FIELDS};
my $nbnd = $cursor->{NUM_OF_PARAMS};
print("# Number of Columns: $nfld; Number of Parameters: $nbnd\n");

stmt_note("# Re-testing: \$cursor->finish\n");
stmt_fail() unless ($cursor->finish);
stmt_ok(0);

# FREE the cursor and asociated data
undef $cursor;

my $stmt6 = "UPDATE $testtable SET id = 2 WHERE name = 'Alligator Descartes'";
stmt_retest($dbh, $stmt6, 0);

my $stmt7 = "INSERT INTO $testtable VALUES(1, 'Jonathan Leffler')";
stmt_test($dbh, $stmt7, 0);

sub select_all
{
    my ($dbh, $exp1) = @_;
    my (%exp2) = %{$exp1};  # Associative array of numbers (keys) and names
    my (@row, $i);  # Local variables

    stmt_note("# Checking Updated Data\n");
    my $stmt8 = "SELECT * FROM $testtable ORDER BY id";
    stmt_note("# Re-testing: \$cursor = \$dbh->prepare('$stmt8')\n");
    stmt_fail() unless ($cursor = $dbh->prepare($stmt8));
    stmt_ok(0);

    stmt_note("# Re-testing: \$cursor->execute\n");
    stmt_fail() unless ($cursor->execute);
    stmt_ok(0);

    stmt_note("# Testing: \$cursor->fetchrow iteratively\n");
    $i = 1;
    while (@row = $cursor->fetchrow)
    {
        stmt_note("# Row $i: $row[0] => $row[1]\n");
        if ($row[1] eq $exp2{$row[0]})
        {
            stmt_ok(0);
        }
        else
        {
            stmt_note("# Wrong value:\n");
            stmt_note("# -- Got <<$row[1]>>\n");
            stmt_note("# -- Wanted <<$exp2{$row[0]}>>\n");
            stmt_fail();
        }
        $i++;
    }

    stmt_note("# Re-testing: \$cursor->finish\n");
    stmt_fail() unless ($cursor->finish);
    stmt_ok(0);

    # Free cursor referencing the table...
    undef $cursor;
}

select_all($dbh, {
    1 => 'Jonathan Leffler',
    2 => 'Alligator Descartes',
});

# Now the table is dropped.
stmt_retest($dbh, $stmt1, 0);

# Test execute with bound values
stmt_retest($dbh, $stmt2, 0);   # CREATE TABLE
stmt_retest($dbh, $stmt7, 0);   # INSERT Alligator
stmt_retest($dbh, $stmt3, 0);   # UPDATE Alligator
stmt_retest($dbh, $stmt6, 0);   # INSERT Jonathan

my $stmt13 = "INSERT INTO $testtable VALUES(?, ?)";
stmt_note("# Testing: \$sth = \$dbh->prepare('$stmt13')\n");
my $sth;
stmt_fail() unless ($sth = $dbh->prepare($stmt13));
stmt_ok(0);

my @bind = ( "3", "Frederick the Great" );
stmt_note("# Testing: \$sth->execute(@bind)\n");
stmt_fail() unless ($sth->execute(@bind));
stmt_ok(0);
print_sqlca($sth);

stmt_note("# Testing: \$sth->execute([4.00, \"Ghenghis Khan\"])\n");
stmt_fail() unless ($sth->execute(4.00, "Ghenghis Khan"));
stmt_ok(0);

select_all($dbh, {
1 => 'Jonathan Leffler',
2 => 'Alligator Descartes',
3 => 'Frederick the Great',
4 => 'Ghenghis Khan',
});

# FREE the statement and asociated data
undef $sth;

stmt_note("# Testing: \$dbh->disconnect()\n");
stmt_fail() unless ($dbh->disconnect);
stmt_ok(0);

all_ok;
