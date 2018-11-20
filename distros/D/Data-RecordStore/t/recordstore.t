use strict;
use warnings;

use Data::RecordStore;
use lib 't/lib';

use Data::Dumper;
use Fcntl ':mode';
use File::Temp qw/ :mktemp tempdir /;
use Test::More;
use Errno qw(ENOENT);

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

BEGIN {
    use_ok( "Data::RecordStore" ) || BAIL_OUT( "Unable to load Data::RecordStore" );
}

# -----------------------------------------------------
#               init
# -----------------------------------------------------
test_suite();
test_open();
test_stow_and_fetch_and_delete();
test_recycle();
test_record_silos();

done_testing;

exit( 0 );

sub test_recycle {
    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::RecordStore->open_store( $dir );

    my $id = $store->stow( "REC1 " );
    is( $id, 1, "first record id " );
    $store->stow( "REC2 " );
    $store->stow( "REC3 " );
    $store->stow( "REC4 " );
    $id = $store->stow( "REC5 " );
    is( $id, 5, "fifth record" );

    is( $store->entry_count, 5, "Five records" );
    $store->delete_record( 1 );
    $store->delete_record( 2 );
    $store->delete_record( 3 );
    $store->delete_record( 4 );
    is( $store->record_count, 1, "one record" );
    $store->recycle_id( 5 );

    my $nextid = $store->next_id;
    is( $id, 5, "fifth record was recycled" );

    is( $store->record_count, 0, "no records" );

    $id = $store->stow( "REC5 ANEW ", $nextid );
    is( $id, 5, "fifth record was recycled" );
    is( $store->fetch( $nextid ), 'REC5 ANEW ', 'recycled fetched' );
    is( $store->record_count, 1, "one record after recycle" );
} #test_recycle

sub test_open {
    local( *STDERR );
    my $out;
    open( STDERR, ">>", \$out );

    # test _log too, just for the code coverage
    $Data::RecordStore::DEBUG = 0;
    Data::RecordStore::_log( "HI THERE" );
    is( $out, undef, "log is silent" );
    $Data::RecordStore::DEBUG = 1;
    Data::RecordStore::_log( "HI THERE AGAIN" );
    is( $out, "HI THERE AGAIN\n", "log is now loud" );
    $Data::RecordStore::DEBUG = 0;

    #
    # test permatations of open and open_store
    #

    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::RecordStore->open( $dir );
    ok( -d $dir, "directory created with ->open" );
    ok( -d "$dir/RECYC_SILO", "recyc silo exists with ->open" );
    ok( -d "$dir/RECORD_INDEX_SILO", "index silo created with ->open" );

    pass( "able to open store via deprecated open" );
    like( $out, qr/Data::RecordStore::open is deprecated/, "open is deprecated" );

    $dir = tempdir( CLEANUP => 1 );
    $store = Data::RecordStore::open( $dir );
    ok( -d $dir, "directory created with ::open" );
    ok( -d "$dir/RECYC_SILO", "recyc silo exists with ::open" );
    ok( -d "$dir/RECORD_INDEX_SILO", "index silo created with ::open" );

    $dir = tempdir( CLEANUP => 1 );

    $dir = tempdir( CLEANUP => 1 );
    $store = Data::RecordStore->open_store( $dir );
    ok( -d $dir, "directory created with ->open" );
    ok( -d "$dir/RECYC_SILO", "recyc silo exists with ->open_store" );
    ok( -d "$dir/RECORD_INDEX_SILO", "index silo created with ->open_store" );

    $dir = tempdir( CLEANUP => 1 );
    $store = Data::RecordStore::open_store( $dir );
    ok( -d $dir, "directory created with ::open_store" );
    ok( -d "$dir/RECYC_SILO", "recyc silo exists with ::open_store" );
    ok( -d "$dir/RECORD_INDEX_SILO", "index silo created with ::open_store" );

    $dir = tempdir( CLEANUP => 1 );
    $store->open_store( $dir );
    ok( -d $dir, "directory created with ->open_store and args" );
    ok( -d "$dir/RECYC_SILO", "recyc silo exists with ->open_store and args" );
    ok( -d "$dir/RECORD_INDEX_SILO", "index silo created with ->open_store and args" );

    $dir = tempdir( CLEANUP => 1 );
    $store->open( $dir );
    ok( -d $dir, "directory created with ->open_store and args" );
    ok( -d "$dir/RECYC_SILO", "recyc silo exists with ->open_store and args" );
    ok( -d "$dir/RECORD_INDEX_SILO", "index silo created with ->open_store and args" );

    #
    # Test directory that can't be written to
    #
    $dir = tempdir( CLEANUP => 1 );
    chmod 0666, $dir;
    eval {
        $store = Data::RecordStore::open_store( $dir );
        fail( "Was able to open store in unwritable directory" );
    };

    is( ENOENT, 2, "could not write to unwritable directory" );
    chmod 0755, $dir;

    Data::RecordStore::open_store( $dir );
    chmod 0444, "$dir/RECORD_INDEX_SILO/0";
    eval {
        $store = Data::RecordStore::open_store( $dir );
        fail( "Was able to open store with unwriteable index" );
    };
    is( ENOENT, 2, "could not write to unwritable directory" );

    chmod 0755, "$dir/RECORD_INDEX_SILO/0";

    #
    # Test old versions
    #
    my $ver = "$dir/VERSION";
    unlink( $ver );
    eval {
        $store = Data::RecordStore::open_store( $dir );
        fail( "was able to open store without version" );
    };
    like( $@, qr/run the record_store_convert/, "fail message for opening store without version" );

    undef $out;
    open $out, '>', $ver;
    print $out "3.2\n";
    close $out;
    eval {
        $store = Data::RecordStore::open_store( $dir );
        fail( "was able to open store without version" );
    };
    like( $@, qr/run the record_store_convert/, "fail message for opening store with old version" );


} #test_open

sub test_stow_and_fetch_and_delete {
    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::RecordStore->open_store( $dir );
    $store->stow( "SOMETHING TO STOW", 2 );
    is( $store->fetch(2), "SOMETHING TO STOW", "stow given id" );

    eval {
        $store->stow( "BADSTOW", 2.1 );
        fail( "was able to stow a non-integer" );
    };

    eval {
        $store->stow( "NOSTOW", 0 );
        fail( "was able to stow a non-positive integer" );
    };

    eval {
        $store->stow( "NOSTOW", -2 );
        fail( "was able to stow a non-positive integer" );
    };
    # 4096 - 5 is 4091 and 8192 - 5 is 8187, 16384 - 5 is 16379
    $store->stow( "x" x 8187, 2 );
    $store->stow( "y" x 4093, 3 );
    is( $store->record_count, 2, "two records in store" );
    is( $store->_get_silo( 13 )->entry_count, 2, "two records in silo 13" );
    is( $store->_get_silo( 12 )->entry_count, 0, "no records in silo 12" );

    $store->stow( "X" x 8189, 2 );
    is( $store->record_count, 2, "still two entries" );
    is( $store->_get_silo( 13 )->entry_count, 1, "still two records in silo 13" );
    is( $store->_get_silo( 14 )->entry_count, 1, "still no records yet in silo 14" );


    # check to see if the entry moves when stowed again with a size
    # that would remove it from one silo and put it in an other

    $store->stow( "X" x 16376, 2 ); #14
    is( $store->record_count, 2, "still two entries" );
    is( $store->_get_silo( 12 )->entry_count, 0, "no records in silo 12" );
    is( $store->_get_silo( 13 )->entry_count, 1, "one records in silo 13" );
    is( $store->_get_silo( 14 )->entry_count, 1, "one records in silo 14" );

    is( $store->fetch(91), undef, "no record for too large a fetch" );


    # swap out a record that is in the middle of a silo and make sure it goes
    # to a smaller silo
    my $sid = $store->stow( "S" x 16376 ); #14
    is( $store->record_count, 3, "now 3 entries" );
    is( $store->_get_silo( 12 )->entry_count, 0, "no records in silo 12" );
    is( $store->_get_silo( 13 )->entry_count, 1, "1 record in silo 13" );
    is( $store->_get_silo( 14 )->entry_count, 2, "2 records in silo 14" );

    $store->stow( "tiny", 2 );
    is( $store->record_count, 3, "still 3 entries" );
    is( $store->_get_silo( 12 )->entry_count, 1, "one records in silo 12" );
    is( $store->_get_silo( 13 )->entry_count, 1, "one records in silo 13" );
    is( $store->_get_silo( 14 )->entry_count, 1, "one records in silo 14" );

    {
        local( *STDERR );
        my $out;
        open( STDERR, ">>", \$out );
        $store->stow( "q" x 12, 5 );
        is( $store->active_entry_count, 4, "4 active records" );

        chmod 0222, "$dir/silos/14_RECSTORE/0";
        eval {
            $store->fetch( $sid );
            fail( "Was able to fetch from unreadable file" );
        };
        like( $@, qr/unable to open/, "unable to open" );

        $store->delete( 5 );
        like( $out, qr/Data::RecordStore::delete is deprecated/, "delete is deprecated" );
    }
    
    is( $store->active_entry_count, 3, "3 active records" );
    eval{    $store->delete_record( 1 );};
    is( $store->active_entry_count, 3, "still 3 active records" );

    $store->recycle_id( 3 );
    $store->recycle_id( 5 );
    is( $store->active_entry_count, 2, "now 2 active records" );
    is( $store->next_id, 5, "recycled 5" );
    is( $store->next_id, 3, "recycled 3" );

    $store->delete_record( 54 );
    is( $store->active_entry_count, 2, "now 2 active record after trying to delete out of bounds record" );

    chmod 0444, "$dir/silos/12_RECSTORE/0";
    eval {
        $store->empty;
        fail( "Was able to unlink store with unwriteable file" );
    };
    like( $@, qr/Unable to empty silo/, "unable to open" );

    chmod 0666, "$dir/silos/12_RECSTORE/0";

    $dir = tempdir( CLEANUP => 1 );
    $store = Data::RecordStore->open_store( $dir );
    $store->stow( "FOO", 1 );
    is( $store->entry_count, 1, "ONE THING" );
    $store->stow( "BAR", 1 );
    is( $store->entry_count, 1, "still ONE THING" );

    #
    # Make sure this doesn't pop out of its location
    #
    my $id = $store->stow( "BAAAAAAAAGS" );
    $store->stow( "H", $id );
    eval {
        is( $store->fetch( $id ), "H", "didn't pop out" );
        pass( "last item stayed in the smallest silo despite being much smaller" );
    };
    ok( ! $@, "no errors in pop test" );

    is( $store->_get_silo( 12 )->entry_count, 2, "two records in silo 12" );

    $store->stow( "B" x 5000, $id );
    is( $store->_get_silo( 12 )->entry_count, 1, "one records in silo 12" );
    is( $store->_get_silo( 13 )->entry_count, 1, "one records in silo 12" );

    $store->stow( "t", $id );
    is( $store->_get_silo( 12 )->entry_count, 2, "back to two records in silo 12" );
    is( $store->_get_silo( 13 )->entry_count, 0, "back to no records in silo 12" );


    # test putting something big in 12, then shrinking it down and make sure it wasn't deleted
    $dir = tempdir( CLEANUP => 1 );
    $store = Data::RecordStore->open_store( $dir );
    $id = $store->stow( "X" x 4000 );
    is( $store->fetch( $id ), 'X' x 4000, 'stored okey' );
    is( $store->_get_silo( 12 )->entry_count, 1, "stored in silo 12" );
    my $id2 = $store->stow( "X" x 3000, $id );
    is( $id2, $id, "id didn't change" );
    is( $store->fetch( $id2 ), 'X' x 3000, 'restored okey' );
    is( $store->_get_silo( 12 )->entry_count, 1, "still stored in silo 12" );
    $store->stow( "X", $id );
    is( $store->fetch( $id ), 'X', 'tinystored stored okey' );
    is( $store->_get_silo( 12 )->entry_count, 1, "tiny stored in silo 12" );

    
} #test_stow_and_fetch_and_delete

sub test_suite {
    my $dir = tempdir( CLEANUP => 1 );
    my $dir2 = tempdir( CLEANUP => 1 );
    my $dir3 = tempdir( CLEANUP => 1 );

    my $store = Data::RecordStore->open_store( $dir );
    is( $store->entry_count, 0, 'no entries in new store' );
    ok( ! $store->has_id( 1 ), "no first id yet" );
    ok( ! $store->has_id( 2 ), "no second id yet" );

    my $id  = $store->stow( "FOO FOO" );
    ok( $store->has_id( 1 ), "now has first id" );
    ok( ! $store->has_id( 2 ), "still no second id yet" );

    my $id2 = $store->stow( "BAR BAR" );
    ok( $store->has_id( 2 ), "now has second id" );

    my $id3 = $store->stow( "Käse essen" );

    # store with 3 entries
    is( $store->entry_count, 3, "store 3 entries" );

    $store = Data::RecordStore->open_store( $dir );
    is( $id2, $id + 1, "Incremental object ids" );
    is( $store->fetch( $id ), "FOO FOO", "first item saved" );
    is( $store->fetch( $id2 ), "BAR BAR", "second item saved" );
    is( $store->fetch( $id3 ), "Käse essen", "third item saved" );

    my $ds = Data::RecordStore::Silo->open_silo( "LLA4", "$dir2/filename" );
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

    my $cur_silo = $store->_get_silo( 13 );
    is( $cur_silo->entry_count, 0, "silo #13 empty" );

    $cur_silo = $store->_get_silo( 12 );
    is( $cur_silo->entry_count, 3, "silo #12 full of stuff" );

    #
    # Try testing the moving of a record
    #
    $store = Data::RecordStore->open_store( $dir3 );

    # 12 is 4096 - 5 = 4091, 13 is 8192 - 5 = 8187
    $id = $store->stow( "x" x 4087 ); #12
    $store->stow( "x" x 8187 ); # 13

    is( $store->entry_count, 2, "two entry count in store" );

    $cur_silo = $store->_get_silo( 12 );
    is( $cur_silo->entry_count, 1, "One entry in silo #12" );
    is( $store->_get_silo( 13 )->entry_count, 1, "One entry in silo #13" );

    my $yid = $store->stow( "y" ); #real small, should still be in 12 which is the minimum
    is( $yid, 3, "Third ID" );
    is( $cur_silo->entry_count, 2, "Two entry in silo #12" );

    $store->stow( "x" x 8188, $id );  # 12 is max 4092, 13 is max 8187
    is( $store->_get_silo( 13 )->entry_count, 1, "One entry in silo #13" );

    is( $cur_silo->entry_count, 1, "Entry relocated from silo #12" );
    my $new_silo = $store->_get_silo( 14 );
    is( $new_silo->entry_count, 1, "One entry relocated to silo #14" );

    is( $store->fetch( $yid ), "y", "correctly relocated data" );

    # try for a much smaller relocation

    $new_silo = $store->_get_silo( 5 );
    is( $new_silo->entry_count, 0, "No entries in silo #5" );


    $store->stow( "x" x 90, $id );

    $new_silo = $store->_get_silo( 14 );
    is( $new_silo->entry_count, 0, "One entry relocated from silo #14" );
    $new_silo = $store->_get_silo( 12 );
    is( $new_silo->entry_count, 2, "One entry relocated to silo #12" );

    # test for record too large. idx out of bounds

    my $xid = $store->stow( "x" x 90 );
    is( $new_silo->entry_count, 3, "Three entries now in silo #12" );
    $store->delete_record( $id );
    is( $new_silo->entry_count, 2, "two entries now in silo #12 after delete" );

    # test store empty
    $store->empty;
    ok( !$store->has_id(1), "does not have any entries" );
    ok( !$store->has_id(0), "does not have any entries" );

    is( $store->entry_count, 0, "empty then no entries" );

    $store->stow( "BOOGAH", 4 );
    is( $store->next_id, '5', "next id is 5" );
    is( $store->entry_count, 5, "5 entries after skipping ids plus asking to generate the next one" );
    ok( $store->has_id(4), "has entry four" );
    ok( ! $store->has_id(1), "no entry one, was skipped" );

    $store->recycle_id( 3 );
    is( $store->entry_count, 4, "4 entries after recycling entry" );
    is( $store->next_id, 3, 'recycled id' );
    is( $store->entry_count, 5, "5 entries after recycling empty id" );
    is( $store->next_id, 6, 'no more recycling ids' );
    is( $store->fetch( 4 ), "BOOGAH" );
    $store->recycle_id( 4 );
    ok( ! $store->fetch( 4 ), "4 was recycled" );
    is( $store->next_id, 4, 'recycled id 4' );

    $store->stow( "TEN", 10 );
    is( $store->entry_count, 10, "entry count explicitly set" );
    is( $store->next_id, 11, 'after entry count being set' );

    $store->recycle_id(2);
    is( $store->next_id, 2, 'recycled id' );
    $store->recycle_id(3);
    $store->recycle_id(4);
    $store->empty_recycler;

    is( $store->next_id, 12, 'after recycler emptied' );

} #test suite

sub test_record_silos {
    my $dir = tempdir( CLEANUP => 1 );

    $Data::RecordStore::Silo::MAX_SIZE = 80;

    my $store = Data::RecordStore->open_store( $dir );
    $store->empty;

    is( $store->entry_count, 0, "Emptied store" );

    for( 1..11 ) {
        my $id = $store->next_id;
        $store->stow( "GZAA $id", $id );
        is( $id, $_, "got correct id $_" );
    }

} #test_record_silos

__END__
