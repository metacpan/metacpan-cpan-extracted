use strict;
use warnings;

# this program is for use by a developer to write a test to upgrade
# from one version to the current. It requires the Data::RecordStore
# required to be the old version to test.

# control which version of test file to be created.
require '/home/wolf/opensource/recordstore/lib/Data/RecordStore.pm';

print $Data::RecordStore::VERSION,"\n";

#print STDERR "BEEP\n";exit;
#
# Make a test for convert from 3.21 to 4.
#  include records that are in different sizes and
#  make sure to test the fensepost boundaries.
#
# This must be run when the version is at least 3.1
# and less than 4.
#
# It creates an old style record store that the
# record_store_coner test will try to convert and
# verify.
#

mkdir ( "t/upgrade_data/$Data::RecordStore::VERSION" );
my $store = Data::RecordStore->open_store( "t/upgrade_data/$Data::RecordStore::VERSION" );

sub make_1 {
  my $old_min_size = 0;
  my $last_new_id = 12;
  my $stows = 1;

  my $old_size_chunk = 500;

  # go through 12 old stores?
  for my $old_store_id (1..12) {
    my $old_max_size = $old_size_chunk * $old_store_id;

    my $new_store_id = log( $old_max_size + 1 ) / log( 2 );

    print "))$old_store_id --> $new_store_id((\n";

    if ( int( $new_store_id ) < $new_store_id ) {
      $new_store_id = 1 + int( $new_store_id );
    }
    if ( $new_store_id < 12 ) {
      $new_store_id = 12;       #4096
    }
    my $avg = int( ($old_min_size + $old_max_size) / 2 );
    print "old store $old_store_id is from $old_min_size to $old_max_size  -> to store $new_store_id. (avg $avg)\n";

    if( $old_store_id == 12 ) {
      my $bigid = $store->stow( 'x'x(8192-5) );
      my $r = $store->{OBJ_INDEX}->get_record( $bigid );
      ++$stows;
    }

    $store->stow( 'x'x$old_min_size ) if $old_min_size;
    ++$stows if $old_min_size;

    if ( $new_store_id > ($last_new_id+1) ) {
      my $mid_boundary = 2**($last_new_id+1);
      print "   new store ".($new_store_id-1)." with min ".($mid_boundary-1)."\n";
      $store->stow( 'x'x($mid_boundary-1) ); #still on the first new store id
      ++$stows;
      $store->stow( 'x'x($mid_boundary) ); #start of cleft
      ++$stows;
    } 
    else {
      $store->stow( 'x'x$avg );
      ++$stows;
    }
    
    $last_new_id = $new_store_id;
    $old_min_size = $old_max_size + 1;
  }

  print STDERR "Did $stows stows\n";
} #make_1

sub make_3_1 {
  my $old_min_size = 0;
  my $last_new_id = 12;
  my $stows = 0;
  my $recs = 0;

  for my $old_store_id (1..12,12) {
    my $old_max_size = int( exp( $old_store_id ) );
    $old_max_size -= 12; # long,id,rest. Its the rest that we get the size for
    if ( $old_max_size < 0 ) {
      next;
      $old_store_id = 3;
    }
    my $new_size = 4 + $old_max_size;
    if ( $new_size < 1 ) {
      $new_size = 1;
    }
    my $new_store_id = log( $new_size ) / log( 2 );
    if ( int( $new_store_id ) < $new_store_id ) {
      $new_store_id = 1 + int( $new_store_id );
    }
    if ( $new_store_id < 12 ) {
      $new_store_id = 12;       #4096
    }
    my $avg = int( ($old_max_size+$old_max_size) / 2 );

    $store->stow( 'x'x$old_min_size ) if $old_min_size;
    ++$stows if $old_min_size;
    ++$recs if $old_min_size;
    print "  $recs) $old_min_size in old store $old_store_id -> to store $new_store_id. \n" if $old_min_size;
    my $id = $store->stow( 'x'x($old_max_size-4) );
    ++$recs;
    $store->stow( 'x'x$old_max_size );
    ++$stows;
    ++$recs;
    print "  $recs) $old_max_size in old store $old_store_id -> to store $new_store_id. \n";
    $store->delete( $id );

    if ( $new_store_id > ($last_new_id+1) ) {
      my $mid_boundary = 2**($last_new_id+1);
      print "   new store ".($new_store_id-1)." with min ".($mid_boundary-1)."\n";
      $store->stow( 'x'x($mid_boundary-1) ); #still on the first new store id
      ++$recs;
      ++$stows;
    print "  $recs) ".($mid_boundary-1)." in old store $old_store_id -> to store $new_store_id. \n";
      $store->stow( 'x'x($mid_boundary) ); #start of cleft
      ++$recs;
      ++$stows;
      print "  $recs) $mid_boundary in old store $old_store_id -> to store $new_store_id. \n";
    } 
    else {
      $store->stow( ('x'x$avg)."\0" );
      ++$recs;
      ++$stows;
      print "  $recs) $avg in old store $old_store_id -> to store $new_store_id. \n";
    }
    
    $last_new_id = $new_store_id;
    $old_min_size = $old_max_size + 1;
  }

  print STDERR "Did $stows stows, recs $recs\n";
} #make_3_1

sub make_3 {
  my $old_min_size = 0;
  my $last_new_id = 12;
  my $stows = 0;
  my $recs = 0;
  for my $old_store_id (1..12,12) {
    my $old_max_size = int( exp( $old_store_id ) );
    $old_max_size -= 4; # long,rest. Its the rest that we get the size for
    if ( $old_max_size < 0 ) {
      next;
    }
    my $new_size = 4 + $old_max_size;
    if ( $new_size < 1 ) {
      $new_size = 1;
    }
    my $new_store_id = log( $new_size ) / log( 2 );
    if ( int( $new_store_id ) < $new_store_id ) {
      $new_store_id = 1 + int( $new_store_id );
    }
    if ( $new_store_id < 12 ) {
      $new_store_id = 12;       #4096
    }
    my $avg = int( ($old_min_size+$old_max_size) / 2 );
    print STDERR "old store $old_store_id is from $old_min_size/$avg/$old_max_size  -> to store $new_store_id. \n";
    $store->stow( 'x'x$old_min_size ) if $old_min_size;
    ++$stows if $old_min_size;
    ++$recs if $old_min_size;

    my $id = $store->stow( 'x'x($old_max_size-4) );
    ++$recs;
    $store->stow( 'x'x$old_max_size );
    ++$stows;
    $store->delete( $id );
    ++$recs;

    if ( $new_store_id > ($last_new_id+1) ) {
      my $mid_boundary = 2**($last_new_id+1);
      print "   new store ".($new_store_id-1)." with min ".($mid_boundary-1)."\n";
      $store->stow( 'x'x($mid_boundary-1) ); #still on the first new store id
      ++$stows;
      ++$recs;
      $store->stow( 'x'x($mid_boundary) ); #start of cleft
      ++$stows;
      ++$recs;
    } 
    else {
      $store->stow( 'x'x$avg );
      ++$stows;
      ++$recs;
    }
    
    $last_new_id = $new_store_id;
    $old_min_size = $old_max_size + 1;
  }

  print STDERR "Did $stows stows, $recs records\n";
} #make_3

sub make_2 {
  my $old_min_size = 0;
  my $last_new_id = 12;
  my $stows = 0;
  my $recs = 0;
  for my $old_store_id (1..12,12) {
    my $old_max_size = int( exp( $old_store_id ) );
    $old_max_size -= 4; # long,rest. Its the rest that we get the size for
    if ( $old_max_size < 0 ) {
      next;
    }
    my $new_size = 4 + $old_max_size;
    if ( $new_size < 1 ) {
      $new_size = 1;
    }
    my $new_store_id = log( $new_size ) / log( 2 );
    if ( int( $new_store_id ) < $new_store_id ) {
      $new_store_id = 1 + int( $new_store_id );
    }
    if ( $new_store_id < 12 ) {
      $new_store_id = 12;       #4096
    }
    my $avg = int( ($old_min_size+$old_max_size) / 2 );
    print STDERR "old store $old_store_id is from $old_min_size/$avg/$old_max_size  -> to store $new_store_id. \n";
    $store->stow( 'x'x$old_min_size ) if $old_min_size;
    ++$stows if $old_min_size;
    ++$recs if $old_min_size;

    my $id = $store->stow( 'x'x($old_max_size-4) );
    ++$recs;
    $store->stow( 'x'x$old_max_size );
    ++$stows;
    $store->delete( $id );
    ++$recs;

    if ( $new_store_id > ($last_new_id+1) ) {
      my $mid_boundary = 2**($last_new_id+1);
      print "   new store ".($new_store_id-1)." with min ".($mid_boundary-1)."\n";
      $store->stow( 'x'x($mid_boundary-1) ); #still on the first new store id
      ++$stows;
      ++$recs;
      $store->stow( 'x'x($mid_boundary) ); #start of cleft
      ++$stows;
      ++$recs;
    } 
    else {
      $store->stow( 'x'x$avg );
      ++$stows;
      ++$recs;
    }
    
    $last_new_id = $new_store_id;
    $old_min_size = $old_max_size + 1;
  }

  print STDERR "Did $stows stows, $recs records\n";
} #make_2

sub make_4_or_5 {
  my $old_min_size = 0;
  my $last_new_id = 12;
  my $stows = 0;
  my $recs = 0;
  for my $old_silo_id (1..12,12) {
    my $old_max_size = int( exp( $old_silo_id ) );
    $old_max_size -= 4; # long,rest. Its the rest that we get the size for
    if ( $old_max_size < 0 ) {
      next;
    }
    my $new_size = 4 + $old_max_size;
    if ( $new_size < 1 ) {
      $new_size = 1;
    }
    my $new_silo_id = log( $new_size ) / log( 2 );
    if ( int( $new_silo_id ) < $new_silo_id ) {
      $new_silo_id = 1 + int( $new_silo_id );
    }
    if ( $new_silo_id < 12 ) {
      $new_silo_id = 12;       #4096
    }
    my $avg = int( ($old_min_size+$old_max_size) / 2 );
    $store->stow( 'x'x$old_min_size ) if $old_min_size;
    ++$stows if $old_min_size;
    ++$recs if $old_min_size;

    my $id = $store->stow( 'x'x($old_max_size-4) );
    ++$recs;
    $store->stow( 'x'x$old_max_size );
    ++$stows;
    $store->delete_record( $id );
    ++$recs;

    if ( $new_silo_id > ($last_new_id+1) ) {
      my $mid_boundary = 2**($last_new_id+1);
      print "   new store ".($new_silo_id-1)." with min ".($mid_boundary-1)."\n";
      $store->stow( 'x'x($mid_boundary-1) ); #still on the first new store id
      ++$stows;
      ++$recs;
      $store->stow( 'x'x($mid_boundary) ); #start of cleft
      ++$stows;
      ++$recs;
    } 
    else {
      $store->stow( 'x'x$avg );
      ++$stows;
      ++$recs;
    }
    
    $last_new_id = $new_silo_id;
    $old_min_size = $old_max_size + 1;
  }

  print STDERR "Did $stows stows, $recs records\n";
} #make_4_or_5

#make_2();
#make_3();
#make_3_1();
make_4_or_5();

__END__

3.21
old store 3 is from 0 to 8 -> to store 12. 
old store 4 is from 9 to 42 -> to store 12. 
old store 5 is from 43 to 136 -> to store 12. 
old store 6 is from 137 to 391 -> to store 12. 
old store 7 is from 392 to 1084 -> to store 12. 
old store 8 is from 1085 to 2968 -> to store 12. 
old store 9 is from 2969 to 8091 -> to store 13. 
old store 10 is from 8092 to 22014 -> to store 15. 
old store 11 is from 22015 to 59862 -> to store 16. 
old store 12 is from 59863 to 162742 -> to store 18. 
