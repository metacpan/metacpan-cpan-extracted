package api;

use strict;
use warnings;

use Fcntl qw( :flock );
use Data::Dumper;
use Test::More;
use Time::HiRes qw(usleep);

use lib 't/lib';
use forker;
use OtherThing;
use test::TestThing;

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

# -----------------------------------------------------
#               ObjectStore
# -----------------------------------------------------

use Data::ObjectStore;

use constant {
    DATA_PROVIDER => 0,
    DIRTY         => 1,
    WEAK          => 2,
    PATH          => 3,
    OPTIONS       => 4,
    STOREINFO     => 5,
    
    ID            => 0,
    DATA          => 1,
    DSTORE        => 2,
    METADATA      => 3,
    LEVEL         => 4,
};

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

sub test_overload {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    my( $x, $z );
    {
        my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
        $x = $store->create_container;
        $z = $store->create_container;
        my $r = $store->load_root_container;
        $r->set_x( $x );
        $r->set_z( $z );
        $store->save;
    }

    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    my $r = $store->load_root_container;
    my $y = $r->get_x;
    ok( $y == $x, ' overload == true ' );
    ok( $y != $z, ' overload != true ' );
    ok( $y eq $x, ' overload eq true ' );
    ok( $y ne $z, ' overload ne true ' );

    ok( !( $y == $z ), ' overload == false' );
    ok( !( $y != $x ), ' overload != false' );
    ok( !( $y eq $z ), ' overload eq false' );
    ok( !( $y ne $x ), ' overload ne false' );

    ok( !( $y == 3 ), ' overload == false scalar' );
    ok( $y != 3, ' overload != false scalar' );
    ok( !( $y eq 3 ), ' overload eq false scalar' );
    ok( $y ne 3, ' overload ne false scalar' );


} #test_overload

sub test_autoload {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    my $root = $store->load_root_container;
    my $thing = $store->create_container( 'test::TestThing' );
    eval {
        $thing->zap;
        fail( "Thing zapped" );
    };
    like( $@, qr/unknown function/, 'thing didnt zap' );


    $thing->add_to_list( "A" );
    is_deeply( $thing->get_list, [ "A" ], "added to list" );

    $thing->add_once_to_list( "A" );
    is_deeply( $thing->get_list, [ "A" ], "added once to list" );

    $thing->add_once_to_list( qw( A A A ) );
    is_deeply( $thing->get_list, [ "A" ], "added once to list" );

    $thing->add_to_list( qw( A A A B ) );
    is_deeply( $thing->get_list, [ qw( A A A A B ) ], "added more to list" );

    $thing->add_once_to_list( qw( A A C D A ) );
    is_deeply( $thing->get_list, [ qw(A A A A B C D) ], "added even more to list" );

    $thing->remove_from_list(qw(B A D) );
    is_deeply( $thing->get_list, [ qw( A A A C ) ], "removed from list" );

    $thing->add_to_list( qw( A A D B C ) );
    is_deeply( $thing->get_list, [ qw(A A A C A A D B C) ], "added more to list" );

    $thing->remove_all_from_list(qw(B A D) );
    is_deeply( $thing->get_list, [ qw(C C) ], "removed all from list" );

    $thing->get_FOO( "OO" );
    is( $thing->get_FOO, "OO", "get with default" );
    $thing->get_FOO( "UU" );
    is( $thing->get_FOO, "OO", "get with default but its set already" );
    $thing->set_FOO( undef );
    $thing->get_FOO( "UU" );
    is( $thing->get_FOO, "UU", "get with default but its set already but with undef" );

} #test_autoload

sub test_subclass {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    {
        my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
        my $root = $store->load_root_container;
        $root->set_thing( $store->create_container( 'test::TestThing' ) );
        $root->set_thing2( $store->create_container( 'test::TestThing', { message => "for you sir" } ) );
      $root->set_container( $store->create_container( { message => "not so hot" } ) );
      $store->save;
  }
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    is( $store->load_root_container->get_thing->foo, 'BAR', 'test thing loaded okey' );
    is( $store->load_root_container->get_thing2->get_message, 'for you sir', 'test thing data loaded okey' );
    is( $store->load_root_container->get_container->get_message, 'not so hot', 'normal data loaded okey' );


} #test_subclass

sub test_vol {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    {
        my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
        my $root = $store->load_root_container;
        $root->vol( "TEST", "VALUE" );
        $root->vol( "TEST2", "VALUE2" );
        is( $store->load_root_container->vol( "TEST" ), "VALUE", "VOL lived in store" );
        is( $store->load_root_container->vol( "TEST2" ), "VALUE2", "VOL lived in store" );
        $root->clearvol( "TEST2" );
        ok( ! $store->load_root_container->vol( "TEST2" ), "VOL cleared from store" );

        $root->vol( "TEST", "VALUE" );
        $root->vol( "TEST2", "VALUE2" );
        is_deeply( [sort @{$root->vol_fields}], [qw( TEST TEST2)], "correct vol fields" );
        $root->clearvols( "TEST2" );
        is_deeply( [sort @{$root->vol_fields}], [qw( TEST)], "correct vol fields after clearing one" );
        $root->clearvols;
        is_deeply( $root->vol_fields, [], "cleared vol fields" );
        ok( ! $store->load_root_container->vol( "TEST2" ), "VOL cleared from store" );
        ok( ! $store->load_root_container->vol( "TEST" ), "VOL cleared from store" );

        $root->vol( "TEST", "VALUE" );
        $root->vol( "TEST2", "VALUE2" );
        $store->load_root_container->store->save;

    }
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    ok( ! $store->load_root_container->vol( "TEST" ), "VOL is gone as store reloads" );
} #test_vol

sub test_lock {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    # ohhh, this is going to have to be forked, isn't it?
    {
        my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
        my $root = $store->load_root_container;
        $root->lock('nurf','nurf');
        $root->unlock;
    }
} #test_lock

sub test_objectstore {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;

    eval {
        my $store = Data::ObjectStore->open_store;
        fail( "Was able to open the store without arguments" );
    };
    like( $@, qr/requires at least one argument/, 'correct error for no arguments open' );

    # try opening store with a record store as an argument
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    my $root_node = $store->load_root_container;
    $root_node->set_foo( "BARZY" );
    $store->save;

    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $root_node = $store->load_root_container;
    is( $root_node->get_foo, "BARZY", "same datastore run with different objectstore" );

    $provider = $rs_factory->new_rs;
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $root_node = $store->load_root_container;

    is( $store->get_db_version, $Data::RecordStore::VERSION, "store version" );
    ok( (time - $store->get_created_time) < 3, "just created" );
    ok( ($store->get_last_update_time-$store->get_created_time) < 3, "Just created" );

    ok( ! $store->_has_dirty, "no dirty yet" );

    #
    # general check of item integrity
    #
    $root_node->add_to_myList( { objy =>
                                     $store->create_container( {
                                         someval => 124.42,
                                         somename => 'Käse',
                                         someobj => $store->create_container( {
                                             boringval => "YAWN",
                                             binnerval => "`SPANXZ",
                                             linnerval => "SP`A`NXZ",
                                             'zinn`erval' => "PANXZ`",
                                             innerval => "This is an \\ inner `val\\`\n with Käse \\\ essen ",
                                         } ),
                                     } ),
                                 'some`part' => 'other`part',
                             } );
    $root_node->add_to_myList( 'we three ` foo foo', 'DOOPY' );

    is( $store->_has_dirty, 5, "now has 5 dirty" );

    $store->save( $root_node->get_myList );

    is( $store->_has_dirty, 4, "now has 4 dirty after specific save" );

    #
    # make sure utf 8 is active and working
    #
    is( $root_node->get_myList->[0]{objy}->get_somename, 'Käse', "utf 8 character defore stow" );

    $store->save;

    ok( ! $store->_has_dirty, "no dirty after save" );

    is( $root_node->get_myList->[0]{objy}->get_somename, 'Käse', "utf 8 character after stow before load" );

    #
    # Make sure 6 items got saved...(infoNode), (rootNode), (myList), (hash in mylist), (obj in hash) and (obj in obj)
    #
    is( $store->[DATA_PROVIDER]->entry_count, 6, "correct entry count" );
#    is( $store->[DATA_PROVIDER]->record_count, 6, "correct entry count silo method" );

    #
    # Check to make sure opening the store again will have all the same values.
    #
    my $dup_store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    my $dup_root = $dup_store->load_root_container;

    is( $dup_root->[Data::ObjectStore::Container::ID], $root_node->[Data::ObjectStore::Container::ID] );
    is_deeply( $dup_root->[Data::ObjectStore::Container::DATA], $root_node->[Data::ObjectStore::Container::DATA] );

    my $hash = $dup_root->get_myList->[0];
    my $oy = $hash->{objy};
    is( $oy->get_somename, 'Käse', "utf 8 character saved in object" );

    is( $oy->get_someval, '124.42', "number saved in object" );

    is( $dup_root->get_myList->[1], 'we three ` foo foo', "list has broken up stuff" );
    is( $dup_root->get_myList->[2], 'DOOPY', "add_to_ takes a lits of things to add" );

    ok( exists $hash->{'some`part'}, "has key with ` character");
    is( $hash->{'some`part'}, 'other`part', "hash key and value both with ` characters" );

    #
    # test ` seperator esccapint working
    #
    is( $oy->get_someobj->get_innerval, "This is an \\ inner `val\\`\n with Käse \\\ essen " );
    is( $oy->get_someobj->get_binnerval, "`SPANXZ" );
    is( $oy->get_someobj->get_boringval, "YAWN" );
    is( $oy->get_someobj->get_linnerval, "SP`A`NXZ" );
    is( $oy->get_someobj->get( 'zinn`erval'), "PANXZ`" );

    # filesize of $dir/1_OBJSTORE should be 360

    # purge test. This should eliminate the following :
    # the old myList, the hash first element of myList, the objy in the hash, the someobj of objy, so 4 items

    my $list_to_remove = $root_node->get_myList();

    my $list_thingy = $store->_knot( $list_to_remove );

    push @$list_to_remove, $list_to_remove, $list_to_remove, $list_to_remove;

    $list_to_remove->[9] = "NINE";

    $store->save;

    $list_to_remove = $root_node->get_myList();

    is( $list_to_remove->[9], 'NINE' );

    my $hash_in_list = $list_to_remove->[0];

    my $list_to_remove_id = $store->_get_id( $list_to_remove );
    my $hash_in_list_id   = $store->_get_id( $hash_in_list );

    my $objy              = $hash_in_list->{objy};

    my $objy_id           = $store->_get_id( $objy );
    my $someobj           = $objy->get_someobj;
    my $someobj_id        = $store->_get_id( $someobj );

    # testing circular reference here. It's connection may have advanced to 2
    $someobj->set_mylistref( $list_to_remove );

    is( $store->[DATA_PROVIDER]->entry_count, 6, "seven entries reset list" );

    $root_node->set_myList( [] );

    is( $store->[DATA_PROVIDER]->entry_count, 7, "seven entries before save" );

    # the seventh entry was written to the record store index, but not yet
    # saved to a silo until save
#    is( $store->[DATA_PROVIDER]->record_count, 6, "correct entry count silo method" );

    $store->save;
    $store->quick_purge;

    is( $store->[DATA_PROVIDER]->entry_count, 7, "correct entry count after nuking the list" );
#    is( $store->[DATA_PROVIDER]->record_count, 3, "correct entry count silo method" );

    undef $list_to_remove;
    undef $hash_in_list;
    undef $objy;
    undef $someobj;

    ok( ! $store->fetch( $list_to_remove_id ), "removed list still removed" );
    ok( ! $store->fetch( $hash_in_list_id ), "removed hash id still removed" );
    ok( ! $store->fetch( $objy_id ), "removed objy still removed" );
    ok( ! $store->fetch( $someobj_id ), "removed someobj still removed" );

    undef $dup_root;

    undef $root_node;

    $Data::ObjectStore::Hash::BUCKET_SIZE = 7;

    my $thash = $store->load_root_container->set_test_hash({});
    # test for hashes large enough that subhashes are inside

    my( %confirm_hash );
    my( @alpha ) = ("A".."G");
    my $val = 1;
    for my $letter (@alpha) {
        $thash->{$letter} = $val;
        $confirm_hash{$letter} = $val;
        $val++;
    }

    $val = 1;
    for my $letter (@alpha) {
        is( $thash->{$letter}, $val++, "Hash value works" );
    }
    $thash->{A} = 100;
    is( $thash->{A}, 100, "overriding hash value works" );
    delete $thash->{A};
    delete $confirm_hash{A};
    ok( ! exists($thash->{A}), "deleting hash value works" );
    $thash->{G} = "GG";
    $confirm_hash{G} = "GG";

    is_deeply( [sort keys %$thash], ["B".."G"], "hash keys works for the simpler hashes" );
    $root_node = $store->load_root_container;

    # now stuff enough there so that the hashes must overflow
    ( @alpha ) = ("AA".."ZZ");
    for my $letter (@alpha) {
        if ( $letter eq 'AE' ) {
            eval {
                $thash->{$letter} = $root_node;
                fail( "was able to put root node into hash" );
            };
            like( $@, qr/cannot store a root node in a hash/, 'correct error' );
            my $c = $store->create_container;
            $thash->{$letter} = $c;
            is( $thash->{$letter}, $c, 'could store normal container' );
        }
        $thash->{$letter} = $val;
        $confirm_hash{$letter} = $val;
        $val++;
    }
    $store->save;
    undef $store;

    my $sup_store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $thash = $sup_store->load_root_container->get_test_hash;

    is_deeply( [sort keys %$thash], [sort ("B".."G","AA".."ZZ")], "hash keys works for the heftier hashes" );

    is_deeply( $thash, \%confirm_hash, "hash checks out keys and values" );

    # array tests
    # listy test because
    $Data::ObjectStore::Array::MAX_BLOCKS  = 4;

    $store = $sup_store;
    $root_node = $store->load_root_container;
    my $l = $root_node->get_listy( [] );

    push @$l, "ONE", "TWO";
    is_deeply( $l, ["ONE", "TWO"], "first push" );
    is( @$l, 2, "Size two" );
    is( $#$l, 1, "last index 1" );

    push @$l, "THREE", "FOUR", "FIVE";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE"], "push 1" );
    is( @$l, 5, "Size five" );
    is( $#$l, 4, "last index 1" );

    push @$l, "SIX", "SEVEN", "EIGHT", "NINE";

    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"], "push 2" );
    is( @$l, 9, "Size nine" );

    push @$l, "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN"], "push 3" );
    is( @$l, 16, "Size sixteen" );

    push @$l, "SEVENTEEN", "EIGHTTEEN";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN"], "push 4" );
    is( @$l, 18, "Size eighteen" );
    is_deeply( ["SIXTEEN","SEVENTEEN","EIGHTTEEN",undef],[@$l[15..18]], "nice is slice" );

    push @$l, "NINETEEN";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN"], "push 5" );
    is( @$l, 19, "Size nineteen" );
    is_deeply( ["SIXTEEN","SEVENTEEN","EIGHTTEEN","NINETEEN"],[@$l[15..18]], "nice is slice" );

    push @$l, "TWENTY","TWENTYONE";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "push 6" );
    is( @$l, 21, "Size twentyone" );
    my $v = shift @$l;
    is( $v, "ONE" );
    is_deeply( $l, ["TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "first shift" );
    is( @$l, 20, "Size twenty" );
    push @$l, $v;
    is_deeply( $l, ["TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE", "ONE"], "push 7" );
    is( @$l, 21, "Size twentyone again" );
    unshift @$l, 'ZERO';

    is_deeply( $l, ["ZERO", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE", "ONE"], "first unshift" );
    is( @$l, 22, "Size twentytwo again" );

    # test push, unshift, fetch, fetchsize, store, storesize, delete, exists, clear, pop, shift, splice

    my $pop = pop @$l;
    is( $pop, "ONE", "FIRST POP" );
    is( @$l, 21, "Size after pop" );

    is( $l->[2], "THREE", "fetch early" );
    is( $l->[10], "ELEVEN", "fetch middle" );
    is( $l->[20], "TWENTYONE", "fetch end" );



    my @spliced = splice @$l, 3, 5, "NEENER", "BOINK", "NEENER";

    is_deeply( \@spliced, ["FOUR","FIVE","SIX","SEVEN","EIGHT"], "splice return val" );
    is_deeply( $l, ["ZERO", "TWO", "THREE", "NEENER", "BOINK", "NEENER",
                    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "first splice" );

    $l->[1] = "TWONE";
    is( $l->[1], "TWONE", "STORE" );

    delete $l->[1];

    is_deeply( $l, ["ZERO", undef, "THREE", "NEENER", "BOINK", "NEENER",
                    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "first delete" );
    ok( exists( $l->[0] ), "exists" );
    ok( exists( $l->[1] ), "exists and undefined" );
    ok( !defined( $l->[1] ), "undefined" );
    ok( !exists( $l->[$#$l+1] ), "doesnt exist beyond" );
    ok( exists( $l->[$#$l] ), "exists at end" );

    my $last = pop @$l;
    is( $last, "TWENTYONE", 'POP' );
    is_deeply( $l, ["ZERO", undef, "THREE", "NEENER", "BOINK", "NEENER",
                    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY"], "more pop" );
    is( scalar(@$l), 18, "pop size" );
    is( $#$l, 17, "pop end" );

    @{$l} = ();
    is( $#$l, -1, "last after clear" );
    is( scalar(@$l), 0, "size after clear" );

    $Data::ObjectStore::Array::MAX_BLOCKS  = 82;

    push @$l, 0..10000;
    $store->save;
    my $other_store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $root_node = $store->load_root_container;
    my $ol = $root_node->get_listy( [] );
    my $lsize = @$ol;

    is_deeply( $l, $ol, "lists compare" );

    eval {
        push @$ol, $root_node;
        fail( "was able to push root node into list" );
    };
    like( $@, qr/cannot store a root node in a list/, 'correct error' );
    is( @$ol, $lsize, "list size unchanged" );

    eval {
        $ol->[5] = $root_node;
        fail( "was able to insert root node into list" );
    };
    like( $@, qr/cannot store a root node in a list/, 'correct error' );
    is( @$ol, $lsize, "list size unchanged" );

    my $oh = $root_node->get_hashy( {} );
    eval {
        $oh->{ROOT} = $root_node;
        fail( "was able to store root node into hash" );
    };
    like( $@, qr/cannot store a root node/, 'correct error' );

    my $ohnode = $root_node->get_thingy( $store->create_container() );
    eval {
        $ohnode->get_root( $root_node );
        fail( "was able to store root node into container" );
    };
    like( $@, qr/cannot store a root node/, 'correct error' );
    eval {
        $ohnode->set_root( $root_node );
        fail( "was able to store root node into container" );
    };
    like( $@, qr/cannot store a root node/, 'correct error' );

    $root_node->set_root( $root_node );

    my $old_store = $store;

    $provider = $rs_factory->new_rs;
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );


    my $root = $store->load_root_container;


    my $othing = new OtherThing;
    ok( ! $old_store->_knot( $othing ), ' knot returns undef for non Yote container' );

    $root->set_buf( undef );
    my $thing = $store->create_container;
    $root->get_myList([])->[5] = $thing;

    $store->save;

    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $root = $store->load_root_container;
    is( $root->get_buf, undef, "buf undef" );
    is( $root->get_buf("SLIP"), "SLIP", "buf undef" );
    is_deeply( $root->get_myList, [ undef,undef,undef,undef,undef,$thing ], "thing in list" );
    $root->get_myList->[1] = "WHOOP";

    is_deeply( $root->get_myList, [ undef,"WHOOP",undef,undef,undef,$thing ], "thing in list" );

    # test garbled record
    $provider = $rs_factory->new_rs;
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $root = $store->load_root_container;
    my $third = $store->create_container( { IM => "A GONNER" } );
    $root->set_third( $third );
    $store->save;
    is( $third->[ID], 3, "third with 3rd id" );
    $store->[0]->stow( "BLAHBLAHBLAH", 3 );

    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $root = $store->load_root_container;
    eval {
        $root->get_third;
        fail( "Was able to get garbled record" );
    };
    like( $@, qr/Malformed record/, "error message for garbled record" );

    is( $store->existing_id( "IMNOTOBJ" ), undef, "no id for a non object" );
    is( $store->existing_id( [] ), undef, "no id for an object not put in" );

    

} #test_suite


sub test_no_auto_clean {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    # try opening store with a record store as an argument
    my $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $provider,
        );
    
    my $root_node = $store->load_root_container;
    $root_node->set_foo( "BARZY" );
    $store->save;

    $provider = $rs_factory->reopen( $provider );
    $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $provider,
        );
    
    $root_node = $store->load_root_container;
    is( $root_node->get_foo, "BARZY", "same datastore run with different objectstore" );


    $provider = $rs_factory->new_rs;
    $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $provider,
    );

    $root_node = $store->load_root_container;

    is( $store->get_db_version, $Data::RecordStore::VERSION, "store version" );
    ok( (time - $store->get_created_time) < 3, "just created" );
    ok( ($store->get_last_update_time-$store->get_created_time) < 3, "Just created" );

    ok( ! $store->_has_dirty, "no dirty yet" );

    #
    # general check of item integrity
    #
    $root_node->add_to_myList( { objy =>
                                     $store->create_container( {
                                         someval => 124.42,
                                         somename => 'Käse',
                                         someobj => $store->create_container( {
                                             boringval => "YAWN",
                                             binnerval => "`SPANXZ",
                                             linnerval => "SP`A`NXZ",
                                             'zinn`erval' => "PANXZ`",
                                             innerval => "This is an \\ inner `val\\`\n with Käse \\\ essen ",
                                         } ),
                                     } ),
                                 'some`part' => 'other`part',
                             } );
    $root_node->add_to_myList( 'we three ` foo foo', 'DOOPY' );

    is( $store->_has_dirty, 5, "now has 5 dirty" );
    $store->save( $root_node->get_myList );

    is( $store->_has_dirty, 4, "now has 4 dirty after specific save" );

    #
    # make sure utf 8 is active and working
    #
    is( $root_node->get_myList->[0]{objy}->get_somename, 'Käse', "utf 8 character defore stow" );

    $store->save;

    ok( ! $store->_has_dirty, "no dirty after save" );

    is( $root_node->get_myList->[0]{objy}->get_somename, 'Käse', "utf 8 character after stow before load" );

    #
    # Make sure 6 items got saved...(infoNode), (rootNode), (myList), (hash in mylist), (obj in hash) and (obj in obj)
    #
    is( $store->[DATA_PROVIDER]->entry_count, 6, "correct entry count" );
#    is( $store->[DATA_PROVIDER]->record_count, 6, "correct entry count silo method" );
    #
    # Check to make sure opening the store again will have all the same values.
    #
    my $dup_store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $provider,
        );
    
    my $dup_root = $dup_store->load_root_container;

    is( $dup_root->[Data::ObjectStore::Container::ID], $root_node->[Data::ObjectStore::Container::ID] );
    is_deeply( $dup_root->[Data::ObjectStore::Container::DATA], $root_node->[Data::ObjectStore::Container::DATA] );

    my $hash = $dup_root->get_myList->[0];
    my $oy = $hash->{objy};
    is( $oy->get_somename, 'Käse', "utf 8 character saved in object" );

    is( $oy->get_someval, '124.42', "number saved in object" );

    is( $dup_root->get_myList->[1], 'we three ` foo foo', "list has broken up stuff" );
    is( $dup_root->get_myList->[2], 'DOOPY', "add_to_ takes a lits of things to add" );

    ok( exists $hash->{'some`part'}, "has key with ` character");
    is( $hash->{'some`part'}, 'other`part', "hash key and value both with ` characters" );

    $oy->set_other_objy( $oy->get_someobj->get_innerval );
    $root_node->add_to_myList( $oy, $oy->get_someobj->get_innerval );

    #
    # test ` seperator esccapint working
    #
    is( $oy->get_someobj->get_innerval, "This is an \\ inner `val\\`\n with Käse \\\ essen " );
    is( $oy->get_someobj->get_binnerval, "`SPANXZ" );
    is( $oy->get_someobj->get_boringval, "YAWN" );
    is( $oy->get_someobj->get_linnerval, "SP`A`NXZ" );
    is( $oy->get_someobj->get( 'zinn`erval'), "PANXZ`" );

    # purge test. This should eliminate the following :
    # the old myList, the hash first element of myList, the objy in the hash, the someobj of objy, so 4 items

    my $list_to_remove = $root_node->get_myList();

    my $list_thingy = $store->_knot( $list_to_remove );

    push @$list_to_remove, $list_to_remove, $list_to_remove, $list_to_remove;

    $list_to_remove->[9] = "NINE";

    $store->save;
    $list_to_remove = $root_node->get_myList();

    is( $list_to_remove->[9], 'NINE' );

    my $hash_in_list = $list_to_remove->[0];

    my $list_to_remove_id = $store->_get_id( $list_to_remove );
    my $hash_in_list_id   = $store->_get_id( $hash_in_list );

    my $objy              = $hash_in_list->{objy};

    my $objy_id           = $store->_get_id( $objy );
    my $someobj           = $objy->get_someobj;
    my $someobj_id        = $store->_get_id( $someobj );

    # testing circular reference here. It's connection may have advanced to 2
    $someobj->set_mylistref( $list_to_remove );

    is( $store->[DATA_PROVIDER]->entry_count, 6, "seven entries reset list" );


    ok( $store->[DATA_PROVIDER]->fetch( $list_to_remove_id ), "list before removal" );

    $root_node->set_myList( [] );
    
    is( $store->[DATA_PROVIDER]->entry_count, 7, "seven entries before save" );

    # the seventh entry was written to the record store index, but not yet
    # saved to a silo until save
#    is( $store->[DATA_PROVIDER]->record_count, 6, "correct entry count silo method" );

    $store->save;

    ok( $store->[DATA_PROVIDER]->fetch( $list_to_remove_id ), "removed list before purge" );
    
    is( $store->[DATA_PROVIDER]->entry_count, 7, "correct entry count after nuking the list" );
#    is( $store->[DATA_PROVIDER]->record_count, 7, "correct entry count silo method before syncing store" );

    ok( $store->[DATA_PROVIDER]->fetch( $list_to_remove_id ), "removed list still in cache" );

    undef $list_to_remove;
    undef $hash_in_list;
    undef $objy;
    undef $someobj;

    $store->quick_purge;
    is( $store->[DATA_PROVIDER]->record_count, 3, "correct entry count silo method" );
    
    ok( ! $store->[DATA_PROVIDER]->fetch( $list_to_remove_id ), "removed list removed from store" );
    ok( ! $store->fetch( $list_to_remove_id ), "removed list still removed" );
    ok( ! $store->fetch( $hash_in_list_id ), "removed hash id still removed" );
    ok( ! $store->fetch( $objy_id ), "removed objy still removed" );
    ok( ! $store->fetch( $someobj_id ), "removed someobj still removed" );

    undef $dup_root;

    undef $root_node;

    $Data::ObjectStore::Hash::BUCKET_SIZE = 7;

    my $thash = $store->load_root_container->set_test_hash({});
    # test for hashes large enough that subhashes are inside

    my( %confirm_hash );
    my( @alpha ) = ("A".."G");
    my $val = 1;
    for my $letter (@alpha) {
        $thash->{$letter} = $val;
        $confirm_hash{$letter} = $val;
        $val++;
    }

    $val = 1;
    for my $letter (@alpha) {
        is( $thash->{$letter}, $val++, "Hash value works" );
    }
    $thash->{A} = 100;
    is( $thash->{A}, 100, "overriding hash value works" );
    delete $thash->{A};
    delete $confirm_hash{A};
    ok( ! exists($thash->{A}), "deleting hash value works" );
    $thash->{G} = "GG";
    $confirm_hash{G} = "GG";

    is_deeply( [sort keys %$thash], ["B".."G"], "hash keys works for the simpler hashes" );
    $root_node = $store->load_root_container;

    # now stuff enough there so that the hashes must overflow
    ( @alpha ) = ("AA".."ZZ");
    for my $letter (@alpha) {
        if ( $letter eq 'AE' ) {
            eval {
                $thash->{$letter} = $root_node;
                fail( "was able to put root node into hash" );
            };
            like( $@, qr/cannot store a root node in a hash/, 'correct error' );
            my $c = $store->create_container;
            $thash->{$letter} = $c;
            is( $thash->{$letter}, $c, 'could store normal container' );
        }
        $thash->{$letter} = $val;
        $confirm_hash{$letter} = $val;
        $val++;
    }
    $store->save;
    undef $store;

    my $sup_store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $provider,
    );

    $thash = $sup_store->load_root_container->get_test_hash;

    is_deeply( [sort keys %$thash], [sort ("B".."G","AA".."ZZ")], "hash keys works for the heftier hashes" );

    is_deeply( $thash, \%confirm_hash, "hash checks out keys and values" );
    

    # array tests
    # listy test because
    $Data::ObjectStore::Array::MAX_BLOCKS  = 4;

    $store = $sup_store;
    $root_node = $store->load_root_container;
    my $l = $root_node->get_listy( [] );

    push @$l, "ONE", "TWO";
    is_deeply( $l, ["ONE", "TWO"], "first push" );
    is( @$l, 2, "Size two" );
    is( $#$l, 1, "last index 1" );

    push @$l, "THREE", "FOUR", "FIVE";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE"], "push 1" );
    is( @$l, 5, "Size five" );
    is( $#$l, 4, "last index 1" );

    push @$l, "SIX", "SEVEN", "EIGHT", "NINE";

    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"], "push 2" );
    is( @$l, 9, "Size nine" );

    push @$l, "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN"], "push 3" );
    is( @$l, 16, "Size sixteen" );

    push @$l, "SEVENTEEN", "EIGHTTEEN";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN"], "push 4" );
    is( @$l, 18, "Size eighteen" );
    is_deeply( ["SIXTEEN","SEVENTEEN","EIGHTTEEN",undef],[@$l[15..18]], "nice is slice" );

    push @$l, "NINETEEN";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN"], "push 5" );
    is( @$l, 19, "Size nineteen" );
    is_deeply( ["SIXTEEN","SEVENTEEN","EIGHTTEEN","NINETEEN"],[@$l[15..18]], "nice is slice" );

    push @$l, "TWENTY","TWENTYONE";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "push 6" );
    is( @$l, 21, "Size twentyone" );
    my $v = shift @$l;
    is( $v, "ONE" );
    is_deeply( $l, ["TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "first shift" );
    is( @$l, 20, "Size twenty" );
    push @$l, $v;
    is_deeply( $l, ["TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE", "ONE"], "push 7" );
    is( @$l, 21, "Size twentyone again" );
    unshift @$l, 'ZERO';

    is_deeply( $l, ["ZERO", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE", "ONE"], "first unshift" );
    is( @$l, 22, "Size twentytwo again" );

    # test push, unshift, fetch, fetchsize, store, storesize, delete, exists, clear, pop, shift, splice

    my $pop = pop @$l;
    is( $pop, "ONE", "FIRST POP" );
    is( @$l, 21, "Size after pop" );

    is( $l->[2], "THREE", "fetch early" );
    is( $l->[10], "ELEVEN", "fetch middle" );
    is( $l->[20], "TWENTYONE", "fetch end" );



    my @spliced = splice @$l, 3, 5, "NEENER", "BOINK", "NEENER";

    is_deeply( \@spliced, ["FOUR","FIVE","SIX","SEVEN","EIGHT"], "splice return val" );
    is_deeply( $l, ["ZERO", "TWO", "THREE", "NEENER", "BOINK", "NEENER",
                    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "first splice" );

    $l->[1] = "TWONE";
    is( $l->[1], "TWONE", "STORE" );

    delete $l->[1];

    is_deeply( $l, ["ZERO", undef, "THREE", "NEENER", "BOINK", "NEENER",
                    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "first delete" );
    ok( exists( $l->[0] ), "exists" );
    ok( exists( $l->[1] ), "exists and undefined" );
    ok( !defined( $l->[1] ), "undefined" );
    ok( !exists( $l->[$#$l+1] ), "doesnt exist beyond" );
    ok( exists( $l->[$#$l] ), "exists at end" );

    my $last = pop @$l;
    is( $last, "TWENTYONE", 'POP' );
    is_deeply( $l, ["ZERO", undef, "THREE", "NEENER", "BOINK", "NEENER",
                    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY"], "more pop" );
    is( scalar(@$l), 18, "pop size" );
    is( $#$l, 17, "pop end" );

    @{$l} = ();
    is( $#$l, -1, "last after clear" );
    is( scalar(@$l), 0, "size after clear" );

    $Data::ObjectStore::Array::MAX_BLOCKS  = 82;

    push @$l, 0..10000;
    $store->save;
    my $other_store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $provider,
    );

    $root_node = $store->load_root_container;
    my $ol = $root_node->get_listy( [] );
    my $lsize = @$ol;

    is_deeply( $l, $ol, "lists compare" );

    eval {
        push @$ol, $root_node;
        fail( "was able to push root node into list" );
    };
    like( $@, qr/cannot store a root node in a list/, 'correct error' );
    is( @$ol, $lsize, "list size unchanged" );

    eval {
        $ol->[5] = $root_node;
        fail( "was able to insert root node into list" );
    };
    like( $@, qr/cannot store a root node in a list/, 'correct error' );
    is( @$ol, $lsize, "list size unchanged" );

    my $oh = $root_node->get_hashy( {} );
    eval {
        $oh->{ROOT} = $root_node;
        fail( "was able to store root node into hash" );
    };
    like( $@, qr/cannot store a root node/, 'correct error' );

    my $ohnode = $root_node->get_thingy( $store->create_container() );
    eval {
        $ohnode->get_root( $root_node );
        fail( "was able to store root node into container" );
    };
    like( $@, qr/cannot store a root node/, 'correct error' );
    eval {
        $ohnode->set_root( $root_node );
        fail( "was able to store root node into container" );
    };
    like( $@, qr/cannot store a root node/, 'correct error' );

    $root_node->set_root( $root_node );

    my $old_store = $store;

    $provider = $rs_factory->new_rs;
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );


    my $root = $store->load_root_container;

    my $othing = new OtherThing;
    ok( !$old_store->_knot( $othing ), 'getting knot for non container returns undef' );

    $root->set_buf( undef );
    my $thing = $store->create_container;
    $root->get_myList([])->[5] = $thing;

    $store->save;

    $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $provider,
    );

    $root = $store->load_root_container;
    is( $root->get_buf, undef, "buf undef" );
    is( $root->get_buf("SLIP"), "SLIP", "buf undef" );
    is_deeply( $root->get_myList, [ undef,undef,undef,undef,undef,$thing ], "thing in list" );
    $root->get_myList->[1] = "WHOOP";

    is_deeply( $root->get_myList, [ undef,"WHOOP",undef,undef,undef,$thing ], "thing in list" );

    # test garbled record
    $provider = $rs_factory->new_rs;
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );

    $root = $store->load_root_container;
    my $third = $store->create_container( { IM => "A GONNER" } );
    $root->set_third( $third );
    $store->save;
    is( $third->[ID], 3, "third with 3rd id" );
    $store->[0]->stow( "BLAHBLAHBLAH", 3 );

    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );

    $root = $store->load_root_container;
    eval {
        $root->get_third;
        fail( "Was able to get garbled record" );
    };
    like( $@, qr/Malformed record/, "error message for garbled record" );

    $provider = $rs_factory->new_rs;
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $root_node = $store->load_root_container;
    #
    # general check of item integrity
    #
    $root_node->add_to_myList( { objy =>
                                     $store->create_container( {
                                         someval => 124.42,
                                         somename => 'Käse',
                                         someobj => $store->create_container( {
                                             boringval => "YAWN",
                                             binnerval => "`SPANXZ",
                                             linnerval => "SP`A`NXZ",
                                             'zinn`erval' => "PANXZ`",
                                             innerval => "This is an \\ inner `val\\`\n with Käse \\\ essen ",
                                         } ),
                                     } ),
                                 'some`part' => 'other`part',
                             } );
    $root_node->add_to_myList( 'we three ` foo foo', 'DOOPY' );
    $hash = $root_node->get_myList->[0];
    $oy = $hash->{objy};
    my $soy = $oy->get_someobj;
    $root_node->add_to_myList( $oy, $soy ); #adding this to two places.
    $soy->set_somelist( $root_node->get_myList );
    $oy->set_somelist( $root_node->get_myList );
    $oy->set_woothing( $soy );

    $store->save;
    my $prov = $store->[DATA_PROVIDER];
    $store->quick_purge;
    $root_node->set_myList([]);
    $store->save;

    $store->quick_purge;
    $store->save;
    is_deeply( $root_node->get_myList, [], "root node mylist after clean and stuff" );
    
} #test_no_auto_clean



sub test_circular {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    my $info_node = $store->_fetch_store_info_node;
    my $root      = $store->load_root_container;
    my $h = {};
    my $l = [$h];
    my $o = $store->create_container( {
        list => $l,
        hash => $h,
    } );
    approx( $store->last_updated( $o ), $store->created( $o ), .5 , "obj created and last updated same time" );

    ok( ! $store->last_updated("FOO"), "no update for a scalar" );
    ok( ! $store->created("FOO"), "no update for a scalar" );

    $o->set_self( $o );

    $h->{foo} = $o;
    $h->{bar} = $h;
    push @$l, $l, $h;
    # make sure the root and the info node can't be added to other nodes.
    eval {
        $h->{root} = $root;
        fail( 'cannot store a root node' );
    };
    like( $@, qr/cannot store a root node/, 'hash store root' );
    eval {
        $h->{info} = $info_node;
        fail( 'cannot store info node' );
    };
    like( $@, qr/cannot store a root node/, 'hash store info' );
    eval {
        push @$l, $root;
        fail( 'cannot store a root node' );
    };
    like( $@, qr/cannot store a root node/, 'list store root' );
    eval {
        push @$l, $info_node;
        fail( 'cannot store info node' );
    };
    like( $@, qr/cannot store a root node/, 'list store info' );
    eval {
        $o->set_root( $root );
        fail( '' );
        fail( 'cannot store a root node' );
    };
    like( $@, qr/cannot store a root node/, 'obj store root' );
    eval {
        $o->set_info( $info_node );
        fail( 'cannot store info node' );
    };
    like( $@, qr/cannot store a root node/, 'obj store info' );

    $root->set_root( $root );
    $root->set_info( $info_node );
    $info_node->set_root( $root );
    $info_node->set_info( $info_node );


    $root->set_list( $l );

    my $ht = $store->_knot( $h );
    my $lt = $store->_knot( $l );

    $store->save;
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $root = $store->load_root_container;
    $l = $root->get_list;
    $h = $l->[0];
    $o = $h->{foo};

    $ht = $store->_knot( $h );
    $lt = $store->_knot( $l );


} #test_circular

sub test_loop {
    my( $cls, $rs_factory ) = @_;
    
    my $provider = $rs_factory->new_rs;
    my $new_store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    my $new_root_node = $new_store->load_root_container;
    my $list = [ 1, 2, 3, 4, 5 ];
    unshift @$list, $list;
    $new_root_node->set_list( $list );
    approx( $new_store->last_updated( $list ), $new_store->created( $list ), .5, "list created and last updated same time" );
    $new_store->save;

    $new_store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $new_root_node = $new_store->load_root_container;
    $list = $new_root_node->get_list;
    is( scalar( @$list ), 6, "six items in the self referencing list" );
    is( scalar( @{$list->[0]} ), 6, "six items in the list in the list" );
    is( scalar( @{$list->[0][0]} ), 6, "six items in the list in the list in the list" );
    push @$list, '6';
    is( scalar( @$list ), 7, "seven items in the self referencing list" );
    is( scalar( @{$list->[0][0]} ), 7, "seven items in the list in the list in the list" );

    my $h = { foo => 'bar' };
    $h->{h} = $h;
    push @$list, $h;
    approx( $new_store->last_updated( $h ), $new_store->created( $h ), .5, "created and last updated same time" );
    $new_store->save;


    $new_store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    $new_root_node = $new_store->load_root_container;
    $list = $new_root_node->get_list;
    my $hash = $list->[7];

    is( scalar( keys %$hash ), 2, "two keys after load" );
    $hash->{ZIP} = 234;
    is( scalar( keys %{$hash->{h}} ), 3, "now 3 keys" );

    my $olist = shift @$list;
    is( $olist, $list, "List was unshifted" );


} #test loop

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

sub test_purge {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider, CACHE => 900 );
    my $root = $store->load_root_container;
    my $keep = $root->set_keep( $store->create_container );
    $keep->set_me( $keep );
    my $dontkeep = $root->set_dontkeep( $store->create_container );
    $dontkeep->set_me( $dontkeep );
    $store->save;
    $root->remove_field( 'dontkeep' );
    $store->save;
    my $recstore = $store->data_store;

    $store->quick_purge;
} #test_purge

sub test_hash {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider, CACHE => 900 );
    my $root_node = $store->load_root_container;
    my $hash;
    for my $SZ (2..30) {
        $Data::ObjectStore::Hash::BUCKET_SIZE = $SZ;
        $hash = $root_node->set_hash({});
        my $match = {};
        $hash->{FOO} = "BAR";
        $match->{FOO} = "BAR";

        _cmph( "FIRSTFROO", $hash, $match );
        $hash->{FOO} = "BAF";
        $match->{FOO} = "BAF";
        _cmph( "SecondFOO", $hash, $match );

        my( @keys ) = ("A".."Z","UND","ROOT");
        my( @vals ) = (1..26,undef,$root_node);
        is( scalar(@keys), scalar(@vals), "keys match vals" );
        while ( @keys ) {
            my $k = shift @keys;
            my $v = shift @vals;
            if ( $k eq 'ROOT' ) {
                if ( $SZ == 25 ) {
                    eval {
                        $hash->{$k} = $v;
                        fail( "Was able to put the root into a hash" );
                    };
                    like( $@, qr/cannot store a root node/, 'not able to store a root into hash' );
                }
            }
            else {
                $hash->{$k} = $v;
                $match->{$k} = $v;
            }
        }
        _cmph( "alphawet buckets $SZ", $hash, $match );
        if ( $SZ == 3 ) {
            is( delete $hash->{BOOGA}, undef, 'nothing to delete from big hash' );
            is( delete $hash->{A}, 1, 'deleted from big hash' );
            is( $hash->{B}, 2, 'get from big hash' );

            %$hash = ();        #clear away

            is( $hash->{BA}, undef, 'nothing to get from big hash' );
        }
    } #each size

    $root_node->set_bigdoubler( { map { $_ => 2*$_ } (0..$Data::ObjectStore::Hash::BUCKET_SIZE) } );
    is_deeply( $root_node->get_bigdoubler, { map { $_ => 2*$_ } (0..$Data::ObjectStore::Hash::BUCKET_SIZE) }, "hash made okey that was larger than the default bucket size" );
    $store->save;
    is_deeply( $root_node->get_bigdoubler, { map { $_ => 2*$_ } (0..$Data::ObjectStore::Hash::BUCKET_SIZE) }, "hash made okey that was larger than the default bucket size, still okey after save" );

    $provider = $rs_factory->new_rs;
    my $cache = Data::ObjectStore::Cache->new( 900 );
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider, CACHE => $cache );

    $root_node = $store->load_root_container;

    my $h = $root_node->set_newh({});
    $h->{FOO} = "BAR";
    is_deeply( $h, { FOO => "BAR" }, "Simple hash" );
    is( $store->_has_dirty, 2, 'dirty before save' );
    $store->save;

    $h->{FOO} = "BAR";
    ok( ! $store->_has_dirty, "no dirty changes" );
    is_deeply( $h, { FOO => "BAR" }, "Simple hash" );

    $h->{OBJY} = $store->create_container;
    $store->save;

    delete $h->{OBJY};
    $h->{NOTHING} = undef;
    $store->save;
    $store->quick_purge;
    

    eval {
        $h->{NOTHERE} = new OtherThing;
        fail( "wrong obj type allowed in hash" );
    };
    like( $@, qr/Cannot ingest/, "error message for setting non container object in hash" );

    %$h = ( NEW => "SO CLEARED" );
    is( delete $h->{FOOFU}, undef, "Nothing to delete" );
    is_deeply( $h, { NEW => "SO CLEARED" }, "cleared hash new values" );
    $store->save;

    %$h = ();
    is( $store->_has_dirty, 1, "cleared hash so its dirty" );
    $store->save;
    %$h = ();
    ok( ! $store->_has_dirty, "cleared hash that was already cleared so not dirty" );

    my $tied = $store->_knot( $h );
    is( ref( $h ), 'HASH', "hash is correct class" );
    is( ref( $tied ), 'Data::ObjectStore::Hash', "tied hash is correct class" );
    is( ref( $tied->store ), 'Data::ObjectStore', "can access store thru tied" );

    is( $store->_knot( { my => 'hash' } ), undef, "not tied hash" );
    is_deeply( $tied, $store->_knot( $tied ), "tied hash knot returns itself" );

    $provider = $rs_factory->new_rs;

    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider, CACHE => 900 );
    my $root = $store->load_root_container;
    $Data::ObjectStore::Hash::BUCKET_SIZE = 3;
    $h = $root->set_hash( { 1 => 1, 2 => 2, 3 => 3 } );
    $h->{4} = 4;
    eval {
        $h->{root} = $root;
        fail( "Was able to store the root in the hash" );
    };
    like( $@, qr/cannot store a root node in a hash/, "unable to store the root in the hash" );
    eval {
        $h->{extra_to_make_sure_newkey_also_works} = $root;
        fail( "Was able to store the root in the hash" );
    };
    like( $@, qr/cannot store a root node in a hash/, "unable to store the root in the hash" );

    eval {
        $h->{must_hash_to_new_bucket} = $root;
        fail( "Was able to store the root in the hash" );
    };
    like( $@, qr/cannot store a root node in a hash/, "unable to store the root in the hash" );
    
} #test_hash

sub test_arry {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider, CACHE => 900 );
    my $root_node = $store->load_root_container;

    for my $SZ (2..9) {
        $Data::ObjectStore::Array::MAX_BLOCKS  = $SZ;

        my $arry = $root_node->set_arry( [] );
        my $match = [];

        _cmpa( "empty start $SZ", $arry, $match );

        _cmpa( "fifth el $SZ", $arry->[4], $match->[4] );

        $arry->[8] = "EI";
        $match->[8] = "EI";
        _cmpa( "one el $SZ", $arry, $match );

        _cmpa( "exists nothing $SZ", exists $arry->[9], exists $match->[9] );
        _cmpa( "exists yada $SZ", exists $arry->[8], exists $match->[8] );
        _cmpa( "same array sizes", $#$arry, $#$match );
        _cmpa( "exists before $SZ", exists $arry->[4], exists $match->[4] );

        $arry->[81] = "EI2";
        $match->[81] = "EI2";
        _cmpa( "oneel $SZ", $arry, $match );

        $store->save;

        my $other_store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider, CACHE => 900 );
        my $aloaded = $other_store->load_root_container->get_arry;

        _cmpa( "SAVED LOADED", $aloaded, $match );

        my $a = $arry->[82];
        my $m = $match->[82];

        _cmpa( "delnow1 $SZ", $arry, $match, $a, $m );

        $a = delete $arry->[81];
        $m = delete $match->[81];
        _cmpa( "delnow2 $SZ", $arry, $match, $a, $m );

        $a = delete $arry->[81];
        $m = delete $match->[81];
        _cmpa( "delnowagain $SZ", $arry, $match, $a, $m );

        $a = pop @$arry;
        $m = pop @$match;
        _cmpa( "pops $SZ", $arry, $match, $a, $m );

        @{$arry} = ();
        @{$match} = ();
        _cmpa( "clear $SZ", $arry, $match );

        $#$arry = 17;
        $#$match = 17;
        _cmpa( "setsize $SZ", $arry, $match );

        unshift @$arry, "HERE ARE SOME THINGS", "AND AGAIN";
        unshift @$match, "HERE ARE SOME THINGS", "AND AGAIN";
        _cmpa( "unshift $SZ", $arry, $match );

        $a = shift @$arry;
        $m = shift @$match;
        _cmpa( "shift $SZ", $arry, $match, $a, $m );

        unshift @$arry, 'A'..'L';
        unshift @$match, 'A'..'L';

        _cmpa( "unshift more $SZ", $arry, $match, $a, $m );

        $arry = $root_node->set_arry_more( [ 1 .. 19 ] );
        $match = [ 1 .. 19 ];
        is_deeply( $arry, $match, "INITIAL $SZ" );
        is( @$arry, 19, "19 items" );
        is( $#$arry, 18, "last idx is 18" );
        $a = shift @$arry;
        $m = shift @$match;
        is( $a, $m, "SHIFT $SZ" );
        is_deeply( $arry, $match, "AFTER SHIFT $SZ" );
        is( @$arry, 18, "18 items" );
        is( $#$arry, 17, "last idx is 17" );
        $a = pop @$arry;
        $m = pop @$match;
        is( $a, $m, "POP $SZ" );
        is_deeply( $arry, $match, "AFTER POP $SZ" );
        is( @$arry, 17, "17 items" );
        is( $#$arry, 16, "last idx is 16" );

        my( @a ) = splice @$arry, 3, 4, ("A".."N");
        my( @m ) = splice @$match, 3, 4, ("A".."N");

        is_deeply( $arry, $match, "AFTER SPLICE $SZ" );
        is_deeply( \@a, \@m, "SPLICE return $SZ" );

        my $a2 = $root_node->set_arry2([]);
        my $m2 = [];

        $a2->[55] = "Z";
        $m2->[55] = "Z";
        is( $#$a2, $#$m2, "Same last index $SZ" );
        is( @$a2, @$m2, "Same size $SZ" );
        is_deeply( $a2, $m2, "Same stuff $SZ" );

        my( @sa ) = splice @$a2, 3, 44;
        my( @sm ) = splice @$m2, 3, 44;
        is( $#$a2, $#$m2, "empty splice last idx $SZ" );
        is( @$a2, @$m2, "empty splice size $SZ" );
        is_deeply( $a2, $m2, "empty splice stuff $SZ" );

    }                           #each bucketsize

    $Data::ObjectStore::Array::MAX_BLOCKS = 10;
    #
    # [ 0 .. 9 ] [ 10 .. 19 ] [ 20 .. 29 ]
    #
    $root_node = $store->load_root_container;
    my $arry = $root_node->set_arry( [ 0..29 ] );
    my $thingy = tied @$arry;

    is( $thingy->[LEVEL], 1, "One level of blocks" );
    splice @$arry, 10, 11, "A".."L";

    is_deeply( $arry, [(0..9),('A'..'L'),(21..29)], "after splice" );

    $arry = $root_node->set_arry( [ 0..29 ] );
    $thingy = tied @$arry;
    splice @$arry, 10, 1111, "A".."L";
    is_deeply( $arry, [(0..9),('A'..'L')], "after splice 2" );
    $store->save;
    $root_node = $store->load_root_container;

    is_deeply( $root_node->get_arry, [(0..9),('A'..'L')], "after splice 2" );


    my $newa = $root_node->set_somea([]);
    $newa->[6] = 55;
    my $o = $store->create_container;
    $newa->[5] = $o;
    my( @parts ) = splice @$newa, 4, 5;
    is_deeply( \@parts, [undef,$o,55],"spice with empties" );
    (@parts) = splice @$newa, 0, 0;
    is_deeply( \@parts, [],"empty spice" );

    my $oa = $root_node->set_oa([]);
    ok( tied @$oa, "tied after creeation" );
    $oa->[1] = $store->create_container;

    my $arra = $root_node->set_arra( [ "ONE" ] );
    delete $arra->[0];
    is_deeply( $arra, [],"empty after delete" );

    ok( ! exists $arra->[0], "first element was deleted from array" );
    my $nexto = $store->create_container;
    $oa->[1] = $nexto;
    is_deeply( $oa, [undef,$nexto], "after obj replace" );

    ok( ! exists $arra->[0], "doesnt exist past end of array" );
    $oa->[2] = "NOTAREF";
    ok( tied @$oa, "tied after set" );
    eval {
        $oa->[2] = new OtherThing;
        fail( "wrong obj type allowed in array" );
    };
    like( $@, qr/Cannot ingest/, "error message for setting non container object in array" );
    ok( tied @$oa, "tied after fail" );
    is( $oa->[2], "NOTAREF", "old value still there" );
    is( delete $oa->[2], "NOTAREF", "delete a non reference" );
    ok( tied @$oa, "tied after reset" );
    @$oa = ("ARRAY TRIGGER CLEAR");
    ok( tied @$oa, "still tied after reset" );
    is_deeply( $oa, ["ARRAY TRIGGER CLEAR"], "after obj replace" );
    $store->save;

    @$oa = ();
    ok( tied @$oa, "still tied after clear" );
    is( $store->_has_dirty, 1, "cleared array so its dirty" );
    $store->save;
    @$oa = ();
    ok( ! $store->_has_dirty, "cleared array that was already cleared so not dirty" );
    is( shift @$oa, undef, "nothing to shift off" );
    ok( ! $store->_has_dirty, "shifting off nothing doesnt make dirty" );
    is( $oa, $root_node->get_oa, 'same ref after cleaer' );
    is_deeply( $oa, $root_node->get_oa, 'same ref after cleaer' );

    my $item = $store->create_container;
    push @$oa, 1,2,3,4,5,$item,$item;

    is( pop @$oa, $item, "last reference popped off" );

    is( delete $oa->[-1], $item, 'deleted the last one' );
    is( delete $oa->[-1], 5, 'deleted the last one after the last one' );
    is( delete $oa->[-2], 3, 'deleted the next to last one' );

    is_deeply( $oa, [ 1, 2, undef, 4 ], 'array after deletions' );

    $#$oa = 2;
    is_deeply( $oa, [ 1, 2, undef ], 'array after adjusting size' );
    $#$oa = -1;
    is_deeply( $oa, [  ], 'array after adjusting size to negative or zero' );

    $provider = $rs_factory->new_rs;
    $Data::ObjectStore::Array::MAX_BLOCKS  = 5;
    
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider, CACHE => 900 );
    
    $root_node = $store->load_root_container;
    my $spli = $root_node->set_fooy( [1..15] ); # [5][5][5][][]
    splice @$spli, 5, 0, (16..25);              #fills it up

    is_deeply( $root_node->get_fooy, [1..5,16..25,6..15], 'splice filled up' );

    my( @ret ) = splice @$spli, 5, 20, "A".."C";
    is_deeply( \@ret, [16..25,6..15], "spliced out" );
    is_deeply( $spli, [1..5,"A".."C"], "spliced remaining" );
    splice @$spli, 7, 0, "D","E";
    is_deeply( $spli, [1..5,"A","B","D","E","C"], "spliced added" );
    is( pop @$spli, "C", "popped off C" );
    splice @$spli, 10, 0, "NOINS";
    is_deeply( $spli, [1..5,"A","B","D","E","NOINS"], "spliced added no insert into block case" );

    # the following makes sure that the tied UNSHIFT doesn't barf but perl freaks out and
    # warns if unshift isn't give a value to unshift.
    no warnings 'syntax';
    unshift @$spli;
    use warnings 'syntax';

    is_deeply( $spli, [1..5,"A","B","D","E","NOINS"], "after empty unshift" );
    my( @gone ) = splice @$spli, 0, 100, "Q".."Z";
    is_deeply( \@gone, [1..5,"A","B","D","E","NOINS"], "after big splice" );
    is_deeply( $spli, ["Q".."Z"], "after biiggy splice" );
    (@gone) = splice @$spli, 0, -2, "A", "B";
    is_deeply( $spli, ["A","B","Y","Z"], "after neg offset" );
    is_deeply( \@gone, ["Q".."X"], "after big splice and neg offset" );
    
    (@gone) = splice @$spli, 1, -2, "C", "D";
    is_deeply( $spli, ["A","C","D","Y","Z"], "after neg offset" );
    is_deeply( \@gone, ["B"], "after small splice and neg offset" );

    my $c = $store->create_container;
    (@gone) = splice @$spli, -3, 0, 1, 2, $c;
    is_deeply( $spli, ["A","C",1,2,$c,"D","Y","Z"], "after neg offset" );
    is_deeply( \@gone, [], "after neg offset no remove" );
    my( $rc ) = splice @$spli, 4, 1;
    is( $rc, $c, "spliced out an object" );
    is_deeply( $spli, ["A","C",1,2,"D","Y","Z"], "after splicing out container" );
    
    ( @gone ) = splice @$spli;
    is_deeply( \@gone, ["A","C",1,2,"D","Y","Z"], "when everything removed" );
    is_deeply( $spli, [], "what is left when everything removed" );

    my $tied = $store->_knot( $spli );
    is( ref( $spli ), 'ARRAY', "array is correct class" );
    is( ref( $tied ), 'Data::ObjectStore::Array', "tied is correct class" );
    is( ref( $tied->store ), 'Data::ObjectStore', "can access store thru tied" );

    is_deeply( $tied, $store->_knot( $tied ), "tied array knot returns itself" );

    
    is( $store->_knot( [ 'my','arry' ] ), undef, "not tied arry" );

    $root_node->set_poparry([]);
    is( pop( @{$root_node->get_poparry} ), undef, "popping empty array" );

    is( shift( @{$root_node->get_poparry} ), undef, "shifting empty array" );

} #test_arry

#012345678901234567890123456789
#ABCDEFGHIJKLMNOPQRSTUVWXYZ
sub test_connections {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    my $root = $store->load_root_container;

    my $other_thing = OtherThing->new;
    eval {
        $root->set_other( $other_thing );
        fail( "was able to set a non container object" );
    };
    like( $@, qr/Cannot ingest/, "error message for setting non container object" );

    my $hash = $root->set_hash({});
    my $tha = $store->_knot( $hash );

    my $obj_rand = $store->create_container;
    $root->set_rand( $obj_rand );

    my $obj_refd = $store->create_container;
    my $refd_id = $obj_refd->[ID];

    my $obj_unrefd = $store->create_container;
    my $unrefd_id = $obj_unrefd->[ID];
    $obj_refd->set_unrefd( $obj_unrefd );
    undef $obj_unrefd;

    $obj_refd->get_unrefd->set_rand( $obj_rand );

    $root->set_refd( $obj_refd );

    $root->set_refd( undef );

    ok( $root->[DSTORE]->fetch( $unrefd_id ), 'unref id not gone from store before save' );
    ok( $root->[DSTORE]->fetch( $refd_id ), 'ref obj not yet gone from store' );

    $store->save;

    undef $obj_refd;

    $store->save;
    $store->quick_purge;

    ok( ! $root->[DSTORE]->fetch( $unrefd_id ), 'unref id gone from store' );
    ok( ! $root->[DSTORE]->fetch( $refd_id ), 'ref obj now gone from store' );

    $root->add_to_myList( { foo => "bar" } );

    is( $root->get_myList->[0]{foo}, "bar", "objects path correct" );

    $provider = $rs_factory->new_rs;
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    is( $store->[DATA_PROVIDER]->entry_count, 2, 'store with just root nodes' );
    my $con = $store->create_container;
    my $zon = $store->create_container;
    my $pon = $store->create_container;
    is( $store->[DATA_PROVIDER]->entry_count, 5, 'id for the containers' );
    $zon->set_pon( $pon );
    $store->load_root_container->set_zon( $zon );
    $store->save( $con );
    $store->save( $pon );
    $store->quick_purge;
    
    $store->save;

} #test_connections

sub test_classes {
    my( $cls, $rs_factory ) = @_;
    my $provider = $rs_factory->new_rs;
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    my $root = $store->load_root_container;

    require SomeThing;
    my $newid;
    {
        my $newy = $root->set_newy( $store->create_container( 'SomeThing' ) );
        $newid = $store->existing_id( $newy );
        ok( $newid > 0, "got an existing id for the other thing" );
        $store->save;
    }
    {
        local @INC = grep { $_ ne 't/lib' } @INC;
        local %INC = %INC;
        delete $INC{"SomeThing.pm"};
        eval {
            require SomeThing;
        };
        like( $@, qr/Can't locate SomeThing.pm/, "removed something from includable path" );
        undef $@;
        eval {
            my $newy = $root->get_newy;
            fail( 'was able to instantiate newy without SomeThing in path' );
        };
        like( $@, qr/Can't locate SomeThing.pm/, "removed otherthing from includable path" );
        
        eval {
            my $newy = $store->fetch( $newid );
            fail( 'was able to instantiate newy without SomeThing in path from fetch' );
        };
        like( $@, qr/Can't locate SomeThing.pm/, "removed otherthing from includable path from fetch" );
        
        my $newy = $store->fetch( $newid, 1 );
        is( ref($newy), 'Data::ObjectStore::Container', "Was able to force newy to be a container" );
    }
    
    my $newy = $store->create_container( 'SomeThing' );
    is( ref( $newy ), 'SomeThing', "made an obj" );
    $store->save( $newy );
    {
        is( SomeThing->isa( 'Data::ObjectStore::Container' ), 1, "something is still a container" );
        local @INC = grep { $_ ne 't/lib' } @INC;
        local %INC = %INC;
        delete $INC{"SomeThing.pm"};
        unshift @INC, 't/lib2';
        # simulate SomeThing being changed from a container to not a container
        require SomeThing;
        is( SomeThing->isa( 'Data::ObjectStore::Container' ), '', "something is no longer a container" );
        eval {
            my $newy = $store->fetch( $newid );
            fail( 'was able to instantiate newy with augmented non container SomeThing' );
        };
        like( $@, qr/is not a 'Data::ObjectStore::Container'/, "removed otherthing from includable path from fetch" );
        $newy = $store->fetch( $newid, 1 );
        is( ref($newy), 'Data::ObjectStore::Container', "Was able to force newy to be a container" );
    }

} #test_classes

sub test_fields {
    my( $cls, $rs_factory ) = @_;    
    my $provider = $rs_factory->new_rs;
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $provider );
    my $root = $store->load_root_container;

    $root->get_foo( undef );
    $root->get_bar;
    $root->get_zap( 0 );
    is_deeply( [sort @{$root->fields}], [sort qw( zap ) ], "one fields defined" );
    $root->set_foo( undef );
    $root->set_bar;
    is_deeply( [sort @{$root->fields}], [sort qw( bar foo zap ) ], "now three fields defined" );
    $root->set_zap( undef );
    is_deeply( [sort @{$root->fields}], [sort qw( bar foo zap ) ], "still three fields defined" );

    $root->remove_field( 'zap' );
    is_deeply( [sort @{$root->fields}], [sort qw( bar foo ) ], "now two fields defined" );

} #test_fields

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
