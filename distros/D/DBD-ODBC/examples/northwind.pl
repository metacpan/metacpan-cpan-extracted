#!perl -w
# $Id$

#
# Perl script that talks with the Northwinds database using an
# ODBC DSN of Northwind.
#

use DBI qw(:sql_types);
use Data::Dumper;
use strict;

my $dbh = DBI->connect( "dbi:ODBC:Northwind", "", "",
     {RaiseError => 1, PrintError => 1, AutoCommit => 1} ) or
die "Unable to connect: " . $DBI::errstr . "\n";

# OK, connected, now select from Customers table.

my $sel = $dbh->prepare( "select * from Customers where CustomerID like 
?" );

$sel->execute( qq{A%} );

print "Driver : " . $dbh->{Driver}->{Name} . "\n";
print "SQL Statement: " . $sel->{Statement} . "\n";
print "Table contains: " . $sel->{NUM_OF_FIELDS} . " columns.\n";
print "Column names are: " . join( "\n\t", @{$sel->{NAME}}, "" );
print "Number of Params: " . $sel->{NUM_OF_PARAMS} . "\n";

print "\n";
my @row;
{
     local $^W = 0;
     print join( "\t", @{$sel->{NAME}}, "\n");
     while( @row = $sel->fetchrow_array ) {
         print join( "\t",@row, "\n");
     }
}

print "\n";
# Remove sample row, if needed.

$dbh->do( qq{delete from Customers where CustomerID = 'TAL'} );

# Insert a new customer.
#Column names are: CustomerID
#CompanyName
#ContactName
#ContactTitle
#Address
#City
#Region
#PostalCode
#Country
#Phone
#Fax

print "Inserting new customer: ";

$ins = $dbh->prepare( qq{insert into Customers
     values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )}
);

my @tal = (
"TAL",
"STL",
"ThomasAL",
"STL",
"Thomas Lowery",
"Manager",
"74 Washington Ave.",
"Battle Creek",
"Northeast",
49017,
"USA",
"616.961.4000",
"616.961.4000"
);

print $ins->execute(@tal) . "\n";

# Select new customer.
print "Select new customer: ";
$sel->execute( qq{TAL%} );
print "\n";

{
     local $^W = 0;
     print join( "\t", @{$sel->{NAME}}, "\n");
     while( @row = $sel->fetchrow_array ) {
         print join( "\t",@row, "\n");
     }
}

$ins->finish;

print "\n";
# Change new customer.

print "Update customers: ";
$upd = $dbh->prepare( qq{update Customers set CompanyName = 'TAL' where 
CustomerID = 'TAL'} );

print $upd->execute . "\n";

$sel->execute( qq{TAL%} );
{
     local $^W = 0;
     print join( "\t", @{$sel->{NAME}}, "\n");
     while( @row = $sel->fetchrow_array ) {
         print join( "\t",@row, "\n");
     }
}

print "\n";
# Delete new customer.

print "Delete customer: " . $dbh->do( qq{ delete from Customers where 
CustomerID = 'TAL'} ) . "\n";

$sel->execute( qq{TAL%} );
{
     local $^W = 0;
     print join( "\t", @{$sel->{NAME}}, "\n");
     while( @row = $sel->fetchrow_array ) {
         print join( "\t",@row, "\n");
     }
}

print "\n";
# Finished

$sel->finish;
$dbh->disconnect;
exit;
