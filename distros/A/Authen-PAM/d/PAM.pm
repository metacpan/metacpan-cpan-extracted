#This is a dummy file so CPAN will find a VERSION
package Authen::PAM;
$VERSION = "0.16";
#This is to make sure require will return an error
0;
__END__

=head1 NAME

Authen::PAM - Perl interface to PAM library

=head1 SYNOPSIS

  use Authen::PAM;

  $res = pam_start($service_name, $pamh);
  $res = pam_start($service_name, $user, $pamh);
  $res = pam_start($service_name, $user, \&my_conv_func, $pamh);
  $res = pam_end($pamh, $pam_status);

  $res = pam_authenticate($pamh, $flags);
  $res = pam_setcred($pamh, $flags);
  $res = pam_acct_mgmt($pamh, $flags);
  $res = pam_open_session($pamh, $flags);
  $res = pam_close_session($pamh, $flags);
  $res = pam_chauthtok($pamh, $flags);

  $error_str = pam_strerror($pamh, $errnum);

  $res = pam_set_item($pamh, $item_type, $item);
  $res = pam_get_item($pamh, $item_type, $item);

  if (HAVE_PAM_ENV_FUNCTIONS()) {
      $res = pam_putenv($pamh, $name_value);
      $val = pam_getenv($pamh, $name);
      %env = pam_getenvlist($pamh);
  }

  if (HAVE_PAM_FAIL_DELAY()) {
      $res = pam_fail_delay($pamh, $musec_delay);
      $res = pam_set_item($pamh, PAM_FAIL_DELAY(), \&my_fail_delay_func);
  }

=head1 DESCRIPTION

The I<Authen::PAM> module provides a Perl interface to the I<PAM>
library. The only difference with the standard PAM interface is that
instead of passing a pam_conv struct which has an additional context
parameter appdata_ptr, you must only give an address to a conversation
function written in Perl (see below).

If you want to pass a NULL pointer as a value of the $user in
pam_start use undef or the two-argument version. Both in the two and
the three-argument versions of pam_start a default conversation
function is used (Authen::PAM::pam_default_conv).

The $flags argument is optional for all functions which use it
except for pam_setcred. The $pam_status argument is also optional for
pam_end function. Both of these arguments will be set to 0 if not given.

The names of some constants from the PAM library have changed over the
time. You can use any of the known names for a given constant although
it is advisable to use the latest one.

When this module supports some of the additional features of the PAM
library (e.g. pam_fail_delay) then the corresponding HAVE_PAM_XXX
constant will have a value 1 otherwise it will return 0.

For compatibility with older PAM libraries I have added the constant
HAVE_PAM_ENV_FUNCTIONS which is true if your PAM library has the
functions for handling environment variables (pam_putenv, pam_getenv,
pam_getenvlist).


=head2 Object Oriented Style

If you prefer to use an object oriented style for accessing the PAM
library here is the interface:

  use Authen::PAM qw(:constants);

  $pamh = new Authen::PAM($service_name);
  $pamh = new Authen::PAM($service_name, $user);
  $pamh = new Authen::PAM($service_name, $user, \&my_conv_func);

  ref($pamh) || die "Error code $pamh during PAM init!";

  $res = $pamh->pam_authenticate($flags);
  $res = $pamh->pam_setcred($flags);
  $res = $pamh->pam_acct_mgmt($flags);
  $res = $pamh->pam_open_session($flags);
  $res = $pamh->pam_close_session($flags);
  $res = $pamh->pam_chauthtok($flags);

  $error_str = $pamh->pam_strerror($errnum);

  $res = $pamh->pam_set_item($item_type, $item);
  $res = $pamh->pam_get_item($item_type, $item);

  $res = $pamh->pam_putenv($name_value);
  $val = $pamh->pam_getenv($name);
  %env = $pamh->pam_getenvlist;

The constructor new will call the pam_start function and if successfull
will return an object reference. Otherwise the $pamh will contain the
error number returned by pam_start.
The pam_end function will be called automatically when the object is no
longer referenced.

=head2 Examples

Here is an example of using PAM for changing the password of the current
user:

  use Authen::PAM;

  $login_name = getpwuid($<);

  pam_start("passwd", $login_name, $pamh);
  pam_chauthtok($pamh);
  pam_end($pamh);


or the same thing but using OO style:

  $pamh = new Authen::PAM("passwd", $login_name);
  $pamh->pam_chauthtok;
  $pamh = 0;  # Force perl to call the destructor for the $pamh

=head2 Conversation function format

When starting the PAM the user must supply a conversation function.
It is used for interaction between the PAM modules and the user. The
argument of the function is a list of pairs ($msg_type, $msg) and it
must return a list with the same number of pairs ($resp_retcode,
$resp) with replies to the input messages. For now the $resp_retcode
is not used and must be always set to 0. In addition the user must
append to the end of the resulting list the return code of the
conversation function (usually PAM_SUCCESS). If you want to abort
the conversation function for some reason then just return an error
code, normally PAM_CONV_ERR.

Here is a sample form of the PAM conversation function:

  sub my_conv_func {
      my @res;
      while ( @_ ) {
          my $msg_type = shift;
          my $msg = shift;

          print $msg;

	 # switch ($msg_type) { obtain value for $ans; }

         push @res, (0,$ans);
      }
      push @res, PAM_SUCCESS();
      return @res;
  }

More examples can be found in the L<Authen::PAM:FAQ>.

=head1 COMPATIBILITY

The following constant names: PAM_AUTHTOKEN_REQD, PAM_CRED_ESTABLISH,
PAM_CRED_DELETE, PAM_CRED_REINITIALIZE, PAM_CRED_REFRESH are used by
some older version of the Linux-PAM library and are not exported by
default. If you really want them, load the module with

  use Authen::PAM qw(:DEFAULT :old);

This module still does not support some of the new Linux-PAM
functions such as pam_system_log.

=head1 SEE ALSO

PAM Application developer's Manual,
L<Authen::PAM::FAQ>

=head1 AUTHOR

Nikolay Pelov <NIKIP at cpan.org>

=head1 COPYRIGHT

Copyright (c) 1998-2005 Nikolay Pelov. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
