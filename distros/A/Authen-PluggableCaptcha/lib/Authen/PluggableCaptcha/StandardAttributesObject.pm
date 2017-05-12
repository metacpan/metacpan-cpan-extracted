#!/usr/bin/perl
#
#
# ValidityObject
# PerlLib 2XLP StandardAttributesObject Package
#
######################################################

=head1 NAME

Authen::PluggableCaptcha::StandardAttributesObject

=head1 SYNOPSIS

This contains routines that handle standard attributes

=head1 OBJECT METHODS

=over 4

=item B<publickey PARAMS>

get / set publickey

=item B<seed PARAMS>

get / set seed

=item B<site_secret PARAMS>

get / set site_secret

=item B<time_expiry PARAMS>

get / set time_expiry

=item B<time_expiry_future PARAMS>

get / set time_expiry_future

=item B<time_now PARAMS>

get / set time_now

=item B<time_start PARAMS>

get / set time_start


=back

=cut




use strict;
use warnings;

package Authen::PluggableCaptcha::StandardAttributesObject;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';

######################################################


sub publickey {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Attributes'}{'publickey'}= $set_val;
	}
	return $self->{'.Attributes'}{'publickey'};
}

sub seed {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Attributes'}{'seed'}= $set_val;
	}
	return $self->{'.Attributes'}{'seed'};
}

sub site_secret {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Attributes'}{'site_secret'}= $set_val;
	}
	return $self->{'.Attributes'}{'site_secret'};
}

sub time_expiry {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Attributes'}{'time_expiry'}= $set_val;
	}
	return $self->{'.Attributes'}{'time_expiry'};
}

sub time_expiry_future {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Attributes'}{'time_expiry_future'}= $set_val;
	}
	return $self->{'.Attributes'}{'time_expiry_future'};
}

sub time_now {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Attributes'}{'time_now'}= $set_val;
	}
	return $self->{'.Attributes'}{'time_now'};
}

sub time_start {
	my 	( $self , $set_val )= @_;
	if 	( defined $set_val ) {
		$self->{'.Attributes'}{'time_start'}= $set_val;
	}
	return $self->{'.Attributes'}{'time_start'};
}



####
1;
