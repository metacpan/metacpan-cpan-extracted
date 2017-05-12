#
#    iNcom.pm - Main module of the iNcom package.
#
#    This file is part of Apache::iNcom
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
package Apache::iNcom;

use strict;

require 5.005;

use DBI;

use Apache;
use Apache::Log;
use Apache::Cookie;
use Apache::Request;
use Apache::File;
use Apache::Constants qw( :common :response HTTP_PRECONDITION_FAILED );

use HTML::Embperl;

use Apache::iNcom::Request;
use Apache::iNcom::Localizer;

use vars qw($VERSION);
BEGIN {
    ($VERSION) = '0.09';
}

my %VALID_PNOTES = map { $_ => 1 } qw (
    INCOM_SESSION INCOM_DBH INCOM_LOCALIZER INCOM_COOKIES
);

# Grabbed from CGI.pm by Lincoln Stein
sub offset_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    my($offset);
    if (!$time || (lc($time) eq 'now')) {
        $offset = 0;
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([mhdMy]?)/) {
        $offset = ($mult{$2} || 1)*$1;
    } else {
	die "invalid expiration offset: $time\n";
    }
    return ($offset);
}

sub db_init {
    my $r = shift;
    my $dsn	= $r->dir_config( "INCOM_DBI_DSN" );
    my $user	= $r->dir_config( "INCOM_DBI_USER" );
    my $passwd	= $r->dir_config( "INCOM_DBI_PASSWD" );

    unless ( $dsn ) {
	$r->log_error( "iNcom configuration error: INCOM_DBI_DSN is not defined" );
	return SERVER_ERROR;
    }

    my $dbh;
    eval {
	$dbh = DBI->connect( $dsn, $user, $passwd, { RaiseError => 1,
						     AutoCommit => 0,
						   } );
	my $trace_lvl  = $r->dir_config( "INCOM_DBI_TRACE" );
	my $trace_file = $r->dir_config( "INCOM_DBI_LOG"   );

	# Turn tracing on if requested
	if ( $trace_lvl ) {
	    $trace_file = $r->server_root_relative( $trace_file )
	      if defined $trace_file;
	    $dbh->trace( $trace_lvl, $trace_file );
	}

	# Saves it in the request record for access from
	# other handlers
	$r->pnotes( INCOM_DBH => $dbh );

    };
    if ($@ ) {
	$r->log_error( "error opening connection to database: $@" );
	return return_error( $r, SERVER_ERROR );
    }
    return OK;
}

sub i18n_init {
    my $r = shift;

    my $langs = $r->header_in( "Accept-Language" );
    my @languages;
    if ( $langs ) {
	my $q = 100;
	@languages = map {
	    $_->[0];
	} sort { $b->[1] <=> $a->[1] } map {
	    my $l;
	    if ( /([-\w]+)\s*;\s*q=([\d.]+)/ ) {
		$l = [$1, $2 ];
	    } else {
		$l = [$_, $q--];
	    }
	} split /\s*,\s*/, $langs;
    }

    # Add the language set in cookies
    my $cookies = $r->pnotes( "INCOM_COOKIES" );
    unshift @languages, $cookies->{INCOM_LANGUAGE}->value
      if $cookies->{INCOM_LANGUAGE};

    # Check each languages tags for validity
    my $localizer =
      new Apache::iNcom::Localizer( $r->dir_config( "INCOM_DEFAULT_LANGUAGE" ) || "en",
				    @languages
				  );

    # Set environment variables so that other parts of the system
    # does hopefully the Right Things(tm)
    $ENV{LANG} = $localizer->preferred_lang;

    # Long live GNU !
    $ENV{LANGUAGE} = join ":", $localizer->preferred_langs,
      $localizer->default_lang;

    # Cache it for further use.
    $r->pnotes( "INCOM_LOCALIZER", $localizer );

    return OK;
}

*Apache::iNcom::handler = \&request_init;

sub request_init {
    my $r = shift;

    # If we are in a subrequest, just copy
    # what was initialized to the new request
    if ( $r->is_main ) {
	my $prefix	    = $r->dir_config( "INCOM_URL_PREFIX" ) || "/";
	unless ( $prefix =~ m|/$| ) {
	    $r->log_error( "iNcom configuration error: INCOM_URL_PREFIX must ends with /" );
	    return SERVER_ERROR;
	}

	# Parse cookies
	my $c = $r->header_in( "Cookie" );
	my $cookies = Apache::Cookie->new( $r )->parse( $c );
	$r->pnotes( "INCOM_COOKIES", $cookies );

	# Parse languages
	my $rv = i18n_init( $r );
	return $rv if $rv != OK;

    } else {
	my $prev = $r->prev;
	foreach my $name ( keys %VALID_PNOTES ) {
	    $r->pnotes( $name, $prev->pnotes( $name ) );
	}
	return OK;
    }

    # Next handler is dispatch_handler
    $r->push_handlers( PerlTransHandler => \&dispatch_handler );

    return OK;
}

sub bake_session_cookie {
    my ($r, $session_id) = @_;

    my $prefix		= $r->dir_config( "INCOM_URL_PREFIX" ) || "/";
    my $session_secure  = $r->dir_config( "INCOM_SESSION_SECURE" );
    my $session_domain  = $r->dir_config( "INCOM_SESSION_DOMAIN" );
    my $session_expires = $r->dir_config( "INCOM_SESSION_EXPIRES" );
    my $session_path    = $r->dir_config( "INCOM_SESSION_PATH" )
      || $prefix;

    my $cookie = new Apache::Cookie( $r,
				     -name   => "INCOM_SESSION",
				     -value  => $session_id,
				     -path   => $session_path
				   );
    $cookie->domain( $session_domain )	    if $session_domain;
    $cookie->expires( $session_expires )    if $session_expires;
    $cookie->secure( 1 )		    if $session_secure;

    # Add cookie to outgoing headers
    $cookie->bake;
}

sub session_init {
    my $r = shift;

    my %session;

    # Check if there is a session id in the cookies
    my $cookies = $r->pnotes( "INCOM_COOKIES" );
    if ( $cookies->{INCOM_SESSION} ) {
	my $session_id = $cookies->{INCOM_SESSION}->value;

	# Load the user's session
	eval {
	    # Make sure it looks like a session id
	    die "Invalid session id: $session_id\n"
	      unless length $session_id == 32 &&
		$session_id =~ tr/a-fA-F0-9/a-fA-F0-9/ == 32;

	    tie %session, 'Apache::iNcom::Session', $session_id,
	      { dbh => $r->pnotes( "INCOM_DBH"),
		Serialize => $r->dir_config( "INCOM_SESSION_SERIALIZE_ACCESS" ),
	      };

	    # Save the session for future handlers
	    $r->pnotes( INCOM_SESSION => \%session );

	    if ( $r->dir_config( "INCOM_SESSION_EXPIRES" ) ) {
		# If session doesn't expire with the browser session
		# we must renew the cookie.
		bake_session_cookie( $r, $session_id );
	    }

	};
	if ( $@ ) {
	    # The session ID is probably invalid
	    chomp $@;
	    $r->warn( "error loading session: $@" );
	} else {
	    # Return ref to session to indicate success
	    return \%session;
	}
    }

    # No valid session could be loaded
    return undef;
}


# Return the requested error code but sets a custom response
# if the error condition is present in the error map.
sub return_error {
    my ( $r, $status ) = @_;

    my $prefix = $r->dir_config( "INCOM_URL_PREFIX" ) || "/";
    my $map = $r->dir_config( "INCOM_ERROR_PROFILE" );
    return $status unless $map;

    $map = $r->server_root_relative( $map );
    unless ( -e $map && -f _ && -r _ ) {
	$r->warn( "INCOM_ERROR_PROFILE is not valid" );
	return $status;
    }

    my $response = eval {
	my $profile = do $map;
	unless ( ref $profile eq "HASH" ) {
	    $r->warn( "INCOM_ERROR_PROFILE didn't return an hash ref" );
	    return $status;
	}

	my $error_cond = $r->pnotes( "INCOM_ERROR" );

	$profile->{$error_cond} || $profile->{$status};
    };
    if ( $@) {
	$r->warn( "error while evaluating error profile: $@" );
	return $status;
    }

    $r->custom_response( $status, $prefix . "/incom_error/" . $response ) if $response;

    return $status;
}

# This is a handler used to transform the request
# to an action. It is invoked during the URI
# translation phase of the request
#
# It is responsible for loading the user session. If
# there is no session it sets the content handler to
# the new_session_handler
sub dispatch_handler {
    my $r = shift;

    # Get configuration
    my $prefix	    = $r->dir_config( "INCOM_URL_PREFIX" ) || "/";
    my $index_file  = $r->dir_config( "INCOM_INDEX" )  || "index.html";
    my $incom_root  = $r->dir_config( "INCOM_ROOT" )
      || $r->document_root;
    $incom_root = $r->server_root_relative( $incom_root );

    my $uri = $r->uri;

    # Decline to handle this unless the request URI match our prefix
    return DECLINED unless $uri =~ s!^$prefix/*!!;

    # Only support GET or POST
    return NOT_IMPLEMENTED unless $r->method =~ /^(GET|POST)$/;

    if ( $r->is_main ) {
	# On the first request, we open the connection to the database
	# and loads the user session
	my $rc      = db_init( $r );
	session_init( $r );

	# To clean DB connection and Session
	$r->push_handlers( PerlCleanupHandler => \&request_cleanup );
    }

    # Determine the handler
    if ( $uri =~ s!^incom_cookie_check/!! ) {
	# Check if the session was loaded properly
	if ( ref $r->pnotes( "INCOM_SESSION") ) {
	    # Cookie test suceeded. Tell browser to refetch
	    # original file
	    $r->pnotes( "INCOM_REDIRECT_TO", $prefix . $uri );
	    $r->push_handlers( PerlHandler => \&redirect_handler );
	    $r->handler( "perl-script" );
	} else {
	    # Cookie test failed
	    $r->pnotes( "INCOM_ERROR", "no_cookies" );
	    return return_error( $r, HTTP_PRECONDITION_FAILED );
	}
    } elsif ( $uri =~ s!^incom_set_lang/([-\w]+)/!! ) {
	$r->pnotes( "INCOM_NEW_LANG", "$1" );
	$r->pnotes( "INCOM_REDIRECT_TO", $prefix . $uri );

	$r->push_handlers( PerlHandler => \&set_lang_handler );
	$r->handler( "perl-script" );

    # incom_error magic URL should only be called as a subrequest.
    } elsif ( (!$r->main) && $uri =~ s!^incom_error/!! ) {

	$incom_root = $r->dir_config( "INCOM_ERROR_ROOT" ) || $incom_root;
	$incom_root = $r->server_root_relative( $incom_root );

	$r->push_handlers( PerlHandler => \&error_handler );
	$r->handler( "perl-script" );

    } elsif ( not ref $r->pnotes( "INCOM_SESSION" ) ) {

	# The user doesn't belong to an existing session
	$r->push_handlers( PerlHandler => \&new_session_handler );
	$r->handler( "perl-script" );
    } else {

	# Default handler
	$r->push_handlers( PerlHandler => \&default_handler );
	$r->handler( "perl-script" );
    }

    # Set the filename
    $uri ||= $index_file;

    # Handle directory index
    $uri =~ s!/$!/$index_file!;

    # Find the properly localized file
    my $localizer = $r->pnotes( "INCOM_LOCALIZER" );
    my $file = $localizer->find_localized_file( $incom_root . "/" . $uri );

    # Set filename of the request
    $r->filename(  $file  );

    # Request should never be cached
    $r->header_out( 'Pragma',	     'no-cache' );
    $r->header_out( 'Cache-control', 'no-cache' );
    $r->no_cache(1);

    # Default content-type
    $r->content_type( "text/html" );

    return OK;
}

# Content handler invoked when the request is not
# part of a session.
#
# It creates a new session.  Sets a cookie to it
# and redirect the user to resubmit the request
# to a rewritten URL.
sub new_session_handler {
    my $r = shift;

    my %session;
    eval {
	tie %session, 'Apache::iNcom::Session', undef,
	  { dbh => $r->pnotes( "INCOM_DBH"),
	    Serialize => $r->dir_config( "INCOM_SESSION_SERIALIZE_ACCESS" ),
	  };

	bake_session_cookie( $r, $session{_session_id} );
    };
    if ($@) {
	$r->log_error( "error creating session: $@" );
	return return_error( $r, SERVER_ERROR );
    }

    # Tell the browser to repost its request. We will then be
    # able to check if he has cookie turn on
    my $prefix	= $r->dir_config( "INCOM_URL_PREFIX" ) || "/";
    my $uri	= $r->uri;
    $uri =~ s!^$prefix/*!${prefix}incom_cookie_check/!;

    $r->content_type( "text/html" );
    $r->header_out( Location => $uri );

    return REDIRECT;
}

sub redirect_handler {
    my $r = shift;

    $r->content_type( "text/html" );
    $r->header_out( Location => $r->pnotes( "INCOM_REDIRECT_TO" ) );

    return REDIRECT;
}

sub set_lang_handler {
    my $r = shift;

    my $prefix	    = $r->dir_config( "INCOM_URL_PREFIX" ) || "/";
    my $session_domain  = $r->dir_config( "INCOM_SESSION_DOMAIN" );
    my $session_path    = $r->dir_config( "INCOM_SESSION_PATH" )
      || $prefix;
    my $session_expires = $r->dir_config( "INCOM_SESSION_EXPIRES" );

    # Create a cookie which has the same lifespan than
    # the session cookie.
    my $cookie = new Apache::Cookie( $r,
				     -name  => "INCOM_LANGUAGE",
				     -value => $r->pnotes( "INCOM_NEW_LANG" ),
				     -path  => $session_path,
				   );
    $cookie->domain( $session_domain )	    if $session_domain;
    $cookie->expires( $session_expires )    if $session_expires;

    # Add cookie to outgoing headers
    $cookie->bake;

    # Tell the browser to repost its request. The next
    # request will favorise the new language.
    $r->content_type( "text/html" );
    $r->header_out( Location => $r->pnotes( "INCOM_REDIRECT_TO" ) );

    return REDIRECT;
}

sub package_name {
    my $r    = shift;
    my $file = shift;

    my $host = $r->server->server_hostname;
    my $root = $r->dir_config( "INCOM_ROOT" ) || $r->document_root;
    $root = $r->server_root_relative( $root );

    # Remove document root
    $file =~ s!^$root/!!;

    # Remove trailing suffixes of the last component 
    # of the path name
    $file =~ s!\.[^/]*$!!;

    # Munge invalid character
    $file =~ tr/a-zA-Z0-9/_/cs;

    # Munge invalid character in hostname
    $host =~ tr/a-zA-Z0-9/_/cs;

    return  "Apache::iNcom::" . $host . "::" . $file;
}

sub error_handler {
    my $r = shift;

    my $filename    = $r->filename;

    unless ( -e $r->finfo ) {
	$r->log_reason( "nonexistent file", $filename );
	return NOT_FOUND;
    }

    unless ( -f _ ) {
	$r->log_reason( "not a regular file", $filename );
	return FORBIDDEN;
    }

    unless ( -r _ ) {
	$r->log_reason( "No permissions to read", $filename );
	return FORBIDDEN;
    }

    # Determine the package name of this error page
    # Package is Apache::iNcom::basename of the page
    my $package = package_name( $r, $filename );
    my $req	= new Apache::iNcom::Request( $r, $package );
    # Play magic
    $req->setup_aliases;

    # Send the response
    my $output;
    $r->content_type( "text/html" );

    my $debug = $r->dir_config( "EMBPERL_DEBUG" ) || $ENV{EMBPERL_DEBUG} || 0;
    my $options = $r->dir_config( "EMBPERL_OPTIONS" ) ||
      $ENV{EMBPERL_OPTIONS} || 16; # Default = optRawInput
    # optDisableFormData,optReturnError
    $options |= 256 | 262144;

    my $params = {
		  package   => $package,
		  output    => \$output,
		  inputfile => $filename,
		  req_rec   => $r,
		  debug	    => $debug,
		  options   => $options,
		  param	    => $r->prev->pnotes( "INCOM_HTML_EMBPERL_ERRORS" ),
		 };
    my $rc = HTML::Embperl::Execute( $params );

    $req->cleanup_aliases;

    my $dbh	= $r->pnotes( "INCOM_DBH" );
    if ($rc != OK && $rc != MOVED && $rc != REDIRECT ) {
	# If there was an error, rollback all changes
	# to the database
	eval { $dbh->rollback; };
	$r->log_error( "error reverting changes to database: $@" ) if $@;

	$r->log_reason( "error in embperl code", $filename );

	return $rc;
    } else {
	# Commit all changes to the database
	eval { $dbh->commit; };
	$r->log_error( "error commiting changes to database: $@" ) if $@;
	$r->header_out( "Content-Length", length $output );
	$r->send_http_header;

	$r->print( $output );
	return OK;
    }
}

sub default_handler {
    # Create an Apache::Request object for
    # parsing POST and GET request
    my $r = new Apache::Request( shift );

    my $filename    = $r->filename;

    unless ( -e $r->finfo ) {
	$r->log_reason( "nonexistent file", $filename );
	return return_error( $r, NOT_FOUND );
    }

    unless ( -f _ ) {
	$r->log_reason( "not a regular file", $filename );
	return return_error( $r, FORBIDDEN );
    }

    unless ( -r _ ) {
	$r->log_reason( "No permissions to read", $filename );
	return return_error( $r, FORBIDDEN );
    }

    # Read the POST data or the Query stringn
    my $status = $r->parse;
    unless ( $status == OK ) {
	$r->log_reason( "error reading request body: " .
 			$r->notes( "error-notes"), $filename);
	return return_error( $r, $status );
    }

    # Copy the elements into the fdat hash
    my %fdat = ();
    my @ffld = ();
    for my $key ( $r->param ) {
	# Discard empty fields
	my @values = grep { $_ ne "" } $r->param( $key );
	next unless @values;
	push @ffld, $key;

	# This is what is expected from HTML::Embperl
	$fdat{$key} = join "\t", @values;
    }

    # Determine the package name of this page
    # Package is Apache::iNcom::basename of the page
    my $package = package_name( $r, $filename );
    my $req	= new Apache::iNcom::Request( $r, $package );
    # Play magic
    $req->setup_aliases;

    # Send the response
    my $output;
    $r->content_type( "text/html" );

    my $debug = $r->dir_config( "EMBPERL_DEBUG" ) || $ENV{EMBPERL_DEBUG} || 0;
    my $options = $r->dir_config( "EMBPERL_OPTIONS" ) ||
      $ENV{EMBPERL_OPTIONS} || 16; # Default = optRawInput
    # optDisableFormData,optReturnError
    $options |= 256 | 262144;

    my $params = {
		  package   => $package,
		  output    => \$output,
		  inputfile => $filename,
		  req_rec   => $r,
		  errors    => [],
		  debug	    => $debug,
		  options   => $options,
		  fdat	    => \%fdat,
		  ffld	    => \@ffld,
		 };
    my $rc = HTML::Embperl::Execute( $params );

    $req->cleanup_aliases;

    my $dbh	= $r->pnotes( "INCOM_DBH" );
    if ($rc != OK && $rc != MOVED && $rc != REDIRECT ) {
	# If there was an error, rollback all changes
	# to the database
	eval { $dbh->rollback; };
	$r->log_error( "error reverting changes to database: $@" ) if $@;

	$r->log_reason( "error in embperl code", $filename );

	# Save HTML error messages for the error page
	$r->pnotes( "INCOM_HTML_EMBPERL_ERRORS", $params->{errors} );

	return return_error( $r, $rc );
    } else {
	# Commit all changes to the database
	eval { $dbh->commit; };
	$r->log_error( "error commiting changes to database: $@" ) if $@;
	$r->header_out( "Content-Length", length $output );
	$r->send_http_header;

	$r->print( $output );
	return OK;
    }
}

sub request_cleanup {
    my $r = shift;

    my $session = $r->pnotes( "INCOM_SESSION" );
    if ( $session ) {
	eval { untie %$session; };
	$r->log_error( "error untying session: $@" ) if $@;
    }

    my $dbh = $r->pnotes( "INCOM_DBH" );
    if ( $dbh ) {
	# Delete expired sessions on 5% of the requests
	if ( rand 100 < 5 ) {
	    eval {
		my $session_expires = 
		  $r->dir_config( "INCOM_SESSION_EXPIRES" );
		my $offset;
		if ( $session_expires ) {
		    $offset = offset_calc( $session_expires );
		} else {
		    $offset = 3600 * 24; # One day
		}
		# XXX Is this really portable ????
		my $time = localtime ( time - $offset);
		$dbh->do( "DELETE FROM sessions WHERE last_update < '$time'" );
		$dbh->commit;
	    };
	    $r->log_error( "error removing old sessions: $@" ) if $@;
	}

	eval {
	    $dbh->disconnect unless $dbh;
	};
	$r->log_error( "error closing connection to database: $@" ) if $@;
    }

    return OK;
}

1;
__END__

=pod

=head1 NAME

Apache::iNcom - An e-commerce framework.

=head1 SYNOPSIS

    - Configure Apache and mod_perl
    - Create databases
    - Install Apache::iNcom
    - Design your e-commerce site.
    - Wait for incomes.

=head1 DESCRIPTION

Apache::iNcom is an e-commerce framework. It is not a ready-to-run
merchant systems. It is an integration of different components needed
for e-commerce into a coherent whole.

The primary design goals of the framework are flexibility and
security. Most merchant systems will make assumptions in the way your
catalog's data, customer's data are structured or on how your order
process works. Most also imposes severe restrictions on how the user
will interface to your electronic catalog. This is precisely the kind
of constraints that Apache::iNcom was designed to avoid.

Apache::iNcom provides the following infrastructure :

    - Session Management
    - Cart Management
    - Input Validation
    - Order management
    - User management
    - << Easy >> database access
    - Internationalization
    - Error handling

Most of the base functionalities of Apache::iNcom are realized by
leveraging standard and well known modules like DBI(3) for generic SQL
database access, HTML::Embperl(3) for dynamic page generation,
Apache::Session(3) for session management, mod_perl(3) for Apache
integration and Locale::Maketext(3) for localization.

Here are its assumptions :

    - Data is in a SQL database which supports transactions.
    - Interface is in HTML.
    - Session is managed through cookies.

=head1 REQUIREMENTS

    - DBI              1.13
    - mod_perl         1.21
    - libapreq	       0.31
    - HTML::Embperl    1.2b10
    - Apache::Session  1.03   + generate_id patch
    - MIME::Base64
    - Locale::Maketext 0.17   + currency patch
    - apache	       1.3.6 or later
    - Database which supports transactions. (tested with PostgreSQL 6.5.x)

=head1 CONFIGURATION

Apache::iNcom is configured using standard the Apache directives
PerlSetVar. Activating Apache::iNcom for a particular virtual host
is a simple as

    <VirtualHost 192.168.1.1>
	PerlInitHandler Apache::iNcom
	PerlSetVar INCOM_URL_PREFIX /incom/
	PerlSetVar INCOM_ROOT	    pages
    </VirtualHost>

This will make all URL starting with C</incom/> served dynamically
by Apache::iNcom.

Additionnaly different modules used by Apache::iNcom will be
configured by profile files. Consult the appropriate module
documentation for details.

=head2 GENERAL DIRECTIVES

=over

=item INCOM_URL_PREFIX

This is the prefix that must match for the URI to be serve by
Apache::iNcom. THIS PREFIX MUST ENDS WITH A SLASH (/). To make all
files Apache::iNcom page, use / as prefix. This wouldn't work well for
images and other binary files though. Use only / as prefix, if binary
files are served by another server.

=item INCOM_ROOT

This is the path to the directory where Apache::iNcom requests will be
mapped. For example, if you have a I<INCOM_URL_PREFIX> of F</incom/>
and a I<INCOM_ROOT> of F</home/incom/site/pages>, the request
F</incom/index.html> will be mapped to
F</home/incom/site/pages/index.html>. Default is to use the server's
document root.

=item INCOM_INDEX

This is page that will be used when accessing directory. Defaults
to F<index.html>

=item INCOM_TEMPLATE_PATH

Colon separated list of directory to search when using the C<Include()>
function. (See Apache::iNcom::Request(3) for more information). Non
absolute paths are relative to the server's root.

=back

=head2 DATABASE DIRECTIVES

=over

=item INCOM_DBI_DSN

The DBI(3) URL to use to open a database connection.

=item INCOM_DBI_USER

Username to use for the database connection.

=item INCOM_DBI_PASSWD

Password to use for the database connection.

=item INCOM_DBI_TRACE

Sets the tracing level for the connection.

=item INCOM_DBI_LOG

File where the DBI(3) trace output will go.

=item INCOM_SEARCH_PROFILE

DBIx::SearchProfiles(3) profile file that will be used to configure
the $DB object accessible in Apache:iNcom pages. If non-absolute, it
is relative to the server's root. Defaults to
F<conf/search_profiles.pl> relative to the server's root.

See DBIx::SearchProfiles(3) for details on the format of this file.

To turn off the use of the search profiles set this directive to
C<NONE>.

=back

=head2 PROFILES DIRECTIVES

=over

=item INCOM_INPUT_PROFILE

Sets the input profile that will be used to initialize the $Validator
object. Defaults to F<conf/input_profiles.pl> relative to server's
root.

See HTML::FormValidator(3) for details on the format of this file.

To turn off the creation of an input profile set this directive to
C<NONE>.

=item INCOM_PRICING_PROFILE

Sets the pricing profile that will be used to initialize the $Cart
object. Defaults to F<conf/pricing_profile.pl> relative to server's
root.

See Apache::iNcom::CartManager(3) for details on the format of this file.

If you don't need the cart management feature, set this directive to
C<NONE>.


=item INCOM_ORDER_PROFILE

Sets the order profiles file that will be used to initialize the
$Order object. Defaults to F<conf/order_profiles.pl> relative to server's
root.

See Apache::iNcom::OrderManager(3) for details on the format of this file.

If you don't need this feature, you can set this directive to C<NONE>.

=back

=head2 USERDB DIRECTIVES

=over

=item INCOM_USERDB_PROFILE

Name of the profile to use for the user database. Defaults to
C<userdb>. See DBIx::UserDB(3) for more information. To disable the
use of a DBIx::UserDB object, sets this directives to C<NONE>.

=item INCOM_GROUPDB_PROFILE

Name of the profile to use for the group database access. Defaults to
C<groupdb>. See DBIx::UserDB(3) for more information.

=item INCOM_SCRAMBLE_PASSWORD

Turn on or off scrambling of user's password in the UserDB.

=back


=head2 LOCALIZATION DIRECTIVES

=over

=item INCOM_DEFAULT_LANGUAGE

The language of the files without a language extension. Defaults to C<en>.

=item INCOM_LOCALE

The package uses to create Locale::Maketext(3) instance. If this is
set, an instance appropriate for the user's locale will be available
through the $Locale object.

=back


=head2 SESSION DIRECTIVES

=over

=item INCOM_SESSION_SERIALIZE_ACCESS

Set this to 1 to serialize access through session. This will make sure
that only one session's request is processed at a time. You should set
this to 1 if your site uses frameset.

=item INCOM_SESSION_SECURE

Sets this to true if you want the cookie that contains the session id
to be only transmitted over SSL connections. Be aware that setting
this variable to true will require that all Apache::iNcom transactions
be conducted over SSL.

=item INCOM_SESSION_DOMAIN

The domain to which the Apache::iNcom session's cookie will be
transmitted. You can use this, if you are using a server farm for
example.

=item INCOM_SESSION_PATH

The path under which the session id is valid. Defaults to
I<INCOM_URL_PREFIX>.

=item INCOM_SESSION_EXPIRES

The time for which the use session is valid. Defaults is for a browser
session. (Once the user exists its browser session will become
invalid).

=back

=head2 ERROR HANDLING DIRECTIVES

=over

=item INCOM_ERROR_PROFILE

The error profile that will be used for displaying server error.

=item INCOM_ERROR_ROOT

The directory which contains error pages. If a non absolute path
is specified, it is relative to the server's root.

=back

=head1 SESSION HANDLING

On the user's first request, a new session is created. Each and every
other request will be part of a session which will used to track the
user's cart and other such things.

The session id is returned to the user in a cookie. COOKIES MUST BE
ENABLED for Apache::iNcom to function. Fortunately, Apache::iNcom
detects if the user has cookies turned off and will send the user an
error.

Cookies are used for security and confidentiality. The session id is a
truly random 128bits number, which is make it very much unguessable.
That means that you can't try to stomp into another user's session.
That is a good thing since having access to the session id means
having access to a whole bunch of informations. (What information is
application specific.) IP address aren't used to restrict the session
access because of the various problems with proxies and other Internet
niceties.

Now, what has this to do with cookies ? Well, using URL rewriting was
originally considered, but then two big issues cralwed in : proxies
and the Referer header. Having the session id embedded in the URL
means that our precious session id will be stored in various log files
across multiple server (web server, proxy server, etc) This is a bad
thing. Also, must request contains a Referer header which means that
the session id is likely to leak to third party sites which are linked
from your site (or not, Netscape used to send the header even if the
user only typed in the new URL while viewing your page). This is
another bad thing, and this is why we are using cookies.


=head1 APACHE::INCOM PAGES

Apache::iNcom pages are HTML::Embperl pages with some extra variables
and functions available. See Apache::iNcom::Request(3) for details.
You may also which to consult the HTML::Embperl documentation for
syntax. Additionnaly, the normal $req_rec object in the page is an
instance of Apache::Request(3) so that you can handle multipart
upload.

=head1 DATABASE CONNECTIVITY

The database connection is opened once per request and shared by
all modules that must use it. Database access is mediated through
the use of the DBIx::SearchProfiles(3) module. 

Connections are opened in commit on request mode. The database
connection is commit after the page is executed. If an error occurs,
the transaction will be rolled back. The application may elect to
commit part of the transaction earlier.

=head1 CART MANAGEMENT

See Apache::iNcom::CartManager(3) for details.

=head1 ORDER MANAGEMENT

See Apache::iNcom::OrderManager(3) for details.

=head1 USER MANAGEMENT

User management is handled through the DBIx::UserDB(3) module.

=head1 LOCALIZATION

Apache::iNcom is designed to make it easy to adapt your e-commerce
application to multiple locale.

The framework uses Locale::Maketext(3) for message formatting.

All pages may have a localized version available. The localized should
have an extension describing its language. (.en for English, .fr for
French, .de for German, etc.)

The user locale will
be negotiated through the Accep-Language header which is part of the
HTTP protocol. It can also be set explicitely by sending the user to
a special link (since not many users took the time to configure their
browser for language negotiation).

The URL :

    I<INCOM_URL_PREFIX>/incom_set_lang/I<LANG>

This will set the language to use in the user's session.

=head1 SECURITY

Apache::iNcom has been with security has one of its primary design goal.

=over

=item 1

Session ID are 128bits truly random number.

=item 2

Session ID are transmitted only by cookies to assure confidentiality.

=item 3

There are no user transmitted magic variables. Form data doesn't act upon
the framework. All actions are triggered by the application and not the
user. All form data that should be used for action are determined by the
application through the various profiles. This means that you won't be
burned by a magic feature that sprung without you knowing it.

=item 4

Regular access control of Apache can be used. Also see the ACLs
mechanism offered by the DBIx::UserDB(3) for access control with finer
resolution than URL or file based.

=item 5

SSL can (and should) be used to assure confidentiality.

=item 6

Executable content (pages) that shouldn't be directly accessible from
the user (include file, error pages, etc) can be kept in separate
directory which aren't accessible directly.

=back

The major (current) security limitations is that the application
programmer is trusted. Apache::iNcom pages have complete control over
the Apache server environment in which they run. Keep this in mind
when running multiple sites. Future version will use the Safe(3) module
to improve on this.

=head1 MULTIPLE CATALOGS

Multiple e-commerce sites can easily be run by using the VirtualHost
capability of apache.

=head1 PERFORMANCE AND SCALABILITY

No state is kept between requests which makes it easy to scale the
load on Apache::iNcom across multiple server.

mod_perl general tips for improving performance should be applied. See
the mod_perl guide for details (http://perl.apache.org/guide/).

=head1 ERROR HANDLING

Error are handled in a way similar to the ErrorDocument functionality.
The error profile is an file which should C<eval> to an hash
reference. Keys are error number and values are the file that should
be returned on error. The pages are assumed to be relative to the
I<INCOM_ERROR_ROOT> directory, or if unspecified the I<INCOM_ROOT>.

If a localized version of the page exists, that one will be use. The
page will be executed as a normal Apache::iNcom pages. Error are keyed
either by the HTTP response code (404,403,500, etc) or by an arbitrary
key for application specific error. In order to return an arbitrary
error, you set the pnote I<INCOM_ERROR> in the page before returning
an error.

    Example: $req_rec->pnotes( "INCOM_ERROR", "validation_failed" );
	     die "validation_failed";

The page linked to the "validation_failed" key in the error profile
will be used.

The "no_cookies" key is used to find the error page to return in case
the user has turned off cookies.

In the case of an error handler trigerred by an error in an HTML::Embperl
page. The error page will received in the @param array the error messages
emitted by HTML::Embperl.

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

Apache::iNcom::Request(3) Apache::iNcom::CartManager(3)
Apache::iNcom::OrderManager(3) DBIx::SearchProfiles(3) DBIx::UserDB(3)
Locale::Maketext(3) HTML::Embperl

=cut



