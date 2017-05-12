require 'dbconn.pl';
use DBIx::Recordset;

use vars qw(*set);

*set =
  DBIx::Recordset -> Search
  ({
    '!TabJoin'     => 
      'authors LEFT OUTER JOIN publishers on authors.city = publishers.city',
      '$fields'    => 'au_fname, au_lname, pub_name',
    conn_dbh(),
   });


use Data::Dumper;
while ( my $rec = $set->Next) {
  print Dumper($rec);
}
