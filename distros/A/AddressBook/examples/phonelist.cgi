#!/usr/bin/perl

use AddressBook;
use CGI;

$query = CGI::new();
print $query->header(-charset=>'UTF-8');
print "<html><head>\n";
print "<style type=\"text/css\">\n";
print "td {font-size: 8pt; vertical-align: top}\n";
print "</style>\n";
print "<title>Phone List</title></head><body>\n";

$ldap=AddressBook->new(source => LDAP);
$html=AddressBook->new(source => phonelist,config=>$ldap->{config});

$lines = 0;
print "<table>\n";
print "<tr><td><table>\n";

$ldap->search(filter=>{phonelist => "Yes"});
while ($entry = $ldap->read) {
  if ($lines >= 36) {print "</table></td><td><table>\n";$lines=0}
  $cell = $html->write($entry);
  (@matches) = $cell =~ /<tr>(?!<\/tr>)/gi;
  $lines += $#matches;
  print "$cell\n";
}

print "</table></td></tr></table></font>\n";
print "</body></html>\n";
