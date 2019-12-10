package Data::RecordStore::Transaction;

use strict;
use warnings;
no warnings 'numeric';
no warnings 'uninitialized';

use File::Path qw(make_path remove_tree);

use vars qw($VERSION);
$VERSION = '0.01';

use constant {
    RS_ACTIVE    => 1,
    RS_DEAD      => 2,
    RS_IN_TRANSACTION => 3,

    TR_ACTIVE         => 1,
    TR_IN_COMMIT      => 2,
    TR_IN_ROLLBACK    => 3,
    TR_COMPLETE       => 4,
};

#######################################################################
# Transactions use a stack silo to record what happens                #
# to entries affected by the transaction.                             #
#                                                                     #
# When an entry is deleted in a transaction, the stack silo           #
# marks that entry for deletion.                                      #
#                                                                     #
# When entry data is stowed in a transaction, the transaction         #
# stores the data in the store. It marks this location as well        #
# as the original location of the entry data (if any).                #
#                                                                     #
# The stack silo keeps only the last record for an entry, so          #
# if an entry is stowed, then deleted, then stowed again, only        #
# the most recent action is recorded. The stack silo contains the     #
# id, the state, the original silo id (if there is one ),             #
# the original idx in the silo (if there is one ), the silo id that   #
# the transaction stored data in, the idx in the silo that the        #
# the transaction stored data in                                      #
#                                                                     #
# When fetch is used from a transaction, the stack silo is checked    #
# to see if there was any action on the fetched id. If so, it returns #
# the transactional value.                                            #
#######################################################################


sub create {
    my( $cls, $store, $dir, $id ) = @_;

    # stack of id used
    my $stack_silo_dir = "$dir/stack_silo";
    make_path( $stack_silo_dir, { error => \my $err } );
    if( @$err ) { die join( ", ", map { values %$_ } @$err ) }

    my $stack_silo = Data::RecordStore::Silo->open_silo(
        $stack_silo_dir,
        'ILILIL', # action, id, trans silo id, trans id in silo, orig silo id, orig id in silo
        0,
        $store->max_file_size );

    return bless {
        directory  => $dir,
        id         => $id,
        stack_silo => $stack_silo,
        changes => {},
        store      => $store,
        state      => TR_ACTIVE,
    }, $cls;

} #create

sub commit {
    my $self = shift;

    my $store = $self->{store};

    $store->transaction_silo->put_record( $self->{id}, [TR_IN_COMMIT], 'I' );
    $self->{state} = TR_IN_COMMIT;

    my $store_index = $store->index_silo;
    my $store_silos = $store->silos;

    my $stack_silo = $self->{stack_silo};
    my $changes = $self->{changes};
    for my $id (sort { $a <=> $b } keys %$changes) {
        my( $action, $rec_id, $orig_silo_id, $orig_idx_in_silo, $trans_silo_id, $trans_id_in_silo ) = @{$changes->{$id}};
        if( $action == RS_ACTIVE ) {
            $store_silos->[$trans_silo_id]->put_record( $trans_id_in_silo, [ RS_ACTIVE ], 'I' );
            $store_index->put_record( $rec_id, [$trans_silo_id,$trans_id_in_silo,time] );
        }
        else {
            my( $s_id, $id_in_s ) = @{$store_index->get_record( $rec_id )};
            if( $s_id ) {
                $store->silos->[$s_id]->put_record( $id_in_s, [RS_DEAD], 'I' );
            }
            $store_index->put_record( $rec_id, [0,0,time] );
        }
    }
    $store->transaction_silo->put_record( $self->{id}, [TR_COMPLETE], 'I' );

    # this is sort of linting. The transaction is complete, but this cleans up any records marked deleted.
    for my $id (sort { $a <=> $b } keys %$changes) {
        my( $action, $rec_id, $orig_silo_id, $orig_idx_in_silo ) = @{$changes->{$id}};
        if( $action == RS_DEAD && $orig_silo_id ) {
            $store->_vacate( $orig_silo_id, $orig_idx_in_silo );
        }
    }
} #commit

sub rollback {
    my $self = shift;

    my $store = $self->{store};
    my $index = $store->index_silo;

    $store->transaction_silo->put_record( $self->{id}, [TR_IN_ROLLBACK], 'I' );
    $self->{state} = TR_IN_ROLLBACK;

    # [RS_ACTIVE, $id, $orig_silo_id, $orig_id_in_silo, $trans_silo_id, $trans_id_in_silo];
    # [RS_DEAD  , $id, $orig_silo_id, $orig_id_in_silo, 0, 0];
    
    # go and mark dead any temporary stows
    my $stack_silo = $self->{stack_silo};
    my $count = $stack_silo->entry_count;

    # go backwards to remove items that may have been partially created.
    for my $stack_id (reverse(1..$count)) {
        my( $action, $rec_id, $orig_silo_id, $id_in_orig_silo, $trans_silo_id, $trans_id_in_silo ) = @{$stack_silo->get_record( $stack_id )};
        my( $reported_silo_id, $id_reported_silo ) = @{$index->get_record( $rec_id )};
        if( $reported_silo_id != $orig_silo_id || $id_reported_silo != $id_in_orig_silo ) {
            $index->put_record( $rec_id, [$orig_silo_id,$id_in_orig_silo,time] );
        }
        if( $trans_silo_id ) {
            $store->_vacate( $trans_silo_id, $trans_id_in_silo );
        }
    }

    $store->transaction_silo->put_record( $self->{id}, [TR_COMPLETE], 'I' );
} #rollback

sub fetch {
    my( $self, $id ) = @_;

    my $store = $self->{store};

    my $changes = $self->{changes};
    if( my $rec = $changes->{$id} ) {
        my( $action, $rec_id, $a, $b, $trans_silo_id, $trans_id_in_silo ) = @$rec;    
        if( $action == RS_ACTIVE ) {
            my $ret = $store->silos->[$trans_silo_id]->get_record( $trans_id_in_silo );
            return substr( $ret->[3], 0, $ret->[2] );
        }
        return undef;
    }
    return $store->fetch( $id, 'no-trans' );
} #fetch

#####################################################################################################################
# given data and id,                                                                                                #
#                                                                                                                   #
#  uses the data size to find the appropriate silo id (new-silo-id) to store the data.                              #
#                                                                                                                   #
#  looks up the original silo-id, index-in-silo from the stores index,                                              #
#    which may or not exist                                                                                         #
#                                                                                                                   #
#  push the new data value into the store silo with the new-silo-id from above                                      #
#                                                                                                                   #
#  sees if the id already has an entry in the stack silo                                                            #
#     - if yes, it updates it to include STOW,id,new_silo_id,new_idx_in_silo,$original-silo-id,original-idx-in-silo #
#     - if no, pushes on to it to STOW,id,new_silo_id,new_idx_in_silo,$original-silo-id,original-idx-in-silo        #
#####################################################################################################################
sub stow {
    my $self = $_[0];
    my $id   = $_[2];

    my $store = $self->{store};
    if( $id == 0 ) {
        $id = $store->next_id;
    }

    my $data_write_size = do { use bytes; length( $_[1] ) };
    my $trans_silo_id = $store->silo_id_for_size( $data_write_size );

    my $trans_silo = $store->silos->[$trans_silo_id];
    my( $orig_silo_id, $orig_id_in_silo ) = @{$store->index_silo->get_record($id)};
    my $trans_id_in_silo = $trans_silo->push( [RS_IN_TRANSACTION, $id, $data_write_size, $_[1]] );

    my $stack_silo = $self->{stack_silo};
    my $changes = $self->{changes};
    # if( my $rec = $changes->{$id} ) {
    #     my( $action, $rec_id, $a, $b, $old_trans_silo_id, $old_idx_in_trans_silo ) = @$rec;
    #     if( $old_trans_silo_id ) {
    #         my $old_trans_silo = $store->silos->[$old_trans_silo_id];
    #         $old_trans_silo->put_record( $old_idx_in_trans_silo, [RS_DEAD], 'I' );
    #     }
    # }
    my $update = [RS_ACTIVE,$id,$orig_silo_id,$orig_id_in_silo,$trans_silo_id,$trans_id_in_silo];
    $changes->{$id} = $update;
    $stack_silo->push( $update );
    return $id;
} #stow

sub delete_record {
    my( $self, $id ) = @_;
    
    my( $orig_silo_id, $orig_id_in_silo ) = @{$self->{store}->index_silo->get_record($id)};
    
    my $stack_silo = $self->{stack_silo};
    my $changes = $self->{changes};

#    if( my $rec = $changes->{$id} ) {
#        my( $action, $rec_id, $a, $b, $old_trans_silo_id, $old_idx_in_trans_silo ) = @$rec;
#        if( $old_trans_silo_id ) {
#            my $old_trans_silo = $self->{store}->silos->[$old_trans_silo_id];
#            $old_trans_silo->put_record( $old_idx_in_trans_silo, [RS_DEAD], 'I' );
#        }
#    }
    my $update = [RS_DEAD,$id,$orig_silo_id,$orig_id_in_silo,0,0];
    $changes->{$id} = $update;
    $stack_silo->push( $update );

} #delete_record

"I think there comes a time when you start dropping expectations. Because the world doesn't owe you anything, and you don't owe the world anything in return. Things, feelings, are a very simple transaction. If you get it, be grateful. If you don't, be alright with it. - Fawad Khan";

__END__

=head1 NAME

 Data::RecordStore::Transaction - Transaction support for Data::RecordStore

=head1 DESCRIPTION

This is used by Data::RecordStore and is not meant for use outside of it.

=head1 METHODS

=head2 create

=head2 commit

=head2 rollback

=head2 fetch( id )

Returns the record associated with the ID. If the ID has no
record associated with it, undef is returned.

=head2 stow( data, optionalID )

This saves the text or byte data to the record store.
If an id is passed in, this saves the data to the record
for that id, overwriting what was there.
If an id is not passed in, it creates a new record store.

Returns the id of the record written to.

=head2 delete_record( id )

Removes the entry with the given id from the store, freeing up its space.
It does not reuse the id.


=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2015-2019 Eric Wolf. All rights reserved.
       This program is free software; you can redistribute it
       and/or modify it under the same terms as Perl itself.

=head1 VERSION
       Version 0.01  (Oct, 2019))

=cut
