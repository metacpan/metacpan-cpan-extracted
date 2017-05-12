#!/usr/bin/perl
#
#
# ValidityObject
# PerlLib 2XLP  Package
#
######################################################

=head1 NAME

Authen::PluggableCaptcha::ValidityObject

=head1 SYNOPSIS

This contains routines that handle validity flags
	
=head1 CLASS METHODS

=over 4

=item B<ACCEPTABLE_ERROR>

get/set if $self has an acceptable errpr

=item B<INVALID>

get/set if $self is INVALID

=item B<EXPIRED>

get/set if $self is EXPIRED

=back

=head1 DEPRECATED METHODS

=over 4

=item B<IS_VALID>

get if $self is valid

=item B<is_valid>

get if $self is valid

=item B<IS_INVALID>

get if $self is invalid

=item B<is_invalid>

get if $self is invalid


=item B<IS_EXPIRED>

get if $self is expired

=item B<is_expired>

get if $self is expired


=back


=cut


use strict;
use warnings;

package Authen::PluggableCaptcha::ValidityObject;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';

######################################################

sub ACCEPTABLE_ERROR {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Validity'}{'ACCEPTABLE_ERROR'}= $set_val;
	}
	return $self->{'.Validity'}{'ACCEPTABLE_ERROR'};
}
sub INVALID {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Validity'}{'INVALID'}= $set_val;
	}
	return $self->{'.Validity'}{'INVALID'};
}
sub EXPIRED {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Validity'}{'EXPIRED'}= $set_val;
	}
	return $self->{'.Validity'}{'EXPIRED'};
}


######################################################
# migration functions

sub IS_VALID {
	my 	( $self )= @_;
	return !$self->{'.Validity'}{'INVALID'};
}
sub is_valid { return $_[0]->IS_VALID ; }

sub IS_INVALID {
	my 	( $self )= @_;
	return $self->{'.Validity'}{'INVALID'};
}
sub is_invalid { return $_[0]->IS_INVALID ; }

sub IS_EXPIRED {
	my 	( $self )= @_;
	return $self->{'.Validity'}{'EXPIRED'};
}
sub is_expired { return $_[0]->IS_EXPIRED ; }


####
1;
