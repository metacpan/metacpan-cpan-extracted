#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render::Text::Plain
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Text::Plain;
use vars qw(@ISA $VERSION);
$VERSION= '0.02';
use Authen::PluggableCaptcha::Render::Text ();
our @ISA= qw( Authen::PluggableCaptcha::Render::Text );

######################################################

# constructor
sub new {
	Authen::PluggableCaptcha::Render::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('new');
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );

		# init the base class
		Authen::PluggableCaptcha::Render::_init( $self , \%kw_args );

		# do the subclass init
		$self->_init( \%kw_args );
	return $self;
}

sub _init {
	Authen::PluggableCaptcha::Render::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('_init');
	my  ( $self , $kw_args__ref )= @_;
	$self->is_rendered(0);
}

sub as_string {
=pod
get the object object as a string
=cut
	Authen::PluggableCaptcha::Render::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('as_string');
	my 	( $self , %kw_args )= @_;

	if  ( $self->EXPIRED ) 
	{
		return $self->expired_message ;
	}
	
	return $self->challenge_instance->instructions . " : " . $self->challenge_instance->user_prompt;
}


###
1;