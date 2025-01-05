package Ascii::Text::Image;

use 5.006;
use strict;
use warnings;

use Types::Standard qw/HashRef Int Str/;
use Imager;
use Imager::Color;
use Imager::Font;

our $VERSION = '0.04';

use Rope;
use Rope::Autoload;

extends 'Ascii::Text';

property padding => (
	initable => 1,
	writeable => 1,
	type => Int,
	value => 10,
);

property imager_font => (
	initable => 1,
	writeable => 1,
	required => 1,
	type => Str,
);

property color_map => (
	initablie => 1,
	writeable => 1,
	type => HashRef,
	builder => sub {
		return {
			black => Imager::Color->new(0,0,0),
			red => Imager::Color->new(255, 0, 0),
			green => Imager::Color->new(0, 255, 0),
			yellow => Imager::Color->new(255, 255, 0),
			blue => Imager::Color->new(0, 0, 255),
			magenta => Imager::Color->new(255, 0, 255),
			cyan => Imager::Color->new(0, 255, 255),
			white => Imager::Color->new(255, 255, 255),
			bright_black => Imager::Color->new(100,100,100),
			bright_red => Imager::Color->new(255, 100, 100),
			bright_green => Imager::Color->new(100, 255, 100),
			bright_yellow => Imager::Color->new(255, 255, 100),
			bright_blue => Imager::Color->new(100, 100, 255),
			bright_magenta => Imager::Color->new(255, 100, 255),
			bright_cyan => Imager::Color->new(100, 255, 255),
			bright_white => Imager::Color->new(255, 255, 255),
		}
	}
);

around render => sub {
	my ($self, $cb, $text, $file, $wrap) = @_;

	my $color = $self->color;
	$self->color = "";
	my $lines = [];
	$cb->($text, $lines);
	if ($wrap) {
		$lines = [ grep {
			$_ !~ m/^\s+$/
		} @{$lines} ];
	}
	
	$self->color = $color || "black";
	my $font = Imager::Font->new(
		file => $self->imager_font,
		color => $self->color_map->{$self->color}
	);

	my $bbox = $font->bounding_box(string => [grep { $_ !~ m/^[\s]+$/ } @{$lines}]->[0]);

	my $out = Imager->new(
		xsize => $bbox->total_width + ($self->padding * 2),
		ysize => ($bbox->font_height * scalar @{$lines}) + ($self->padding * 2),
		channels => 4
	);

	my $y = $self->padding + ($bbox->font_height * 0.66);

	for my $line (@{$lines}) {
		$out->string(
			string => $line,
			x => $self->padding,
			y => $y,
			font => $font
		);
		$y += $bbox->font_height;
	}

	$out->write(file => $file) or die $out->errstr;

	return $lines;
};

1;

__END__

=head1 NAME

Ascii::Text::Image - module for generating images using ASCII text.

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use Ascii::Text::Image;

	my $ascii = Ascii::Text::Image->new(
		imager_font => 'path/to/RobotoMono.ttf',
		color => 'green',
		font => 'Poison'
	);

	$ascii->("Hello World", "test.png");

	...

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Ascii::Text::Image object.

	my $ascii = Ascii::Text::Image->new(
		imager_font => 'path/to/RobotoMono.ttf',
		padding => 100,
	);

see L<Ascii::Text> documentation for inheritance.

=head1 ATTRIBUTES

=head2 padding

set/get padding for the image.

	$ascii->padding(10);

=head2 imager_font

set/get imager ttf font.

	$ascii->imager_font('path/to/RobotoMono.ttf');

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii-text-image at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Image>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Image

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Image>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Image>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Image>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Ascii::Text::Image
