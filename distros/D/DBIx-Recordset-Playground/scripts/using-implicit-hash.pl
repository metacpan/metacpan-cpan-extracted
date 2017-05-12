require 'dbconn.pl';
use DBIx::Recordset;
use strict;
use vars qw(*set);

my %where = (title_id => 'MC3026');

*set =
  DBIx::Recordset -> Search ({

      %where,
      conn_dbh(), royalty_table()

      });


while ($set->Next) {
    print $set{royalty}, $/;
}
