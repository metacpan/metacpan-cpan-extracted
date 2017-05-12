require 'dbconn.pl';
use DBIx::Recordset;
use strict;
use vars qw(*set);

my %where = (name => 'tony');

*set =
  DBIx::Recordset -> Search ({

      %where,
      conn_dbh(), person_table()

      });


use vars qw(*set2);

 *set2 =

  DBIx::Recordset -> Insert ({

      name => 'foo',
      age  => '400',
      conn_dbh(), person_table()

      });

#$set2{age} = 300; # this adds another reocrd without name!

$set2[0]{age}=299; # this too!

my %where = (age => 400);
my %setvals = (name => 'methusalah');
$set->Update (
	      \%setvals,
	      \%where
	      );





o
