#!/usr/local/bin/perl -w
#
use DBI;
use strict;
my $connstr = 'ENG=asademo;DBN=asademo;DBF=asademo.db;UID=dba;PWD=sql';
# For a remote connection, you might want to add "CommLinks=tcpcip" for example

my $dbh = DBI->connect( "DBI:ASAny:$connstr", '', '', {PrintError => 0, AutoCommit => 0} )
    or die "Connection failed\n    Connection string: $connstr\n    Error message    : $DBI::errstr\n";
$dbh->disconnect;
exit(0);
__END__
