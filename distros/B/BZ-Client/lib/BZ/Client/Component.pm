#!/bin/false
# PODNAME: BZ::Client::Component
# ABSTRACT: Client side representation of Product Components in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Component;
$BZ::Client::Component::VERSION = '4.4003';

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Component.html
# These are in order as per the above

## functions

sub create {
    my($class, $client, $params) = @_;
    return $class->_create($client, 'Component.create', $params);
}

sub update {
    my($class, $client, $params) = @_;
    return $class->_returns_array($client, 'Component.update', $params, 'components');
}

sub delete {
    my($class, $client, $params) = @_;
    return $class->_returns_array($client, 'Component.delete', $params, 'components');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::Component - Client side representation of Product Components in Bugzilla

=head1 VERSION

version 4.4003

=head1 SYNOPSIS

This class provides methods for accessing Product Component information in
the Bugzilla server.

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $id = BZ::Client::Component->create( $client, \%params );
  my $changes = BZ::Client::Component->update( $client, \%params );
  my $ids = BZ::Client::Component->delete( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 create

 $id = BZ::Client::Component->create( $client, \%params );

Returns the ID of the newly created Component.

=head3 History

Added in Bugzilla 5.0.

Marked experiemental as of Bugzilla 5.0.

=head3 Parameters

Some params must be set, or an error will be thrown. These params are marked "Required".

=over 4

=item name

I<name> (string) The name of the new component.

B<Required>.

=item product

I<product> (string) The name of the product that the component must be added to. This
product must already exist, and the user have the necessary permissions to edit components
for it.

B<Required>.

=item description

I<description> (string) The description of the new component.

B<Required>.

=item default_assignee

I<default_assignee> (string) The login name of the default assignee of the component.

B<Required>.

=item default_cc

I<default_cc> (array) An array of strings with each element representing one login name of
the default CC list.

=item default_qa_contact

I<default_qa_contact> (string) The login name of the default QA contact for the component.

=item is_open

I<is_open> (boolean) C<1> if you want to enable the component for bug creations.
C<0> otherwise. Default is C<1>.

=back

=head3 Returns

The ID of the newly-added component.

=head3 Errors

=over 4

=item 304 - Authorization Failure

You are not authorized to create a new component.

=item 1200 - Component already exists

The name that you specified for the new component already exists in the specified product.

=back

=head2 update

  $changes = BZ::Client::Component->update( $client, \%params );
  @changes = BZ::Client::Component->update( $client, \%params );

This allows you to update one or more components in Bugzilla.

=head3 History

Added in Bugzilla 5.0.

=head3 Parameters

You must set one or both of L</ids> or L</names> to select the Component to update.

Other parameters set or update values of the Component

=over 4

=item ids

I<ids> (array) Numeric ID's of the components that you wish to update.

=item names

I<names> (array of hashes) Names of the components that you wish to update. The hash keys
are C<product> and C<component>, representing the name of the product and the component
you wish to change.

=item name

I<name> (string) A new name for this component. If you try to set this while updating
more than one component for a product, an error will occur, as component names must be
unique per product.

=item description

I<description> (string) The description of the new component.

Required.

=item default_assignee

I<default_assignee> (string) The login name of the default assignee of the component.

Required.

=item default_cc

I<default_cc> (array) An array of strings with each element representing one login name of
the default CC list.

=item default_qa_contact

I<default_qa_contact> (string) The login name of the default QA contact for the component.

=item is_open

I<is_open> (boolean) C<1> if you want to enable the component for bug creations.
C<0> otherwise.

=back

=head3 Returns

An array of hashes with the following fields:

=over 4

=item id

I<id> (int) The ID of the component that was updated.

=item changes

The changes that were actually done on this component. The keys are the names of the fields
that were changed, and the values are a hash with two keys:

=over 4

=item added

I<added> (string) The value that this field was changed to.

=item removed

I<removed> (string) The value that was previously set in this field.

Note that booleans will be represented with the strings C<1> and C<0>.

=back

=back

Here's an example of what a return value might look like:

 [
   {
     id => 123,
     changes => {
       name => {
         removed => 'FooName',
         added   => 'BarName'
       },
       default_assignee => {
         removed => 'foo@company.com',
         added   => 'bar@company.com',
       }
     }
   }
 ]

=head3 Errors

=over 4

=item 51 - User does not exist

One of the contact e-mail addresses is not a valid Bugzilla user.

=item 106 - Product access denied

The product you are trying to modify does not exist or you don't have access to it.

=item 706 - Product admin denied

You do not have the permission to change components for this product.

=item 105 - Component name too long

The name specified for this component was longer than the maximum allowed length.

=item 1200 - Component name already exists

You specified the name of a component that already exists. (Component names must be unique per
product in Bugzilla.)

=item 1210 - Component blank name

You must specify a non-blank name for this component.

=item 1211 - Component must have description

You must specify a description for this component.

=item 1212 - Component name is not unique

You have attempted to set more than one component in the same product with the same name.
Component names must be unique in each product.

=item 1213 - Component needs a default assignee

A default assignee is required for this component.

=back

=head2 delete

  $ids = BZ::Client::Component->delete( $client, \%params );
  @ids = BZ::Client::Component->delete( $client, \%params );

This allows you to delete one or more components in Bugzilla.

=head3 History

Added in Bugzilla 5.0.

=head3 Parameters

You must set one or both of these parameters.

=over 4

=item ids

I<ids> (array) Numeric ID's of the components that you wish to delete.

=item names

I<names> (array of hashes). Names of the components that you wish to delete. The hash keys are
C<product> and C<component>, representing the name of the product and the component you wish to
delete.

=back

=head3 Returns

An array of ID's that were deleted

=head3 Errors

=over 4

=item 106 - Product access denied

The product you are trying to modify does not exist or you don't have access to it.

=item 706 - Product admin denied

You do not have the permission to delete components for this product.

=item 1202 - Component has bugs

The component you are trying to delete currently has bugs assigned to it. You must move these
bugs before trying to delete the component.

=back

=head1 EXCEPTION HANDLING

See L<BZ::Client::Exception>

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Component.html>

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
