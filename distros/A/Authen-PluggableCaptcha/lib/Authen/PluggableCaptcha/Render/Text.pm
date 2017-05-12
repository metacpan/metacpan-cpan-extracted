#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render::Text
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Text;
use vars qw(@ISA $VERSION);
$VERSION= '0.02';
use Authen::PluggableCaptcha::Render ();
our @ISA= qw( Authen::PluggableCaptcha::Render Authen::PluggableCaptcha::ValidityObject );

######################################################
use Authen::PluggableCaptcha ();
use Authen::PluggableCaptcha::ErrorLoggingObject ();
######################################################

our %_DEFAULTS = (
	'format'=> 'PLAIN',
	message_expired=> 'This captcha has expired',
);

######################################################

sub _init__text {
	Authen::PluggableCaptcha::Render::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('_init__text');
	my  ( $self , $kw_args__ref )= @_;
	$self->is_rendered(0);
}

sub init_expired {
	Authen::PluggableCaptcha::Render::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('init_expired');
	my 	( $self )= @_;
	$self->EXPIRED(1);
	$self->expired_message( $Authen::PluggableCaptcha::TextLogic::_DEFAULTS{'message_expired'} );
}

sub init_valid {
	Authen::PluggableCaptcha::Render::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('init_valid');
	my 	( $self )= @_;
	$self->EXPIRED(0);
}

sub render {
	Authen::PluggableCaptcha::Render::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('render');
	my 	( $self )= @_;
	if ( $self->is_rendered ) {
		return;
	}

	# we would do a render here.

	$self->is_rendered(1);
}







###
1;