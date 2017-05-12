package Catalyst::View::Image::Text2Image;

use warnings;
use strict;
use parent 'Catalyst::View';
use GD::Simple;

=head1 NAME

Catalyst::View::Image::Text2Image - View to create text into image AND render GD::Simple-images;

=head1 DESCRIPTION

Catalyst::View::Image::Text2Image is a view that creates images using GD::Simple.
You can set $c->stash->{Text2Image} to several options that will define your output.
The "morph" Option lets your image stretch by length of given string and font-definition.
Or you just create an image using GD::Simple and pass it to the view.

=head1 SYNOPSIS

=over

=item Create a Text2Image view:

 script/myapp_create.pl view Image::Text2Image Image::Text2Image

=item Text2Image example:

  Your controller:

	sub Text2Image :Local {
		my ( $self, $c) = @_;
		
		$c->stash->{Text2Image}->{string} 	||= 'Done with Catalyst::View::Image::Text2Image';
		$c->stash->{Text2Image}->{x} 		= 10; # doesn't matter in this case, might be just 1
		$c->stash->{Text2Image}->{y} 		= 45;
		$c->stash->{Text2Image}->{font} 	= 'Times New Roman';
		$c->stash->{Text2Image}->{fontsize} = '15';
		$c->stash->{Text2Image}->{bgcolor} 	= 'black';
		$c->stash->{Text2Image}->{fgcolor} 	= 'green';
		$c->stash->{Text2Image}->{moveTo} 	= [0,44];
		$c->stash->{Text2Image}->{angle} 	= -5;
		$c->stash->{Text2Image}->{morph} 	= 1; ### Should the x value be adapted when text is too long?
		$c->stash->{Text2Image}->{clear} 	= 1; ### define "clear" to make canvas-color = bgcolor !!
		$c->stash->{Text2Image}->{transparent} 	= 'white'; # set color to become transparent
		
		$c->detach('View::Image::Text2Image');
	}
	
=item Example to process a pre-created image with GD::Simple:

  (this leaves you all the possibilities of GD::Simple)

  Your controller:
  
	sub Text2Image :Local {
		my ( $self, $c) = @_;
		my $img = GD::Simple->new(640, 480); 
		$img->fgcolor('black');
		$img->bgcolor('green'); 
		$img->rectangle(10, 10, 150, 150);
		$img->ellipse(50, 50);
		$img->moveTo(0,25);
		$img->font('Times New Roman');
		$img->fontsize(18);
		$img->string('Image processed by Catalyst::View::Image::Text2Image'); 
		$c->stash->{Text2Image}->{'img'} = $img;
		$c->detach('View::Image::Text2Image');
	}

=back	
	
=head2 Options

The view is controlled by setting the following values in the stash:

=over

=item $c->stash->{Text2Image}->{img}

(optional) Can contain a GD::Image object. If set, the view will not create an image but try to process/render this object. 
If not set, you need at least to provide "y","string", "font" and "fontsize".

=item $c->stash->{Text2Image}->{x}

The width (in pixels) of the image. Might be altered if option "morph" is set.
Only considered if not $c->stash->{Text2Image}->{img}.

=item $c->stash->{Text2Image}->{y}

The height (in pixels) of the image.
Mandatory if not $c->stash->{Text2Image}->{img}

=item $c->stash->{Text2Image}->{string}

The Text of the image. Only one line supported in this version.
Mandatory if not $c->stash->{Text2Image}->{img}

=item $c->stash->{Text2Image}->{morph}

(optional) Bool. Should the width of the image be adapted to the width of $c->stash->{Text2Image}->{string}? 
Note: The option "angle" isn't considered in "morph"-functionality, so your images may become to wide if you use "angle" and "morph" together.
Only considered if not $c->stash->{Text2Image}->{img}

=item $c->stash->{Text2Image}->{font}

The font to use for the text.
Mandatory if not $c->stash->{Text2Image}->{img}

=item $c->stash->{Text2Image}->{fontsize}

The font to use for the text.
Mandatory if not $c->stash->{Text2Image}->{img}

=item MORE Options...

More GD::Simple Options are just applied by values in the stash.
Tested in this version are: bgcolor, fgcolor, moveTo, clear, transparent and angle. 
Refer to examples for more informations on that.

=back

=head2 Image format

The generated images will always be produced in the PNG-Format.

=head1 SEE ALSO

GD::Simple
Catalyst::View

=head1 AUTHOR

Martin Gillmaier (MG), C<< <gillmaus at cpan.org> >>

=head1 SUPPORT

Critics, requests, commercial support and training for this module is available:
Contact L<gillmaus at cpan.org> for details.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2012 Martin Gillmaier (GILLMAUS).

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This module is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. 

=cut

our $VERSION = '0.02';

=head1 METHODS

=head2 process
	
	Main method of the view.
	
=cut

sub process {
  my ($self, $c) = @_;
  
  # Is there an pre-created image already?
  unless (defined($c->stash->{Text2Image}->{'img'})) {
	  # No? Create one using &text2image:
	  $c->stash->{'Text2Image'}->{'img'} = $self->text2image($c->stash->{'Text2Image'});
  }
  
  # Set content:
  $c->response->content_type('image/png');
  $c->response->body($c->stash->{'Text2Image'}->{'img'}->png); 
}


=head2 text2image

	Converts a texts into a png-image using GD::Simple;
	
	param: Hash-Ref of GD::Simple options (meaning: function=>value), for example: 
			{
				### MUST-values:
				x => 100,
				y => 20, 
				font => 'Times New Roman',
				fontsize => 18,
				string => 'Huhu..its me..your pic!',
				### OPTIONAL Values:
				morph => 1, 	# optional, will adapt x to string-width 
				clear => '1', 	# to set canvas-color=bgcolor. 
				transparent => 'white' # make background transparent
				### other optional, GD::Simple Values:
				fgcolor => 'black',
				bgcolor => 'white',
				angle => -5,
				moveTo => [0,20] # Move pencil 
			}
			
	return: GD image-Object
=cut

sub text2image {
  my ($self, $options) = @_;
  my %opts = %{$options};
  
  # check: 
  $opts{x} = 1 if $opts{x}<1; # height not 0 or negative
  return 'y value missing' if $opts{y}<1; # width not 0 or negative
  return 'string value missing' unless $opts{string}; # text-width not 0
  return 'font value missing' unless $opts{font}; # font not undef
  return 'fontsize value missing' if $opts{fontsize} <1; # fontsize not 0
  
  # Create image:
  my $img = GD::Simple->new($opts{x}, $opts{y});
   
  # Morph image?
  $img->font($opts{font});
  $img->fontsize($opts{fontsize});
  my $size = $img->stringWidth($opts{'string'});
  if ($size > $opts{y} && $opts{morph}) {
	$img = GD::Simple->new($size, $opts{y});
  }

  # Try to apply all other options:
  eval {
	foreach my $opt (keys %opts) {
	  next if ($opt eq 'x' || $opt eq 'y' || $opt eq 'morph' || $opt eq 'string' || $opt eq 'clear');
	  
	  if (ref($opts{$opt}) eq 'ARRAY') {
		# Array-Parameters
		$img->$opt( @{$opts{$opt}} );
		
	  } elsif (!$opts{$opt}) {
		# No Params:
		$img->$opt();
		
	  } else {
		# One Parameter:
		$img->$opt( $opts{$opt} );
	  }
	}
  };
  return $@ if ($@);
  
  # Change background color?
  $img->clear if (exists $opts{clear});
  
  # Now apply string:
  $img->string($opts{string});
  
  return $img;
}

1; # End of Catalyst::View::Image::Text2Image

