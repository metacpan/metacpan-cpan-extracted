#!/usr/bin/perl
use strict;
use warnings;
no warnings 'uninitialized';

use Data::ObjectStore;
use Data::RecordStore;

use lib 't/lib';
use test::TestThing;
use OtherThing;

use Data::Dumper;
use File::Copy;
use File::Copy::Recursive qw/dircopy/;
use File::Temp qw/ :mktemp tempdir /;
use File::Path qw/ remove_tree /;
use Test::More;
use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

BEGIN {
    use_ok( "Data::ObjectStore" ) || BAIL_OUT( "Unable to load 'Data::ObjectStore'" );
}

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

# -----------------------------------------------------
#               init
# -----------------------------------------------------

$Data::ObjectStore::DEBUG = 0;

test_no_auto_clean();
test_autoload();
test_overload();
test_subclass();
test_vol();
test_lock();
test_suite();
test_upgrade_db();
test_circular();
test_loop();
test_arry();
test_hash();
test_connections();
test_fields();
test_classes();
test_purge();
test_bighash();

done_testing;

exit( 0 );

sub approx {
    my( $a, $b, $tol, $test ) = @_;
    ok( abs($a-$b) <= $tol, $test );
}

sub test_overload {

    my $dir = tempdir( CLEANUP => 1 );
    my( $x, $z );
  {
      my $store = Data::ObjectStore->open_store( $dir );
      $x = $store->create_container;
      $z = $store->create_container;
      my $r = $store->load_root_container;
      $r->set_x( $x );
      $r->set_z( $z );
      $store->save;
  }

    my $store = Data::ObjectStore->open_store( $dir );
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

    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store( $dir );
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
    my $dir = tempdir( CLEANUP => 1 );
  {
      my $store = Data::ObjectStore->open_store( $dir );
      my $root = $store->load_root_container;
      $root->set_thing( $store->create_container( 'test::TestThing' ) );
      $root->set_thing2( $store->create_container( 'test::TestThing', { message => "for you sir" } ) );
      $root->set_container( $store->create_container( { message => "not so hot" } ) );
      $store->save;
  }
    my $store = Data::ObjectStore->open_store( $dir );
    is( $store->load_root_container->get_thing->foo, 'BAR', 'test thing loaded okey' );
    is( $store->load_root_container->get_thing2->get_message, 'for you sir', 'test thing data loaded okey' );
    is( $store->load_root_container->get_container->get_message, 'not so hot', 'normal data loaded okey' );


} #test_subclass

sub test_vol {
    my $dir = tempdir( CLEANUP => 1 );
  {
      my $store = Data::ObjectStore->open_store( $dir );
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
    my $store = Data::ObjectStore->open_store( $dir );
    ok( ! $store->load_root_container->vol( "TEST" ), "VOL is gone as store reloads" );
} #test_vol

sub test_lock {
    my $dir = tempdir( CLEANUP => 1 );
    # ohhh, this is going to have to be forked, isn't it?
  {
      my $store = Data::ObjectStore->open_store( $dir );
      my $root = $store->load_root_container;
      $root->lock('nurf','nurf');
      $root->unlock;
  }
} #test_lock

sub test_suite {

    eval {
        my $store = Data::ObjectStore->open_store;
        fail( "Was able to open the store without arguments" );
    };
    like( $@, qr/requires at least one argument/, 'correct error for no arguments open' );

    # try opening store with a record store as an argument
    my $dir = tempdir( CLEANUP => 1 );
    my $datastore = Data::RecordStore->open_store( $dir );
    my $store = Data::ObjectStore->open_store( $datastore );
    my $root_node = $store->load_root_container;
    $root_node->set_foo( "BARZY" );
    $store->save;

    $store = Data::ObjectStore->open_store( $datastore );
    $root_node = $store->load_root_container;
    is( $root_node->get_foo, "BARZY", "same datastore run with different objectstore" );

    $dir = tempdir( CLEANUP => 1 );
    $store = Data::ObjectStore->open_store( $dir );
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
    is( $store->[DATA_PROVIDER]->active_entry_count, 6, "correct active entry count silo method" );

    #
    # Check to make sure opening the store again will have all the same values.
    #
    my $dup_store = Data::ObjectStore->open_store( $dir );
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
    is( $store->[DATA_PROVIDER]->active_entry_count, 6, "correct entry count silo method" );

    $store->save;
    $store->quick_purge;

    is( $store->[DATA_PROVIDER]->entry_count, 7, "correct entry count after nuking the list" );
    is( $store->[DATA_PROVIDER]->active_entry_count, 3, "correct active entry count after nuking the list" );

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

    my $sup_store = Data::ObjectStore->open_store( $dir );
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
    my $other_store = Data::ObjectStore->open_store( $dir );
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

    $dir = tempdir( CLEANUP => 1 );
    $store = Data::ObjectStore->open_store( $dir );


    my $root = $store->load_root_container;


    my $othing = new OtherThing;
    ok( ! $old_store->_knot( $othing ), ' knot returns undef for non Yote container' );

    $root->set_buf( undef );
    my $thing = $store->create_container;
    $root->get_myList([])->[5] = $thing;

    $store->save;

    $store = Data::ObjectStore->open_store( $dir );
    $root = $store->load_root_container;
    is( $root->get_buf, undef, "buf undef" );
    is( $root->get_buf("SLIP"), "SLIP", "buf undef" );
    is_deeply( $root->get_myList, [ undef,undef,undef,undef,undef,$thing ], "thing in list" );
    $root->get_myList->[1] = "WHOOP";

    is_deeply( $root->get_myList, [ undef,"WHOOP",undef,undef,undef,$thing ], "thing in list" );

    # test garbled record
    $dir = tempdir( CLEANUP => 1 );
    $store = Data::ObjectStore->open_store( $dir );
    $root = $store->load_root_container;
    my $third = $store->create_container( { IM => "A GONNER" } );
    $root->set_third( $third );
    $store->save;
    is( $third->[ID], 3, "third with 3rd id" );
    $store->[0]->stow( "BLAHBLAHBLAH", 3 );

    $store = Data::ObjectStore->open_store( $dir );
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

    # try opening store with a record store as an argument
    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $dir,
    );
    my $root_node = $store->load_root_container;
    $root_node->set_foo( "BARZY" );
    $store->save;

    $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $dir,
    );
    $root_node = $store->load_root_container;
    is( $root_node->get_foo, "BARZY", "same datastore run with different objectstore" );
    $dir = tempdir( CLEANUP => 1 );
    $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $dir,
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
    is( $store->[DATA_PROVIDER]->active_entry_count, 6, "correct active entry count " );

    #
    # Check to make sure opening the store again will have all the same values.
    #
    my $dup_store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $dir,
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


    ok( $store->[DATA_PROVIDER]->fetch( $list_to_remove_id ), "list before removal" );

    $root_node->set_myList( [] );
    
    is( $store->[DATA_PROVIDER]->entry_count, 7, "seven entries before save" );

    # the seventh entry was written to the record store index, but not yet
    # saved to a silo until save
    is( $store->[DATA_PROVIDER]->active_entry_count, 6, "correct entry count silo method" );

    $store->save;

    ok( $store->[DATA_PROVIDER]->fetch( $list_to_remove_id ), "removed list before purge" );
    
    is( $store->[DATA_PROVIDER]->entry_count, 7, "correct entry count after nuking the list" );
    is( $store->[DATA_PROVIDER]->active_entry_count, 7, "correct active entry count before syncing the store" );

    ok( $store->[DATA_PROVIDER]->fetch( $list_to_remove_id ), "removed list still in cache" );

    undef $list_to_remove;
    undef $hash_in_list;
    undef $objy;
    undef $someobj;

    $store->quick_purge;
    is( $store->[DATA_PROVIDER]->active_entry_count, 3, "correct active entry count after nuking the list" );
    
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
        DATA_PROVIDER => $dir,
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
        DATA_PROVIDER => $dir,
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

    $dir = tempdir( CLEANUP => 1 );
    $store = Data::ObjectStore->open_store( $dir );


    my $root = $store->load_root_container;

    my $othing = new OtherThing;
    ok( !$old_store->_knot( $othing ), 'getting knot for non container returns undef' );

    $root->set_buf( undef );
    my $thing = $store->create_container;
    $root->get_myList([])->[5] = $thing;

    $store->save;

    $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $dir,
    );

    $root = $store->load_root_container;
    is( $root->get_buf, undef, "buf undef" );
    is( $root->get_buf("SLIP"), "SLIP", "buf undef" );
    is_deeply( $root->get_myList, [ undef,undef,undef,undef,undef,$thing ], "thing in list" );
    $root->get_myList->[1] = "WHOOP";

    is_deeply( $root->get_myList, [ undef,"WHOOP",undef,undef,undef,$thing ], "thing in list" );

    # test garbled record
    $dir = tempdir( CLEANUP => 1 );
    $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $dir,
    );

    $root = $store->load_root_container;
    my $third = $store->create_container( { IM => "A GONNER" } );
    $root->set_third( $third );
    $store->save;
    is( $third->[ID], 3, "third with 3rd id" );
    $store->[0]->stow( "BLAHBLAHBLAH", 3 );

    $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $dir,
    );

    $root = $store->load_root_container;
    eval {
        $root->get_third;
        fail( "Was able to get garbled record" );
    };
    like( $@, qr/Malformed record/, "error message for garbled record" );


    
    $dir = tempdir( CLEANUP => 1 );
    $store = Data::ObjectStore->open_store(
        DATA_PROVIDER => $dir,
    );
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
    is( $prov->active_entry_count, 6, 'six things created' );
    $store->quick_purge;
    $root_node->set_myList([]);
    $store->save;
    is( $prov->active_entry_count, 7, 'now seven things created' );

    $store->quick_purge;
    $store->save;
    is_deeply( $root_node->get_myList, [], "root node mylist after clean and stuff" );
    is( $prov->active_entry_count, 3, 'now just 3 things' );
    
} #test_no_auto_clean


sub test_upgrade_db {

    #
    # storing a structure defined by :
    #
    # 1 --> OBJ( root -> r2 )
    # 2 --> OBJ( list -> rlist )
    # robj --> OBJ( hash -> rhash, list -> rlist, self -> robj,  )
    # rarray --> ARRAY( rhash rlist rhash )
    # rhash --> HASH( bar --> rhash, foo --> robj )
    #
    #  [root] --list--> [ { foo => Obj( hash => rlist, list => rlist, self => rself ), bar => rhash }, rlist, rhash ]
    #
    # so it should have the following connections to root
    #     robj  II
    #     rlist  III
    #     rhash  IIII
    #
    # back connections should be
    #     robj  : robj=1, rhash=1
    #     rlist : robj=1, rlist=1, 2=1
    #     rhash : rhash=1, rlist=2, robj=1
    #
    #  (made by code )
    #      my $h = {};
    #      my $l = [$h];
    #      my $o = $store->create_container( {
    #          list => $l,
    #          hash => $h,
    #                                        } );
    #      $o->set_self( $o );
    #      $h->{foo} = $o;
    #      $h->{bar} = $h;
    #      push @$l, $l, $h;
    #
    #      $root->set_list( $l );
    #
    #
    my $source_dir = tempdir( CLEANUP => 1 );
    dircopy( "t/OLDVERSIONDB", $source_dir );
    my $dest_dir = tempdir( CLEANUP => 1 );

    eval {
        my $store = Data::ObjectStore->open_store( $source_dir );
        fail( "was able to open a store with an old incompatable version" );
    };
    like( $@, qr/Unable to open|lock file did not exist|Permission denied/i, 'error message for opeining store with incompatable message' );


    # allows the store to be open anyway
    $Data::ObjectStore::UPGRADING = 1;
    my $store = Data::ObjectStore->open_store( $source_dir );

    is( $store->[DATA_PROVIDER]->entry_count, 8, "upgrade eight IDs to start" );
    is( $store->[DATA_PROVIDER]->active_entry_count, 8, "upgrade seven active IDS to start" );

    $Data::ObjectStore::UPGRADING = 0;
    eval {
        Data::ObjectStore::upgrade_store( $source_dir, $dest_dir );
        pass( "able to upgrade store" );
    };
    ok( !$@, "got error '$@' upgrading store" );
    $store = Data::ObjectStore->open_store( $dest_dir );
    my $root = $store->load_root_container;


    my $list = $root->get_list;
    my $listthing = $store->_knot( $list );
    my $hash = $list->[0];
    my $hashthing = $store->_knot( $hash );
    my $obj = $hash->{foo};

    is( $store->[DATA_PROVIDER]->entry_count, 5, "upgrade five IDS after" );
    is( $store->[DATA_PROVIDER]->active_entry_count, 5, "upgrade five active IDS after" );

    eval {
        Data::ObjectStore::upgrade_store( $source_dir, $dest_dir );
        fail( "Was able to upgrade a store into a full directory" );
    };
    like( $@, qr/already has a store/, "error message for trying to upgrade an upgraded store" );

    my $newempty = tempdir( CLEANUP => 1 );
    eval {
        Data::ObjectStore::upgrade_store( $dest_dir, $newempty );
        fail( "Was able to upgrade a store already upgraded" );
    };
    like( $@, qr/already at version/, "error message for trying to upgrade an upgraded store" );


} #test_upgrade_db

sub test_circular {

    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store( $dir );

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
    $store = Data::ObjectStore->open_store( $dir );
    $root = $store->load_root_container;
    $l = $root->get_list;
    $h = $l->[0];
    $o = $h->{foo};

    $ht = $store->_knot( $h );
    $lt = $store->_knot( $l );


} #test_circular

sub test_loop {
    my $dir = tempdir( CLEANUP => 1 );

    my $new_store = Data::ObjectStore->open_store( $dir );
    my $new_root_node = $new_store->load_root_container;
    my $list = [ 1, 2, 3, 4, 5 ];
    unshift @$list, $list;
    $new_root_node->set_list( $list );
    approx( $new_store->last_updated( $list ), $new_store->created( $list ), .5, "list created and last updated same time" );
    $new_store->save;

    $new_store = Data::ObjectStore->open_store( $dir );
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

    is( $new_store->[DATA_PROVIDER]->active_entry_count, 4, 'one list, hash and root' );

    $new_store = Data::ObjectStore->open_store( $dir );
    $new_root_node = $new_store->load_root_container;
    $list = $new_root_node->get_list;
    my $hash = $list->[7];

    is( scalar( keys %$hash ), 2, "two keys after load" );
    $hash->{ZIP} = 234;
    is( scalar( keys %{$hash->{h}} ), 3, "now 3 keys" );

    my $olist = shift @$list;
    is( $olist, $list, "List was unshifted" );

    is( $new_store->[DATA_PROVIDER]->active_entry_count, 4, 'still one list, hash and root' );

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
    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
    my $root = $store->load_root_container;
    my $keep = $root->set_keep( $store->create_container );
    $keep->set_me( $keep );
    my $dontkeep = $root->set_dontkeep( $store->create_container );
    $dontkeep->set_me( $dontkeep );
    $store->save;
    $root->remove_field( 'dontkeep' );
    $store->save;
    my $recstore = $store->data_store;
    is( ref( $recstore ), 'Data::RecordStore', "data store is record store" );
    is( $recstore->active_entry_count, 4, '4 active entries' );

    is( $store->quick_purge, 1, 'one thing purged' );
    is( $recstore->active_entry_count, 3, '3 active entries after purge' );
} #test_purge


sub test_hash {

    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
    my $root_node = $store->load_root_container;
    my $hash;
    for my $pair ([20,2], [20,10 ] ) {
        ( $Data::ObjectStore::Hash::MAX_SIZE,
          $Data::ObjectStore::Hash::BUCKET_SIZE ) = @$pair;

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
                if ( $pair->[1] == 10 ) {
                    eval {
                        $hash->{$k} = $v;
                        fail( "Was able to put the root into a hash" );
                    };
                    like( $@, qr/cannot store a root node/, 'not able to store a root into hash' );
                }
            }
            else {
                $hash->{$k} = $v;
                ok(exists $hash->{$k}, "Hash has key" );
                $match->{$k} = $v;
            }
        }
        my( @kv );
        while( my($k,$v) = each %$hash ) {
            push @kv, "$k$v";
        }
        is_deeply( [sort @kv], [sort map { "$_$hash->{$_}" } keys( %$hash ) ], "alphabuck keys each" );
        _cmph( "alphawet buckets @$pair", $hash, $match );
        $store->save;
        my $news = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
        my $nooroo = $news->load_root_container;
        my $newh = $nooroo->get_hash;
        _cmph( "alphawet buckets @$pair loaded", $hash, $match );
        if ( $pair->[1] == 2 ) {
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

    $dir = tempdir( CLEANUP => 1 );
    my $cache = Data::ObjectStore::Cache->new( 900 );
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => $cache );
#    $store = Data::ObjectStore->open_store( $dir );
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
    is( $store->[DATA_PROVIDER]->active_entry_count, 4, 'stowing things in hash' );

    delete $h->{OBJY};
    $h->{NOTHING} = undef;
    $store->save;
    is( $store->quick_purge, 1, 'one thing purged' );
    
    is( $store->[DATA_PROVIDER]->active_entry_count, 3, 'removed obj from hash' );

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

    $dir = tempdir( CLEANUP => 1 );

    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
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

sub test_bighash {
    ( $Data::ObjectStore::Hash::MAX_SIZE,
      $Data::ObjectStore::Hash::BUCKET_SIZE ) = ( 4, 7 );
    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
    my $root_node = $store->load_root_container;
    my $h = $root_node->set_hash({});
    my $top = 20;
    for (1 .. $top ) {
        $h->{$_} = $_;
    }
    is_deeply( $h, { map { $_ => $_ } (1..$top) }, "in hash 5x5" );
    $h->{BAGEL} = [];
    $store->save;

    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
    $root_node = $store->load_root_container;
    $h = $root_node->get_hash;
    is_deeply( $h, { BAGEL => [], map { $_ => $_ } (1..$top) }, "in hash 5x5, loaded store" );

    delete $h->{BAGEL};
    is_deeply( $h, { map { $_ => $_ } (1..$top) }, "in hash 5x5, loaded store" );
    $store->save;
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
    $root_node = $store->load_root_container;
    $h = $root_node->get_hash;
    is_deeply( $h, { map { $_ => $_ } (1..$top) }, "in hash 5x5, loaded store" );
    ( $Data::ObjectStore::Hash::MAX_SIZE,
      $Data::ObjectStore::Hash::BUCKET_SIZE ) = ( 4, 1000 );
    $dir = tempdir( CLEANUP => 1 );    
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
    $root_node = $store->load_root_container;
    $h = $root_node->get_hash({});
    
    for (3 .. 7) {
        $h->{$_} = $_*2;
    }
    my $t = tied %$h;

    eval {
        $h->{ROOT} = $root_node;
        fail( "could attach root node" );
    };
    my( @keys );
    while( my( $k, $v ) = each %$h ) {
        push @keys, $k;
        is( $k*2, $v, "each $k correct" );
    }
    is_deeply( [sort @keys], [3..7], 'keys from hash got by each' );
    is_deeply( [sort keys %$h], [3..7], 'keys from hash' );
    
    ( $Data::ObjectStore::Hash::MAX_SIZE,
      $Data::ObjectStore::Hash::BUCKET_SIZE ) = ( 1_062_599, 29 );

    
} #test_bighash

sub test_arry {

    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
#    my $store = Data::ObjectStore->open_store( $dir );
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

        my $other_store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
        #        my $other_store = Data::ObjectStore->open_store( $dir );
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

    $dir = tempdir( CLEANUP => 1 );
    $Data::ObjectStore::Array::MAX_BLOCKS  = 5;
    
    $store = Data::ObjectStore->open_store( DATA_PROVIDER => $dir, CACHE => 900 );
#    $store = Data::ObjectStore->open_store( $dir );
    
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
    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store( $dir );

    my $root = $store->load_root_container; # 1, 2 entries

    my $other_thing = new OtherThing;
    eval {
        $root->set_other( $other_thing );
        fail( "was able to set a non container object" );
    };
    like( $@, qr/Cannot ingest/, "error message for setting non container object" );

    my $hash = $root->set_hash({}); # 1, 2, 3 entries
    my $tha = $store->_knot( $hash );

    my $obj_rand = $store->create_container; # 1, 2, 3, 4 entries
    $root->set_rand( $obj_rand );

    my $obj_refd = $store->create_container; # 1, 2, 3, 4, 5 entries
    my $refd_id = $obj_refd->[ID];

    my $obj_unrefd = $store->create_container; # 1, 2, 3, 4, 5, 6 entries
    my $unrefd_id = $obj_unrefd->[ID];
    $obj_refd->set_unrefd( $obj_unrefd );
    undef $obj_unrefd;

    $obj_refd->get_unrefd->set_rand( $obj_rand );

    $root->set_refd( $obj_refd ); # 1, 2, 3, 4, 5, 6 entries all conneccted

    $root->set_refd( undef );  # 1, 2, 3, 4 entries conneccted,  5, 6 unconnected

    ok( $root->[DSTORE]->fetch( $unrefd_id ), 'unref id not gone from store before save' );
    ok( $root->[DSTORE]->fetch( $refd_id ), 'ref obj not yet gone from store' );

    $store->save;

    undef $obj_refd;

    $store->save;
    is( $store->quick_purge, 2, 'two thing purged' );

    ok( ! $root->[DSTORE]->fetch( $unrefd_id ), 'unref id gone from store' );
    ok( ! $root->[DSTORE]->fetch( $refd_id ), 'ref obj now gone from store' );

    $root->add_to_myList( { foo => "bar" } );

    is( $root->get_myList->[0]{foo}, "bar", "objects path correct" );

    $dir = tempdir( CLEANUP => 1 );
    $store = Data::ObjectStore->open_store( $dir );
    is( $store->[DATA_PROVIDER]->entry_count, 2, 'store with just root nodes' );
    is( $store->[DATA_PROVIDER]->active_entry_count, 2, 'root nodes saved by store creation' );
    my $con = $store->create_container;
    my $zon = $store->create_container;
    my $pon = $store->create_container;
    is( $store->[DATA_PROVIDER]->entry_count, 5, 'id for the containers' );
    is( $store->[DATA_PROVIDER]->active_entry_count, 2, 'nothing saved yet' );
    $zon->set_pon( $pon );
    $store->load_root_container->set_zon( $zon );
    $store->save( $con );
    $store->save( $pon );
    is( $store->quick_purge, 1, 'one thing purged' );
    
    is( $store->[DATA_PROVIDER]->active_entry_count, 3, 'root nodes and 2 containers saved, but only one of the containers connects' );
    $store->save;

    is( $store->[DATA_PROVIDER]->active_entry_count, 4, 'root nodes and 2 containers saved, one container not connected' );

} #test_connections

sub test_classes {
    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store( $dir );

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
        like( $@, qr/Can't locate SomeThing.pm/, "removed otherthing from includable path" );
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
        
        local( *STDERR );
        my $errout;
        open( STDERR, ">>", \$errout );
        my $newy = $store->fetch( $newid, 1 );
        is( ref($newy), 'Data::ObjectStore::Container', "Was able to force newy to be a container" );
        like( $errout, qr/Forcing 'SomeThing' to be 'Data::ObjectStore::Container'/, "force warning" );
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

        local( *STDERR );
        my $errout;
        open( STDERR, ">>", \$errout );
        $newy = $store->fetch( $newid, 1 );
        like( $errout, qr/Forcing 'SomeThing' to be 'Data::ObjectStore::Container'/, "force warning" );
        is( ref($newy), 'Data::ObjectStore::Container', "Was able to force newy to be a container" );
    }
#    unshift @INC, 't/lib';
    require SomeThingElse;
    require Tainer;
    my $other = $root->set_othur( $store->create_container('Tainer') );
    is( ref($other), 'Tainer', 'starts as other' );
    $store->save( $other, 'SomeThingElse' );
    $store->save;
    $store = Data::ObjectStore->open_store( $dir );
    $root = $store->load_root_container;
    is( ref($root->get_othur), 'SomeThingElse', 'is now some' );
} #test_classes

sub test_fields {
    my $dir = tempdir( CLEANUP => 1 );
    my $store = Data::ObjectStore->open_store( $dir );

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

__END__

    eval {

    };
    like( $@, qr//, '' );


bash$ perl -e '@l = (1,2,3); $l[1] = "A"; print join(",",@l)."\n"'
1,A,3
bash$ perl -e '@l = (1,2,3); $l[1] = "A"; print scalar(@l)."\n"'
3
bash$ perl -e '@l = (1,2,3); $l[10] = "A"; print scalar(@l)."\n"'
3
bash$ perl -e '@l = (1,2,3); $l[10] = "A"; print scalar(@l)."\n"'
11
bash$ perl -e '@l = (1,2,3); $l[10] = undef; print scalar(@l)."\n"'perl -e '@l = (1,2,3); $l[10] = undef; print scalar(@l)."\n"'
11
bash$ perl -e '@l = (1,2,3); $l[10] = undef; delete $l[10]; print scalar(@l)."\n"'
3
bash$ perl -e '@l = (1,2,3); $l[10] = undef; $l[9] = undef; delete $l[10]; print scalar(@l)."\n"'
10
bash$ perl -e '@l = (1,2,3); $l[10] = undef; $l[9] = undef; delete $l[10]; print scalar(@l)."\n"'
