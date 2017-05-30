#!/bin/false
# PODNAME: BZ::Client::FlagType
# ABSTRACT: The API for creating, changing, and getting info on Flags

use strict;
use warnings 'all';

package BZ::Client::FlagType;
$BZ::Client::FlagType::VERSION = '4.4002';

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/FlagType.html

## functions

sub get {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'FlagType.get', $params);
    return wantarray ? %$result : $result
}

sub create {
    my($class, $client, $params) = @_;
    return $class->_create($client, 'FlagType.create', $params, 'flag_id');
}

sub update {
    my($class, $client, $params) = @_;
    return $class->_returns_array($client, 'FlagType.update', $params, 'flagtypes');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::FlagType - The API for creating, changing, and getting info on Flags

=head1 VERSION

version 4.4002

=head1 SYNOPSIS

This class provides methods for accessing and managing Flags in Bugzilla.

 my $client = BZ::Client->new( url       => $url,
                               user      => $user,
                               password  => $password );

 my %results     = BZ::Client::FlagType->get( $client, \%params );
 my $id = BZ::Client::FlagType->create( $client, \%params );
 my @updates = BZ::Client::FlagType->update( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 get

 $id = BZ::Client::FlagType->get( $client, \%params );

Get information about valid flag types that can be set for bugs and attachments.

=head3 History

Added in Bugzilla 5.0.

=head3 Parameters

You must pass a product L</name> and an optional L</component> name.

=over 4

=item product

I<product> (string) The name of a valid product.

=item component

I<component> (string) An optional valid component name associated with the product.

=back

=head3 Returns

A hash containing two keys, bug and attachment. Each key value is an array of hashes, containing the following keys:

=over 4

=item id

I<id> (int) An integer ID uniquely identifying this flag type.

=item name

I<name> (string) The name for the flag type.

=item type

I<type> (string) The target of the flag type which is either bug or attachment.

=item description

I<description> (string) The description of the flag type.

=item values

I<values> (array) An array of string values that the user can set on the flag type.

=item is_requesteeble

I<is_requesteeble> (boolean) Users can ask specific other users to set flags of this type.

=item is_multiplicable

I<is_multiplicable> (boolean) Multiple flags of this type can be set for the same bug or attachment.

=back

=head3 Errors

=over 4

=item 106 - Product Access Denied

Either the product does not exist or you don't have access to it.

=item 51 - Invalid Component

The component provided does not exist in the product.

=back

=head2 create

 $id = BZ::Client::FlagType->create( $client, \%params );

This allows you to create a new Flag Type in Bugzilla.

Marked as unstable as of Bugzilla 5.0.

Added in Bugzilla 5.0.

=head3 Parameters

Some params must be set, or an error will be thrown. These params are noted as Required.

=over 4

=item name

I<name> (string)  A short name identifying this type.

Required.

=item description

I<description> (string) A comprehensive description of this type.

Required.

=item inclusions

I<inclusions> (array) An array of strings or a hash containing product names,
and optionally component names. If you provide a string, the flag type will be shown on all
bugs in that product. If you provide a hash, the key represents the product name, and the
value is the components of the product to be included.

For example:

 [ 'FooProduct',
    {
      BarProduct => [ 'C1', 'C3' ],
      BazProduct => [ 'C7' ]
    }
 ]

This flag will be added to All components of FooProduct, components C1 and C3 of BarProduct,
and C7 of BazProduct.

=item exclusions

I<exclusions> (array) An array of strings or hashes containing product names. This uses the same format
as inclusions.

This will exclude the flag from all products and components specified.

=item sortkey

I<sortkey>  (int) A number between 1 and 32767 by which this type will be sorted when displayed
to users in a list; ignore if you don't care what order the types appear in or if you want them
to appear in alphabetical order.

=item is_active

I<is_active> (boolean) Flag of this type appear in the UI and can be set.

Default is true.

=item is_requestable

I<is_requestable> (boolean) Users can ask for flags of this type to be set.

Default is true.

=item cc_list

I<cc_list> (array) An array of strings. If the flag type is requestable, who should receive e-mail
notification of requests. This is an array of e-mail addresses which do not need to be Bugzilla logins.

=item is_specifically_requestable

I<is_specifically_requestable> (boolean) Users can ask specific other users to set flags of this
type as opposed to just asking the wind.

Default is true.

=item is_multiplicable

I<is_multiplicable> (boolean) Multiple flags of this type can be set on the same bug.

Default is true.

=item grant_group

I<grant_group> (string) The group allowed to grant/deny flags of this type (to allow all users to
grant/deny these flags, select no group).

Default is no group.

=item request_group

I<request_group> (string) If flags of this type are requestable, the group allowed to request them
(to allow all users to request these flags, select no group). Note that the request group alone has
no effect if the grant group is not defined!

Default is no group.

=back

=head3 Returns

The ID of the newly-created group.

=head3 Errors

=over 4

=item 51 - Group Does Not Exist

The group name you entered does not exist, or you do not have access to it.

=item 105 - Unknown component

The component does not exist for this product.

=item 106 - Product Access Denied

Either the product does not exist or you don't have editcomponents privileges to it.

=item 501 - Illegal Email Address

One of the e-mail address in the CC list is invalid. An e-mail in the CC list does NOT need to be a
valid Bugzilla user.

=item 1101 - Flag Type Name invalid

You must specify a non-blank name for this flag type. It must no contain spaces or commas, and must
be 50 characters or less.

=item 1102 - Flag type must have description

You must specify a description for this flag type.

=item 1103 - Flag type CC list is invalid

The CC list must be 200 characters or less.

=item 1104 - Flag Type Sort Key Not Valid

The sort key is not a valid number.

=item 1105 - Flag Type Not Editable

This flag type is not available for the products you can administer. Therefore you can not edit
attributes of the flag type, other than the inclusion and exclusion list.

=back

=head2 update

 @results = BZ::Client::FlagType->update( $client, \%params );
 $results = BZ::Client::FlagType->update( $client, \%params );

This allows you to update a flag type in Bugzilla.

=head3 History

Added in Bugzilla 5.0.

=head3 Parameters

Note: The following parameters specify which products you are updating. You must set one or both of these parameters.

=over 4

=item ids

I<ids> (array of ints) Numeric ids of the flag types that you wish to update.

=item names

I<names> (array of strings) Names of the flag types that you wish to update. If many flag types have the same name, this will change ALL of them.

=back

Note: The following parameters specify the new values you want to set for the products you are updating.

=over 4

=item name

I<name> (string) A short name identifying this type.

=item description

I<description> (string) A comprehensive description of this type.

=item inclusions

An array of strings or a hash containing product names, and optionally component names.

If you provide a string, the flag type will be shown on all bugs in that product.

If you provide a hash, the key represents the product name, and the value is the components of the product to be included.

For example:

 [ 'FooProduct',
   {
     BarProduct => [ 'C1', 'C3' ],
     BazProduct => [ 'C7' ]
   }
 ]

This flag will be added to B<all> components of C<FooProduct>, components C<C1> and C<C3> of C<BarProduct>, and C<C7> of C<BazProduct>.

=item exclusions

An array of strings or hashes containing product names.

This uses the same fromat as L</inclusions>.

This will exclude the flag from all products and components specified.

=item sortkey

I<sortkey> (int) A number between 1 and 32767 by which this type will be sorted when displayed to users in a list; ignore if you don't care what order the types appear in or if you want them to appear in alphabetical order.

=item is_active

I<is_active> (boolean) Flag of this type appear in the UI and can be set.

=item is_requestable

I<is_requestable> (boolean) Users can ask for flags of this type to be set.

=item cc_list

I<cc_list> (array) An array of strings. If the flag type is requestable, who should receive e-mail notification of requests. This is an array of e-mail addresses which do not need to be Bugzilla logins.

=item is_specifically_requestable

I<is_specifically_requestable> (boolean) Users can ask specific other users to set flags of this type as opposed to just asking the wind.

=item is_multiplicable

I<is_multiplicable> (boolean) Multiple flags of this type can be set on the same bug.

=item grant_group

I<grant_group> (string) The group allowed to grant/deny flags of this type (to allow all users to grant/deny these flags, select no group).

=item request_group

I<request_group> (string) If flags of this type are requestable, the group allowed to request them (to allow all users to request these flags, select no group).

Note that the request group alone has no effect if the grant group is not defined!

=back

=head2 Returns

An array of hashes with the following fields:

=over 4

=item id

I<id> (int) The ID of the product that was updated.

=item name

I<name> (string) The name of the product that was updated.

=item changes

I<changes> (hash) The changes that were actually done on this product.

The keys are the names of the fields that were changed, and the values are a hash with two keys:

=over 4

=item added

I<added> (string) The value that this field was changed to.

=item removed

I<removed> (string) The value that was previously set in this field.

=back

Note that booleans will be represented with the strings C<1> and C<0>.

Here's an example of what a return value might look like:

 [
   {
     id => 123,
     changes => {
       name => {
         removed => 'FooFlagType',
         added   => 'BarFlagType'
       },
       is_requestable => {
         removed => '1',
         added   => '0',
       }
     }
   }
 ]

=back

=head3 Errors

=over 4

=item 51 - Group Does Not Exist

The group name you entered does not exist, or you do not have access to it.

=item 105 - Unknown component

The component does not exist for this product.

=item 106 - Product Access Denied

Either the product does not exist or you don't have editcomponents privileges to it.

=item 501 - Illegal Email Address

One of the e-mail address in the CC list is invalid. An e-mail in the CC list does NOT need to be a valid Bugzilla user.

=item 1101 - Flag Type Name invalid

You must specify a non-blank name for this flag type. It must no contain spaces or commas, and must be 50 characters or less.

=item 1102 - Flag type must have description

You must specify a description for this flag type.

=item 1103 - Flag type CC list is invalid

The CC list must be 200 characters or less.

=item 1104 - Flag Type Sort Key Not Valid

The sort key is not a valid number.

=item 1105 - Flag Type Not Editable

This flag type is not available for the products you can administer. Therefore you can not edit attributes of the flag type, other than the inclusion and exclusion list.

=back

=head1 INSTANCE METHODS

FIXME Not yet implemented

=head1 EXCEPTION HANDLING

See L<BZ::Client::Exception>

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/FlagType.html>

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
