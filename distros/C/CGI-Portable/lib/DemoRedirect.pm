=head1 NAME

DemoRedirect - Demo of CGI::Portable sending a redirection header.

=cut

######################################################################

package DemoRedirect;
require 5.004;

# Copyright (c) 1999-2004, Darren R. Duncan.  All rights reserved.  This module
# is free software; you can redistribute it and/or modify it under the same terms
# as Perl itself.  However, I do request that this copyright information and
# credits remain attached to the file.  If you modify this module and
# redistribute a changed version then please attach a note listing the
# modifications.  This module is available "as-is" and the author can not be held
# accountable for any problems resulting from its use.

use strict;
use warnings;
use vars qw($VERSION @ISA);
$VERSION = '0.50';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	CGI::Portable 0.50
	CGI::Portable::AppStatic 0.50

=cut

######################################################################

use CGI::Portable 0.50;
use CGI::Portable::AppStatic 0.50;
@ISA = qw(CGI::Portable::AppStatic);

######################################################################

=head1 SYNOPSIS

=head2 Redirect To A Custom Url In User Query Parameter 'url'

	#!/usr/bin/perl
	use strict;
	use warnings;

	require CGI::Portable;
	my $globals = CGI::Portable->new();

	require CGI::Portable::AdapterCGI;
	my $io = CGI::Portable::AdapterCGI->new();
	$io->fetch_user_input( $globals );

	my %CONFIG = ();

	$globals->set_prefs( \%CONFIG );
	$globals->call_component( 'DemoRedirect' );

	$io->send_user_output( $globals );

	1;

=head1 DESCRIPTION

This Perl 5 object class is part of a demonstration of CGI::Portable in use.  
It is one of a set of "application components" that takes its settings and user 
input through CGI::Portable and uses that class to send its user output.  
This demo module set can be used together to implement a web site complete with 
static html pages, e-mail forms, guest books, segmented text document display, 
usage tracking, and url-forwarding.  Of course, true to the intent of 
CGI::Portable, each of the modules in this demo set can be used independantly 
of the others.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 PUBLIC FUNCTIONS AND METHODS

=head2 main( GLOBALS )

You invoke this method to run the application component that is encapsulated by 
this class.  The required argument GLOBALS is an CGI::Portable object that 
you have previously configured to hold the instance settings and user input for 
this class.  When this method returns then the encapsulated application will 
have finished and you can get its user output from the CGI::Portable object.

=head1 PREFERENCES HANDLED BY THIS MODULE

I<There are no preferences.  Just set the query parameter named "url" to the 
destination that you want the script to forward you to.  However, this module 
does subclass CGI::Portable::AppStatic, so you can optionally set the 
high_http_status_code and high_http_window_target preferences that it handles.>

=cut

######################################################################

# Names of properties for objects of parent class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Constant values used by this class:
my $UIPN_DEST_URL = 'url';  # look in the user query for destination

######################################################################

sub main {
	my ($class, $globals) = @_;
	my $self = bless( {}, ref($class) || $class );

	UNIVERSAL::isa( $globals, 'CGI::Portable' ) or 
		die "initializer is not a valid CGI::Portable object";

	$self->set_static_low_replace( $globals );

	$self->{$KEY_SITE_GLOBALS} = $globals;
	$self->main_dispatch();

	$self->set_static_high_replace( $globals );
	$self->set_static_attach_unordered( $globals );
	$self->set_static_attach_ordered( $globals );
	$self->set_static_search_and_replace( $globals );
}

######################################################################

sub main_dispatch {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $dest_url = $globals->user_query_param( $UIPN_DEST_URL );
	
	unless( $dest_url ) {
		$globals->page_title( 'No Url Provided' );

		$globals->set_page_body( <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>I'm sorry, but this redirection page requires a query parameter named 
"$UIPN_DEST_URL", whose value is an url.  No url was provided, so I 
can't redirect you to it.  If you got this error while clicking 
on one of the links on this website, then the problem is likely 
on this end.  In the latter case...</p>

@{[$self->get_amendment_message()]}
__endquote

		return( 1 );
	}

	$globals->http_status_code( '301 Moved' );
	$globals->http_redirect_url( $dest_url );
}

######################################################################

sub get_amendment_message {
	my ($self) = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	return( <<__endquote );
<p>This should be temporary, the result of a transient server problem or an 
update being performed at the moment.  Click @{[$globals->recall_html('here')]} 
to automatically try again.  If the problem persists, please try again later, 
or send an @{[$globals->maintainer_email_html('e-mail')]} message about the 
problem, so it can be fixed.</p>
__endquote
}

######################################################################

1;
__END__

=head1 AUTHOR

Copyright (c) 1999-2004, Darren R. Duncan.  All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.  However, I do request that this copyright information and
credits remain attached to the file.  If you modify this module and
redistribute a changed version then please attach a note listing the
modifications.  This module is available "as-is" and the author can not be held
accountable for any problems resulting from its use.

I am always interested in knowing how my work helps others, so if you put this
module to use in any of your own products or services then I would appreciate
(but not require) it if you send me the website url for said product or
service, so I know who you are.  Also, if you make non-proprietary changes to
the module because it doesn't work the way you need, and you are willing to
make these freely available, then please send me a copy so that I can roll
desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 SEE ALSO

perl(1), CGI::Portable, CGI::Portable::AppStatic, CGI::Portable::AdapterCGI.

=cut
