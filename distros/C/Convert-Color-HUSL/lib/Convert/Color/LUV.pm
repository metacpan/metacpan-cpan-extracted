package Convert::Color::LUV;

use 5.008009;
use strict;
use warnings;
use parent qw/Convert::Color/;

use Convert::Color::XYZ;

our $VERSION = '1.000';

use constant +{ ## no critic (Capitalization)
	KAPPA => (29/3) ** 3,
	EPS => (6/29) ** 3,

	REF_X => 3127/3290,
	REF_Z => 3583/3290,
};

use constant +{ ## no critic (Capitalization)
	REF_U => 4 * REF_X / (REF_X + 15 + 3 * REF_Z),
	REF_V => 9         / (REF_X + 15 + 3 * REF_Z),
};

__PACKAGE__->register_color_space('luv');

sub new {
	my ($class, $l, $u, $v) = @_;
	($l, $u, $v) = split /,/s, $l unless defined $u;
	bless [$l, $u, $v], $class
}

sub L { shift->[0] }
sub u { shift->[1] }
sub v { shift->[2] }

sub luv { @{$_[0]} }

sub _y_to_l {
	my ($y) = @_;
	$y <= EPS ? $y * KAPPA : 116 * ($y ** (1/3)) - 16
}

sub _l_to_y {
	my ($l) = @_;
	$l <= 8 ? $l / KAPPA : (($l + 16) / 116) ** 3
}

sub convert_to_xyz {
	my ($self) = @_;
	my ($l, $u, $v) = @$self;
	return Convert::Color::XYZ->new(0, 0, 0) unless $l;
	my $var_u = $u / (13 * $l) + REF_U;
	my $var_v = $v / (13 * $l) + REF_V;
	my $y = _l_to_y $l;
	my $x = 9 * $y * $var_u / (4 * $var_v);
	my $z = (9 * $y - (15 * $var_v * $y) - ($var_v * $x)) / (3 * $var_v);
	Convert::Color::XYZ->new($x, $y, $z)
}

sub new_from_xyz {
	my ($class, $xyz) = @_;
	my ($x, $y, $z) = @$xyz;
	my $l = _y_to_l $y;
	return $class->new(0, 0, 0) unless $l;
	my $var_u = (4 * $x) / ($x + 15 * $y + 3 * $z);
	my $var_v = (9 * $y) / ($x + 15 * $y + 3 * $z);
	my $u = 13 * $l * ($var_u - REF_U);
	my $v = 13 * $l * ($var_v - REF_V);
	$class->new($l, $u, $v)
}

sub rgb { shift->convert_to_xyz->rgb }
sub new_rgb { shift->new_from_xyz(Convert::Color::XYZ->new_rgb(@_)) }

1;
__END__

=encoding utf-8

=head1 NAME

Convert::Color::LUV - a color value in the CIE 1976 (L*, u*, v*) color space

=head1 SYNOPSIS

  use Convert::Color::LUV;
  my $red = Convert::Color::LUV->new(53.23711, 175.00982, 37.76509);
  my $green = Convert::Color::LUV->new('87.73552,-83.06712,107.41811');

  use Convert::Color;
  my $blue = Convert::Color->new('luv:32.30087,-9.40241,-130.35109');

  say $red->L; # 53.23711
  say $red->u; # 175.00982
  say $red->v; # 37.76509
  say join ',', $blue->luv; # 32.30087,-9.40241,-130.35109

=head1 DESCRIPTION

Objects of this class represent colors in the CIE 1976 (L*, u*, v*) color space.

Methods:

=over

=item Convert::Color::LUV->B<new>(I<$l>, I<$u>, I<$v>)

Construct a color from its components.

=item Convert::Color::LUV->B<new>(I<"$l,$u,$v">)

Construct a color from a string. The string should contain the three
components, separated by commas.

=item $luv->B<L>

=item $luv->B<u>

=item $luv->B<v>

Accessors for the three components of the color.

=item $luv->B<luv>

Returns the three components as a list.

=back

=head1 SEE ALSO

L<Convert::Color>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
