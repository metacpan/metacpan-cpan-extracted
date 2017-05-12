use strict;
use warnings;

use Data::RecordStore;

use Data::Dumper;
use File::Temp qw/ :mktemp tempdir /;
use Test::More;
use JSON;

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

BEGIN {
    use_ok( "Data::RecordStore" ) || BAIL_OUT( "Unable to load Data::RecordStore" );
}

# -----------------------------------------------------
#               init
# -----------------------------------------------------

my $dir = tempdir( CLEANUP => 1 );
my $dir2 = tempdir( CLEANUP => 1 );
my $dir3 = tempdir( CLEANUP => 1 );
test_suite();
done_testing;

exit( 0 );


sub test_suite {

    my $store = Data::RecordStore->open( $dir );

    ok( ! $store->has_id( 1 ), "no first id yet" );
    ok( ! $store->has_id( 2 ), "no second id yet" );
    
    my $id  = $store->stow( "FOO FOO" );
    ok( $store->has_id( 1 ), "now has first id" );
    ok( ! $store->has_id( 2 ), "still no second id yet" );
    my $id2 = $store->stow( "BAR BAR" );
    ok( $store->has_id( 2 ), "now has second id" );
    my $json_data = encode_json( {
        todo => [ "Käse essen"  ],
                             } );
    my $id3 = $store->stow( $json_data );

    $store = Data::RecordStore->open( $dir );    
    is( $id2, $id + 1, "Incremental object ids" );
    is( $store->fetch( $id ), "FOO FOO", "first item saved" );
    is( $store->fetch( $id2 ), "BAR BAR", "second item saved" );
    is( $store->fetch( $id3 ), encode_json( {
        todo => [ "Käse essen"  ],
                                        } ), "third item saved" );
    
    my $ds = Data::RecordStore::FixedStore->open( "LLA4", "$dir2/filename" );
    my( @r ) = (
        [],
        [ 12,44,"BOO" ],
        [ 2342,300,"QSA" ],
        [ 66,89,"DDI" ],
        [ 2,139,"FUR" ],
        [ 12,19939,"LEG" ],
        );

    $ds->push( $r[1] );
    $ds->push( $r[2] );
    $ds->push( $r[3] );
    
    is_deeply( $ds->get_record( 2 ), $r[2], "Second record" );
    is_deeply( $ds->get_record( 1 ), $r[1], "First record" );
    is_deeply( $ds->get_record( 3 ), $r[3], "Third record" );

    #
    # Try testing the moving of a record
    #
    $store = Data::RecordStore->open( $dir3 );
    $id = $store->stow( "x" x 2972 );
    my $cur_store = $store->_get_store( 8 );

    is( $cur_store->entry_count, 1, "One entry in store #8" );

    my $yid = $store->stow( "y" x 2972 );
    is( $cur_store->entry_count, 2, "Two entry in store #8" );
    
    $store->stow( "x" x 3000, $id );

    is( $cur_store->entry_count, 1, "Entry relocated from store #8" );
    my $new_store = $store->_get_store( 9 );
    is( $new_store->entry_count, 1, "One entry relocated to store #9" );

    is( $store->fetch( $yid ), "y" x 2972, "correctly relocated data" );

    # try for a much smaller relocation

    $store->stow( "x" x 90, $id );
    
    is( $new_store->entry_count, 0, "One entry relocated from store #9" );
    $new_store = $store->_get_store( 5 );
    is( $new_store->entry_count, 1, "One entry relocated to store #5" );
    # test for record too large. idx out of bounds

    my $xid = $store->stow( "x" x 90 );
    is( $new_store->entry_count, 2, "Two entries now in store #5" );
    $store->delete( $id );
    is( $new_store->entry_count, 1, "one entries now in store #5 after delete" );
    
} #test suite


__END__
