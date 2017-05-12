=head1 NAME

CGI::Portable::AppSplitScreen - Delegate construction of a screen between several modules

=cut

######################################################################

package CGI::Portable::AppSplitScreen;
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

=head2 Simple program whose output is made by combining several modules:

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
	$globals->call_component( 'CGI::Portable::AppSplitScreen' );

	$io->send_user_output( $globals );

	1;

=head2 Content of file 'myconfig.pl' telling program what to do:

I<This is not a whole example, but you can get an idea what to substitute.  
This example shows 3 screen regions handled by 3 module instances, each of 
which has their own preferences and optional subdirectory for files.>

	my $rh_preferences = { 
		delegate_list => [
			{
				file_subdir => 'menus',
				preferences => { key => 'value' },
				module_name => 'other::module::menu',
				leave_scalars => 1,
				replace_lists => 0,
			},
			{
				file_subdir => 'forms',
				preferences => { key1 => 'value', key2 => 'value' },
				module_name => 'other::module::form',
				leave_scalars => 0,
				replace_lists => 0,
			},
			{
				file_subdir => undef,
				preferences => {},
				module_name => 'other::module::disclaim',
				leave_scalars => 1,
				replace_lists => 0,
			},
		],
	};

=head1 DESCRIPTION

This Perl 5 object class is a simple encapsulated application, or "component",
that runs in the CGI::Portable environment.  It allows you to easily divide a
response screen into multiple regions and then delegate the construction of each
region to separate "components".  You define the regions within the standard
"preferences", and no other input is required.  Specifically, you use the
"delegate_list" array preference; each array element describes a region, and the
created regions appear consecutively in the same order as in the array.  Each
element says what delegate module to call and what its preferences are.  This
class is subclassed from CGI::Portable::AppStatic, which is convenient if you
want to do simple post-processing of your new screen using its preferences.  This
module is designed to be easily subclassed by your own application components,
should you wish to extend or customize its functionality.

=cut

######################################################################

# Constant values used by this class:

# Keys for items in site page preferences:
my $PKEY_DELEGATE_LIST = 'delegate_list';

# Keys for elements in $PKEY_DELEGATE_LIST hash:
my $DKEY_FILE_SUBDIR = 'file_subdir';
my $DKEY_PREFERENCES = 'preferences';
my $DKEY_MODULE_NAME = 'module_name';
my $DKEY_LEAVE_SCALARS = 'leave_scalars';
my $DKEY_REPLACE_LISTS = 'replace_lists';

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

=cut

######################################################################

sub main {
	my ($class, $globals) = @_;
	my $self = bless( {}, ref($class) || $class );

	UNIVERSAL::isa( $globals, 'CGI::Portable' ) or 
		die "initializer is not a valid CGI::Portable object";

	$self->set_static_low_replace( $globals );

	$self->set_split_screen_attach_delegate_list( $globals );

	$self->set_static_high_replace( $globals );
	$self->set_static_attach_unordered( $globals );
	$self->set_static_attach_ordered( $globals );
	$self->set_static_search_and_replace( $globals );
}

######################################################################

=head1 PREFERENCES HANDLED BY THIS MODULE

This module is a subclass of CGI::Portable::AppStatic and will handle all of 
that module's preferences in addition to the new ones discussed below.

The only preference specifically for CGI::Portable::AppSplitScreen allows you to
define a list of other modules which are all to be called in order to construct a
portion of the result screen.  AppSplitScreen doesn't normally do any screen
construction by itself, but rather handles the logic required to call a list of
modules and stitch together their results.  The key preference that you need to
set is "delegate_list".  See the SYNOPSIS for the format of that preference.

=head2 delegate_list

This array-ref preference is a delegation list which divides the result screen
into a list of consecutive regions, and matches each region with an "application
component" module instance that will handle the content of that region.  The
array elements are hash-refs that say what other module to call and what its
config preferences are.  Any elements that are not hash-refs are ignored.

Each of these hash-refs must have values for at least these two keys set:
"module_name" and "preferences".  Each can optionally have these three keys set:
"file_subdir", "leave_scalars", "replace_lists".  The value for "module_name" is
a scalar having the name of the Perl 5 module to invoke as an "application
component" that will make the new result screen.  The value for "preferences" can
be either a hash-ref having literal preferences for the invoked module, or a
scalar having a filename of a Perl file that can be executed to return the same
preferences hash ref; it must be an empty hash ref if the module takes no
preferences.  The value for "file_subdir" is a relative file system path within
which the invoked module should look for its files (or config file) if any; if
this value is not set then the current file directory is used instead.  The
values for "leave_scalars" and "replace_lists" are used when stitching the
delegates' output together, in order to better control when conflicting outputs
have priority over each other (eg: there can be only one document title).

Delegated modules operate within a new "context" created by the current
CGI::Portable object's make_new_context() method.  Within that context,
AppSplitScreen does the following: 1. call navigate_file_path() with the
"file_subdir" value as its argument; 2. call set_prefs() with the "preferences"
value as its argument; 3. call call_component() with the "module_name" value as
its argument.  Finally, the output held by the inner context is saved using the
current CGI::Portable object's take_context_output() method, which takes the
"leave_scalars" and "replace_lists" values as its last two optional arguments.

=head1 PRIVATE METHODS FOR USE BY SUBCLASSES

=head2 set_split_screen_attach_delegate_list( GLOBALS )

This method will iterate through all the elements of the "delegate_list" array 
preference and use each element to construct a consecutive screen region.  For 
each element, the method set_split_screen_attach_delegate_list() is called to 
process it as a delegate.  This method returns without doing anything if there 
is no "delegate_list" preference or it isn't an array.

=cut

######################################################################

sub set_split_screen_attach_delegate_list {
	my ($self, $globals) = @_;
	my $delegate_list = $globals->pref( $PKEY_DELEGATE_LIST );
	ref( $delegate_list ) eq 'ARRAY' or return( 0 );
	foreach my $delegate (@{$delegate_list}) {
		$self->set_split_screen_attach_one_delegate( $globals, $delegate );
	}
}

######################################################################

=head2 set_split_screen_attach_one_delegate( GLOBALS, DELEGATE )

This method will use its DELEGATE argument to construct a new screen region and
append it to any existing response in the GLOBALS context argument.  DELEGATE is
a hash ref whose values describe how the new screen region is to be made.  It's
properties are described by the delegate_list preference documentation, above, as
DELEGATE can be set as an element in the delegate_list array.  This method
returns without doing anything if DELEGATE is not a valid hash ref.

=cut

######################################################################

sub set_split_screen_attach_one_delegate {
	my ($self, $globals, $delegate) = @_;
	ref( $delegate ) eq 'HASH' or return( 0 );
	my $inner_context = $globals->make_new_context();
	$inner_context->navigate_file_path( $delegate->{$DKEY_FILE_SUBDIR} );
	$inner_context->set_prefs( $delegate->{$DKEY_PREFERENCES} );
	$inner_context->call_component( $delegate->{$DKEY_MODULE_NAME} );
	$globals->take_context_output( $inner_context, 
		$delegate->{$DKEY_LEAVE_SCALARS}, $delegate->{$DKEY_REPLACE_LISTS} );
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

perl(1), CGI::Portable, CGI::Portable::AppStatic, CGI::Portable::AppMultiScreen.

=cut
