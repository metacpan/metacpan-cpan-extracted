use strict;
use warnings;

use Data::RecordStore;

use Data::Dumper;
use File::Path qw/remove_tree/;
use File::Temp qw/ :mktemp tempdir /;
use Test::More;

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

BEGIN {
    use_ok( "Data::RecordStore" ) || BAIL_OUT( "Unable to load Data::RecordStore" );
}

test_suite();

done_testing;

exit;


sub test_suite {

    my $old_version_store = "t/upgrade_data";
    my $new_version_store = tempdir( CLEANUP => 1 )."/new_version";
    system( 'bin/record_store_convert', $old_version_store, $new_version_store );
    our $store = Data::RecordStore::open_store( $new_version_store );

    warn "the store created was touched up manually, the last few blank entries not created by the creation program. Make them match and update the tests.";
    is( $store->entry_count, 32, 'converted store has 32 entries' );
    is( $store->record_count, 32, 'converted store has 35 entries' );
    
    our $id = 1;
    sub check {
        my( $size, $old_id, $new_id ) = @_;
        my $d = $store->fetch( $id ) || '';
        is( length( $d ), $size, "converting $id from old store $old_id to new store $new_id" );
        if( $d eq 'x'x$size ) {
            pass( "converting $id from old store $old_id to new store $new_id" );
        } else {
            fail( "converting $id from old store $old_id to new store $new_id" );
        }
        $id++;
    }

    
    my $old_min_size = 0;
    my $last_new_id = 12;
    for my $old_store_id (1..12) {
        my $old_max_size = int( exp( $old_store_id ) );
        $old_max_size -= 12; # long,id,rest. Its the rest that we get the size for
        if( $old_max_size < 0 ) {
            next;
        }
        my $new_size = 4 + $old_max_size;
        if( $new_size < 1 ) { $new_size = 1; }
        my $new_store_id = log( $new_size ) / log( 2 );
        if( int( $new_store_id ) < $new_store_id ) {
            $new_store_id = 1 + int( $new_store_id );
        }
        if( $new_store_id < 12 ) {
            $new_store_id = 12; #4096
        }
        my $avg = int( $old_max_size / 2 );

        check( $old_min_size, $old_store_id, $new_store_id );
        check( $old_max_size, $old_store_id, $new_store_id );

        if( $new_store_id > ($last_new_id+1) ) {
            my $mid_boundary = 2**($last_new_id+1);
            check( $mid_boundary-1, $old_store_id, $new_store_id );
            check( $mid_boundary, $old_store_id, $new_store_id );
        } 
        else {
            check( $avg, $old_store_id, $new_store_id );
        }
        
        $last_new_id = $new_store_id;
        $old_min_size = $old_max_size + 1;
    }
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
