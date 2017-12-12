use strict;
use warnings;

use Data::RecordStore;

use Data::Dumper;
use File::Temp qw/ :mktemp tempdir /;
use Test::More;

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

BEGIN {
    use_ok( "Data::RecordStore" ) || BAIL_OUT( "Unable to load Data::RecordStore" );
}

# -----------------------------------------------------
#               init
# -----------------------------------------------------

test_suite();

done_testing;

exit( 0 );

sub check {
    my( $store, $txt, %checks ) = @_;

    my $silo = $store->_get_silo(4);

    my( @trans ) = $store->list_transactions;
    is( @trans, $checks{trans}, "$txt : transactions" );
    is( $store->entry_count, $checks{entries}, "$txt: active entries" );
    is( $store->[1]->entry_count, $checks{ids}, "$txt: ids in index" );
    is( $store->[2]->entry_count, $checks{recyc}, "$txt: recycle count" );
    is( $silo->entry_count, $checks{silo}, "$txt: silo count" );

} #check

sub test_suite {
    my $dir = tempdir( CLEANUP => 1 );

    my $store = Data::RecordStore->open_store( $dir );
    check( $store, "init",
           entries => 0,
           trans   => 0,
           ids     => 0,
           recyc   => 0,
           silo    => 0,
        );

    my $trans = $store->create_transaction;
    check( $store, "create trans",
           entries => 0,
           ids     => 0,
           silo    => 0,
           recyc   => 0,
           trans   => 1, #trans created
        );

    $trans->commit;
    check( $store, "commit trans",
           entries => 0,
           ids     => 0,
           silo    => 0,
           recyc   => 0,
           trans   => 0, #trans completed
        );

    eval { $trans->stow("WOOBUU"); };
    like( $@, qr/not active/, "cant stow on inactve" );
    undef $@;

    eval { $trans->delete_record(3); };
    like( $@, qr/not active/, "cant delete record on inactve" );
    undef $@;

    eval { $trans->recycle_id(3); };
    like( $@, qr/not active/, "cant recycle record on inactve" );
    undef $@;

    check( $store, "still nada",
           trans   => 0,
           entries => 0,
           recyc   => 0,
           ids     => 0,
           silo    => 0,
        );

    $trans = $store->create_transaction;
    check( $store, "new trans",
           trans   => 1, #new trans
           entries => 0,
           ids     => 0,
           silo    => 0,
           recyc   => 0,
        );


    my $id = $trans->stow( "HERE IS SOME" );

    check( $store, "trans stow 1",
           trans   => 1,
           entries => 1, # one id in use
           ids     => 1, # one id created
           silo    => 1, # one written to silo
           recyc   => 0,
        );

    $trans->stow( "HERE IS MORE", $id );

    check( $store, "trans stow 2",
           trans   => 1,
           entries => 1,
           recyc   => 0,
           ids     => 1,
           silo    => 2, # same id written to silo
        );

    $trans->recycle_id( $id );

    check( $store, "trans recycle",
           trans   => 1,
           entries => 1,
           recyc   => 0,
           ids     => 1,
           silo    => 2,
        );

    my $next_id = $store->next_id;

    is( $next_id, 2, "second id created during trans recycle" );

    check( $store, "store next id",
           trans   => 1,
           entries => 2, # 2 ids in use
           recyc   => 0,
           ids     => 2, # 2 ids created
           silo    => 2,
        );

    $trans->commit;

    check( $store, "trans stow 1 after commit",
           trans   => 0, # transaction committed
           entries => 1, # one recycled out, other is next id
           recyc   => 1, # recycle
           ids     => 2,
           silo    => 0, # 2 instances of one id recycled away
        );

    $next_id = $store->next_id;

    is( $next_id, 1, "next id is recycled 1 after commit" );

    check( $store, "after trans recyc next id",
           trans   => 0,
           entries => 2, # 1 and 2
           recyc   => 0, # recycle done
           ids     => 2,
           silo    => 0,
        );


    $trans = $store->create_transaction;

    check( $store, "new transaction",
           trans   => 1, #new trans
           entries => 2,
           recyc   => 0,
           ids     => 2,
           silo    => 0,
        );

    $id = $next_id;
    $trans->stow( "HERE IS SOME", $id );

    check( $store, "transaction stow",
           trans   => 1,
           entries => 2,
           recyc   => 0,
           ids     => 2,
           silo    => 1, #trans stow
        );

    $trans->stow( "HERE IS MORE", $id );

    check( $store, "addl stow",
           trans   => 1,
           entries => 2,
           recyc   => 0,
           ids     => 2,
           silo    => 2, #addl stow on same id
        );

    $trans->recycle_id( $id );

    check( $store, "trans recyc",
           trans   => 1,
           entries => 2,
           recyc   => 0, #recycle not yet happened
           ids     => 2,
           silo    => 2,
        );

    $next_id = $store->next_id;

    is( $next_id, 3, "next id is three" );

    check( $store, "after next id",
           trans   => 1,
           entries => 3, #after next id
           recyc   => 0,
           ids     => 3, #after next id
           silo    => 2,
        );

    $trans->rollback;
"
    also, test to make sure a broken written record at the end of a silo file
        doesn't sink the whole thing

    there is something in the silo that shouldnt be there
        rollback didnt work for this case
 ";
    check( $store, "after transaction rollback",
           trans   => 0, #transaction done
           entries => 3,
           recyc   => 0,
           ids     => 3,
           silo    => 0,
        );

    $next_id = $store->next_id;
    is( $next_id, 4, "next id is 4 after aborted recycle" );

    check( $store, "after aborted recycle",
           trans   => 0,
           entries => 4,
           recyc   => 0,
           ids     => 4,
           silo    => 0,
        );



    $trans = $store->create_transaction;
    check( $store, "new trans",
           trans   => 1, #new trans
           entries => 4,
           recyc   => 0,
           ids     => 4,
           silo    => 0,
        );

    $id = $trans->stow( "HERE IS SOME" );
    is( $id, 5, "new trans new id" );

    check( $store, "new trans will store",
           trans   => 1, #new trans
           entries => 5, #new id
           recyc   => 0,
           ids     => 5, #new id generated
           silo    => 1, #something in silo
        );

    $id = $trans->stow( "CHANGED mind", $id );
    is( $id, 5, "new trans new id still 5" );

    check( $store, "new trans will store overwrite",
           trans   => 1,
           entries => 5,
           recyc   => 0,
           ids     => 5, #same id used
           silo    => 2, #one more silo entry though
       );

    $id = $trans->stow( "MEW NEW mind" );
    is( $id, 6, "new trans new id now 6" );

    check( $store, "new trans will store overwrite",
           trans   => 1,
           entries => 6, #new entry
           recyc   => 0,
           ids     => 6, #new id for new entry
           silo    => 3, #one more silo entry though
       );

    $trans->commit;

    is( $store->fetch( $id ), "MEW NEW mind", "transaction value" );
    
    check( $store, "new trans commit",
           trans   => 0,
           entries => 6,
           recyc   => 0,
           ids     => 6, #same id used
           silo    => 2, #one more silo entry though
       );

} #test_suite
