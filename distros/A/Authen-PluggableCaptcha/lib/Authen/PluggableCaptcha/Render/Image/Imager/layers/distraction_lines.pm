#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render::Image::Imager::layers::distraction_lines
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Image::Imager::layers::distraction_lines;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
use Authen::PluggableCaptcha::Render::Image::Imager::layers;
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
		$self->_init_layer( \%kw_args );

	# make sure we have required items for this layer
	foreach ( qw( color_fg image ) ) {
		if ( !exists $self->{$_} ) {
			die "Missing required element for layer 'distraction_lines' : $_";
		}
	}

	return $self;
}

sub render {
	my 	( $self )= @_;
	my 	$color= Imager::Color->new( $self->{'color_fg'} ) or die "Color Error";
	
	my 	$width= $self->{'image'}->getwidth();
	my 	$height= $self->{'image'}->getheight();
	my 	$img= $self->{'image'};
	
	my 	$max_loop;

	# first some sweeping arcs.  in PIL these would be lines, but in Perl they are 'pie slices'
	$max_loop= int(rand(4))+1;
	foreach ( my $i=0; $i<= $max_loop ; $i++ ) { 
		my 	$angle= int(rand(360));
		my 	$x= int(rand($width));
		my 	$y= int(rand($height));
		my 	$radius= int(rand( $width - $x ));
		$img->arc( 
			color=> $color ,
			'x'=> $x,
			'y'=> $y,
			r=> $radius,
			d1=> $angle,
			d2=> $angle+1,
		);
	}

	# then some smaller arcs
	$max_loop= int(rand(10))+5;
	foreach ( my $i=0; $i<= $max_loop ; $i++ ) { 
		my 	$angle= int(rand(360));
		my 	$x= int(-20+ rand($width +20));
		my 	$y= int(-20+ rand($height +20));
		my 	$radius= int(rand(30));
		$img->arc( 
			color=> $color ,
			'x'=> $x,
			'y'=> $y,
			r=> $radius,
			d1=> $angle,
			d2=> $angle+2,
		);
	}
	

	# then some lines
	$max_loop= int(rand(10))+5;
	foreach ( my $i=0; $i<= $max_loop ; $i++ ) { 
		my 	( $x1 , $y1 )= ( int(-20+ rand($width +20)) , int(-20+ rand($height +20)) );
		my 	( $x2 , $y2 )= ( $x1+int(rand(40)), $y1+int(rand(40)) );
		$img->line( 
			color=> $color,
			x1=> $x1,
			x2=> $x2,
			y1=> $y1,
			y2=> $y2,
			aa=> 0,
			endp=> 1,
		);
		if ( rand(100) > 50 ) {
			foreach ( my $j=1; $j<=int(4)+1; $j++ ){
				$x1+= 1;
				$x2+= 1;
				$y1+= 1;
				$y2+= 1;
				$img->line(
					color=> $color,
					x1=> $x1,
					x2=> $x2,
					y1=> $y1,
					y2=> $y2,
					aa=> 0,
					endp=> 1,
				)
			}
		}
	}
}


###
1;