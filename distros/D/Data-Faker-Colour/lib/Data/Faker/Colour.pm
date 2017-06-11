package Data::Faker::Colour;

use 5.014000;
use strict;
use warnings;
use parent qw/Data::Faker/;
use Convert::Color::HSLuv;

our $VERSION = '0.001';

sub new { bless {}, shift } # Don't call superclass constructor

sub ir ($) { int rand $_[0] }

sub colour {
	shift; # drop $self
	my $cnt = shift // 1;
	my %args = @_;
	my @ret;

	for (1 .. $cnt) {
		push @ret, [ir 256, ir 256, ir 256]
	}

	wantarray ? @ret : $ret[0]
}

sub colour_hsluv {
	shift; # drop $self
	my @ret;
	my ($cnt, $ch, $cs, $cl) = @_;
	$cnt //= 1;
	$ch  //= -1;
	$cs  //= -1;
	$cl  //= -1;

	for (1 .. $cnt) {
		my ($h, $s, $l) = ($ch, $cs, $cl);
		$h = rand 360 if $h < 0;
		$s = rand 100 if $s < 0;
		$l = rand 100 if $l < 0;
		my @colour = Convert::Color::HSLuv->new($h, $s, $l)->rgb;
		for (@colour) {
			$_ = int (256 * $_);
			$_ = 0 if $_ < 0;
			$_ = 255 if $_ > 255;
		}
		push @ret, \@colour
	}

	wantarray ? @ret : $ret[0]
}

sub to_hex {
	my ($rgb) = @_;
	sprintf "#%02x%02x%02x", @$rgb
}

sub to_css {
	my ($rgb) = @_;
	sprintf 'rgb(%d,%d,%d)', @$rgb
}

sub colour_hex       { map { to_hex $_ } colour @_ }
sub colour_css       { map { to_css $_ } colour @_ }
sub colour_hsluv_hex { map { to_hex $_ } colour_hsluv @_ }
sub colour_hsluv_css { map { to_css $_ } colour_hsluv @_ }

BEGIN {
	*color           = *colour;
	*color_hsluv     = *colour_hsluv;
	*color_hex       = *colour_hex;
	*color_hsluv_hex = *colour_hsluv_hex;
	*color_css       = *colour_css;
	*color_hsluv_css = *colour_hsluv_css;

	for my $c (qw/colour color/) {
		__PACKAGE__->register_plugin(
			"${c}"           => \&colour,
			"${c}_hsluv"     => \&colour_hsluv,
			"${c}_hex"       => \&colour_hex,
			"${c}_hsluv_hex" => \&colour_hsluv_hex,
			"${c}_css"       => \&colour_css,
			"${c}_hsluv_css" => \&colour_hsluv_css,
		);
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Faker::Colour - Generate random colours

=head1 SYNOPSIS

  use Data::Faker::Colour;

  local $, = ' ';
  my $f = Data::Faker::Colour->new;
  say 'Random colour: ', $f->colour_hex;
  say 'Three random colours of 60% lightness: ',
      $f->colour_hsluv_hex(3, -1, -1, 60);
  say 'A colour with 70% saturation, in CSS format: ',
      $f->colour_hsluv_css(1, -1, 70);
  say '5 colours with hue 120 and lightness 45%: ',
      $f->colour_hsluv_hex(5, 150, -1, 45);

=head1 DESCRIPTION

This module is a plugin for Data::Faker for generating random colours.
It uses the HSLuv colour space to permit generation of colours with
specific hue, saturation, or lightness values. One use case would be
generating colour schemes.

It is recommended to use this without Data::Faker, as Data::Faker does
not currently pass arguments to methods.

=head1 DATA PROVIDERS

=over

=item B<colour>([I<$cnt>])

Generate I<$cnt> (default 1) random colours.
Returns a list of 3-element arrayrefs, representing the R, G, and B
components, each ranging 0-255.

=item B<colour_hex>([I<$cnt>])

As above, but returns a list of strings like C<#rrggbb>.

=item B<colour_css>([I<$cnt>])

As above, but returns a list of strings like C<rgb(r, g, b)>.

=item B<colour_hsluv>([I<$cnt>, I<$H>, I<$S>, I<$L>])

Generates I<$cnt> (default 1) random colours using the HSLuv colour
space. You can specify your desired hue, saturation and/or lightness,
and all generated colours will have that hue/saturation/lightness.

Set I<$H>, I<$S>, I<$L> to a positive value to request a specific
hue/saturation/lightness, or to -1 for a randomly chosen one. They all
default to -1.

=item B<colour_hsluv_hex>([I<$cnt>, I<$H>, I<$S>, I<$L>])

=item B<colour_hsluv_css>([I<$cnt>, I<$H>, I<$S>, I<$L>])

As above but with hex/css output.

=back

C<color> can be substituted for C<colour> in any of the methods above.

=head1 SEE ALSO

L<Data::Faker>, L<Convert::Colour>, L<Convert::Colour::HSLuv>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
