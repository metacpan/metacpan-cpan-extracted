#!/usr/bin/env perl
# Short example using bind_columns() to list a table's values

use DBI;

use strict;

# Set trace level if '-# trace_level' option is given
DBI->trace( shift ) if 1 < @ARGV && $ARGV[0] =~ /^-#/ && shift;

die "syntax: $0 [-# trace] base user pass [max]" if 3 > @ARGV;
my ( $inst, $user, $pass, $max ) = @ARGV;
$max = 20 if ! $max || 0 > $max;

my ( $name, $id, $created );
format STDOUT_TOP =
       Name                                   ID  Created
       ==============================  =========  =========
.

format STDOUT =
       @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>  @<<<<<<<<
       $name,                          $id,       $created
.

# Connect to database
my $dbh = DBI->connect( "dbi:Oracle:$inst", $user, $pass,
    { AutoCommit => 0, RaiseError => 1, PrintError => 0 } )
    or die $DBI::errstr;

my $sth = $dbh->prepare(
   "SELECT username, user_id, created FROM all_users ORDER BY username" );
$sth->execute;

my $nfields = $sth->{NUM_OF_FIELDS};
print "Query will return $nfields fields\n\n";

$sth->bind_columns( {}, \( $name, $id, $created ) );
while ( $sth->fetch ) {
    last if ! --$max;
    # mark any NULL fields found
    foreach ( $name, $id, $created ) { $_ = 'NULL' if ! defined; }
    write;
}

$sth->finish;
$dbh->disconnect;
