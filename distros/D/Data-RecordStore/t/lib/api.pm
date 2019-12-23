package api;

use strict;
use warnings;

use Fcntl qw( :flock );
use Data::Dumper;
use Test::More;
use Time::HiRes qw(usleep);

use lib 't/lib';
use forker;

# -----------------------------------------------------
#               RecordStore
# -----------------------------------------------------


sub test_suite_recordstore {
    my( $cls, $rs_factory ) = @_;
    $cls->test_stow_and_fetch_and_delete( $rs_factory );
    $cls->test_locks( $rs_factory );
    $cls->test_recordstore( $rs_factory );
}


sub test_stow_and_fetch_and_delete {
    my( $cls, $rs_factory ) = @_;

    my $store = $rs_factory->new_rs;

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

#    my $dbh = $store->{DBH};
#    my $sth = $dbh->prepare( "SELECT * FROM test" );
#    $sth->execute;
#    print STDERR Data::Dumper->Dump([$sth->fetchall_arrayref,"XX"]);
    
#    is( $store->record_count, 2, "two records in store" );
    is( $store->entry_count, 3, "3 entries in index" );

    $store->stow( "X" x 8189, 2 );
#    is( $store->record_count, 2, "still two entries" );
    is( $store->entry_count, 3, "3 entries in index" );

    $store->stow( "X" x 16376, 2 ); #14
#    is( $store->record_count, 2, "still two entries" );
    is( $store->entry_count, 3, "3 entries in index" );

    is( $store->fetch(91), undef, "no record for too large a fetch" );

    my $sid = $store->stow( "S" x 16376 ); #14
 #   is( $store->record_count, 3, "now 3 records" );
    is( $store->entry_count, 4, "4th entry in index" );

    $store->stow( "tiny", 2 );
#    is( $store->record_count, 3, "3 records" );
    is( $store->entry_count, 4, "still 4th entry in index" );

    $store->stow( "q" x 12, 5 );
#    is( $store->record_count, 4, "now 4 records" );
    is( $store->entry_count, 5, "5th entry in index" );

    {
        local( *STDERR );
        my $errout;
        open( STDERR, ">>", \$errout );

        $store->delete_record( 54 );
        like ($errout, qr/delete past end of record/, 'delete past end of ' );
#    is( $store->record_count, 4, "now 4 records" );
        is( $store->entry_count, 5, "5th entry in index" );
    }

    $store = $rs_factory->new_rs;
    $store->stow( "FOO", 1 );
    is( $store->entry_count, 1, "ONE THING" );
    $store->stow( "BAR", 1 );
    is( $store->entry_count, 1, "still ONE THING" );
    
    my $id = $store->stow( "BAAAAAAAAGS" );
    $store->stow( "H", $id );
    is( $store->fetch( $id ), "H", "didn't pop out" );
    is( $store->entry_count, 2, "2 entries" );
#    is( $store->record_count, 2, "2 records" );
    
    $store->stow( "B" x 5000, $id );
    is( $store->entry_count, 2, "2 entries" );
#    is( $store->record_count, 2, "2 records" );

    $store->stow( "t", $id );
    is( $store->entry_count, 2, "2 entries" );
#    is( $store->record_count, 2, "2 records" );


    # test putting something big in 12, then shrinking it down and make sure it wasn't deleted
    $store = $rs_factory->new_rs;
    $id = $store->stow( "X" x 4000 );
    is( $store->fetch( $id ), 'X' x 4000, 'stored okey' );
    my $id2 = $store->stow( "X" x 3000, $id );
    is( $id2, $id, "id didn't change" );
    is( $store->fetch( $id2 ), 'X' x 3000, 'restored okey' );
    $store->stow( "X", $id );
    is( $store->fetch( $id ), 'X', 'tinystored stored okey' );

} #test_stow_and_fetch_and_delete

sub test_locks {
    my( $cls, $rs_factory ) = @_;
    
    my $store = $rs_factory->new_rs;
    $store->lock( "FOO", "BAR", "BAZ", "BAZ" );
    eval {
        $store->lock( "SOMETHING" );
        fail( "lock called twice in a row" );
    };
    like( $@, qr/cannot be called twice in a row/, 'Data::RecordStore->lock called twice in a row error message' );
    $store->unlock;
    $store->lock( "SOMETHING" );
    pass( "Store was able to lock after unlocking" );
}

sub test_recordstore {
    my( $cls, $rs_factory ) = @_;

    my $store = $rs_factory->new_rs;
    is( $store->entry_count, 0, 'no entries in new store' );

    my $id  = $store->stow( "FOO FOO" );

    my $id2 = $store->stow( "BAR BAR" );

    my $id3 = $store->stow( "Käse essen" );

    # store with 3 entries
    is( $store->entry_count, 3, "store 3 entries" );
    $store = $rs_factory->reopen( $store );
    is( $id2, $id + 1, "Incremental object ids" );
    is( $store->fetch( $id ), "FOO FOO", "first item saved" );
    is( $store->fetch( $id2 ), "BAR BAR", "second item saved" );
    is( $store->fetch( $id3 ), "Käse essen", "third item saved" );

    #
    # Try testing the moving of a record
    #
    $store = $rs_factory->new_rs;

    # 12 is 4096 - 5 = 4091, 13 is 8192 - 5 = 8187
    $id = $store->stow( "x" x 4087 ); #12
    $store->stow( "x" x 8187 ); # 13

    is( $store->entry_count, 2, "two entry count in store" );
#    is( $store->record_count, 2, "two record count in store" );

    my $yid = $store->stow( "y" ); #real small, should still be in 12 which is the minimum
    is( $yid, 3, "Third ID" );

    is( $store->entry_count, 3, "3 entry count in store" );
#    is( $store->record_count, 3, "3 record count in store" );

    $store->stow( "x" x 8188, $id );  # 12 is max 4092, 13 is max 8187

    is( $store->entry_count, 3, "still 3 entry count in store" );
#    is( $store->record_count, 3, "still 3 record count in store" );

    is( $store->fetch( $yid ), "y", "correctly relocated data" );

    # try for a much smaller relocation

    $store->stow( "x" x 90, $id );

    is( $store->entry_count, 3, "yet still 3 entry count in store" );
#    is( $store->record_count, 3, "yet still 3 record count in store" );

    my $xid = $store->stow( "x" x 90 );

    is( $store->entry_count, 4, "now 4 entry count in store" );
#    is( $store->record_count, 4, "now 4 record count in store" );

    $store->delete_record( $id );

    is( $store->entry_count, 4, "still 4 entry count in store after delete" );
#    is( $store->record_count, 3, "now 3 record count in store after delete" );

    $store = $rs_factory->new_rs;
    
    is( $store->entry_count, 0, "empty then no entries" );
#    is( $store->record_count, 0, "empty then no records" );

    $store->stow( "BOOGAH", 4 );
    is( $store->next_id, '5', "next id is 5" );
    is( $store->entry_count, 5, "5 entries after skipping ids plus asking to generate the next one" );
#    is( $store->record_count, 1, "one record at id 4" );

    is( $store->fetch( 4 ), "BOOGAH", "record hasnt changed" );

    $store->stow( "TEN", 10 );
    is( $store->entry_count, 10, "entry count explicitly set" );
#    is( $store->record_count, 2, "now 2 record count in store after delete after explicit set" );
    is( $store->fetch( 10 ), "TEN", "got the 10 stow" );
    is( $store->next_id, 11, 'after entry count being set' );
    is( $store->entry_count, 11, "entry count explicitly set" );
    is( $store->next_id, 12, 'next again' );
    is( $store->entry_count, 12, "entry count explicitly set" );


    $store->stow( "x" x 90 );
    is( $store->entry_count, 13, "now 13 entry count in store after stow" );
#    is( $store->record_count, 3, "now 3 record count in store after stow" );

    $xid = $store->stow( "x" x 90 );

    is( $store->entry_count, 14, "now 14 entry count in store after stow" );
#    is( $store->record_count, 4, "now 4 record count in store after stow" );


} #test suite

sub test_suite_objectstore {
    my( $cls, $rs_factory ) = @_;

    $cls->test_no_auto_clean( $rs_factory );
    $cls->test_autoload( $rs_factory );
    $cls->test_overload( $rs_factory );
    $cls->test_subclass( $rs_factory );
    $cls->test_vol( $rs_factory );
    $cls->test_lock( $rs_factory );
    $cls->test_objectstore( $rs_factory );
    $cls->test_circular( $rs_factory );
    $cls->test_loop( $rs_factory );
    $cls->test_arry( $rs_factory );
    $cls->test_hash( $rs_factory );
    $cls->test_connections( $rs_factory );
    $cls->test_fields( $rs_factory );
    $cls->test_classes( $rs_factory );
    $cls->test_purge( $rs_factory );
}


sub approx {
    my( $a, $b, $tol, $test ) = @_;
    ok( abs($a-$b) <= $tol, $test );
}




sub _cmpa {
    my( $title, @pairs ) = @_;
    while ( @pairs ) {
        my $actual = shift @pairs;
        my $expected = shift @pairs;
        if ( ref( $expected ) ) {
            is_deeply( $actual, $expected, $title );
            is( scalar( @$actual ), scalar( @$expected ), "$title size" );
            is( $#$actual, $#$expected, "$title index" );
        }
        else {
            is( $actual, $expected, $title );
        }
    }
} #_cmpa

sub _cmph {
    my( $title, @pairs ) = @_;
    while ( @pairs ) {
        my $actual = shift @pairs;
        my $expected = shift @pairs;
        if ( ref( $expected ) ) {
            is_deeply( [sort keys( %$actual )], [sort  keys( %$expected ) ], "$title keys" );
            is_deeply( [sort values( %$actual )], [sort  values( %$expected ) ], "$title values" );
            is( scalar( values( %$actual )), scalar(  values( %$expected ) ), "$title value counts" );
            is_deeply( $actual, $expected, $title );
        }
        else {
            is( $actual, $expected, $title );
        }
    }
} #_cmph


#012345678901234567890123456789
#ABCDEFGHIJKLMNOPQRSTUVWXYZ


use POSIX ":sys_wait_h";
use File::Temp qw/ :mktemp tempdir /;

sub test_locks_async {
    my( $cls, $rs_factory ) = @_;

    my $dir = tempdir( CLEANUP => 1 );
    my $forker = forker->new( $dir );

    #
    # A lot to test asyncronous stuff, but hey, need to
    #
    my $provider = $rs_factory->new_rs;
    $forker->init();
    my $A = fork;
    unless( $A ) {
        $provider = $rs_factory->reopen( $provider );
        $forker->expect( 'ready' );
        $provider->lock("A","B","C");
        $forker->put( 'start' );
        usleep(200_000);
        $forker->put( 'a-done' );
        $provider->unlock;
        exit;
    }
    
    my $B = fork;
    unless( $B ) {
        $provider = $rs_factory->reopen( $provider );
        $forker->spush( 'ready' );
        $forker->expect( 'start' );
        $provider->lock( "B" );
        $forker->put( 'b-done' );
        $provider->unlock;
        exit;
    }

    $forker->put( 'ready' );
    waitpid $A, 0;
    waitpid $B, 0;
        
    is_deeply( $forker->get(), [qw( ready start a-done b-done )] );
} #test_locks_async

sub test_transaction_async {
    my( $cls, $rs_factory ) = @_;
    
    my $dir = tempdir( CLEANUP => 1 );
    my $forker = forker->new( $dir );

    my $provider = $rs_factory->new_rs;
    $forker->init();
    
    my $A = fork;
    unless( $A ) {
        $provider = $rs_factory->reopen( $provider );

        $provider->index_silo->ensure_entry_count(100);
        
        $forker->expect( 'ready' );
        $provider->use_transaction;
        $forker->put( 'point-one' );
        
        $forker->expect( 'point-two' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.12795|1568050706.1351 0`29`1`32`r32', 87 );
        $forker->put( 'point-three' );

        $forker->expect( 'point-four' );
        $provider->stow( 'Yote::App::Session|1568050706.12746|1568050706.13562 app`r32`_session_id`v12360109430417719296`_last_updated`v1568050706.13507`login`u`root_cache`r87`cache`r86', 85 );
        $forker->put( 'point-five' );
        
        $forker->expect( 'point-six' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.12773|1568050706.13516 0`29`1`32`r32', 86 );
        $forker->put( 'point-seven' );

        $forker->expect( 'point-eight' );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.13949 db_version`v5.03`created_time`v1568050706.0199`last_update_time`v1568050706.13567`root`r2`ObjectStore_version`v2.10', 1 );
        $forker->put( 'point-nine' );

        $forker->expect( 'point-ten' );
        $provider->commit_transaction;
        $forker->put( 'a-done' );

        exit;
    }
    
    my $B = fork;
    unless( $B ) {
        $provider = $rs_factory->reopen( $provider );
        $forker->spush( 'ready' );
        
        $forker->expect( 'point-one' );
        my $id = $provider->next_id; #1
        $forker->put( 'point-two' );
        
        $forker->expect( 'point-three' );
        $provider->use_transaction;
        $forker->put( 'point-four' );

        $forker->expect( 'point-five' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.13645|1568050706.13646 0`29`0', 90 );
        $forker->put( 'point-six' );

        $forker->expect( 'point-seven' );
        $provider->stow( 'Yote::App::Session|1568050706.1355|1568050706.13662 app`r13`_session_id`v266713600675086336`login`u`root_cache`r90`cache`r89', 88 );
        $forker->put( 'point-eight' );
        
        $forker->expect( 'point-nine' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.13576|1568050706.13578 0`29`0', 89 );
        $forker->put( 'point-ten' );

        $forker->expect( 'a-done' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05329|1568050706.13668 0`29`1`266713600675086336`r88', 17 );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.14463 db_version`v5.03`created_time`v1568050706.0199`root`r2`last_update_time`v1568050706.13669`ObjectStore_version`v2.10', 1 );
        my $data = $provider->fetch( 89 );

        $provider->commit_transaction;
        my $last = $data eq 'Data::ObjectStore::Hash|1568050706.13576|1568050706.13578 0`29`0' ? 'b-done' : 'b-failed';
        
        $forker->put( $last );
        exit;
    }
    $provider->stow( '0', 1 );
    $provider->stow( 1, 2 );
    $forker->put( 'ready' );
    waitpid $A, 0;
    waitpid $B, 0;
    
    is_deeply( $forker->get(), [qw( ready 
                                    point-one 
                                    point-two
                                    point-three
                                    point-four
                                    point-five
                                    point-six
                                    point-seven
                                    point-eight
                                    point-nine
                                    point-ten
                                    a-done
                                    b-done
                              )] );
} #test_transaction_async


sub test_failed_async {
    my( $cls, $rs_factory ) = @_;

    my $dir = tempdir( CLEANUP => 1 );
    my $forker = forker->new( $dir );
    $forker->init();
    my $provider = $rs_factory->new_rs;
    
    my $A = fork;
    unless( $A ) {
        $provider = $rs_factory->reopen( $provider );
                $provider->index_silo->ensure_entry_count(300);
        $forker->expect( '1' );
        $provider->fetch( 1 );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->use_transaction(  );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.0204 db_version`v5.03`created_time`v1568050706.0199`root`r2`last_update_time`v1568050706.0199`ObjectStore_version`v2.10',1 );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.02031|1568050706.02035 ',2 );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.02291 db_version`v5.03`created_time`v1568050706.0199`root`r2`last_update_time`v1568050706.02041`ObjectStore_version`v2.10',1 );
        $provider->commit_transaction(  );
        $forker->put( '9' );
        $forker->expect( '12' );
        $provider->use_transaction(  );
        $forker->put( '13' );
        $forker->expect( '15' );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.02711 db_version`v5.03`created_time`v1568050706.0199`root`r2`last_update_time`v1568050706.02595`ObjectStore_version`v2.10',1 );
        $forker->put( '17' );
        $forker->expect( '18' );
        $provider->commit_transaction(  );
        $forker->put( '19' );
        $forker->expect( '20' );
        $provider->next_id(  );
        $forker->put( '21' );
        $forker->expect( '22' );
        $provider->next_id(  );
        $forker->put( '23' );
        $forker->expect( '25' );
        $provider->next_id(  );
        $provider->next_id(  );
        $forker->put( '27' );
        $forker->expect( '29' );
        $provider->next_id(  );
        $forker->put( '30' );
        $forker->expect( '31' );
        $provider->next_id(  );
        $forker->put( '32' );
        $forker->expect( '33' );
        $provider->next_id(  );
        $forker->put( '34' );
        $forker->expect( '35' );
        $provider->next_id(  );
        $forker->put( '36' );
        $forker->expect( '37' );
        $provider->next_id(  );
        $forker->put( '38' );
        $forker->expect( '39' );
        $provider->next_id(  );
        $forker->put( '40' );
        $forker->expect( '41' );
        $provider->next_id(  );
        $forker->put( '42' );
        $forker->expect( '43' );
        $provider->next_id(  );
        $forker->put( '44' );
        $forker->expect( '45' );
        $provider->next_id(  );
        $forker->put( '46' );
        $forker->expect( '47' );
        $provider->next_id(  );
        $forker->put( '48' );
        $forker->expect( '49' );
        $provider->next_id(  );
        $forker->put( '50' );
        $forker->expect( '51' );
        $provider->next_id(  );
        $forker->put( '52' );
        $forker->expect( '53' );
        $provider->next_id(  );
        $forker->put( '54' );
        $forker->expect( '55' );
        $provider->next_id(  );
        $forker->put( '56' );
        $forker->expect( '57' );
        $provider->next_id(  );
        $forker->put( '58' );
        $forker->expect( '59' );
        $provider->next_id(  );
        $forker->put( '60' );
        $forker->expect( '61' );
        $provider->next_id(  );
        $forker->put( '62' );
        $forker->expect( '63' );
        $provider->next_id(  );
        $forker->put( '64' );
        $forker->expect( '65' );
        $provider->next_id(  );
        $forker->put( '66' );
        $forker->expect( '67' );
        $provider->next_id(  );
        $forker->put( '68' );
        $forker->expect( '69' );
        $provider->next_id(  );
        $forker->put( '70' );
        $forker->expect( '71' );
        $provider->next_id(  );
        $forker->put( '72' );
        $forker->expect( '73' );
        $provider->next_id(  );
        $forker->put( '74' );
        $forker->expect( '75' );
        $provider->next_id(  );
        $forker->put( '76' );
        $forker->expect( '77' );
        $provider->next_id(  );
        $forker->put( '78' );
        $forker->expect( '79' );
        $provider->next_id(  );
        $forker->put( '80' );
        $forker->expect( '81' );
        $provider->next_id(  );
        $forker->put( '82' );
        $forker->expect( '83' );
        $provider->next_id(  );
        $forker->put( '84' );
        $forker->expect( '85' );
        $provider->next_id(  );
        $forker->put( '86' );
        $forker->expect( '87' );
        $provider->next_id(  );
        $forker->put( '88' );
        $forker->expect( '89' );
        $provider->next_id(  );
        $forker->put( '90' );
        $forker->expect( '91' );
        $provider->next_id(  );
        $forker->put( '92' );
        $forker->expect( '93' );
        $provider->next_id(  );
        $forker->put( '94' );
        $forker->expect( '95' );
        $provider->next_id(  );
        $forker->put( '96' );
        $forker->expect( '97' );
        $provider->next_id(  );
        $forker->put( '98' );
        $forker->expect( '99' );
        $provider->next_id(  );
        $provider->next_id(  );
        $forker->put( '101' );
        $forker->expect( '104' );
        $provider->use_transaction(  );
        $forker->put( '105' );
        $forker->expect( '106' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05933|1568050706.05984 0`29`1`Yote::App::PageCounter`r69',67 );
        $forker->put( '108' );
        $forker->expect( '109' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05528|1568050706.05529 0`29`0',33 );
        $forker->put( '110' );
        $forker->expect( '111' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05884|1568050706.06077 0`29`2`pageCounter2`r65`pageCounter`r73',63 );
        $forker->put( '112' );
        $forker->expect( '113' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05377|1568050706.05378 0`29`0',21 );
        $forker->put( '114' );
        $forker->expect( '115' );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.05979|1568050706.05983 0`1000000`3`0`vupdate_counter`vupdate`vfetch',71 );
        $forker->put( '116' );
        $forker->expect( '117' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05329|1568050706.05331 0`29`0',17 );
        $forker->put( '118' );
        $forker->expect( '119' );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.02031|1568050706.03178 yote`r4',2 );
        $forker->put( '120' );
        $forker->expect( '121' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05789|1568050706.0579 0`29`0',55 );
        $forker->put( '122' );
        $forker->expect( '123' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.06183|1568050706.06185 0`29`1`BASE_PATH`v/opt/yote/data_store',84 );
        $forker->put( '124' );
        $forker->expect( '125' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05427|1568050706.05429 0`29`0',25 );
        $forker->put( '126' );
        $forker->expect( '127' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05453|1568050706.0553 0`29`3`PUBLIC`r29`ADMIN-REQUIRED`r33`LOGIN-REQUIRED`r31',27 );
        $forker->put( '128' );
        $forker->expect( '129' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.06118|1568050706.06186 0`29`2`CLASS`vData::RecordStore`OPTIONS`r84',83 );
        $forker->put( '130' );
        $forker->expect( '131' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.06025|1568050706.06076 0`29`1`Yote::App::PageCounter`r77',75 );
        $forker->put( '132' );
        $forker->expect( '133' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05814|1568050706.06186 0`29`2`DOMAINS`r59`DATA-STORE`r83',57 );
        $forker->put( '134' );
        $forker->expect( '135' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05861|1568050706.06098 0`29`2`APPS`r63`OPTIONS`r81',61 );
        $forker->put( '136' );
        $forker->expect( '137' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05956|1568050706.05984 0`29`1`PUBLIC`r71',69 );
        $forker->put( '138' );
        $forker->expect( '139' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05838|1568050706.06098 0`29`1`localhost`r61',59 );
        $forker->put( '140' );
        $forker->expect( '141' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05718|1568050706.05791 0`29`3`PUBLIC`r51`ADMIN-REQUIRED`r55`LOGIN-REQUIRED`r53',49 );
        $forker->put( '142' );
        $forker->expect( '143' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.0522|1568050706.05795 0`29`2`pageCounter2`r13`pageCounter`r35',10 );
        $forker->put( '144' );
        $forker->expect( '145' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.055|1568050706.05501 0`29`0',31 );
        $forker->put( '146' );
        $forker->expect( '147' );
        $provider->stow( 'Yote::App::PageCounter|1568050706.05555|1568050706.05793 _session_pool`r41`_app_path`vpageCounter`_methods_access_levels`r37`_site`vlocalhost`_domain`r9`_session`r39`_login`r45`_resets`r43`_email`r47',35 );
        $forker->put( '148' );
        $forker->expect( '149' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05767|1568050706.05768 0`29`0',53 );
        $forker->put( '150' );
        $forker->expect( '151' );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.06072|1568050706.06075 0`1000000`3`0`vupdate_counter`vupdate`vfetch',79 );
        $forker->put( '152' );
        $forker->expect( '153' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.06049|1568050706.06075 0`29`1`PUBLIC`r79',77 );
        $forker->put( '154' );
        $forker->expect( '155' );
        $provider->stow( 'Yote::App::PageCounter|1568050706.0528|1568050706.05533 _session_pool`r19`_app_path`vpageCounter2`_methods_access_levels`r15`_site`vlocalhost`_domain`r9`_session`r17`_login`r23`_resets`r21`_email`r25',13 );
        $forker->put( '156' );
        $forker->expect( '157' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.054|1568050706.05401 0`29`0',23 );
        $forker->put( '158' );
        $forker->expect( '159' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05476|1568050706.05482 0`29`3`update_counter`v1`fetch`v1`update`v1',29 );
        $forker->put( '160' );
        $forker->expect( '161' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05908|1568050706.05985 0`29`2`MAIN-APP-CLASS`vYote::App::PageCounter`APP-METHODS`r67',65 );
        $forker->put( '162' );
        $forker->expect( '163' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.03171|1568050706.05233 0`29`1`localhost`r9',6 );
        $forker->put( '164' );
        $forker->expect( '165' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05601|1568050706.05603 0`29`0',39 );
        $forker->put( '166' );
        $forker->expect( '167' );
        $provider->stow( 'Yote::Domain|1568050706.05196|1568050706.05229 domain`vlocalhost`apps`r10',9 );
        $forker->put( '168' );
        $forker->expect( '169' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05742|1568050706.05747 0`29`3`update_counter`v1`fetch`v1`update`v1',51 );
        $forker->put( '170' );
        $forker->expect( '171' );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.05625|1568050706.05626 0`1000000`0`0',41 );
        $forker->put( '172' );
        $forker->expect( '173' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05305|1568050706.05455 0`29`1`Yote::App::PageCounter`r27',15 );
        $forker->put( '174' );
        $forker->expect( '175' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05695|1568050706.05696 0`29`0',47 );
        $forker->put( '176' );
        $forker->expect( '177' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.06095|1568050706.06097 0`29`1`ENDPOINT`vlocalhost/app-endpoint',81 );
        $forker->put( '178' );
        $forker->expect( '179' );
        $provider->stow( 'Yote|1568050706.03146|1568050706.06187 domains`r6`root_dir`v/opt/yote/`config`r57',4 );
        $forker->put( '180' );
        $forker->expect( '181' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.06002|1568050706.06077 0`29`2`MAIN-APP-CLASS`vYote::App::PageCounter`APP-METHODS`r75',73 );
        $forker->put( '182' );
        $forker->expect( '183' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05579|1568050706.05719 0`29`1`Yote::App::PageCounter`r49',37 );
        $forker->put( '184' );
        $forker->expect( '185' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05672|1568050706.05673 0`29`0',45 );
        $forker->put( '186' );
        $forker->expect( '187' );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.05353|1568050706.05355 0`1000000`0`0',19 );
        $forker->put( '188' );
        $forker->expect( '189' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05648|1568050706.0565 0`29`0',43 );
        $forker->put( '190' );
        $forker->expect( '191' );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.10889 db_version`v5.03`created_time`v1568050706.0199`root`r2`last_update_time`v1568050706.06189`ObjectStore_version`v2.10',1 );
        $forker->put( '192' );
        $forker->expect( '193' );
        $provider->commit_transaction(  );
        $forker->put( '194' );
        $forker->expect( '196' );
        $provider->lock( 'Yote::App::SESSION' );
        $forker->expect( '210' );
        $provider->next_id(  );
        $forker->put( '211' );
        $forker->expect( '212' );
        $provider->next_id(  );
        $forker->put( '213' );
        $forker->expect( '215' );
        $provider->next_id(  );
        $forker->put( '216' );
        $forker->expect( '218' );
        $provider->use_transaction(  );
        $forker->put( '219' );
        $forker->expect( '220' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.13645|1568050706.13646 0`29`0',90 );
        $forker->put( '222' );
        $forker->expect( '223' );
        $provider->stow( 'Yote::App::Session|1568050706.1355|1568050706.13662 app`r13`_session_id`v266713600675086336`login`u`root_cache`r90`cache`r89',88 );
        $forker->put( '224' );
        $forker->expect( '225' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.13576|1568050706.13578 0`29`0',89 );
        $forker->put( '226' );
        $forker->expect( '227' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05329|1568050706.13668 0`29`1`266713600675086336`r88',17 );
        $forker->put( '228' );
        $forker->expect( '229' );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.14463 db_version`v5.03`created_time`v1568050706.0199`root`r2`last_update_time`v1568050706.13669`ObjectStore_version`v2.10',1 );
        $provider->commit_transaction(  );
        $provider->unlock(  );
        $provider->fetch( 89 );
        $provider->unlock(  );
        $forker->put( '234' );
        exit;
    }
    my $B = fork;
    unless( $B ) {
        $provider = $rs_factory->reopen( $provider );
        $forker->spush( '1' );
        $forker->expect( '9' );
        $provider->fetch( 1 );
        $provider->fetch( 2 );
        $provider->use_transaction(  );
        $forker->put( '12' );
        $forker->expect( '13' );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.02661 db_version`v5.03`created_time`v1568050706.0199`last_update_time`v1568050706.02554`root`r2`ObjectStore_version`v2.10',1 );
        $forker->put( '15' );
        $forker->expect( '17' );
        $provider->commit_transaction(  );
        $forker->put( '18' );
        $forker->expect( '19' );
        $provider->next_id(  );
        $forker->put( '20' );
        $forker->expect( '21' );
        $provider->next_id(  );
        $forker->put( '22' );
        $forker->expect( '23' );
        $provider->next_id(  );
        $provider->next_id(  );
        $forker->put( '25' );
        $forker->expect( '27' );
        $provider->next_id(  );
        $provider->next_id(  );
        $forker->put( '29' );
        $forker->expect( '30' );
        $provider->next_id(  );
        $forker->put( '31' );
        $forker->expect( '32' );
        $provider->next_id(  );
        $forker->put( '33' );
        $forker->expect( '34' );
        $provider->next_id(  );
        $forker->put( '35' );
        $forker->expect( '36' );
        $provider->next_id(  );
        $forker->put( '37' );
        $forker->expect( '38' );
        $provider->next_id(  );
        $forker->put( '39' );
        $forker->expect( '40' );
        $provider->next_id(  );
        $forker->put( '41' );
        $forker->expect( '42' );
        $provider->next_id(  );
        $forker->put( '43' );
        $forker->expect( '44' );
        $provider->next_id(  );
        $forker->put( '45' );
        $forker->expect( '46' );
        $provider->next_id(  );
        $forker->put( '47' );
        $forker->expect( '48' );
        $provider->next_id(  );
        $forker->put( '49' );
        $forker->expect( '50' );
        $provider->next_id(  );
        $forker->put( '51' );
        $forker->expect( '52' );
        $provider->next_id(  );
        $forker->put( '53' );
        $forker->expect( '54' );
        $provider->next_id(  );
        $forker->put( '55' );
        $forker->expect( '56' );
        $provider->next_id(  );
        $forker->put( '57' );
        $forker->expect( '58' );
        $provider->next_id(  );
        $forker->put( '59' );
        $forker->expect( '60' );
        $provider->next_id(  );
        $forker->put( '61' );
        $forker->expect( '62' );
        $provider->next_id(  );
        $forker->put( '63' );
        $forker->expect( '64' );
        $provider->next_id(  );
        $forker->put( '65' );
        $forker->expect( '66' );
        $provider->next_id(  );
        $forker->put( '67' );
        $forker->expect( '68' );
        $provider->next_id(  );
        $forker->put( '69' );
        $forker->expect( '70' );
        $provider->next_id(  );
        $forker->put( '71' );
        $forker->expect( '72' );
        $provider->next_id(  );
        $forker->put( '73' );
        $forker->expect( '74' );
        $provider->next_id(  );
        $forker->put( '75' );
        $forker->expect( '76' );
        $provider->next_id(  );
        $forker->put( '77' );
        $forker->expect( '78' );
        $provider->next_id(  );
        $forker->put( '79' );
        $forker->expect( '80' );
        $provider->next_id(  );
        $forker->put( '81' );
        $forker->expect( '82' );
        $provider->next_id(  );
        $forker->put( '83' );
        $forker->expect( '84' );
        $provider->next_id(  );
        $forker->put( '85' );
        $forker->expect( '86' );
        $provider->next_id(  );
        $forker->put( '87' );
        $forker->expect( '88' );
        $provider->next_id(  );
        $forker->put( '89' );
        $forker->expect( '90' );
        $provider->next_id(  );
        $forker->put( '91' );
        $forker->expect( '92' );
        $provider->next_id(  );
        $forker->put( '93' );
        $forker->expect( '94' );
        $provider->next_id(  );
        $forker->put( '95' );
        $forker->expect( '96' );
        $provider->next_id(  );
        $forker->put( '97' );
        $forker->expect( '98' );
        $provider->next_id(  );
        $forker->put( '99' );
        $forker->expect( '101' );
        $provider->use_transaction(  );
        $provider->stow( 'Yote::App::PageCounter|1568050706.05515|1568050706.05759 _session_pool`r38`_app_path`vpageCounter`_methods_access_levels`r34`_site`vlocalhost`_domain`r7`_session`r36`_login`r42`_resets`r40`_email`r44',32 );
        $forker->put( '104' );
        $forker->expect( '105' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05967|1568050706.06041 0`29`2`MAIN-APP-CLASS`vYote::App::PageCounter`APP-METHODS`r72',70 );
        $forker->put( '106' );
        $forker->expect( '108' );
        $provider->stow( 'Yote::Domain|1568050706.05155|1568050706.05188 domain`vlocalhost`apps`r8',7 );
        $forker->put( '109' );
        $forker->expect( '110' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.06083|1568050706.06109 0`29`2`CLASS`vData::RecordStore`OPTIONS`r82',80 );
        $forker->put( '111' );
        $forker->expect( '112' );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.05944|1568050706.05948 0`1000000`3`0`vupdate_counter`vupdate`vfetch',68 );
        $forker->put( '113' );
        $forker->expect( '114' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.0544|1568050706.05445 0`29`3`update_counter`v1`fetch`v1`update`v1',26 );
        $forker->put( '115' );
        $forker->expect( '116' );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.02031|1568050706.03165 yote`r3',2 );
        $forker->put( '117' );
        $forker->expect( '118' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05341|1568050706.05342 0`29`0',18 );
        $forker->put( '119' );
        $forker->expect( '120' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.0599|1568050706.06041 0`29`1`Yote::App::PageCounter`r74',72 );
        $forker->put( '121' );
        $forker->expect( '122' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05488|1568050706.05489 0`29`0',30 );
        $forker->put( '123' );
        $forker->expect( '124' );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.05317|1568050706.05318 0`1000000`0`0',16 );
        $forker->put( '125' );
        $forker->expect( '126' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.0566|1568050706.05661 0`29`0',44 );
        $forker->put( '127' );
        $forker->expect( '128' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.06106|1568050706.06109 0`29`1`BASE_PATH`v/opt/yote/data_store',82 );
        $forker->put( '129' );
        $forker->expect( '130' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.06013|1568050706.0604 0`29`1`PUBLIC`r76',74 );
        $forker->put( '131' );
        $forker->expect( '132' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05464|1568050706.05466 0`29`0',28 );
        $forker->put( '133' );
        $forker->expect( '134' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05613|1568050706.05614 0`29`0',40 );
        $forker->put( '135' );
        $forker->expect( '136' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05292|1568050706.05294 0`29`0',14 );
        $forker->put( '137' );
        $forker->expect( '138' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05365|1568050706.05366 0`29`0',20 );
        $forker->put( '139' );
        $forker->expect( '140' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05414|1568050706.0549 0`29`3`PUBLIC`r26`ADMIN-REQUIRED`r30`LOGIN-REQUIRED`r28',24 );
        $forker->put( '141' );
        $forker->expect( '142' );
        $provider->stow( 'Yote::App::PageCounter|1568050706.05239|1568050706.05493 _session_pool`r16`_app_path`vpageCounter2`_methods_access_levels`r12`_site`vlocalhost`_domain`r7`_session`r14`_login`r20`_resets`r18`_email`r22',11 );
        $forker->put( '143' );
        $forker->expect( '144' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.0606|1568050706.06062 0`29`1`ENDPOINT`vlocalhost/app-endpoint',78 );
        $forker->put( '145' );
        $forker->expect( '146' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05706|1568050706.05711 0`29`3`update_counter`v1`fetch`v1`update`v1',48 );
        $forker->put( '147' );
        $forker->expect( '148' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05388|1568050706.05389 0`29`0',22 );
        $forker->put( '149' );
        $forker->expect( '150' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05637|1568050706.05638 0`29`0',42 );
        $forker->put( '151' );
        $forker->expect( '152' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05683|1568050706.05757 0`29`3`PUBLIC`r48`ADMIN-REQUIRED`r52`LOGIN-REQUIRED`r50',46 );
        $forker->put( '153' );
        $forker->expect( '154' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05731|1568050706.05732 0`29`0',50 );
        $forker->put( '155' );
        $forker->expect( '156' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05896|1568050706.05949 0`29`1`Yote::App::PageCounter`r66',64 );
        $forker->put( '157' );
        $forker->expect( '158' );
        $provider->stow( 'Yote|1568050706.03132|1568050706.06111 domains`r5`root_dir`v/opt/yote/`config`r54',3 );
        $forker->put( '159' );
        $forker->expect( '160' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05567|1568050706.05569 0`29`0',36 );
        $forker->put( '161' );
        $forker->expect( '162' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05264|1568050706.05417 0`29`1`Yote::App::PageCounter`r24',12 );
        $forker->put( '163' );
        $forker->expect( '164' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05826|1568050706.06063 0`29`2`APPS`r60`OPTIONS`r78',58 );
        $forker->put( '165' );
        $forker->expect( '166' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05179|1568050706.05761 0`29`2`pageCounter2`r11`pageCounter`r32',8 );
        $forker->put( '167' );
        $forker->expect( '168' );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.0559|1568050706.05591 0`1000000`0`0',38 );
        $forker->put( '169' );
        $forker->expect( '170' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05755|1568050706.05756 0`29`0',52 );
        $forker->put( '171' );
        $forker->expect( '172' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05849|1568050706.06042 0`29`2`pageCounter2`r62`pageCounter`r70',60 );
        $forker->put( '173' );
        $forker->expect( '174' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05539|1568050706.05685 0`29`1`Yote::App::PageCounter`r46',34 );
        $forker->put( '175' );
        $forker->expect( '176' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05801|1568050706.06063 0`29`1`localhost`r58',56 );
        $forker->put( '177' );
        $forker->expect( '178' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.0592|1568050706.05949 0`29`1`PUBLIC`r68',66 );
        $forker->put( '179' );
        $forker->expect( '180' );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.06037|1568050706.0604 0`1000000`3`0`vupdate_counter`vupdate`vfetch',76 );
        $forker->put( '181' );
        $forker->expect( '182' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05872|1568050706.0595 0`29`2`MAIN-APP-CLASS`vYote::App::PageCounter`APP-METHODS`r64',62 );
        $forker->put( '183' );
        $forker->expect( '184' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.03158|1568050706.05192 0`29`1`localhost`r7',5 );
        $forker->put( '185' );
        $forker->expect( '186' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05778|1568050706.0611 0`29`2`DOMAINS`r56`DATA-STORE`r80',54 );
        $forker->put( '187' );
        $forker->expect( '188' );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.10732 db_version`v5.03`created_time`v1568050706.0199`last_update_time`v1568050706.06113`root`r2`ObjectStore_version`v2.10',1 );
        $forker->put( '189' );
        $forker->expect( '190' );
        $provider->commit_transaction(  );
        $forker->put( '191' );
        $forker->expect( '192' );
        $provider->lock( 'Yote::App::SESSION' );
        $forker->put( '193' );
        $forker->expect( '194' );
        $provider->next_id(  );
        $provider->next_id(  );
        $forker->put( '196' );
        $provider->next_id(  );
        $provider->use_transaction(  );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.12795|1568050706.12796 0`29`0',87 );
        $provider->stow( 'Yote::App::Session|1568050706.12746|1568050706.12814 app`r32`_session_id`v12360109430417719296`login`u`root_cache`r87`cache`r86',85 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05567|1568050706.12819 0`29`1`12360109430417719296`r85',36 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.12773|1568050706.12775 0`29`0',86 );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.13138 db_version`v5.03`created_time`v1568050706.0199`last_update_time`v1568050706.12821`root`r2`ObjectStore_version`v2.10',1 );
        $provider->commit_transaction(  );
        $provider->unlock(  );
        $provider->fetch( 86 );
        $provider->fetch( 87 );
        $provider->fetch( 34 );
        $forker->put( '210' );
        $forker->expect( '211' );
        $provider->fetch( 46 );
        $forker->put( '212' );
        $forker->expect( '213' );
        $provider->unlock(  );
        $forker->put( '215' );
        $forker->expect( '216' );
        $provider->use_transaction(  );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.12795|1568050706.1351 0`29`1`32`r32',87 );
        $forker->put( '218' );
        $forker->expect( '219' );
        $provider->stow( 'Yote::App::Session|1568050706.12746|1568050706.13562 app`r32`_session_id`v12360109430417719296`_last_updated`v1568050706.13507`login`u`root_cache`r87`cache`r86',85 );
        $forker->put( '220' );
        $forker->expect( '222' );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.12773|1568050706.13516 0`29`1`32`r32',86 );
        $forker->put( '223' );
        $forker->expect( '224' );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.13949 db_version`v5.03`created_time`v1568050706.0199`last_update_time`v1568050706.13567`root`r2`ObjectStore_version`v2.10',1 );
        $forker->put( '225' );
        $forker->expect( '226' );
        $provider->commit_transaction(  );
        $forker->put( '227' );
        $forker->expect( '228' );
        $provider->unlock(  );
        $forker->put( '229' );
        exit;
    }
    my $C = fork;
    unless( $C ) {
        $provider = $rs_factory->reopen( $provider );
        $forker->spush( '1' );
        $forker->spush( '9' );
        $forker->spush( '12' );
        $forker->spush( '13' );
        $forker->spush( '15' );
        $forker->spush( '17' );
        $forker->spush( '18' );
        $forker->spush( '19' );
        $forker->spush( '20' );
        $forker->spush( '21' );
        $forker->spush( '22' );
        $forker->spush( '23' );
        $forker->spush( '25' );
        $forker->spush( '27' );
        $forker->spush( '29' );
        $forker->spush( '30' );
        $forker->spush( '31' );
        $forker->spush( '32' );
        $forker->spush( '33' );
        $forker->spush( '34' );
        $forker->spush( '35' );
        $forker->spush( '36' );
        $forker->spush( '37' );
        $forker->spush( '38' );
        $forker->spush( '39' );
        $forker->spush( '40' );
        $forker->spush( '41' );
        $forker->spush( '42' );
        $forker->spush( '43' );
        $forker->spush( '44' );
        $forker->spush( '45' );
        $forker->spush( '46' );
        $forker->spush( '47' );
        $forker->spush( '48' );
        $forker->spush( '49' );
        $forker->spush( '50' );
        $forker->spush( '51' );
        $forker->spush( '52' );
        $forker->spush( '53' );
        $forker->spush( '54' );
        $forker->spush( '55' );
        $forker->spush( '56' );
        $forker->spush( '57' );
        $forker->spush( '58' );
        $forker->spush( '59' );
        $forker->spush( '60' );
        $forker->spush( '61' );
        $forker->spush( '62' );
        $forker->spush( '63' );
        $forker->spush( '64' );
        $forker->spush( '65' );
        $forker->spush( '66' );
        $forker->spush( '67' );
        $forker->spush( '68' );
        $forker->spush( '69' );
        $forker->spush( '70' );
        $forker->spush( '71' );
        $forker->spush( '72' );
        $forker->spush( '73' );
        $forker->spush( '74' );
        $forker->spush( '75' );
        $forker->spush( '76' );
        $forker->spush( '77' );
        $forker->spush( '78' );
        $forker->spush( '79' );
        $forker->spush( '80' );
        $forker->spush( '81' );
        $forker->spush( '82' );
        $forker->spush( '83' );
        $forker->spush( '84' );
        $forker->spush( '85' );
        $forker->spush( '86' );
        $forker->spush( '87' );
        $forker->spush( '88' );
        $forker->spush( '89' );
        $forker->spush( '90' );
        $forker->spush( '91' );
        $forker->spush( '92' );
        $forker->spush( '93' );
        $forker->spush( '94' );
        $forker->spush( '95' );
        $forker->spush( '96' );
        $forker->spush( '97' );
        $forker->spush( '98' );
        $forker->spush( '99' );
        $forker->spush( '101' );
        $forker->spush( '104' );
        $forker->spush( '105' );
        $forker->spush( '106' );
        $forker->spush( '108' );
        $forker->spush( '109' );
        $forker->spush( '110' );
        $forker->spush( '111' );
        $forker->spush( '112' );
        $forker->spush( '113' );
        $forker->spush( '114' );
        $forker->spush( '115' );
        $forker->spush( '116' );
        $forker->spush( '117' );
        $forker->spush( '118' );
        $forker->spush( '119' );
        $forker->spush( '120' );
        $forker->spush( '121' );
        $forker->spush( '122' );
        $forker->spush( '123' );
        $forker->spush( '124' );
        $forker->spush( '125' );
        $forker->spush( '126' );
        $forker->spush( '127' );
        $forker->spush( '128' );
        $forker->spush( '129' );
        $forker->spush( '130' );
        $forker->spush( '131' );
        $forker->spush( '132' );
        $forker->spush( '133' );
        $forker->spush( '134' );
        $forker->spush( '135' );
        $forker->spush( '136' );
        $forker->spush( '137' );
        $forker->spush( '138' );
        $forker->spush( '139' );
        $forker->spush( '140' );
        $forker->spush( '141' );
        $forker->spush( '142' );
        $forker->spush( '143' );
        $forker->spush( '144' );
        $forker->spush( '145' );
        $forker->spush( '146' );
        $forker->spush( '147' );
        $forker->spush( '148' );
        $forker->spush( '149' );
        $forker->spush( '150' );
        $forker->spush( '151' );
        $forker->spush( '152' );
        $forker->spush( '153' );
        $forker->spush( '154' );
        $forker->spush( '155' );
        $forker->spush( '156' );
        $forker->spush( '157' );
        $forker->spush( '158' );
        $forker->spush( '159' );
        $forker->spush( '160' );
        $forker->spush( '161' );
        $forker->spush( '162' );
        $forker->spush( '163' );
        $forker->spush( '164' );
        $forker->spush( '165' );
        $forker->spush( '166' );
        $forker->spush( '167' );
        $forker->spush( '168' );
        $forker->spush( '169' );
        $forker->spush( '170' );
        $forker->spush( '171' );
        $forker->spush( '172' );
        $forker->spush( '173' );
        $forker->spush( '174' );
        $forker->spush( '175' );
        $forker->spush( '176' );
        $forker->spush( '177' );
        $forker->spush( '178' );
        $forker->spush( '179' );
        $forker->spush( '180' );
        $forker->spush( '181' );
        $forker->spush( '182' );
        $forker->spush( '183' );
        $forker->spush( '184' );
        $forker->spush( '185' );
        $forker->spush( '186' );
        $forker->spush( '187' );
        $forker->spush( '188' );
        $forker->spush( '189' );
        $forker->spush( '190' );
        $forker->spush( '191' );
        $forker->spush( '192' );
        $forker->spush( '193' );
        $forker->spush( '194' );
        $forker->spush( '196' );
        $forker->spush( '210' );
        $forker->spush( '211' );
        $forker->spush( '212' );
        $forker->spush( '213' );
        $forker->spush( '215' );
        $forker->spush( '216' );
        $forker->spush( '218' );
        $forker->spush( '219' );
        $forker->spush( '220' );
        $forker->spush( '222' );
        $forker->spush( '223' );
        $forker->spush( '224' );
        $forker->spush( '225' );
        $forker->spush( '226' );
        $forker->spush( '227' );
        $forker->spush( '228' );
        $forker->spush( '229' );
        $forker->expect( '234' );
        $provider->fetch( 1 );
        $provider->fetch( 2 );
        $provider->use_transaction(  );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.23006 db_version`v5.03`created_time`v1568050706.0199`last_update_time`v1568050706.22926`root`r2`ObjectStore_version`v2.10',1 );
        $provider->commit_transaction(  );
        $provider->fetch( 4 );
        $provider->fetch( 57 );
        $provider->fetch( 59 );
        $provider->fetch( 61 );
        $provider->fetch( 6 );
        $provider->fetch( 9 );
        $provider->fetch( 10 );
        $provider->fetch( 13 );
        $provider->fetch( 35 );
        $provider->fetch( 15 );
        $provider->fetch( 27 );
        $provider->fetch( 29 );
        $provider->fetch( 31 );
        $provider->fetch( 37 );
        $provider->fetch( 49 );
        $provider->fetch( 51 );
        $provider->fetch( 53 );
        $provider->fetch( 55 );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->use_transaction(  );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.26178|1568050706.26206 0`29`2`CLASS`vData::RecordStore`OPTIONS`r105',104 );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.26126|1568050706.26129 0`1000000`3`0`vupdate_counter`vupdate`vfetch',102 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.25904|1568050706.26207 0`29`2`DOMAINS`r92`DATA-STORE`r104',91 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.2607|1568050706.26131 0`29`2`MAIN-APP-CLASS`vYote::App::PageCounter`APP-METHODS`r100',99 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.25945|1568050706.26156 0`29`2`APPS`r94`OPTIONS`r103',93 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.26201|1568050706.26205 0`29`1`BASE_PATH`v/opt/yote/data_store',105 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.2609|1568050706.26131 0`29`1`Yote::App::PageCounter`r101',100 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05476|1568050706.25745 0`29`3`update_counter`v1`fetch`v1`update`v1',29 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.26006|1568050706.26052 0`29`1`Yote::App::PageCounter`r97',96 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.25986|1568050706.26053 0`29`2`MAIN-APP-CLASS`vYote::App::PageCounter`APP-METHODS`r96',95 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.25964|1568050706.26132 0`29`2`pageCounter2`r95`pageCounter`r99',94 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.26025|1568050706.26051 0`29`1`PUBLIC`r98',97 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05742|1568050706.25844 0`29`3`update_counter`v1`fetch`v1`update`v1',51 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.25923|1568050706.26156 0`29`1`localhost`r93',92 );
        $provider->stow( 'Yote|1568050706.03146|1568050706.2621 domains`r6`root_dir`v/opt/yote/`config`r91',4 );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.26045|1568050706.2605 0`1000000`3`0`vupdate_counter`vupdate`vfetch',98 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.26153|1568050706.26155 0`29`1`ENDPOINT`vlocalhost/app-endpoint',103 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.26108|1568050706.2613 0`29`1`PUBLIC`r102',101 );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.27449 db_version`v5.03`created_time`v1568050706.0199`last_update_time`v1568050706.26213`root`r2`ObjectStore_version`v2.10',1 );
        $provider->commit_transaction(  );
        $provider->fetch( 39 );
        $provider->lock( 'Yote::App::SESSION' );
        $provider->fetch( 41 );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->next_id(  );
        $provider->use_transaction(  );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.05601|1568050706.28431 0`29`1`805610603367432192`r106',39 );
        $provider->stow( 'Yote::App::Session|1568050706.28342|1568050706.28423 app`r35`_session_id`v805610603367432192`login`u`root_cache`r108`cache`r107',106 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.28403|1568050706.28404 0`29`0',108 );
        $provider->stow( 'Data::ObjectStore::Hash|1568050706.28378|1568050706.2838 0`29`0',107 );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.28751 db_version`v5.03`created_time`v1568050706.0199`last_update_time`v1568050706.28432`root`r2`ObjectStore_version`v2.10',1 );
        $provider->commit_transaction(  );
        $provider->unlock(  );
        $provider->lock( 'PAGECOUNTER' );
        $provider->fetch( 108 );
        $provider->fetch( 107 );
        $provider->unlock(  );
        $provider->lock( 'Yote::App-pageCounter-NOTES' );
        $provider->next_id(  );
        $provider->use_transaction(  );
        $provider->stow( 'Data::ObjectStore::Array|1568050706.29195|1568050706.29196 0`1000000`0`0',109 );
        $provider->stow( 'Yote::App::PageCounter|1568050706.05555|1568050706.29198 _session_pool`r41`_methods_access_levels`r37`_app_path`vpageCounter`_site`vlocalhost`_session`r39`_domain`r9`_secret_count`v11`hits`v1`_login`r45`_resets`r43`_logs`r109`_email`r47',35 );
        $provider->stow( 'Yote::App::Session|1568050706.28342|1568050706.29163 app`r35`_session_id`v805610603367432192`_last_updated`v1568050706.29159`login`u`root_cache`r108`cache`r107',106 );
        $provider->stow( 'Data::ObjectStore::Container|1568050706.0199|1568050706.29487 db_version`v5.03`created_time`v1568050706.0199`last_update_time`v1568050706.292`root`r2`ObjectStore_version`v2.10',1 );
        $provider->commit_transaction(  );
        $provider->unlock(  );
        exit;
    }
    $forker->put( '1' );
    waitpid $A, 0;
    waitpid $B, 0;
    waitpid $C, 0;
    
} #test_async

1;
