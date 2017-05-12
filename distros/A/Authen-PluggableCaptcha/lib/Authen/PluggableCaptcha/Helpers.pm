#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Helpers
#
######################################################

=head1 NAME

Authen::PluggableCaptcha::Helpers

=head1 SYNOPSIS

This just has some shared functions in its own namespace
	
=head1 CLASS FUNCTIONS

=over 4

=item B<check_requires PARAMS>

requires the following key-value pairs:

=over 8

=item kw_args__ref

a reference to a hash of kw_args

=item requires_array__ref

a reference to an array of required fields

=item error_message

an error message

=back

check_requires will check the fields of kw_args__ref to ensure all items in requires_array__ref are present.   if any are missing, it will die with the error message.

=back

=head1 DEBUGGING

Set the Following envelope variables for debugging

	$ENV{'Authen::PluggableCaptcha::Helpers-DEBUG_FUNCTION_NAME'}

debug messages are sent to STDERR via the ErrorLoggingObject package

=cut


use strict;

package Authen::PluggableCaptcha::Helpers;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';

######################################################

use constant DEBUG_FUNCTION_NAME=> $ENV{'Authen::PluggableCaptcha::Helpers-DEBUG_FUNCTION_NAME'} || 0;

######################################################

=pod

This class stores shared helper methods.

It should be a mix-in eventually, with exported methods.  For now, call directly.

=cut

sub check_requires {
	my 	( %kw_args )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('check_requires');

	# make sure we were called with the requisite args
	my 	@check_requireds= qw( kw_args__ref requires_array__ref error_message );
	foreach my $check_required ( @check_requireds ) {
		if ( !defined $kw_args{ $check_required } ) {
			die "Missing required element in _check_requires [ " . ( join ',' , caller(1) ) . ' ]';
		}
	}

	# then check to make sure we have the right args
	foreach my $required ( @{$kw_args{'requires_array__ref'}} ) {
		if ( ! defined $kw_args{'kw_args__ref'}{$required} ) {
			die ( 
				sprintf( $kw_args{'error_message'} ,  $required ) 
				.
				( ' [' . ( join ',' , caller(1) ) . ' ]' ) 
			);
		}
	}
	return 1;
}





###
1;