package Convert::Color::HUSLp;

use 5.008009;
use strict;
use warnings;
use parent qw/Convert::Color::HUSL/;

use Convert::Color::XYZ;
use Convert::Color::LUV;
use Convert::Color::LCh;
use List::Util qw/min/;
use Math::Trig qw/:pi/;

BEGIN {
	*_get_bounds = *Convert::Color::HUSL::_get_bounds; ## no critic (ProtectPrivate)
}

our $VERSION = '1.000';

__PACKAGE__->register_color_space('huslp');

sub _intersect_line_line {
	my ($l1, $l2) = @_;
	($l1->[1] - $l2->[1]) / ($l2->[0] - $l1->[0])
}

sub _distance_from_pole {
	my ($x, $y) = @_;
	sqrt $x * $x + $y * $y
}

sub max_chroma_for_lh {
	my ($self, $l) = @_;
	min map {
		my ($m, $n) = @$_;
		my $x = _intersect_line_line $_, [-1 / $m, 0];
		_distance_from_pole $x, $n + $x * $m
	} _get_bounds $l
}

1;
__END__

=encoding utf-8

=head1 NAME

Convert::Color::HUSLp - a color value in the HUSLp color space

=head1 SYNOPSIS

  use Convert::Color::HUSLp;
  my $reddish = Convert::Color::HUSLp->new(12.17705, 100, 53.23712);
  my $greenish = Convert::Color::HUSLp->new('127.71501,100,87.73552');

  use Convert::Color;
  my $bluish = Convert::Color->new('huslp:265.87432,100,32.30087');

  say $reddish->H; # 12.17705
  say $reddish->S; # 100
  say $reddish->L; # 53.23712
  say join ',', $bluish->hsl; # 265.87432,100,32.30087

=head1 DESCRIPTION

Objects of this class represent colors in the HUSLp color space, revision 4.

Methods:

=over

=item Convert::Color::HUSLp->B<new>(I<$h>, I<$s>, I<$l>)

Construct a color from its components.

=item Convert::Color::HUSLp->B<new>(I<"$h,$s,$l">)

Construct a color from a string. The string should contain the three
components, separated by commas.

=item $huslp->B<H>

=item $huslp->B<S>

=item $huslp->B<L>

Accessors for the three components of the color.

=item $huslp->B<hsl>

Returns the three components as a list.

=back

=head1 SEE ALSO

L<Convert::Color>, L<http://www.husl-colors.org/>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
