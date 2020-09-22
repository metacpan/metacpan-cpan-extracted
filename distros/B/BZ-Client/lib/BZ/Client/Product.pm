#!/bin/false
# PODNAME: BZ::Client::Product
# ABSTRACT: Client side representation of a product in Bugzilla
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

use strict;
use warnings 'all';

package BZ::Client::Product;
$BZ::Client::Product::VERSION = '4.4003';

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html

## functions

sub create {
    my(undef, $client, $params) = @_;
    return _create($client, 'Product.create', $params);
}

sub update {
    my($class, $client, $params) = @_;
    return $class->_returns_array($client, 'Product.update', $params, 'components');
}

# convenience function
sub _get_list {
    my($class, $methodName, $client) = @_;
    my $result = $class->api_call($client, $methodName);
    my $ids = $result->{'ids'};
    if (!$ids || 'ARRAY' ne ref($ids)) {
        $class->error($client, 'Invalid reply by server, expected array of ids.');
    }
    return $ids
}

sub get_selectable_products {
    my($class, $client) = @_;
    $client->log('debug', $class . '::get_selectable_products: Asking');
    my $result = $class->_get_list('Product.get_selectable_products', $client);
    $client->log('debug', $class . '::get_selectable_products: Got ' . @$result);
    return wantarray ? @$result : $result
}

sub get_enterable_products {
    my($class, $client) = @_;
    $client->log('debug', $class . '::get_enterable_products: Asking');
    my $result = $class->_get_list('Product.get_enterable_products', $client);
    $client->log('debug', $class . '::get_enterable_products: Got ' . @$result);
    return wantarray ? @$result : $result
}

sub get_accessible_products {
    my($class, $client) = @_;
    $client->log('debug', $class . '::get_accessible_products: Asking');
    my $result = $class->_get_list('Product.get_accessible_products', $client);
    $client->log('debug', $class . '::get_accessible_products: Got ' . @$result);
    return wantarray ? @$result : $result
}

# do everything in one place
sub _get {
    my($class, $client, $result) = @_;
    my $products = $result->{'products'};
    if (!$products or 'ARRAY' ne ref $products) {
        $class->error($client, 'Invalid reply by server, expected array of products.');
    }
    my @result;
    for my $product (@$products) {
        push @result, $class->new(
                id          => $product->{'id'},
                name        => $product->{'name'},
                description => $product->{'description'},
                internals   => $product->{'internals'}
        );
    }
    return wantarray ? @result : \@result
}

sub get_products {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'Product.get_products', $params);
    return $class->_get($client, $result)
}

sub get {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'Product.get', $params);
    return $class->_get($client, $result)
}

## rw methods

sub name {
    my $self = shift;
    if (@_) {
        $self->{'name'} = shift;
    }
    else {
        return $self->{name};
    }
}

sub description {
    my $self = shift;
    if (@_) {
        $self->{'description'} = shift;
    }
    else {
        return $self->{'description'};
    }
}

sub version {
    my $self = shift;
    if (@_) {
        $self->{'version'} = shift;
    }
    else {
        return $self->{'version'};
    }
}

## boolean
sub has_unconfirmed {
    my $self = shift;
    if (@_) {
        $self->{'has_unconfirmed'} = shift;
    }
    else {
        return $self->{'has_unconfirmed'};
    }
}

sub classification {
    my $self = shift;
    if (@_) {
        $self->{'classification'} = shift;
    }
    else {
        return $self->{'classification'};
    }
}

sub default_milestone {
    my $self = shift;
    if (@_) {
        $self->{'default_milestone'} = shift;
    }
    else {
        return $self->{'default_milestone'};
    }
}

## boolean
sub is_open {
    my $self = shift;
    if (@_) {
        $self->{'is_open'} = shift;
    }
    else {
        return $self->{'is_open'};
    }
}

sub create_series {
    my $self = shift;
    if (@_) {
        $self->{'create_series'} = shift;
    }
    else {
        return $self->{'create_series'};
    }
}

## ro methods

sub id { my $self = shift; return $self->{'id'} }

sub internals { my $self = shift; return $self->{'internals'} }

sub components {
    my $self = shift;
    return unless $self->{'components'};

    return wantarray ? @{$self->{'components'}}
                     : $self->{'components'}
}


sub versions {
    my $self = shift;
    return unless $self->{'versions'};

    return wantarray ? @{$self->{'versions'}}
                     : $self->{'versions'}
}


sub milestones {
    my $self = shift;
    return unless $self->{'milestones'};

    return wantarray ? @{$self->{'milestones'}}
                     : $self->{'milestones'}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::Product - Client side representation of a product in Bugzilla

=head1 VERSION

version 4.4003

=head1 SYNOPSIS

This class provides methods for accessing and managing products in Bugzilla. Instances
of this class are returned by L<BZ::Client::Product::get>.

 my $client = BZ::Client->new( url       => $url,
                               user      => $user,
                               password  => $password );

 my $ids = BZ::Client::Product->get_accessible_products( $client );
 my $products = BZ::Client::Product->get( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 create

 $id = BZ::Client::Product->create( $client, \%params );

This allows you to create a new Product in Bugzilla.

=head3 History

Marked as experimental as of Bugzilla 5.0.

=head3 Parameters

Some params must be set, or an error will be thrown. These params are noted as Required.

=over 4

=item name

I<name> (string) The name of this product. Must be globally unique within Bugzilla.

B<Required>.

=item description

I<description> (string) A description for this product. Allows some simple HTML.

B<Required>.

=item version

I<version> (string) The default version for this product.

B<Required>.

=item has_unconfirmed

I<has_unconfirmed> (boolean) Allow the UNCONFIRMED status to be set on bugs in this product. Default: true.

=item classification

I<classification> (string) The name of the Classification which contains this product.

=item default_milestone

I<default_milestone> (string) The default milestone for this product. Default '---'.

=item is_open

I<is_open> (boolean) True if the product is currently allowing bugs to be entered into it. Default: true.

=item create_series

I<create_series> (boolean) True if you want series for New Charts to be created for this new product. Default: true.

=back

=head3 Returns

The ID of the newly-filed product.

=head3 Errors

=over 4

=item 51 - Classification does not exist

You must specify an existing classification name.

=item 700 - Product blank name

You must specify a non-blank name for this product.

=item 701 - Product name too long

The name specified for this product was longer than the maximum allowed length.

=item 702 - Product name already exists

You specified the name of a product that already exists. (Product names must be globally unique in Bugzilla.)

=item 703 - Product must have description

You must specify a description for this product.

=item 704 - Product must have version

You must specify a version for this product.

=back

=head2 update

 $id = BZ::Client::Product->update( $client, \%params );

This allows you to update a Group in Bugzilla.

=head3 History

As of Bugzilla 5.0. this is marked as experimental.

Added in Bugzilla 4.4.

=head3 Parameters

Either L</ids> or L</names> is required to select the bugs you want to update.

All other values change or set something in the product.

=over 4

=item ids

I<ids> (array) Numeric ID's of the products you wish to update.

=item names

I<names> (array) Text names of the products that you wish to update.

=item default_milestone

I<default_milestone> (string) When a new bug is filed, what milestone does it
get by default if the user does not choose one? Must represent a milestone that
is valid for this product.

=item description

I<description> (string) Update the long description for these products to this value.

=item has_unconfirmed

I<has_unconfirmed> (boolean) Allow the UNCONFIRMED status to be set on bugs in this products.

=item is_open

I<is_open> (boolean) True if the product is currently allowing bugs to be entered into it.
Otherwise false.

=back

=head3 Returns

An array or arrayref of hashes containing the following:

=over 4

=item id

I<id> (int) The ID of the product that was updated.

=item changes

The changes that were actually done on this product. The keys are the names of the
fields that were changed, and the values are a hash with two keys:

=over 4

=item added

I<added> (string) The value that this field was changed to.

=item removed

I<removed> (string) The value that was previously set in this field.

=back

Note that booleans will be represented with the strings '1' and '0'.

Here's an example of what a return value might look like:

 [
     {
         id => 123,
         changes => {
             name => {
                 removed => 'FooName',
                 added   => 'BarName'
             },
             has_unconfirmed => {
                 removed => '1',
                 added   => '0',
             }
         }
     },
     \%etc
 ],

=back

=head3 Errors

=over 4

=item 700 - Product blank name

You must specify a non-blank name for this product.

=item 701 - Product name too long

The name specified for this product was longer than the maximum allowed length.

=item 702 - Product name already exists

You specified the name of a product that already exists. (Product names must be globally unique in Bugzilla.)

=item 703 - Product must have description

You must specify a description for this product.

=item 705 - Product must define a default milestone

You must define a default milestone.

=back

=head2 get_selectable_products

 @products = BZ::Client::Product->get_selectable_products( $client );
 $products = BZ::Client::Product->get_selectable_products( $client );

Returns a list of the ID's of the products the user can search on.

=head3 History

Marked as experimental as of Bugzilla 5.0.

=head3 Parameters

(none)

=head3 Returns

An array of product ID's

=head3 Errors

(none)

=head2 get_enterable_products

 @products = BZ::Client::Product->get_enterable_products( $client );
 $products = BZ::Client::Product->get_enterable_products( $client );

Returns a list of the ID's of the products the user can enter bugs against.

=head3 History

Marked as experimental as of Bugzilla 5.0.

=head3 Parameters

(none)

=head3 Returns

An array of product ID's

=head3 Errors

(none)

=head2 get_accessible_products

 @products = BZ::Client::Product->get_selectable_products( $client );
 $products = BZ::Client::Product->get_selectable_products( $client );

Returns a list of the ID's of the products the user can search or enter bugs against.

=head3 History

Marked as unstable as of Bugzilla 5.0.

=head3 Parameters

(none)

=head3 Returns

An array of product ID's

=head3 Errors

(none)

=head2 get

 @products = BZ::Client::Product->get( $client, \%params );
 $products = BZ::Client::Product->get( $client, \%params );

Returns a list of BZ::Client::Product instances based on the given parameters.

Note, that if the user tries to access a product that is not in the list of
accessible products for the user, or a product that does not exist, that is
silently ignored, and no information about that product is returned.

=head3 Parameters

In addition to the parameters below, this method also accepts the standard
L<BZ::Client::Bug/include_fields> and L<BZ::Client::Bug/exclude_fields> arguments.

Note: You must at least specify one of L</ids> or L</names>.

=over 4

=item ids

I<ids> (array) An array of product ID's.

=item names

I<names> (array) An array of product names.

Added in Bugzilla 4.2.

=item type

The group of products to return. Valid values are: C<accessible> (default),
C<selectable>, and C<enterable>. L</type> can be a single value or an array
of values if more than one group is needed with duplicates removed.

=back

=head3 Returns

An array or arrayref of bug instance objects with the given ID's.

See L</INSTANCE METHODS> for how to use them.

=head3 Errors

(none)

=head2 get_products

Compatibilty with Bugzilla 3.0 API. Exactly equivalent to L</get>.

=head2 new

 my $product = BZ::Client::Product->new( id           => $id,
                                         name         => $name,
                                         description  => $description );

Creates a new instance with the given ID, name, and description.

=head1 INSTANCE METHODS

This section lists the modules instance methods.

=head2 id

 $id = $product->id();

Gets the products ID.

Read only.

=head2 name

 $name = $product->name();
 $product->name( $name );

Gets or sets the products name.

=head2 description

 $description = $product->description();
 $product->description( $description );

Gets or sets the products description.

=head2 version

 $version = $product->version();
 $product->version( $version );

Gets or sets the products version.

(Set only works for new products, not updates)

=head2 has_unconfirmed

 $bool = $product->has_unconfirmed();
 $product->has_unconfirmed( $bool );

Gets or sets the products has_unconfirmed setting.

Added in Bugzilla 4.2 as a replacement for L</internals>.

=head2 classification

 $classification = $product->classification();
 $product->classification( $classification );

Gets or sets the products classification.

Added in Bugzilla 4.2 as a replacement for L</internals>.

=head2 default_milestone

 $milestone = $product->default_milestone();
 $product->default_milestone( $milestone );

Gets or sets the products default milestone.

Added in Bugzilla 4.2 as a replacement for L</internals>.

=head2 is_open

 $bool = $product->is_open();
 $product->is_open( $bool );

Gets or sets the products is_open setting.

=head2 create_series

 $series = $product->create_series();
 $product->create_series( $series );

Gets or sets the products is_open setting.

=head2 components

 @components = $product->components();
 $components = $product->components();

An array of hashes, where each hash describes a component, and has the following items:

=over 4

=item id

I<id> (int) An integer ID uniquely identifying the component in this installation only.

=item name

I<name> (string) The name of the component. This is a unique identifier for this component.

=item description

I<description> (string) A description of the component, which may contain HTML.

=item default_assigned_to

I<default_assigned_to> (string) The login name of the user to whom new bugs will be assigned
by default.

=item default_qa_contact

I<default_qa_contact> (string) The login name of the user who will be set as the QA Contact
for new bugs by default. Empty string if the QA contact is not defined.

=item sort_key

I<sort_key> (int) Components, when displayed in a list, are sorted first by this integer and
then secondly by their name.

=item is_active

I<is_active> (boolean) A boolean indicating if the component is active. Inactive components
are not enabled for new bugs.

=item flag_types

Added in Bugzilla 4.4.

A hash containing the two items bug and attachment that each contains an array of hashes, where
each hash describes a flagtype, and has the following items:

=over 4

=item id

I<id> (int) Returns the ID of the flagtype.

=item name

I<name> (string) Returns the name of the flagtype.

=item description

I<description> (string) Returns the description of the flagtype.

=item cc_list

I<cc_list> (string) Returns the concatenated CC list for the flagtype, as a single string.

=item sort_key

I<sort_key> (int) Returns the sortkey of the flagtype.

=item is_active

I<is_active> (boolean) Returns whether the flagtype is active or disabled. Flags being in a
disabled flagtype are not deleted. It only prevents you from adding new flags to it.

=item is_requestable

I<is_requestable> (boolean) Returns whether you can request for the given flagtype (i.e.
whether the '?' flag is available or not).

=item is_requesteeble

I<is_requesteeble> (boolean) Returns whether you can ask someone specifically or not.

=item is_multiplicable

I<is_multiplicable> (boolean) Returns whether you can have more than one flag for the given
flagtype in a given bug/attachment.

=item grant_group

I<grant_group> (int) the group ID that is allowed to grant/deny flags of this type. If the
item is not included all users are allowed to grant/deny this flagtype.

=item request_group

I<request_group> (int) the group ID that is allowed to request the flag if the flag is of
the type requestable. If the item is not included all users are allowed request this flagtype.

=back

=back

Added in Bugzilla 4.2 as a replacement for L</internals>.

=head2 versions

 $versions = $product->versions();

Added in Bugzilla 4.2 as a replacement for L</internals>.

Returns an array of hashes, where each hash describes a version, and has the
following items: C<name>, C<sort_key> and C<is_active>.

=head2 milestones

 $milestones = $product->milestones();

Returns an array of hashes, where each hash describes a milestones, and has the
following items: C<name>, C<sort_key> and C<is_active>.

Added in Bugzilla 4.2 as a replacement for L</internals>.

=head2 internals

Returned by L</get> until version 4.2, at which point it was dropped.
Remains for compatibility. Please move away from using it asap.

=head1 EXCEPTION HANDLING

See L<BZ::Client::Exception>

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html>

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
