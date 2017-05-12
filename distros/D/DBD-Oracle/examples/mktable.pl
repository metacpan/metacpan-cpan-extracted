#!/usr/bin/env perl
# Sample DBI program to create a new table and load data into it.
#
# Author:   Kevin Stock (original oraperl script)
# Date:     5th August 1991
# Date:     25th September 1992

use DBI;

use strict;

# Set trace level if '-# trace_level' option is given
DBI->trace( shift ) if 1 < @ARGV && $ARGV[0] =~ /^-#/ && shift;

die "syntax: $0 [-# trace] base user pass" if 3 > @ARGV;
my ( $inst, $user, $pass ) = @ARGV;

# Connect to database
my $dbh = DBI->connect( "dbi:Oracle:$inst", $user, $pass,
    { AutoCommit => 0, RaiseError => 1, PrintError => 0 } )
    or die $DBI::errstr;

# set these as strings to make the code more readable
my $CREATE      = "CREATE TABLE tryit ( name VARCHAR2(10), ext NUMBER(3) )";
my $INSERT      = "INSERT INTO tryit VALUES ( ?, ? )";
my $LIST        = "SELECT * FROM tryit ORDER BY name";
my $DELETE      = "DELETE FROM tryit WHERE name = ?";
my $DELETE_NULL = "DELETE FROM tryit WHERE name IS NULL";
my $DROP        = "DROP TABLE tryit";

# Can use dynamic variables in write as long as they are visible at format time
my ( $msg, $name, $ext );

# Prepare formats for output
format STDOUT_TOP =

          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
          $msg

          Name         Ext
          ====         ===
.

format STDOUT =
          @<<<<<<<<<   @>>
          $name,       $ext
.

# function to list the table
sub list {
    $msg = join "\n", @_;
    $- = 0;
    my $sth = $dbh->prepare( $LIST );
    $sth->execute;
    $sth->bind_columns( {}, \( $name, $ext ) );
    while ( $sth->fetch ) {
        $name = '<NULL>' unless defined $name;
        $ext  = '<N>'    unless defined $ext;
        write;
    }
    $sth->finish;
}

# create the database
$dbh->do( $CREATE );

# put some data into it
my $sth = $dbh->prepare( $INSERT );
while ( <DATA> ) {
    chomp;
    $sth->execute( map { 'NULL' eq $_ ? undef : $_ } split /:/, $_, 2 );
}
$dbh->commit;
list( 'Initial Data' );

# remove a few rows
$sth = $dbh->prepare( $DELETE );
foreach $name ( 'catherine', 'angela', 'arnold', 'julia' ) {
    $sth->execute( $name );
}
$dbh->commit;
list( 'After removing selected people' );

# Remove some rows with NULLs
$dbh->do( $DELETE_NULL );
list( 'After removing NULL names' );

# remove the table and disconnect
$dbh->do( $DROP );
$dbh->disconnect;

# This is the data which will go into the table
__END__
julia:292
angela:208
NULL:999
larry:424
catherine:201
nonumber:NULL
randal:306
arnold:305
NULL:NULL
