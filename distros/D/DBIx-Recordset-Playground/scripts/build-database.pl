require 'dbconn.pl';
use DBI;
use strict;
use DBSchema::Sample;

my $dbh = dbh();
my $sql = DBSchema::Sample->sql;

for (@$sql) {
    warn $_;
    $dbh->do($_);
}
