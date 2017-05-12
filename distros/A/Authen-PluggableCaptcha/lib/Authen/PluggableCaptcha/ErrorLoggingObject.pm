#!/usr/bin/perl
#
#
# ErrorLoggingObject
# PerlLib 2XLP ErrorLoggingObject Package
#
######################################################

=head1 NAME

Authen::PluggableCaptcha::ErrorLoggingObject

=head1 SYNOPSIS

	This is an ErrorLoggingObject- it contains routines that log and retreive errors for objects


	It's really nothing more than a few simple methods and an _ERROR namespace that can help manage objects
	
	This also supports '__dict__', which returns a Data::Dumper representation of an object ( kind of like printing a python __dict__ )
	
=head1 OBJECT METHODS

=over 4

=item B<_init TYPE>

initialize the errors store.  derived objects may want to call this in their constructor as 

	Authen::PluggableCaptcha::ErrorLoggingObject::_init( $self )

=item B<get_error TYPE>

returns the error defined for TYPE, or undef.  it is usually best to submit a function name as TYPE

=item B<set_error TYPE>

sets an error message, or error flag, for TYPE

=item B<clear_error TYPE>

clears the error marked for TYPE

=item B<log_function_name TYPE>

prints TYPE to STDERR

=item B<__dict__>

returns a Data::Dumper->Dump representation of $self

=cut



use strict;
use warnings;

package Authen::PluggableCaptcha::ErrorLoggingObject;
use vars qw(@ISA $VERSION);
$VERSION= '0.03';

######################################################

sub _init {
	my 	( $self )= @_;
	$self->{'.ERRORS'}= {};
}

sub get_error {
	my 	( $self , $function )= @_;
	if ( !defined $self->{'.ERRORS'}{$function} ) {
		return undef;
	};
	return $self->{'.ERRORS'}{$function};
}
	
sub set_error {
	my 	( $self , $function , $error )= @_;
	$self->{'.ERRORS'}{$function}= $error || 1;
}

sub clear_error {
	my 	( $self , $function )= @_;
	delete $self->{'.ERRORS'}{$function};
}

sub __dict__ {
	my 	( $self )= @_;
	use Data::Dumper();
	return Data::Dumper->Dump( [$self] , [qw(self)] );
}

sub log_function_name {
	print STDERR "\n\t".$_[0];
}

sub log_error {
	print STDERR "\n\t".$_[0];
}

sub log_die {
	my ( $msg_die , $clean_die )= @_;
	if ( $msg_die && defined $clean_die ) {
		my ($rmk, $msg)= map {scalar reverse} split(/ ta /, reverse($msg_die), 2);
		if ( $msg ) {
			$msg_die= $msg;
		}
		else
		{
			$msg_die= $rmk;
		}
	}
	Authen::PluggableCaptcha::ErrorLoggingObject::log_error( "DIE\t\t" . $msg_die );
}

####
1;
