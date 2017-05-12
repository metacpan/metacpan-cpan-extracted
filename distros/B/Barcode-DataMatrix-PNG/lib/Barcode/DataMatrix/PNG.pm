#!/usr/bin/perl

package Barcode::DataMatrix::PNG;

use GD;
use Moose;
use Barcode::DataMatrix;
use Carp;

our $VERSION = '0.04';

has 'barcode', is=>'rw', default=>undef;
has 'data', is=>'rw', default=>undef;
has 'resolution', is=>'rw', default=>3;
has 'target', is=>'rw', default=>'stdout';

=head1 NAME

Barcode::DataMatrix::PNG - Generate PNG graphical representations of Data Matrix barcodes

=head1 SYNOPSIS

    use Barcode::DataMatrix::PNG;
    my $data = Barcode::DataMatrix::PNG->new->(barcode=>'test_barcode');
											# Minimal call for a new object.
	$data->encode();						# Encode the Barcode data.
	$data->render();						# Default:  Render the image to <STDOUT>
	$data->target = 'pass';					# C<return()> the image.
	my $barcode = $data->render();			# Return a PNG representation of a DataMatrix Barcode.
	my $my_barcode = $data->echo_barcode(); # Return a human-readable string of the encoded data.
	
	$data->barcode = "A new barcode.";		# To render a new barcode with the same object.
	$data->target = 'stdout';
	$data->encode();
	$data->render();						# etc.

=cut

=head1 DESCRIPTION

This class is used to create graphical representations of data matrix barcodes.  It is an extension of the Barcode::DataMatrix class.  
Potential applications include graphically oriented documents such as PDF, printable web documents, invoices, packing lists, shipping labels, etc....

=head1 METHODS

=head2 new (%attributes)

Minimal initiation of a barcode object is new(barcode=>"yourtext").  Options may be added via the C<%attributes> in any order.  

Default settings of output to C<STDOUT> with a resolution of 3 pixels will be used unless changed.

=cut

=head2 encode ()

Encode the barcode string into DataMatrix format.  An C<encode()> must be completed prior to rendering a barcode.

=cut

=head2 render ()

Render a PNG image of the created barcode.  The graphic will be rendered based on settings selected.

An exception may be thrown by foundation classes if they are unable to generate the barcode data or graphics.

=cut

=head2 echo_barcode()

Echo a human-readable representation of the barcode data stored in $this->{"barcode"}

=cut



sub encode { 
	my $self = shift;

	unless (defined $self->barcode) {
		croak("Barcode::DataMatrix::PNG : Barcode data string \$PNGobj->barcode is undefined.  Barcode contains no data.  Set \$PNGobj->barcode prior to \$PNGobj->encode().");
	}
	$self->data(new Barcode::DataMatrix->barcode($self->barcode));
}

sub render { 
	# Create PNG version of barcode 
	my $self = shift;

	unless (defined $self->data) {
		croak("Barcode::DataMatrix::PNG : Barcode matrix data \$PNGobj->data is undefined, barcode must \$PNGobj->encode() prior to \$PNGobj->render().");
	}

	my $dimension = @{$self->data->[0]}; # Width of image
	my $size = ($dimension * $self->resolution); # Size of image, pixel-resolution times width.

	my $img = new GD::Image($size,$size);
	# Render our PNG ; 
	my $white = $img->colorAllocate(255,255,255);
	my $black = $img->colorAllocate(0,0,0);
	$img->setAntiAliasedDontBlend($white);
	$img->setAntiAliasedDontBlend($black);
	# Allocate colors, Don't blend ; Use aliased colors. 
	$img->fill(0,0,$white);
	# Fill the background with white.
	my $x = 0;
	my $y = 0;

	unless ($self->target =~ /pass/i) {
		binmode STDOUT;
	}

	foreach (@{$self->data}) {
		foreach my $tn (@{$_}) {
			if ($tn == 1) {
				$img->filledRectangle($x,$y,($x + ($self->resolution - 1)),($y + ($self->resolution - 1)),$black);
				# Fill our 1s with black at a size of 'resolution' pixels.
			}
			$x = ($x + $self->resolution);
		}
		$x = 0;
		$y = ($y + $self->resolution);
	}
	if ($self->target =~ /pass/i) {
		# Return the png image.
		return ($img->png); 		
	} else {
		# Dump our image to STDOUT.
		print $img->png;
		return 1;
	}
}

sub echo_barcode {
	# Dump the text of the matrix.
	my $self = shift;
	return $self->barcode;
	# Useful for Human-readable string.
}

=head1 ATTRIBUTES

=head2 barcode

Ascii string data to be inserted into the barcode. 

=head2 resolution

The resolution (in pixels) of the barcode to be generated.   The default setting is C<3> pixels resolution.

=head2 target

Default output is C<stdout>.  Options are C<stdout> or C<pass>.  Pass will C<return()> the barcode PNG data for use.   

=cut

=head1 AUTHOR

Kasem Omary<< <kasemo@cpan.org> >> 

=head1 SOURCE REPOSITORY

L<https://github.com/KasemOmary/Barcode-DataMatrix-PNG>

=head1 SEE ALSO

=over 4

=item L<HTML::Barcode::DataMatrix>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 the AUTHORs listed above.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


no Any::Moose;
1;
