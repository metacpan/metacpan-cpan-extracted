use Data::RecordStore;

use strict;
use warnings;

print $Data::RecordStore::VERSION,"\n";
die if $Data::RecordStore::VERSION > 4 || $Data::RecordStore::VERSION < 3.1;

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



my $store = Data::RecordStore::open_store( "t/upgrade_data" );

my $id = 1;
sub check {
    my( $size ) = @_;
    my $d = $store->fetch( $id++ );
    print length($d)." vs $size\n";
    if( length( $d ) == $size ) {
        return;
    }
    return "ERROR\n";exit;
}

my $old_min_size = 0;
my $last_new_id = 12;
for my $old_store_id (1..12) {
    my $old_max_size = int( exp( $old_store_id ) );
    $old_max_size -= 12; # long,id,rest. Its the rest that we get the size for
    if( $old_max_size < 0 ) {next;
        $old_store_id = 3;
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
    print "old store $old_store_id is from $old_min_size to $old_max_size  -> to store $new_store_id. \n";
    check( $old_min_size );
    check( $old_max_size );
#    $store->stow( 'x'x$old_min_size );
#    $store->stow( 'x'x$old_max_size );

    if( $new_store_id > ($last_new_id+1) ) {
        my $mid_boundary = 2**($last_new_id+1);
        print "   new store ".($new_store_id-1)." with min $mid_boundary\n";
        check( $mid_boundary-1 );
        check( $mid_boundary );
#        $store->stow( 'x'x() ); #still on the first new store id
#        $store->stow( 'x'x($mid_boundary) ); #start of cleft
    } 
    else {
        check( $avg );
#        $store->stow( 'x'x$avg );
    }
    
    $last_new_id = $new_store_id;
    $old_min_size = $old_max_size + 1;
}


for (1..$store->entry_count) {
    my $d = $store->fetch( $_ );
    print length( $d ),"\n";
}
exit;
$store->empty;

$old_min_size = 0;
$last_new_id = 12;
for my $old_store_id (1..12) {
    my $old_max_size = int( exp( $old_store_id ) );
    $old_max_size -= 12; # long,id,rest. Its the rest that we get the size for
    if( $old_max_size < 0 ) {next;
        $old_store_id = 3;
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
    print "old store $old_store_id is from $old_min_size to $old_max_size  -> to store $new_store_id. \n";
    $store->stow( 'x'x$old_min_size );
    my $id = $store->stow( 'x'x($old_max_size-4) );
    $store->stow( 'x'x$old_max_size );
    $store->delete_record( $id );

    if( $new_store_id > ($last_new_id+1) ) {
        my $mid_boundary = 2**($last_new_id+1);
        print "   new store ".($new_store_id-1)." with min ".($mid_boundary-1)."\n";
        $store->stow( 'x'x($mid_boundary-1) ); #still on the first new store id
        $store->stow( 'x'x($mid_boundary) ); #start of cleft
    } 
    else {
        $store->stow( 'x'x$avg );
    }
    
    $last_new_id = $new_store_id;
    $old_min_size = $old_max_size + 1;
}
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
