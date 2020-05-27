package Data::AnyXfer::Elastic::Import::Storage::Directory;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;
use Path::Class           ();
use File::Copy::Recursive ();
use Data::AnyXfer         ();

=head1 NAME

Data::AnyXfer::Elastic::Import::Storage::Directory -
 Filesystem directory-based import storage

=head1 SYNOPSIS

    my $storage =
        Data::AnyXfer::Elastic::Import::Storage::Directory->new;

    $storage->set(
        company => 'Limited',
        address =>
            'Building One, Chiswick Park, 566 Chiswick High Road, London W4 5BE',
        regno => 1680058,
    );

    $storage->save;

=head1 DESCRIPTION

This module implements L<Data::AnyXfer::Elastic::Import::Storage>,
based on filesystem directories.

It uses temporary working directories, with persistence to an optional final
target directory on L<Data::AnyXfer::Elastic::Import::Storage/save>.

It represents items as single files, and can only store printable characters
(i.e. any complex content should be serialised to a representable format
before being passed to this module to store).

=cut

=head1 ATTRIBUTES

=over

=item B<dir>

Optional. The final target directory that data should be persisted to.

=item B<working_dir>

Optional. The temporary directory data should be written to as operations are performed
on this instance.

=item B<item_file_suffix>

Optional. A string that will be appended to the end of every item name transparently
when written to storage (will not be visible through the storage interface).

You can also use this for file extensions.

=item B<item_file_prefix>

Optional. A string that will be prepended to the start of every item name transparently
when written to storage (will not be visible through the storage interface).

=back

=head1 STORAGE INTERFACE

B<Please see L<Data::AnyXfer::Elastic::Import::Storage> for the
interface definition and information>.

=cut


# ATTRIBUTES


has dir => (
    is      => 'ro',
    isa     => InstanceOf['Path::Class::Dir'],
    builder => '_setup_default_dir',
);

has read_only => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has working_dir => (
    is      => 'ro',
    isa     => InstanceOf['Path::Class::Dir'],
    lazy    => 1,
    builder => '_setup_and_init_working_dir',
);

has item_file_suffix => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

has item_file_prefix => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

has destination_info => (
    is  => 'ro',
    isa => Str,
);

has _item_list => (
    is      => 'bare',
    isa     => ArrayRef,
    default => sub { [] },
);

has _item_map => (
    is      => 'bare',
    isa     => HashRef,
    default => sub { {} },
);

# set the destination string to the dir path
sub get_destination_info {
    my $self = shift;
    return $self->destination_info || $self->dir . '';
}


# CONSUME STORAGE ROLE
with 'Data::AnyXfer::Elastic::Import::Storage';



# CONSTRUCTOR ROUTINES


sub BUILD {

    my $self = $_[0];

    # if we're in read-only mode, use the target directory as the
    # working tree, as all modification ops are disabled
    if ( $self->read_only ) {
        $self->{working_dir} = $self->dir;
    }

    # load in current directory state
    # from final dir, not temp dir
    $self->reload;
}


=head2 ADDITIONAL METHODS

=cut

# GENERAL STORAGE INTERFACE


=head3 search

    my @item_names = $storage->search('test');
    # e.g. returns ( 'a_test_item', 'this_has_test_in_the_name_also' )

Searches the storage instance for any item names containing the supplied
substring.

Returns a list of matching item names.

=cut

sub search {

    my ( $self, $name_part ) = @_;
    # name_part should be a plain string!

    # escape name part we're searching for
    my $pat = $self->convert_item_name($name_part);
    # filter items containing the resulting
    # string anywhere in their names
    return grep {/^.*$pat.*$/} $self->list_items;
}

sub list_items {
    return @{ $_[0]->{_item_list} };
}


sub add_item {

    my $self = shift;
    croak 'Cannot perform add item. Datafile storage in read-only mode!'
        if $self->read_only;

    return ( scalar $self->create_file_item(@_) ) ? 1 : 0;
}


sub set_item {

    my ( $self, $name, $value ) = @_;

    croak 'Cannot perform set item. Datafile storage in read-only mode!'
        if $self->read_only;

    # create the file (also write to the new file)
    my ( $status, $file ) = $self->create_file_item( $name, $value );
    # overwrite the contents if it already existed
    $file->spew( iomode => '>:raw', $value ) unless $status;

    # we always succeed (otherwise we died)
    return 1;
}


sub remove_item {

    my ( $self, $name ) = @_;

    croak 'Cannot perform remove item. Datafile storage in read-only mode!'
        if $self->read_only;

    my $item_map = $self->{_item_map};
    my $fname    = $self->convert_item_name($name);

    my $file = $item_map->{$fname};
    if ( $file && -e $file ) {

        # try to remove, if it fails, bail
        $file->remove or return 0;
        # otherwise we can cleanup the mapping etc.
        delete $item_map->{$fname};
        return 1;
    }
    return 0;
}


sub get_item {

    my ( $self, $name ) = @_;

    # find the mapped file for the item
    my $file = $self->{_item_map}->{ $self->convert_item_name($name) };

    # if a mapping exists, it should be safe to slurp
    # otherwise we return undef when an item does not exist at all
    # (an item should never 'exist' without a mapped file)
    return $file ? $file->slurp( iomode => '<:raw' ) : undef;
}


sub reload {

    my $self = $_[0];

    # find all files under our directory
    my @files = grep { !$_->is_dir } $self->working_dir->children;

    # create and store a list of their names
    my $list = $self->{_item_list} = [ map { $_->basename } @files ];

    # create and store a map of names to file objects
    my %item_map = ();
    @item_map{ @{$list} } = @files;
    $self->{_item_map} = \%item_map;

    # return indicating success
    return 1;
}


sub save {

    my $self = $_[0];

    croak 'Cannot perform save. Datafile storage in read-only mode!'
        if $self->read_only;

    # we can only save if we have a final dir set
    if ( $self->dir ) {
        # remove any exising files in final dir
        $self->dir->rmtree;

        # copy files over to final path
        unless (
            File::Copy::Recursive::dircopy( $self->working_dir, $self->dir ) )
        {
            croak 'Failed to save datafile directory to: ' . $self->dir;
        }
        return 1;
    }

    # can't save as this is a temp storage inst
    return 0;
}

sub cleanup {
    return $_[0]->working_dir->rmtree ? 1 : 0;
}



# DIRECTORY STORAGE-SPECIFIC METHODS

=head3 create_file_item

    my ( $status, $fh ) = $self->create_file_item('item_1', 'Hello World!');

Adds a new item, containing the supplied content. Fails if an item under the
specified name already exists.

In scalar context returns a boolean indicating success or failure.
In list context returns the boolean status value followed by a
L<Path::Class::File> object pointing to the underlying file.

=cut

sub create_file_item {

    my ( $self, $name, $value ) = @_;

    my $item_map = $self->{_item_map};
    my $fname    = $self->convert_item_name($name);
    my $file;

    # if the file doesn't exist, add it as an item
    unless ( $file = $item_map->{$fname} ) {

        # initialise the file
        $file = $self->working_dir->file($fname);
        $file->touch;

        # setup mappings
        $item_map->{$fname} = $file;
        push @{ $self->{_item_list} }, $fname;

        # if there's a value, write it out
        # (in list context, we also return the file also)
        $file->spew( iomode => '>:raw', $value ) if $value;
        return wantarray() ? ( 1, $file ) : 1;
    }

    # otherwise fail
    # (in list context, we also return the file also)
    return wantarray() ? ( 0, $file ) : 0;
}


sub _export_internal_item_map {

    my $self = $_[0];
    return { %{ $self->{_item_map} } };
}


sub _setup_and_init_working_dir {

    my $self = $_[0];

    # create a temp dir using default dir setup
    my $working_dir = $self->_setup_default_dir;

    # if we have a source / working_dir dir, copy it
    if ( my $source_dir = $self->dir ) {

        unless ( File::Copy::Recursive::dircopy( $source_dir, $working_dir ) )
        {
            croak 'Failed to temp copy of source datafile directory: '
                . $source_dir;
        }
    }
    return $working_dir;
}

sub _setup_default_dir {

    my $self = $_[0];

    # create a temporary directory
    my $dir = Data::AnyXfer->tmp_dir(
        { name => 'es_import_datefile', cleanup => 1 } );

    # resolve the path and make sure it's empty
    $dir = Path::Class::dir($dir)->resolve;
    $dir->rmtree;

    # re-create it and return
    $dir->mkpath;

    return $dir;
}


=head2 convert_item_name

    my $item =
        $self->convert_item_name('some_random_string_with_unknown_chars');

Converts an arbritrary string to a format safe to be used by this storage
backend as an item name.

This is not necessary on storage interface methods as this is handled
transparently for you.

=head3 CAVEATS

This convertion is most likely one-way (lossy). Because of the normalisation,
different strings can point to the same item,
e.g. 'some_string' and 'some-string' are considered the same item.

=cut

sub convert_item_name {

    my $suffix = $_[0]->item_file_suffix || '';
    my $prefix = $_[0]->item_file_prefix || '';

    my $name = sprintf "%s%s%s", $prefix, $_[1], $suffix;
    $name =~ s/([ ]+|[-\.]{2,})/-/g;
    $name =~ s/[^A-Za-z0-9-\.]/-/g;
    $name =~ s/-+/-/g;
    return $name;
}




1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

