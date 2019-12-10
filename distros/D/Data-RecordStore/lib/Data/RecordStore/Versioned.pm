package Data::RecordStore::Versioned;

# with immutable objects and versioned ones

use strict;
use warnings;

use Fcntl qw( :flock SEEK_SET );
use File::Path qw(make_path);
use Data::Dumper;

use vars qw($VERSION);

$VERSION = '0.01';

sub open_store {
    my( $cls, @options ) = @_;

    # directory structure
    #   root/CLASS <-- Data::RecordStore::Versioned
    #   root/VERSION <-- version file
    #   root/MASTER_LOCK <-- lock file
    #         master lock is used when creating new silos and setting up
    #         the initial store
    #   root/USER_LOCKS/
    #   root/RECORD_INDEX_SILO/ <-- record index silo directory
    #   root/silos/             <-- directory for silo directories


    #
    # Interpret the arguments ---------------------------------------
    #
    if( 1 == @options ) {
        unshift @options, 'BASE_PATH';
    }
    my( %options ) = @options;
    my $directory = $options{BASE_PATH};

    #
    # Make sure the path exists ---------------------------------------
    #
    make_path( $directory, { error => \my $err } );
    if( @$err ) {
        die "Error opening store : " . join ',',map { values %$_ } @$err;
    }
    
    #
    # Engage the master lock ---------------------------------------
    #
    open( my $master_fh, ">", "$directory/MASTER_LOCK" ) or die "Unable to create $directory/MASTER_LOCK : $!";
    flock( $master_fh, LOCK_EX );
    print $master_fh "MASTER LOCK";

    #
    # Ensure the directories ---------------------------------------
    #
    for my $subdir ( qw( USER_LOCKS silos TRANS/instances  ) ) {
        make_path( "$directory/$subdir", { error => \my $err } );
        if( @$err ) {
            die "Error opening store : " . join ',',map { values %$_ } @$err;
        }
    }

    #
    # Find the version of the database. ---------------------------------------
    #
    my $version;
    my $version_file = "$directory/VERSION";
    my $FH;
    if( -e $version_file ) {
        open $FH, "<", $version_file;
        $version = <$FH>;
        chomp $version;
        if( $version < 5 ) {
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
        open $FH, ">", $version_file;
        print $FH "$version\n";
    }
    close $FH;

    my $store =  bless {
        DIRECTORY    => $directory,
        MASTER_FH    => $master_fh,
        MASTER_LOCK_COUNT => 1,
        RECORD_INDEX => Data::RecordStore::Silo->open_silo( "ILL", "$directory/RECORD_INDEX_SILO" ),
        SILOS        => Data::RecordStore::SiloPack->new,
        VERSION      => $version,
        TRANSACTION  => [],
        LOCKS        => [],
    }, $cls;

    $store->_unlock_master;
    return $store;
} #open_store

sub _open_silo {
    my $self = shift;
    $self->_lock_master;
    my $silo = $self->{SILOS}->open_silo( @_ );
    $self->_unlock_master;
    return $silo;
}

sub _close_silo {
    my( $self, $silo ) = @_;
    $self->{SILOS}->clear_silo( $silo->{DIRECTORY} );
}

sub _lock_master {
    my $self = shift;
    flock( $self->{MASTER_FH}, LOCK_EX );
    $self->{MASTER_LOCK_COUNT}++;
}

sub _unlock_master {
    my $self = shift;
    if( 1 > --$self->{MASTER_LOCK_COUNT} ) {
        flock( $self->{MASTER_FH}, LOCK_UN );
    }
}

sub find_broken_ids {
    my $self = shift;
    my $index = $self->{RECORD_INDEX};
    my $size  = $index->entry_count;
    my $silos = [];
    my $problems = [];
    for( my $i=1; $i<=$size; $i++ ) {
        my($silo_id,$in_silo_idx,$update_time) = @{$index->get_record( $i )};
        next if $silo_id == 0;
        my $silo = $silos->[$silo_id];
        unless( $silo ) {
            $silo = $self->_get_silo( $silo_id );
            $silos->[$silo_id] = $silo;
        }
        my $ec = $silo->entry_count;
        if( $in_silo_idx > $ec ) {
            push @$problems, $i;
        }
    }
    return $problems;
} #find_broken_ids

sub detect_version {
    my( $cls, $dir ) = @_;
    my $ver_file = "$dir/VERSION";
    my $source_version;
    if ( -e $ver_file ) {
        open( my $FH, "<", $ver_file );
        $source_version = <$FH>;
        chomp $source_version;
        close $FH;
    }
    return $source_version;
} #detect_version

#
# If there is no current transaction, this starts one.
#
sub use_transaction {
    my $self = shift;
    my $trans = $self->{TRANSACTION}[0];
    return $trans if $trans;
    return $self->start_transaction;
}

sub commit_transaction {
    my $self = shift;
    my $trans = $self->{TRANSACTION}[0]; # it is removed in the commit call below
    if( $trans ) {
        $trans->commit;
    } else {
        warn "No transaction in progress";
    }
} #commit_transaction

sub rollback_transaction {
    my $self = shift;
    my $trans = $self->{TRANSACTION}[0]; # it is removed in the rollback call below
    if( $trans ) {
        $trans->rollback;
    } else {
        warn "No transaction in progress";
    }
} #rollback_transaction

sub start_transaction {
    my $self = shift;
    $self->_lock_master;
    my $trans = Data::RecordStore::Transaction->_create( $self );
    unshift @{$self->{TRANSACTION}}, $trans;
    $self->_unlock_master;
    return $trans;
} #start_transaction

sub list_transactions {
    my $self = shift;
    my $trans_directory = $self->_open_silo( "ILLI", "$self->{DIRECTORY}/TRANS/META" );
    $trans_directory->lock;
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
    $trans_directory->unlock;
    return @trans;
}

sub stow {
    my( $self, $data, $id ) = @_;
    print STDERR "STOW ($id) <$$>\n";
    my $trans = $self->{TRANSACTION}[0];
    if( $trans ) {
        return $trans->stow( $data, $id );
    }

    unless( defined $id ) {
        $id = $self->next_id(1);
    }

    if(  $id < 1 ) {
        die "ID must be a positive integer";
    }

    $self->_ensure_entry_count( $id );


    my $save_size = do { use bytes; length( $data ); };

    # tack on the size of the id (a long or 4 bytes) and the \0 (1 byte) to the byte count
    $save_size += 5;

    my( $current_silo_id, $current_id_in_silo, $update_time ) = @{ $self->{RECORD_INDEX}->get_record( $id ) };

    #
    # See if this record is already in a silo. If it is, see if it
    # should stay there or needs to move to a different sized silo.
    #
    my $old_silo = $current_silo_id ? $self->_get_silo( $current_silo_id ) : undef;

    my( $needs_swap, $needs_pop ) = ( 0, 0 );
    if( $old_silo ) {

        #
        # Nomove case.
        # Keep it in the same silo if the record is not too big for it
        # and the record takes at least a third of the space
        #
        if ( $save_size <= $old_silo->{RECORD_SIZE} &&
             ( $current_silo_id == 12 || $old_silo->{RECORD_SIZE} < (3 * $save_size) ) )
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
            $needs_swap = 1;
        }
        else {
            #
            # this is the last one in the old silo just pop it off, no swapping
            # needed.
            #
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

    #
    # Save this to the new silo and update the index
    #
    my $silo = $self->_get_silo( $silo_id );
    my $id_in_silo = $silo->next_id(1);
    print STDERR " STOW INDEX ($id_in_silo/$silo_id)\n";
    $self->{RECORD_INDEX}->put_record( $id, [ $silo_id, $id_in_silo, _time() ] );
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

    return $id;
} #stow

sub last_updated {
    my( $self, $id ) = @_;
    (undef,undef,my $update_time) = @{$self->{RECORD_INDEX}->get_record( $id )};
    return $update_time;
}

sub fetch {
    my( $self, $id ) = @_;
    print STDERR "FETCH ($id) <$$>\n";
    if( $id > $self->{RECORD_INDEX}->entry_count ) {
        print STDERR "    FETCH ($id) --> past index {empty} <$$>\n";
        return undef;
    }

    my( @trans ) = @{$self->{TRANSACTION}};
    my( $silo_id, $id_in_silo, $found_trans );

    # if an existing transaction, return any updates to it
    for my $trans (@trans) {
        my( $trans_id );
        next if $id > $trans->{ITEM_SILO}->entry_count; # this ID was not touched by this transaction
        ( $trans_id ) = @{ $trans->{ITEM_SILO}->get_record( $id ) };
        next unless $trans_id;
        my $trans_record = $trans->{ACTION_SILO}->get_record( $trans_id );
        my( $action, undef, undef, undef, $to_silo_id, $to_record_id ) = @$trans_record;
        if( $action eq 'S' ) {
            $found_trans = 1;
            ( $silo_id, $id_in_silo ) = ( $to_silo_id, $to_record_id );
        }
        else {
            return undef;
        }
        last;
    }

    unless( $found_trans ) {
        print STDERR "   FETCH FROM INDEX <$$>\n";
        ( $silo_id, $id_in_silo ) = @{ $self->{RECORD_INDEX}->get_record( $id ) };
    }
    unless( $silo_id ) {
        print STDERR "   FETCH ($id) --> undef <$$>\n";
        return undef;
    }
    print STDERR "FETCH ($id) --> ($id_in_silo/$silo_id) <$$>\n";
    my $silo = $self->_get_silo( $silo_id );

    # skip the included id, just get the data
    ( undef, my $data ) = @{ $silo->get_record( $id_in_silo ) };

    return $data;
} #fetch


# returns the size in bytes of the record store
sub size {
    my $self = shift;
    my $size = 0;
    my $silos = $self->_all_silos;
    for my $silo (@$silos) {
        $size += $silo->size;
    }
    return $size;
} #size

# entry count in the index
sub entry_count {
    my $self = shift;
    return $self->{RECORD_INDEX}->entry_count;
} #entry_count

# number of records marked reachable by the index
sub active_entry_count {
    my $self = shift;
    my $count = 0;
    for( my $id=1; $id<= $self->{RECORD_INDEX}->entry_count; $id++ ) {
        my( $silo_id, $id_in_silo ) = @{ $self->{RECORD_INDEX}->get_record( $id ) };
        $count++ if $silo_id;
    }
    return $count;
} #entry_count

# number of entries across all silos
sub record_count {
    my $self = shift;
    my $count = 0;
    my $silos = $self->_all_silos;
    for my $silo (@$silos) {
        $count += $silo->entry_count;
    }
    return $count;
} #record_count

sub delete_record {
    my( $self, $del_id, $no_unlock ) = @_;

    my $trans = $self->{TRANSACTION}[0];
    if( $trans ) {
        return $trans->delete_record( $del_id );
    }
    if( $del_id > $self->{RECORD_INDEX}->entry_count ) {
        return undef;
    }

    my( $from_silo_id, $current_id_in_silo ) = @{ $self->{RECORD_INDEX}->get_record( $del_id ) };

    unless( $from_silo_id ) {
        return;
    }

    my $from_silo = $self->_get_silo( $from_silo_id );
    $self->{RECORD_INDEX}->put_record( $del_id, [ 0, 0, 0 ] );
    $self->_swapout( $from_silo, $from_silo_id, $current_id_in_silo );

    return 1;
} #delete_record


sub has_id {
    my( $self, $id ) = @_;
    my $ec = $self->{RECORD_INDEX}->entry_count;

    return 0 if $ec < $id || $id < 1;

    my( $silo_id ) = @{ $self->{RECORD_INDEX}->get_record( $id ) };
    return $silo_id > 0;
} #has_id

sub next_id {
    my( $self ) = @_;
    my $ret = $self->{RECORD_INDEX}->next_id;
    print STDERR "NEXT ID : $ret <$$>\n";
    return $ret;
}

sub empty {
    my $self = shift;
    $self->_lock_master;
    my $silos = $self->_all_silos;
    $self->{RECORD_INDEX}->empty;
    for my $silo (@$silos) {
        $silo->empty;
    }
    $self->_unlock_master;
} #empty

# locks the given lock names
sub lock {
    my( $self, @locknames ) = @_;
    if( @{$self->{LOCKS}} ) {
        die "Data::RecordStore->lock cannot be called twice in a row without unlocking between";
    }
    $self->_lock_master;
    my @fhs;
    my %seen;
    my $failed;
    for my $name (sort @locknames) {
        next if $seen{$name}++;
        if( open my $fh, '>', "$self->{DIRECTORY}/USER_LOCKS/$name" ) {
            flock( $fh, LOCK_EX ); #WRITE LOCK
            $fh->autoflush(1);
            push @fhs, $fh;
        } else {
            $failed = 1;
        }
    }
    if( $failed ) {
        # it must be able to lock all the locks or it fails
        # if it failed, unlock any locks it managed to get
        for my $fh (@fhs) {
            flock( $fh, LOCK_UN );
        }
        die "Data::RecordStore->lock : lock failed";
    } else {
        push @{$self->{LOCKS}}, @fhs;
    }
    $self->_unlock_master;
} #lock

# unlocks all locks
sub unlock {
    my $self = shift;
    $self->_lock_master;
    my $fhs = $self->{LOCKS};
    for my $fh (@$fhs) {
        flock( $fh, LOCK_UN );
    }
    @$fhs = ();
    $self->_unlock_master;
} #unlock


# -///     PRIVATES    ///-

sub _time { #overridable for tests
    return time();
}


#
# Returns a list of all the silos created in this Data::RecordStore
#
sub _all_silos {
    my $self = shift;
    opendir my $DIR, "$self->{DIRECTORY}/silos";
    return [ map { /(\d+)_RECSTORE/; $self->_get_silo($1) } grep { /_RECSTORE/ } readdir($DIR) ];
} #_all_silos

#This makes sure there there are at least min_count
#entries in this record store. This creates empty
#records if needed.
sub _ensure_entry_count {
    shift->{RECORD_INDEX}->_ensure_entry_count( shift );
} #_ensure_entry_count


sub _get_silo {
    my( $self, $silo_index ) = @_;

    my $dir = "$self->{DIRECTORY}/silos/${silo_index}_RECSTORE";
    my $silo = $self->{SILOS}->fetch_silo($dir);
    return $silo if $silo;

    if( $silo_index > 40 ) { # ~ 1 TB
        die "TOO BIG SILOINDEX";
    }

    my $silo_row_size = 2 ** $silo_index;

    # storing first the size of the record, uuencode flag, then the bytes of the record
    $silo = $self->_open_silo( "LZ*", $dir, $silo_row_size );

    return $silo;
} #_get_silo

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
        my( $moving_id ) = unpack( $silo->{TMPL}, $data );
        my( $last_updated ) = $self->last_updated( $moving_id );

        $self->{RECORD_INDEX}->put_record( $moving_id, [ $silo_id, $vacated_silo_id, $last_updated ] );
    }

    # remove the record from the end. This is either the record being vacated or the
    # record that was moved into its place.
    return $silo->pop;

} #_swapout


# ----------- end Data::RecordStore


package Data::RecordStore::Silo;

use strict;
use warnings;
no warnings 'uninitialized';
no warnings 'numeric';

use Fcntl qw( :flock SEEK_SET );
use File::Path qw(make_path remove_tree);

# this really isn't much of a limit anymore, but...
# keeping it for now
$Data::RecordStore::Silo::MAX_SIZE = 2_000_000_000;
sub open_silo {
    my( $class, $template, $directory, $size ) = @_;

    my $template_size = $template =~ /\*/ ? 0 : do { use bytes; length( pack( $template ) ) };
    my $record_size = $size || $template_size;

    unless( -d $directory ) {
        die "Data::RecordStore::Silo->open_silo Error opening record store. $directory exists and is not a directory" if -e $directory;
        make_path( $directory, { error => \my $err } );
    }
    open( my $silo_lock_fh, ">", "$directory/SILO_LOCK" ) or die "Unable to create $directory/SILO_LOCK : $!";
    flock( $silo_lock_fh, LOCK_EX );
    print $silo_lock_fh "SILO LOCK";
    die "Data::RecordStore::Silo->open_sile error : given record size $size does not agree with template size $template_size" if $size && $template_size && $template_size != $size;
    die "Data::RecordStore::Silo->open_silo Cannot open a zero record sized fixed store" unless $record_size;
    my $file_max_records = int( $Data::RecordStore::Silo::MAX_SIZE / $record_size );
    if( $file_max_records == 0 ) {
        warn "Opening store at $directory with template '$template' of size $record_size which is above the set max size of $Data::RecordStore::Silo::MAX_SIZE. Allowing only one record per file for this size. ";
        $file_max_records = 1;
    }
    my $file_max_size = $file_max_records * $record_size;
    unless( -e "$directory/0" ){
        open( my $fh, ">", "$directory/0" ) or die "Data::RecordStore::Silo->open_silo : Unable to open '$directory/0' : $!";
        close $fh;
    }

    unless( -w "$directory/0" ) {
        die "Data::RecordStore::Silo->open_silo : Unable to open '$directory/0'";
    }

    my $silo = bless {
        DIRECTORY        => $directory,
        RECORD_SIZE      => $record_size,
        FILE_SIZE        => $file_max_size,
        FILE_MAX_RECORDS => $file_max_records,
        TMPL             => $template,
        FILE_HANDLES     => [],
        SILO_LOCK_FH     => $silo_lock_fh,
        SILO_LOCK_COUNT  => 1,
    }, $class;

    $silo->unlock;

    return $silo;
} #open_silo

sub lock {
    my $self = shift;
    if( 0 == $self->{SILO_LOCK_COUNT}++ ) {
        flock( $self->{SILO_LOCK_FH}, LOCK_EX );
    }

}

sub unlock {
    my $self = shift;
    if( 0 == --$self->{SILO_LOCK_COUNT} ) {
        flock( $self->{SILO_LOCK_FH}, LOCK_UN );
    }
}

sub empty {
    my $self = shift;
    $self->lock;
    my( $first, @files ) = map { "$self->{DIRECTORY}/$_" } $self->_files;
    truncate( $first, 0 ) // die "Unable to empty silo $self->{DIRECTORY}";
    for my $file (@files) {
        unlink( $file );
    }
    $self->unlock;
    return undef;
} #empty

sub size {
    my $self = shift;
    my @files = $self->_files;
    my $filesize;
    for my $file (@files) {
        $filesize += -s "$self->{DIRECTORY}/$file";
    }
    return $filesize;
}

sub entry_count {
    # return how many entries this silo has
    my $self = shift;
    my @files = $self->_files;
    my $filesize;
    for my $file (@files) {
        $filesize += -s "$self->{DIRECTORY}/$file";
    }
    return int( $filesize / $self->{RECORD_SIZE} );
} #entry_count

sub get_record {
    my( $self, $id ) = @_;

    print STDERR "Get Record ($id) <$$> $self->{DIRECTORY}\n";
    $self->lock;
    if( $id > $self->entry_count || $id < 1 ) {
        $self->unlock;
        die "Data::RecordStore::Silo->get_record : index $id out of bounds for silo $self->{DIRECTORY}. Silo has entry count of ".$self->entry_count;
    }

    my( $f_idx, $fh, $file, $file_id ) = $self->_fh( $id );

    my $seek_pos = $self->{RECORD_SIZE} * $f_idx;
    sysseek( $fh, $seek_pos, SEEK_SET );
    my $srv = sysread $fh, my $data, $self->{RECORD_SIZE};
    $self->unlock;

    return [unpack( $self->{TMPL}, $data )];
} #get_record

sub next_id {
    my( $self ) = @_;
    $self->lock;
    my $next_id = 1 + $self->entry_count;
    $self->_ensure_entry_count( $next_id );
    $self->unlock;
    return $next_id;
} #next_id


sub pop {
    my( $self ) = @_;
    print STDERR "POP <$$> $self->{DIRECTORY}\n";
    $self->lock;
    my $entries = $self->entry_count;
    unless( $entries ) {
        $self->unlock;
        return undef;
    }
    my $ret = $self->get_record( $entries );
    my( $idx_in_f, $fh, $file, $f_idx ) = $self->_fh( $entries );
    my $new_fs = (($entries-1) - ($f_idx * $self->{FILE_MAX_RECORDS}  ))*$self->{RECORD_SIZE};

    if( $new_fs || $file =~ m!/0$! ) {
        truncate $fh, $new_fs;
    } else {
        unlink $file;
        $self->_clearfh( $f_idx );
    }
    
    $self->unlock;
    return $ret;
} #pop

sub last_entry {
    my( $self ) = @_;
    print STDERR "LAST ENTRY <$$> $self->{DIRECTORY}\n";
    $self->lock;
    my $entries = $self->entry_count;
    unless( $entries ) {
        $self->unlock;
        return undef;
    }
    my $r = $self->get_record( $entries );
    $self->unlock;
    return $r;
} #last_entry

sub push {
    my( $self, $data ) = @_;
    print STDERR "PUSH <$$> $self->{DIRECTORY}\n";
    $self->lock;
    my $next_id = $self->next_id;

    # the problem is that the second file has stuff in it not sure how
    $self->put_record( $next_id, $data );
    $self->unlock;

    return $next_id;
} #push


sub put_record {
    my( $self, $id, $data ) = @_;
    print STDERR "PUT RECORD ($id) <$$> $self->{DIRECTORY}\n";
    $self->lock;

    if( $id > $self->entry_count || $id < 1 ) {
        $self->unlock;
        die "Data::RecordStore::Silo->put_record : index $id out of bounds for silo $self->{DIRECTORY}. Store has entry count of ".$self->entry_count;
    }

    my $to_write = pack ( $self->{TMPL}, ref $data ? @$data : $data );

    # allows the put_record to grow the data store by no more than one entry
    my $write_size = do { use bytes; length( $to_write ) };

    if( $write_size > $self->{RECORD_SIZE} ) {
        $self->unlock;
        die "Data::RecordStore::Silo->put_record : record size $write_size too large. Max is $self->{RECORD_SIZE}";
    }

    my( $idx_in_f, $fh, $file, $file_id ) = $self->_fh( $id );
    my $seek_pos = $self->{RECORD_SIZE} * ($idx_in_f);
    sysseek( $fh, $seek_pos, SEEK_SET );
    syswrite( $fh, $to_write );

    $self->unlock;
#    close $fh;

    return 1;
} #put_record

sub unlink_store {
    my $self = shift;
    remove_tree( $self->{DIRECTORY} );# // die "Data::RecordStore::Silo->unlink_store: Error unlinking store : $!";
} #unlink_store

#
# This copies a record from one index in the store to an other.
# This returns the data of record so copied. Note : idx designates an index beginning at zero as
# opposed to id, which starts with 1.
#
sub _copy_record {
    my( $self, $from_idx, $to_idx ) = @_;
    print STDERR "COPY RECORD ($from_idx->$to_idx) <$$> $self->{DIRECTORY}\n";
    $self->lock;
    if( $from_idx >= $self->entry_count || $from_idx < 0 ) {
        $self->unlock;
        die "Data::RecordStore::Silo->_copy_record : from_index $from_idx out of bounds. Store has entry count of ".$self->entry_count;
    }

    if( $to_idx >= $self->entry_count || $to_idx < 0 ) {
        $self->unlock;
        die "Data::RecordStore::Silo->_copy_record : to_index $to_idx out of bounds. Store has entry count of ".$self->entry_count;
    }

    my( $from_file_idx, $fh_from ) = $self->_fh($from_idx+1);
    my( $to_file_idx, $fh_to ) = $self->_fh($to_idx+1);
    my $seek_pos = $self->{RECORD_SIZE} * ($from_file_idx);
    sysseek $fh_from, $seek_pos, SEEK_SET;
    my $srv = sysread $fh_from, my $data, $self->{RECORD_SIZE};

    $seek_pos = $self->{RECORD_SIZE} * $to_file_idx;
    sysseek( $fh_to, $seek_pos, SEEK_SET );
    syswrite( $fh_to, $data );

    $self->unlock;

    return $data;
} #_copy_record


#Makes sure this silo has at least as many entries
#as the count given. This creates empty records if needed
#to rearch the target record count.
sub _ensure_entry_count {
    my( $self, $count ) = @_;
    print STDERR "ENSURE ($count) <$$> $self->{DIRECTORY}\n";
    my $needed = $count - $self->entry_count;

    if( $needed > 0 ) {
        $self->lock;
        my( @files ) = $self->_files;
        my $write_file = $files[$#files];

        my $existing_file_records = int( (-s "$self->{DIRECTORY}/$write_file" ) / $self->{RECORD_SIZE} );
        my $records_needed_to_fill = $self->{FILE_MAX_RECORDS} - $existing_file_records;
        $records_needed_to_fill = $needed if $records_needed_to_fill > $needed;

        if( $records_needed_to_fill > 0 ) {
            # fill the last file up with \0
            my $fh;
            unless( open( $fh, "+<", "$self->{DIRECTORY}/$write_file" ) ) {
                $self->unlock;
                die "Data::RecordStore::Silo->ensure_entry_count : Unable to open '$self->{DIRECTORY}/$write_file' : $!";
            }
            my $nulls = "\0" x ( $records_needed_to_fill * $self->{RECORD_SIZE} );
            my $seek_pos = $self->{RECORD_SIZE} * $existing_file_records;
            sysseek( $fh, $seek_pos, SEEK_SET );
            syswrite( $fh, $nulls );
            close $fh;

            $needed -= $records_needed_to_fill;
        }
        while( $needed > $self->{FILE_MAX_RECORDS} ) {
            # still needed, so create a new file
            $write_file++;

            if( -e "$self->{DIRECTORY}/$write_file" ) {
                $self->unlock;
                die "Data::RecordStore::Silo->ensure_entry_count : file $self->{DIRECTORY}/$write_file already exists";
            }
            open( my $fh, ">", "$self->{DIRECTORY}/$write_file" );
            my $nulls = "\0" x ( $self->{FILE_MAX_RECORDS} * $self->{RECORD_SIZE} );
            sysseek( $fh, 0, SEEK_SET );
            syswrite( $fh, $nulls );
            $needed -= $self->{FILE_MAX_RECORDS};
            close $fh;
        }
        if( $needed > 0 ) {
            # still needed, so create a new file
            $write_file++;

            if( -e "$self->{DIRECTORY}/$write_file" ) {
                $self->unlock;
                die "Data::RecordStore::Silo->ensure_entry_count : file $self->{DIRECTORY}/$write_file already exists";
            }
            open( my $fh, ">", "$self->{DIRECTORY}/$write_file" );
            my $nulls = "\0" x ( $needed * $self->{RECORD_SIZE} );
            sysseek( $fh, 0, SEEK_SET );
            syswrite( $fh, $nulls );
            close $fh;
        }
        $self->unlock;
    }
    return;
} #_ensure_entry_count

sub _clearfh {
    my( $self, $f_idx ) = @_;
    ( undef, my $fh ) = @{$self->{FILE_HANDLES}[$f_idx]||[]};
    if( $fh ) {
        close $fh;
    }
    $self->{FILE_HANDLES}[$f_idx] = undef;
}

#
# Takes an insertion id and returns
#   an insertion index for in the file
#   filehandle.
#   filepath/filename
#   which number file this is (0 is the first)
#
sub _fh {
    my( $self, $id ) = @_;

    my $f_idx = int( ($id-1) / $self->{FILE_MAX_RECORDS} );
    my $idx_in_f = ($id - ($f_idx*$self->{FILE_MAX_RECORDS})) - 1;
    
    my $fh_info = $self->{FILE_HANDLES}[$f_idx];
    if( $fh_info ) {
        $fh_info->[0] = $idx_in_f;
        return @$fh_info;
    }

    $self->lock;
    my @files = $self->_files;
    my $file = $files[$f_idx];

    my $fh;
    unless( open( $fh, "+<", "$self->{DIRECTORY}/$file" ) ) {
        $self->unlock;
        die "Data::RecordStore::Silo->_fh unable to open '$self->{DIRECTORY}/$file' : $! $?";
    }
    $fh->autoflush(1);
    # index in the file, $file handle, $file, $f_idx
    $fh_info = [$idx_in_f,$fh,"$self->{DIRECTORY}/$file",$f_idx];

    $self->{FILE_HANDLES}[$f_idx] = $fh_info;
    $self->unlock;
    return @$fh_info;

} #_fh

#
# Returns the list of filenames of the 'silos' of this store. They are numbers starting with 0
#
sub _files {
    my $self = shift;
    $self->lock;
    my $dh = $self->{DIR_HANDLE};
    if( $dh ) {
        rewinddir $dh;
    } else {
        unless( opendir( $dh, $self->{DIRECTORY} ) ) {
            $self->unlock;
            die "Data::RecordStore::Silo->_files : can't open $self->{DIRECTORY}\n";
        }
        $self->{DIR_HANDLE} = $dh;
    }
    my( @files ) = (sort { $a <=> $b } grep { $_ eq '0' || (-s "$self->{DIRECTORY}/$_") > 0 } grep { $_ > 0 || $_ eq '0' } readdir( $dh ) );
    $self->unlock;
    return @files;
} #_files

# ----------- end Data::RecordStore::Silo

package Data::RecordStore::SiloPack;

use strict;
use warnings;
no warnings 'uninitialized';
no warnings 'numeric';

use Fcntl qw( :flock SEEK_SET );
use File::Path qw(make_path remove_tree);

sub new {
    return bless {
        SILOS => {},
    }, shift;
}
sub clear_silos {
    my $self = shift;
    $self->{SILOS} = {};
}
sub clear_silo {
    my( $self, $dir ) = @_;
    delete $self->{SILOS}{$dir};
}
sub fetch_silo {
    my( $self, $dir ) = @_;
    return $self->{SILOS}{$dir};
}
sub open_silo {
    my $self = shift;
    my( $template, $directory, $size ) = @_;

    my $template_size = $template =~ /\*/ ? 0 : do { use bytes; length( pack( $template ) ) };
    my $record_size = $size || $template_size;

    my $silo = $self->{SILOS}{$directory};
    if( $silo ) {
        # check if the size and template are asked for
        if( $silo->{RECORD_SIZE} == $record_size && $silo->{TMPL} eq $template ) {
            return $silo;
        }
        warn "Asking for a silo of a different size from one that was already cached. Creating new";
    }
    $silo = Data::RecordStore::Silo->open_silo( @_ );
    $self->{SILOS}{$directory} = $silo;
    return $silo;
} #open_silo


# ----------- end Data::RecordStore::SiloPack

package Data::RecordStore::Transaction;

use constant {

    ID          => 0,
    PID         => 1,
    UPDATE_TIME => 2,
    STATE       => 3,

    TRA_ACTIVE           => 1,  # transaction has been created
    TRA_IN_COMMIT        => 2, # commit has been called, not yet completed
    TRA_IN_ROLLBACK      => 3, # commit has been called, has not yet completed
    TRA_CLEANUP_COMMIT   => 4, # everything in commit has been written, TRA is in process of being removed
    TRA_CLEANUP_ROLLBACK => 5, # everything in commit has been written, TRA is in process of being removed
    TRA_DONE             => 6, # transaction complete. It may be removed.
};

our @STATE_LOOKUP = ('Active',
                     'In Commit',
                     'In Rollback',
                     'In Commit Cleanup',
                     'In Rollback Cleanup',
                     'Done');

#
# Creates a new transaction or returns an existing one based on the data provided
#
sub _create {
    my( $pkg, $record_store, $trans_data ) = @_;

    # A transaction has the following
    # transaction id
    # process id
    # update time
    # state
    my $trans_dir = "$record_store->{DIRECTORY}/TRANS";
    my $trans_catalog = $record_store->_open_silo( "ILLI", "$trans_dir/META" );
    my $trans_id;

    # trans data is passed in when an existing transaction is loaded
    if( $trans_data ) {
        ($trans_id) = @$trans_data;
    }
    else {
        $trans_id   = $trans_catalog->next_id;
        $trans_data = [ $trans_id, $$, time, TRA_ACTIVE ];
        $trans_catalog->put_record( $trans_id, $trans_data );
    }

    # ACTION_SILO (idx is action id)
    #     action
    #     record id
    #     from silo id
    #     from silo record id
    #     to silo id
    #     to silo record id
    # ITEM_SILO (idx is record id)
    #     action id
    my $trans_obj    =  {
        ID           => $trans_id,
        RECORD_STORE => $record_store,
        ACTION_SILO  => $record_store->_open_silo(
            "ALILIL",
            "$trans_dir/instances/$trans_id",
        ),
        ITEM_SILO    => $record_store->_open_silo(
            "L",
            "$trans_dir/instances/D_$trans_id",
        ),
        DATA         => $trans_data,
        CATALOG      => $trans_catalog, #LLLI
    };
    return bless $trans_obj, $pkg;

} #_create


sub get_update_time { shift->{DATA}[UPDATE_TIME] }

sub get_process_id  { shift->{DATA}[PID] }

sub get_state       { shift->{DATA}[STATE] }

sub get_id          { shift->{DATA}[ID] }

sub stow {
    my( $self, $data, $id ) = @_;

    die "Data::RecordStore::Transaction::stow Error : is not active" unless $self->get_state == TRA_ACTIVE;

    my $action_silo = $self->{ACTION_SILO};
    my $item_silo   = $self->{ITEM_SILO};

    my $store = $self->{RECORD_STORE};

    unless( defined $id ) {
        $id = $store->next_id( 1 );
    }

    if( $id < 1 || int($id) != $id ) {
        die "ID must be a positive integer";
    }

    $store->_ensure_entry_count( $id );

    my $save_size = do { use bytes; length( $data ); };

    # tack on the size of the id (a long + \0 or 5 bytes) to the byte count
    $save_size += 5;
    my( $from_silo_id, $from_record_id ) = @{ $store->{RECORD_INDEX}->get_record( $id ) };

    my $to_silo_id = 12; # the min size

    if( $save_size > 4096 ) {
        $to_silo_id = log( $save_size ) / log( 2 );
        if( int( $to_silo_id ) < $to_silo_id ) {
            $to_silo_id = 1 + int( $to_silo_id );
        }
    }

    my $to_silo = $store->_get_silo( $to_silo_id );

    my $to_record_id = $to_silo->next_id(1);

    $to_silo->put_record( $to_record_id, [ $id, $data ] );

    my $next_action_id = $action_silo->next_id(1);

    # action (stow)
    # record id
    # from silo id
    # from silo idx
    # to silo id
    # to silo idx
    $action_silo->put_record( $next_action_id,
                              [ 'S', $id, $from_silo_id, $from_record_id, $to_silo_id, $to_record_id ] );

    $item_silo->_ensure_entry_count( $id );
    $item_silo->put_record( $id, [ $next_action_id ] );

    return $id;
} #stow


sub delete_record {
    my( $self, $id_to_delete ) = @_;
    die "Data::RecordStore::Transaction::delete_record Error : is not active" unless $self->get_state == TRA_ACTIVE;

    my $store = $self->{RECORD_STORE};
    my $action_silo = $self->{ACTION_SILO};
    my $item_silo   = $self->{ITEM_SILO};

    my( $from_silo_id, $from_record_id ) = @{ $store->{RECORD_INDEX}->get_record( $id_to_delete ) };
    my $next_action_id = $action_silo->next_id(1);
    $action_silo->put_record( $next_action_id,
                             [ 'D', $id_to_delete, $from_silo_id, $from_record_id, 0, 0 ] );
    $item_silo->_ensure_entry_count( $id_to_delete );
    $item_silo->put_record( $id_to_delete, [ $next_action_id ] );

    return 1;
} #delete_record

sub commit {
    my $self = shift;

    my $store = $self->{RECORD_STORE};

    my $trans = shift @{$store->{TRANSACTION}};

    unless( $trans eq $self ) {
        unshift @{$store->{TRANSACTION}}, $trans;
        die "Cannot commit outer transaction intil inner transactions have been committed";
    }

    my $state = $self->get_state;
    unless( $state == TRA_ACTIVE || $state == TRA_IN_COMMIT ||
            $state == TRA_IN_ROLLBACK || $state == TRA_CLEANUP_COMMIT ) {
        unshift @{$store->{TRANSACTION}}, $trans;
        die "Cannot commit transaction. Transaction state is ".$STATE_LOOKUP[$state];
    }

    my $index        = $store->{RECORD_INDEX};
    my $cat_silo     = $self->{CATALOG};
    my $action_silo  = $self->{ACTION_SILO};
    my $item_silo    = $self->{ITEM_SILO};

    my $trans_id = $self->{ID};

    $cat_silo->put_record( $trans_id, [ $trans_id, $$, Data::RecordStore::_time, TRA_IN_COMMIT ] );
    $self->{DATA}[STATE] = TRA_IN_COMMIT;

    my $actions = $action_silo->entry_count;

    #
    # In this phase, the indexes are updated to point to new locations
    # of updated (via stow) items.
    # The old locations are marked for purging, which occurs in a later
    # stage.
    #
    # Since a stow can occur MULTIple times for a single id, only the
    # last stow is acted upon.
    #
    my $purges = [];
    my( %foundid );
    for( my $a_id=$actions; $a_id > 0; $a_id-- ) {
        my $tstep = $action_silo->get_record($a_id);
        my( $action, $record_id, $from_silo_id, $from_record_id, $to_silo_id, $to_record_id ) = @$tstep;
        if( 0 == $foundid{$record_id}++ ) {
            # first time this record is acted upon
            if( $action eq 'S' ) {
                $index->put_record( $record_id, [ $to_silo_id, $to_record_id, Data::RecordStore::_time ] );
            }
            push @$purges, [ $action, $record_id, $from_silo_id, $from_record_id ];

        }
        elsif( $action eq 'S' ) {
            push @$purges, [ $action, $record_id, $to_silo_id, $to_record_id ];
        }
    }

    #
    # This clause deletes records, and deletes the old
    # locations of stowed entries.
    #
    $purges = [ sort { $b->[3] <=> $a->[3] } @$purges ];
    for my $purge (@$purges) {
        my( $action, $record_id, $from_silo_id, $from_record_id ) = @$purge;
        if ( $action eq 'S' ) {
            my $silo = $store->_get_silo( $from_silo_id );
            $store->_swapout( $silo, $from_silo_id, $from_record_id );
        } elsif ( $action eq 'D' ) {
            $store->delete_record( $record_id, 1 );
        }
    }

    #
    # Update the state of this transaction and remove the record.
    #
    $cat_silo->put_record( $trans_id, [ $trans_id, $$, Data::RecordStore::_time, TRA_DONE ] );
    $self->{DATA}[STATE] = TRA_DONE;

    $action_silo->unlink_store;
    $item_silo->unlink_store;
    $store->_close_silo( $action_silo );
    $store->_close_silo( $item_silo );

    return 1;
} #commit


sub rollback {
    my $self = shift;
    my $store = $self->{RECORD_STORE};
    my $trans = shift @{$store->{TRANSACTION}};

    my $state = $self->get_state;
    unless( $state == TRA_ACTIVE || $state == TRA_IN_COMMIT ||
            $state == TRA_IN_ROLLBACK || $state == TRA_CLEANUP_ROLLBACK ) {
        unshift @{$store->{TRANSACTION}}, $trans;
        die "Cannot rollback transaction. Transaction state is ".$STATE_LOOKUP[$state];
    }

    my $index       = $store->{RECORD_INDEX};
    my $cat_silo    = $self->{CATALOG};
    my $action_silo = $self->{ACTION_SILO};
    my $item_silo   = $self->{ITEM_SILO};
    my $trans_id    = $self->{ID};

    $cat_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_IN_ROLLBACK ] );
    $self->{DATA}[STATE] = TRA_IN_ROLLBACK;

    my $actions = $action_silo->entry_count;

    #
    # Rewire the index to the old silo/location
    #
    my( %swapout );
    for my $a_id (1..$actions) {
        my( $action, $record_id, $from_silo_id, $from_record_id, $to_silo_id, $to_record_id ) =
            @{ $action_silo->get_record($a_id) };
        if( $from_silo_id ) {
            $index->put_record( $record_id, [ $from_silo_id, $from_record_id, time ] );
        } else {
            $index->put_record( $record_id, [ 0, 0, 0 ] );
        }
        if( $to_silo_id ) {
            push @{$swapout{ $to_silo_id }}, $to_record_id;
        }
    }

    $cat_silo->put_record( $trans_id, [ $trans_id, $$, time, TRA_CLEANUP_ROLLBACK ] );
    $self->{DATA}[STATE] = TRA_CLEANUP_ROLLBACK;

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
    $self->{DATA}[STATE] = TRA_DONE;

    $action_silo->unlink_store;
    $item_silo->unlink_store;
    $store->_close_silo( $action_silo );
    $store->_close_silo( $item_silo );

    # if this is the last transaction, remove it from the list
    # of transactions
    if( $trans_id == $cat_silo->entry_count ) {
        $cat_silo->pop;
    }
    return;
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

 my $val = $store->fetch( $some_id );

 my $count = $store->entry_count;

 $store->delete_record( $id_to_remove ); #deletes the old record

 my $has_id = $store->has_id( $someother_id );

 $store->empty; # clears out store completely

=head1 DESCRIPTION

Data::RecordStore is a simple way to store serialized text or byte data.
It is written entirely in perl with no non-core dependencies.
It is designed to be both easy to set up and easy to use.
Space is automatically reclaimed when records are reycled or deleted.

Transactions (see below) can be created that stow records.
They come with the standard commit and rollback methods. If a process dies
in the middle of a commit or rollback, the operation can be reattempted.
Incomplete transactions are obtained by the store's 'list_transactions'
method.

Data::RecordStore operates directly and instantly on the file system.
It is not a daemon or server and is not thread safe. It can be used
in a thread safe manner if the controlling program uses locking mechanisms.


=head1 METHODS

=head2 open_store( options )

Constructs a data store according to the options.

Options

=over 2

=item BASE_PATH

The directory to construct this record store in.

=head2 size()

Reports the size in bytes of the items in the record store.
Remember that the minimum size of an item will be the block
size 4096. This size does not include the index.

=head2 detect_version( directory )

Tries to detect version of the record store in the directory.
Returns undef if it is unable to detect it.

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

=head2 last_updated( id )

Returns the timestamp that this record was last written to the database.

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

=head2 find_broken_ids

This is a report that scans the store for any ids that
do not map to stored entries

=head2 record_count

Scans the silos and returns a count of how many records
are contained in them.

=head2 entry_count

Returns how many record ids exist.

=head2 record_count

Return how many records there actually are.

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

=head2 lock( @names )

Adds an advisory (flock) lock for each of the unique names given.
This may not be called twice in a row without an unlock in between.

=head2 unlock

Unlocks all names locked by this thread

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

my $next_id = $store->next_id;

$transaction->stow( "MORE DATA", $next_id );

$transaction->delete_record( $someid );

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

=head1 HELPER METHODS

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

=head2 commit()

Commit applies

=head2 unlink_store

Removes the file for this record store entirely from the file system.

=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2015-2019 Eric Wolf. All rights reserved.
       This program is free software; you can redistribute it
       and/or modify it under the same terms as Perl itself.

=head1 VERSION
       Version 5.04  (Aug, 2019))

=cut
