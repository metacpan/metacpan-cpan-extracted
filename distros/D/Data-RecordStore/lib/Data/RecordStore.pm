package Data::RecordStore;

=head1 NAME

 Data::RecordStore - Simple and fast record based data store

=head1 SYNPOSIS

 use Data::RecordStore;

 $store = Data::RecordStore->open_store( $directory );
 $data = "TEXT OR BINARY DATA";

 ### Without transactions ###

 my $id = $store->stow( $data );

 my $new_or_recycled_id = $store->next_id;
 $store->stow( $new_data, $new_or_recycled_id );

 my $val = $store->fetch( $some_id );

 my $count = $store->entry_count;

 $store->delete_record( $del_id );

 $store->recycle_id( $del_id );

 my $has_id = $store->has_id( $someother_id );

 $store->empty_recycler; #all recycled ids are gone

 $store->empty; # clears out store completely



 ### Using Transactions ###

 my $transaction = $store->create_transaction;

 print join(",", $transaction->get_update_time,
                 $transaction->get_process_id,
                 $transaction->get_state,
                 $transaction->get_id );

 my $new_id = $transaction->stow( $data );

 my $new_or_reused_id = $store->next_id;

 $transaction->stow( "MORE DATA", $new_or_reused_id );

 $transaction->delete_record( $someid );

 $transaction->recycle_id( $dead_id );

 if( $is_good ) {
    $transaction->commit;
 } else {
    $transaction->rollback;
 }


 ### Transaction maintenance ###

 # Get a list of transactions that are old and probably stale.
 for my $trans ($store->list_transactions) {

   next if $trans->get_udpate_time > $too_old;

   if( $trans->get_state == Data::RecordStore::Transaction::TRA_IN_COMMIT
     || $trans->get_state == Data::RecordStore::Transaction::TRA_CLEANUP_COMMIT )
   {
      $trans->commit;
   }
   elsif( $trans->get_state == Data::RecordStore::Transaction::TRA_IN_ROLLBACK
     || $trans->get_state == Data::RecordStore::Transaction::TRA_CLEANUP_ROLLBACK )
   {
      $trans->rollback;
   }
   elsif( $trans->get_state == Data::RecordStore::Transaction::TRA_ACTIVE )
   {
      # commit or rollback, depending on preference
   }
 }


=head1 DESCRIPTION

A simple and fast way to store arbitrary text or byte data.
It is written entirely in perl with no non-core dependencies.
It is designed to be both easy to set up and easy to use.

Transactions allow the RecordStore to protect data.
Transactions can collect stow, delete_record and recycle_id actions.
Data stowed this way is stored in the record store, but indexed to
only by the transaction. Upon a transaction commit, the indexes
are updated and discarded data removed. Destructive actions are
only performed once the transaction updates the indexes.

Data is stored in fixed record file silos. This applies
to index data, recycling data, payload data and transaction data.
These silos are self vaccuuming. Entries that are removed either
by deletion or recycling have their space in the file replaced
by a live entry.

This is not a server or daemon, this is a direct operation on
the file system. Only meta data such as directories, file location
and fixed calculated values are stored as state. That means this
is not thread safe. It can be used in a thread safe manner if
a program using it provides locking mechanisms.


=head1 LIMITATIONS

Data::RecordStore is not thread safe. Thread coordination
and locking can be done on a level above Data::RecordStore.

=cut

use strict;
use warnings;

use Fcntl qw( SEEK_SET LOCK_EX LOCK_UN );
use File::Path qw(make_path);
use Data::Dumper;

use vars qw($VERSION);

$VERSION = '3.17';

use constant {
    DIRECTORY    => 0,
    RECORD_INDEX => 1,
    RECYC_SILO   => 2,
    SILOS        => 3,
    VERSION      => 4,
    TRANS_RECORD => 5,

    RECORD_SIZE      => 1,
    FILE_SIZE        => 2,
    FILE_MAX_RECORDS => 3,
    TMPL             => 4,

    TRA_ACTIVE           => 1, # transaction has been created
    TRA_IN_COMMIT        => 2, # commit has been called, not yet completed
    TRA_IN_ROLLBACK      => 3, # commit has been called, has not yet completed
    TRA_CLEANUP_COMMIT   => 4, # everything in commit has been written, TRA is in process of being removed
    TRA_CLEANUP_ROLLBACK => 5, # everything in commit has been written, TRA is in process of being removed
    TRA_DONE             => 6, # transaction complete. It may be removed.
};


=head1 METHODS

=head2 open_store( directory )

Takes a single argument - a directory, and constructs the data store in it.
The directory must be writeable or creatible. If a RecordStore already exists
there, it opens it, otherwise it creates a new one.

=cut

sub open_store {
    my $directory = pop @_;
    my $pkg = shift @_ || 'Data::RecordStore';

    # directory structure
    #   root/VERSION <-- version file
    #   root/RECORD_INDEX_SILO <-- record index silo directory
    #   root/RECYC_SILO        <-- recycle silo directory
    #   root/silos/            <-- directory for silo directories

    
    make_path( "$directory/silos", { error => \my $err } );
    if( @$err ) {
        my( $err ) = values %{ $err->[0] };
        die $err;
    }
    my $record_index_directory = "$directory/RECORD_INDEX_SILO";

    #
    # Find the version of the database.
    #
    my $version;
    my $version_file = "$directory/VERSION";
    my $FH;
    if( -e $version_file ) {
        CORE::open $FH, "<", $version_file;
        $version = <$FH>;
        chomp $version;

        if( $version < 3.1 ) {
            die "A database was found in $directory with version $version. Please run the record_store_convert program to upgrade to version $VERSION.";
        }
    }
    else {
        #
        # a version file needs to be created. if the database
        # had been created and no version exists, assume it is
        # version 1.
        #
        if( -e $record_index_directory ) {
            die "A database was found in $directory with no version information and is assumed to be an old format. Please run the record_store_convert program.";
        }
        $version = $VERSION;
        CORE::open $FH, ">", $version_file;
        print $FH "$version\n";
    }
    close $FH;

    my $self = [
        $directory,
        Data::RecordStore::Silo->open_silo( "IL", $record_index_directory ),
        Data::RecordStore::Silo->open_silo( "L", "$directory/RECYC_SILO" ),
        [],
        $version,
#        $transaction_record,
    ];

    bless $self, ref( $pkg ) || $pkg;

} #open_store

=head2 create_transaction()

Creates and returns a transaction object

=cut

sub create_transaction {
    my $self = shift;
    Data::RecordStore::Transaction->_create( $self );
}

=head2 list_transactions

Returns a list of currently existing transaction objects that are not marked TRA_DONE.

=cut

sub list_transactions {
    my $self = shift;
    my $trans_directory = Data::RecordStore::Silo->open_silo( "ILLI", "$self->[DIRECTORY]/TRANS/META" );
    my @trans;
    my $items = $trans_directory->entry_count;
    for( my $trans_id=$items; $trans_id > 0; $trans_id-- ) {
        my $data = $trans_directory->get_record( $trans_id );
        my $trans = Data::RecordStore::Transaction->_create( $self, $data );
        if( $trans->get_state == TRA_DONE ) {
            $trans_directory->pop; #its done, remove it
        } else {
            push @trans, $trans;
        }
    }
    @trans;
}

=head2 stow( data, optionalID )

This saves the text or byte data to the record store.
If an id is passed in, this saves the data to the record
for that id, overwriting what was there.
If an id is not passed in, it creates a new record store.

Returns the id of the record written to.

=cut

sub stow {
    my( $self, $data, $id ) = @_;

    $id //= $self->next_id;

    $self->_ensure_entry_count( $id ) if $id > 0;

    die "ID must be a positive integer" if $id < 1;

    my $uue = $data =~ /\0/;
    if( $uue ) {
        $data = pack 'u', $data;
    }

    my $save_size = do { use bytes; length( $data ); };

    # tack on the size of the id (a long + an int or 12 bytes) to the byte count
    $save_size += 12;
    my( $current_silo_id, $current_id_in_silo, $old_silo, $needs_swap );
    if( $self->[RECORD_INDEX]->entry_count > $id ) {

        ( $current_silo_id, $current_id_in_silo ) = @{ $self->[RECORD_INDEX]->get_record( $id ) };

        #
        # Check if this record had been saved before, and that the
        # silo is was in has a large enough record size.
        #
        if ( $current_silo_id ) {
            $old_silo = $self->_get_silo( $current_silo_id );

            warn "record '$id' references silo '$current_silo_id' which does not exist" unless $old_silo;

            # if the data isn't too big or too small for the table, keep it where it is and return
            if ( $old_silo->[RECORD_SIZE] >= $save_size && $old_silo->[RECORD_SIZE] < 3 * $save_size ) {
                $old_silo->put_record( $current_id_in_silo, [$id,$uue,$data] );
                return $id;
            }

            #
            # the old silo was not big enough (or missing), so remove its record from
            # there, compacting it if possible
            #
            $needs_swap = 1;
        } #if this already had been saved before
    }

    my $silo_id = 1 + int( log( $save_size ) );

    my $silo = $self->_get_silo( $silo_id );

    my $id_in_silo = $silo->next_id;

    $self->[RECORD_INDEX]->put_record( $id, [ $silo_id, $id_in_silo ] );

    $silo->put_record( $id_in_silo, [ $id, $uue, $data ] );

    if( $needs_swap ) {
        $self->_swapout( $old_silo, $current_silo_id, $current_id_in_silo );
    }

    $id;
} #stow

=head2 fetch( id )

Returns the record associated with the ID. If the ID has no
record associated with it, undef is returned.

=cut
sub fetch {
    my( $self, $id ) = @_;

    return undef if $id > $self->[RECORD_INDEX]->entry_count;

    my( $silo_id, $id_in_silo ) = @{ $self->[RECORD_INDEX]->get_record( $id ) };
    return undef unless $silo_id;

    my $silo = $self->_get_silo( $silo_id );

    # skip the included id, just get the data
    ( undef, my $uue, my $data ) = @{ $silo->get_record( $id_in_silo ) };

    if( $uue ) {
        $data = unpack "u", $data;
    }

    $data;
} #fetch

=head2 entry_count

Returns how many active ids have been assigned in this store.
If an ID was assigned but not used, it still counts towards
the number of entries.

=cut
sub entry_count {
    my $self = shift;
    $self->[RECORD_INDEX]->entry_count - $self->[RECYC_SILO]->entry_count;
} #entry_count

=head2 delete_record( id )

Removes the entry with the given id from the store, freeing up its space.
It does not reuse the id.

=cut

sub delete_record {
    my( $self, $del_id ) = @_;
    my( $from_silo_id, $current_id_in_silo ) = @{ $self->[RECORD_INDEX]->get_record( $del_id ) };

    return unless $from_silo_id;

    my $from_silo = $self->_get_silo( $from_silo_id );
    $self->[RECORD_INDEX]->put_record( $del_id, [ 0, 0 ] );
    $self->_swapout( $from_silo, $from_silo_id, $current_id_in_silo );
    1;
} #delete_record

=head2 has_id( id )

  Returns true if an record with this id exists in the record store.

=cut
sub has_id {
    my( $self, $id ) = @_;
    my $ec = $self->entry_count;

    return 0 if $ec < $id || $id < 1;

    my( $silo_id ) = @{ $self->[RECORD_INDEX]->get_record( $id ) };
    $silo_id > 0;
} #has_id


=head2 next_id

This sets up a new empty record and returns the
id for it.

=cut
sub next_id {
    my $self = shift;
    my $next = $self->[RECYC_SILO]->pop;
    return $next->[0] if $next && $next->[0];
    $self->[RECORD_INDEX]->next_id;
}


=head2 empty()

This empties out the entire record store completely.
Use only if you mean it.

=cut
sub empty {
    my $self = shift;
    my $silos = $self->_all_silos;
    $self->[RECYC_SILO]->empty;
    $self->[RECORD_INDEX]->empty;
    for my $silo (@$silos) {
        $silo->empty;
    }
} #empty

=head2 empty_recycler()

  Clears out all data from the recycler

=cut
sub empty_recycler {
    shift->[RECYC_SILO]->empty;
} #empty_recycler

=head2 recycle( id, keep_data_flag )

  Ads the id to the recycler, so it will be returned when next_id is called.
  This removes the data occupied by the id, freeing up space unles keep_data_flag
  is set to true.

=cut
sub recycle_id {
    my( $self, $id ) = @_;
    $self->delete_record( $id );
    $self->[RECYC_SILO]->push( [$id] );
} #empty_recycler


=head2 open( direcdtory )

Alias to open_store

=cut
    
sub open { goto &Data::RecordStore::open_store }

=head2 delete( id )

Alias to delete_record

=cut
    
sub delete { goto &Data::RecordStore::delete_record }



#This makes sure there there are at least min_count
#entries in this record store. This creates empty
#records if needed.
sub _ensure_entry_count {
    shift->[RECORD_INDEX]->_ensure_entry_count( shift );
} #_ensure_entry_count

#
# Removes a record from the store. If there was a record at the end of the store
# then move that record to the vacated space, reducing the file size by one record.
#
sub _swapout {
    my( $self, $silo, $silo_id, $vacated_silo_id ) = @_;

    my $last_id = $silo->entry_count;

    if( $vacated_silo_id < $last_id ) {
        my $data = $silo->_copy_record( $last_id - 1, $vacated_silo_id - 1 );
        #
        # update the record db with the new silo index for the moved record id
        #
        my( $moving_id ) = unpack( $silo->[TMPL], $data );

        $self->[RECORD_INDEX]->put_record( $moving_id, [ $silo_id, $vacated_silo_id ] );

        #
        # truncate now that the silo is one record shorter
        #
        $silo->pop;
    }
    elsif( $vacated_silo_id == $last_id ) {
        #
        # this was the last record, so just remove it and
        # the silo it rode in on.
        #
        $silo->pop;
    }
    else {

        # this is a bug caused when two entries are swapped out on the same silo
        # where they both were at the end at the time the vacated id record was
        # created by the transaction commit. The answer is to sort the
        # ids by the the lastid here.
        
#        use Carp 'longmess'; print STDERR Data::Dumper->Dump([longmess]);
        die "Data::RecordStore::_swapout : error, swapping out id $vacated_silo_id is larger than the last id $last_id";
    }

} #_swapout

#
# Returns a list of all the silos created in this Data::RecordStore
#
sub _all_silos {
    my $self = shift;
    opendir my $DIR, "$self->[DIRECTORY]/silos";
    [ map { /(\d+)_RECSTORE/; $self->_get_silo($1) } grep { /_RECSTORE/ } readdir($DIR) ];
} #_all_silos

sub _get_silo {
    my( $self, $silo_index ) = @_;

    if( $self->[SILOS][ $silo_index ] ) {
        return $self->[SILOS][ $silo_index ];
    }

    my $silo_row_size = int( exp $silo_index );

    # storing first the size of the record, uuencode flag, then the bytes of the record
    my $silo = Data::RecordStore::Silo->open_silo( "LIZ*", "$self->[DIRECTORY]/silos/${silo_index}_RECSTORE", $silo_row_size, $silo_index );

    $self->[SILOS][ $silo_index ] = $silo;
    $silo;
} #_get_silo

# ----------- end Data::RecordStore


=head1 HELPER PACKAGES

Data::RecordStore relies on two helper packages that are useful in
their own right and are documented here.

=head1 HELPER PACKAGE

Data::RecordStore::Silo

=head1 DESCRIPTION

A fixed record store that uses perl pack and unpack templates to store
identically sized sets of data and uses a set of files to do so.

=head1 SYNOPSIS

 my $template = "LII"; # perl pack template. See perl pack/unpack.

 my $size; #required if the template does not have a definite size, like A*

 my $store = Data::RecordStore::Silo->open_silo( $template, $filename, $size );

 my $new_id = $store->next_id;

 $store->put_record( $new_id, [ 321421424243, 12, 345 ] );

 my $more_data = $store->get_record( $other_id );

 my $removed_last = $store->pop;

 my $last_id = $store->push( $data_for_the_end );

 my $entries = $store->entry_count;

 $store->emtpy;

 $store->unlink_store;

=head1 METHODS

=cut

package Data::RecordStore::Silo;

use strict;
use warnings;
no warnings 'uninitialized';
no warnings 'numeric';

use Fcntl qw( SEEK_SET LOCK_EX LOCK_UN );
use File::Path qw(make_path remove_tree);

use constant {
    DIRECTORY        => 0,
    RECORD_SIZE      => 1,
    FILE_SIZE        => 2,
    FILE_MAX_RECORDS => 3,
    TMPL             => 4,
    LOCK             => 5,
};

$Data::RecordStore::Silo::MAX_SIZE = 2_000_000_000;

=head2 open_silo( template, filename, record_size )

Opens or creates the directory for a group of files
that represent one silo storing records of the given
template and size.
If a size is not given, it calculates the size from
the template, if it can. This will die if a zero byte
record size is given or calculated.

=cut

sub open_silo {
    my( $pkg, $template, $directory, $size ) = @_;
    my $class = ref( $pkg ) || $pkg;
    my $template_size = $template =~ /\*/ ? 0 : do { use bytes; length( pack( $template ) ) };
    my $record_size = $size // $template_size;

    die "Data::RecordStore::Silo->open_sile error : given record size does not agree with template size" if $size && $template_size && $template_size != $size;
    die "Data::RecordStore::Silo->open_silo Cannot open a zero record sized fixed store" unless $record_size;
    my $file_max_records = int( $Data::RecordStore::Silo::MAX_SIZE / $record_size );
    if( $file_max_records == 0 ) {
        warn "Opening store of size $record_size which is above the set max size of $Data::RecordStore::Silo::MAX_SIZE. Allowing only one record per file for this size.";
        $file_max_records = 1;
    }
    my $file_max_size = $file_max_records * $record_size;
    my $lock_fh;
    unless( -d $directory ) {
        die "Data::RecordStore::Silo->open_silo Error opening record store. $directory exists and is not a directory" if -e $directory;
        make_path( $directory ) or die "Data::RecordStore::Silo->open_silo : Unable to create directory $directory";
    }
    unless( -e "$directory/0" ){
        CORE::open( my $fh, ">", "$directory/0" ) or die "Data::RecordStore::Silo->open_silo : Unable to open '$directory/0' : $!";
        close $fh;
    }
    CORE::open( $lock_fh, ">", "$directory/l" ) or die "Data::RecordStore::Silo->open_silo : Unable to open '$directory/l' : $!";

    unless( -w "$directory/0" ){
        die "Data::RecordStore::Silo->open_silo Error operning record store. $directory exists but is not writeable" if -e $directory;
    }

    my $silo = bless [
        $directory,
        $record_size,
        $file_max_size,
        $file_max_records,
        $template,
        $lock_fh,
    ], $class;

    $silo;
} #open_silo

=head2 empty

This empties out the database, setting it to zero records.

=cut
sub empty {
    my $self = shift;
    $self->_lock_write;
    my( $first, @files ) = map { "$self->[DIRECTORY]/$_" } $self->_files;
    truncate $first, 0;
    for my $file (@files) {
        unlink $file;
    }
    $self->_unlock;
    undef;
} #empty

=head2

Returns the number of entries in this store.
This is the same as the size of the file divided
by the record size.

=cut
sub entry_count {
    # return how many entries this index has
    my $self = shift;
    $self->_lock_read;
    my @files = $self->_files;
    my $filesize;
    for my $file (@files) {
        $filesize += -s "$self->[DIRECTORY]/$file";
    }
    $self->_unlock;
    int( $filesize / $self->[RECORD_SIZE] );
} #entry_count

=head2 get_record( idx )

Returns an arrayref representing the record with the given id.
The array in question is the unpacked template.

=cut
sub get_record {
    my( $self, $id ) = @_;

    $self->_lock_read;
    die "Data::RecordStore::Silo->get_record : index $id out of bounds. Store has entry count of ".$self->entry_count if $id > $self->entry_count || $id < 1;

    my( $f_idx, $fh, $file, $file_id ) = $self->_fh( $id );

    sysseek( $fh, $self->[RECORD_SIZE] * $f_idx, SEEK_SET )
        or die "Data::RecordStore::Silo->get_record : error reading id $id at file $file_id at index $f_idx. Could not seek to ($self->[RECORD_SIZE] * $f_idx) : $@ $!";
    my $srv = sysread $fh, my $data, $self->[RECORD_SIZE];
    close $fh;
    $self->_unlock;

    defined( $srv )
        or die "Data::RecordStore::Silo->get_record : error reading id $id at file $file_id at index $f_idx. Could not read : $@ $!";
    [unpack( $self->[TMPL], $data )];
} #get_record

=head2 next_id

adds an empty record and returns its id, starting with 1

=cut
sub next_id {
    my( $self ) = @_;
    $self->_lock_write;
    my $next_id = 1 + $self->entry_count;
    $self->_ensure_entry_count( $next_id );
    $self->_unlock;
    $next_id;
} #next_id


=head2 pop

Remove the last record and return it.

=cut
sub pop {
    my( $self ) = @_;

    my $entries = $self->entry_count;
    return undef unless $entries;
    $self->_lock_write;
    my $ret = $self->get_record( $entries );
    my( $f_idx, $fh, $file ) = $self->_fh( $entries );
    my $new_fs = $f_idx * $self->[RECORD_SIZE];
    if( $new_fs || $file =~ m!/0$! ) {
        truncate $fh, $new_fs;
    } else {
        unlink $file;
    }
    $self->_unlock;
    close $fh;

    $ret;
} #pop

=head2 last_entry

Return the last record.

=cut
sub last_entry {
    my( $self ) = @_;

    my $entries = $self->entry_count;
    return undef unless $entries;
    $self->get_record( $entries );
} #last_entry


=head2 push( data )

Add a record to the end of this store. Returns the id assigned
to that record. The data must be a scalar or list reference.
If a list reference, it should conform to the pack template
assigned to this store.

=cut 
sub push {
    my( $self, $data ) = @_;
    my $next_id = $self->next_id;

    # the problem is that the second file has stuff in it not sure how
    $self->put_record( $next_id, $data );
    $next_id;
} #push

=head2 push( idx, data )

Saves the data to the record and the record to the filesystem.
The data must be a scalar or list reference.
If a list reference, it should conform to the pack template
assigned to this store.

=cut
sub put_record {
    my( $self, $id, $data ) = @_;

    die "Data::RecordStore::Silo->put_record : index $id out of bounds. Store has entry count of ".$self->entry_count if $id > $self->entry_count || $id < 1;

    my $to_write = pack ( $self->[TMPL], ref $data ? @$data : $data );

    # allows the put_record to grow the data store by no more than one entry
    my $write_size = do { use bytes; length( $to_write ) };

    die "Data::RecordStore::Silo->put_record : record too large" if $write_size > $self->[RECORD_SIZE];

    my( $f_idx, $fh, $file, $file_id ) = $self->_fh( $id );

    $self->_lock_write;
    sysseek( $fh, $self->[RECORD_SIZE] * ($f_idx), SEEK_SET ) && ( my $swv = syswrite( $fh, $to_write ) ) || die "Data::RecordStore::Silo->put_record : unable to put record id $id at file $file_id index $f_idx : $@ $!";
    $self->_unlock;
    close $fh;

    1;
} #put_record

=head2 unlink_store

Removes the file for this record store entirely from the file system.

=cut
sub unlink_store {
    my $self = shift;
    remove_tree( $self->[DIRECTORY] ) // die "Data::RecordStore::Silo->unlink_store: Error unlinking store : $!";
} #unlink_store


=head2 open( direcdtory )

Alias to open_silo

=cut

sub open { goto &Data::RecordStore::Silo::open_silo }


#
# This copies a record from one index in the store to an other.
# This returns the data of record so copied. Note : idx designates an index beginning at zero as
# opposed to id, which starts with 1.
#
sub _copy_record {
    my( $self, $from_idx, $to_idx ) = @_;

    die "Data::RecordStore::Silo->_copy_record : from_index $from_idx out of bounds. Store has entry count of ".$self->entry_count if $from_idx >= $self->entry_count || $from_idx < 0;

    die "Data::RecordStore::Silo->_copy_record : to_index $to_idx out of bounds. Store has entry count of ".$self->entry_count if $to_idx >= $self->entry_count || $to_idx < 0;

    my( $from_file_idx, $fh_from ) = $self->_fh($from_idx+1);
    my( $to_file_idx, $fh_to ) = $self->_fh($to_idx+1);
    sysseek $fh_from, $self->[RECORD_SIZE] * ($from_file_idx), SEEK_SET
        or die "Data::RecordStore::Silo->_copy_record could not seek ($self->[RECORD_SIZE] * ($to_idx)) : $@ $!";
    my $srv = sysread $fh_from, my $data, $self->[RECORD_SIZE];
    defined( $srv ) or die "Data::RecordStore::Silo->_copy_record could not read : $@ $!";
    sysseek( $fh_to, $self->[RECORD_SIZE] * $to_file_idx, SEEK_SET ) && ( my $swv = syswrite( $fh_to, $data ) );
    defined( $srv ) or die "Data::RecordStore::Silo->_copy_record could not read : $@ $!";
    $data;
} #_copy_record


#Makes sure the data store has at least as many entries
#as the count given. This creates empty records if needed
#to rearch the target record count.
sub _ensure_entry_count {
    my( $self, $count ) = @_;
    my $needed = $count - $self->entry_count;

    if( $needed > 0 ) {
        my( @files ) = $self->_files;
        my $write_file = $files[$#files];

        my $existing_file_records = int( (-s "$self->[DIRECTORY]/$write_file" ) / $self->[RECORD_SIZE] );
        my $records_needed_to_fill = $self->[FILE_MAX_RECORDS] - $existing_file_records;
        $records_needed_to_fill = $needed if $records_needed_to_fill > $needed;
        $self->_lock_write;
        if( $records_needed_to_fill > 0 ) {
            # fill the last flie up with \0

            CORE::open( my $fh, "+<", "$self->[DIRECTORY]/$write_file" ) or die "Data::RecordStore::Silo->ensure_entry_count : unable to open '$self->[DIRECTORY]/$write_file' : $!";
            binmode $fh; # for windows
            my $nulls = "\0" x ( $records_needed_to_fill * $self->[RECORD_SIZE] );
            (my $pos = sysseek( $fh, $self->[RECORD_SIZE] * $existing_file_records, SEEK_SET )) && (my $wrote = syswrite( $fh, $nulls )) || die "Data::RecordStore::Silo->ensure_entry_count : unable to write blank to '$self->[DIRECTORY]/$write_file' : $!";
            close $fh;
            $needed -= $records_needed_to_fill;
        }
        while( $needed > $self->[FILE_MAX_RECORDS] ) {
            # still needed, so create a new file
            $write_file++;

            die "Data::RecordStore::Silo->ensure_entry_count : file $self->[DIRECTORY]/$write_file already exists" if -e $write_file;
            CORE::open( my $fh, ">", "$self->[DIRECTORY]/$write_file" ) or die "Data::RecordStore::Silo->ensure_entry_count : unable to create '$self->[DIRECTORY]/$write_file' : $!";
            binmode $fh; # for windows
            my $nulls = "\0" x ( $self->[FILE_MAX_RECORDS] * $self->[RECORD_SIZE] );
            (my $pos = sysseek( $fh, 0, SEEK_SET )) && (my $wrote = syswrite( $fh, $nulls )) || die "Data::RecordStore::Silo->ensure_entry_count : unable to write blank to '$self->[DIRECTORY]/$write_file' : $!";
            $needed -= $self->[FILE_MAX_RECORDS];
            close $fh;
        }
        if( $needed > 0 ) {
            # still needed, so create a new file
            $write_file++;

            die "Data::RecordStore::Silo->ensure_entry_count : file $self->[DIRECTORY]/$write_file already exists" if -e $write_file;
            CORE::open( my $fh, ">", "$self->[DIRECTORY]/$write_file" ) or die "Data::RecordStore::Silo->ensure_entry_count : unable to create '$self->[DIRECTORY]/$write_file' : $!";
            binmode $fh; # for windows
            my $nulls = "\0" x ( $needed * $self->[RECORD_SIZE] );
            (my $pos = sysseek( $fh, 0, SEEK_SET )) && (my $wrote = syswrite( $fh, $nulls )) || die "Data::RecordStore::Silo->ensure_entry_count : unable to write blank to '$self->[DIRECTORY]/$write_file' : $!";
            close $fh;
        }
        $self->_unlock;
    }
} #_ensure_entry_count

#
# Takes an insertion id and returns
#   an insertion index for in the file
#   filehandle.
#   filepath/filename
#   which number file this is (0 is the first)
#
sub _fh {
    my( $self, $id ) = @_;

    my @files = $self->_files;
    die "Data::RecordStore::Silo->_fh : No files found for this data store" unless @files;

    my $f_idx;
    if( $id ) {
        $f_idx = int( ($id-1) / $self->[FILE_MAX_RECORDS] );
        if( $f_idx > $#files || $f_idx < 0 ) {
            die "Data::RecordStore::Silo->_fh : requested a non existant file handle ($f_idx, $id)";
        }
    }
    else {
        $f_idx = $#files;
    }

    my $file = $files[$f_idx];
    CORE::open( my $fh, "+<", "$self->[DIRECTORY]/$file" ) or die "Data::RecordStore::Silo->_fhu nable to open '$self->[DIRECTORY]/$file' : $! $?";
    binmode $fh; # for windows

    (($id - ($f_idx*$self->[FILE_MAX_RECORDS])) - 1,$fh,"$self->[DIRECTORY]/$file",$f_idx);

} #_fh

#
# Returns the list of filenames of the 'silos' of this store. They are numbers starting with 0
#
sub _files {
    my $self = shift;
    opendir( my $dh, $self->[DIRECTORY] ) or die "Data::RecordStore::Silo->_files : can't open $self->[DIRECTORY]\n";
    my( @files ) = (sort { $a <=> $b } grep { $_ eq '0' || (-s "$self->[DIRECTORY]/$_") > 0 } grep { $_ > 0 || $_ eq '0' } readdir( $dh ) );
    closedir $dh;
    @files;
} #_files

sub _lock_read {
    my $fh = shift->[LOCK];
    flock( $fh, 1 );
}
sub _lock_write {
    my $fh = shift->[LOCK];
    flock( $fh, 2 );
}
sub _unlock {
    my $fh = shift->[LOCK];
    flock( $fh, 8 );
}

# ----------- end Data::RecordStore::Silo

=head1 HELPER PACKAGE

Data::RecordStore::Transaction

=head1 DESCRIPTION

A transaction that can collect actions on the record store and then
writes them as a block.

=head1 SYNOPSIS

my $trans = $store->create_transaction;

print join(",", $transaction->get_update_time,
                $transaction->get_process_id,
                $transaction->get_state,
                $transaction->get_id );

my $new_id = $transaction->stow( $data );

my $new_or_recycled_id = $store->next_id;

$transaction->stow( "MORE DATA", $new_or_recycled_id );

$transaction->delete_record( $someid );
$transaction->recycle_id( $dead_id );

if( $is_good ) {
   $transaction->commit;
} else {
   $transaction->rollback;
}
#
# Get a list of transactions that are old and probably stale.
#
for my $trans ($store->list_transactions) {

  next if $trans->get_udpate_time > $too_old;

  if( $trans->get_state == Data::RecordStore::Transaction::TRA_IN_COMMIT
    || $trans->get_state == Data::RecordStore::Transaction::TRA_CLEANUP_COMMIT )
  {
     $trans->commit;
  }
  elsif( $trans->get_state == Data::RecordStore::Transaction::TRA_IN_ROLLBACK
    || $trans->get_state == Data::RecordStore::Transaction::TRA_CLEANUP_ROLLBACK )
  {
     $trans->rollback;
  }
  elsif( $trans->get_state == Data::RecordStore::Transaction::TRA_ACTIVE )
  {
     # commit or rollback, depending on preference
  }
}


=head1 METHODS

=cut
package Data::RecordStore::Transaction;

use constant {
    ID          => 0,
    PID         => 1,
    UPDATE_TIME => 2,
    STATE       => 3,
    STORE       => 4,
    SILO        => 5,
    CATALOG     => 6,

    TRA_ACTIVE           => 1, # transaction has been created
    TRA_IN_COMMIT        => 2, # commit has been called, not yet completed
    TRA_IN_ROLLBACK      => 3, # commit has been called, has not yet completed
    TRA_CLEANUP_COMMIT   => 4, # everything in commit has been written, TRA is in process of being removed
    TRA_CLEANUP_ROLLBACK => 5, # everything in commit has been written, TRA is in process of being removed
    TRA_DONE             => 6, # transaction complete. It may be removed.

};

our @STATE_LOOKUP = ('Active','In Commit','In Rollback','In Commit Cleanup','In Rollback Cleanup','Done');

#
# Creates a new transaction or returns an existing one based on the data provided
#
sub _create {
    my( $pkg, $record_store, $trans_data ) = @_;

    # transaction id
    # process id
    # update time
    # state
    my $trans_catalog = Data::RecordStore::Silo->open_silo( "ILLI", "$record_store->[Data::RecordStore::DIRECTORY]/TRANS/META" );
    my $trans_id;

    if( $trans_data ) {
        ($trans_id) = @$trans_data;
    }
    else {
        $trans_id = $trans_catalog->next_id;
        $trans_data = [ $trans_id, $$, time, TRA_ACTIVE ];
        $trans_catalog->put_record( $trans_id, $trans_data );
    }

    push @$trans_data, $record_store;

    # action
    # record id
    # from silo id
    # from record id
    # to silo id
    # to record id
    push @$trans_data, Data::RecordStore::Silo->open_silo(
        "ALILIL",
        "$record_store->[Data::RecordStore::DIRECTORY]/TRANS/instances/$trans_id"
        );
    push @$trans_data, $trans_catalog;

    bless $trans_data, $pkg;

} #_create

=head2 get_update_time

Returns the epoch time when the last time this was updated.

=cut

sub get_update_time { shift->[UPDATE_TIME] }

=head2 get_process_id

Returns the process id that last wrote to this transaction.

=cut

sub get_process_id  { shift->[PID] }

=head2 get_state

Returns the state of this process. Values are 
  TRA_ACTIVE
  TRA_IN_COMMIT
  TRA_IN_ROLLBACK
  TRA_COMMIT_CLEANUP
  TRA_ROLLBACK_CLEANUP
  TRA_DONE

=cut

sub get_state       { shift->[STATE] }

=head2 get_id

Returns the ID for this transaction, which is the same as its
position in the transaction index plus one.

=cut

sub get_id          { shift->[ID] }

=head2 stow( $data, $optional_id )

Stores the data given. Returns the id that the data was stowed under.
If the id is not given, this generates one from the record store.
The data stored this way is really stored in the record store, but
the index is not updated until a commit happens. That means it is
not reachable from the store until the commit.

=cut

sub stow {
    my( $self, $data, $id ) = @_;
    die "Data::RecordStore::Transaction::stow Error : is not active" unless $self->[STATE] == TRA_ACTIVE;

    my $trans_silo = $self->[SILO];

    my $store = $self->[STORE];
    $id //= $store->next_id;

    $store->_ensure_entry_count( $id ) if $id > 0;

    die "ID must be a positive integer" if $id < 1;

    my $uue = $data =~ /\0/;
    if( $uue ) {
        $data = pack 'u', $data;
    }

    my $save_size = do { use bytes; length( $data ); };

    # tack on the size of the id (a long + an int or 12 bytes) to the byte count
    $save_size += 12;
    my( $from_silo_id, $from_record_id ) = ( 0, 0 );
    if( $store->[Data::RecordStore::RECORD_INDEX]->entry_count >= $id ) {
        ( $from_silo_id, $from_record_id ) = @{ $store->[Data::RecordStore::RECORD_INDEX]->get_record( $id ) };
    }

    my $to_silo_id = 1 + int( log( $save_size ) );

    my $to_silo = $store->_get_silo( $to_silo_id );

    my $to_record_id = $to_silo->next_id;

    $to_silo->put_record( $to_record_id, [ $id, $uue, $data ] );

    my $next_trans_id = $trans_silo->next_id;

    # action (stow)
    # record id
    # from silo id
    # from silo idx
    # to silo id
    # to silo idx
    $trans_silo->put_record( $next_trans_id,
                             [ 'S', $id, $from_silo_id, $from_record_id, $to_silo_id, $to_record_id ] );

    $id;

} #stow

=head2 delete_record( $id )

Marks that the record associated with the id is to be deleted when the transaction commits.

=cut

sub delete_record {
    my( $self, $id_to_delete ) = @_;
    die "Data::RecordStore::Transaction::delete_record Error : is not active" unless $self->[STATE] == TRA_ACTIVE;
    my $trans_silo = $self->[SILO];

    my( $from_silo_id, $from_record_id ) = @{ $self->[STORE]->[Data::RecordStore::RECORD_INDEX]->get_record( $id_to_delete ) };
    my $next_trans_id = $trans_silo->next_id;
    $trans_silo->put_record( $next_trans_id,
                             [ 'D', $id_to_delete, $from_silo_id, $from_record_id, 0, 0 ] );
    1;
} #delete_record

=head2 recycle_id( $id )

Marks that the record associated with the id is to be deleted and its id recycled when the transaction commits.

=cut

sub recycle_id {
    my( $self, $id_to_recycle ) = @_;
    die "Data::RecordStore::Transaction::recycle Error : is not active" unless $self->[STATE] == TRA_ACTIVE;
    my $trans_silo = $self->[SILO];

    my( $from_silo_id, $from_record_id ) = @{ $self->[STORE]->[Data::RecordStore::RECORD_INDEX]->get_record( $id_to_recycle ) };
    my $next_trans_id = $trans_silo->next_id;
    $trans_silo->put_record( $next_trans_id,
                             [ 'R', $id_to_recycle, $from_silo_id, $from_record_id, 0, 0 ] );
    1;
} #recycle

=head2 commit()

Commit applies 

=cut

sub commit {
    my $self = shift;

    my $state = $self->get_state;
    die "Cannot commit transaction. Transaction state is ".$STATE_LOOKUP[$state]
        unless $state == TRA_ACTIVE || $state == TRA_IN_COMMIT ||
        $state == TRA_IN_ROLLBACK || $state == TRA_CLEANUP_COMMIT;

    my $store = $self->[STORE];

    my $index        = $store->[Data::RecordStore::RECORD_INDEX];
    my $recycle_silo = $store->[Data::RecordStore::RECYC_SILO];
    my $dir_silo     = $self->[CATALOG];
    my $trans_silo   = $self->[SILO];

    my $trans_id = $self->[ID];

    $dir_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_IN_COMMIT ] );
    $self->[STATE] = TRA_IN_COMMIT;

    my $actions = $trans_silo->entry_count;

    #
    # in this phase, the indexes are updated. The blank spaces
    # are not purged here.
    #
    my $purges = [];
    my( %foundid );
    for( my $a_id=$actions; $a_id > 0; $a_id-- ) {
        my $tstep = $trans_silo->get_record($a_id);
        my( $action, $record_id, $from_silo_id, $from_record_id, $to_silo_id, $to_record_id ) = @$tstep;
        if( 0 == $foundid{$record_id}++ ) {
            if( $action eq 'S' ) {
                $index->put_record( $record_id, [ $to_silo_id, $to_record_id ] );
            } else {
                $index->put_record( $record_id, [ 0, 0 ] );
            }
            push @$purges, [ $action, $record_id, $from_silo_id, $from_record_id ];
            
        } elsif( $action eq 'S' ) {
            push @$purges, [ $action, $record_id, $to_silo_id, $to_record_id ];
        }
    }

    $purges = [ sort { $b->[3] <=> $a->[3] } @$purges ];
    for my $purge (@$purges) {
        my( $action, $record_id, $from_silo_id, $from_record_id ) = @$purge;
        if ( $action eq 'S' ) {
            my $silo = $store->_get_silo( $from_silo_id );
            $store->_swapout( $silo, $from_silo_id, $from_record_id );
        } elsif ( $action eq 'D' ) {
            $store->delete_record( $record_id );
        } elsif ( $action eq 'R' ) {
            $store->recycle_id( $record_id );
        }
    }

    $dir_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_DONE ] );
    $self->[STATE] = TRA_DONE;

    $trans_silo->unlink_store;

} #commit

=head2 unlink_store

Removes the file for this record store entirely from the file system.

=cut

sub rollback {
    my $self = shift;

    my $state = $self->get_state;
    die "Cannot rollback transaction. Transaction state is ".$STATE_LOOKUP[$state]
        unless $state == TRA_ACTIVE || $state == TRA_IN_COMMIT ||
        $state == TRA_IN_ROLLBACK || $state == TRA_CLEANUP_COMMIT;

    my $store = $self->[STORE];

    my $index        = $store->[Data::RecordStore::RECORD_INDEX];
    my $dir_silo     = $self->[CATALOG];
    my $trans_silo   = $self->[SILO];
    my $trans_id     = $self->[ID];

    $dir_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_IN_ROLLBACK ] );
    $self->[STATE] = TRA_IN_ROLLBACK;

    my $actions = $trans_silo->entry_count;

    #
    # Rewire the index to the old silo/location
    #
    my( %swapout );
    for my $a_id (1..$actions) {
        my( $action, $record_id, $from_silo_id, $from_record_id, $to_silo_id, $to_record_id ) =
            @{ $trans_silo->get_record($a_id) };

        if( $from_silo_id ) {
            $index->put_record( $record_id, [ $from_silo_id, $from_record_id ] );
        } else {
            $index->put_record( $record_id, [ 0, 0 ] );
        }
        if( $to_silo_id ) {
            push @{$swapout{ $to_silo_id }}, $to_record_id;
        }
    }

    $dir_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_CLEANUP_ROLLBACK ] );
    $self->[STATE] = TRA_CLEANUP_ROLLBACK;

    #
    # Cleanup new data. The swapouts for a silo are sorted by descending ID.
    # this allows the cleanup to go backwards from the end of the silo file
    #
    for my $to_silo_id (keys %swapout) {
        for my $to_record_id (sort { $b <=> $a } @{$swapout{$to_silo_id}}) {
            my $to_silo = $store->_get_silo( $to_silo_id );
            $store->_swapout( $to_silo, $to_silo_id, $to_record_id );
        }
    }

    $dir_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_DONE ] );
    $self->[STATE] = TRA_DONE;

    $trans_silo->unlink_store;

    # if this is the last transaction, remove it from the list
    # of transactions
    if( $trans_id == $dir_silo->entry_count ) {
        $dir_silo->pop;
    }

} #rollback

1;

__END__


=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2015-2018 Eric Wolf. All rights reserved.  This program is free software; you can redistribute it and/or modify it
       under the same terms as Perl itself.

=head1 VERSION
       Version 3.17  (April, 2018))

=cut
