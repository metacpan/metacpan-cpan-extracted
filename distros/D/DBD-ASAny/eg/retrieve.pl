#!/usr/local/bin/perl -w
# Note: The value specified for the password param is ignored
#       by the ASA DBD driver but, DBI requires something in the field.
#
use DBI;
use strict;

my $connstr = 'ENG=asademo;DBN=asademo;DBF=asademo.db;UID=dba;PWD=sql';
my $dbh = DBI->connect( "DBI:ASAny:$connstr", '', '', {AutoCommit => 0} );

my $sel_statement = "SELECT id, fname, lname FROM customer"; 
&db_query( $sel_statement, $dbh );
$dbh->disconnect;
exit( 0 );

sub db_query {
    my( $sel, $h ) = @_;
    my( $row, $sth ) = undef;
    $sth = $h->prepare( $sel );
    $sth->execute;
    print "Names:      @{$sth->{NAME}}\n";
    print "Fields:     $sth->{NUM_OF_FIELDS}\n";
    print "Params:     $sth->{NUM_OF_PARAMS}\n";
    print "\nFirst Name\tLast_name\tTitle\n";
    while( $row = $sth->fetch ) {
	print "@$row[0]\t@$row[1]\t\t@$row[2]\n";
    }
    $sth->finish;
}
__END__
