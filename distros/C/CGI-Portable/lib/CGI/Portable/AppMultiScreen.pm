=head1 NAME

CGI::Portable::AppMultiScreen - Delegate construction, navigation of hierarchical screens

=cut

######################################################################

package CGI::Portable::AppMultiScreen;
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
	CGI::Portable::AppStatic 0.50 (a superclass)

=cut

######################################################################

use CGI::Portable 0.50;
use CGI::Portable::AppStatic 0.50;
@ISA = qw( CGI::Portable::AppStatic );

######################################################################

=head1 SYNOPSIS

=head2 Simple program with multiple screens from different modules:

	#!/usr/bin/perl
	use strict;
	use warnings;

	require CGI::Portable;
	my $globals = CGI::Portable->new();

	use Cwd;
	$globals->file_path_root( cwd() );  # let us default to current working dir
	$globals->file_path_delimiter( $^O=~/Mac/i ? ":" : $^O=~/Win/i ? "\\" : "/" );

	require CGI::Portable::AdapterCGI;
	my $io = CGI::Portable::AdapterCGI->new();
	$io->fetch_user_input( $globals );

	$globals->default_application_title( 'Demo Application' );
	$globals->default_maintainer_name( 'Tony Simons' );
	$globals->default_maintainer_email_address( 'tony@aardvark.net' );

	$globals->current_user_path_level( 1 );
	$globals->set_prefs( 'myconfig.pl' );
	$globals->call_component( 'CGI::Portable::AppMultiScreen' );

	$io->send_user_output( $globals );

	1;

=head2 Content of file 'myconfig.pl' telling program what to do:

I<This is not a whole example, but you can get an idea what to substitute.  
This example shows 5 screens handled by 5 module instances, most of 
which has their own preferences and optional subdirectory for files.>

	my $rh_preferences = { 
		delegate_list => {
			pg_one => {
				file_subdir => 'statics',
				preferences => { filename => 'welcome.html' },
				module_name => 'other::module::textfile',
			},
			pg_two => {
				file_subdir => 'content',
				preferences => 'content_config.pl',
				module_name => 'other::module::content',
			},
			pg_three => {
				file_subdir => 'indexes',
				preferences => { key1 => 'value1', key2 => 'value2' },
				module_name => 'other::module::search',
			},
			pg_four => {
				file_subdir => 'statics',
				preferences => { filename => 'help.html' },
				module_name => 'other::module::textfile',
			},
		},
		default_delegate => 'pg_one',
		unknown_delegate => {
			file_subdir => undef,
			preferences => {},
			module_name => 'other::module::error',
		},
	};

=head1 DESCRIPTION

This Perl 5 object class is a simple encapsulated application, or "component",
that runs in the CGI::Portable environment.  It allows you to easily define a
group of screens that are related, delegate the construction of each screen to
separate "components", and simplify the creation of links between the screens.
When screens are related hierarchically according to the possible values of the
"user path", this class will evaluate the "current user path element" and compare
it to the valid options you specify, in order to resolve exactly which screen the
user requested.  You define what options are available at the current hierarchy
node or branch within the standard "preferences", or specifically in the
"delegate_list" hash preference; each key/value pair has a user path segment to
match and instructions for how to build that chosen node or screen.  Each hash
value says what delegate module to call and what its preferences are.  If the
option leads to another branch then the called module could be another
AppMultiScreen instance; these can be chained as far as you want.  This class is
subclassed from CGI::Portable::AppStatic, which is convenient if you want to do
simple post-processing of your new screen using its preferences.  This module is
designed to be easily subclassed by your own application components, should you
wish to extend or customize its functionality.

=cut

######################################################################

# Constant values used by this class:

# Keys for items in site page preferences:
my $PKEY_DELEGATE_LIST = 'delegate_list';
my $PKEY_DEFAULT_DELEGATE = 'default_delegate';
my $PKEY_UNKNOWN_DELEGATE = 'unknown_delegate';

# Keys for elements in $PKEY_DELEGATE_LIST hash:
my $DKEY_FILE_SUBDIR = 'file_subdir';
my $DKEY_PREFERENCES = 'preferences';
my $DKEY_MODULE_NAME = 'module_name';

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
SUBCLASSES, and equivalents in CGI::Portable::Static, which do the actual work.

=cut

######################################################################

sub main {
	my ($class, $globals) = @_;
	my $self = bless( {}, ref($class) || $class );

	UNIVERSAL::isa( $globals, 'CGI::Portable' ) or 
		die "initializer is not a valid CGI::Portable object";

	$self->set_static_low_replace( $globals );

	$self->set_multi_screen_navigate_delegate_list( $globals );

	$self->set_static_high_replace( $globals );
	$self->set_static_attach_unordered( $globals );
	$self->set_static_attach_ordered( $globals );
	$self->set_static_search_and_replace( $globals );
}

######################################################################

=head1 PREFERENCES HANDLED BY THIS MODULE

This module is a subclass of CGI::Portable::AppStatic and will handle all of 
that module's preferences in addition to the new ones discussed below.

The preferences specifically for CGI::Portable::AppMultiScreen allow you to 
define a list of other modules which are to be called under certain circumstances 
to construct a result screen.  AppMultiScreen doesn't normally do any screen 
construction by itself, but instead handles the conditional logic required to 
pick one module from the list and call it.  The key preference that you need to 
set is "delegate_list", but you can optionally set "default_delegate" and 
"unknown_delegate" as well.  See the SYNOPSIS for the format of each preference.

=head2 delegate_list

This hash-ref preference is a lookup table which matches the "current user path 
element" with an "application component" module instance that will handle the 
screen or hierarchy of screens associated with the currently resolved user path.  
The keys in the hash are scalars that match a user path element, and associated 
values are hash-refs that say what other module to call and what its config 
preferences are.  A key can only match if the associated value is a hash-ref.

Each of these latter hash-refs must have values for at least these two keys set:
"module_name" and "preferences".  Each can optionally have this one key set:
"file_subdir".  The value for "module_name" is a scalar having the name of the
Perl 5 module to invoke as an "application component" that will make the new
result screen.  The value for "preferences" can be either a hash-ref having
literal preferences for the invoked module, or a scalar having a filename of a
Perl file that can be executed to return the same preferences hash ref; it must
be an empty hash ref if the module takes no preferences.  The value for
"file_subdir" is a relative file system path within which the invoked module
should look for its files (or config file) if any; if this value is not set then
the current file directory is used instead.

Delegated modules operate within a new "context" created by the current
CGI::Portable object's make_new_context() method.  Within that context,
AppMultiScreen does the following: 1. call inc_user_path_level() so that the
delegated module sees a different "current user path element" than this one does;
2. call navigate_url_path() with the "current user path element" as its argument
so that any self-referencing urls generated by the delegated module are correct
for the current screen; 3. call navigate_file_path() with the "file_subdir" value
as its argument; 4. call set_prefs() with the "preferences" value as its
argument; 5. call call_component() with the "module_name" value as its argument. 
Finally, the output held by the inner context is saved using the current
CGI::Portable object's take_context_output() method.

=head2 default_delegate

This optional scalar preference is a default value for the "current user path
element" that will be used when processing "delegate_list" in situations where
the existing "current user path element" is not defined or false.  The
functionality of this is similar to how web browsers look for specific filenames
like "index.html" when the user didn't specify a file name inside a directory.  
If this preference is not set then it is unlikely that any screen would match the
user's request.

=head2 unknown_delegate

This optional hash-ref preference lets you customize the response screen that 
the user will get if they provide a "current user path element" that does not 
match any keys in the "delegate_list" lookup table.  The functionality of this 
is similar to how web browsers produce a "404 Page Not Found" message when the 
user specifies a file or directory name that doesn't exist.  This preference is 
formatted the name way as a value in "delegate_list", so it requires the same 
"module_name" and "preferences" settings to work properly.  If this preference 
is not set then AppMultiScreen will generate a default error screen instead.

=head1 PRIVATE METHODS FOR USE BY SUBCLASSES

=head2 set_multi_screen_navigate_delegate_list( GLOBALS )

This method will resolve the "current user path element" towards a screen some
how, using the [delegate_list, default_delegate, unknown_delegate] preferences to
decide how that is done.  If a preferences-defined screen is resolved to, whether
a normal or an error screen, then this method calls the
set_multi_screen_dispatch_one_delegate() method to handle the details of invoking
the delegate module, including any context-related matters.  Otherwise, this
method calls the set_multi_screen_no_delegate_message() method which produces a
default error screen instead.

=cut

######################################################################

sub set_multi_screen_navigate_delegate_list {
	my ($self, $globals) = @_;
	my $rh_prefs = $globals->get_prefs_ref();

	my $user_path_element = $globals->current_user_path_element();
	$user_path_element ||= $rh_prefs->{$PKEY_DEFAULT_DELEGATE};

	my $delegate = $rh_prefs->{$PKEY_DELEGATE_LIST}->{$user_path_element};

	unless( ref( $delegate ) eq 'HASH' ) {
		$delegate = $rh_prefs->{$PKEY_UNKNOWN_DELEGATE};
	}

	if( ref( $delegate ) eq 'HASH' ) {
		$self->set_multi_screen_dispatch_one_delegate( 
			$globals, $delegate, $user_path_element );

	} else {
		$self->set_multi_screen_no_delegate_message( $globals );
	}
}

######################################################################

=head2 set_multi_screen_dispatch_one_delegate( GLOBALS, DELEGATE, USER_PATH )

This method will use its DELEGATE argument to construct a new screen and store it
in the GLOBALS context argument.  DELEGATE is a hash ref whose values describe
how the new screen is to be made.  It's properties are described by the
delegate_list preference documentation, above, as DELEGATE can be set as an
element in the delegate_list lookup table; it may also have been set from the
unknown_delegate preference.  This method uses its USER_PATH argument as an
argument for navigate_url_path() rather than taking the "current user path
element" from GLOBALS because the latter may be empty, meaning that USER_PATH
would have the default value.  This method returns without doing anything if
DELEGATE is not a valid hash ref.

=cut

######################################################################

sub set_multi_screen_dispatch_one_delegate {
	my ($self, $globals, $delegate, $user_path_element) = @_;
	ref( $delegate ) eq 'HASH' or return( 0 );
	my $inner_context = $globals->make_new_context();
	$inner_context->inc_user_path_level();
	$inner_context->navigate_url_path( $user_path_element );
	$inner_context->navigate_file_path( $delegate->{$DKEY_FILE_SUBDIR} );
	$inner_context->set_prefs( $delegate->{$DKEY_PREFERENCES} );
	$inner_context->call_component( $delegate->{$DKEY_MODULE_NAME} );
	$globals->take_context_output( $inner_context );
}

######################################################################

=head2 set_multi_screen_no_delegate_message( GLOBALS )

This method produces a default error screen to use if the user requested a 
screen not defined in the "delegate_list" preference, and the "unknown_delegate" 
preference is not set.  This default screen has some resemblence to the error 
screen that CGI::Portable's call_component() method produces when it fails, 
except that the other message is for a program error while this method's screen 
is for a user error.  It says '404 Page Not Found'.  Since this method assumes 
a user error, CGI::Portable's error list is not supplemented.

=cut

######################################################################

sub set_multi_screen_no_delegate_message {
	my ($self, $globals) = @_;

	$globals->http_status_code( '404 Not Found' );

	$globals->page_title( '404 Page Not Found' );

	$globals->set_page_body( <<__endquote );
<h1>@{[$globals->page_title()]}</h1>

<p>I'm sorry, but the screen you requested, "@{[$globals->user_path_string()]}", 
doesn't seem to exist.  If you manually typed that address into your browser, 
then it is either out-dated or you mis-spelled it.  If you got this error from 
clicking a navigation link on another screen, then the problem is likely at this 
end.  In the latter case...</p>

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

perl(1), CGI::Portable, CGI::Portable::AppStatic, CGI::Portable::AppSplitScreen.

=cut
