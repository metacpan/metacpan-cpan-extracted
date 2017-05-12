package Convert::Color::XYZ;

use 5.008009;
use strict;
use warnings;
use parent qw/Convert::Color/;

use Convert::Color::RGB;
use List::Util qw/sum/;

our $VERSION = '1.000001';

use constant +{ ## no critic (Capitalization)
	MAT_R => [  3.2409699419045214,   -1.5373831775700935, -0.49861076029300328  ],
	MAT_G => [ -0.96924363628087983,   1.8759675015077207,  0.041555057407175613 ],
	MAT_B => [  0.055630079696993609, -0.20397695888897657, 1.0569715142428786   ],

	IMAT_X => [ 0.41239079926595948,  0.35758433938387796, 0.18048078840183429  ],
	IMAT_Y => [ 0.21263900587151036,  0.71516867876775593, 0.072192315360733715 ],
	IMAT_Z => [ 0.019330818715591851, 0.11919477979462599, 0.95053215224966058  ],
};

__PACKAGE__->register_color_space('xyz');

sub new {
	my ($class, $x, $y, $z) = @_;
	($x, $y, $z) = split /,/s, $x unless defined $y;
	bless [$x, $y, $z], $class
}

sub X { shift->[0] }
sub Y { shift->[1] }
sub Z { shift->[2] }

sub xyz { @{$_[0]} }

sub _dot_product {
	my ($x, $y) = @_;
	sum map { $x->[$_] * $y->[$_] } 0 .. $#{$x}
}

sub _from_linear {
	my ($c) = @_;
	$c <= 0.0031308 ? 12.92 * $c : 1.055 * $c ** (1 / 2.4) - 0.055
}

sub _to_linear {
	my ($c) = @_;
	$c <= 0.04045 ? $c / 12.92 : (($c + 0.055) / 1.055) ** 2.4
}

sub rgb {
	my ($self) = @_;
	map { _from_linear _dot_product $_, $self } MAT_R, MAT_G, MAT_B;
}

sub new_rgb {
	my $class = shift;
	my $vector = [map { _to_linear $_ } @_];
	$class->new(map { _dot_product $_, $vector } IMAT_X, IMAT_Y, IMAT_Z)
}

1;
__END__

=encoding utf-8

=head1 NAME

Convert::Color::XYZ - a color value in the CIE 1931 XYZ color space

=head1 SYNOPSIS

  use Convert::Color::XYZ;
  my $red = Convert::Color::XYZ->new(0.41239, 0.21264, 0.01933);
  my $green = Convert::Color::XYZ->new('0.35758,0.71517,0.11919');

  use Convert::Color;
  my $blue = Convert::Color->new('xyz:0.18048,0.07219,0.95053');

  say $red->X; # 0.41239
  say $red->Y; # 0.21264
  say $red->Z; # 0.01933
  say join ',', $blue->xyz; # 0.18048,0.07219,0.95053

=head1 DESCRIPTION

Objects of this class represent colors in the CIE 1931 XYZ color space.

Methods:

=over

=item Convert::Color::XYZ->B<new>(I<$x>, I<$y>, I<$z>)

Construct a color from its components.

=item Convert::Color::XYZ->B<new>(I<"$x,$y,$z">)

Construct a color from a string. The string should contain the three
components, separated by commas.

=item $xyz->B<X>

=item $xyz->B<Y>

=item $xyz->B<Z>

Accessors for the three components of the color.

=item $xyz->B<xyz>

Returns the three components as a list.

=back

=head1 SEE ALSO

L<Convert::Color>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
