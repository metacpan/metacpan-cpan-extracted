package Data::RecordStore;

use strict;
use warnings;

use Fcntl qw( SEEK_SET );
use File::Path qw(make_path);
use Data::Dumper;

use vars qw($VERSION);

$VERSION = '4.06';

our $DEBUG = 0;

#
# On disc block size. If the reads align with block sizes, the reads will go faster
#  however, there is some annoying things about finding out what that blocksize is.
#  (spoiler: it is currently either 4096 or 512 bytes and probably the former)
#
#  ways to determine :
#     sudo blockdev -getbsz /dev/sda1
#     lsblk -o NAME,MOUNTPOINT,FSTYPE,TYPE,SIZE,STATE,DISC-MAX,DISC-GRAN,PHY-SEC,MIN-IO,RQ-SIZE
#  and they disagree :(
#  using 4096 in any case. It won't be slower, though the space required could be 8 times are large.
#
#  note: this is only for the records, not for any indexes.
#


use constant {
    DIRECTORY    => 0,
    RECORD_INDEX => 1,
    RECYC_SILO   => 2,
    SILOS        => 3,
    VERSION      => 4,
    TRANSACTION  => 5,


    SILO         => 5,    # lookup of trans-id to transaction action [ action from_silo_id from_record_id to_silo_id to_record_id  ]    
    SILODIR      => 6,    # lookup of obj to last silo action [ record-id action-id ]
    
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

sub open {
    warn "Data::RecordStore::open is deprecated. Please use open_store instead.";
    goto &Data::RecordStore::open_store;
}
sub open_store {
    my( $directory ) = grep{! ref($_) } reverse @_;
    my $pkg = 'Data::RecordStore';

    # directory structure
    #   root/VERSION <-- version file
    #   root/RECORD_INDEX_SILO <-- record index silo directory
    #   root/RECYC_SILO        <-- recycle silo directory
    #   root/silos/            <-- directory for silo directories

    make_path( "$directory/silos", { error => \my $err } );

    if( @$err ) {
        die join ',',map { values %$_ } @$err;
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
        if( $version < 4 ) {
            die "A database was found in $directory with version $version. Please run the record_store_convert program to upgrade to version $VERSION.";
        }
    }
    else {
        #
        # a version file needs to be created. if the database
        # had been created and no version exists, assume it is
        # version 1.
        #
        if( -e "$directory/STORE_INDEX" ) {
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
        [],
        ];

    my $store = bless $self, $pkg;

    _log( "Opening store '$directory' with entry count of ".$store->entry_count." and record count of ".$store->record_count );
    
    $store;
} #open_store

#
# If there is no current transaction, this starts one.
#
sub use_transaction {
    my $self = shift;
    $self->_current_transaction || $self->start_transaction;
}

sub commit_transaction {
    my $self = shift;
    my $trans = $self->_current_transaction; # it is removed in the commit call below
    if( $trans ) {
        $trans->commit;
    } else {
        warn "No transaction in progress";
    }
} #commit_transaction

sub rollback_transaction {
    my $self = shift;
    my $trans = $self->_current_transaction; # it is removed in the rollback call below
    if( $trans ) {
        $trans->rollback;
    } else {
        warn "No transaction in progress";
    }
} #rollback_transaction

sub create_transaction {
    warn "create_transaction is deprecated. Please use start_transaction instead.";
    goto &start_transaction;
}

sub start_transaction {
    my $self = shift;
    my $trans = Data::RecordStore::Transaction->_create( $self );
    unshift @{$self->[TRANSACTION]}, $trans;
    $trans;
} #start_transaction

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

sub stow {
    my( $self, $data, $id ) = @_;

    my $trans = $self->_current_transaction;
    if( $trans ) {
        return $trans->stow( $data, $id );
    }

    unless( defined $id ) {
        $id = $self->next_id;
    }

    die "ID must be a positive integer" if $id < 1;
    
    $self->_ensure_entry_count( $id );


    my $save_size = do { use bytes; length( $data ); };

    # tack on the size of the id (a long or 4 bytes) and the \0 (1 byte) to the byte count
    $save_size += 5;

    _log( "RECSTORE STOW id $id with entry count of ".$self->[RECORD_INDEX]->entry_count );

    my( $current_silo_id, $current_id_in_silo ) = @{ $self->[RECORD_INDEX]->get_record( $id ) };

    _log( "  id $id is currently in $current_silo_id/$current_id_in_silo" );

    #
    # See if this record is already in a silo. If it is, see if it
    # should stay there or needs to move to a different sized silo.
    #
    my $old_silo = $current_silo_id ? $self->_get_silo( $current_silo_id ) : undef;
    
    my( $needs_swap, $needs_pop ) = ( 0, 0 );
    if( $old_silo ) {
            
        _log( " SWAP $id  was in $current_silo_id. Now has $save_size vs $old_silo->[RECORD_SIZE]" );

        #
        # Nomove case.
        # Keep it in the same silo if the record is not too big for it
        # and the record takes at least a third of the space
        #
        if ( $save_size <= $old_silo->[RECORD_SIZE] &&
             ( $current_silo_id == 12 || $old_silo->[RECORD_SIZE] < (3 * $save_size) ) ) 
        {
            $old_silo->put_record( $current_id_in_silo, [$id,$data] );
            return $id;
        }

        #
        # the old silo was not the right size, so move it to a new silo
        #
        if( $old_silo->entry_count > $current_id_in_silo ) {
            #
            # the record leaves a hole in the old silo, so move the last
            # entry in the silo to its location to keep things autovacuumed.
            #
            _log( " NEEDS SWAP" );
            $needs_swap = 1;
        } 
        else {
            #
            # this is the last one in the old silo just pop it off, no swapping
            # needed.
            #
            _log( " NEEDS POP" );
            $needs_pop = 1;
        }
    } # if this had a former place

    # 
    # find the new silo for this record
    #
    my $silo_id = 12; # the min size
    if( $save_size > 4096 ) {
        $silo_id = log( $save_size ) / log( 2 );
        if( int( $silo_id ) < $silo_id ) {
            $silo_id = 1 + int( $silo_id );
        }
    }

    _log( "RECSTORE stow $id to silo $silo_id (swap:$needs_swap)" );

    #
    # Save this to the new silo and update the index
    #
    my $silo = $self->_get_silo( $silo_id );
    my $id_in_silo = $silo->next_id;
    $self->[RECORD_INDEX]->put_record( $id, [ $silo_id, $id_in_silo ] );
    $silo->put_record( $id_in_silo, [ $id, $data ] );

    #
    # Clean up the old silo if necessary.
    #
    if( $needs_swap ) {
        $self->_swapout( $old_silo, $current_silo_id, $current_id_in_silo );
    } 
    elsif( $needs_pop ) {
        $old_silo->pop;
    }
    $id;
} #stow

sub fetch {
    my( $self, $id ) = @_;
    
    _log( "Fetch $id from store with ".$self->[RECORD_INDEX]->entry_count." entries" );
    return undef if $id > $self->[RECORD_INDEX]->entry_count;

    my( @trans ) = @{$self->[TRANSACTION]};
    my( $silo_id, $id_in_silo, $found_trans );
    
    # if an existing transaction, return any updates to it
    for my $trans (@trans) {
        my( $trans_id );
        next if $id > $trans->[SILODIR]->entry_count; # this ID was not touched by this transaction
        ( $trans_id ) = @{ $trans->[SILODIR]->get_record( $id ) };
        next unless $trans_id;
        my $trans_record = $trans->[SILO]->get_record( $trans_id );
        my( $action, undef, undef, undef, $to_silo_id, $to_record_id ) = @$trans_record;
        if( $action eq 'S' ) {
            $found_trans = 1;
            ( $silo_id, $id_in_silo ) = ( $to_silo_id, $to_record_id );
        } 
        else {
            # deleted or recycled, so return nothing
            return undef;
        }
        last;
    }

    unless( $found_trans ) {
        ( $silo_id, $id_in_silo ) = @{ $self->[RECORD_INDEX]->get_record( $id ) };
    }

    _log( "Fetch $id from silo $silo_id/$id_in_silo" );

    return undef unless $silo_id;

    my $silo = $self->_get_silo( $silo_id );

    # skip the included id, just get the data
    ( undef, my $data ) = @{ $silo->get_record( $id_in_silo ) };

    $data;
} #fetch

sub entry_count {
    my $self = shift;
    $self->[RECORD_INDEX]->entry_count - $self->[RECYC_SILO]->entry_count;
} #entry_count

sub active_entry_count {
    my $self = shift;
    my $count = 0;
    for( my $id=1; $id<= $self->[RECORD_INDEX]->entry_count; $id++ ) {
        my( $silo_id, $id_in_silo ) = @{ $self->[RECORD_INDEX]->get_record( $id ) };
        $count++ if $silo_id;
    }
    $count;
} #entry_count


sub record_count {
    my $self = shift;
    my $count = 0;
    my $silos = $self->_all_silos;
    for my $silo (@$silos) {
        $count += $silo->entry_count;
    }
    $count;
} #record_count

sub delete_record {
    my( $self, $del_id ) = @_;

    my $trans = $self->_current_transaction;
    if( $trans ) {
        return $trans->delete_record( $del_id );
    }
    return undef if $del_id > $self->[RECORD_INDEX]->entry_count;
    
    my( $from_silo_id, $current_id_in_silo ) = @{ $self->[RECORD_INDEX]->get_record( $del_id ) };

    _log( " DELETE RECORD $del_id IN $from_silo_id" );
    
    return unless $from_silo_id;

    my $from_silo = $self->_get_silo( $from_silo_id );
    $self->[RECORD_INDEX]->put_record( $del_id, [ 0, 0 ] );
    $self->_swapout( $from_silo, $from_silo_id, $current_id_in_silo );
    1;
} #delete_record


sub has_id {
    my( $self, $id ) = @_;
    my $ec = $self->[RECORD_INDEX]->entry_count;

    return 0 if $ec < $id || $id < 1;

    my( $silo_id ) = @{ $self->[RECORD_INDEX]->get_record( $id ) };
    $silo_id > 0;
} #has_id

sub next_id {
    my $self = shift;
    my $next = $self->[RECYC_SILO]->pop;
    if( $next->[0] ) {
        return $next->[0];
    }
    $self->[RECORD_INDEX]->next_id;
}

sub empty {
    my $self = shift;
    my $silos = $self->_all_silos;
    $self->[RECYC_SILO]->empty;
    $self->[RECORD_INDEX]->empty;
    for my $silo (@$silos) {
        $silo->empty;
    }
} #empty

sub empty_recycler {
    shift->[RECYC_SILO]->empty;
} #empty_recycler

sub recycle_id {
    my( $self, $id ) = @_;
    my $trans = $self->_current_transaction;
    if( $trans ) {
        return $trans->recycle_id( $id );
    }
    $self->delete_record( $id );
    $self->[RECYC_SILO]->push( [$id] );
} #empty_recycler


sub delete {
    warn "Data::RecordStore::delete is deprecated. Please use delete_record instead.";
    goto &Data::RecordStore::delete_record;
}

# -///     PRIVATES    ///-

#
# Returns a list of all the silos created in this Data::RecordStore
#
sub _all_silos {
    my $self = shift;
    opendir my $DIR, "$self->[DIRECTORY]/silos";
    [ map { /(\d+)_RECSTORE/; $self->_get_silo($1) } grep { /_RECSTORE/ } readdir($DIR) ];
} #_all_silos

sub _current_transaction {
    shift->[TRANSACTION][0];
}

#This makes sure there there are at least min_count
#entries in this record store. This creates empty
#records if needed.
sub _ensure_entry_count {
    shift->[RECORD_INDEX]->_ensure_entry_count( shift );
} #_ensure_entry_count


sub _get_silo {
    my( $self, $silo_index ) = @_;

    if( $self->[SILOS][ $silo_index ] ) {
        return $self->[SILOS][ $silo_index ];
    }

    my $silo_row_size = 2 ** $silo_index;

    # storing first the size of the record, uuencode flag, then the bytes of the record
    my $silo = Data::RecordStore::Silo->open_silo( "LZ*", "$self->[DIRECTORY]/silos/${silo_index}_RECSTORE", $silo_row_size );

    $self->[SILOS][ $silo_index ] = $silo;
    $silo;
} #_get_silo

sub _log {
    return unless $DEBUG;
    my $txt = shift;
    print STDERR "$txt\n";
} #_log

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
    }

    # remove the record from the end. This is either the record being vacated or the
    # record that was moved into its place.
    $silo->pop;

} #_swapout


# ----------- end Data::RecordStore



package Data::RecordStore::Silo;

use strict;
use warnings;
no warnings 'uninitialized';
no warnings 'numeric';

use Fcntl qw( SEEK_SET );
use File::Path qw(make_path remove_tree);

use constant {
    DIRECTORY        => 0,
    RECORD_SIZE      => 1,
    FILE_SIZE        => 2,
    FILE_MAX_RECORDS => 3,
    TMPL             => 4,
};

$Data::RecordStore::Silo::MAX_SIZE = 2_000_000_000;


sub open_silo {
    if( $_[0] ne 'Data::RecordStore::Silo' ) {
        unshift @_, 'Data::RecordStore::Silo';
    }
    my( $class, $template, $directory, $size ) = @_;
    my $template_size = $template =~ /\*/ ? 0 : do { use bytes; length( pack( $template ) ) };
    
    my $record_size = $size // $template_size;
    
    die "Data::RecordStore::Silo->open_sile error : given record size does not agree with template size" if $size && $template_size && $template_size != $size;
    die "Data::RecordStore::Silo->open_silo Cannot open a zero record sized fixed store" unless $record_size;
    my $file_max_records = int( $Data::RecordStore::Silo::MAX_SIZE / $record_size );
    if( $file_max_records == 0 ) {
        warn "Opening store of size $record_size which is above the set max size of $Data::RecordStore::Silo::MAX_SIZE. Allowing only one record per file for this size. ";
        $file_max_records = 1;
    }
    my $file_max_size = $file_max_records * $record_size;
    unless( -d $directory ) {
        die "Data::RecordStore::Silo->open_silo Error opening record store. $directory exists and is not a directory" if -e $directory;
        make_path( $directory, { error => \my $err } );
    }
    unless( -e "$directory/0" ){
        CORE::open( my $fh, ">", "$directory/0" ) or die "Data::RecordStore::Silo->open_silo : Unable to open '$directory/0' : $!";
        close $fh;
    }

    my $silo = bless [
        $directory,
        $record_size,
        $file_max_size,
        $file_max_records,
        $template,
        ], $class;

    Data::RecordStore::_log( "open silo $directory of size $record_size and template $template with ".$silo->entry_count." records" );

    
    $silo;
} #open_silo

sub empty {
    my $self = shift;
    my( $first, @files ) = map { "$self->[DIRECTORY]/$_" } $self->_files;
    truncate( $first, 0 ) // die "Unable to empty silo $self->[0]";;
    for my $file (@files) {
        unlink( $file );
    }
    undef;
} #empty

sub entry_count {
    # return how many entries this silo has
    my $self = shift;
    my @files = $self->_files;
    my $filesize;
    Data::RecordStore::_log( "entry count for $self->[DIRECTORY] with ".scalar(@files)." files");
    for my $file (@files) {
        $filesize += -s "$self->[DIRECTORY]/$file";
    }

    int( $filesize / $self->[RECORD_SIZE] );
} #entry_count

sub get_record {
    my( $self, $id ) = @_;

    Data::RecordStore::_log( "  silo $self->[0] get record id $id" );

    die "Data::RecordStore::Silo->get_record : index $id out of bounds for silo $self->[DIRECTORY]. Silo has entry count of ".$self->entry_count if $id > $self->entry_count || $id < 1;

    my( $f_idx, $fh, $file, $file_id ) = $self->_fh( $id, 'readonly' );

    sysseek( $fh, $self->[RECORD_SIZE] * $f_idx, SEEK_SET );
    my $srv = sysread $fh, my $data, $self->[RECORD_SIZE];
    close $fh;

    [unpack( $self->[TMPL], $data )];
} #get_record

sub next_id {
    my( $self ) = @_;
    my $next_id = 1 + $self->entry_count;
    $self->_ensure_entry_count( $next_id );
    $next_id;
} #next_id


sub pop {
    my( $self ) = @_;

    my $entries = $self->entry_count;
    return undef unless $entries;
    Data::RecordStore::_log( "  silo $self->[0] POP now with entries ".($entries-1) );
    my $ret = $self->get_record( $entries );
    my( $f_idx, $fh, $file ) = $self->_fh( $entries );
    my $new_fs = $f_idx * $self->[RECORD_SIZE];
    if( $new_fs || $file =~ m!/0$! ) {
        truncate $fh, $new_fs;
    } else {
        unlink $file;
    }
    close $fh;

    $ret;
} #pop

sub last_entry {
    my( $self ) = @_;

    my $entries = $self->entry_count;
    return undef unless $entries;
    $self->get_record( $entries );
} #last_entry

sub push {
    my( $self, $data ) = @_;
    
    my $next_id = $self->next_id;

    # the problem is that the second file has stuff in it not sure how
    $self->put_record( $next_id, $data );
    $next_id;
} #push


sub put_record {
    my( $self, $id, $data ) = @_;
    
    die "Data::RecordStore::Silo->put_record : index $id out of bounds for silo $self->[DIRECTORY]. Store has entry count of ".$self->entry_count if $id > $self->entry_count || $id < 1;

    my $to_write = pack ( $self->[TMPL], ref $data ? @$data : $data );

    # allows the put_record to grow the data store by no more than one entry
    my $write_size = do { use bytes; length( $to_write ) };

    Data::RecordStore::_log( "  put_record silo $self->[0] of size $self->[RECORD_SIZE] write to id $id with size $write_size" );

    die "Data::RecordStore::Silo->put_record : record size $write_size too large. Max is $self->[RECORD_SIZE]" if $write_size > $self->[RECORD_SIZE];

    my( $f_idx, $fh, $file, $file_id ) = $self->_fh( $id );

    sysseek( $fh, $self->[RECORD_SIZE] * ($f_idx), SEEK_SET );
    syswrite( $fh, $to_write );
    
    close $fh;

    1;
} #put_record

sub unlink_store {
    my $self = shift;
    remove_tree( $self->[DIRECTORY] );# // die "Data::RecordStore::Silo->unlink_store: Error unlinking store : $!";
} #unlink_store



sub open {
    warn "Data::RecordStore::Silo::open is deprecated. Please use open_silo instead.";
    goto &Data::RecordStore::Silo::open_silo;
}


#
# This copies a record from one index in the store to an other.
# This returns the data of record so copied. Note : idx designates an index beginning at zero as
# opposed to id, which starts with 1.
#
sub _copy_record {
    my( $self, $from_idx, $to_idx ) = @_;

    die "Data::RecordStore::Silo->_copy_record : from_index $from_idx out of bounds. Store has entry count of ".$self->entry_count if $from_idx >= $self->entry_count || $from_idx < 0;

    die "Data::RecordStore::Silo->_copy_record : to_index $to_idx out of bounds. Store has entry count of ".$self->entry_count if $to_idx >= $self->entry_count || $to_idx < 0;

    my( $from_file_idx, $fh_from ) = $self->_fh($from_idx+1,'readonly');
    my( $to_file_idx, $fh_to ) = $self->_fh($to_idx+1);
    sysseek $fh_from, $self->[RECORD_SIZE] * ($from_file_idx), SEEK_SET;
    my $srv = sysread $fh_from, my $data, $self->[RECORD_SIZE];

    sysseek( $fh_to, $self->[RECORD_SIZE] * $to_file_idx, SEEK_SET );
    syswrite( $fh_to, $data );

    $data;
} #_copy_record


#Makes sure this silo has at least as many entries
#as the count given. This creates empty records if needed
#to rearch the target record count.
sub _ensure_entry_count {
    my( $self, $count ) = @_;
    my $needed = $count - $self->entry_count;
    
    Data::RecordStore::_log( "  silo $self->[0] ensure entries to $count" );

    if( $needed > 0 ) {
        my( @files ) = $self->_files;
        my $write_file = $files[$#files];

        my $existing_file_records = int( (-s "$self->[DIRECTORY]/$write_file" ) / $self->[RECORD_SIZE] );
        my $records_needed_to_fill = $self->[FILE_MAX_RECORDS] - $existing_file_records;
        $records_needed_to_fill = $needed if $records_needed_to_fill > $needed;

        if( $records_needed_to_fill > 0 ) {
            # fill the last flie up with \0

            CORE::open( my $fh, "+<", "$self->[DIRECTORY]/$write_file" ) or die "Data::RecordStore::Silo->ensure_entry_count : unable to open '$self->[DIRECTORY]/$write_file' : $!";
            binmode $fh; # for windows
            my $nulls = "\0" x ( $records_needed_to_fill * $self->[RECORD_SIZE] );
            sysseek( $fh, $self->[RECORD_SIZE] * $existing_file_records, SEEK_SET );
            syswrite( $fh, $nulls );
            close $fh;
            $needed -= $records_needed_to_fill;
        }
        while( $needed > $self->[FILE_MAX_RECORDS] ) {
            # still needed, so create a new file
            $write_file++;

            die "Data::RecordStore::Silo->ensure_entry_count : file $self->[DIRECTORY]/$write_file already exists" if -e "$self->[DIRECTORY]/$write_file";
            CORE::open( my $fh, ">", "$self->[DIRECTORY]/$write_file" );
            binmode $fh; # for windows
            my $nulls = "\0" x ( $self->[FILE_MAX_RECORDS] * $self->[RECORD_SIZE] );
            sysseek( $fh, 0, SEEK_SET );
            syswrite( $fh, $nulls );
            $needed -= $self->[FILE_MAX_RECORDS];
            close $fh;
        }
        if( $needed > 0 ) {
            # still needed, so create a new file
            $write_file++;

            die "Data::RecordStore::Silo->ensure_entry_count : file $self->[DIRECTORY]/$write_file already exists" if -e "$self->[DIRECTORY]/$write_file";
            CORE::open( my $fh, ">", "$self->[DIRECTORY]/$write_file" );
            binmode $fh; # for windows
            my $nulls = "\0" x ( $needed * $self->[RECORD_SIZE] );
            sysseek( $fh, 0, SEEK_SET );
            syswrite( $fh, $nulls );
            close $fh;
        }
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
    my( $self, $id, $readonly ) = @_;
    my @files = $self->_files;

    my $f_idx = int( ($id-1) / $self->[FILE_MAX_RECORDS] );

    my $file = $files[$f_idx];
    my $fh;
    if( $readonly ) {
      CORE::open( $fh, "<", "$self->[DIRECTORY]/$file" ) or die "Data::RecordStore::Silo->_fh unable to open '$self->[DIRECTORY]/$file' : $! $?";
    } else {
      CORE::open( $fh, "+<", "$self->[DIRECTORY]/$file" ) or die "Data::RecordStore::Silo->_fh unable to open '$self->[DIRECTORY]/$file' : $! $?";
    }
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

# ----------- end Data::RecordStore::Silo

package Data::RecordStore::Transaction;

use constant {
    ID          => 0,
    PID         => 1,
    UPDATE_TIME => 2,
    STATE       => 3,
    STORE       => 4,
    SILO        => 5,    # actions for this transaction [ action record-id from-silo-id from-record-id to-silo-it to-record-id ]
    SILODIR     => 6,    # lookup of obj to last silo action [ record-id action-id ]
    CATALOG     => 7,    # lists all transactions [ transaction-id process_id timestamp transaction-status ]

    TRANSACTION  => 5,   # for the store
    
    # TRANSACTION STATUSES
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

    # ( transaction id )
    # transaction id
    # process id
    # update time
    # state
    my $trans_catalog = Data::RecordStore::Silo->open_silo( "ILLI", "$record_store->[Data::RecordStore::DIRECTORY]/TRANS/META" );
    my $trans_id;

    # trans data is passed in when an existing transaction is loaded
    if( $trans_data ) {
        ($trans_id) = @$trans_data;
    }
    else {
        $trans_id = $trans_catalog->next_id;
        $trans_data = [ $trans_id, $$, time, TRA_ACTIVE ];
        $trans_catalog->put_record( $trans_id, $trans_data );
    }

    push @$trans_data, $record_store;

    # ( transaction id )
    # action
    # record id
    # from silo id
    # from silo record id
    # to silo id
    # to silo record id
    push @$trans_data, Data::RecordStore::Silo->open_silo(
        "ALILIL",
        "$record_store->[Data::RecordStore::DIRECTORY]/TRANS/instances/$trans_id",
        );

    # ( record id )
    # transaction-id
    push @$trans_data, Data::RecordStore::Silo->open_silo(
        "L",
        "$record_store->[Data::RecordStore::DIRECTORY]/TRANS/instances/D_$trans_id",
        );
    
    push @$trans_data, $trans_catalog;

    bless $trans_data, $pkg;

} #_create


sub get_update_time { shift->[UPDATE_TIME] }

sub get_process_id  { shift->[PID] }

sub get_state       { shift->[STATE] }

sub get_id          { shift->[ID] }

sub stow {
    my( $self, $data, $id ) = @_;
    die "Data::RecordStore::Transaction::stow Error : is not active" unless $self->[STATE] == TRA_ACTIVE;

    my $trans_silo = $self->[SILO];
    my $dir_silo   = $self->[SILODIR];

    my $store = $self->[STORE];
    unless( defined $id ) {
        $id = $store->next_id;
    }

    die "ID must be a positive integer" if $id < 1 || int($id) != $id;
    
    $store->_ensure_entry_count( $id );

    my $save_size = do { use bytes; length( $data ); };

    # tack on the size of the id (a long + \0 or 5 bytes) to the byte count
    $save_size += 5;
    my( $from_silo_id, $from_record_id ) = @{ $store->[Data::RecordStore::RECORD_INDEX]->get_record( $id ) };

    my $to_silo_id = 12; # the min size

    if( $save_size > 4096 ) {
        $to_silo_id = log( $save_size ) / log( 2 );
        if( int( $to_silo_id ) < $to_silo_id ) {
            $to_silo_id = 1 + int( $to_silo_id );
        }
    }

    my $to_silo = $store->_get_silo( $to_silo_id );

    my $to_record_id = $to_silo->next_id;

    $to_silo->put_record( $to_record_id, [ $id, $data ] );

    my $next_trans_id = $trans_silo->next_id;

    # action (stow)
    # record id
    # from silo id
    # from silo idx
    # to silo id
    # to silo idx
    $trans_silo->put_record( $next_trans_id,
                             [ 'S', $id, $from_silo_id, $from_record_id, $to_silo_id, $to_record_id ] );

    $dir_silo->_ensure_entry_count( $id );
    $dir_silo->put_record( $id, [ $next_trans_id ] );
    $id;

} #stow


sub delete_record {
    my( $self, $id_to_delete ) = @_;
    die "Data::RecordStore::Transaction::delete_record Error : is not active" unless $self->[STATE] == TRA_ACTIVE;
    my $trans_silo = $self->[SILO];
    my $dir_silo   = $self->[SILODIR];
    
    my( $from_silo_id, $from_record_id ) = @{ $self->[STORE]->[Data::RecordStore::RECORD_INDEX]->get_record( $id_to_delete ) };
    my $next_trans_id = $trans_silo->next_id;
    $trans_silo->put_record( $next_trans_id,
                             [ 'D', $id_to_delete, $from_silo_id, $from_record_id, 0, 0 ] );
    $dir_silo->_ensure_entry_count( $id_to_delete );
    $dir_silo->put_record( $id_to_delete, [ $next_trans_id ] );

    1;    
} #delete_record


sub recycle_id {
    my( $self, $id_to_recycle ) = @_;
    die "Data::RecordStore::Transaction::recycle Error : is not active" unless $self->[STATE] == TRA_ACTIVE;
    my $trans_silo = $self->[SILO];
    my $dir_silo   = $self->[SILODIR];
    
    my( $from_silo_id, $from_record_id ) = @{ $self->[STORE]->[Data::RecordStore::RECORD_INDEX]->get_record( $id_to_recycle ) };
    my $next_trans_id = $trans_silo->next_id;
    $trans_silo->put_record( $next_trans_id,
                             [ 'R', $id_to_recycle, $from_silo_id, $from_record_id, 0, 0 ] );
    
    $dir_silo->_ensure_entry_count( $id_to_recycle );
    $dir_silo->put_record( $id_to_recycle, [ $next_trans_id ] );
    1;
} #recycle

sub commit {
    my $self = shift;
    
    my $store = $self->[STORE];

    my $trans = shift @{$store->[TRANSACTION]};

    unless( $trans eq $self ) {
        unshift @{$store->[TRANSACTION]}, $trans;
        die "Cannot commit outer transaction intil inner transactions have been committed";
    }

    my $state = $self->get_state;
    unless( $state == TRA_ACTIVE || $state == TRA_IN_COMMIT ||
            $state == TRA_IN_ROLLBACK || $state == TRA_CLEANUP_COMMIT ) {
        unshift @{$store->[TRANSACTION]}, $trans;
        die "Cannot commit transaction. Transaction state is ".$STATE_LOOKUP[$state];
    }

    my $index        = $store->[Data::RecordStore::RECORD_INDEX];
    my $recycle_silo = $store->[Data::RecordStore::RECYC_SILO];
    my $cat_silo     = $self->[CATALOG];
    my $trans_silo   = $self->[SILO];
    my $dir_silo     = $self->[SILODIR];

    my $trans_id = $self->[ID];

    $cat_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_IN_COMMIT ] );
    $self->[STATE] = TRA_IN_COMMIT;

    my $actions = $trans_silo->entry_count;

    #
    # In this phase, the indexes are updated to point to new locations
    # of updated (via stow) items.
    # The old locations are marked for purging, which occurs in a later
    # stage.
    #
    # Since a stow can occur multiple times for a single id, only the
    # last stow is acted upon.
    #
    my $purges = [];
    my( %foundid );
    for( my $a_id=$actions; $a_id > 0; $a_id-- ) {
        my $tstep = $trans_silo->get_record($a_id);
        my( $action, $record_id, $from_silo_id, $from_record_id, $to_silo_id, $to_record_id ) = @$tstep;
        if( 0 == $foundid{$record_id}++ ) {
            # first time this record is acted upon
            if( $action eq 'S' ) {
                $index->put_record( $record_id, [ $to_silo_id, $to_record_id ] );
            }
            push @$purges, [ $action, $record_id, $from_silo_id, $from_record_id ];

        } 
        elsif( $action eq 'S' ) {
            push @$purges, [ $action, $record_id, $to_silo_id, $to_record_id ];
        }
    }

    #
    # This clause recycles records, deletes records, and deletes the old
    # locations of stowed entries.
    #
    $purges = [ sort { $b->[3] <=> $a->[3] } @$purges ];
    for my $purge (@$purges) {
        my( $action, $record_id, $from_silo_id, $from_record_id ) = @$purge;
        if ( $action eq 'S' ) {
            my $silo = $store->_get_silo( $from_silo_id );
            $store->_swapout( $silo, $from_silo_id, $from_record_id );
        } elsif ( $action eq 'D' ) {
            $store->delete_record( $record_id );
        } else {
            $store->recycle_id( $record_id );
        }
    }

    #
    # Update the state of this transaction and remove the record.
    #
    $cat_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_DONE ] );
    $self->[STATE] = TRA_DONE;

    $trans_silo->unlink_store;
    $dir_silo->unlink_store;


} #commit


sub rollback {
    my $self = shift;

    my $store = $self->[STORE];
    my $trans = shift @{$store->[TRANSACTION]};
    
    my $state = $self->get_state;
    unless( $state == TRA_ACTIVE || $state == TRA_IN_COMMIT ||
            $state == TRA_IN_ROLLBACK || $state == TRA_CLEANUP_ROLLBACK ) {
        unshift @{$store->[TRANSACTION]}, $trans;
        die "Cannot rollback transaction. Transaction state is ".$STATE_LOOKUP[$state];
    }

    my $index      = $store->[Data::RecordStore::RECORD_INDEX];
    my $cat_silo   = $self->[CATALOG];
    my $trans_silo = $self->[SILO];
    my $dir_silo   = $self->[SILODIR];
    my $trans_id   = $self->[ID];

    $cat_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_IN_ROLLBACK ] );
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

    $cat_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_CLEANUP_ROLLBACK ] );
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

    $cat_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_DONE ] );
    $self->[STATE] = TRA_DONE;

    $trans_silo->unlink_store;
    $dir_silo->unlink_store;
    
    
    # if this is the last transaction, remove it from the list
    # of transactions
    if( $trans_id == $cat_silo->entry_count ) {
        $cat_silo->pop;
    }

} #rollback

1;

__END__

=head1 NAME

 Data::RecordStore - Simple store for text and byte data

=head1 SYNPOSIS

 use Data::RecordStore;

 $store = Data::RecordStore->open_store( $directory );
 $data = "TEXT OR BYTES";

 # the first record id is 1
 my $id = $store->stow( $data );

 my $new_or_recycled_id = $store->next_id;
 $store->stow( $new_data, $new_or_recycled_id );

 my $val = $store->fetch( $some_id );

 my $count = $store->entry_count;

 # delete the old record, make its id available for future
 # records
 $store->recycle_id( $id_to_recycle );

 $store->delete_record( $id_to_remove ); #deletes the old record

 my $has_id = $store->has_id( $someother_id );

 $store->empty; # clears out store completely

=head1 DESCRIPTION

Data::RecordStore is a simple way to store serialized text or byte data.
It is written entirely in perl with no non-core dependencies.
It is designed to be both easy to set up and easy to use.
Space is automatically reclaimed when records are reycled or deleted.

Transactions (see below) can be created that stow and recycle records.
They come with the standard commit and rollback methods. If a process dies
in the middle of a commit or rollback, the operation can be reattempted.
Incomplete transactions are obtained by the store's 'list_transactions'
method.

Data::RecordStore operates directly and instantly on the file system.
It is not a daemon or server and is not thread safe. It can be used
in a thread safe manner if the controlling program uses locking mechanisms.


=head1 METHODS

=head2 open( directory )

Deprecated alias to open_store

=head2 open_store( directory )

Takes a directory, and constructs the data store in it.
The directory must be writeable or creatible. If a RecordStore already exists
there, it opens it, otherwise it creates a new one.

=head2 create_transaction()

Deprecated alias to start_transaction

=head2 start_transaction()

Creates and returns a transaction object

=head2 use_transaction()

Returns the current transaction. If there is no
current transaction, it creates one and returns it.

=head2 commit_transaction()

Commits the current transaction, if any.

=head2 rollback_transaction()

Rolls back the current transaction, if any.

=head2 list_transactions

Returns a list of currently existing transaction objects not marked TRA_DONE.

=head2 stow( data, optionalID )

This saves the text or byte data to the record store.
If an id is passed in, this saves the data to the record
for that id, overwriting what was there.
If an id is not passed in, it creates a new record store.

Returns the id of the record written to.

=head2 fetch( id )

Returns the record associated with the ID. If the ID has no
record associated with it, undef is returned.

=head2 active_entry_count

Scans the index and returns a count of how many records 
are marked as having active data

=head2 record_count

Scans the silos and returns a count of how many records 
are contained in them.

=head2 entry_count

How many entries there are for records. This is equal to
the highest ID that has been assigned minus the number of
pending recycles. It is different from
the record count, as entries may be marked deleted.

=head2 record_count

Return how many records there actually are

=head2 delete( id )

Deprecated alias to delete_record

=head2 delete_record( id )

Removes the entry with the given id from the store, freeing up its space.
It does not reuse the id.

=head2 has_id( id )

  Returns true if an record with this id exists in the record store.

=head2 next_id

This sets up a new empty record and returns the
id for it.

=head2 empty()

This empties out the entire record store completely.
Use only if you mean it.

=head2 empty_recycler()

  Clears out all data from the recycler.

=head2 recycle( id, keep_data_flag )

  Ads the id to the recycler, so it will be returned when next_id is called.
  This removes the data occupied by the id, freeing up space unles
  keep_data_flag is set to true.

=head1 LIMITATIONS

Data::RecordStore is not thread safe. Thread coordination
and locking can be done on a level above Data::RecordStore.

=head1 HELPER PACKAGE

Data::RecordStore::Transaction

=head1 HELPER DESCRIPTION

A transaction that can collect actions on the record store and then
writes them as a block.

=head1 HELPER SYNOPSIS

my $transaction = $store->create_transaction;

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

  my $state = $trans->get_state;
  if( $state == Data::RecordStore::Transaction::TRA_IN_COMMIT
    || $state == Data::RecordStore::Transaction::TRA_CLEANUP_COMMIT )
  {
     $trans->commit;
  }
  elsif( $state == Data::RecordStore::Transaction::TRA_IN_ROLLBACK
    || $state == Data::RecordStore::Transaction::TRA_CLEANUP_ROLLBACK )
  {
     $trans->rollback;
  }
  elsif( $state == Data::RecordStore::Transaction::TRA_ACTIVE )
  {
     # commit or rollback, depending on preference
  }
}

=head1 METHODS

=head2 get_update_time

Returns the epoch time when the last time this was updated.

=head2 get_process_id

Returns the process id that last wrote to this transaction.

=head2 get_state

Returns the state of this process. Values are
  TRA_ACTIVE
  TRA_IN_COMMIT
  TRA_IN_ROLLBACK
  TRA_COMMIT_CLEANUP
  TRA_ROLLBACK_CLEANUP
  TRA_DONE

=head2 get_id

Returns the ID for this transaction, which is the same as its
position in the transaction index plus one.

=head2 stow( $data, $optional_id )

Stores the data given. Returns the id that the data was stowed under.
If the id is not given, this generates one from the record store.
The data stored this way is really stored in the record store, but
the index is not updated until a commit happens. That means it is
not reachable from the store until the commit.

=head2 delete_record( $id )

Marks that the record associated with the id is to be deleted when the
transaction commits.

=head2 recycle_id( $id )

Marks that the record associated with the id is to be deleted and its id
recycled when the transaction commits.

=head2 commit()

Commit applies

=head2 unlink_store

Removes the file for this record store entirely from the file system.


=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2015-2018 Eric Wolf. All rights reserved.
       This program is free software; you can redistribute it
       and/or modify it under the same terms as Perl itself.

=head1 VERSION
       Version 4.06  (November, 2018))

=cut
