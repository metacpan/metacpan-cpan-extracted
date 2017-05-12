# This script is intended to be invoked by a servlet (or another
# Java application). The servlet is responsible for creating a 
# JDBC connection and then creating a com.vizdom.dbd.jdbc.Server
# object which will accept a socket connection from this script.
# The servlet can then exec this script, passing the port and any
# other variables in CGI fashion. This script will, in turn, connect
# to the port and make database calls using the DBI interface
# and the DBD::JDBC module. The servlet will read this script's
# stdout and stderr for the script results and take whatever action
# it desires.

# Since the servlet created the JDBC connection, this script
# doesn't need a JDBC url or database username and password.
# However, since the driver requires them, supply something.

# Setup: the servlet or other application will need to be able
# to use a JDBC driver and exec this script. This script will
# need access to DBD::JDBC (and its supporting modules(s)).


BEGIN
{
    # I needed to set this in order to get Perl scripts to work 
    # when invoked by a servlet.
    $ENV{'SYSTEMROOT'} = "c:\\winnt";
}

use strict;
use CGI;
use DBI;

my $q = new CGI();
my $port = $q->param('com.vizdom.dbd.jdbc.Server.port');

my ($dsn, $dbh, $sth, $row);
$dsn = "dbi:JDBC:hostname=localhost;port=$port;url=PerlServlet";

$dbh = DBI->connect($dsn, undef, undef,
                    { AutoCommit => 1, PrintError => 0, RaiseError => 1})
    or ( die("Failed to connect: ($DBI::err) $DBI::errstr\n"));

# We don't really want to use $q->header; the servlet is handling that.
# Just create HTML for display.

print $q->start_html(-title=>"Perl Script Output");
my $fields = $q->param('fields');
print "The parameter from the servlet is '$fields'.<br><br>\n";

my $query = qq/select $fields from employee where eno < 5000 order by eno/;
$sth = $dbh->prepare($query);
$sth->execute();

print "<table>\n";
print "<tr><th>";
print join("</th><th>", split(/,/, $fields));
print "</th></tr>\n";
print "<tr><td>\n";
while ($row = $sth->fetch()) {
    print "<tr><td>";
    print join("</td><td>", @$row);
    print "</td></tr>\n";
}
print "</table>\n";
print $q->end_html();

$dbh->disconnect();

exit(0);
