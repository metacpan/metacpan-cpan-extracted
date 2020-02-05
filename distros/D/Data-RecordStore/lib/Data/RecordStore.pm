package Data::RecordStore;

#######################################################################
# The RecordStore is an index-value store that is composed of fixed   #
#     sized data silos to store its data, transaction info and        #
#     indexes. The silos are primarily binary data files so finding a #
#     record in them is as easy as multiplying the record size times  #
#     the index and performing a seek on the silo's file handle.      #
#                                                                     #
# Its primary subs are stow and fetch. Their description should       #
#     give a good feel for how the record store works in general.     #
#                                                                     #
# fetch :                                                             #
#     When fetch is called for a id, it uses its index silo to look   #
#     up which fixed record silo the data for that id is stored in    #
#     and what silo index it has.                                     #
#     The store then accesses that silo and gets the data it needs.   #
#     Silos use pack and unpack to store and retreive data.           #
#                                                                     #
# stow :                                                              #
#     When stow is called with data and an id, it picks a data        #
#     silo based on the size of the data. The silos are numbered      #
#     starting with 12. The size of the silo is 2^N where N is        #
#     the number of the silo. The smallest silo by default is 4096    #
#     bytes.                                                          #
#######################################################################


#
# The original that adheres the record store interface.
# namely
#   * open_store
#
#   * stow
#   * fetch
#   * delete_record
#   * next_id
#   * last_updated
#
#   * highest_entry_id
#
#   * lock
#   * unlock
#
#   * use_transaction
#   * commit_transaction
#   * rollback_transaction
#   * list_transactions
#   * empty
#

use strict;
use warnings;
no warnings 'numeric';
no warnings 'uninitialized';

use Fcntl qw( :flock SEEK_SET );
use File::Path qw(make_path);
use Data::Dumper;
use YAML;

use Data::RecordStore::Silo;
use Data::RecordStore::Transaction;

use vars qw($VERSION);

$VERSION = '6.06';
my $SILO_VERSION = '6.00';

use constant {
    # record state
    RS_ACTIVE         => 1,
    RS_DEAD           => 2,
    RS_IN_TRANSACTION => 3,

    TR_ACTIVE         => 1,
    TR_IN_COMMIT      => 2,
    TR_IN_ROLLBACK    => 3,
    TR_COMPLETE       => 4,

    DIRECTORY => 0,
    ACTIVE_TRANS_FILE => 1,
    MAX_FILE_SIZE => 2,
    MIN_SILO_ID => 3,
    INDEX_SILO  => 4,
    SILOS       => 5,
    TRANSACTION_INDEX_SILO  => 6,
    TRANSACTION => 7,
    HEADER_SIZE => 8,
    LOCK_FH     => 9,
    LOCKS       => 10,
    MAX_SILO_ID => 11,
};
#
# On disc block size : If the reads align with block sizes, the reads will go faster
#  however, there are some annoying things about finding out what that blocksize is.
#  (spoiler: it is currently either 4096 or 512 bytes and probably the former)
#
#  ways to determine block size :
#     sudo blockdev -getbsz /dev/sda1
#     lsblk -o NAME,MOUNTPOINT,FSTYPE,TYPE,SIZE,STATE,DISC-MAX,DISC-GRAN,PHY-SEC,MIN-IO,RQ-SIZE
#  and they disagree :(
#  using 4096 in any case. It won't be slower, though the space required could be 8 times are large.
#
#  note: this is only for the records, not for any indexes.
#

sub reopen_store {
    my( $cls, $dir ) = @_;
    my $cfgfile = "$dir/config.yaml";
    if( -e $cfgfile ) {
        my $lockfile = "$dir/LOCK";
        die "no lock file found" unless -e $lockfile;
        open my $lock_fh, '+<', $lockfile or die "$@ $!";
        flock( $lock_fh, LOCK_EX );

        my $lock_dir = "$dir/user_locks";
        my $trans_dir = "$dir/transactions";
        die "locks directory not found" unless -d $lock_dir;
        die "transaction directory not found" unless -d $trans_dir;
        
        my $cfg = YAML::LoadFile( $cfgfile );

        my $index_silo = Data::RecordStore::Silo->reopen_silo( "$dir/index_silo" );
        my $transaction_index_silo = Data::RecordStore::Silo->reopen_silo( "$dir/transaction_index_silo" );

        my $max_file_size = $cfg->{MAX_FILE_SIZE};
        my $min_file_size = $cfg->{MIN_FILE_SIZE};
        my $max_silo_id = int( log( $max_file_size ) / log( 2 ));
        $max_silo_id++ if 2 ** $max_silo_id < $max_file_size;
        my $min_silo_id = int( log( $min_file_size ) / log( 2 ));
        $min_silo_id++ if 2 ** $min_silo_id < $min_file_size;

        my $silo_dir = "$dir/data_silos";
        my $silos = [];
        for my $silo_id ($min_silo_id..$max_silo_id) {
            $silos->[$silo_id] = Data::RecordStore::Silo->reopen_silo( "$silo_dir/$silo_id" );
        }

        my $header = pack( 'ILL', 1,2,3 );
        my $header_size = do { use bytes; length( $header ) };

        my $store = bless [
            $dir,
            "$dir/ACTIVE_TRANS",
            $max_file_size,
            $min_silo_id,
            $index_silo,
            $silos,
            $transaction_index_silo,
            undef,
            $header_size, # the ILL from ILLa*
            $lock_fh,
            [],
            $max_silo_id,
        ], $cls;
        $store->_fix_transactions;
        flock( $lock_fh, LOCK_UN );
        return $store;
    }
    die "could not find record store in $dir";
} #reopen_store

sub open_store {
    my( $cls, @options ) = @_;
    if( @options == 1 ) {
        unshift @options, 'BASE_PATH';
    }
    my( %options ) = @options;
    my $dir = $options{BASE_PATH};
    unless( -d $dir ) {
        _make_path( $dir, 'base' );
    }
    my $max_file_size = $options{MAX_FILE_SIZE};
    $max_file_size = $Data::RecordStore::Silo::DEFAULT_MAX_FILE_SIZE unless $max_file_size;
    
    my $min_file_size = $options{MIN_FILE_SIZE};
    $min_file_size = $Data::RecordStore::Silo::DEFAULT_MIN_FILE_SIZE unless $min_file_size;
    if( $min_file_size > $max_file_size ) {
        die "MIN_FILE_SIZE cannot be more than MAX_FILE_SIZE";
    }
    my $max_silo_id = int( log( $max_file_size ) / log( 2 ));
    $max_silo_id++ if 2 ** $max_silo_id < $max_file_size;
    my $min_silo_id = int( log( $min_file_size ) / log( 2 ));
    $min_silo_id++ if 2 ** $min_silo_id < $min_file_size;
    my $lockfile = "$dir/LOCK";
    my $lock_fh;

    my $silo_dir = "$dir/data_silos";
    my $lock_dir = "$dir/user_locks";
    my $trans_dir = "$dir/transactions";
    
    if( -e $lockfile ) {
        open $lock_fh, '+<', $lockfile or die "$@ $!";
        flock( $lock_fh, LOCK_EX );
    }
    else {
        open $lock_fh, '>', $lockfile or die "$@ $!";
        flock( $lock_fh, LOCK_EX );
        $lock_fh->autoflush(1);
        print $lock_fh "LOCK\n";
        
        my $vers_file = "$dir/VERSION";
        if( -e $vers_file ) {
            die "Aborting open : lock file did not exist but version file did. This may mean a partial store was in here at some point in $dir.";
        }
        
        _make_path( $silo_dir, 'silo' );
        _make_path( $lock_dir, 'lock' );
        _make_path( $trans_dir, 'transaction' );
        
        open my $out, '>', "$dir/config.yaml";
        print $out <<"END";
VERSION: $VERSION
MAX_FILE_SIZE: $max_file_size
MIN_FILE_SIZE: $min_file_size
END
        close $out;
        
        open my $vers_fh, '>', $vers_file;
        print $vers_fh "$VERSION\n";
        close $vers_fh;
    }

    my $index_silo = Data::RecordStore::Silo->open_silo( "$dir/index_silo",
                                                         "ILL", #silo id, id in silo, last updated time
                                                         0,
                                                         $max_file_size );
    my $transaction_index_silo = Data::RecordStore::Silo->open_silo( "$dir/transaction_index_silo",
                                                                     "IL", #state, time
                                                                     0,
                                                                     $max_file_size );

    my $silos = [];

    for my $silo_id ($min_silo_id..$max_silo_id) {
        $silos->[$silo_id] = Data::RecordStore::Silo->open_silo( "$silo_dir/$silo_id",
                                                                 'ILLa*',  # status, id, data-length, data
                                                                 2 ** $silo_id,
                                                                 $max_file_size );
    }
    my $header = pack( 'ILL', 1,2,3 );
    my $header_size = do { use bytes; length( $header ) };

    my $store = bless [
        $dir,
        "$dir/ACTIVE_TRANS",
        $max_file_size,
        $min_silo_id,
        $index_silo,
        $silos,
        $transaction_index_silo,
        undef,
        $header_size, # the ILL from ILLa*
        $lock_fh,
        [],
        $max_silo_id,
    ], $cls;
    $store->_fix_transactions;
    flock( $lock_fh, LOCK_UN );
    return $store;
} #open_store

sub fetch {
    my( $self, $id, $no_trans ) = @_;
    my $trans = $self->[TRANSACTION];
    if( $trans && ! $no_trans ) {
        if( $trans->{state} != TR_ACTIVE ) {
            die "Transaction is in a bad state. Cannot fetch";
        }
        return $trans->fetch( $id );
    }

    $self->_read_lock;

    if( $id > $self->entry_count ) {
        return undef;
    }

    my( $silo_id, $id_in_silo ) = @{$self->[INDEX_SILO]->get_record($id)};
    if( $silo_id ) {
        my $ret = $self->[SILOS]->[$silo_id]->get_record( $id_in_silo );
        $self->_unlock;
        return substr( $ret->[3], 0, $ret->[2] );
    }

    $self->_unlock;
    return undef;
} #fetch

sub stow {
    my $self = $_[0];
    my $id   = $_[2];

    my $trans = $self->[TRANSACTION];
    if( $trans ) {
        return $trans->stow( $_[1], $id );
    }

    my $index = $self->[INDEX_SILO];
    $self->_write_lock;

    $index->ensure_entry_count( $id );
    if( defined $id && $id < 1 ) {
        die "The id must be a supplied as a positive integer";
    }
    my( $old_silo_id, $old_id_in_silo );
    if( $id > 0 ) {
        ( $old_silo_id, $old_id_in_silo ) = @{$index->get_record($id)};
    }
    else {
        $id = $index->next_id;
    }

    my $data_write_size = do { use bytes; length $_[1] };
    my $new_silo_id = $self->silo_id_for_size( $data_write_size );
    my $new_silo = $self->[SILOS][$new_silo_id];

    my $new_id_in_silo = $new_silo->push( [RS_ACTIVE, $id, $data_write_size, $_[1]] );

    $index->put_record( $id, [$new_silo_id,$new_id_in_silo,time] );

    if( $old_silo_id ) {
        $self->_vacate( $old_silo_id, $old_id_in_silo );
    }

    $self->_unlock;
    return $id;
} #stow

sub next_id {
    return shift->[INDEX_SILO]->next_id;
} #next_id

sub delete_record {
    my( $self, $del_id ) = @_;
    $self->_write_lock;
    my $trans = $self->[TRANSACTION];
    if( $trans ) {
        $self->_unlock;
        return $trans->delete_record( $del_id );
    }

    if( $del_id > $self->[INDEX_SILO]->entry_count ) {
        warn "Tried to delete past end of records";
        $self->_unlock;
        return undef;
    }
    my( $old_silo_id, $old_id_in_silo ) = @{$self->[INDEX_SILO]->get_record($del_id)};
    $self->[INDEX_SILO]->put_record( $del_id, [0,0,time] );

    if( $old_silo_id ) {
        $self->_vacate( $old_silo_id, $old_id_in_silo );
    }
    $self->_unlock;
} #delete_record

# locks the given lock names
# they are locked in order to prevent deadlocks.
sub lock {
    my( $self, @locknames ) = @_;

    my( %previously_locked ) = ( map { $_ => 1 } @{$self->[LOCKS]} );

    if( @{$self->[LOCKS]} && grep { ! $previously_locked{$_} } @locknames ) {
        die "Data::RecordStore->lock cannot be called twice in a row without unlocking between";
    }
    my $fhs = [];

    my $failed;

    for my $name (sort @locknames) {
        next if $previously_locked{$name}++;
        my $lockfile = "$self->[DIRECTORY]/user_locks/$name";
        my $fh;
        if( -e $lockfile ) {
            unless( open ( $fh, '+<', $lockfile ) ) {
                $failed = 1;
                last;
            }
            flock( $fh, LOCK_EX ); #WRITE LOCK
        }
        else {
            unless( open( $fh, '>', $lockfile ) ) {
                $failed = 1;
                last;
            }
            flock( $fh, LOCK_EX ); #WRITE LOCK
            $fh->autoflush(1);
            print $fh '';
        }
        push @$fhs, $fh;
    }

    if( $failed ) {
        # it must be able to lock all the locks or it fails
        # if it failed, unlock any locks it managed to get
        for my $fh (@$fhs) {
            flock( $fh, LOCK_UN );
        }
        die "Data::RecordStore->lock : lock failed";
    } else {
        $self->[LOCKS] = $fhs;
    }

} #lock

# unlocks all locks
sub unlock {
    my $self = shift;
    my $fhs = $self->[LOCKS];

    for my $fh (@$fhs) {
        flock( $fh, LOCK_UN );
    }
    @$fhs = ();
} #unlock

sub use_transaction {
    my $self = shift;
    if( $self->[TRANSACTION] ) {
        warn __PACKAGE__."->use_transaction : already in transaction";
        return $self->[TRANSACTION];
    }
    $self->_write_lock;
    my $tid = $self->[TRANSACTION_INDEX_SILO]->push( [TR_ACTIVE, time] );
    $self->_unlock;
    my $tdir = "$self->[DIRECTORY]/transactions/$tid";
    make_path( $tdir, { error => \my $err } );
    if( @$err ) { die join( ", ", map { values %$_ } @$err ) }

    $self->[TRANSACTION] = Data::RecordStore::Transaction->create( $self, $tdir, $tid );
    return $self->[TRANSACTION];
} #use_transaction

sub commit_transaction {
    my $self = shift;
    $self->_write_lock;
    my $trans = $self->[TRANSACTION];
    unless( $trans ) {
        die __PACKAGE__."->commit_transaction : no transaction to commit";
    }
    my $trans_file = $self->[ACTIVE_TRANS_FILE];
    open my $trans_fh, '>', $trans_file;
    print $trans_fh " ";
    close $trans_fh;

    $trans->commit;
    delete $self->[TRANSACTION];
    unlink $trans_file;
    $self->_unlock;
} #commit_transaction

sub rollback_transaction {
    my $self = shift;
    $self->_write_lock;
    my $trans = $self->[TRANSACTION];
    unless( $trans ) {
        die __PACKAGE__."->rollback_transaction : no transaction to roll back";
    }
    my $trans_file = $self->[ACTIVE_TRANS_FILE];
    open my $trans_fh, '>', $trans_file;
    print $trans_fh " ";
    close $trans_fh;
    $trans->rollback;
    delete $self->[TRANSACTION];
    unlink $trans_file;
    $self->_unlock;
} #rollback_transaction

sub entry_count {
    return shift->[INDEX_SILO]->entry_count;
}

sub index_silo {
    return shift->[INDEX_SILO];
}

sub max_file_size {
    return shift->[MAX_FILE_SIZE];
}

sub silos {
    return [@{shift->[SILOS]}];
}

sub transaction_silo {
    return shift->[TRANSACTION_INDEX_SILO];
}

sub silos_entry_count {
    my $self = shift;
    my $silos = $self->silos;
    my $count = 0;
    for my $silo (grep {defined} @$silos) {
        $count += $silo->entry_count;
    }
    return $count;
}

sub record_count {
    goto &active_entry_count;
}

sub active_entry_count {
    my $self = shift;
    my $index = $self->index_silo;
    my $count = 0;
    for(1..$self->entry_count) {
        my( $silo_id ) = @{$index->get_record( $_ )};
        ++$count if $silo_id;
    }
    return $count;
}

sub detect_version {
    my( $cls, $dir ) = @_;
    my $ver_file = "$dir/VERSION";
    my $source_version;
    if ( -e $ver_file ) {
        open( my $FH, "<", $ver_file );
        $source_version = <$FH>;
        chomp $source_version;
        close $FH;
    } elsif( -e "$dir/STORE_INDEX" ) {
        return 1;
    }
    return $source_version;
} #detect_version



sub _vacate {
    my( $self, $silo_id, $id_to_empty ) = @_;
    my $silo = $self->[SILOS][$silo_id];
    my $rc = $silo->entry_count;
    if( $id_to_empty == $rc ) {
        $silo->pop;
    } else {
        while( $rc > $id_to_empty ) {
            my( $state, $id ) = (@{$silo->get_record( $rc, 'IL' )});
            if( $state == RS_ACTIVE ) {
                $silo->copy_record($rc,$id_to_empty);
                $self->[INDEX_SILO]->put_record( $id, [$silo_id,$id_to_empty], "IL" );
                $silo->pop;
                return;
            }
            elsif( $state == RS_DEAD ) {
                $silo->pop;
            }
            else {
                return;
            }
            $rc--;
        }
    }
} #_vacate

sub silo_id_for_size {
    my( $self, $data_write_size ) = @_;

    my $write_size = $self->[HEADER_SIZE] + $data_write_size;

    my $silo_id = int( log( $write_size ) / log( 2 ) );
    $silo_id++ if 2 ** $silo_id < $write_size;
    $silo_id = $self->[MIN_SILO_ID] if $silo_id < $self->[MIN_SILO_ID];
    return $silo_id;
} #silo_id_for_size

# ---------------------- private stuffs -------------------------

sub _make_path {
    my( $dir, $msg ) = @_;
    make_path( $dir, { error => \my $err } );
    if( @$err ) {
        die "unable to make $msg directory.". join( ", ", map { $_->{$dir} } @$err );
    }
}

sub _read_lock {
    my $self = shift;
    flock( $self->[LOCK_FH], LOCK_SH );
    $self->_fix_transactions;
}

sub _unlock {
    my( $self ) = @_;
    flock( $self->[LOCK_FH], LOCK_UN );
}

sub _write_lock {
    my $self = shift;
    flock( $self->[LOCK_FH], LOCK_EX );
    $self->_fix_transactions;
}

sub _fix_transactions {
    my $self = shift;
    # check the transactions
    # if the transaction is in an incomplete state, fix it. Since the store is write locked
    # during transactions, the lock has expired if this point has been reached.
    # that means the process that made the lock has fallen.
    #
    # of course, do a little experiment to test this with two processes and flock when
    # one exits before unflocking.
    #
    my $transaction_index_silo = $self->transaction_silo;
    my $last_trans = $transaction_index_silo->entry_count;
    while( $last_trans ) {
        my( $state ) = @{$transaction_index_silo->get_record( $last_trans )};
        my $tdir = "$self->[DIRECTORY]/transactions/$last_trans";
        if( $state == TR_IN_ROLLBACK ||
                $state == TR_IN_COMMIT ) {
            # do a full rollback
            # load the transaction
            my $trans = Data::RecordStore::Transaction->create( $self, $tdir, $last_trans );
            $trans->rollback;
            $transaction_index_silo->pop;
        }
        elsif( $state == TR_COMPLETE ) {
            $transaction_index_silo->pop;
        }
        else {
            return;
        }
        $last_trans--;
    }

} #_fix_transactions


"I became Iggy because I had a sadistic boss at a record store. I'd been in a band called the Iguanas. And when this boss wanted to embarrass and demean me, he'd say, 'Iggy, get me a coffee, light.' - Iggy Pop";

__END__

=head1 NAME

 Data::RecordStore - Simple store for text and byte data

=head1 SYNPOSIS

 use Data::RecordStore;

 $store = Data::RecordStore->init_store( DIRECTORY => $directory, MAX_FILE_SIZE => 20_000_000_000 );
 $data = "TEXT OR BYTES";

 # the first record id is 1
 my $id = $store->stow( $data );

 my $val = $store->fetch( $some_id );

 my $count = $store->entry_count;

 $store->lock( qw( FEE FIE FOE FUM ) ); # lock blocks, may not be called until unlock.

 $store->unlock; # unlocks all

 $store->delete_record( $id_to_remove ); #deletes the old record

 $reopened_store = Data::RecordStore->open_store( $directory );

=head1 DESCRIPTION

Data::RecordStore is a simple way to store serialized text or byte data.
It is written entirely in perl with no non-core dependencies.
It is designed to be both easy to set up and easy to use.

It adheres to a RecordStore interface so other implementations exist using
other technologies rather than simple binary file storage.

Transactions (see below) can be created that stow records.
They come with the standard commit and rollback methods. If a process dies
in the middle of a commit or rollback, the operation can be reattempted.
Incomplete transactions are obtained by the store's 'list_transactions'
method.

Data::RecordStore operates directly and instantly on the file system.
It is not a daemon or server and is not thread safe. It can be used
in a thread safe manner if the controlling program uses locking mechanisms,
including the locks that the store provides.

=head1 METHODS

=head2 open_store( options )

Constructs a data store according to the options.

Options

=over 2

=item BASE_PATH

=item MIN_FILE_SIZE - default is 4096

=item MAX_FILE_SIZE - default is 2 gigs

=head2 reopen_store( directory )

Opens the existing store in the given directory.

=head2 fetch( id )

Returns the record associated with the ID. If the ID has no
record associated with it, undef is returned.

=head2 stow( data, optionalID )

This saves the text or byte data to the record store.
If an id is passed in, this saves the data to the record
for that id, overwriting what was there.
If an id is not passed in, it creates a new record store.

Returns the id of the record written to.

=head2 next_id

This sets up a new empty record and returns the
id for it.

=head2 delete_record( id )

Removes the entry with the given id from the store, freeing up its space.
It does not reuse the id.

=head2 lock( @names )

Adds an advisory (flock) lock for each of the unique names given.
This may not be called twice in a row without an unlock in between
and will die if that happens.

=head2 unlock

Unlocks all names locked by this thread

=head2 use_transaction()

Returns the current transaction. If there is no
current transaction, it creates one and returns it.

=head2 commit_transaction()

Commits the current transaction, if any.

=head2 rollback_transaction()

Rolls back the current transaction, if any.

=head2 entry_count

Returns how many record ids exist.

=head2 index_silo

Returns the index silo for this store. 
This method is not part of the record store interface.

=head2 max_file_size

Returns the max file size of any silo in bytes.
This method is not part of the record store interface.

=head2 silos

Returns a list of data silo objects where the data silo record
size is 2**index position. This means that the beginning of the list
will have undefs as there is a minimum silo size.
This method is not part of the record store interface.

=head2 transaction_silo

Returns the transaction silo for this store.
This method is not part of the record store interface.

=head2 active_entry_count

Returns how many record ids exist that have silo entries.
This method is not part of the record store interface.

=head2 silos_entry_count

Returns the number of entries in the data silos.

=head2 detect_version( $dir )

Tries to detect the version of the Data::RecordStore in
the given directory, if any.

=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2015-2020 Eric Wolf. All rights reserved.
       This program is free software; you can redistribute it
       and/or modify it under the same terms as Perl itself.

=head1 VERSION
       Version 6.06  (Jan, 2020))

=cut


# ------------- for DEBUG ---------

sub _show_silo {
    my( $self, $txt, $temp ) = @_;

    my( @pairs ) = (['index',$self->[INDEX_SILO],"IL"], map { ["record $_", $self->[SILOS][$_],'IL'] } ($self->[MIN_SILO_ID]..$self->[MAX_SILO_ID]) );
    my $trans = $self->[TRANSACTION];
    if( $trans ) {
        push @pairs, ['trans stack',$trans->{stack_silo}];
    }
    print STDERR "\n";
    for my $pair (@pairs) {
        my( $title, $silo, $templ ) = @$pair;
        if( my $ec = $silo->entry_count ) {
            print STDERR " $title : $txt ". join(",", map { " ($_)[".join(",",@{$silo->get_record($_,$templ)} ).']' } (1..$ec) )."\n";
        }
    }
}
