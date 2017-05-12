require 'dbconn.pl';
use DBI;
use strict;
use DBSchema::Sample;

my $sql = DBSchema::Sample->sql;
my $idx = DBSchema::Sample->idx;
my $dbh = dbh();

for (keys %$sql) {
    warn $_;
    $dbh->do($sql->{$_});
}

for (keys %$idx) {
    warn $_;
   $dbh->do($idx->{$_});
}
