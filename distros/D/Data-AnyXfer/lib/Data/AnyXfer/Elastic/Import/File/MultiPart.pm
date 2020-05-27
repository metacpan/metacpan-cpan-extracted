package Data::AnyXfer::Elastic::Import::File::MultiPart;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;


extends 'Data::AnyXfer::Elastic::Import::File::Simple';
with 'Data::AnyXfer::Elastic::Import::File';


=head1 NAME

Data::AnyXfer::Elastic::Import::File::MultiPart - An object
representing a collection of data spanning multiple entries in storage

=head1 SYNOPSIS

    # create a multi-part entry...

    my $file =
        Data::AnyXfer::Elastic::Import::File::MultiPart->new(
        name => 'My-Data',
        storage => STORAGE,
        part_size => 2);

    # now use it exactly the same as a normal HH::C::ES::Import::File
    # object...

=head1 DESCRIPTION

B<This is a low-level module> representing a C<Data::AnyXfer::Elastic>
collection of data, I<spanning multiple storage entries>.

The interface
allows the storage and interaction with
the data collection.

The underlying file implementation is provided by:
L<Data::AnyXfer::Elastic::Import::File::Simple>

This module implements: L<Data::AnyXfer::Elastic::Import::File>

=cut

=head1 ATTRIBUTES

=over

=item B<part_size>

Optional. Determines the number of data elements to store within a single
storage entry.

Defaults to: C<1000>

This only takes effect between seperate calls to
L<Data::AnyXfer::Elastic::Import::File/add>.

For example, with a C<part_size> of 2...

    $file->add(1..100);
    $file->add(1)
    $file->add(2);
    $file->add('bob', 'pav');

Would be implemented across three underlying storage entries.
Part 1, containing 100 elements (the list of numbers 1 through 100), Part 2,
containing 2 elements (the numbers '1' and '2'), and Part 3,
containing 2 elements (the strings 'bob', and 'pav')

=back

=head1 DATA INTERFACE

B<Please see L<Data::AnyXfer::Elastic::Import::File::Simple> and
L<Data::AnyXfer::Elastic::Import::File>>

=cut



has part_size => (
    is => 'ro',
    isa => Int,
    default => 1000,
);


has _part_name_pattern => (
    is => 'ro',
    isa => RegexpRef,
    lazy => 1,
    default => sub {
        my $name = $_[0]->storage->convert_item_name($_[0]->name . '_');
        return qr/^${name}(\d+)/;
    },
);




sub BUILD {

    my $self = $_[0];

    # set the initial item name to the first part (zero)
    # so reads start in the right place
    $self->item_name($self->_create_part_item_name(0));

}



=head2 ADDITIONAL METHODS

=cut


sub add {

    my $self = $_[0];
    my $part_size = $self->part_size;

    # always set the current item to the highest part number
    # (this means if you mix reading and adding, the next read will
    # jump to the last part)
    # we now do this with a 'reset to end'
    $self->reset(1);

    if ($part_size && @{$self->_content_body} >= $part_size) {

        my $current_item = $self->item_name;

        # start a new part once the current body size exceeds
        # the set part size limit, between a single atomic add call
        $self->_move_to_new_part;

        # protect against recursion bugs / regressions, with a clear error
        unless ($self->item_name ne $current_item) {
            croak 'Failed to create next part whilst at or over the set '
                . 'part size limit. Escaping add operation to avoid '
                . 'recursion';
        }

        # call ourselves again once we've switched to the new part
        goto &add;
    }

    # current part looks good. perform normal add operation
    # copying @_ would be too expensive, so we remove self
    # from the front of @_, so we can re-use it
    shift;
    return $self->SUPER::add(@_);
}


sub get {

    my $self = $_[0];
    my $value = $self->SUPER::get;

    # undef value means we're at the end of the current body
    # only return undef once we've tried a few times
    # (to allow the current part to be forwarded)
    unless (defined $value) {

        # try to load the next part
        my $current_item = $self->item_name;
        my $current_pos = $self->{_cur_get_idx};
        $self->_move_to_next_part;

        # do we have anything?
        $value = $self->SUPER::get;

        # if we still didn't get anything, go back to the previous part
        # (it is probably the final part)
        unless (defined $value) {
            $self->_move_to_part($current_item);
            $self->{_cur_get_idx} = $current_pos;
        }
    }
    return $value;
}


sub reset {

    my ( $self, $to_end ) = @_;

    $to_end ? $self->_load_last_part : $self->_load_first_part;
    $self->SUPER::reset($to_end);

    return 1;
}


=head3 list_part_names

    my @names = $file->list_part_names;
        # e.g. returns 'name_00', 'name_01', 'name_02'

Lists the underlying storage entry names this multi-part file is
implemented on top of.

Takes no arguments. May return an empty list on as-yet unused / empty
instances of this class.

=cut

sub list_part_names {

    my $self = $_[0];
    my $pat = $self->_part_name_pattern;

    # find all items in storage matching the part naming pattern
    return grep { /$pat/ }
        $self->storage->search($self->name);

}


sub _create_part_item_name {

    my ( $self, $part_number ) = @_;
    return $self->_get_item_name(
        (sprintf '%s_%.4d', $self->name, $part_number));
}


sub _last_part_item_name {

    my ( $self ) = $_[0];

    my $pat = $self->_part_name_pattern;
    # extract number from part name pattern and create a mapping
    # number to full item name
    my %parts = map { ($_ =~ /$pat/)[0] => $_ } $self->list_part_names;

    # sort the numbers and return the item name for the highest
    my $key = (sort keys %parts)[-1];
    return $key ? $parts{$key} : undef;
}


sub _next_part_item_name {

    my ( $self, $from_last ) = @_;

    my $pat = $self->_part_name_pattern;

    # get the number from the highest part
    # or we start from the first part when there are no existing parts,
    # which is zero
    my $item = $from_last
        ? $self->_last_part_item_name
        : $self->item_name;

    my $part_no = $item
        ? ($item =~ /$pat/)[0] + 1
        : 0;

    # make and return the full item name for the next part number
    return $self->_create_part_item_name($part_no);
}



sub _move_to_part {

    my ( $self, $part_name ) = @_;

    # switch the current part
    $self->item_name($part_name);
    $self->reset_item_pos;

    # load it
    return $self->_load_content;

}

sub _load_first_part {

    my $self = $_[0];
    # switch to part zero
    return $self->_move_to_part($self->_create_part_item_name(0));
}


sub _load_last_part {

    my $self = $_[0];

    # switch to the last part (or if there are none, part zero)
    return $self->_move_to_part(
        $self->_last_part_item_name
            || $self->_create_part_item_name(0));
}


sub _move_to_new_part {

    my $self = $_[0];
    # switch to the next *new* incremental part
    return $self->_move_to_part($self->_next_part_item_name(1));
}


sub _move_to_next_part {

    my $self = $_[0];
    # switch to the next incremental part
    return $self->_move_to_part($self->_next_part_item_name);
}



1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

