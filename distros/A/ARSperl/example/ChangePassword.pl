#!/usr/bin/perl

#
# NAME
#  ChangePassword.pl server username password newpassword
#
# DESCRIPTION
#  This script allows a user to change his password. Since user accounts are just
#  plain records in a form we use the common getlistentry and setentry calls to
#  fetch the user's record and update the password field.
#  Note that on some systems permissions are set strangely and depending on
#  the type of license you have you might not be able to update your password
#  (Think Read Restricted licenses...)
#  Also on some systems the User form is renamed to something other than "User".
#
# AUTHOR
#  Michiel Beijen, Mansolutions, 2007.
#

use ARS;
use strict;

die "usage: ChangePassword.pl server username password newpassword\n"
  unless ( $#ARGV >= 3 );

my ( $server, $user, $password, $newpassword ) = ( shift, shift, shift, shift );

#Logging in to the server
( my $ctrl = ars_Login( $server, $user, $password ) )
  || die "ars_Login: $ars_errstr";

# Creating qualifier to look up the entry ID of the username; Login Name field is 101.
( my $userqualifier = ars_LoadQualifier( $ctrl, "User", "'101' = \"$user\"" ) )
  || die "ars_LoadQualifier(User): $ars_errstr";

# fetch the Entry ID for this user by using GetListEntry with the qualifier we
# just specified, otherwise die.
my @userentry = ars_GetListEntry( $ctrl, "User", $userqualifier, 0, 0 );
die "No such user $user? ($ars_errstr)\n" if ( $#userentry == -1 );

# Change the password for this user by setting field 102 (the password field) with the new value
ars_SetEntry( $ctrl, "User", $userentry[0], 0, 102, $newpassword )
  || die "Error updating password: $ars_errstr";
print "Password changed for user $user on server $server\n";
