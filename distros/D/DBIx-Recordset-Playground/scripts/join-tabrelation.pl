require 'dbconn.pl';
use DBIx::Recordset;

use vars qw(*set);

*set =
  DBIx::Recordset -> Search
  ({
    '!TabRelation' => 'sales.sonum = salesdetails.sonum',
    'qty_ordered'  => 15,
    '$fields'      => 'title_id,ponum',
    conn_dbh(),
    tblnm('sales,salesdetails')
   });


while ( $set->Next) {
    print join "\t", $set{title_id}, $set{ponum}, $/;
}
