=head1 NAME

CGI::Portable::AppStatic - Define whole response screens within a config file

=cut

######################################################################

package CGI::Portable::AppStatic;
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
use vars qw($VERSION);
$VERSION = '0.50';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	CGI::Portable 0.50

=cut

######################################################################

use CGI::Portable 0.50;

######################################################################

=head1 SYNOPSIS

=head2 Simple program that returns a static HTML page:

	#!/usr/bin/perl
	use strict;
	use warnings;

	require CGI::Portable;
	my $globals = CGI::Portable->new();

	my %CONFIG = (
		high_http_status_code => '200 OK',
		high_http_content_type => 'text/html',
		high_page_title => 'Simple AppStatic Demo',
		high_page_author => 'Darren Duncan',
		high_page_meta => { 
			keywords => 'HTTP, HTML, Perl, Static', 
		},
		high_page_style_code => [
			'body {background-color: white; background-image: none}', 
			'h1, h2 {text-align: center}', 
			'td {text-align: left; vertical-align: top}',
		],
		high_page_body => __endquote,
	<h1>Simple AppStatic Demo</h1>
	<p>This page is a trivial example of what can be done with CGI::Portable 
	when you want your script to always return the same screen.  It is more 
	common, however, that your script would contain many screens of which some 
	are dynamic and some are static.</p>
	<h2>Oh, A Table!</h2>
	<table><tr>
	<td>Question:</td><td>Answer!</td>
	</tr><tr>
	<td>Another Question:</td>
	<td>This is a really really long answer.  It just keeps going on and on and 
	on and on and on and on and on and on and on.  However, the short question 
	should stay top aligned with the long answer due to the stylesheet.</td>
	</tr></table>
	__endquote
	);

	$globals->set_prefs( \%CONFIG );
	$globals->call_component( 'CGI::Portable::AppStatic' );

	require CGI::Portable::AdapterCGI;
	my $io = CGI::Portable::AdapterCGI->new();
	$io->send_user_output( $globals );

	1;

=head2 Simple program that returns an HTTP redirection header:

	my %CONFIG = (
		high_http_status_code => '301 Moved',
		high_http_window_target => 'nyx_demo_file_window', 
		high_http_redirect_url => 'http://www.nyxmydomain.net/dir/file.html',
	);

=head2 Simple program that returns a bit of binary data:

	my %CONFIG = (
		high_http_status_code => '200 OK',
		high_http_content_type => 'application/xxxencoded',
		high_http_body => pack( 'H8', '5065726c' ),
		high_http_body_is_binary => 1,
	);

=head1 DESCRIPTION

This Perl 5 object class is a simple encapsulated application, or "component", 
that runs in the CGI::Portable environment.  It allows you to define a complete 
static "program response screen" within the standard "preferences" config file 
without having to write your own "application" to do it.  Or, to be specific, 
this module allows you to set any CGI::Portable 'Response' properties by 
providing a like-named "preference" with each new value, rather than having to 
explicitely call each appropriate accessor method.  This module is designed to be
easily subclassed by your own application components, so they can do the same 
things while you only need to program the interesting dynamic functionality.  
An example scenario has users of your subclassed application using AppStatic 
methods to apply a common header or footer or stylesheet to every screen.

=cut

######################################################################

# Constant values used by this class:

# root property/preference names applied as "low/high" scalars:
my @SCALAR_PREFS = qw( 
	http_status_code http_window_target http_content_type
	http_redirect_url http_body http_body_is_binary
	page_prologue page_title page_author
);

# root property/preference names applied as "low/high" list refs:
my @PREFS_TO_SET = qw( 
	http_cookies http_headers page_meta page_style_sources 
	page_style_code page_head page_frameset_attributes 
	page_frameset page_body_attributes page_body 
);

# root property/preference names applied as "add" list refs:
my @PREFS_TO_ADD = qw( 
	http_cookies http_headers page_meta page_style_sources page_style_code 
	page_frameset_attributes page_body_attributes 
);

# root property/preference names applied as "append/prepend" list refs:
my @PREFS_TO_PEND = qw( 
	page_head page_frameset page_body 
);

######################################################################

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>.

This class does not have any of its own stored properties, so there is no risk 
of property namespace collisions with subclasses.  Instead, you must provide the 
CGI::Portable object to each method explicitely as its first argument.

=head1 THE ONLY PUBLIC METHOD

=head2 main( GLOBALS )

You invoke this method to run the application component that is encapsulated by 
this class.  The required argument GLOBALS is an CGI::Portable object that 
you have previously configured to hold the instance settings and user input for 
this class.  When this method returns then the encapsulated application will 
have finished and you can get its user output from the CGI::Portable object.

This method is simple and intended to be overriden by subclasses.  All it does 
by itself is invoke the private methods listed under PRIVATE METHODS FOR USE BY 
SUBCLASSES, which do the actual work.

=cut

######################################################################

sub main {
	my ($class, $globals) = @_;
	my $self = bless( {}, ref($class) || $class );

	UNIVERSAL::isa( $globals, 'CGI::Portable' ) or 
		die "initializer is not a valid CGI::Portable object";

	$self->set_static_low_replace( $globals );
	$self->set_static_high_replace( $globals );
	$self->set_static_attach_unordered( $globals );
	$self->set_static_attach_ordered( $globals );
	$self->set_static_search_and_replace( $globals );
}

######################################################################

=head1 PREFERENCES HANDLED BY THIS MODULE

These preferences have names that are the same as the CGI::Portable 'Response'
properties that their values are being used to set, except that each has a prefix
indicating how the value is set.  The prefixes used include any of the following,
where they make sense for each property: "low", "high", "add", "append",
"prepend".  Preferences are used only if they have a defined value.

The first two prefixes are valid with all scalar and list properties; "low"
priority values are applied as early as possible, and will be lost if the
subclassed application decides to set the same properties; "high" priority values
are assigned after the "main program" does its work, and will overwrite any same
properties that the "main program" sets.

The latter three prefixes only make sense with non-scalar or "list" properties
where each property can store multiple values; they are all applied as late as
possible, and try to preserve existing property values while adding their own. 
The "append" and "prepend" prefixes are only used where the order of the property
elements is important, such as in the "page body".  The "add" prefix is only used
where the order is not preserved, such as with the "page meta" tags.

The page_search_and_replace preference is different, having no prefixes, and is 
applied after all of the other preferences.

This module assumes that the CGI::Portable object passed to it did not have any
of its output properties set prior to main() being called, so even the "low"
priority preferences will overwrite any pre-existing same properties.  To avoid
unpleasantries it is a good idea for calling modules to apply all of their own
output after called modules have finished, or to employ make_new_context() and
related functionality.

=head2 These preferences are for generic HTTP responses:

	low_http_status_code - string
	low_http_window_target - string
	low_http_content_type - string
	low_http_redirect_url - string
	low_http_cookies - array of encoded cookie strings
	low_http_headers - hash of header names and values
	low_http_body - string
	low_http_body_is_binary - boolean

	high_http_status_code - string
	high_http_window_target - string
	high_http_content_type - string
	high_http_redirect_url - string
	high_http_cookies - array of encoded cookie strings
	high_http_headers - hash of header names and values
	high_http_body - string
	high_http_body_is_binary - boolean

	add_http_cookies - array of encoded cookie strings
	add_http_headers - hash of header names and values

=head2 These preferences are specifically for HTML pages:

	low_page_prologue - string (override the DOCTYPE tag)
	low_page_title - string
	low_page_author - string
	low_page_meta - hash of meta-tag names and values
	low_page_style_sources - array of strings (urls)
	low_page_style_code - array of strings (raw code)
	low_page_head - array
	low_page_frameset_attributes - hash
	low_page_frameset - array of hashes (each hash is attributes for new FRAME tag)
	low_page_body_attributes - hash
	low_page_body - array

	high_page_prologue - string (override the DOCTYPE tag)
	high_page_title - string
	high_page_author - string
	high_page_meta - hash of meta-tag names and values
	high_page_style_sources - array of strings (urls)
	high_page_style_code - array of strings (raw code)
	high_page_head - array
	high_page_frameset_attributes - hash
	high_page_frameset - array of hashes (each hash is attributes for new FRAME tag)
	high_page_body_attributes - hash
	high_page_body - array

	add_page_meta - hash of meta-tag names and values
	add_page_style_sources - array of strings (urls)
	add_page_style_code - array of strings (raw code)
	add_page_frameset_attributes - hash
	add_page_body_attributes - hash

	prepend_page_head - array
	prepend_page_frameset - array of hashes (each hash is attributes for new FRAME tag)
	prepend_page_body - array

	append_page_head - array
	append_page_frameset - array of hashes (each hash is attributes for new FRAME tag)
	append_page_body - array

	page_search_and_replace - hash (keys are tokens to search for; values replace)

=head1 PRIVATE METHODS FOR USE BY SUBCLASSES

=head2 set_static_low_replace( GLOBALS )

This method will apply all of the "low" priority preferences, which replace 
any respective properties.

=cut

######################################################################

sub set_static_low_replace {
	my ($self, $globals) = @_;
	my $rh_prefs = $globals->get_prefs_ref();
	foreach my $base (@SCALAR_PREFS) {
		if( defined( $rh_prefs->{"low_$base"} ) ) {
			eval "\$globals->$base( \$rh_prefs->{low_$base} );";
			$@ and die;
		}
	}
	foreach my $base (@PREFS_TO_SET) {
		if( defined( $rh_prefs->{"low_$base"} ) ) {
			eval "\$globals->set_$base( \$rh_prefs->{low_$base} );";
			$@ and die;
		}
	}
}

######################################################################

=head2 set_static_high_replace( GLOBALS )

This method will apply all of the "high" priority preferences, which replace 
any respective properties.

=cut

######################################################################

sub set_static_high_replace {
	my ($self, $globals) = @_;
	my $rh_prefs = $globals->get_prefs_ref();
	foreach my $base (@SCALAR_PREFS) {
		if( defined( $rh_prefs->{"high_$base"} ) ) {
			eval "\$globals->$base( \$rh_prefs->{high_$base} );";
			$@ and die;
		}
	}
	foreach my $base (@PREFS_TO_SET) {
		if( defined( $rh_prefs->{"high_$base"} ) ) {
			eval "\$globals->set_$base( \$rh_prefs->{high_$base} );";
			$@ and die;
		}
	}
}

######################################################################

=head2 set_static_attach_unordered( GLOBALS )

This method will apply all of the "add" preferences, which try to add values to 
any respective properties without deleting previous values.  Previous values 
are only deleted where the properties are hashes and new hash keys are the same 
as existing ones; different keys do not conflict.

=cut

######################################################################

sub set_static_attach_unordered {
	my ($self, $globals) = @_;
	my $rh_prefs = $globals->get_prefs_ref();
	foreach my $base (@PREFS_TO_ADD) {
		if( defined( $rh_prefs->{"add_$base"} ) ) {
			eval "\$globals->add_$base( \$rh_prefs->{add_$base} );";
			$@ and die;
		}
	}
}

######################################################################

=head2 set_static_attach_ordered( GLOBALS )

This method will apply all of the "append" and "prepend" preferences, which will 
always add to their respective properties without deleting previous values.

=cut

######################################################################

sub set_static_attach_ordered {
	my ($self, $globals) = @_;
	my $rh_prefs = $globals->get_prefs_ref();
	foreach my $base (@PREFS_TO_PEND) {
		if( defined( $rh_prefs->{"append_$base"} ) ) {
			eval "\$globals->append_$base( \$rh_prefs->{append_$base} );";
			$@ and die;
		}
	}
	foreach my $base (@PREFS_TO_PEND) {
		if( defined( $rh_prefs->{"prepend_$base"} ) ) {
			eval "\$globals->prepend_$base( \$rh_prefs->{prepend_$base} );";
			$@ and die;
		}
	}
}

######################################################################

=head2 set_static_search_and_replace( GLOBALS )

This method will apply the page_search_and_replace preference, and should be 
run later than all of the other methods, to affect their results also.

=cut

######################################################################

sub set_static_search_and_replace {
	my ($self, $globals) = @_;
	$globals->page_search_and_replace( 
		$globals->pref( 'page_search_and_replace' ) );
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

perl(1), CGI::Portable.

=cut
