#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Img::effects::sinewarp;
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Image::Imager::effects::sinewarp;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
our @ISA= qw( Authen::PluggableCaptcha::Render::Image::Imager::effects );

######################################################

use Imager ();
use Authen::PluggableCaptcha::Render::Image::Imager::effects ();

######################################################

# constructor
sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );
		$self->_init_effect( \%kw_args );
	return $self;
}

sub render {
	my 	( $self )= @_;
=pod

ToDo-
	This doesn't sinewarp.  It should.  But Imager doesn't support it yet, and i'm not going to code it
=cut
}



###
1;