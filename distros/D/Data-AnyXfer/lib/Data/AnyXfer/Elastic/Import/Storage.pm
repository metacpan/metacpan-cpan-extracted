package Data::AnyXfer::Elastic::Import::Storage;

use Carp;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);


=head1 NAME

Data::AnyXfer::Elastic::Import::Storage - Import storage role

=head1 SYNOPSIS


    package My::Type::Of::Storage;

    use Moo;
    use MooX::Types::MooseLike::Base qw(:all);


    with 'Data::AnyXfer::Elastic::Import::Storage';


    # implement interface

    1;

=head1 DESCRIPTION

This role represents a C<Data::AnyXfer::Elastic> storage backend for
import data.

The interface allows the storage and retrieval of data, persistence, and
provides some helper methods.

=head1 ATTRIBUTES

=cut


=head1 METHODS REQUIRED

=cut

=head2 get_destination_info

    my $info = $storage->get_destination_info;

Returns the target information for the save operation.
This is relative to the type of storage backend.
This could be database information, or a file system location etc.
Consult your storage implementation.

=cut

requires 'get_destination_info';

=head2 list_items

    my @item_names = $storage->list_items;

Returns a list of all item names. Takes no arguments.

=cut

requires 'list_items';


=head2 add_item

    unless ( $storage->add_item('test_item', $content) ) {

        croak 'Failed to add test_item';

    }

Adds a new item to the storage backend. Fails if this item already exists.
Returns a boolean indicating success or failure.

=cut

requires 'add_item';


=head2 set_item

    $storage->set_item('test_item', $content);

Stores content under the specified item name in the storage backend.
Clobbers any existing values.

Should always return 1.

=cut

requires 'set_item';


=head2 remove_item

    $storage->remove_item('test_item');

Deletes the specified item from the storage backend.

=cut

requires 'remove_item';


=head2 get_item

    my $content = $storage->get('test_item');

Retrieves the contents of an item from the storage backend.

=cut

requires 'get_item';


=head2 reload

    $storage->reload;

Reinitialise the storage backend. Pickup any external changes in the storage
for backends where this is relevant.

Does not have to return anything.

May be implemented as a noop.

=cut

requires 'reload';


=head2 save

    $storage->save;

Persist any changes to storage, beyond the life of this instance,
when relevant.

Should die on failure.

=cut

requires 'save';

=head2 cleanup

    $storage->cleanup;

Cleans up any working copy, or partial and temporary files that may have been
created or in use by this instance.

=cut

requires 'cleanup';


=head1 METHODS PROVIDED

=cut

=head2 add

    $storage->add(
        item_1 => 'Hello',
        item_2 => 'World!',
    );

Convenience method. Allows multiple items to be added.
Already existing items will silently fail.

Use L</add_item> directly if you wish to detect and handle this.

Always returns 1;

=cut

sub add {

    my ( $self, %items ) = @_;

    foreach ( keys %items ) {
        $self->add_item( $_, $items{$_} );
    }

    return 1;
}


=head2 set

    $storage->set(
        item_1 => 'Hello',
        item_2 => 'World!',
    );

Convenience method. Allows multiple items to be set.
Already existing items will be clobbered.

Always returns 1;

=cut

sub set {

    my ( $self, %items ) = @_;

    foreach ( keys %items ) {
        $self->set_item( $_, $items{$_} );
    }

    return 1;
}




1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

