require 'dbconn.pl';
use DBIx::Recordset;
use strict;

use vars qw(*set);

*set =
  DBIx::Recordset -> Search
  ({
    au_lname => 'Ringer',
    state    => 'UT',
    conn_dbh(), author_table()

   });

warn 1.0;
#print Dumper(\@set); # results not fetched because FetchsizeWarn not disabled

warn 1.01;
$DBIx::Recordset::FetchsizeWarn = 0;
print Dumper(\@set); # results are now fetched

warn 1.1;
print Dumper(\%set); # only print current record

warn 1.2; # Here we print all
$set->Reset;
while ($set->Next) {
    print Dumper(\%set)
}


warn 1.3; # Here we print all in another way
$set->Reset;
while (my $rec = $set->Next) {
    print Dumper($rec);
}

warn 1.4; # This doesnt work either <... why?>
$set->Reset;
while ($set->MoreRecords) {
    print Dumper($set->Next);
}
