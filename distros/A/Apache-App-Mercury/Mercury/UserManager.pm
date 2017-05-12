package Apache::App::Mercury::UserManager;

require 5.004;
use strict;

use Apache::App::Mercury::Base;
use base qw(Apache::App::Mercury::Base);

sub initialize {
    my ($self) = @_;
    # save default user in 'user' instance var
}

sub cleanup {
    my ($self) = @_;
}

=head1 NAME

Apache::App::Mercury::UserManager - Sample UserManager class

=head1 DESCRIPTION

This is a sample class which illustrates how Apache::App::Mercury
uses a user manager class to interact with your application's users.
You should implement your own UserManager class with the methods
described below to fit your application.  Set the name of your UserManager
class in the Apache::App::Mercury::Config::USER_MANAGER_CLASS variable.

=head1 METHODS

=over 4

=item * userprofile($param)

Get profile information on current user (logged in to your application).
Expects the calling object to know what user is logged in,
and the userprofile() method to have access to that information.

Currently, userprofile() must minimally support the
following values for $param (return the appropriate user
information when called with that $param):

  user        Apache::App::Mercury user name
  user_desc   long user description (e.g. "Fname Lname")
  e_mail      user's e-mail address
  fname       user's first name
  lname       user's last name

Your userprofile() method can support more; which you can
then make use of in a custom Display class, for example.
You can also opt to make your userprofile() method read-write,
and then make use of it elsewhere in your application.
The only requirements of Apache::App::Mercury is it should
return valid values for the above params for the currently
logged-in user.

=cut
sub userprofile($) {}

=item * get_userinfo(@users)

Get user profile information on users that exist in the application
(but not necessarily logged in at the moment).  Input is a list of
valid user names in your application.  Output should be an array of
hashrefs, one for each of @users, (minimally) of the following structure:

  { user  => 'userid',
    fname => 'First name of user',
    mname => 'Middle name or initial of user', #optional
    lname => 'Last name of user',
    e_mail => 'email@forward.to.addr' }

=cut
sub get_userinfo(@) {}

=item * mailboxes($user, [@update_boxes])

Get a list of $user's custom-defined mailboxes, or if called in
set context sets the given user's custom-defined mailboxes to
those specified in @update_boxes.  If called in set context,
return 1 for success, undef on failure.

=cut
sub mailboxes($@) {}

=item * mail_trans_filter([$trans_box])

Get name of mailbox to send transaction-related msgs to for current user.
In set context (if $trans_box is given), sets mailbox to filter
transaction-related msgs to.  Returns 1 for success, undef on failure.

Expects the calling object to know what user is logged in,
and the mail_trans_filter() method to have access to that information.

=cut
sub mail_trans_filter {}

=item * auto_forward($level)

Get auto-forward setting for current user, given a security level.
Security level may be one of "low", "medium", or "high".
Return value is one of "message", "notify", or "none".

  "message" => "send the entire message",
  "notify"  => "send a notification",
  "none"    => "do not send anything"

Expects the calling object to know what user is logged in,
and the auto_forward() method to have access to that information.

=cut
sub auto_forward($) {}


1;
__END__

=head1 AUTHOR

Adi Fairbank <adi@adiraj.org>

=head1 COPYRIGHT

Copyright (c) 2003 - Adi Fairbank

This software (Apache::App::Mercury and all related Perl modules under
the Apache::App::Mercury namespace) is copyright Adi Fairbank.

=head1 LAST MODIFIED

July 19, 2003

=cut
