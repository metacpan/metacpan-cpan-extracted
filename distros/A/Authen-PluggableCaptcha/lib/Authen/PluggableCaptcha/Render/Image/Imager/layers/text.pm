#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render::Image::Imager::layers::text
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Image::Imager::layers::text;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
use Authen::PluggableCaptcha::Render::Image::Imager::layers ();
our @ISA= qw( Authen::PluggableCaptcha::Render::Image::Imager::layers );

######################################################

use Imager ();
use Imager::Color ();

######################################################

# constructor
sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );

		# shared init
		$self->_init_layer( \%kw_args );

		# specific init
		$self->{'render_text'}= $kw_args{'render_text'} || undef;
		$self->{'font_size'}= $kw_args{'font_size'} || undef;
		$self->{'font_filename'}= $kw_args{'font_filename'} || undef;

	# make sure we have required items for this layer
	foreach ( qw( color_fg font_filename font_size render_text image ) ) {
		if ( !exists $self->{$_} ) {
			die "Missing required element for layer 'text' : $_";
		}
	}
	
	return $self;
}

sub render {
	my 	( $self )= @_;
	
	my 	$color= Imager::Color->new( $self->{'color_fg'} ) or die "Color Error";
	my 	$font= Imager::Font->new( 
			file=> $self->{'font_filename'} 
		) or die ('Cannot load  ' . $self->{'font_filename'} . ' : ' . Imager->errstr );

		$font->align(
			string=> $self->{'render_text'},
			size=> $self->{'font_size'},
			color=> $color,
			'x'=> $self->{'image'}->getwidth/2,
			'y'=> $self->{'image'}->getheight/2,
			halign=> 'center',
			valign=> 'center',
			image=> $self->{'image'},
		);
}

###
1;