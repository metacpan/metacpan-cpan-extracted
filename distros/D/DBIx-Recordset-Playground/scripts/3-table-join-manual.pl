require 'dbconn.pl';
use DBIx::Recordset;
use strict;
use vars qw(*set *set2 *set3);

{

    my %DEBUG = ('!Debug' => 0);

    *set = DBIx::Recordset -> Search 
      ({
	conn_dbh(),
	%DEBUG,
	'!Table'	   => 'authors'
       }) ;

    while ( my $rec = $set->Next) {
	print join "\t", $set{au_fname}, $set{au_lname}, $set{au_id}, $/;
	*set2 = DBIx::Recordset -> Search
	  ({
	    conn_dbh(),
	    %DEBUG,
	    '!Table'	   => 'titleauthors',
	    au_id              => $set{au_id}
	   }) ;
    
	while ( my $rec2 = $set2->Next) {
	    #	warn 1.3;
	    print "\t", $set2{title_id}, $/;

	    #	warn 1.4;
	    *set3 = DBIx::Recordset -> Search
	      ({
		conn_dbh(),
		%DEBUG,
		'!Table'	   => 'titles',
		title_id       => $set2{title_id}
	       });

	    while ( my $rec3 = $set3->Next) {
		print "\t\t", $set3{title}, $/;

	    }
	}
    }


}
