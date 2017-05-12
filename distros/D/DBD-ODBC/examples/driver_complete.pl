# $Id$
# shows how (in Windows) you can set the odbc_driver_complete flag,
# pass incomplete connection strings and be prompted for completion
use strict;
use warnings;
use DBI;

my $h = DBI->connect('dbi:ODBC:DRIVER={SQL Server}', undef, undef, {odbc_driver_complete => 1}) or die $DBI::errstr;
if (defined($h->err)) {
    if ($h->err eq 0) {
	print "Warning message : ", $h->errstr, "\n";
    } elsif ($h->err eq '') {
	print "Informational message : ", $h->errstr, "\n";
    }
}
print "Out Connection String: ", $h->{odbc_out_connect_string}, "\n";
print "odbc_driver_complete: ", $h->{odbc_driver_complete}, "\n";

