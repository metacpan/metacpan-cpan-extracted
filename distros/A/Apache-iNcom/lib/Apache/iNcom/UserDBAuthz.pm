#
#    UserDBAuthz.pm - Apache authorization handler using the UserDB.
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
package Apache::iNcom::UserDBAuthz;

use strict;

require 5.005; # For the semantics of Text::ParseWords

use Apache;
use Apache::Constants qw( :common :response );

use Apache::iNcom;

use DBIx::SearchProfiles;
use DBIx::UserDB;

use Text::ParseWords ();

sub handler {
    my $r = shift;

    my $requires = $r->requires;
    return DECLINED unless $requires;

    # Load the UserDB and the current user
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

    my $user;
    if ( $r->connection->user ) {
	$user = $userdb->user_search( { username => $r->connection->user }
				    )->[0];
	unless ( $user ) {
	    $r->log_reason( "No such user " . $r->connection->user, 
			    $r->filename );
	    return Apache::iNcom::return_error( $r, AUTH_REQUIRED );
	}
    } else {
	my $session = $r->pnotes( "INCOM_SESSION" );
	if ( exists $session->{_incom_logged_in} ) {
	    $user = $userdb->user_get( $session->{_incom_logged_in} );
	} else {
	    $r->log_reason( "User is not logged in", $r->filename );
	    return Apache::iNcom::return_error( $r, AUTH_REQUIRED );
	}
    }

    # Requires are a disjonction, which means that ONLY one is needed
    # to give access. Each conditions in a require is a conjonction.
  REQUIRES:
    foreach my $req ( @$requires ) {
	# Split the requirements in its part
	my @expr = Text::ParseWords::quotewords( '\s*(and|;|,)\s*', 0,
						 $req->{requirement} );
	next REQUIRES unless @expr;

	# Each expr is than parse as a series of words
	@expr = map { [ Text::ParseWords::quotewords('\s+',0, $_ ) ] } @expr;

	foreach my $e ( @expr ) {
	    unless ( @$e ) {
		$r->warn( "Invalid requirements expression in " .
			  $req->{requirement} );
		next REQUIRES;
	    }

	    # valid-user
	    next if ( $e->[0] eq "valid-user" );

	    # user <username>
	    if ( $e->[0] eq "user" ) {
		if ( @$e != 2 ) {
		    $r->warn( "user expression takes only one args in " .
			      $req->{requirement}
			    );
		    next REQUIRES;
		}
		next if $e->[1] eq $user->{username};
		# Username doesn't match
		next REQUIRES;
	    }


	    # group <groupname>
	    if ( $e->[0] eq "group" ) {
		if ( @$e != 2 ) {
		    $r->warn( "group expression takes only one args in " .
			      $req->{requirement}
			    );
		    next REQUIRES;
		}
		next if grep {
		    $e->[1] eq $_->{groupname}
		} @{ $user->{groups} };
		# Group doesn't match
		next REQUIRES;
	    }

	    # perm on URL
	    if ( @$e == 1 ) {
		my $target = $r->uri;
		my $prefix = $r->dir_config( "INCOM_URL_PREFIX" );
		$target =~ s/^$prefix//;

		next if $userdb->allowed( $user, $target, $e->[0] );

		next REQUIRES;
	    } else {
		if ( @$e > 3 ) {
		    $r->warn( "syntax of ACL is perm or perm on target in " .
			      $req->{requirement}
			    );
		    next REQUIRES;
		}
		# Allow noise word between perm and target
		# Ex: perm on target
		my $target = @$e == 3 ? $e->[2] : $e->[1];

		next if $userdb->allowed( $user, $target, $e->[0] );

		next REQUIRES;
	    }
	}

	# All were match success
	return OK;
    }

    $r->log_reason( "Not authorized", $r->filename );
    return Apache::iNcom::return_error( $r, FORBIDDEN );
}

1;

__END__

=pod

=head1 NAME

Apache::iNcom::UserDBAuthz - mod_perl authorization handler that use
the UserDB.

=head1 SYNOPSIS

    PerlRequire	Apache::iNcom:UserDBAuthz

    AuthType Basic
    AuthName "iNcom Users"

    PerlAuthenHandler	Apache::iNcom::UserDBAuthen
    PerlAuthzHandler	Apache::iNcom::UserDBAuthz

    require valid-user

    require user foo

    require group bar

    require user foo and write

    require group baz; exec on test

    require valid-user, admin code

=head1 DESCRIPTION

This module integrates the DBIx::UserDB module used by the
Apache::iNcom framework with the apache authorization phase.

This module will set the authorization on the authenticated user by
checking the DBIx::UserDB ACL.

=head1 CONFIGURATION

The DBIx::UserDB used is configured via the normal Apache::iNcom
directives.

=head1 REQUIREMENTS DIRECTIVES

This module will let the user if ANY C<require> directives match. This
means that different C<require> ar ORed together.

In a C<require> directive, different clause can be ANDed together by
separating them by C<and>, comma (,) or semi-colon (;).

Here are the different expression that are understood by the module.

=over

=item valid-user

This requirements will pass everytime the user was authenticated
successfully.

=item user <username>

This requirement will succeed if the user's username is identical.

=item group <groupname>

This requirement will suceed if the user is a member of that group.

=item <privilege>

This requirement will succeed if the user has the specified privilege
on the current URL. The C<INCOM_URL_PREFIX> is stripped from the URL.
The privilege is checked by using the C<allowed> method of the UserDB.

=item <privilege> [on] <target>

This requirement will succeed if the user has the specified privilege
on the specified target. The privilege is checked by using the
C<allowed> method of the UserDB.

=back

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

Apache::iNcom(3) DBIx::UserDB(3) Apache::iNcom::UserDBAuthen(3)

=cut
