package Data::AnyXfer::Elastic::Import::File::Simple;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;
use Scalar::Util ( );

use Data::AnyXfer::Elastic::Import::File::Format::JSON ( );
use Data::AnyXfer::Elastic::Import::Storage::TempDirectory ( );

with 'Data::AnyXfer::Elastic::Import::File';


=head1 NAME

Data::AnyXfer::Elastic::Import::File::Simple - An object
representing a collection of data in storage

=head1 SYNOPSIS

    # initialise any type of storage...
    use constant STORAGE =>
        Data::AnyXfer::Elastic::Import::Storage::Directory->new(
        dir => '/mnt/webdata/some/path' );


    # 1. CREATE AN ENTRY...

    my $file =
        Data::AnyXfer::Elastic::Import::File::Simple->new(
        name => 'My-Data',
        storage => STORAGE, );

    # store some data in the "file" entry

    $file->add($$);
    $file->add(%ENV);


    # depending on the storage type, you may need to call save...
    $storage->save;


    # 2. AND THEN...AT SOME OTHER TIME...

    my $file =
        Data::AnyXfer::Elastic::Import::File::Simple->new(
        name => 'My-Data',
        storage => STORAGE, );

    # get the pid back

    print "PID: %s\n", $file->get;

    # get the env back

    my @env_data;
    push @env_data, $data while ( my $data = $file->get );

    print Data::Dumper::Dumper( { @env_data } );

=head1 DESCRIPTION

B<This is a low-level module> representing a C<Data::AnyXfer::Elastic>
collection of data. The interface allows the storage and interaction with
the data collection. Details of actual storage and persistence are handled
by the L<Data::AnyXfer::Elastic::Import::Storage> backend.
See the L</storage> attribute.

Not all perl data structures may be supported. Serialisation is handled by
L<Data::AnyXfer::Elastic::Import::File::Format>.
See the L</format> attribute.

This module implements: L<Data::AnyXfer::Elastic::Import::File>

=cut

=head1 ATTRIBUTES

=over

=item B<storage>

Optional. The storage backend to retrieve and manipulate data from.
If not supplied, will default to an instance of
L<Data::AnyXfer::Elastic::Import::Storage::TempDirectory>.

=item B<name>

Optional. The name of the data collection. This will be need to
match to retrieve the same data.

=item B<format>

Optional. An implementation of
L<Data::AnyXfer::Elastic::Import::File::Format>.
This controls serialisation and supported data types.

If not supplied, defaults to an instance of
L<Data::AnyXfer::Elastic::Import::File::Format::JSON>,

=back

=head1 DATA INTERFACE

B<Please see L<Data::AnyXfer::Elastic::Import::File> for the
interface definition and information>.

=cut



has storage => (
    is  => 'ro',
    isa => ConsumerOf['Data::AnyXfer::Elastic::Import::Storage'],
    default => sub {
        Data::AnyXfer::Elastic::Import::Storage::TempDirectory->new;
    },
);


has name => (
    is => 'ro',
    isa => Str,
    builder => '_generate_tmp_item_name',
);


has item_name => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    builder => '_get_item_name',
);


has format => (
    is  => 'ro',
    isa => ConsumerOf['Data::AnyXfer::Elastic::Import::File::Format'],
    default => sub {
        Data::AnyXfer::Elastic::Import::File::Format::JSON->new
    },
);


has _content_body => (
    is => 'rw',
    isa => ArrayRef,
    lazy => 1,
    builder => '_fetch_content'
);


has _cur_get_idx => (
    is => 'bare',
    isa => Int,
    default => 0,
);




sub _generate_tmp_item_name {
    # address of this object as hex string
    return sprintf '0x%x', Scalar::Util::refaddr($_[0]);
}

sub _get_item_name {
    my $self = $_[0];
    # build proper escaped item name
    return $self->storage->convert_item_name(
        ($_[1] || $self->name) . $self->format->format_suffix);
}



=head2 ADDITIONAL METHODS

=cut

# ITERATION INTERFACE


sub get {

    my $self = $_[0];

    # see if we have a next entry to get from the body
    my $idx = $self->{_cur_get_idx};
    my $value = $self->_content_body->[$idx];

    # if there was a value, increment the current get pointer
    $self->{_cur_get_idx} = ++$idx if defined $value;

    return $value;
}


sub add {

    my $self = shift;
    my $ret = push @{$self->_content_body}, grep { defined } @_;

    # persist to storage after add operations
    # (will also cause the get iteration pointer to reset)
    $self->_flush_content_body;

    return $ret;
}


sub clear {
    my $self = $_[0];
    $self->_content_body($self->content([], 1));
    return 1;
}


sub reset {

    my ( $self, $to_end ) = @_;

    # iterate from the start again by default
    # unless to_end has been se
    return $self->reset_item_pos($to_end);
}


=head3 reset_item_pos

Does the same as the L</reset> method but more descriptive.
Can be used by subclasses to provide clarity when
multiple types of 'resets' are available.

See L<Data::AnyXfer::Elastic::Import::File/reset>
for the interface definition.

=cut

sub reset_item_pos {

    my ( $self, $to_end ) = @_;
    $self->{_cur_get_idx} = $to_end
        ? $#{$self->_content_body}+1
        : 0;
    return 1;
}



# FILE CONTENT / ITEM HANDLING


=head3 content

    # get all of the content
    my @data = @{ $file->content };

    # or set it...
    $file->content([1..10]);

Fetch or overwrite the entire contents of the data collection.
All at once.

This method should B<NOT> be favoured over the standard
iteration interface provided by
L<Data::AnyXfer::Elastic::Import::File/get> and
L<Data::AnyXfer::Elastic::Import::File/add>.

Knowledge of the entry structure and underlying implementation
is required, or there may be unknown side-effects.

This is mostly intended for use within specialised subclasses
such as L<Data::AnyXfer::Elastic::Import::File::MultiPart>.

=cut

sub content {

    my ( $self, $value, $no_save ) = @_;
    my $storage = $self->storage;

    # if there is a value supplied, this is a 'set' operation
    # completely overwrite the underlying item in storage
    # with the new data
    if ($value) {

        unless (ref $value eq 'ARRAY') {
            croak q/Content body (file->content) must be an ARRAY. /
                . q/Perhaps use 'add' instead./;
        }

        # serialise and set the item in storage
        $storage->set_item(
            $self->item_name,
            $self->format->serialise($value));

        # by default we save / persist the value immediately
        # unless no_save is set
        $storage->save unless $no_save;

        # jump the read iterator to the end and return,
        # this should bail out any futher reads
        $self->reset(1);
        return $value;

    }

    # this is a 'get' operation, get everything
    # until we're exhausted
    my @value_list;
    while ($value = $self->get) {
        push @value_list, $value;
    }
    return \@value_list;
}


sub _fetch_content {

    my ( $self, $from_item ) = @_;
    $from_item ||= $self->item_name;

    # deserialise and return the item from storage
    my $value = $self->storage->get_item($from_item);

    # make sure it deserialises to an array ref
    return $value = [@{$self->format->deserialise($value)}]
        if $value;

    # if we're still alive here
    # we don't have a value, so the item must be new or empty
    # so just return a ref to an empty array
    # (but "touch" the item so it exists if we may need to write)
    unless ($self->storage->read_only) {
        $self->storage->set_item($from_item, $self->format->serialise([]));
    }
    return [];
}


sub _load_content {

    my ( $self, $from_item ) = @_;
    return $self->_content_body($self->_fetch_content($from_item));
}


sub _flush_content_body {

    my $self = $_[0];
    # just set the file content to the current value of _content_body
    # this should trigger a save
    return $self->content($self->_content_body, 1);
}



1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

