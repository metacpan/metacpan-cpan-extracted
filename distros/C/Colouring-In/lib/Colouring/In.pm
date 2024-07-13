package Colouring::In;

use 5.006;
use strict;
use warnings;
use smallnum;
our $VERSION = '0.26';

our (%TOOL, $ANOBJECT);

use overload 
	'""' => sub { $_[0]->toCSS() };


BEGIN {
	%TOOL = (
		clamp => sub { return $TOOL{min}( $TOOL{max}( $_[0], 0 ), $_[1]); },
		max => sub { $_[ ($_[0] || 0) < ($_[1] || 0) ] || 0 },
		min => sub { $_[ ($_[0] || 0) > ($_[1] || 0) ] || 0 },
		round => sub {
			return sprintf '%.' . ( defined $_[1] ? $_[1] : 0 ) . 'f', $_[0];
		},
		numIs => sub { return defined $_[0] && $_[0] =~ /^[0-9]+/; },
		percent => sub { return ( $_[0] * 100 ) . '%'; },
		depercent => sub { my $p = shift; $p =~ s/%$//; return $p / 100; },
		joinRgb => sub {
			return join ',', map { $TOOL{clamp}( $TOOL{round}($_), 255 ); } @_;
		},
		rgb2hs => sub {
			my @rgb = map { $_ / 255 } @_;
			push @rgb, $TOOL{max}( $TOOL{max}( $rgb[0], $rgb[1] ), $rgb[2] );
			push @rgb, $TOOL{min}( $TOOL{min}( $rgb[0], $rgb[1] ), $rgb[2] );
			push @rgb, ( $rgb[3] - $rgb[4] );
			return @rgb;
		},
		hue => sub {
			my ( $h, $m1, $m2 ) = @_;
			$h = $h < 0 ? $h + 1 : ( $h > 1 ? $h - 1 : $h );
			if ( $h * 6 < 1 ) { return $m1 + ( $m2 - $m1 ) * $h * 6; }
			elsif ( $h * 2 < 1 ) { return $m2; }
			elsif ( $h * 3 < 2 ) {
				return $m1 + ( $m2 - $m1 ) * ( 2 / 3 - $h ) * 6;
			}
			return $m1;
		},
		scaled => sub {
			my ( $n, $size ) = @_;
			return ( $n =~ s/%// )
				? sprintf( '%.f', (($n * $size) / 100 ))
				: return sprintf( "%d", $n );
		},
		convertColour => sub {
			my $colour	 = shift;
			my %converter = (
				'#'	=> 'hex2rgb',
				'rgb' => 'rgb2rgb',
				'hsl' => 'hsl2rgb',
				'hsla' => 'hsl2rgb',
			);
			my $reg = join '|', reverse sort keys %converter;
			if ( $colour =~ s/^($reg)// ) {
				return $TOOL{ $converter{$1} }($colour);
			}
			die $TOOL{MESSAGES}{INVALID_COLOUR} || 'Cannot convert the colour format';
		},
		rgb2rgb => sub {
			my @numbers = $TOOL{numbers}(shift);
			die $TOOL{MESSAGES}{INVALID_RGB} || 'Cannot convert rgb colour format' unless (scalar @numbers > 2);
			return @numbers;
		},
		hex2rgb => sub {
			my $hex = shift;
			my $l = length $hex;
			return $l != 6
				? $l == 3
					? map { my $h = hex( $_ . $_ ); $_ =~ 0 || $h ? $h : die( $TOOL{MESSAGES}{INVALID_HEX} || 'Cannot convert hex colour format' ) } $hex =~ m/./g
					: die 'hex length must be 3 or 6'
				: map { my $h = hex( $_ ); $_ =~ m/00/ || $h ? $h : die( $TOOL{MESSAGES}{INVALID_HEX} || 'Cannot convert hex colour format' ) } $hex =~ m/../g;
		},
		hsl2rgb => sub {
			my ( $h, $s, $l, $a, $m1, $m2 ) = scalar @_ > 1 ? @_ : $TOOL{numbers}(shift);
			defined $_ && $_ =~ m/([0-9.]+)/ or die $TOOL{MESSAGES}{INVALID_HSL} || 'Cannot convert hsl colour format' for ($h, $s, $l);
			$h = ( $h % 360 ) / 360;
			unless ($m1) {
				$s = $TOOL{depercent}($s);
				$l = $TOOL{depercent}($l);
			}
			$m2 = $l <= 0.5 ? $l * ( $s + 1 ) : $l + $s - $l * $s;
			$m1 = $l * 2 - $m2;
			return (
				($TOOL{clamp}($TOOL{hue}( $h + 1 / 3, $m1, $m2 ), 1) * 255),
				($TOOL{clamp}($TOOL{hue}( $h,			$m1, $m2 ), 1) * 255),
				($TOOL{clamp}($TOOL{hue}( $h - 1 / 3, $m1, $m2 ), 1) * 255),
				( defined $a ? $a : () ),
			);
		},
		numbers => sub {
			return ( $_[0] =~ m/([0-9.]+)/g );
		},
		hsl => sub {
			my $colour = shift;
			if ( ref \$colour eq 'SCALAR' ) {
				$colour = Colouring::In->new($colour);
			}
			my $hsl = $TOOL{asHSL}($colour);
			return ( $hsl, $colour );
		},
		hash2array => sub {
			my $hash = shift;
			return map { $hash->{$_} } @_;
		},
		asHSL => sub {
			my ( $r, $g, $b, $max, $min, $d, $h, $s, $l ) = $TOOL{rgb2hs}( $_[0]->colour );

			$l = ( $max + $min ) / 2;
			if ( $max == $min ) {
				$h = $s = 0;
			}
			else {
				$d = smallnum::_smallnum($d); #grrr
				$s = $l > 0.5 ? ($d / ( 2 - $max - $min )) : ($d / ( $max + $min ));
				$h = ( $max == $r )
					? ( $g - $b ) / $d + ( $g < $b ? 6 : 0 )
					: ( $max == $g )
							? ( $b - $r ) / $d + +2
							: ( $r - $g ) / $d + 4;
				$h /= 6;
			}

			return {
				h => $h * 360,
				s => $s,
				l => $l,
				a => $_[0]->{alpha},
			};
		}
	);
}

sub import {
	my ($pkg, @exports) = @_;
	my $caller = caller;
	$TOOL{MESSAGES} = pop @exports if (ref $exports[-1] eq 'HASH');
	if (scalar @exports) {
		no strict 'refs';
		*{"${caller}::${_}"} = \&{"${_[0]}::${_}"} foreach @exports;
	}
}

sub rgb {
	return $_[0]->rgba( $_[1], $_[2], $_[3], $_[4] );
}

sub rgba {
	my $rgb = [ map { $TOOL{scaled}( $_, 255 ) } ( $_[1], $_[2], $_[3] ) ];
	return Colouring::In->new( $rgb, $TOOL{clamp}($_[4], 1) );
}

sub hsl {
	my $self = shift;
	return $self->rgba($TOOL{hsl2rgb}(@_, 1));
}

sub hsla {
	my $self = shift;
	return $self->rgba($TOOL{hsl2rgb}(@_, 1));
}

sub new {
	my ( $pkg, $rgb, $a ) = @_;

	my $self = bless {}, $pkg;
	# The end goal here, is to parse the arguments
	# into an integer triplet, such as `128, 255, 0`
	if ( ref $rgb eq 'ARRAY' ) {
		scalar @$rgb == 4 and $a = pop @$rgb;
		$self->{colour} = $rgb;
	} else {
		$self->{colour} = [ $TOOL{convertColour}($rgb) ];
		scalar @{ $self->{colour} } == 4 and $a = pop @{$self->{colour}};
	}
	$self->{alpha} = $TOOL{numIs}($a) ? $a : 1;
	return $self;
}

sub toCSS {
	my $alpha = $TOOL{round}( $_[0]->{alpha}, $_[1] );
	return ( $alpha != 1 ) ? $_[0]->toRGBA() : $_[0]->toHEX( $_[2] );
}

sub toTerm {
	return sprintf( "r%sg%sb%s", $_[0]->colour );
}

sub toOnTerm {
	return sprintf( "on_r%sg%sb%s", $_[0]->colour );
}

sub toRGB {
	return $_[0]->toRGBA( $_[1] ) if $TOOL{numIs}( $_[1] ) and $_[1] != 1;
	return sprintf( 'rgb(%s)', ( $TOOL{joinRgb}( $_[0]->colour ) ) );
}

sub toRGBA {
	return sprintf 'rgba(%s,%s)', $TOOL{joinRgb}( $_[0]->colour ),
		$_[0]->{alpha};
}

sub toHEX {
	my $colour = sprintf(
		"#%02lx%02lx%02lx",
		(
			map { my $c = $TOOL{clamp}( $TOOL{round}($_), 255 ); $c }
				$_[0]->colour
		)
	);
	unless ( $_[1] ) {
		if ( $colour =~ /#(.)\1(.)\2(.)\3/g ) {
			$colour = sprintf "#%s%s%s", $1, $2, $3;
		}
	}
	return $colour;
}

sub toHSL {
	my $hsl = $TOOL{asHSL}($_[0]);
	sprintf( "hsl(%s,%s,%s)",
		$hsl->{h},
		$TOOL{percent}( $hsl->{s} ),
		$TOOL{percent}( $hsl->{l} ),
	);
}

sub toHSV {
	 my ( $r, $g, $b, $max, $min, $d, $h, $s, $v ) = $TOOL{rgb2hs}( $_[0]->colour );

	 $v = $max;
	 $s = ( $max == 0 ) ? $max : $d / $max;

	 if ( $max == $min ) {
		  $h = 0;
	 }
	 else {
		  $h = ( $max == $r ) ? ( $g - $b ) / $d + ( $g < $b ? 6 : 0 )
			 : ( $max == $g ) ? ( $b - $r ) / $d + 2
			 : ( $r - $g ) / $d + 4;
		  $h /= 6;
	 }

	 return sprintf( "hsv(%s,%s,%s)",
		( $h * 360 ),
		$TOOL{percent}($s),
		$TOOL{percent}($v),
	);
}

sub lighten {
	my ( $colour, $amt, $meth, $hsl ) = @_;

	( $hsl, $colour ) = $TOOL{hsl}($colour);

	$amt = $TOOL{depercent}($amt);
	$hsl->{l} += $TOOL{clamp}(
		( $meth && $meth eq 'relative' )
			? (($hsl->{l} || 1) * $amt)
			: $amt, 1
	);

	return $colour->hsla( $TOOL{hash2array}( $hsl, 'h', 's', 'l', 'a' ) );
}

sub darken {
	my ( $colour, $amt, $meth, $hsl ) = @_;

	( $hsl, $colour ) = $TOOL{hsl}($colour);

	$amt = $TOOL{depercent}($amt);
	$hsl->{l} -= $TOOL{clamp}(
		( $meth && $meth eq 'relative' )
			? $hsl->{l} * $amt
			: $amt, 1,
	);

	return $colour->hsla( $TOOL{hash2array}( $hsl, 'h', 's', 'l', 'a' ) );
}

sub fade {
	my ($colour, $amt, $hsl) = @_;

	($hsl, $colour) = $TOOL{hsl}($colour);
	$hsl->{a} = $TOOL{depercent}($amt);

	return $colour->hsla( $TOOL{hash2array}( $hsl, 'h', 's', 'l', 'a' ) );
}

sub fadeout {
	my ($colour, $amt, $meth, $hsl) = @_;

	($hsl, $colour) = $TOOL{hsl}($colour);
	$hsl->{a} -= (($meth && $meth eq 'relative')
		? $hsl->{a} * $TOOL{depercent}($amt)
 		: $TOOL{depercent}($amt));
	return $colour->hsla( $TOOL{hash2array}( $hsl, 'h', 's', 'l', 'a' ) );
}

sub fadein {
	my ($colour, $amt, $meth, $hsl) = @_;
	($hsl, $colour) = $TOOL{hsl}($colour);
	$hsl->{a} += ($meth && $meth eq 'relative')
		? $hsl->{a} * $TOOL{depercent}($amt)
 		: $TOOL{depercent}($amt);
	$hsl->{a} = smallnum::_smallnum($hsl->{a});
	return $colour->hsla( $TOOL{hash2array}( $hsl, 'h', 's', 'l', 'a' ) );
}

sub mix {
	my ($colour1, $colour2, $weight) = @_;
	my ($h1, $c1, $h2, $c2) = ($TOOL{hsl}($colour1), $TOOL{hsl}($colour2));
	$weight = ($weight || 50) / 100;
	my $a = $h1->{a} - $h2->{a};
	my $w = ($weight * 2) - 1;
	my $w1 = ((($w * $a == -1) ? $w : ($w + $a) / (1 + $w * $a)) + 1) / 2;
	my $w2 = 1 - $w1;
	return Colouring::In->new([ 
		($c1->{colour}[0] * $w1) + ($c2->{colour}[0] * $w2),
		($c1->{colour}[1] * $w1) + ($c2->{colour}[1] * $w2),
		($c1->{colour}[2] * $w1) + ($c2->{colour}[2] * $w2),
		($c1->{alpha} * $weight) + ($c2->{alpha} * 1 - $weight)
	]);
}

sub tint {
	my ($colour, $weight) = @_;
	mix(
		'rgb(255,255,255)',
		$colour,
		$weight
	);
}

sub shade {
	my ($colour, $weight) = @_;
	mix(
		'rgb(0, 0, 0)',
		$colour,
		$weight
	);
}

sub saturate {
	my ($colour, $amt, $meth) = @_;
	my ($h1, $c1) = $TOOL{hsl}($colour);
	$amt = $TOOL{depercent}($amt);
	$h1->{s} += $TOOL{clamp}(
		( $meth && $meth eq 'relative' )
			? $h1->{s} * $amt
			: $amt, 1,
	);
	return $c1->hsla( $TOOL{hash2array}( $h1, 'h', 's', 'l', 'a' ) );
}

sub desaturate {
	my ($colour, $amt, $meth) = @_;
	my ($h1, $c1) = $TOOL{hsl}($colour);
	$amt = $TOOL{depercent}($amt);
	$h1->{s} -= $TOOL{clamp}(
		( $meth && $meth eq 'relative' )
			? $h1->{s} * $amt
			: $amt, 1,
	);
	return $c1->hsla( $TOOL{hash2array}( $h1, 'h', 's', 'l', 'a' ) );
}

sub greyscale {
	my ($colour) = @_;
	desaturate($colour, 100);
}

sub colour {
	my @rgb = @{ $_[0]->{colour} };
	my $r = defined $rgb[0] ? $rgb[0] : 255;
	my $g = defined $rgb[1] ? $rgb[1] : 255;
	my $b = defined $rgb[2] ? $rgb[2] : 255;
	return ( $r, $g, $b );
}

sub validate {
	my ($self, $colour) = @_;
	my $new = eval { $self->new($colour) };
	if ($@) {
		return {
			valid => \0,
			message => $TOOL{MESSAGES}{VALIDATE_ERROR} || 'The string passed to Colouring::In::validate is not a valid color.',
			color => $colour
		};
	}
	return {
		valid => \1,
		message => $TOOL{MESSAGES}{VALIDATE} || 'The string passed to Colouring::In::validate is a valid color',
		color => $colour,
		colour => $new
	};
}

1;

__END__

=head1 NAME

Colouring::In - color or colour.

=head1 VERSION

Version 0.26

=cut

=head1 SYNOPSIS

	use Colouring::In;

	my $black = Colouring::In->new('#000000');

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

	use Colouring::In qw/lighten darken/;

	my $white = lighten('#000', '100%');
	my $black = darken('#fff', '100%');

	my $transparent = fade('#fff', '0%');
	my $transparent = fadeout('#fff', '100%');

	my $colour = fadein('rgba(125,125,125,0'), '100%');

=head1 Instantiate

=cut

=head2 new

Instantiate an Colouring::In Object using a supported colour formated string or RGBA array reference.

	my $colour = Colouring::In->new('hsla(0, 0%, 100%, 0.3)');
	my $colour = Colouring::In->new([255, 255, 255, 0.3]);

=cut

=head2 rgb

Instantiate an Colouring::In Object opaque colour from decimal red, green and blue (RGB) values.

	my $colour = Colouring::In->rgb(0, 0, 0);

=cut

=head2 rgba

Instantiate an Colouring::In Object transparent colour from decimal red, green, blue and alpha (RGBA) values.

	my $colour = Colouring::In->rgb(0, 0, 0, 0.5);

=cut

=head2 hsl

Instantiate an Colouring::In Object opaque colour from hue, saturation and lightness (HSL) values.

	my $colour = Colouring::In->hsl(0, 0%, 100%);
=cut

=head2 hsla

Instantiate an Colouring::In Object tranparent colour from hue, saturation, lightness and alpha (HSLA) values.

	my $colour = Colouring::In->hsla(0, 0%, 100%, 1);

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

This method is called on stringification of a Colouring::In Object.

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

	my $string = $colour->toCSS;

=head2 toOnTerm

Returns an opaque colour string from decimal red, green and blue (RGB) values 
valid for Term::ANSIColor background content.

	my $string = $colour->toCSS;

=head2 colour

Returns an array containeing the red, green and blue (RGB) values.

	my $string = $colour->colour;

=cut

=head2 validate

Validate that the passed colour is a color.

	my $valid = $colour->validate('#abc'); # valid
	my $invalid = $colour->validate('#xyz'); # invalid

=cut

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-colouring-in at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Colouring-In>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	 perldoc Colouring::In

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Colouring-In>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Colouring-In>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Colouring-In>

=item * Search CPAN

L<http://search.cpan.org/dist/Colouring-In/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Colouring::In
