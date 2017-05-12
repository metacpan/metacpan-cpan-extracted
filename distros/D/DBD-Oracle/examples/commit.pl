#!/usr/bin/env perl
#
# commit.pl
#
# Simple example of using commit and rollback.

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

# Create the table to hold prime numbers
print "Creating table\n";
eval { $dbh->do( 'CREATE TABLE primes ( prime NUMBER )' ); };
warn $@ if $@;

print "Loading table";
my $sth = $dbh->prepare( 'INSERT INTO primes VALUES ( ? )' );
while ( <DATA> ) {
    chomp;
    print " $_";
    $sth->execute( $_ );
    print " commit (", $dbh->commit, ")" if 11 == $_;
}
print "\n";

my $prime;
print "Reading table for the first time\n";
$sth = $dbh->prepare( 'SELECT prime FROM primes ORDER BY prime' );
$sth->execute;
$sth->bind_columns( {}, \$prime );
while ( $sth->fetch ) {
    print " $prime";
}
$sth->finish;
print "\n";

print "rollback (", $dbh->rollback, ")\n";

print "Reading table for the second time.\n";
$sth->execute;
$sth->bind_columns( {}, \$prime );
while ( $sth->fetch ) {
    print " $prime";
}
$sth->finish;
print "\n";

$dbh->do( 'DROP TABLE primes' );
print "Table Dropped\n";
$dbh->disconnect;
__END__
2
3
5
7
11
13
17
19
23
29
