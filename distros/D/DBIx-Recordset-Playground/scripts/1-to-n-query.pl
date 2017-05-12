require 'dbconn.pl';
use DBIx::Recordset;
use strict;
use vars qw(*set *set2 *set3);


*set = DBIx::Recordset -> Search 
  ({
    conn_dbh(),
    '!Table'	   => 'authors'
   }) ;

while ( my $rec = $set->Next) {
    print join "\t", $set{au_fname}, $set{au_lname}, $set{au_id}, $/;
    *set2 = DBIx::Recordset -> Search
      ({
	conn_dbh(),
	'!Table'	   => 'titleauthors',
	au_id              => $set{au_id}
       }) ;
    
    while ( my $rec2 = $set2->Next) {
	print "\t", $set2{title_id}, $/;

	*set3 = DBIx::Recordset -> Search
	  ({

	   })

    }

}
