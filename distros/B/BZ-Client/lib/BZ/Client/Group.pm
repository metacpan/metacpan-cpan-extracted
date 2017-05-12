#!/bin/false
# PODNAME: BZ::Client::Group
# ABSTRACT: The API for creating, changing, and getting info on Groups

use strict;
use warnings 'all';

package BZ::Client::Group;
$BZ::Client::Group::VERSION = '4.4001';

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Group.html

## functions

sub create {
    my($class, $client, $params) = @_;
    return $class->_create($client, 'Group.create', $params);
}

sub update {
    my($class, $client, $params) = @_;
    return $class->_returns_array($client, 'Group.update', $params, 'groups');
}

sub get {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'Group.get', $params);
    return wantarray ? %$result : $result
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::Group - The API for creating, changing, and getting info on Groups

=head1 VERSION

version 4.4001

=head1 SYNOPSIS

This class provides methods for accessing and managing Groups in Bugzilla.

 my $client = BZ::Client->new( url       => $url,
                               user      => $user,
                               password  => $password );

 my $id = BZ::Client::Group->create( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 create

 $id = BZ::Client::Group->create( $client, \%params );

This allows you to create a new Group in Bugzilla.

=head3 History

Marked as unstable as of Bugzilla 5.0.

=head3 Parameters

Some params must be set, or an error will be thrown. These params are noted as Required.

=over 4

=item name

I<name> (string) A short name for this group. Must be unique.

This is infrequently displayed in the web user interface.

B<Required>.

=item description

I<description> (string) A human-readable name for this group. Should be relatively short.

This is what will normally appear in the UI as the name of the group.

B<Required>.

=item user_regexp

I<user_regexp> (string) A regular expression. Any user whose Bugzilla username matches this regular expression will automatically be granted membership in this group.

=item is_active

I<is_active> (boolean) True if new group can be used for bugs,

False if this is a group that will only contain users and no bugs will be restricted to it.

=item icon_url

I<icon_url> (boolean) A URL pointing to a small icon used to identify the group. This icon will show up next to users' names in various parts of Bugzilla if they are in this group.

=back

=head3 Returns

The ID of the newly-created group.

=head3 Errors

=over 4

=item 800 - Empty Group Name

You must specify a value for the L</name> field.

=item 801 - Group Exists

There is already another group with the same L</name>.

=item 802 - Group Missing Description

You must specify a value for the L</description> field.

=item 803 - Group Regexp Invalid

You specified an invalid regular expression in the L</user_regexp> field.

=back

=head2 update

 $id = BZ::Client::Group->update( $client, \%params );

This allows you to update a Group in Bugzilla.

=head3 History

As of Bugzilla 5.0. this is marked as unstable.

=head3 Parameters

Either L</ids> or L</names> is required to select the bugs you want to update.

All other values change or set something in the product.

=over 4

=item ids

I<ids> (array) Numeric ID's of the groups you wish to update.

=item names

I<names> (array) Text names of the groups that you wish to update.

=item name

I<name> (string) A new name for group.

=item description

I<description> (string) A new description for groups. This is what will appear in the UI as the name of the groups.

=item user_regexp

I<user_regexp> (string) A new regular expression for email. Will automatically grant membership to these groups to anyone with an email address that matches this perl regular expression.

=item is_active

I<is_active> (boolean) Set if groups are active and eligible to be used for bugs. True if bugs can be restricted to this group, false otherwise.

=item icon_url

I<icon_url> (string) A URL pointing to an icon that will appear next to the name of users who are in this group.

=back

=head3 Returns

An array or arrayref of hashes containing the following:

=over 4

=item id

I<id> (int) The ID of the Group that was updated.

=item changes

The changes that were actually done on this Group. The keys are the names of the
fields that were changed, and the values are a hash with two keys:

=over 4

=item added

I<added> (string)  The values that were added to this field, possibly a comma-and-space-separated list if multiple values were added.

=item removed

I<removed> (string) The values that were removed from this field, possibly a comma-and-space-separated list if multiple values were removed.

=back

Note that booleans will be represented with the strings C<1> and <0>.

=back

=head3 Errors

=over 4

=item 800 - Empty Group Name

You must specify a value for the L</name> field.

=item 801 - Group Exists

There is already another group with the same L</name>.

=item 802 - Group Missing Description

You must specify a value for the L</description> field.

=item 803 - Group Regexp Invalid

You specified an invalid regular expression in the L</user_regexp> field.

=back

=head2 get

Returns information about C<Bugzilla::Group>.

=head3 History

This function was added in Bugzilla 5.0.

=head3 Parameters

If neither L</ids> or L</names> is passed, and you are in the creategroups or editusers group, then all groups will be retrieved.

Otherwise, only groups that you have bless privileges for will be returned.

=over 4

=item ids

I<ids> (array) Contain IDs of groups to update.

=item names

I<names> (array) Contain names of groups to update.

=item membership

I<membership> (boolean) Set to C<1> then a list of members of the passed groups' names and IDs will be returned.

=back

=head3 Returns

If the user is a member of the C<creategroups>" group they will receive information about all groups or groups matching the criteria that they passed. You have to be in the creategroups group unless you're requesting membership information.

If the user is not a member of the Ccreategroups> group, but they are in the C<editusers> group or have bless privileges to the groups they require membership information for, the is_active, is_bug_group and user_regexp values are not supplied.

The return value will be a hash containing group names as the keys, each group name will point to a hash that describes the group and has the following items:

=over 4

=item id

I<id> (int) The unique integer ID that Bugzilla uses to identify this group. Even if the name of the group changes, this ID will stay the same.

=item name

I<name> (string) The name of the group.

=item description

I<description> (string) The description of the group.

=item is_bug_group

I<is_bug_group> (int) Whether this groups is to be used for bug reports or is only administrative specific.

=item user_regexp

I<user_regexp> (string) A regular expression that allows users to be added to this group if their login matches.

=item is_active

I<is_active> (int) Whether this group is currently active or not.

=item users

I<users> (array) An array of hashes, each hash contains a user object for one of the members of this group, only returned if the user sets the C<membership> parameter to C<1>, the user hash has the following items:

=over 4

=item id

I<id> (int) The ID of the user.

=item real_name

I<real_name> (string) The actual name of the user.

=item email

I<emaiL> (string) The email address of the user.

=item name

I<name> (string) The login name of the user. Note that in some situations this is different than their email.

=item can_login

I<can_login> (boolean) A boolean value to indicate if the user can login into bugzilla.

=item email_enabled

I<email_enabled> (boolean) A boolean value to indicate if bug-related mail will be sent to the user or not.

=item disabled_text

I<disabled_text> (string) A text field that holds the reason for disabling a user from logging into bugzilla, if empty then the user account is enabled otherwise it is disabled/closed.

=back

=back

=head3 Errors

=over 4

=item 51 - Invalid Object

A non existing group name was passed to the function, as a result no group object existed for that invalid name.

=item 805 - Cannot view groups

Logged-in users are not authorized to edit bugzilla groups as they are not members of the creategroups group in bugzilla, or they are not authorized to access group member's information as they are not members of the "editusers" group or can bless the group.

=back

=head1 INSTANCE METHODS

FIXME Not yet implemented

=head1 EXCEPTION HANDLING

See L<BZ::Client::Exception>

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Group.html>

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
