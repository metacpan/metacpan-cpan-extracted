require 'dbconn.pl';
use DBIx::Recordset;

use vars qw(*set);

*set =
  DBIx::Recordset -> Search
  ({

    au_fname => 'Akiko',
    conn_dbh(), author_table()

   });


print $set{address}, $/;

# Now do another search

$set->Search({

	      au_fname => 'Sylvia'
    });

print $set{address}, $/;
