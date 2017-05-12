#
#    UserDBAuthen.pm - Apache authentication handler the uses the UserDB.
#
#    This file is part of Apache::iNcom.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999 Francis J. Lacoste, iNsu Innovations
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
package Apache::iNcom::UserDBAuthen;

use strict;

use Apache;
use Apache::Constants qw( :common :response );

use Apache::iNcom;

use DBIx::SearchProfiles;
use DBIx::UserDB;

sub handler {
    my $r = shift;

    # Load iNcom configuration

    # Setup the database object
    my $sql_profile = $r->dir_config( "INCOM_SEARCH_PROFILE" )
      || "conf/search_profiles.pl";
    $sql_profile = $r->server_root_relative( $sql_profile );

    my $db	= new DBIx::SearchProfiles( $r->pnotes( "INCOM_DBH" ),
					    $sql_profile );

    # Setup the UserDB object
    my $userdb = new DBIx::UserDB( $db,
				   $r->dir_config( "INCOM_USERDB_PROFILE" ),
				   $r->dir_config( "INCOM_GROUPDB_PROFILE" )
				 );

    my $use_session = $r->dir_config( "INCOM_AUTH_SESSION" ) || "false";
    $use_session = $use_session =~ /1|t(rue)?|on|y(es)?/i;
    if ( $use_session ) {

	# Try to authenticate with the session
	my $session = $r->pnotes( "INCOM_SESSION" );
	if ( exists $session->{_incom_logged_in} ) {

	    my $user = $userdb->user_get( $session->{_incom_logged_in} );
	    $r->connection->user( $user->{username} );
	    return OK;

	} else {

	    $r->note_basic_auth_failure;
	    $r->log_reason( "User is not logged in", $r->filename );
	    return Apache::iNcom::return_error( $r, AUTH_REQUIRED );

	}
    } else {

	# Get user credentials
	my ( $rc,  $passwd ) = $r->get_basic_auth_pw();
	return $rc if $rc != OK;

	# Get the username
	my $username = $r->connection->user;

	# We are missing some infos here
	unless ( $username and $passwd ) {
	    $r->note_basic_auth_failure;
	    $r->log_reason( "Missing username or password for authentication",
			    $r->filename );
	    return Apache::iNcom::return_error( $r, AUTH_REQUIRED );
	}

	# Check authentication
	if ( $userdb->user_login( $username, $passwd ) ) {
	    return OK;
	} else {
	    $r->note_basic_auth_failure;
	    $r->log_reason( "Authentication failed for $username",
			    $r->filename );
	    return Apache::iNcom::return_error( $r, AUTH_REQUIRED );
	}
    }
}

1;

__END__

=pod

=head1 NAME

Apache::iNcom::UserDBAuthen - mod_perl authentication handler that use
the UserDB.

=head1 SYNOPSIS

    PerlRequire	Apache::iNcom:UserDBAuthen

    AuthType Basic
    AuthName "iNcom Users"

    PerlAuthenHandler	Apache::iNcom::UserDBAuthen

    require valid-user

=head1 DESCRIPTION

This module integrates the DBIx::UserDB modules used by the
Apache::iNcom with the apache authentication phase.

This module can either try to authenticate the user by trying
to C<login()> on the standard DBIx::UserDB object. Or it can set
the username associated with the connection based on the login status
set in the Apache::iNcom session.

=head1 CONFIGURATION

This module takes on configuration directive C<INCOM_AUTH_SESSION>.
Set it to true to sync the Apache authentication status with the one
in the Apache::iNcom session.

If this directive is set to false or left undefined. The module will
authenticate the user against the default Apache::iNcom DBIx::UserDB
object.

The DBIx::UserDB used in the process is configured via the normal
Apache::iNcom directives.

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

Apache::iNcom(3) DBIx::UserDB(3) Apache::iNcom::UserDBAuthz(3)

=cut

