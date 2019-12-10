#!/usr/bin/perl
use strict;
use warnings;
no warnings 'numeric';

use Data::RecordStore;

use Data::Dumper;
use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree make_path/;
use File::Temp qw/ :mktemp tempdir /;
use Test::More;

use Data::RecordStore;
use Data::RecordStore::Converter;

use Carp 'longmess'; 
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

eval {
    test_suite();
};
fail( "failed $@ $! $?") if $@;
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
    is( length( $d ), $size, "converting $id from old silo $old_id to new silo $new_id for version $ver" );
    if ( $d eq 'x'x$size ) {
      pass( "converting $id from old silo $old_id to new silo $new_id for version $ver" );
    }
    else {
      fail( "converting $id from old silo $old_id to new silo $new_id for version $ver" );
    }
    $id++;
  }
  sub chk  {
      my( $new, $old, $msg ) = @_;
      is( length( $new ), length( $old ), "$msg size check" );
#      is( $new, $old, "$msg full check" );
  };

  sub failright {
      my( $sub, $errm, $msg ) = @_;
      eval {
          $sub->();
          fail( $msg );
      };
      like( $@, qr/$errm/, $msg );
      undef $@;
  }

  # test the directory that isn't there, really.
  my $notthere       = tempdir( CLEANUP => 1 )."/nothing_here";
  my $notthere_too   = "$notthere/../nothing_here_too";
  my $notthere_three = "$notthere/../nothing_here_three";

  my $isthere     = tempdir( CLEANUP => 1 );
  my $isthere_too = tempdir( CLEANUP => 1 );

  # error matrix
  failright( sub { Data::RecordStore::Converter->convert( "$base/4.03" ); },
             'must be given a destination',
             "did not die when trying given no destination directory" );

  failright( sub { Data::RecordStore::Converter->convert( "$base/nothinghere", "$base/whereelse" ); },
             'cannot find source',
             "no source directory given" );

  failright( sub { Data::RecordStore::Converter->convert( undef, "$base/whereelse" ); },
             'must be given a source directory',
             "no source directory given" );

  failright( sub { Data::RecordStore::Converter->convert( "$base/4.03", "$base/3.22" ); },
             'destination directory.*already exists/',
             "did not die when dest directory exists" );

  for my $old_version_store (grep { $_ > 0 } @subs) {
      my $tmp = tempdir( CLEANUP => 1 );
      my $dest_dir = "$tmp/new_version";
      my $source_dir  = "$tmp/old_version";
      
      # copy the source dir to a temp directory
      dircopy( "$base/$old_version_store", $source_dir );
      $id = 1;
      if( $old_version_store > 3.22 ) {

          if( $old_version_store eq '4.03' ) {
              # test that an empty existing directory is fine
              make_path( $dest_dir );
          }
          Data::RecordStore::Converter->convert( $source_dir, $dest_dir );

          my $store = Data::RecordStore->open_store( $dest_dir );
          

          # the store created was touched up manually, the last few blank entries not created by the creation program. 
          # Make them match and update the tests.";
          
          is( $store->entry_count, 49, "$old_version_store store has 49 entries" );
          #        is( $store->active_entry_count, 37, '4 store has 37 active entries' );
          #        is( $store->record_count, 37, '4 store has 37 records' );
          my $old_min_size = 0;
          my $last_new_id = 12;
          my $stows = 0;
          my $recs = 0;

          for my $old_silo_id (1..12) {
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

              if( $old_min_size ) {
                  chk( $store->fetch( $id++ ), 'x'x$old_min_size, "old min size for $old_silo_id $old_version_store check" );
              }
              is( $store->fetch( $id++ ), '', "old max size -4 was deleted for $old_silo_id $old_version_store check" );
              chk( $store->fetch( $id++ ), 'x'x($old_max_size), "old max size for $old_silo_id $old_version_store check" );

              if ( $new_silo_id > ($last_new_id+1) ) {
                  my $mid_boundary = 2**($last_new_id+1);
                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary-1), "mid boundary -1 for $old_silo_id $old_version_store check" );
                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary), "mid boundary for $old_silo_id $old_version_store check" );

              } 
              else {
                  chk( $store->fetch( $id++ ), 'x'x($avg), "avg for $old_silo_id $old_version_store check" );
              }
              
              $last_new_id = $new_silo_id;
              $old_min_size = $old_max_size + 1;
          }
          
      } #4.03
      elsif( $old_version_store eq '3.22' ) {
          failright( sub { Data::RecordStore->reopen_store( $source_dir ); },
                     "was able to open store with older version",
                     qr/run the record_store_convert/,
                     "fail message for opening store without version" );

          Data::RecordStore::Converter->convert( $source_dir, $dest_dir );
          my $store = Data::RecordStore->open_store( $dest_dir );

          #the store created was touched up manually, the last few blank entries not created by the creation program. Make them match and update the tests.";
          is( $store->entry_count, 45, 'converted store has 45 entries' );
          #      is( $store->active_entry_count, 34, 'converted store has 34 active entries' );
          #      is( $store->record_count, 34, 'converted store has 34 records' );
          
          my $old_min_size = 0;
          my $last_new_id = 12;
          my $stows = 0;
          my $recs = 0;

          for my $old_store_id (1..12) {
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

              if( $old_min_size ) {
                  chk( $store->fetch( $id++ ), 'x'x$old_min_size, "old min size for $old_store_id 3.1 check" );
              }
              is( $store->fetch( $id++ ), '', "old max size -4 was deleted for $old_store_id 3.1 check" );
              chk( $store->fetch( $id++ ), 'x'x($old_max_size), "old max size for $old_store_id 3.10 check" );

              if ( $new_store_id > ($last_new_id+1) ) {
                  my $mid_boundary = 2**($last_new_id+1);
                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary-1), "mid boundary -1 for $old_store_id 3.10 check" );
                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary), "mid boundary for $old_store_id 3.10 check" );
              } 
              else {
                  chk( $store->fetch( $id++ ), 'x'x($avg), "avg for $old_store_id 3.10 check" );            
              }
              
              $last_new_id = $new_store_id;
              $old_min_size = $old_max_size + 1;
          }
      } #3.22 
      elsif( $old_version_store eq '3.00' ) {
          failright( sub { Data::RecordStore->reopen_store( $source_dir ) },
                     'run the record_store_convert',
                     "was able to open store with older version" );

          Data::RecordStore::Converter->convert( $source_dir, $dest_dir );
          my $store = Data::RecordStore->open_store( $dest_dir );

          is( $store->entry_count, 49, 'converted store has 49 entries' );

          my $old_min_size = 0;
          my $last_new_id = 12;
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

              if( $old_min_size ) {
                  chk( $store->fetch( $id ), 'x'x$old_min_size, "old min size (id ".($id++).") for $old_store_id 3.00 check" );
              }

              is( $store->fetch( $id ), '', "old max size -4 (id ".($id++).") was deleted for $old_store_id 3.00 check" );
              chk( $store->fetch( $id ), 'x'x($old_max_size), "old max size (id ".($id++).") for $old_store_id 3.00 check" );

              if ( $new_store_id > ($last_new_id+1) ) {
                  my $mid_boundary = 2**($last_new_id+1);
                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary-1), "mid boundary -1 for $old_store_id 3.00 check" );
                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary), "mid boundary for $old_store_id 3.00 check" );

              } 
              else {
                  chk( $store->fetch( $id ), 'x'x($avg), "avg (id ".($id++).") for $old_store_id 3.00 check" );
              }
              
              $last_new_id = $new_store_id;
              $old_min_size = $old_max_size + 1;
          }
          
      } #3.00
      elsif( $old_version_store eq '2.03' ) {
          eval {
              Data::RecordStore->reopen_store( $source_dir );
              fail( "was able to open store with older version" );
          };
          like( $@, qr/could not find record store in/, "fail message for opening store without version" );


          Data::RecordStore::Converter->convert( $source_dir, $dest_dir );
          my $store = Data::RecordStore->open_store( $dest_dir );

          is( $store->entry_count, 49, 'converted store has 49 entries' );


          my $old_min_size = 0;
          my $last_new_id = 12;
          my $id = 1;
          
          for my $old_store_id (1..12) {
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

              if( $old_min_size ) {
                  chk( $store->fetch( $id++ ), 'x'x$old_min_size, "old min size for $old_store_id 2.03 check" );
              }
              #              chk( $store->fetch( $id++ ), 'x'x($old_max_size-4), "old max size -4 for $old_store_id 2.03 check" );
              is( $store->fetch( $id++ ), '', "old max size -4 was deleted for $old_store_id 2.03 check" );
              chk( $store->fetch( $id++ ), 'x'x($old_max_size), "old max size for $old_store_id 2.03 check" );


              if ( $new_store_id > ($last_new_id+1) ) {
                  my $mid_boundary = 2**($last_new_id+1);

                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary-1), "mid boundary -1 for $old_store_id 2.03 check" );
                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary), "mid boundary for $old_store_id 2.03 check" );
              } 
              else {
                  chk( $store->fetch( $id++ ), 'x'x($avg), "avg for $old_store_id 2.03 check" );
              }
              $last_new_id = $new_store_id;
              $old_min_size = $old_max_size + 1;
          }
      } #2.03
      elsif( $old_version_store eq '1.07' ) {

          failright( sub { Data::RecordStore->reopen_store( $source_dir ) },
                    'run the record_store_convert',
                     "was able to open store with older version" );

          my $nada = "$tmp/no_version";
          make_path( $nada );
          failright( sub { Data::RecordStore::Converter->convert( $nada, $dest_dir ) },
                    'No store found',
                     "try to convert with nothing at all" );

          Data::RecordStore::Converter->convert( $source_dir, $dest_dir );
          my $store = Data::RecordStore->open_store( $dest_dir );

          #the store created was touched up manually, the last few blank entries not created by the creation program. Make them match and update the tests.";
          is( $store->entry_count, 24, 'converted store has 24 entries' );

          my $old_min_size = 0;
          my $last_new_id = 12;
          my $old_size_chunk = 500;

          my $id = 1;          
          
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
                  chk( $store->fetch( $id++ ), 'x'x(8192-5), "last iteration for $old_store_id 1.07 check" );
              }

              if( $old_min_size ) {
                  chk( $store->fetch( $id++ ), 'x'x$old_min_size, "old min size for $old_store_id 1.07 check" );
              }

              if ( $new_store_id > ($last_new_id+1) ) {
                  my $mid_boundary = 2**($last_new_id+1);
                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary-1), "under mid boundary for $old_store_id 1.07 check" );
                  chk( $store->fetch( $id++ ), 'x'x($mid_boundary), "under mid boundary for $old_store_id 1.07 check" );
              } 
              else {
                  chk( length($store->fetch( $id++ )), length('x'x($avg)), "under avg for $old_store_id 1.07 check" );
              }
              
              $last_new_id = $new_store_id;
              $old_min_size = $old_max_size + 1;
          }
      } # 1.07
      
      if( $old_version_store < 6 ) {
          is( Data::RecordStore->detect_version( $dest_dir ), $Data::RecordStore::VERSION, "upgrade to current version" );
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

______________________________-
