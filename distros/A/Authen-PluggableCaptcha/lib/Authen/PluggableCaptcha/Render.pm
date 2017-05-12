#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render
#
######################################################

=head1 NAME

Authen::PluggableCaptcha::Render

=head1 SYNOPSIS

Base Render Class

=head1 CONSTRUCTOR

There is no constructor.  Calling ->new() will die .  new() must be subclassed.

=head1 OBJECT METHODS

=over 4

=item C<_init PARAMS>

base render setup.  PARAMS are required name/value pairs.  Required PARAMS are:

=over 8

=item C<challenge_instance TYPE>

an instance of an L<Authen::PluggableCaptcha::Challenge> object

=back

It's often easiest for derived classes to call

	Authen::PluggableCaptcha::Render::_init( $self , \%kw_args );
	
in their constructors


=item C<_challenge_instance TYPE>

sets the internal stash of the L<Authen::PluggableCaptcha::Challenge> object.  you probably don't want to call this , unless you replace _init_render

=item C<challenge_instance>

gets the internal stash of the L<Authen::PluggableCaptcha::Challenge> object. 

=item C<is_rendered BOOL>

gets/sets a bool if the object is rendered or not

=item C<expired_message TEXT>

gets/sets the expired message

=item C<as_string>

returns a rendering of the captcha as a string.  this MUST be subclassed

=item C<render>

runs the render logic.  this MUST be subclassed

=item C<init_expired>

called by L<Authen::PluggableCaptcha> when initializing a new captcha render object for an expired key

=item C<init_valid>

called by L<Authen::PluggableCaptcha> when initializing a new captcha render object for a valid key

=back

=head1 DEBUGGING

Set the Following envelope variables for debugging

	$ENV{'Authen::PluggableCaptcha::Render-DEBUG_FUNCTION_NAME'}

debug messages are sent to STDERR via the ErrorLoggingObject package


=cut


use strict;

package Authen::PluggableCaptcha::Render;
use vars qw(@ISA $VERSION);
$VERSION= '0.02';

use Authen::PluggableCaptcha::ErrorLoggingObject ();
use Authen::PluggableCaptcha::Helpers ();
our @ISA= qw( Authen::PluggableCaptcha::ErrorLoggingObject );

######################################################

use constant DEBUG_FUNCTION_NAME=> $ENV{'Authen::PluggableCaptcha::Render-DEBUG_FUNCTION_NAME'} || 0;

######################################################


sub new {
	die "Called Authen::PluggableCaptcha->new() - new MUST be subclassed";
}	
	

sub _init {
	my	( $self , $kw_args__ref )= @_;
	Authen::PluggableCaptcha::Render::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('_init');

	# make sure we have the requisite kw_args
	my 	@_requires= qw( challenge_instance );
	Authen::PluggableCaptcha::Helpers::check_requires( 
		kw_args__ref=> $kw_args__ref,
		error_message=> "Missing required element '%s' in _init_render",
		requires_array__ref=> \@_requires
	);
	
	die unless defined $$kw_args__ref{'challenge_instance'};
	
	$self->_challenge_instance( $$kw_args__ref{'challenge_instance'} );
	return 1;
}

sub _challenge_instance {
	my 	( $self , $challenge_instance_object )= @_;
	die "no challenge_instance_object supplied" unless $challenge_instance_object;
	$self->{'..challenge_instance'}= $challenge_instance_object;
	return $self->{'..challenge_instance'};
}
sub challenge_instance {
	my 	( $self )= @_;
	return $self->{'..challenge_instance'};
}

sub is_rendered {
	my 	( $self , $val );
	if 	( defined $val ) {
		$self->{'..is_rendered'}= $val;
	}
	return $self->{'..is_rendered'};
}

sub expired_message {
	my 	( $self , $val );
	if 	( defined $val ) {
		$self->{'..expired_message'}= $val;
	}
	return $self->{'..expired_message'};
}

sub as_string {
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('as_string');
	my 	( $self , %kw_args )= @_;
	die "called Authen::PluggableCaptcha::Render::as_string directly or from a non-override subclass.  this method must always be subclassed";
}

sub render {
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('render');
	my 	( $self , %kw_args )= @_;
	die "called Authen::PluggableCaptcha::Render::render directly or from a non-override subclass.  this method must always be subclassed";
}

sub init_expired {
	my 	( $self , %kw_args )= @_;
	die "called Authen::PluggableCaptcha::Render::init_expired directly or from a non-override subclass.  this method must always be subclassed";
}
sub init_valid {
	my 	( $self , %kw_args )= @_;
	die "called Authen::PluggableCaptcha::Render::init_valid directly or from a non-override subclass.  this method must always be subclassed";
}

###
1;