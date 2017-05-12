require 'dbconn.pl';
#use Data::Dumper;
use DBIx::Recordset;
use strict;

use vars qw(*rs);

*rs =
  DBIx::Recordset -> Setup ({

      conn_dbh(), author_table()

      });

$rs->Update
  (
   {
    state => 'Utah'   # SET
   },
   {
    state => 'UT'     # WHERE
   }
  );

# It worked. The field is truncated to 2 chars
