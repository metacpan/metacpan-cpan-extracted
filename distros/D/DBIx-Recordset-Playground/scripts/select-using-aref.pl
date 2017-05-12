require 'dbconn.pl';
#use Data::Dumper;
use DBIx::Recordset;
use strict;

use vars qw(*rs);

*rs =
  DBIx::Recordset -> Search ({

      '$where'   => 'au_lname = ? and state = ?',
      '$values'  => ['Ringer',  "UT"],
      conn_dbh(), author_table()

      });

# print Dumper($rs[0]) only works if FetchsizeWarn siabled

warn $rs{au_fname};
