use strict;
use warnings;
no warnings 'numeric';

use Data::RecordStore;

use Data::Dumper;
use File::Path qw/remove_tree/;
use File::Temp qw/ :mktemp tempdir /;
use Test::More;

use Carp 'longmess'; 
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

BEGIN {
    use_ok( "Data::RecordStore" ) || BAIL_OUT( "Unable to load Data::RecordStore" );
    use_ok( "Data::RecordStore::Converter" ) || BAIL_OUT( "Unable to load Data::RecordStore" );
}

test_suite();

done_testing;

exit;


sub test_suite {

  my $base = "t/upgrade_data";
  opendir (my $DIR, $base);
  my( @subs ) = readdir( $DIR );

  our $id = 1;
  sub check {
    my( $store, $size, $old_id, $new_id, $ver ) = @_;
    my $d = $store->fetch( $id ) || '';
    is( length( $d ), $size, "converting $id from old store $old_id to new store $new_id for version $ver" );
    if ( $d eq 'x'x$size ) {
      pass( "converting $id from old store $old_id to new store $new_id for version $ver" );
    }
    else {
      fail( "converting $id from old store $old_id to new store $new_id for version $ver" );
    }
    $id++;
  }

  # test the directory that isn't there, really.
  my $notthere = tempdir( CLEANUP => 1 )."/nothing_here";
  eval {
    Data::RecordStore::Converter::convert( "$base/4.03" );
    fail( "did not die when trying to convert to ja not there directory" );
  };
  like( $@, qr/must be given a destination/, "error message for convert dest directory not there" );

  my $isthere = tempdir( CLEANUP => 1 );
  eval {
    Data::RecordStore::Converter::convert( $notthere, $isthere );
    fail( "did not die when trying to convert from a not there directory" );
  };
  like( $@, qr/cannot find source directory/, "error message for source dest directory not there" );

  eval {
    Data::RecordStore::Converter::convert( $notthere );
    fail( "did not die when trying to convert to a not there directory and from a not there directory" );
  };
  like( $@, qr/must be given a destination/, "error message for convert dest directory not there" );


  for my $old_version_store (grep { $_ > 0 } @subs) {

    diag "Testing $old_version_store";
    my $new_version_store = tempdir( CLEANUP => 1 )."/new_version";


    $id = 1;
    if( $old_version_store eq '4.03' ) {
      local( *STDERR );
      my $out;
      open( STDERR, ">>", \$out );
      
      Data::RecordStore::Converter::convert( "$base/$old_version_store", $new_version_store );
      like( $out, qr/already at version/, 'warning message for trying to convert store that didnt need it' );
      close $out;
    }
    elsif( $old_version_store eq '3.22' ) {
      Data::RecordStore::Converter::convert( "$base/$old_version_store", $new_version_store );
      my $store = Data::RecordStore::open_store( $new_version_store );

      #the store created was touched up manually, the last few blank entries not created by the creation program. Make them match and update the tests.";
      is( $store->entry_count, 45, 'converted store has 45 entries' );
      is( $store->active_entry_count, 34, 'converted store has 34 active entries' );
      is( $store->record_count, 34, 'converted store has 34 records' );
    

      my $old_min_size = 0;
      my $last_new_id = 12;
      for my $old_store_id (1..12,12) {
        my $old_max_size = int( exp( $old_store_id ) );
        $old_max_size -= 12; # long,id,rest. Its the rest that we get the size for
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
          $new_store_id = 12;   #4096
        }
        my $avg = int( ($old_max_size+$old_max_size) / 2 );

        check( $store, $old_min_size, $old_store_id, $new_store_id, $old_version_store ) if $old_min_size;
        $id++;
        check( $store, $old_max_size, $old_store_id, $new_store_id, $old_version_store );

        if ( $new_store_id > ($last_new_id+1) ) {
          my $mid_boundary = 2**($last_new_id+1);
          check( $store, $mid_boundary-1, $old_store_id, $new_store_id, $old_version_store );
          check( $store, $mid_boundary, $old_store_id, $new_store_id, $old_version_store );
        } 
        else {
          check( $store, $avg, $old_store_id, $new_store_id, $old_version_store );
        }
        
        $last_new_id = $new_store_id;
        $old_min_size = $old_max_size + 1;
      }
    } 
    elsif( $old_version_store eq '3.00' ) {
      Data::RecordStore::Converter::convert( "$base/$old_version_store", $new_version_store );
      my $store = Data::RecordStore::open_store( $new_version_store );

      is( $store->entry_count, 49, 'converted store has 49 entries' );
      is( $store->active_entry_count, 37, 'converted store has 37 active entries' );
      is( $store->record_count, 37, 'converted store has 37 records' );

      my $old_min_size = 0;
      my $last_new_id = 12;
      my $stows = 0;
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
          $new_store_id = 12;   #4096
        }
        my $avg = int( ($old_min_size+$old_max_size) / 2 );

        if( $old_min_size ) {
          check( $store, $old_min_size, $old_store_id, $new_store_id, $old_version_store );
        }

        check( $store, 0, $old_store_id, $new_store_id, $old_version_store ); #check the deleted one

        check( $store, $old_max_size, $old_store_id, $new_store_id, $old_version_store );

        if ( $new_store_id > ($last_new_id+1) ) {
          my $mid_boundary = 2**($last_new_id+1);
          check( $store, $mid_boundary-1, $old_store_id, $new_store_id, $old_version_store );
          check( $store, $mid_boundary, $old_store_id, $new_store_id, $old_version_store );
        } 
        else {
          check( $store, $avg, $old_store_id, $new_store_id, $old_version_store );
        }
    
        $last_new_id = $new_store_id;
        $old_min_size = $old_max_size + 1;
      }
      
    }
    elsif( $old_version_store eq '2.03' ) {
      Data::RecordStore::Converter::convert( "$base/$old_version_store", $new_version_store );
      my $store = Data::RecordStore::open_store( $new_version_store );

      is( $store->entry_count, 49, 'converted store has 49 entries' );
      is( $store->active_entry_count, 37, 'converted store has 37 active entries' );
      is( $store->record_count, 37, 'converted store has 37 records' );

      my $old_min_size = 0;
      my $last_new_id = 12;
      my $stows = 0;
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
          $new_store_id = 12;   #4096
        }
        my $avg = int( ($old_min_size+$old_max_size) / 2 );

        if( $old_min_size ) {
          check( $store, $old_min_size, $old_store_id, $new_store_id, $old_version_store );
        }

        check( $store, 0, $old_store_id, $new_store_id, $old_version_store ); #check the deleted one

        check( $store, $old_max_size, $old_store_id, $new_store_id, $old_version_store );

        if ( $new_store_id > ($last_new_id+1) ) {
          my $mid_boundary = 2**($last_new_id+1);
          check( $store, $mid_boundary-1, $old_store_id, $new_store_id, $old_version_store );
          check( $store, $mid_boundary, $old_store_id, $new_store_id, $old_version_store );
        } 
        else {
          check( $store, $avg, $old_store_id, $new_store_id, $old_version_store );
        }
    
        $last_new_id = $new_store_id;
        $old_min_size = $old_max_size + 1;
      }
    }
    elsif( $old_version_store eq '1.07' ) {
      Data::RecordStore::Converter::convert( "$base/$old_version_store", $new_version_store );
      my $store = Data::RecordStore::open_store( $new_version_store );

      #the store created was touched up manually, the last few blank entries not created by the creation program. Make them match and update the tests.";
      is( $store->entry_count, 24, 'converted store has 24 entries' );
      is( $store->active_entry_count, 24, 'converted store has 24 active entries' );
      is( $store->record_count, 24, 'converted store has 24 records' );

      my $old_min_size = 0;
      my $last_new_id = 12;
      my $old_size_chunk = 500;

      for my $old_store_id (1..12) {
        my $old_max_size = $old_size_chunk * $old_store_id;

        my $new_store_id = log( $old_max_size + 1 ) / log( 2 );
        if ( int( $new_store_id ) < $new_store_id ) {
          $new_store_id = 1 + int( $new_store_id );
        }
        if ( $new_store_id < 12 ) {
          $new_store_id = 12;   #4096
        }
        my $avg = int( ($old_min_size + $old_max_size) / 2 );

        if( $old_store_id == 12 ) {
          check( $store, (8192-5), 3, 13, $old_version_store );
        }

        if( $old_min_size ) {
          check( $store, $old_min_size, $old_store_id, $new_store_id, $old_version_store );
        }

        if ( $new_store_id > ($last_new_id+1) ) {
          my $mid_boundary = 2**($last_new_id+1);
          check( $store, $mid_boundary-1, $old_store_id, $new_store_id, $old_version_store );
          check( $store, $mid_boundary, $old_store_id, $new_store_id, $old_version_store );
        } 
        else {
          check( $store, $avg, $old_store_id, $new_store_id, $old_version_store );
        }
        
        $last_new_id = $new_store_id;
        $old_min_size = $old_max_size + 1;
      }
      
      
    }
  } #each version test
} #test_suite


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
