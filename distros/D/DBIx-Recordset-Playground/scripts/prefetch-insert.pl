require 'dbconn.pl';
use DBIx::Recordset;
use strict;


# This program takes one argument, an integer indicating how often it should
# insert a random record into the sales table.

my $insert_frequency = shift or die 'must specify insert frequency';

use vars qw(*set);

sub rand_ponum {
  sprintf "%s%d%s", chr(65 + rand 25), rand 400 + rand 1000, 
    lc chr(65 + rand 25);
}


*set = DBIx::Recordset->Search
  ({
    conn_dbh(),
    '!Table'  => 'sales',
    '!Fields' => 'max(sonum) as max_id',
    });

my $max_id = $set{max_id};


while (1) {

  DBIx::Recordset->Insert
      (
       {
	conn_dbh(),
	'!Table'  => 'sales',
	sonum     => ++$max_id,
	stor_id   => (sprintf "%d", 7000 + rand 1000),
	ponum     => rand_ponum,
	sdate     => '2003-10-22'
       }
       );

  sleep $insert_frequency;

}
