package Convert::Color::HSLuv;

use 5.008009;
use strict;
use warnings;
use parent qw/Convert::Color/;

use Convert::Color::XYZ;
use Convert::Color::LUV;
use Convert::Color::LCh;
use List::Util qw/min/;
use Math::Trig qw/:pi/;

BEGIN {
	*MAT_R = *Convert::Color::XYZ::MAT_R;
	*MAT_G = *Convert::Color::XYZ::MAT_G;
	*MAT_B = *Convert::Color::XYZ::MAT_B;

	*KAPPA = *Convert::Color::LUV::KAPPA;
	*EPS   = *Convert::Color::LUV::EPS;
}

our $VERSION = '1.000001';

__PACKAGE__->register_color_space('hsluv');

sub new {
	my ($class, $h, $s, $l) = @_;
	($h, $s, $l) = split /,/s, $h unless defined $s;
	bless [$h, $s, $l], $class
}

sub H { shift->[0] }
sub S { shift->[1] }
sub L { shift->[2] }

sub hsl { @{$_[0]} }

sub _get_bounds {
	my ($l) = @_;
	my $sub1 = ($l + 16) ** 3 / 1_560_896;
	my $sub2 = $sub1 > EPS ? $sub1 : $l / KAPPA;
	my @ret;

	for (MAT_R, MAT_G, MAT_B) {
		my ($m1, $m2, $m3) = @$_;
		for (0, 1) {
			my $top1 = (284_517 * $m1 - 94_839 * $m3) * $sub2;
			my $top2 = (838_422 * $m3 + 769_860 * $m2 + 731_718 * $m1) * $l * $sub2 - 769_860 * $_ * $l;
			my $bottom = (632_260 * $m3 - 126_452 * $m2) * $sub2 + 126_452 * $_;
			push @ret, [$top1 / $bottom, $top2 / $bottom]
		}
	}

	@ret
}

sub _length_of_ray_until_intersect {
	my ($theta, $line) = @_;
	my ($m, $n) = @$line;
	my $len = $n / (sin ($theta) - $m * cos $theta);
	return if $len < 0;
	$len
}

sub max_chroma_for_lh {
	my ($self, $l, $h) = @_;
	my $hrad = $h / 180 * pi;
	min map {
		_length_of_ray_until_intersect $hrad, $_
	} _get_bounds $l;
}

sub convert_to_lch {
	my ($self) = @_;
	my ($h, $s, $l) = @$self;
	return Convert::Color::LCh->new(100, 0, $h) if $l > 99.9999999;
	return Convert::Color::LCh->new(0, 0, $h) if $l < 0.00000001;
	my $max = $self->max_chroma_for_lh($l, $h);
	my $c = $max / 100 * $s;
	Convert::Color::LCh->new($l, $c, $h)
}

sub new_from_lch {
	my ($class, $lch) = @_;
	my ($l, $c, $h) = @$lch;
	return $class->new($h, 0, 100) if $l > 99.9999999;
	return $class->new($h, 0, 0) if $l < 0.00000001;
	my $max = $class->max_chroma_for_lh($l, $h);
	my $s = $c / $max * 100;
	$class->new($h, $s, $l)
}

sub rgb { shift->convert_to_lch->rgb }
sub new_rgb { shift->new_from_lch(Convert::Color::LCh->new_rgb(@_)) }

1;
__END__

=encoding utf-8

=head1 NAME

Convert::Color::HSLuv - a color value in the HSLuv color space

=head1 SYNOPSIS

  use Convert::Color::HSLuv;
  my $red = Convert::Color::HSLuv->new(12.17705, 100, 53.23712);
  my $green = Convert::Color::HSLuv->new('127.71501,100,87.73552');

  use Convert::Color;
  my $blue = Convert::Color->new('hsluv:265.87432,100,32.30087');

  say $red->H; # 12.17705
  say $red->S; # 100
  say $red->L; # 53.23712
  say join ',', $blue->hsl; # 265.87432,100,32.30087

=head1 DESCRIPTION

Objects of this class represent colors in the HSLuv color space, revision 4.

Methods:

=over

=item Convert::Color::HSLuv->B<new>(I<$h>, I<$s>, I<$l>)

Construct a color from its components.

=item Convert::Color::HSLuv->B<new>(I<"$h,$s,$l">)

Construct a color from a string. The string should contain the three
components, separated by commas.

=item $hsluv->B<H>

=item $hsluv->B<S>

=item $hsluv->B<L>

Accessors for the three components of the color.

=item $hsluv->B<hsl>

Returns the three components as a list.

=back

=head1 SEE ALSO

L<Convert::Color>, L<http://www.hsluv.org/>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
