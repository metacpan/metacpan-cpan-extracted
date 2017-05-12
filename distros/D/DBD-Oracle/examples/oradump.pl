#!/usr/bin/env perl
#
# Dump the contents of an Oracle table into a set of insert statements.
# Quoting is controlled by the datatypes of each column. (new with DBI)
#
# Usage: oradump <database> <user> <pass> <table>
#
# Author:   Kevin Stock (original oraperl script)
# Date:     28th February 1992
#

use DBI;

use strict;

# Set trace level if '-# trace_level' option is given
DBI->trace( shift ) if 1 < @ARGV && $ARGV[0] =~ /^-#/ && shift;

die "syntax: $0 base user pass table\n" if 4 > @ARGV;
my ( $base, $user, $pass, $table ) = @ARGV;

# Connect to database
my $dbh = DBI->connect( "dbi:Oracle:$base", $user, $pass,
    { AutoCommit => 0, RaiseError => 1, PrintError => 0 } )
    or die $DBI::errstr;

my $sth = $dbh->prepare( "SELECT * FROM $table");
$sth->execute;
my @name = @{$sth->{NAME}};
my @type = @{$sth->{TYPE}};
my $lead = "INSERT INTO $table ( " . join( ', ', @name ) . " ) VALUES ( ";
my ( @data, $i );
$sth->bind_columns( {}, \( @data[0 .. $#name] ) );
while ( $sth->fetch ) {
    $i = 0;
    print $lead . join( ", ", map { $dbh->quote( $_, $type[$i++] ) } @data ) .
  # print $lead . join( ", ", map { $dbh->quote( $_ ) } @data ) . # for old DBI
        " );\n";
}

$sth->finish;
$dbh->disconnect;
