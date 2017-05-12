require 'dbconn.pl';
use DBI;
use DBSchema::Sample;

use strict;

my $dbh    = dbh();
my $insert = DBSchema::Sample->inserts;

for (@$insert) {
    warn $_;
    $dbh->do($_);
}
