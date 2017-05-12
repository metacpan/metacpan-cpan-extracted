#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Img::layers::bg
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Image::Imager::layers::bg;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
use Authen::PluggableCaptcha::Render::Image::Imager::layers;
our @ISA= qw( Authen::PluggableCaptcha::Render::Image::Imager::layers );

######################################################

use Imager ();

######################################################

# constructor
sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );
		$self->_init_layer( \%kw_args );

	# make sure we have required items for this layer
	foreach ( qw( color_bg image ) ) {
		if ( !exists $self->{$_} ) {
			die "Missing required element for layer 'bg' : $_";
		}
	}
	return $self;
}

sub render {
	my 	( $self )= @_;
	$self->{'image'}->box( filled=> 1 , color=> $self->{'color_bg'} );
}

###
1;