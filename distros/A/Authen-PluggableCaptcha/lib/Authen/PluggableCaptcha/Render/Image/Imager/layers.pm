#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render::Image::Imager::layers
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Image::Imager::layers;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';

######################################################

sub _init_layer {
	my 	( $self , $kw_args )= @_;
	$self->{'image'}= $$kw_args{'image'} or die "no image passed to the layer";
	$self->{'width'}= $$kw_args{'width'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'width'};
	$self->{'height'}= $$kw_args{'height'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'height'};
	$self->{'color_bg'}= $$kw_args{'color_bg'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'color_bg'};
	$self->{'color_fg'}= $$kw_args{'color_fg'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'color_fg'};
}

sub render {
=pod
subclasses get AT LEAST a render function with specific render instructions for the layer
=cut
	my 	( $self )= @_;
	die "render must be subclassed";
}

######################################################
1;