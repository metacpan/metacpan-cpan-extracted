#
#    Request.pm - Object that encaspulates an iNcom request.
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
package Apache::iNcom::Request;

use strict;

use Apache::Util;

use Apache::iNcom::CartManager;
use Apache::iNcom::OrderManager;
use Apache::iNcom::Localizer;

use DBIx::SearchProfiles;
use DBIx::UserDB;

use HTML::FormValidator;

use Symbol;

use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );

use Carp;

BEGIN {
    use Exporter;

    @ISA       = qw( Exporter );
    @EXPORT    = ();
    @EXPORT_OK = ();
    %EXPORT_TAGS = (); # This is filled later near the
		       # declaration of global variables

    ($VERSION) = '$Revision: 1.15 $' =~ /Revision: ([\d.]+)/;
}

=pod

=head1 NAME

Apache::iNcom::Request - Manages the Apache::iNcom request's informations.

=head1 SYNOPSIS

    my $user = $Request->user

    etc.

=head1 DESCRIPTION

This module is responsible for managing the environment in which the
Apache::iNcom page will execute. It setups all the objects that will
be accessible to the pages through globals and also provides the
page with a bunch of utility functions. It also provides a bunch
of methods for managing the information associated with the request.


=head1 INITIALIZATION

An object is automatically initialized on each request by the
Apache::iNcom framework. It is accessible through the $Request global
variable in Apache::iNcom pages.

=cut

sub new {
    my $proto	= shift;
    my $class	= ref $proto || $proto;

    my $req_rec = shift;
    my $package = shift;

    my $self = { req_rec => $req_rec,
		 package => $package,
	       };
    bless $self, $class;

    $self->{session}	     = $req_rec->pnotes( "INCOM_SESSION" );
    $self->{dbh}	     = $req_rec->pnotes( "INCOM_DBH" );

    my $root		    = $req_rec->dir_config( "INCOM_ROOT" );
    $root		    = $req_rec->server_root_relative( $root );
    my ($current)	    = $req_rec->filename =~ m!^$root/*(.*)!;
    $self->{current_page}   = $current;
    $self->{last_page}	    = $self->{session}{_incom_last_page};

    # Save current for next session
    $self->{session}{_incom_last_page} = $current;

    # Setup the database object
    my $sql_profile = $req_rec->dir_config( "INCOM_SEARCH_PROFILE" )
      || "conf/search_profiles.pl";
    unless ( $sql_profile eq "NONE" ) {
	$sql_profile = $req_rec->server_root_relative( $sql_profile );
	$self->{database} = new DBIx::SearchProfiles( $self->{dbh},
						      $sql_profile );

	# Setup the UserDB object
	my $userdb_tmpl = $req_rec->dir_config( "INCOM_USERDB_PROFILE" );
	unless ( $userdb_tmpl eq "NONE" ) {
	    $self->{userdb} = new DBIx::UserDB( $self->{database}, 
						$userdb_tmpl,
						$req_rec->dir_config( "INCOM_GROUPDB_PROFILE" ) );

	    my $scramble = $req_rec->dir_config( "INCOM_SCRAMBLE_PASSWORD" );
	    if ( defined $scramble ) {
		$scramble = $scramble =~ /t(rue)?|1|on|y(es)?/i;
		$self->{userdb}->scramble_password( $scramble );
	    }

	    # Load it if the user has logged into this session
	    if ( exists $self->{session}{_incom_logged_in} ) {
		$self->{user} =
		  $self->{userdb}->user_get( $self->{session}{_incom_logged_in} );
	    }
	}
    }

    # Setup validator object
    my $input_profile = $req_rec->dir_config( "INCOM_INPUT_PROFILE" )
      || "conf/input_profiles.pl";
    unless ( $input_profile eq "NONE" ) {
	$input_profile = $req_rec->server_root_relative( $input_profile );

	$self->{validator} = new HTML::FormValidator( $input_profile );
    }

    # Setup the cart object
    my $price_profile = $req_rec->dir_config( "INCOM_PRICING_PROFILE" )
      ||  "conf/pricing_profile.pl";
    unless ( $price_profile eq "NONE" ) {
	$price_profile = $req_rec->server_root_relative( $price_profile );
	$self->{cart} = new Apache::iNcom::CartManager( $self->{session}{_incom_cart},
							$package,
							$price_profile );

	# Make sure the session contains the cart references
	# (In case it wasn't present)
	$self->{session}{_incom_cart} = $self->{cart}->cart();
    }

    # Setup order manager object
    my $order_profile = $req_rec->dir_config( "INCOM_ORDER_PROFILE" )
      ||  "conf/order_profiles.pl";
    unless ( $order_profile eq "NONE" ) {
	$order_profile = $req_rec->server_root_relative( $order_profile );
	$self->{order} = new Apache::iNcom::OrderManager( $self->{database},
							  $order_profile,
							  $self,
							);

    }

    $self;
}

=pod

=head2 logged_in

Returns true if the request is associated with a UserDB's user.

=cut

sub logged_in {
    # Throw an exception if the UserDB feature was turn off.
    croak "logged_in called when INCOM_USERDB_PROFILE set to NONE"
      unless $_[0]->{userdb};
    return defined $_[0]->{user};
}

=pod

=head2 user

Returns the UserDB's user associated with the current request.

=cut

sub user {
    # Throw an exception if the UserDB feature was turn off.
    croak "user() called when INCOM_USERDB_PROFILE set to NONE"
      unless $_[0]->{userdb};
    return $_[0]->{user};
}

=pod

=head2 current

Returns the name of the current page relative to INCOM_PREFIX.

=cut

sub current {
    return $_[0]->{current_page};
}

=pod

=head2 previous

Returns the name of the previous page fetched by the user.

=cut

sub previous {
    return $_[0]->{last_page};
}

=pod

=head2 browser

Returns the user agent string sent by the user's browser.

=cut

sub browser {
    return $_[0]->{req_rec}->header_in( "User-Agent" );
}

=pod

=head2 remote_host

Returns the hostname of the user. This can be an IP address is
hostname resolution is turn off.

=cut

sub remote_host {
    return $_[0]->{req_rec}->connection->remote_host;

}

=pod

=head2 remote_ip

Returns the ip address of the user.

=cut

sub remote_ip {
    return $_[0]->{req_rec}->connection->remote_ip;
}

=pod

=head2 login ( $username, $password )

Invokes the C<login> methods of the UserDB and if the login succeeded,
the user will be associated with the current Session, and its informations
will be available on each subsequent requests until the user logout.

=cut

sub login {
    my ($self,$username,$password) = @_;

    # Throw an exception if the UserDB feature was turn off.
    croak "login called when INCOM_USERDB_PROFILE set to NONE"
      unless $_[0]->{userdb};

    my $user;
    if ( $user = $self->{userdb}->user_login( $username, $password ) ) {
	# The login succeeded
	# Update the session and save the user
	$self->{session}{_incom_logged_in} = $user->{uid};

	$user->{last_login} = time;
	$user->{last_host}  = $self->remote_host || $self->remote_ip;
	$user->{visits} ||= 0;
	$user->{visits}++;

	$self->{userdb}->user_update( $user );

	# Create the user session
	$self->{session}{_incom_user_session} = {};
	$self->{user} = $user;
    }

    return $user;
}

=pod

=head2 logout

Removes the association between the user and the request.

=cut

sub logout {
    my $self	    = shift;

    # Throw an exception if the UserDB feature was turn off.
    croak "logout called when INCOM_USERDB_PROFILE set to NONE"
      unless $self->{userdb};

    my $save_cart   = shift;
    if ( exists $self->{user} ) {
	delete $self->{user};
	delete $self->{session}{_incom_logged_in};
	delete $self->{session}{_incom_user_session};
    }
}

# We need to use globals for the magic 
# symbol table manipulation, because
# Include files remember the state 
# of lexical variable -> closure.
use vars qw( $DB %Session %UserSession $package $Cart $Request $UserDB
	     $Validator $Order $Locale $Localizer ); #)

BEGIN {
    push @EXPORT_OK, qw( $package );
    $EXPORT_TAGS{globals} = [ qw( $DB %Session %UserSession $Cart $Request 
				  $UserDB $Validator $Order $Locale
				  $Localizer ) ];
    $EXPORT_TAGS{functions} = [ qw( Localize Currency Include
				     TextInclude QueryArgs ) ];

    Exporter::export_ok_tags( 'globals' );
    Exporter::export_ok_tags( 'functions' );
}

=pod

=head1 APACHE::INCOM PAGE GLOBALS

Here is a list of the global variables that are defined in the page when
it is executing.

=over

=item $Request

An Apache::iNcom::Request object which can used to query information about
the current request.

=item $DB

A DBIx::SearchProfiles object initialized with as requested by the
Apache::iNcom configuration.

=item $Cart

An Apache::iNcom::CartManager object initialized with the configured
pricing profile.

=item $Order

An Apache::iNcom::OrderManager object initialized with the configured
order profiles.

=item %Session

A hash which associated with the current client. Values in that hash
will persist across request until the user close its browser or
C<INCOM_SESSION_EXPIRES> time has elapsed.

=item %UserSession

A hash which associated with the user currently logged. Values in that
hash will persist across request as long as the client is logged in
and will be cleared once the user logs out.


=item $UserDB

A DBIx::UserDB object which should be used for user management.

=item $Validator

An HTML::Validator object initialized with the configured input
profiles.

=item $Localizer

An Apache::iNcom::Localizer object initialized with the user requested
language.

=item $Locale

A Locale::Maketext object initialized with the proper locale. The
Locale::Maketext subclass used is specified in the C<INCOM_LOCALE>
configuration directives.

=back

=cut

sub setup_aliases {
    my ( $self ) = shift;

    $package	 = $self->{package};
    $DB		 = $self->{database};
    $Cart	 = $self->{cart};
    $Order	 = $self->{order};
    $Request	 = $self;
    *Session	 = $self->{session};
    *UserSession = $self->{session}{_incom_user_session};
    $UserDB	 = $self->{userdb};
    $Validator	 = $self->{validator};
    $Localizer	 = $self->{req_rec}->pnotes( "INCOM_LOCALIZER" );
    if ( $self->{req_rec}->dir_config( "INCOM_LOCALE" ) ) {
	$Locale	=
	  $Localizer->get_handle( $self->{req_rec}->dir_config( "INCOM_LOCALE" ) );
    }
    # Play magic in the namespace of the page
    {
	no strict 'refs';

	*{"$package\:\:DB"}		= \$DB		if $DB;
	*{"$package\:\:UserDB"}		= \$UserDB	if $UserDB;
	*{"$package\:\:Cart"}		= \$Cart	if $Cart;
	*{"$package\:\:Order"}		= \$Order	if $Cart;
	*{"$package\:\:Validator"}	= \$Validator	if $Validator;
	*{"$package\:\:Locale"}		= \$Locale	if $Locale;
	*{"$package\:\:Localizer"}	= \$Localizer	if $Localizer;
	*{"$package\:\:Session"}	= \%Session;
	*{"$package\:\:UserSession"}	= \%UserSession;
	*{"$package\:\:Request"}	= \$Request;
	*{"$package\:\:Localize"}	= \&Localize	if $Locale;
	*{"$package\:\:Currency"}	= \&Currency	if $Locale;
	*{"$package\:\:Include"}	= \&Include;
	*{"$package\:\:TextInclude"}	= \&TextInclude;
	*{"$package\:\:QueryArgs"}	= \&QueryArgs;
    };
}

sub cleanup_aliases {
    my ( $self ) = shift;

    $package	 = undef;
    $DB		 = undef;
    $Cart	 = undef;
    $Order	 = undef;
    $Request	 = undef;
    *Session	 = undef; # Undef the symbol, do not destroy the hash
    *UserSession = undef;
    $UserDB	 = undef;
    $Validator	 = undef;
    $Localizer	 = undef;
    $Locale	 = undef;

    # Play magic in the namespace of the page
    {
	no strict 'refs';

	*{"$package\:\:DB"}		= undef;
	*{"$package\:\:UserDB"}		= undef;
	*{"$package\:\:Cart"}		= undef;
	*{"$package\:\:Order"}		= undef;
	*{"$package\:\:Validator"}	= undef;
	*{"$package\:\:Locale"}		= undef;
	*{"$package\:\:Localizer"}	= undef;
	*{"$package\:\:Session"}	= undef;
	*{"$package\:\:UserSession"}	= undef;
	*{"$package\:\:Request"}	= undef;
	*{"$package\:\:Localize"}	= undef;
	*{"$package\:\:Currency"}	= undef;
	*{"$package\:\:Include"}	= undef;
	*{"$package\:\:TextInclude"}	= undef;
	*{"$package\:\:QueryArgs"}	= undef;
    };
}

=pod

=head1 APACHE::INCOM PAGE FUNCTIONS

Here is list of the helper functions that are defined in the context
of the executing page and that can be used.

=head2 Localize ( ... )

This acts as a wrapper around $Locale->maketext. It should be used
to format messages in a localized format for the user.

=cut

sub Localize {
    return $Locale->maketext( @_ );
}

=pod

=head2 Currency ( ... )

This acts as a wrapper around $Locale->currency. It should be used to
format amount of money for display.

=cut

sub Currency {
    return $Locale->currency( @_ );
}

=pod

=head2 Include ( $file_or_param_ref )

This is a function which is like HTML::Embperl::Execute in that it
includes another page in the current one. The difference is that this
included page will be executed in the name space of the current so
that all global variables remains accessible. Also, this functions checks
for the presence of a localized version of the file and checks in the
C<INCOM_TEMPLATE_PATH> if the path is not absolute.

=cut

sub Include {
    my ($file,$params) ;
    my $r    = $Request->{req_rec};
    # Check if we are called with a file or hash param 
    if ( ref $_[0] ) {
	# We hope the caller knows what he was doing when
	# he setup the parameter hash.
	$params = shift;
	$file = $params->{inputfile};
    } else {
	$file = shift;

	# Create default params
	# Since Include file can contain fragment,
	my $debug = $r->dir_config( "EMBPERL_DEBUG" ) ||
	  $ENV{EMBPERL_DEBUG} || 0;
	# Default = optRawInput + optDisableTableScan
	# disable Table scan by default
	my $options = $r->dir_config( "EMBPERL_OPTIONS" ) ||
	  $ENV{EMBPERL_OPTIONS} || 16 | 2048;
	# optDisableFormData
	$options |= 256 ;
	$params = {
		   param	=> \@_,
		   options	=> $options,
		   debug	=> $debug,
		  };
    }

    # Search for template in TEMPLATE_PATH
    my $path = $r->pnotes( "INCOM_TEMPLATE_PATH" );

    unless ( $path ) {
	# Memoize template path
	$path = [];
	foreach my $p ( split /:/, $r->dir_config( "INCOM_TEMPLATE_PATH" ) ) {
	    push @$path, $r->server_root_relative( $p );
	}
	$r->pnotes( "INCOM_TEMPLATE_PATH", $path );
    }
    unless ( substr( $file, 0, 1) eq "/"  || -e $file ) {
	foreach my $p ( @$path ) {
	    if ( -e $p . "/" . $file ) {
		$file = $p . "/" . $file;
		last;
	    }
	}
    }

    # Localize the template
    my $localizer = $r->pnotes( "INCOM_LOCALIZER" );
    $file = $localizer->find_localized_file( $file );

    # Set the localized and normalized file
    $params->{inputfile} = $file;

    # Set the package in which to execute the template
    $params->{package} = $package;

    HTML::Embperl::Execute( $params );
}

=pod

=head2 TextInclude ( file )

This is a function is like C<Include> except that it is not interpreted
for embedded perl.

=cut

sub TextInclude {
    my $file = shift;

    # Search for template in TEMPLATE_PATH
    my $r    = $Request->{req_rec};
    my $path = $r->pnotes( "INCOM_TEMPLATE_PATH" );

    unless ( $path ) {
	# Memoize template path
	$path = [];
	foreach my $p ( split /:/, $r->dir_config( "INCOM_TEMPLATE_PATH" ) ) {
	    push @$path, $r->server_root_relative( $p );
	}
	$r->pnotes( "INCOM_TEMPLATE_PATH", $path );
    }

    unless ( substr( $file, 0, 1) eq "/"  || -e $file ) {
	foreach my $p ( @$path ) {
	    if ( -e $p . "/" . $file ) {
		$file = $p . "/" . $file;
		last;
	    }
	}
    }

    # Localize the template
    my $localizer = $r->pnotes( "INCOM_LOCALIZER" );
    $file = $localizer->find_localized_file( $file );

    {
	no strict 'refs';
	my $fh = gensym;
	open $fh, $file
	  or die "can't open file $file\n";
	print {"$package\:\:OUT"} <$fh>;
	close $fh;
    };

}

=pod

=head2 QueryArgs ( [ $fdat ], [ $odat ], [ $idat ] )

This function is similar to the [$ hidden $] directive in
HTML::Embperl but instead of generating hidden input fields, it
returns the form data as a query string.

=over

=item $fdat

The form data to output. Defaults to the %fdat hash.

=item $odat

Override data. Fields present in that hash will override the
one in %fdat.

=item $idat

Ignored data. Fields present in that hash will be ignored and
not output in the resulting query string.

=back

    Usage example :

    <a href="search.html?[- QueryArgs() -]">Next</a>

=cut

sub QueryArgs {
    my ( $fdat,$odat,$idat) = @_;

    {
	# Needed to access symbolically the page variables
	no strict 'refs';
	$fdat ||= *{"$package\:\:fdat"};
    };
    $odat ||= {};
    $idat ||= {};
    my $uri = join "&", map { 
	if ( exists $odat->{$_} ) {
	    Apache::Util::escape_uri( $_ ) . "=" .
		Apache::Util::escape_uri( $odat->{$_} );
	} elsif ( not exists $idat->{$_} ) {
	    Apache::Util::escape_uri( $_ ) . "=" .
		Apache::Util::escape_uri( $fdat->{$_} );
	}
    } keys %$fdat;

    {
	no strict 'refs';
	my $old = ${"$package\:\:escmode"};
	${"$package\:\:escmode"} = 0;
	print {"$package\:\:OUT"} $uri;
	${"$package\:\:escmode"} = $old;
    };
}

1;

__END__

=pod

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

Apache::iNcom(3) Apache::iNcom::OrderManager(3) Apache::iNcom::CartManager(3)
DBIx::SearchProfiles(3) DBIx::UserDB(3) Locale::Maketext(3) HTML::Embperl

=cut
