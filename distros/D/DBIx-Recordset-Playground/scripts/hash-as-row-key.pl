require 'dbconn.pl';
use DBIx::Recordset;
use strict;
use vars qw(*set);

*set = DBIx::Recordset -> Setup
  ({
    conn_dbh(),
    '!Table'	    => 'authors',
    '!HashAsRowKey' => 1,
    '!PrimKey'      => 'au_id'
   });


my @au_id = qw( 409-56-7008  213-46-8915 998-72-3567 );


warn Dumper($set{$_}) for @au_id;
