#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render::Image::Imager
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Image::Imager;
use vars qw(@ISA $VERSION);
$VERSION= '0.02';
use Authen::PluggableCaptcha::Render::Image ();
our @ISA= qw( Authen::PluggableCaptcha::Render::Image );

######################################################

use Imager ();

use Authen::PluggableCaptcha::Render::Image::Imager::layers::bg ();
use Authen::PluggableCaptcha::Render::Image::Imager::layers::text ();
use Authen::PluggableCaptcha::Render::Image::Imager::layers::distraction_lines ();
use Authen::PluggableCaptcha::Render::Image::Imager::effects::sinewarp ();

######################################################

our %_DEFAULTS = (
	width=> 300,
	height=> 100,
	color_bg=> '#DDDDDD',
	color_fg=> 'RANDOM',
	message_expired=> 'IMAGE EXPIRED',
	font_size_range=> [ 30 , 45 ],
	font_expired_filename=> '/usr/X11R6/lib/X11/fonts/TTF/VeraBd.ttf',
	font_expired_size=> 20,
	font_filename=> '/usr/X11R6/lib/X11/fonts/TTF/VeraBd.ttf',
	font_size=> 20,
	text_render_mode=> 'by_letter', # ( by_letter | whole_word )
	'format'=> 'jpeg',
);

our @_random_fg_colors= ("#330000","#660000","#003300","#006600","#000033","#000066");

######################################################

# constructor
sub new {
	my	( $proto , %kw_args )= @_;
	my	$class= ref($proto) || $proto;
	my	$self= bless ( {} , $class );
	
		# init the base class
		Authen::PluggableCaptcha::Render::_init( $self , \%kw_args );

		# do the subclass init
		$self->_init( \%kw_args );

	return $self;
}

sub _init {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('init');
	my	( $self , $kw_args__ref )= @_;

	$self->{'width'}= $$kw_args__ref{'width'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'width'};
	$self->{'height'}= $$kw_args__ref{'height'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'height'};
	$self->{'color_bg'}= $$kw_args__ref{'color_bg'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'color_bg'};
	$self->{'color_fg'}= $$kw_args__ref{'color_fg'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'color_fg'};
	
	if ( $self->{'color_fg'} eq 'RANDOM') {
		$self->{'color_fg'}= $Authen::PluggableCaptcha::Render::Image::Imager::_random_fg_colors[ int(rand($#Authen::PluggableCaptcha::Render::Image::Imager::_random_fg_colors)) ];
	}
	
	$self->{'font_size'}= $$kw_args__ref{'font_size'} || int(rand( ${$Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'font_size_range'}}[1] - ${$Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'font_size_range'}}[0] ) + ${$Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'font_size_range'}}[0] );
	$self->{'font_filename'}= $$kw_args__ref{'font_filename'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'font_filename'};

	$self->{'_image'}= Imager->new( 
		xsize=> $self->{'width'}, 
		ysize=> $self->{'height'} 
	);

	$self->{'render_text'}= $self->challenge_instance->user_prompt || die "No user_prompt!";

	$self->is_rendered(0);

	@{$self->{'_layers'}}= ();
}

sub init_expired {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('init_expired');
	my	( $self )= @_;
	$self->{'font_size'}= $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'font_expired_size'};
	@{$self->{'_layers'}} = (
			Authen::PluggableCaptcha::Render::Image::Imager::layers::bg->new( 
				image=> $self->{'_image'} , 
				color_bg=> $self->{'color_bg'} 
			),
			Authen::PluggableCaptcha::Render::Image::Imager::layers::text->new( 
				image=> $self->{'_image'} , 
				render_text=> $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'message_expired'} , 
				font_size=> $self->{'font_size'} , 
				font_filename=> $self->{'font_filename'} , 
				color_fg=> $self->{'color_fg'} , 
				canvas_width=> $self->{'width'} , 
				canvas_height=> $self->{'height'} 
			),
	);
}

sub init_valid {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('init_valid');
	my	( $self )= @_;
	@{$self->{'_layers'}}= (
		Authen::PluggableCaptcha::Render::Image::Imager::layers::bg->new( 
			image=> $self->{'_image'}, 
			color_bg=> $self->{'color_bg'} 
		),
		Authen::PluggableCaptcha::Render::Image::Imager::layers::text->new( 
			image=> $self->{'_image'}, 
			render_text=> $self->{'render_text'} , 
			font_size=> $self->{'font_size'}, 
			font_filename=> $self->{'font_filename'}, 
			color_fg=> $self->{'color_fg'} , 
			canvas_width=> $self->{'width'} , 
			canvas_height=> $self->{'height'} 
		),
		Authen::PluggableCaptcha::Render::Image::Imager::layers::distraction_lines->new( 
			image=> $self->{'_image'}, 
			color_fg=> $self->{'color_fg'} 
		),
		Authen::PluggableCaptcha::Render::Image::Imager::effects::sinewarp->new( 
			image=> $self->{'_image'}, 
			amplitudeRange=> (4, 8) , 
			periodRange=> (0.65,0.73) 
		),
	);
}


sub render {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('render');
	my	( $self )= @_;
=pod
Render this CAPTCHA
=cut
	if ( !$self->{'_image'} ) {
		die "i shouldn't be like this";
	}
	if ( 	$self->is_rendered ) {
		return;
	}
	foreach my $layer ( @{ $self->{'_layers'} } ) {
		$layer->render();
	}
	$self->is_rendered(1);
}

sub as_string {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('as_string');
	my	( $self , %kw_args )= @_;
	my	$as_string;
	my	$format=  $kw_args{'format'} || $Authen::PluggableCaptcha::Render::Image::Imager::_DEFAULTS{'format'};
	$self->{'_image'}->write( type=>$format , data=>\$as_string );
	return $as_string;
}


sub get_img {
	my	( $self )= @_;
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('get_img');
=pod
Get an Imager object representing this Img, creating it if necessary
we really shouldn't need to do this, but its just a convenience method for testing
=cut
	if ( !$self->is_rendered ) {
		$self->render();
	}
	return $self->{'_image'};
}


###
1;