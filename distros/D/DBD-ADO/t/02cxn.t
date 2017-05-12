#!perl -I./t

$| = 1;

use strict;
use warnings;
use Win32::OLE();
use DBI();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 9;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Connection tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

my $Cxn = $dbh->{ado_conn};

ok( $Cxn,"Connection object: $Cxn");

print "\n# Connection properties:\n";
printf "#   %-20s %s\n", $_, $Cxn->{$_} ||'undef'
  for sort keys %$Cxn;

my $Properties = $Cxn->Properties;

ok( $Properties,"Connection Properties Collection: $Properties");

print "\n# Connection Properties Collection:\n";
printf "#   %-45s %s\n", $_->Name, $_->Value ||'undef'
  for sort { $a->Name cmp $b->Name } Win32::OLE::in( $Properties );

ok( $dbh->ping,'Ping');

ok( $dbh->{Active},'Active');

ok( $dbh->disconnect,'Disconnect');

ok(!$dbh->ping,'Ping');

ok(!$dbh->{Active},'Active');
#Connection open, destroy at t\02cxn.t line 0
#        (in cleanup) Can't call method "State" on unblessed reference at F:/tmp/DBD-ADO-2.77/blib/lib/DBD/ADO.pm line 1549.
