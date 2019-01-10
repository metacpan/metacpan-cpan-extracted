package Colouring::In;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.12';

our %TOOL;

BEGIN {
	%TOOL = (
		clamp => sub { return $TOOL{min}( $TOOL{max}( $_[0], 0 ), $_[1]); },
		max => sub { $_[ ($_[0] || 0) < ($_[1] || 0) ] || 0 },
		min => sub { $_[ ($_[0] || 0) > ($_[1] || 0) ] || 0 },
		round => sub {
			return sprintf '%.' . ( $_[1] // 0 ) . 'f', $_[0];
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
				? sprintf( '%.f2', (($n * $size) / 100 ))
				: return sprintf( "%d", $n );
		},
		convertColour => sub {
			my $colour	 = shift;
			my %converter = (
				'#'	=> 'hex2rgb',
				'rgb' => 'rgb2rgb',
				'hsl' => 'hsl2rgb',
				'hsv' => 'hsv2rgb',
			);
			my $reg = join '|', reverse sort keys %converter;
			if ( $colour =~ s/^($reg)// ) {
				return $TOOL{ $converter{$1} }($colour);
			}
			die 'Cannot convert the colour format';
		},
		rgb2rgb => sub {
			return $TOOL{numbers}(shift);
		},
		hex2rgb => sub {
			my $hex = shift;
			my $l = length $hex;
			return $l != 6
				? $l == 3
					? map { hex( $_ . $_ ) } $hex =~ m/./g
					: die 'hex length must be 3 or 6'
				: map { hex($_) } $hex =~ m/../g;
		},
		hsl2rgb => sub {
			my ( $h, $s, $l, $a, $m1, $m2 ) = $TOOL{numbers}(shift);

			$h = ( $h % 360 ) / 360;
			$s = $TOOL{depercent}($s);
			$l = $TOOL{depercent}($l);

			$m2 = $l <= 0.5 ? $l * ( $s + 1 ) : $l + $s - $l * $s;
			$m1 = $l * 2 - $m2;

			return (
				$TOOL{hue}( $h + 1 / 3, $m1, $m2 ) * 255,
				$TOOL{hue}( $h,			$m1, $m2 ) * 255,
				$TOOL{hue}( $h - 1 / 3, $m1, $m2 ) * 255,
				( defined $a ? $a : () ),
			);
		},
		numbers => sub {
			return ( $_[0] =~ m/([0-9]+)/g );
		},
		hsl => sub {
			my $colour = shift;
			if ( ref \$colour eq 'SCALAR' ) {
				$colour = Colouring::In->new($colour);
			}
			my $hsl = $colour->asHSL;
			return ( $hsl, $colour );
		},
		hash2array => sub {
			my $hash = shift;
			return map { $hash->{$_} } @_;
		},
	);
}

sub import {
       my ($pkg, @exports) = @_;
       my $caller = caller;

       if (scalar @exports) {
               no strict 'refs';
               *{"${caller}::${_}"} = \&{"${_[0]}::${_}"} foreach @exports;
               return;
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
	return $_[0]->hsla( $_[1], $_[2], $_[3], $_[4] );
}

sub hsla {
	my ( $self, $h, $s, $l, $a ) = @_;
	my ( $m1, $m2 );

	$h  = ( $h % 360 ) / 360;
	$m2 = $l <= 0.5 ? $l * ( $s + 1 ) : $l + $s - $l * $s;
	$m1 = $l * 2 - $m2;

	return $self->rgba(
		( $TOOL{hue}( $h + 1 / 3, $m1, $m2 ) * 255 ),
		( $TOOL{hue}( $h, $m1, $m2 ) * 255 ),
		( $TOOL{hue}( $h - 1 / 3, $m1, $m2 ) * 255 ),
		$a
	 );
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
	return ( $alpha != 1 ) ? $_[0]->toRGB($alpha) : $_[0]->toHEX( $_[2] );
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

sub asHSL {
	my ( $r, $g, $b, $max, $min, $d, $h, $s, $l ) = $TOOL{rgb2hs}( $_[0]->colour );

	$l = ( $max + $min ) / 2;
	if ( $max == $min ) {
		$h = $s = 0;
	}
	else {
		$s = $l > 0.5 ? $d / ( 2 - $max - $min ) : $d / ( $max + $min );
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

sub toHSL {
	my $hsl = $_[0]->asHSL;

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

	return $colour->hsla( $TOOL{hash2array}( $hsl, 'h', 's', 'l', 'a' ) );
}

sub colour {
	my @rgb = @{ $_[0]->{colour} };
	my $r = $rgb[0] // 255;
	my $g = $rgb[1] // 255;
	my $b = $rgb[2] // 255;
	return ( $r, $g, $b );
}

1;

__END__

=head1 NAME

Colouring::In - color or colour.

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Colouring::In;

	my $black = Colouring::In->new('#000000');

	$black->toHEX # #000
	$black->toHEX(1) # #000000
	$black->toRGB # rgb(0,0,0)
	$black->toRGBA # rgba(0,0,0,1)
	$black->toHSL # hsl(0,0%,0%)
	$black->toHSV # hsv(0,0%,0%)

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

=head1 SUBROUTINES/METHODS

=head2 new

=cut

=head2 rgb 

=cut

=head2 rgba

=cut

=head2 hsl

=cut

=head2 hsla

=cut

=head2 toCSS

=cut

=head2 toRGB

=cut

=head2 toRGBA

=cut

=head2 toHEX

=cut

=head2 asHSL

=cut

=head2 toHSL

=cut

=head2 toHSV

=cut

=head2 lighten

=cut

=head2 darken

=cut

=head2 fade

=cut

=head2 fadeout

=cut

=head2 fadein

=cut

=head2 colour

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
