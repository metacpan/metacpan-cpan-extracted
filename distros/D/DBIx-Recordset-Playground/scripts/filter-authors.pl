require 'dbconn.pl';
use DBIx::Recordset;
use strict;

use vars qw(*set);

*set =
  DBIx::Recordset -> Search
  ({
    conn_dbh(), author_table(),
    '$max' => 10,
    '!Filter' => {
		  DBI::SQL_VARCHAR => [
				       undef, # no input filtering
				       sub { uc (shift()) }
				      ]
		  }
   });


while ($set->Next) {
    print Dumper(\%set)
}

