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

use constant {
    STATE       => 3,

    # TRANSACTION STATUSES
    TRA_ACTIVE           => 1, # transaction has been created
    TRA_IN_COMMIT        => 2, # commit has been called, not yet completed
    TRA_IN_ROLLBACK      => 3, # commit has been called, has not yet completed
    TRA_CLEANUP_COMMIT   => 4, # everything in commit has been written, TRA is in process of being removed
    TRA_CLEANUP_ROLLBACK => 5, # everything in commit has been written, TRA is in process of being removed
    TRA_DONE             => 6, # transaction complete. It may be removed.
};

my $is_windows = $^O eq 'MSWin32';


# -----------------------------------------------------
#               init
# -----------------------------------------------------

test_suite();
test_suite(1);

done_testing;

exit( 0 );

sub check {
    my( $store, $txt, %checks ) = @_;


    my( @trans ) = $store->list_transactions;
    is( @trans, $checks{trans}, "$txt : transactions" );
    is( $store->entry_count, $checks{entries}, "$txt: total entries" );
    is( $store->record_count, $checks{records}, "$txt: active records" );
    is( $store->[1]->entry_count, $checks{ids}, "$txt: ids in index" );
    is( $store->[2]->entry_count, $checks{recyc}, "$txt: recycle count" );
    if( $checks{silo_id} > 0 ) {
        my $silo = $store->_get_silo($checks{silo_id});
        is( $silo->entry_count, $checks{silo}, "$txt: silo count" );
    }

} #check

sub test_suite {
    my $use_single = shift;
    my $mode = $use_single ? 'SINGLE' : 'MULTI';
    my $dir = tempdir( CLEANUP => 1 );

    my $store = Data::RecordStore->open_store( BASE_PATH => $dir, MODE => $mode );
    check( $store, "init",
           entries => 0,
           records => 0,
           trans   => 0,
           ids     => 0,
           recyc   => 0,
           silo_id => 12,
           silo    => 0,
        );

    my $trans = $store->start_transaction;
    is( $trans, $store->use_transaction, "use transaction is same as current transaction" );
    check( $store, "create trans",
           entries => 0,
           records => 0,
           ids     => 0,
           silo_id => 12,
           silo    => 0,
           recyc   => 0,
           trans   => 1, #trans created
        );
    is( $trans->get_state, 1, "active transaction" );
    is( $trans->get_id, 1, "First transaction" );
    is( $trans->get_process_id, $$, "transaction processlist" );
    ok( (time - $trans->get_update_time) < 2, "less than 2 second test" );
    
    $trans->commit;
    check( $store, "commit trans",
           entries => 0,
           records => 0,
           ids     => 0,
           silo_id => 12,
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
           records => 0,
           entries => 0,
           recyc   => 0,
           ids     => 0,
           silo_id => 12,
           silo    => 0,
        );

    $trans = $store->start_transaction;
    check( $store, "new trans",
           trans   => 1, #new trans
           entries => 0,
           records => 0,
           ids     => 0,
           silo_id => 12,
           silo    => 0,
           recyc   => 0,
        );

    eval { $trans->stow("NOZERO",0); };
    like( $@, qr/must be a positive/, "cant stow zero id" );
    undef $@;
    eval { $trans->stow("NONEGS",-1); };
    like( $@, qr/must be a positive/, "cant stow negative id" );
    undef $@;
    eval { $trans->stow("NONEGS",3.2); };
    like( $@, qr/must be a positive/, "cant stow non integer" );
    undef $@;

    
    my $id = $trans->stow( "HERE IS SOME" );

    check( $store, "trans stow 1",
           trans   => 1,
           entries => 1, # one id in use
           records => 1,
           ids     => 1, # one id created
           silo_id => 12,
           silo    => 1, # one written to silo
           recyc   => 0,
        );

    $trans->stow( "HERE IS MORE", $id );

    check( $store, "trans stow 2",
           trans   => 1,
           entries => 1,
           records => 2,
           recyc   => 0,
           ids     => 1,
           silo_id => 12, # one written to silo
           silo    => 2,  # same id written to silo
        );

    
    $trans->recycle_id( $id );

    check( $store, "trans recycle",
           trans   => 1,
           entries => 1,
           records => 2,
           recyc   => 0,
           ids     => 1,
           silo_id => 12,
           silo    => 2,
        );

    my $next_id = $store->next_id;

    is( $next_id, 2, "second id created during trans recycle" );

    check( $store, "store next id",
           trans   => 1,
           entries => 2, # 2 ids in use
           records => 2,
           recyc   => 0,
           ids     => 2, # 2 ids created
           silo_id => 12,
           silo    => 2,
        );

    $trans->commit;

    check( $store, "trans stow 1 after commit",
           trans   => 0, # transaction committed
           entries => 1, # one recycled out, other is next id
           records => 0,
           recyc   => 1, # recycle
           ids     => 2,
           silo_id => 12,
           silo    => 0, # 2 instances of one id recycled away
       );

    $next_id = $store->next_id;

    is( $next_id, 1, "next id is recycled 1 after commit" );

    check( $store, "after trans recyc next id",
           trans   => 0,
           entries => 2, # 1 and 2
           records => 0,
           recyc   => 0, # recycle done
           ids     => 2,
           silo_id => 12,
           silo    => 0,
        );


    # test recursive transactions. an outer transaction
    # will rollback an inner transaction that has committed

    my $outer_trans = $store->start_transaction;
    
    check( $store, "new transaction",
           trans   => 1, #new trans
           entries => 2,
           records => 0,
           recyc   => 0,
           ids     => 2,
           silo_id => 12,
           silo    => 0,
        );

    $id = $next_id;
    $store->stow( "HERE IS SOME", $id );

    check( $store, "transaction stow",
           trans   => 1,
           entries => 2,
           records => 1,
           recyc   => 0,
           ids     => 2,
           silo_id => 12,
           silo    => 1, #trans stow
        );

    $outer_trans->stow( "HERE IS MORE", $id );

    check( $store, "addl stow",
           trans   => 1,
           entries => 2,
           records => 2,
           recyc   => 0,
           ids     => 2,
           silo_id => 12,
           silo    => 2, #addl stow on same id
        );

    my $inner_trans = $store->start_transaction;

    check( $store, "made inner trans",
           trans   => 2,
           entries => 2,
           records => 2,
           recyc   => 0,
           ids     => 2,
           silo_id => 12,
           silo    => 2, #addl stow on same id
        );

    
    is( $store->fetch($id), "HERE IS MORE", "before rollback trans delete" );

    my $inner_inner_trans = $store->start_transaction;
    
    eval {
        $inner_trans->commit;
        fail( "commited transaction without inner transaction being committed" );
    };
    like( $@, qr/Cannot commit outer transaction/, "could commit transaction when inner transaction was active" );
    
    $store->recycle_id( $id );

    is( $store->fetch($id), undef, "after inner trans delete" );
    
    check( $store, "trans recyc",
           trans   => 3,
           entries => 2,
           records => 2,
           recyc   => 0, #recycle not yet committed
           ids     => 2,
           silo_id => 12,
           silo    => 2,
        );

    $next_id = $store->next_id;

    is( $next_id, 3, "next id is three" );

    check( $store, "after next id",
           trans   => 3,
           entries => 3, #after next id
           records => 2,
           recyc   => 0,
           silo_id => 12,
           ids     => 3, #after next id
           silo    => 2,
        );
    $inner_inner_trans->commit;
    eval {
        $inner_inner_trans->commit;
        fail( "commited complete transaction" );
    };
    like( $@, qr/Cannot commit/, 'couldnt commit complete transaction' );

    for my $stat (TRA_IN_COMMIT,TRA_IN_ROLLBACK,TRA_CLEANUP_COMMIT) {
        my $tiny_trans = $store->start_transaction;
        $tiny_trans->[STATE] = $stat;
        eval {
            $tiny_trans->commit;
            pass( "committed tiny transaction with state $stat" );
        };
        is( $@, '', "no error from committing tiny transaction with state $stat" );
    }
    my $tiny_trans = $store->start_transaction;
    my $stat = TRA_CLEANUP_ROLLBACK;
    $tiny_trans->[STATE] = $stat;
    eval {
        $tiny_trans->commit;
        fail( "committed tiny transaction with state $stat" );
    };
    like( $@, qr/Cannot commit transaction/, "unable to commit tiny transaction state $stat" );
    $tiny_trans->rollback;

    for $stat (TRA_IN_COMMIT,TRA_IN_ROLLBACK,TRA_CLEANUP_ROLLBACK) {
        $tiny_trans = $store->start_transaction;
        $tiny_trans->[STATE] = $stat;
        eval {
            $tiny_trans->rollback;
            pass( "rolledback tiny transaction with state $stat" );
        };
        is( $@, '', "no error from rolling back tiny transaction with state $stat" );
    }
    $tiny_trans = $store->start_transaction;
    $stat = TRA_CLEANUP_COMMIT;
    $tiny_trans->[STATE] = $stat;
    eval {
        $tiny_trans->rollback;
        fail( "rolled back tiny transaction with state $stat" );
    };
    like( $@, qr/Cannot rollback transaction/, "unable to roll back tiny transaction state $stat" );
    $tiny_trans->[STATE] = TRA_ACTIVE;
    $tiny_trans->commit;
    
    $inner_trans->rollback;
    eval {
        $inner_trans->commit;
        fail( "commited complete transaction" );
    };
    like( $@, qr/Cannot commit/, 'couldnt commit complete transaction' );

    is( $store->fetch($id), "HERE IS MORE", "after rollback of trans delete" );
    
    # also, test to make sure a broken written record at the end of a silo file
    #     doesn't sink the whole thing

    # there is something in the silo that shouldnt be there
    #     rollback didnt work for this case

    $outer_trans->rollback;

    is( $store->fetch($id), undef, "after rollback of outer trans" );    
    
    check( $store, "after transaction rollback",
           trans   => 0, #transaction done
           entries => 3,
           records => 0,
           recyc   => 0,
           ids     => 3,
           silo_id => 12,
           silo    => 0,
        );

    $next_id = $store->next_id;
    is( $next_id, 4, "next id is 4 after aborted recycle" );

    check( $store, "after aborted recycle",
           trans   => 0,
           entries => 4,
           records => 0,
           recyc   => 0,
           ids     => 4,
           silo_id => 12,
           silo    => 0,
        );



    $trans = $store->start_transaction;
    check( $store, "new trans",
           trans   => 1, #new trans
           entries => 4,
           records => 0,
           recyc   => 0,
           ids     => 4,
           silo_id => 12,
           silo    => 0,
        );

    $id = $trans->stow( "HERE IS SOME" );
    is( $id, 5, "new trans new id" );

    check( $store, "new trans will store",
           trans   => 1, #new trans
           entries => 5, #new id
           records => 1,
           recyc   => 0,
           ids     => 5, #new id generated
           silo_id => 12,
           silo    => 1, #something in silo
        );

    $id = $trans->stow( "CHANGED mind", $id );
    is( $id, 5, "new trans new id still 5" );

    check( $store, "new trans will store overwrite",
           trans   => 1,
           entries => 5,
           records => 2,
           recyc   => 0,
           ids     => 5, #same id used
           silo_id => 12,
           silo    => 2, #one more silo entry though
       );

    $id = $trans->stow( "MEW NEW mind" );
    is( $id, 6, "new trans new id now 6" );

    check( $store, "new trans will store overwrite",
           trans   => 1,
           entries => 6, #new entry
           records => 3, 
           recyc   => 0,
           ids     => 6, #new id for new entry
           silo_id => 12,
           silo    => 3, #one more silo entry though
       );

    $trans->commit;

    is( $store->fetch( $id ), "MEW NEW mind", "transaction value" );

    check( $store, "new trans commit",
           trans   => 0,
           entries => 6,
           records => 2,
           recyc   => 0,
           ids     => 6, #same id used
           silo_id => 12,
           silo    => 2, #one more silo entry though
       );

    my $dir2 = tempdir( CLEANUP => 1 );
    my $store2 = Data::RecordStore->open_store( BASE_PATH => $dir2, MODE => $mode );
    my( @ids );
    for (1..10) {
        push @ids, $store2->stow( "x" x $_ );
    }
    my $t = $store2->start_transaction;
    for my $id (@ids) {
        $t->stow( "y" x ($id), $id );
    }
    check( $store2, "simple swap check before commit",
           trans   => 1,  #1 transaction
           entries => 10, #new entry
           records => 20,
           recyc   => 0,
           ids     => 10, #new id for new entry
           silo_id => 12,
           silo    => 20, # 10 stowed directly, 10 stowed in transaction
       );
    eval {
        $t->commit;
    };
    unlike( $@, qr/\S/, 'no commit error simple' );
    unlike( $@, qr/_swapout/, 'no swapout error simple' );
    check( $store2, "simple swap check after commit",
           trans   => 0,
           entries => 10, #new entry
           records => 10,
           recyc   => 0,
           ids     => 10, #new id for new entry
           silo_id => 12,
           silo    => 10, # initial stowed and no transactions
       );
    for (1..10) {
        is($store2->fetch( $_ ), 'y' x $_, "entry $_ after commit" ) ;
    }
    
    
    my $dir3 = tempdir( CLEANUP => 1 );
    my $store3 = Data::RecordStore->open_store( BASE_PATH => $dir3, MODE => $mode );
    
    ( @ids ) = ();
    for (1..10) {
        push @ids, $store3->stow( 'x' x $_ );  #10
    }
    $t = $store3->start_transaction;
    for my $id (@ids) {
        $t->stow( 'y' x $id, $id );   #20
    }
    for my $id (@ids) {
        $t->stow( 'z' x (4096+$id), $id );   #20 in 12, 10 in 13
    }
    
    for my $id (@ids) {
        $t->stow( 'q' x $id, $id );   #30 in 12, 10 in 13
    }
    check( $store3, "multimove swap check before commit",
           trans   => 1,  #1 transaction
           entries => 10, #new entry
           records => 40,
           recyc   => 0,
           ids     => 10, #new id for new entry
           silo_id => 12,
           silo    => 30, 
       );
    check( $store3, "multimove swap check before commit silo 13",
           trans   => 1,  #1 transaction
           entries => 10, #new entry
           records => 40,
           recyc   => 0,
           ids     => 10, #new id for new entry
           silo_id => 13,
           silo    => 10, 
       );
    eval {
        $t->commit;
    };

    unlike( $@, qr/\S/, 'no commit error multimove' );
    unlike( $@, qr/_swapout/, 'no swapout error multimove' );
    check( $store3, "multimove swap check after commit",
           trans   => 0,
           entries => 10, #new entry
           records => 10,
           recyc   => 0,
           ids     => 10, #new id for new entry
           silo_id => 12,
           silo    => 10, #10 in silo 4
        );
    check( $store3, "multimove swap check after commit silo 13",
           trans   => 0,
           entries => 10, #new entry
           records => 10,
           recyc   => 0,
           ids     => 10, #new id for new entry
           silo_id => 13,
           silo    => 0, #10 in silo 4
        );

    $store3->start_transaction;
    $store3->delete_record( 1 );
    check( $store3, "multimove swap check 2 before commit",
           trans   => 1,
           entries => 10, #new entry
           records => 10,           
           recyc   => 0,
           ids     => 10, #new id for new entry
           silo_id => 12,
           silo    => 10, 
        );
    $store3->commit_transaction;
    check( $store3, "multimove swap check after commit",
           trans   => 0,
           entries => 10, #new entry
           records => 9,           
           recyc   => 0,
           ids     => 10, #new id for new entry
           silo_id => 12,
           silo    => 9, #one was deleted
        );
    

    my $dir4 = tempdir( CLEANUP => 1 );
    my $store4 = Data::RecordStore->open_store( BASE_PATH => $dir, MODE => $mode );

    for (1..10) {
        push @ids, $store4->stow( 'x' x $_ );
    }

    $t = $store4->start_transaction;
    for my $id (@ids) {
        $t->stow( 'y' x $id, $id );
    }
    eval {
        $t->commit;
    };
    unlike( $@, qr/\S/, 'no commit error moar multimove' );
    unlike( $@, qr/_swapout/, 'no swapout error moar multimove' );

    $t = $store4->start_transaction;
    for my $id (@ids) {
        $t->stow( 'z' x $id, $id );
    }
    for my $id (@ids) {
        $t->stow( 'q' x $id, $id );
    }
    eval {
        $t->commit;
    };
    unlike( $@, qr/\S/, 'no commit error moar multimove' );
    unlike( $@, qr/_swapout/, 'no swapout error moar multimove' );

    $dir = tempdir( CLEANUP => 1 );
    $store = Data::RecordStore->open_store( BASE_PATH => $dir, MODE => $mode );
    $store->stow( "NOTOUCHY" );
    $store->stow( "DELME", 3 );
     $trans = $store->use_transaction;
    is( $trans, $store->use_transaction, "use transaction is same as current transaction" );
    $store->stow( "FREENY", 2 );
    is( $store->fetch(2), "FREENY", "returns value it has in transaction" );
    $store->delete_record( 3 );
    is( $store->fetch(3), undef, "returns undef for item deleted in transaction" );
    is( $store->fetch(1), "NOTOUCHY", "returns value not affected by transaction" );
    $store->rollback_transaction;
    is( $store->fetch(2), undef, "transaction value rolled back" );
    is( $store->fetch(3), 'DELME', "transaction deletion rolled back" );
    is( $store->fetch(1), "NOTOUCHY", "returns value not affected by transaction after rollback" );
    is( $store->_current_transaction, undef, "No current transaction after rollback" );
    $trans = $store->start_transaction();
    is( $trans, $store->use_transaction, "use transaction is same as current transaction" );
    $store->stow( "GOST", 3 );
    $store->commit_transaction();
    is( $store->fetch(3), "GOST", "transaction value committed" );

    {
        local( *STDERR );
        my $out;
        open( STDERR, ">>", \$out );
        $store->commit_transaction;
        like( $out, qr/No transaction in progress/, "no trasnaction to commit" );
        $out = '';
        $store->rollback_transaction;
        like( $out, qr/No transaction in progress/, "no trasnaction to commit" );
    }

    $store->start_transaction;
    $id = $store->stow( "x" x 8001 );
    is( $store->fetch( $id ), "x" x 8001, "fetched the 8001" );
    $store->delete_record( $id );
    is( $store->fetch( $id ), undef, "fetched the delted thing" );
    $store->stow( "x" x 8002, $id );
    is( $store->fetch( $id ), "x" x 8002, "fetched the 8002" );
    
    $id = $store->stow( "x" x 8187 );
    is( $store->fetch( $id ), "x" x 8187, "fetched the 8087" );

    $store->commit_transaction;
    is( $store->fetch( $id ), "x" x 8187, "fetched the 8087 after commit" );
    
} #test_suite
