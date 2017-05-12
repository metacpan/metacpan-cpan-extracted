use DBI;
# $Id$

print join(', ', DBI->data_sources("ODBC")), "\n";
print $DBI::errstr;
print "\n";
