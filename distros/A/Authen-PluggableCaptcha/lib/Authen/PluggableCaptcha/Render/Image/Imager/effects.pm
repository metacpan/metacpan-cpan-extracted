#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render::Image::Imager::effects
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Image::Imager::effects;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';

######################################################

sub _init_effect {
	my 	( $self , $kw_args )= @_;
	foreach my $key ( keys %{$kw_args} ) {
		$self->{$key}= $$kw_args{$key};
	}
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