require 'dbconn.pl';
use DBIx::Recordset;
use strict;
use vars qw(*set *set2 *set3);

my %DEBUG = ('!Debug' => 0);

*set = DBIx::Recordset -> Search 
  ({
    conn_dbh(),
    %DEBUG,
    '!Table'	   => 'authors',
    '!Links'           => {

			   '-titleauthors' => {

					       '!Table' => 'titleauthors',
					       '!LinkedField' => 'titleauthors.au_id',
					       '!MainField' => 'authors.au_id'

					      }
			  }
   });


while ( my $rec = $set->Next) {

    warn $rec->{au_fname};
    my $row_count;
    while ( my $titleauthors = $set{'-titleauthors'}->Next ) {
	warn $row_count++;
    }
}

=head1 ERROR:

Can't call method "Next" without a package or object reference at 3-table-join-link.pl line 30.
DB:  Disconnect (id=2, numOpen = 0)
[tbone@horse1 scripts]$ 


=cut

