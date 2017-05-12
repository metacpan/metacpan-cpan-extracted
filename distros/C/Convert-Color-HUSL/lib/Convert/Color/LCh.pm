package Convert::Color::LCh;

use 5.008009;
use strict;
use warnings;
use parent qw/Convert::Color/;

our $VERSION = '1.000';

use Convert::Color::LUV;
use Math::Trig ':pi';

__PACKAGE__->register_color_space('lch');

sub new {
	my ($class, $l, $c, $h) = @_;
	($l, $c, $h) = split /,/s, $l unless defined $c;
	bless [$l, $c, $h], $class
}

sub L { shift->[0] }
sub C { shift->[1] }
sub h { shift->[2] }

sub lch { @{$_[0]} }

sub convert_to_luv {
	my ($self) = @_;
	my ($l, $c, $h) = @$self;
	my $hrad = $h / 180 * pi;
	my $u = $c * cos $hrad;
	my $v = $c * sin $hrad;
	Convert::Color::LUV->new($l, $u, $v)
}

sub new_from_luv {
	my ($class, $luv) = @_;
	my ($l, $u, $v) = @$luv;
	my $c = sqrt $u * $u + $v * $v;
	return $class->new($l, $c, 0) if $c < 0.00000001;
	my $hrad = atan2 $v, $u;
	my $h = $hrad * 180 / pi;
	$h += 360 if $h < 0;
	$class->new($l, $c, $h)
}

sub rgb { shift->convert_to_luv->rgb }
sub new_rgb { shift->new_from_luv(Convert::Color::LUV->new_rgb(@_)) }

1;
__END__

=encoding utf-8

=head1 NAME

Convert::Color::LCh - a color value in the CIE LCh color space

=head1 SYNOPSIS

  use Convert::Color::LCh;
  my $red = Convert::Color::LCh->new(53.23712, 179.03810, 12.17705);
  my $green = Convert::Color::LCh->new('87.73552,135.78953,127.71501');

  use Convert::Color;
  my $blue = Convert::Color->new('lch:32.30087,130.68975,265.87432');

  say $red->L; # 53.23712
  say $red->C; # 179.03810
  say $red->h; # 12.17705
  say join ',', $blue->lch; # 32.30087,130.68975,265.87432

=head1 DESCRIPTION

Objects of this class represent colors in the CIE LCh color space.

Methods:

=over

=item Convert::Color::LCh->B<new>(I<$l>, I<$c>, I<$h>)

Construct a color from its components.

=item Convert::Color::LCh->B<new>(I<"$l,$c,$h">)

Construct a color from a string. The string should contain the three
components, separated by commas.

=item $lch->B<L>

=item $lch->B<C>

=item $lch->B<h>

Accessors for the three components of the color.

=item $lch->B<lch>

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
