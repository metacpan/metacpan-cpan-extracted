#!/bin/false
# PODNAME: BZ::Client::User
# ABSTRACT: Creates and edits user accounts in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::User;
$BZ::Client::User::VERSION = '4.4002';

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/User.html

## functions

sub offer_account_by_email {
    my($class, $client, $params) = @_;
    unless (ref $params) {
        $params = { email => $params }
    }
    $client->log('debug', $class . '::offer_account_by_email: Inviting');
    return $class->api_call($client, 'User.offer_account_by_email', $params, { empty_response_ok => 1});
}

sub get {
    my($class, $client, $params) = @_;
    $client->log('debug', $class . '::get: Asking.');
    if ($params->{'include_disabled'}) {
        $params->{'include_disabled'} = BZ::Client::XMLRPC::boolean::TRUE()
    }
    else {
        $params->{'include_disabled'} = BZ::Client::XMLRPC::boolean::FALSE()
    }
    my $users = $class->_returns_array($client, 'User.get', $params, 'users');
    my @result;
    for my $user (@$users) {
        push(@result, $class->new(%$user));
    }
    $client->log('debug', $class . '::get: Got ' . scalar(@result));
    return wantarray ? @result : \@result
}

## methods

sub create {
    my(undef, $client, $params) = @_;
    return _create($client, 'User.create', $params);
}

sub update {
    my($class, $client, $params) = @_;
    $client->log('debug', $class . '::update: Updating.');
    if (defined $params->{'email_enabled'}) {
        if ($params->{'email_enabled'}) {
            $params->{'email_enabled'} = BZ::Client::XMLRPC::boolean::TRUE()
        }
        else {
            $params->{'email_enabled'} = BZ::Client::XMLRPC::boolean::FALSE()
        }
    }
    my $users = $class->_returns_array($client, 'User.update', $params, 'users');
    my @result;
    for my $user (@$users) {
        push(@result, $class->new(%$user));
    }
    $client->log('debug', $class . '::update: Got ' . scalar(@result));
    return wantarray ? @result : \@result
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::User - Creates and edits user accounts in Bugzilla

=head1 VERSION

version 4.4002

=head1 SYNOPSIS

This class provides methods for accessing information about the Bugzilla
servers installation.

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $ok    = BZ::Client::User->offer_account_by_email( $client, 'email@address' );
  my $users = BZ::Client::User->get( $client, \%params );
  my $id    = BZ::Client::User->create( $client, \%params );
  my $users = BZ::Client::User->update( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 offer_account_by_email

  my $ok = BZ::Client::User->offer_account_by_email( $client, 'email@address' );
  my $ok = BZ::Client::User->offer_account_by_email( $client, \%params );

Sends an email to the user, offering to create an account. The user will have to click on a URL in the email, and choose their password and real name.

This is the recommended way to create a Bugzilla account.

=head3 Parameters

=over 4

=item email

I<email> (string) The email address to send the offer to.

Note: email can be provided as the single option as a scalar as shown above.

=back

=head3 Returns

nothing if successful

=head3 Errors

=over 4

=item 50 - Email parameter missing

The email parameter was not provided.

=item 500 - Account Already Exists

An account with that email address already exists in Bugzilla.

=item 501 - Illegal Email Address

This Bugzilla does not allow you to create accounts with the format of email address you specified. Account creation may be entirely disabled.

=back

=head2 get

  my $users = BZ::Client::User->get( $client, \%params );

Gets information about user accounts in Bugzilla.

=head3 History

Added in Bugzilla 3.4

=head3 Parameters

Note: At least one of L</ids>, L</names>, or L</match> must be specified.

Note: Users will only appear once in the returned list, even if that user is matched by more than one search argument.

In addition to the parameters below, this method also accepts the standard L<BZ::Client::Bug/include_fields> and L<BZ::Client::Bug/exclude_fields> arguments.

=over 4

=item ids (array)

An array of integers, representing user ID's.

Logged-out users cannot pass this parameter to this function. If they try, they will get an error. Logged-in users will get an error if they specify the ID of a user they cannot see.

=item names (array)

An array of login names (strings).

=item match (array)

An array of strings. This works just like "user matching" in Bugzilla itself. Users will be returned whose real name or login name contains any one of the specified strings. Users that you cannot see will not be included in the returned list.

Most installations have a limit on how many matches are returned for each string, which defaults to C<1000> but can be changed by the Bugzilla administrator.

Logged-out users cannot use this argument, and an error will be thrown if they try. (This is to make it harder for spammers to harvest email addresses from Bugzilla, and also to enforce the user visibility restrictions that are implemented on some Bugzillas.)

=item limit (int)

Limit the number of users matched by the L</match> parameter. If value is greater than the system limit, the system limit will be used. This parameter is only used when user matching using the L</match> parameter is being performed.

=item group_ids (array)

I<group_ids> is an array of numeric ids for groups that a user can be in.
If this is specified, it limits the return value to users who are in any of the groups specified.

Added in Bugzilla 4.0

=item groups (array)

I<groups> is an array of names of groups that a user can be in.
If this is specified, it limits the return value to users who are in any of the groups specified.

Added in Bugzilla 4.0

=item include_disabled (boolean)

By default, when using the L</match> parameter, disabled users are excluded from the returned results unless their full username is identical to the match string. Setting L</include_disabled> to C<true> will include disabled users in the returned results even if their username doesn't fully match the input string.

Added in Bugzilla 4.0, default behaviour for L</match> was then changed to exclude disabled users.

=back

=head3 Returns

A hash containing one item, C<users>, that is an array of hashes. Each hash describes a user, and has the following items:

=over 4

=item id

I<id> (int) The unique integer ID that Bugzilla uses to represent this user. Even if the user's login name changes, this will not change.

=item real_name

I<real_name> (string) The actual name of the user. May be blank.

=item email

I<email> (string) The email address of the user.

=item name

I<name> (string) The login name of the user. Note that in some situations this is different than their email.

=item can_login

I<can_login> (boolean) A boolean value to indicate if the user can login into bugzilla.

=item email_enabled

I<email_enabled> (boolean) A boolean value to indicate if bug-related mail will be sent to the user or not.

=item login_denied_text

I<login_denied_text> (string) A text field that holds the reason for disabling a user from logging into bugzilla, if empty then the user account is enabled. Otherwise it is disabled/closed.

=item groups

I<groups> (array) An array of group hashes the user is a member of. If the currently logged in user is querying his own account or is a member of the C<editusers> group, the array will contain all the groups that the user is a member of. Otherwise, the array will only contain groups that the logged in user can bless. Each hash describes the group and contains the following items:

Added in Bugzilla 4.4

=over 4

=item id

I<id> (int) The group ID

=item name

I<name> (string) The name of the group

=item description

I<description> (string) The description for the group

=back

=item saved_searches

I<saved_searches> (array) An array of hashes, each of which represents a user's saved search and has the following keys:

Added in Bugzilla 4.4

=over 4

=item id

I<id> (int) An integer ID uniquely identifying the saved search.

=item name

I<name> (string) The name of the saved search.

=item query

I<query> (string) The CGI parameters for the saved search.

=back

=item saved_reports

I<saved_reports> (array) An array of hashes, each of which represents a user's saved report and has the following keys:

Added in Bugzilla 4.4

=over 4

=item id

I<id> (int) An integer ID uniquely identifying the saved report.

=item name

I<name> (string) The name of the saved report.

=item query

I<query> (string) The CGI parameters for the saved report.

=back

Note: If you are not logged in to Bugzilla when you call this function, you will only be returned the C<id>, C<name>, and C<real_name> items.
If you are logged in and not in C<editusers> group, you will only be returned the C<id>, C<name>, C<real_name>, C<email>, C<can_login>, and C<groups> items.
The C<groups> returned are filtered based on your permission to bless each group.
The L</saved_searches> and L</saved_reports> items are only returned if you are querying your own account, even if you are in the C<editusers> group.

=back

=head3 Errors

=over 4

=item 51 - Bad Login Name or Group ID

You passed an invalid login name in the L</names> array or a bad group ID in the L</group_ids> argument.

=item 52 - Invalid Parameter

The value used must be an integer greater then zero.

=item 304 - Authorization Required

You are logged in, but you are not authorized to see one of the users you wanted to get information about by user ID.

=item 505 - User Access By Id or User-Matching Denied

Logged-out users cannot use the C<ids> or C<match> arguments to this function.

=item 804 - Invalid Group Name

You passed a group name in the C<groups> argument which either does not exist or you do not belong to it.

Added in Bugzilla 4.0.9 and 4.2.4, when it also became illegal to pass a group name you don't belong to.

=back

=head2 new

  my $user = BZ::Client::User->new( id => $id );

Creates a new instance with the given ID.

=head2 create

  my $id = BZ::Client::User->create( $client, \%params );

Creates a user account directly in Bugzilla, password and all.
Instead of this, you should use L</offer_account_by_email> when possible, because that makes sure that the email address specified can actually receive an email.
This function does not check that.

You must be logged in and have the C<editusers> privilege in order to call this function.

Params:

=over 4

=item email

I<email> (string) - The email address for the new user.

B<Required>.

=item full_name

I<full_name> (string) The user's full name. Will be set to empty if not specified.

=item password

I<password> (string) The password for the new user account, in plain text. It will be stripped of leading and trailing whitespace. If blank or not specified, the newly created account will exist in Bugzilla, but will not be allowed to log in using DB authentication until a password is set either by the user (through resetting their password) or by the administrator.

=back

=head3 Returns

The numeric ID of the user that was created.

=head3 Errors

The same as L</offer_account_by_email>. If a password is specified, the function may also throw:

=over 4

=item 502 - Password Too Short

The password specified is too short. (Usually, this means the password is under three characters.)

=item 503 - Password Too Long

Removed in Bugzilla 3.6

=back

=head2 update

 my $users = BZ::Client::User->update( $client, \%params );

Updates user accounts in Bugzilla.

=head3 Parameters

=over 4

=item ids

I<array> Contains ID's of user to update.

=item names

I<array> Contains email/login of user to update.

=item full_name

I<full_name> (string) The new name of the user.

=item email

I<email> (string) The email of the user. Note that email used to login to bugzilla. Also note that you can only update one user at a time when changing the login name / email. (An error will be thrown if you try to update this field for multiple users at once.)

=item password

I<password> (string) The password of the user.

=item email_enabled

I<email_enabled> (boolean) A boolean value to enable/disable sending bug-related mail to the user.

=item login_denied_text

I<login_denied_text> (string) A text field that holds the reason for disabling a user from logging into Bugzilla, if empty then the user account is enabled otherwise it is disabled/closed.

=back

=head3 Returns

An array of hashes with the following fields:

=over 4

=item id

I<id> (int) The ID of the user that was updated.

=item changes

I<changes> (hash) The changes that were actually done on this user. The keys are the names of the fields that were changed, and the values are a hash with two keys:

=item added

I<added> (string) The values that were added to this field, possibly a comma-and-space-separated list if multiple values were added.

=item removed

I<removed> (string) The values that were removed from this field, possibly a comma-and-space-separated list if multiple values were removed.

=back

=head3 Errors

=over 4

=item 51 - Bad Login Name

You passed an invalid login name in the C<names> array.

=item 304 - Authorization Required

Logged-in users are not authorized to edit other users.

=back

=head1 EXCEPTION HANDLING

See L<BZ::Client::Exception>

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/User.html>

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
