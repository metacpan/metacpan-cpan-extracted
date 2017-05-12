#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Challenge
# Copyright(c) 2006, Jonathan Vanasco (cpan@2xlp.com)
# Distribute under the Artistic License
#
#############################################################################

=head1 NAME

Authen::PluggableCaptcha::Challenge

=head1 DESCRIPTION

This is the base class for generating a captcha challenge

captcha challenges must support the following methods

  ->new( keygenerator_instance=> $keygenerator_instance );
  ->validate( user_response=> $user_response );
     validate must return :
     	1 success
     	0 failure
     	-1 error

there are 3 public methods that must be available to other modules

  'instructions'
	what a user should do
  'user_prompt'
    what to prompt the user with
    this will be rendered by the render engine
    for image/audio this is probably the same as correct_response
  'correct_response'
    the repsonse
		
Example:
	Image Authen::PluggableCaptcha:
		instructions: type in the letters you see
		user_prompt: abcdef
		correct_response: abcdef
	
	Text Logic Authen::PluggableCaptcha:
		instructions: do this math problem
		user_prompt: what is 12 divided by 1 ?
		correct_response: 12


=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>
Returns a new L<Authen::PluggableCaptcha::Challenge> object constructed according to PARAMS, where PARAMS are name/value pairs.

PARAMS are required name/value pairs.  Required PARAMS are:

=over 8

=item C<keymanager_instance TYPE>

A reference to an object derived from L<Authen::PluggableCaptcha::KeyManager> 

=back

=back

=head1 OBJECT METHODS

Note that setters and getters are seperate.  Setters should only be called from derived classes.  Getters can be called anywhere from perl code.

=over 4

=item B<validate TYPE>

validate the challege

returns:
	1 on success
	0 on failure
	-1 on error

This method MUST be overriden in a subclass

=item B<_keymanager TYPE>

set the keymanager instance

=item B<keymanager TYPE>

get the keymanager instance


=item B<_instructions TYPE>

set the instructions text

=item B<instructions TYPE>

get the instructions text

=item B<_user_prompt TYPE>

set the user_prompt text

=item B<user_prompt TYPE>

get the user_prompt text

=item B<_correct_response TYPE>

set the correct_response text

=item B<correct_response TYPE>

get the correct_response text

=over

=cut
use strict;

package Authen::PluggableCaptcha::Challenge;
use vars qw(@ISA $VERSION);
$VERSION= '0.02';

use Authen::PluggableCaptcha::ErrorLoggingObject ();
our @ISA= qw( Authen::PluggableCaptcha::ErrorLoggingObject );

#############################################################################

sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );
	die "must supply 'keymanager_instance'" unless $kw_args{'keymanager_instance'};
	return $self;		
}

sub validate {
	my	( $self )= @_;
	die "called Authen::PluggableCaptcha::Challenge::validate directly.  this method must be subclassed"; 
}

sub instructions {
	my	( $self )= @_;
	return $self->{'.Challenge'}{'instructions'};
}
sub user_prompt {
	my	( $self )= @_;
	return $self->{'.Challenge'}{'user_prompt'};
}
sub correct_response {
	my	( $self )= @_;
	return $self->{'.Challenge'}{'correct_response'};
}

sub _instructions {
	my	( $self , $val )= @_;
	die "no instructions" unless defined $val;
	$self->{'.Challenge'}{'instructions'}= $val;
	return $self->{'.Challenge'}{'instructions'};
}
sub _user_prompt {
	my	( $self , $val )= @_;
	die "no user_prompt" unless defined $val;
	$self->{'.Challenge'}{'user_prompt'}= $val;
	return $self->{'.Challenge'}{'user_prompt'};
}
sub _correct_response {
	my	( $self , $val )= @_;
	die "no correct_response" unless defined $val;
	$self->{'.Challenge'}{'correct_response'}= $val;
	return $self->{'.Challenge'}{'correct_response'};
}


sub _keymanager {
	my	( $self , $keymanager_object )= @_;
	die "no keymanager_object" unless defined $keymanager_object;
	$self->{'.keymanager_instance'}= $keymanager_object;
	return $self->{'.keymanager_instance'};
}
sub keymanager {
	my	( $self , $keymanager_object )= @_;
	return $self->{'.keymanager_instance'};
}


###
1;