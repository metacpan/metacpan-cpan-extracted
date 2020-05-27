package Data::AnyXfer::Elastic::Import::DataFile;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;
use Clone                      ();
use Path::Class                ();
use Path::Class::File          ();
use Path::Class::Dir           ();

use Class::Load                ();
use DateTime                   ();
use DateTime::Format::Strptime ();

use Sys::Hostname ();

use Data::AnyXfer::Elastic::Role::IndexInfo ();
use Data::AnyXfer::Elastic::Import::Storage                ();
use Data::AnyXfer::Elastic::Import::Storage::TempDirectory ();
use Data::AnyXfer::Elastic::Import::Storage::TarFile       ();
use Data::AnyXfer::Elastic::Import::Storage::LzmaFile      ();

use Data::AnyXfer::Elastic::Import::File          ();
use Data::AnyXfer::Elastic::Import::Utils::Buffer ();

with 'Data::AnyXfer::Elastic::Role::IndexInfo';

=head1 NAME

Data::AnyXfer::Elastic::Import::DataFile - Prepare and record data for
bulk import into Elasticsearch clusters

=head1 SYNOPSIS

    # Writing...

    my $datafile =
        Data::AnyXfer::Elastic::Import::DataFile->new(
        file => $file, # optional
        index => 'Interiors::IndexInfo',
    );

    while ( my $row = $rs->next ) {
        $datafile->add_document( $row );
    }

    my $pathclass_file = $datafile->write;


    # Reading...

    my $datafile =
        Core::Elasticsearch::Import::DataFile->read(
        file => $pathclass_file );

    # can then get the index info back out
    my $index_info = $datafile->index_info;

    # someone needing to stream the data out of the data file
    # would use the ->fetch_data interface
    $datafile->fetch_data(\&import_data);

=head1 DESCRIPTION

This module allows us to record a dataset for import into Elasticsearch,
which can then be 'played' into an Elasticsearch cluster via
L<Data::AnyXfer::Elastic::Importer>.

This allows us to ensure that the same data is imported to multiple
environments, and to later replay imports or load them into other
environments.

=cut

=head1 ATTRIBUTES

=over

=item B<file>

Optional. The datafile file destination. This must be a string, or a
an instance of L<Path::Class::File>.

If not supplied, but L</dir> B<IS> supplied, this instance will write
to a file within L<dir>, under a name matching the following pattern:

    import.<NAME>.<TIMESTAMP>-<HOSTNAME>.datafile'

Where name is C< INDEX || ALIAS || 'default' >.

B<compress> option also changes destination path.

=item B<dir>

Optional. The destination directory for the datafile.
If not supplied, we will switch to an underlying storage backend of
L<Data::AnyXfer::Elastic::Import::Storage::TempDirectory>.

Meaning no data will be persisted. The datafile instance can still
be passed around within the current process (or until this instance
goes out of scope).

=item B<storage>

Optional. Manually override the storage backend used to persist
the dataset.

Should be an object implementing
L<Data::AnyXfer::Elastic::Import::Storage>.

=item B<index_info>

Optional. A C<ClassName> or object instance implementing
L<Data::AnyXfer::Elastic::Role::IndexInfo>.

This will be recorded along with the data. This is simply a
convenience method versus specifically setting information
using L</GETTERS AND SETTERS>.

=item B<connect_hint>

 A connection hint for use with L<Data::AnyXfer::Elastic>.

 Currently supports C<undef> (unspecified), C<readonly>, or C<readwrite>.

=item B<part_size>

Optional. This is used for the datafile body containing the
data to be imported. It will determine the number of data
elements to store within a single storage entry, and will be the
maximum number of data structures held in memory at any one time.

You will need to reduce this number when storing large nested data
structures, and increase it as data structure size or memory limits
increase.

Defaults to: C<1000>

=item B<data_buffer_size>

Optional. This is used to determine how many documents must be added
to the datafile before it will contact the underlying storage entry.
This is closely related to the L</part_size>, as every time an item
is added to an entry, all of the data held on that part in memory must be
re-serialised and persisted.

You will need to increase this number when ingesting large numbers
of documents.

The fastest and most efficient value for this will be the same as your
maximum L</part_size>.

Defaults to: 25% of L</part_size>

=item B<timestamp>

Optional. This is the creation timestamp, and may be used in the
resulting datafile name.

=item B<compress>

Optional boolean. Defaults to 0. Turns LZMA compression on for
saving datafile. Appends '.lzma' to the filename. If B<file> is
provdied this will be moved to compress version.

=back

=cut

has file => (
    is  => 'rw',
    isa => InstanceOf['Path::Class::File'],
);

has dir => (
    is  => 'ro',
    isa => InstanceOf['Path::Class::Dir'],
);

has index_info => (
    is  => 'ro',
    isa => Object,
);

has connect_hint => (
    is  => 'ro',
    isa => Str,
);

has storage => (
    is   => 'rw',
    isa  => ConsumerOf['Data::AnyXfer::Elastic::Import::Storage'],
);

has part_size => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => 1000,
);

has data_buffer_size => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub {
        int( $_[0]->part_size / 4 );
    }
);

has timestamp => (
    is      => 'ro',
    isa     => InstanceOf['DateTime'],
    default => sub {
        return DateTime->now;
    }
);

has compress => (
    is      => 'ro',
    isa     => Bool,
    default => 0
);

has _contents => (
    is      => 'ro',
    isa     => HashRef[InstanceOf['Data::AnyXfer::Elastic::Import::File']],
    default => sub { {} },
);

has _temp_stash => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

has _data_buffer => (
    is      => 'ro',
    isa     => InstanceOf['Data::AnyXfer::Elastic::Import::Utils::Buffer'],
    builder => '_create_data_buffer',
);


use constant DOC_FILE_CREATED_INFO_KEY  => 'file_created';
use constant DOC_FILE_MODIFIED_INFO_KEY => 'file_modified';
use constant DOC_COUNT_INFO_KEY         => 'total_docs_count';


# CONSTRUCTION ROUTINES


sub BUILD {

    my $self = $_[0];

    # setup and validate instance

    # first resolve the index info, to make sure it's valid
    $self->_resolve_index_info;
    # now setup the target storage (or file and dir)
    $self->_setup_default_storage unless $self->storage;

    # initialise file info
    unless ( $self->file_info ) {
        $self->file_info(
            {   DOC_FILE_CREATED_INFO_KEY() => DateTime->now->iso8601,
                DOC_COUNT_INFO_KEY()        => 0,
            }
        );
    }

    # We look good
    return;
}


# Stash routines
# allows us to have data before we have storage
# this is for bootstrapping / initialisation

sub _add_to_stash {
    return $_[0]->_temp_stash->{ $_[1] } = $_[2];
}

sub _get_from_stash {
    return $_[0]->_temp_stash->{ $_[1] };
}

sub _flush_stash {

    my $self = $_[0];

    # replace stash and return the old contents
    my $vars = $self->_temp_stash;
    $self->_temp_stash( {} );
    return %$vars;
}



# MAIN DATAFILE INTERFACE

=head2 GETTERS AND SETTERS

B<Please see L<Data::AnyXfer::Elastic::Role::IndexInfo> for the
interface definition and information>.

=cut

sub alias {
    shift->_get_set_or_restore( 'alias', @_ );
}

sub index {
    shift->_get_set_or_restore( 'index', @_ );
}

sub type {
    shift->_get_set_or_restore( 'type', @_ );
}

sub mappings {
    shift->_get_set_or_restore( 'mappings', @_ );
}

sub es235_mappings {
    shift->_get_set_or_restore( 'es235_mappings', @_ );
}

sub settings {
    shift->_get_set_or_restore( 'settings', @_ );
}

sub warmers {
    shift->_get_set_or_restore( 'warmers', @_ );
}

sub aliases {
    shift->_get_set_or_restore( 'aliases', @_ );
}

sub silo {
    shift->_get_set_or_restore( 'silo', @_ );
}

sub file_info {
    shift->_get_set_or_restore( 'file_info', @_ );
}

=head3 author_comment

    $datafile->author_comment(
        'Imported from database "mystuff" on `mysql-db-1.myfqdn.net` @ 2015-10-04T12:56:21');

Use this to store useful information about where this data came from.

=cut


sub author_comment {
    shift->_get_set_or_restore( 'author_comment', @_ );
}


=head2 STATISTICS AND CONSISTENCY

=head3 get_document_count

    $datafile->get_document_count;

Try to find the document count for the complete datafile. Fast on non-legacy datafiles
as it will be pre-calculated from when it was authored.

=cut

sub get_document_count {

    my $self = $_[0];
    my $info = $self->file_info;

    return $info->{ +DOC_COUNT_INFO_KEY } || do {
        # XXX : For old datafiles created before statistics were recorded,
        # we have to resort to this extremely slow read-everything-in
        # to keep things working
        unless ( Data::AnyXfer->test ) {
            carp 'Datafile looks old. We are performing a slow datafile '
                . 'document count as there were no file stats available.';
        }
        my $c = 0;
        $self->fetch_data( sub { $c += scalar @_ } );
        return $c;
    };
}


=head2 READING AND WRITING

=cut

=head3 read

Synonym for L<new>

=cut

sub read { return shift->new(@_) }


=head3 fetch_data

    $datafile->fetch_data(\&import_data);

    sub import_data {

        my @data = @_;

        print join("\n", @data);
    }

Retrieves the import data in batches, and passes them to the
supplied callback for processing until we're exhausted.

=cut

sub fetch_data {

    my ( $self, $callback ) = @_;

    # retrieve the main data file entry
    my $file = $self->_get_contained_multipart_file_entry('data');

    # move to the start
    $file->reset;

    # keep retrieving data until exhausted
    while ( defined( my $data = $file->get ) ) {
        $callback->($data);
    }
    return 1;
}


=head3 add_document

    $datafile->add_document( { some => 'data' } );

Add another elasticsearch document to the datafile for import.

=cut

sub add_document {

    my ( $self, $document ) = @_;

    # special handling for DBIC results
    if ( UNIVERSAL::can( $document, 'isa' )
        && $document->isa('DBIx::Class::Row') )
    {
        $document = { $document->get_columns };
    }

    # add document to our default data file
    return $self->_data_buffer->push($document);
}


=head3 write

    my $file = $datafile->write;

Packages and writes the data out to the destination datafile.

=cut

sub write {

    my $self = $_[0];

    # flush the data buffer to cause remaining documents
    # to be serialised and written to storage instance
    $self->_data_buffer->flush;

    # update the modified date
    if ( my $info = $self->file_info ) {
        $info->{ +DOC_FILE_MODIFIED_INFO_KEY } = DateTime->now->iso8601;
        $self->file_info($info);
    }

    # tell storage to cleanup and persist to final
    # destination (and format)
    return $self->storage->save
        ? $self->storage->get_destination_info
        : undef;
}


=head2 UTILITY METHODS

=cut

=head3 export_index_info

    my $index_info = $datafile->export_index_info;

Convenience method which creates an ad-hoc
L<Data::AnyXfer::Elastic::IndexInfo|IndexInfo> instance representing
the datafile target info
(if this datafile were to be played by an importer as-is).

=cut

sub export_index_info {

    my $self = $_[0];

    return Data::AnyXfer::Elastic::IndexInfo->new(
        alias    => $self->alias,
        index    => $self->index,
        type     => $self->type,
        mappings => $self->mappings,
        settings => $self->settings,
        warmers  => $self->warmers,
        alises   => $self->aliases,
        silo     => $self->silo,
    );

}



# CONTENT MANAGEMENT


sub _reset {

    my $self = $_[0];

    # reset our default data file
    return $self->_get_contained_multipart_file_entry('data')->reset;
}


# Set or retrieve values at any time
sub _get_set_or_restore {

    my $self = shift;
    my ( $entry, $value ) = @_;

    # If there's no storage yet, use the stash
    # We need to do this for bootstrapping and to allow us to "appear"
    # functional before we are actually at a stage to configure a storage
    # backend
    unless ( $self->storage ) {
        return $value
            ? $self->_add_to_stash( $entry => $value )
            : $self->_get_from_stash($entry);
    }

    # Otherwise, use the storage
    $value = $self->_get_set_or_restore_from_storage(@_);
    # clone simple values for return (should be fairly cheap, and safer)
    return Clone::clone($value);
}


# Set or retrieve values specifically from the storage backend
# (not always safe to call)
sub _get_set_or_restore_from_storage {

    my ( $self, $entry, $value ) = @_;

    # retrieve the file entry
    my $file = $self->_get_contained_file_entry($entry);

    # perform set operation
    if ($value) {
        $file->clear;
        $file->add($value);
        return $value;
    }

    # or, perform get operation
    $file->reset;
    return $file->get;
}


# Get or create a simple contained file entry
sub _get_contained_file_entry {

    my ( $self, $entry ) = @_;

    # retrieve or create file entry (the file can already exist in storage)
    return $self->_contents->{$entry}
        ||= Data::AnyXfer::Elastic::Import::File->from(
        storage => $self->storage,
        name    => $entry,
        );
}


# Get or create a contained multipart file entry
sub _get_contained_multipart_file_entry {

    my ( $self, $entry ) = @_;

    # retrieve or create file entry (the file can already exist in storage)
    return $self->_contents->{$entry}
        ||= Data::AnyXfer::Elastic::Import::File->from(
        storage   => $self->storage,
        name      => $entry,
        part_size => $self->part_size,
        );
}


# Creates a buffer which adds data to the data file entry when filled
sub _create_data_buffer {

    my $self = $_[0];

    # create callback which adds the buffered data
    # to our underlying data file entry
    my $callback = sub {
        $self->_get_contained_multipart_file_entry('data')->add(@_);

        # increment the document count stats whenever we flush the buffer
        # XXX : adds some overhead for small buffer sizes, but if your
        # documents are big enough to warrant such a small buffer it will
        # be dwarfed by the serialisation time anyway
        if ( my $info = $self->file_info ) {

            # only increment the count for new datafiles
            # or files with an existing count
            # (any other case will mean an old datafile)
            if ( !$info->{ +DOC_FILE_CREATED_INFO_KEY }
                || defined $info->{ +DOC_COUNT_INFO_KEY } )
            {
                $info->{ +DOC_COUNT_INFO_KEY } += scalar @_;
                $self->file_info($info);
            }
        }
    };

    # configure and return the buffer instance
    return Data::AnyXfer::Elastic::Import::Utils::Buffer->new(
        max_size => $self->data_buffer_size,
        callback => $callback
    );
}



# STORAGE AND INDEX SETUP


sub _resolve_index_info {

    my $self = $_[0];

    my $index = $self->index_info;
    # bail if there's nothing to do yet
    return unless $index;

    unless ( ref $index ) {
        # if we were supplied a class name, make sure that it can be loaded
        Class::Load::load_class($index);
        $index = $index->new;
    }

    # extract index info and add it to the current datafile
    foreach (
        qw/ index type mappings es235_mappings
        settings warmers aliases silo alias /
        )
    {
        $self->$_( $index->$_ );
    }
    return 1;
}


sub _setup_default_storage {
    my $self = $_[0];


    my $file;
    # we need a target file or directory
    unless ( $file = $self->file ) {
        my $dir = $self->dir;

        if ($dir) {
            # setup target file within directory
            $file = $self->{file} = Path::Class::dir($dir)
                ->file( $self->_get_default_filename );

            # validate the target
            croak qq/DataFile target is not in a writable location! ($file)/
                unless ( -w $file->parent );
        }
    }

    # setup datafile compression
    if ( $self->compress && $file->stringify !~ qr/\.lzma$/ ) {
        $file = Path::Class::file( sprintf '%s.lzma', $file->stringify );
        $self->file($file);
    }

    # setup the storage backend
    $self->_configure_storage($file);



    # flush the stash to persist any values configured early
    my %stash = $self->_flush_stash;
    foreach ( keys %stash ) {
        $self->_get_set_or_restore_from_storage( $_, $stash{$_} );
    }

    # we're all done
    return 1;
}


sub _get_default_filename {

    my $self = $_[0];
    my $name = $self->alias || $self->index || 'default';

    ( my $timestamp = $self->timestamp ) =~ s/[-:T ]//g;
    my $hostname = Sys::Hostname::hostname();

    return sprintf 'import.%s.%s-%s.datafile', $name, $timestamp, $hostname;
}


sub _configure_storage {
    my ( $self, $file ) = @_;
    my $storage;

    if ($file) {
        my $storage_class = $self->_guess_storage_class($file);
        $storage = $storage_class->new( file => $file );
    } else {
        $storage
            = Data::AnyXfer::Elastic::Import::Storage::TempDirectory
            ->new;
    }

    # set this as our storage instance
    $self->storage($storage);

}


sub _guess_storage_class {
    my ( $self, $file ) = @_;

    $file->basename =~ qr/\.datafile\.lzma$/
        ? 'Data::AnyXfer::Elastic::Import::Storage::LzmaFile'
        : 'Data::AnyXfer::Elastic::Import::Storage::TarFile';
}


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

