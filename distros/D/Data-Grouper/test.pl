# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::Grouper;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# TODO: Test case where I call get_data() without adding rows.  This
#       caused errors in _format_tails earlier.
#


my $g = new Data::Grouper(
   COLNAMES => [ 'COLOR' , 'COUNT' ],
   SORTCOLS => [ 'COLOR' ],
   AGGREGATES => [ 'COUNT' ]
  );

$g->add_row( ('Blue', 2 ) );
$g->add_row( ('Blue', 3 ) );

my $aref = $g->get_data();

# Should only produce one row

   if ($#{$aref} != 0 )
   {

      print "not ok 2\n";
   }
   else
   {
      print "ok 2\n";
   }

# inner aggregate - sum should be 5

   if ( $aref->[0]->{SUM_COUNT} != 5 )
   {
      print "not ok 3\n";
   }
   else
   {
      print "ok 3\n";
   }


# inner aggregate - count should be 2
   if ( $aref->[0]->{COUNT_COUNT} != 2 )
   {
      print "not ok 4\n";
   }
   else
   {
      print "ok 4\n";
   }


# inner aggregate - min should be 2
   if ( $aref->[0]->{MIN_COUNT} != 2 )
   {
      print "not ok 5\n";
   }
   else
   {
      print "ok 5\n";
   }

# inner aggregate - max should be 3
   if ( $aref->[0]->{MAX_COUNT} != 3 )
   {
      print "not ok 6\n";
   }
   else
   {
      print "ok 6\n";
   }


##### OK, now test outer aggregates

$aref = $g->get_top_aggregates();

# outer aggregate, sum should be 5
   if ( $aref->{SUM_COUNT} != 5 )
   {
      print "not ok 7\n";
   }
   else
   {
      print "ok 7\n";
   }



# Test DATA, hashrefs

my $aref8 = [ { lname=>'ferrance', fname=>'dave' },
              { lname=>'ferrance', fname=>'susan' },
              { lname=>'ferrari', fname=>'Modena' }
            ];
            
my $g8 = new Data::Grouper( SORTCOLS => [ 'lname' ], DATA=>$aref8 );
$aref = $g8->get_data();

   if ( $#{$aref} != 1 )
   {
      print "not ok 8\n";
   }
   else
   {
      print "ok 8\n";
   }

# Here is a test that should fail w/ warning
# not sure how to implement it right now so leaving it commented out
#$grouper = new Data::Grouper(SORTCOLS=>['FICTION']); 
#$grouper->add_row( ('hi','there') );

# and another
#$grouper = new Data::Grouper(COLNAMES=>['A','B'], SORTCOLS=>['FICTION']); 
#$grouper->add_row( ('hi','there') );
