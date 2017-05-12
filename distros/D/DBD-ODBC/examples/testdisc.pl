#!perl -w
# $Id$


use strict;

use DBI;

my $dbh = DBI->connect() or die "connect";

$dbh->disconnect;

eval {
   my $sth = $dbh->tables();
};
eval {
   my $sth2 = $dbh->prepare("select sysdate from dual");
};
