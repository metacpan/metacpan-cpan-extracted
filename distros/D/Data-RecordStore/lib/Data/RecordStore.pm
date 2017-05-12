package Data::RecordStore;

=head1 NAME

Data::RecordStore - Simple and fast record based data store

=head1 SYNPOSIS

use Data::RecordStore;


my $store = Data::RecordStore->open( $directory );

my $data = "TEXT DATA OR BYTES";
my $id    = $store->stow( $data, $optionalID );

my $val   = $store->fetch( $id );

my $new_or_recycled_id = $store->next_id;

$store->stow( "MORE DATA", $new_or_recycled_id );

my $has = $store->has_id( $someid );

$store->empty_recycler;
$store->recycle( $dead_id );


=head1 DESCRIPTION

A simple and fast way to store arbitrary text or byte data.
It is written entirely in perl with no non-core dependencies. It is designed to be
both easy to set up and easy to use.

=head1 LIMITATIONS

Data::RecordStore is not meant to store huge amounts of data.
It will fail if it tries to create a file size greater than the
max allowed by the filesystem. This limitation may be removed in
subsequent versions. This limitation is most important when working
with sets of data that approach the max file size of the system
in question.

This is not written with thread safety in mind, so unexpected behavior
can occur when multiple Data::RecordStore objects open the same directory.
Locking coordination is currently the responsibility of the implementation.

=cut

use strict;
use warnings;

use Fcntl qw( SEEK_SET LOCK_EX LOCK_UN );
use File::Path qw(make_path);
use Data::Dumper;

use vars qw($VERSION);

$VERSION = '2.0';

=head1 METHODS

=head2 open( directory )

Takes a single argument - a directory, and constructs the data store in it.
The directory must be writeable or creatible. If a RecordStore already exists
there, it opens it, otherwise it creates a new one.

=cut
sub open {
    my( $pkg, $directory ) = @_;

    make_path( "$directory/stores", { error => \my $err } );
    if( @$err ) {
        my( $err ) = values %{ $err->[0] };
        die $err;
    }
    my $obj_db_filename = "$directory/OBJ_INDEX";

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
    } else {
        #
        # a version file needs to be created. if the database
        # had been created and no version exists, assume it is
        # version 1.
        #
        if( -e $obj_db_filename ) {
            die "opening $directory. A database was found with no version information and is assumed to be an old format. Please run the conversion program.";
        }
        $version = $VERSION;
        CORE::open $FH, ">", $version_file;
        print $FH "$version\n";
    }
    close $FH;

    my $self = {
        DIRECTORY => $directory,
        OBJ_INDEX => Data::RecordStore::FixedStore->open( "IL", $obj_db_filename ),
        RECYC_STORE => Data::RecordStore::FixedStore->open( "L", "$directory/RECYC" ),
        STORES    => [],
        VERSION   => $version,
    };

    if( $version < 2 ) {
        $self->{STORE_IDX} = Data::RecordStore::FixedStore->open( "I", "$directory/STORE_INDEX" );
    }

    bless $self, ref( $pkg ) || $pkg;

} #open

=head2 entry_count

Returns how many entries are in this store.

=cut
sub entry_count {
    shift->{OBJ_INDEX}->entry_count;
}

=head2 ensure_entry_count( min_count )

This makes sure there there are at least min_count
entries in this record store. This creates empty
records if needed.

=cut
sub ensure_entry_count {
    shift->{OBJ_INDEX}->ensure_entry_count( shift );
} #ensure_entry_count

=head2 set_entry_count( min_count )

This makes sure there there are exactly
entries in this record store. This creates empty
records or removes existing ones as needed.
Use with caution.

=cut
sub set_entry_count {
    shift->{OBJ_INDEX}->set_entry_count( shift );
} #set_entry_count


=head2 next_id

This sets up a new empty record and returns the
id for it.

=cut
sub next_id {
    my $self = shift;
    my $next = $self->{RECYC_STORE}->pop;
    return $next->[0] if $next && $next->[0];
    $self->{OBJ_INDEX}->next_id;
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


    $id //= $self->{OBJ_INDEX}->next_id;


    my $save_size = do { use bytes; length( $data ); };

    # tack on the size of the id (a long or 8 bytes) to the byte count
    $save_size += 8;

    my( $current_store_id, $current_idx_in_store ) = @{ $self->{OBJ_INDEX}->get_record( $id ) };

    #
    # Check if this record had been saved before, and that the
    # store is was in has a large enough record size.
    #
    if( $current_store_id ) {
        my $old_store = $self->_get_store( $current_store_id );

        warn "object '$id' references store '$current_store_id' which does not exist" unless $old_store;

        # if the data isn't too big or too small for the table, keep it where it is and return
        if( $old_store->{RECORD_SIZE} >= $save_size && $old_store->{RECORD_SIZE} < 3 * $save_size ) {
            $old_store->put_record( $current_idx_in_store, [$id,$data] );
            return $id;
        }

        #
        # the old store was not big enough (or missing), so remove its record from
        # there, compacting it if possible
        #
        $self->_swapout( $old_store, $current_store_id, $current_idx_in_store );

    } #if this already had been saved before

    my $store_id = 1 + int( log( $save_size ) );

    my $store = $self->_get_store( $store_id );

    my $entry_count = $store->entry_count;

    my $index_in_store = $store->next_id;

    $self->{OBJ_INDEX}->put_record( $id, [ $store_id, $index_in_store ] );

    $store->put_record( $index_in_store, [ $id, $data ] );

    $id;
} #stow

sub delete {
    my( $self, $del_id ) = @_;
    my( $from_store_id, $current_idx_in_store ) = @{ $self->{OBJ_INDEX}->get_record( $del_id ) };

    return unless $from_store_id;

    my $from_store = $self->_get_store( $from_store_id );
    $self->_swapout( $from_store, $from_store_id, $current_idx_in_store );
    $self->{OBJ_INDEX}->put_record( $del_id, [ 0, 0 ] );
    1;
} #delete

sub _swapout {
    my( $self, $store, $store_id, $vacated_store_idx ) = @_;

    my $last_idx = $store->entry_count;
    my $fh = $store->_filehandle;

    if( $vacated_store_idx < $last_idx ) {

        sysseek $fh, $store->{RECORD_SIZE} * ($last_idx-1), SEEK_SET or die "Could not seek ($store->{RECORD_SIZE} * ($last_idx-1)) : $@ $!";
        my $srv = sysread $fh, my $data, $store->{RECORD_SIZE};
        defined( $srv ) or die "Could not read : $@ $!";
        sysseek( $fh, $store->{RECORD_SIZE} * ( $vacated_store_idx - 1 ), SEEK_SET ) && ( my $swv = syswrite( $fh, $data ) );
        defined( $srv ) or die "Could not read : $@ $!";

        #
        # update the object db with the new store index for the moved object id
        #
        my( $moving_id ) = unpack( $store->{TMPL}, $data );

        $self->{OBJ_INDEX}->put_record( $moving_id, [ $store_id, $vacated_store_idx ] );

        #
        # truncate the object file
        #
    }

    #
    # truncate now that the store is one record shorter
    #
    truncate $fh, $store->{RECORD_SIZE} * ($last_idx-1);

} #_swapout

=head2 has_id( id )

  Returns true if an object with this db exists in the record store.

=cut
sub has_id {
    my( $self, $id ) = @_;
    my $ec = $self->entry_count;
    return 0 if $ec < $id;

    my( $store_id ) = @{ $self->{OBJ_INDEX}->get_record( $id ) };
    $store_id > 0;
}

=head2 empty_recycler()

  Clears out all data from the recycler

=cut
sub empty_recycler {
    shift->{RECYC_STORE}->empty;
} #empty_recycler

=head2 recycle( $id )

  Ads the id to the recycler, so it will be returned when next_id is called.

=cut
sub recycle {
    shift->{RECYC_STORE}->push( [shift] );
} #empty_recycler


=head2 fetch( id )

Returns the record associated with the ID. If the ID has no
record associated with it, undef is returned.

=cut
sub fetch {
    my( $self, $id ) = @_;
    my( $store_id, $id_in_store ) = @{ $self->{OBJ_INDEX}->get_record( $id ) };
    return undef unless $store_id;

    my $store = $self->_get_store( $store_id );

    # skip the included id, just get the data
    ( undef, my $data ) = @{ $store->get_record( $id_in_store ) };

    $data;
} #fetch

=head2 all_stores

Returns a list of all the stores created in this Data::RecordStore

=cut
sub all_stores {
    my $self = shift;
    opendir my $DIR, "$self->{DIRECTORY}/stores";
    [ map { /(\d+)_OBJSTORE/; $self->_get_store($1) } grep { /_OBJSTORE/ } readdir($DIR) ];
} #all_stores

sub _get_store {
    my( $self, $store_index ) = @_;

    if( $self->{STORES}[ $store_index ] ) {
        return $self->{STORES}[ $store_index ];
    }

    my $store_size = int( exp $store_index );

    # storing first the size of the record, then the bytes of the record
    my $store = Data::RecordStore::FixedStore->open( "LZ*", "$self->{DIRECTORY}/stores/${store_index}_OBJSTORE", $store_size );

    $self->{STORES}[ $store_index ] = $store;
    $store;
} #_get_store

=head2 convert( $source_dir, $dest_dir )

Copies the database from source dir into dest dir while converting it
to version 2. This does nothing if the source dir database is already
at version 2

=cut
sub convert {
    my( $source_dir, $dest_dir ) = @ARGV;
    die "Usage : converter.pl <db source dir> <db target dir>" unless $source_dir && $dest_dir;

    my $source_obj_idx_file = "$source_dir/OBJ_INDEX";
    my $dest_obj_idx_file = "$dest_dir/OBJ_INDEX";
    die "Database not found in directory '$source_dir'" unless -f $source_obj_idx_file;

    my $ver_file = "$source_dir/VERSION";
    my $source_version = 1;
    if ( -e $ver_file ) {
        Core::open( my $FH, "<", $ver_file );
        $source_version = <$FH>;
        chomp $source_version;
        close $FH;
    }

    if ( $source_version >= 2 ) {
        print STDERR "Database at '$source_dir' already at version $source_version. Doing nothing\n";
        exit;
    }

    print STDERR "Convert from $source_version to $Data::RecordStore::VERSION\n";


    die "Directory '$dest_dir' already exists" if -d $dest_dir;

    print STDERR "Creating destination dir\n";

    mkdir $dest_dir or die "Unable to create directory '$dest_dir'";
    mkdir "$dest_dir/stores" or die "Unable to create directory '$dest_dir/stores'";

    print STDERR "Starting Convertes from $source_version to $Data::RecordStore::VERSION\n";

    my $store_db = Data::RecordStore::FixedStore->open( "I", "$source_dir/STORE_INDEX" );

    #my @old_sizes;
    my $source_dbs = [];
    my $dest_dbs = [];

    for my $id (1..$store_db->entry_count) {
        my( $size ) = @{ $store_db->get_record( $id ) };
        #    $source_sizes[$id] = $size;

        $source_dbs->[$id] = Data::RecordStore::FixedStore->open( "A*", "$source_dir/${id}_OBJSTORE", $size );
    
        #    my( $data ) = @{ $source_dbs->[$id]->get_record( 1 ) };
        #    print STDERR "$id:0) $data\n";
    }


    my $source_obj_db = Data::RecordStore::FixedStore->open( "IL", $source_obj_idx_file );
    my $dest_obj_db = Data::RecordStore::FixedStore->open( "IL", $dest_obj_idx_file );
    $dest_obj_db->ensure_entry_count($source_obj_db->entry_count);

    my $tenth = int($source_obj_db->entry_count/10);
    my $count = 0;

    for my $id (1..$source_obj_db->entry_count) {
        my( $source_store_id, $id_in_old_store ) = @{ $source_obj_db->get_record( $id ) };

        #    print STDERR "id ($id) in $source_store_id/$id_in_old_store\n";next;

    
        next unless $id_in_old_store;

        # grab data
        my( $data ) = @{ $source_dbs->[$source_store_id]->get_record( $id_in_old_store ) };

        # store in new database
        my $save_size = do { use bytes; length( $data ); };
        $save_size += 8;        #for the id
        my $dest_store_id = 1 + int( log( $save_size ) );
        my $dest_store_size = int( exp $dest_store_id );

        my $dest_db = $dest_dbs->[$dest_store_id];
        unless( $dest_db ) {
            $dest_db = Data::RecordStore::FixedStore->open( "LZ*", "$dest_dir/stores/${dest_store_id}_OBJSTORE", $dest_store_size );
            $dest_dbs->[$dest_store_id] = $dest_db;
        }
        my $idx_in_dest_store = $dest_db->next_id;
        $dest_db->put_record( $idx_in_dest_store, [ $id, $data ] );

        $dest_obj_db->put_record( $id, [ $dest_store_id, $idx_in_dest_store ] );
        if ( ++$count > $tenth ) {
            print STDERR ".";
            $count = 0;
        }

    }
    print STDERR "\n";

    print STDERR "Adding version information\n";

    CORE::open( my $FH, ">", "$dest_dir/VERSION");
    print $FH "$Data::RecordStore::VERSION\n";
    close $FH;


    print STDERR "Done. Remember that your new database is in $dest_dir and your old one is in $source_dir\n";

}

# ----------- end Data::RecordStore
=head1 HELPER PACKAGES

Data::RecordStore relies on two helper packages that are useful in
their own right and are documented here.

=head1 HELPER PACKAGE

Data::RecordStore::FixedStore

=head1 DESCRIPTION

A fixed record store that uses perl pack and unpack templates to store
identically sized sets of data and uses a single file to do so.

=head1 SYNOPSIS

my $template = "LII"; # perl pack template. See perl pack/unpack.

my $size;   #required if the template does not have a definite size, like A*

my $store = Data::RecordStore::FixedStore->open( $template, $filename, $size );

my $new_id = $store->next_id;

$store->put_record( $id, [ 321421424243, 12, 345 ] );

my $more_data = $store->get_record( $other_id );

my $removed_last = $store->pop;

my $last_id = $store->push( $data_at_the_end );

my $entries = $store->entry_count;

if( $entries < $min ) {

    $store->ensure_entry_count( $min );

}

$store->emtpy;

$store->unlink_store;

=head1 METHODS

=cut
package Data::RecordStore::FixedStore;

use strict;
use warnings;
no warnings 'uninitialized';

use Fcntl qw( SEEK_SET LOCK_EX LOCK_UN );
use File::Copy;

=head2 open( template, filename, size )

Opens or creates the file given as a fixed record
length data store. If a size is not given,
it calculates the size from the template, if it can.
This will die if a zero byte record size is determined.

=cut
sub open {
    my( $pkg, $template, $filename, $size ) = @_;
    my $class = ref( $pkg ) || $pkg;
    my $FH;
    my $useSize = $size || do { use bytes; length( pack( $template ) ) };
    die "Cannot open a zero record sized fixed store" unless $useSize;
    unless( -e $filename ) {
        CORE::open $FH, ">", $filename;
        print $FH "";
        close $FH;
    }
    CORE::open $FH, "+<", $filename or die "$@ $!";
    bless { TMPL => $template,
            RECORD_SIZE => $useSize,
            FILENAME => $filename,
    }, $class;
} #open

=head2 empty

This empties out the database, setting it to zero records.

=cut
sub empty {
    my $self = shift;
    my $fh = $self->_filehandle;
    truncate $self->{FILENAME}, 0;
    undef;
} #empty

=head2 ensure_entry_count( count )

Makes sure the data store has at least as many entries
as the count given. This creates empty records if needed
to rearch the target record count.

=cut
sub ensure_entry_count {
    my( $self, $count ) = @_;

    my $needed = $count - $self->entry_count;

    if( $needed > 0 ) {
        my $fh = $self->_filehandle;
        truncate $fh, $count * $self->{RECORD_SIZE};
    }

} #ensure_entry_count

=head2 set_entry_count( count )

Sets the number of entries in this record store,
growing or shrinking as necessary.

=cut
sub set_entry_count {
    my( $self, $count ) = @_;
    my $fh = $self->_filehandle;

    truncate $fh, $count * $self->{RECORD_SIZE};

} #set_entry_count


=head2

Returns the number of entries in this store.
This is the same as the size of the file divided
by the record size.

=cut
sub entry_count {
    # return how many entries this index has
    my $self = shift;
    my $fh = $self->_filehandle;
    my $filesize = -s $self->{FILENAME};
    int( $filesize / $self->{RECORD_SIZE} );
}

=head2 get_record( idx )

Returns an arrayref representing the record with the given id.
The array in question is the unpacked template.

=cut
sub get_record {
    my( $self, $idx ) = @_;

    my $fh = $self->_filehandle;

# how about an ensure_entry_count right here?
    # also a has_record
    if( $idx < 1 ) {
        die "get record must be a positive integer";
    }


    sysseek $fh, $self->{RECORD_SIZE} * ($idx-1), SEEK_SET or die "Could not seek ($self->{RECORD_SIZE} * ($idx-1)) : $@ $!";

    my $srv = sysread $fh, my $data, $self->{RECORD_SIZE};
    
    defined( $srv ) or die "Could not read : $@ $!";
    [unpack( $self->{TMPL}, $data )];
} #get_record

=head2 has_id( id )

Returns true if an object with this db exists in the record store.

=cut
sub has_id {
    my( $self, $id ) = @_;
    $self->{OBJ_INDEX}->has_id( $id );
}

=head2 next_id

adds an empty record and returns its id, starting with 1

=cut
sub next_id {
    my( $self ) = @_;
    my $fh = $self->_filehandle;
    my $next_id = 1 + $self->entry_count;
    $self->ensure_entry_count( $next_id );
    $next_id;
} #next_id


=head2 pop

Remove the last record and return it.

=cut
sub pop {
    my( $self ) = @_;

    my $entries = $self->entry_count;
    return undef unless $entries;
    my $ret = $self->get_record( $entries );
    truncate $self->_filehandle, ($entries-1) * $self->{RECORD_SIZE};
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
    my $fh = $self->_filehandle;
    my $next_id = 1 + $self->entry_count;
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
    my( $self, $idx, $data ) = @_;

    my $fh = $self->_filehandle;

    my $to_write = pack ( $self->{TMPL}, ref $data ? @$data : $data );
    # allows the put_record to grow the data store by no more than one entry

    die "Index $idx out of bounds. Store has entry count of ".$self->entry_count if $idx > (1+$self->entry_count);

    sysseek( $fh, $self->{RECORD_SIZE} * ($idx-1), SEEK_SET ) && ( my $swv = syswrite( $fh, $to_write ) );
    1;
} #put_record

=head2 unlink_store

Removes the file for this record store entirely from the file system.

=cut
sub unlink_store {
    # TODO : more checks
    my $self = shift;
    close $self->_filehandle;
    unlink $self->{FILENAME};
}

sub _filehandle {
    my $self = shift;
    CORE::open( my $fh, "+<", $self->{FILENAME} );
    $fh;
}


# ----------- end Data::RecordStore::FixedStore

1;

__END__


=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2015 Eric Wolf. All rights reserved.  This program is free software; you can redistribute it and/or modify it
       under the same terms as Perl itself.

=head1 VERSION
       Version 2.0  (Feb 23, 2017))

=cut
