package Colouring::In::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Colouring::In::XS', $VERSION);

sub import {
        my ($pkg, @exports) = @_;
        my $caller = caller;
        set_messages(pop @exports) if (ref $exports[-1] eq 'HASH');
        if (scalar @exports) {
                no strict 'refs';
                *{"${caller}::${_}"} = \&{"${_[0]}::${_}"} foreach @exports;
        }
}

sub validate {
	my ($self, $colour) = @_;
	my $new = eval { $self->new($colour) };
	if ($@) {
		return {
			valid => \0,
			message => get_message('VALIDATE_ERROR') || 'The string passed to Colouring::In::XS::validate is not a valid color.',
			color => $colour
		};
	}
	return {
		valid => \1,
		message => get_message('VALIDATE') || 'The string passed to Colouring::In::XS::validate is a valid color',
		color => $colour,
		colour => $new
	};
}

1;

__END__

=head1 NAME

Colouring::In::XS - color or colour.

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use Colouring::In::XS;

	my $black = Colouring::In::XS->new('#000000');

	$black->toHEX # #000
	$black->toHEX(1) # #000000
	$black->toRGB # rgb(0,0,0)
	$black->toRGBA # rgba(0,0,0,1)
	$black->toHSL # hsl(0,0%,0%)
	$black->toHSV # hsv(0,0%,0%)
	$black->toTerm # r0g0b0
	$black->toOnTerm # on_r0g0b0

	my $white = $black->lighten('100%');
	my $black = $white->darken('100%');

	my $transparent = $black->fadeout('100%');
	$black = $transparent->fadein('100%');

	...

	use Colouring::In::XS qw/lighten darken/;

	my $white = lighten('#000', '100%');
	my $black = darken('#fff', '100%');

	my $transparent = fade('#fff', '0%');
	my $transparent = fadeout('#fff', '100%');

	my $colour = fadein('rgba(125,125,125,0'), '100%');

=head1 Instantiate

=cut

=head2 new

Instantiate an Colouring::In::XS Object using a supported colour formated string or RGBA array reference.

	my $colour = Colouring::In::XS->new('hsla(0, 0%, 100%, 0.3)');
	my $colour = Colouring::In::XS->new([255, 255, 255, 0.3]);

=cut

=head2 rgb

Instantiate an Colouring::In::XS Object opaque colour from decimal red, green and blue (RGB) values.

	my $colour = Colouring::In::XS->rgb(0, 0, 0);

=cut

=head2 rgba

Instantiate an Colouring::In::XS Object transparent colour from decimal red, green, blue and alpha (RGBA) values.

	my $colour = Colouring::In::XS->rgb(0, 0, 0, 0.5);

=cut

=head2 hsl

Instantiate an Colouring::In::XS Object opaque colour from hue, saturation and lightness (HSL) values.

	my $colour = Colouring::In::XS->hsl(0, 0%, 100%);
=cut

=head2 hsla

Instantiate an Colouring::In::XS Object tranparent colour from hue, saturation, lightness and alpha (HSLA) values.

	my $colour = Colouring::In::XS->hsla(0, 0%, 100%, 1);

=cut

=head1 Methods

=cut

=head2 mix

Mix two colours.

	my $mix = $colour->mix('rgb(255, 255, 255)', 'rgb(0, 0, 0)', $weight);

=cut

=head2 lighten

Increase the lightness of the colour.

	my $lighter = $colour->lighten('50%');

=cut

=head2 darken

Decrease the lightness of the colour.

	my $darken = $colour->darken('50%');

=cut

=head2 fade

Set the absolute opacity of the colour.

	my $fade = $colour->fade('50%');

=cut

=head2 fadeout

Decrease the opacity of the colour.

	my $fadeout = $colour->fadeout('10%');

=cut

=head2 fadein

Increase the opacity of the colour.

	my $fadein = $colour->fadein('5%');

=head2 tint

Apply a tint to the colour.

	my $tint = $colour->tint('rgb(255, 0, 0)');

	my $tint = $colour->tint('rgb(255, 0, 0)', $weight);

=cut

=head2 shade

Apply a shade to the colour.

	my $shade = $colour->shade('rgb(255, 0, 0)');

	my $shade = $colour->shade('rgb(255, 0, 0)', $weight);

=head2 saturate

Increase the saturation of the colour.

	my $saturate = $colour->saturate('rgb(255, 255, 255)', '50%');

=head2 desaturate

Decrease the saturation of a color.

	my $desaturate = $colour->desaturate('rgb(255, 0, 0)', '50%');

=cut

=head2 greyscale

Remove all saturation from a color.

	my $grey = $colour->greyscale('rgb(255, 0, 0)');

=head2 toCSS

Returns either an rgba or hex colour string based on whether the alpha value is set.

	my $string = $colour->toCSS;

This method is called on stringification of a Colouring::In::XS Object.

=cut

=head2 toRGB

Returns an opaque colour string from decimal red, green and blue (RGB) values.

	my $string = $colour->toCSS;

=cut

=head2 toRGBA

Returns an transparent colour string from decimal red, green, blue and alpha (RGBA) values.

	my $string = $colour->toRGBA;

=cut

=head2 toHEX

Returns an opaque colour string from decimal red, green and blue (RGB) values.

	my $string = $colour->toHEX;

=cut

=head2 toHSL

Returns an opaque colour string from hue, saturation and lightness (HSL) values.

	my $string = $colour->toHSL;

=cut

=head2 toHSV

Returns an opaque colour string from hue, saturation and value (HSV) values.

	my $string = $colour->toHSV;

=cut

=head2 toTerm

Returns an opaque colour string from decimal red, green and blue (RGB) values
valid for Term::ANSIColor foreground content.

	my $string = $colour->toTerm;

=head2 toOnTerm

Returns an opaque colour string from decimal red, green and blue (RGB) values
valid for Term::ANSIColor background content.

	my $string = $colour->toOnTerm;

=head2 colour

Returns an array containeing the red, green and blue (RGB) values.

	my $string = $colour->colour;

=cut

=head2 validate

Validate that the passed colour is a color.

	my $valid = $colour->validate('#abc'); # valid
	my $invalid = $colour->validate('#xyz'); # invalid

=cut

=head1 BENCHMARK

	use Benchmark qw(:all);
	use Colouring::In;
	use Colouring::In::XS;

	timethese(1000000, {
		'Colouring::In' => sub {
			my $start = '#ffffff';
			my $colour = Colouring::In->new($start);
			$colour->toRGB();
		},
		'XS' => sub {
			my $start = '#ffffff';
			my $colour = Colouring::In::XS->new($start);
			$colour->toRGB();
		}
	});

...

	Benchmark: timing 1000000 iterations of Colouring::In, XS...
	Colouring::In: 13 wallclock secs (12.36 usr +  0.00 sys = 12.36 CPU) @ 80906.15/s (n=1000000)
		XS:  0 wallclock secs ( 0.59 usr +  0.01 sys =  0.60 CPU) @ 1666666.67/s (n=1000000)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-colouring-in-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Colouring-In-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Colouring::In::XS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Colouring-In-XS>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Colouring-In-XS>

=item * Search CPAN

L<https://metacpan.org/release/Colouring-In-XS>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Colouring::In::XS
