package Color::Fade;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw (
	color_fade
	format_color
);

our @EXPORT = qw(
);

our $VERSION = '0.02';
our $debug = 0;

sub debug {
	my $val = shift;
	if ($val) {
		$debug = 1;
	}
	return $debug;
}

sub format_color {
	my ($format,@codes) = @_;

	# Some pre-defined formats.
	my %formats = (
		html => '<font color="$color">$char</font>',
		ubb  => '[color=$color]$char[/color]',
		css  => '<span style="color: $color">$char</span>',
	);
	if (exists $formats{$format}) {
		$format = $formats{$format};
	}

	# Loop through the given codes.
	my @out = ();
	foreach my $part (@codes) {
		my ($color,$char) = $part =~ /^<color ([^>]+?)>(.+?)$/i;
		my $result = $format;
		$result =~ s/\$color/$color/ig;
		$result =~ s/\$char/$char/ig;
		push (@out,$result);
	}
	return wantarray ? (@out) : join("",@out);
}

sub color_fade {
	my ($text,@in_colors) = @_;

	# Validate the arguments.
	if (not length $text) {
		warn "You must pass a string with a length > 0 to color_fade.";
		return;
	}
	if (not scalar(@in_colors)) {
		warn "You must pass a series of hexadecimal color codes to color_fade.";
		return;
	}

	# There must be at least two colors.
	if (scalar(@in_colors) < 2) {
		warn "color_fade requires at least two colors.";
		return;
	}

	# Validate and clean up color codes.
	my @nodes = ();
	foreach my $ccode (@in_colors) {
		$ccode =~ s/#//g; # Remove hex indicators.
		if (length $ccode != 6) {
			warn "You must pass 6 digit hexadecimal color codes to color_fade.";
			return;
		}
		if ($ccode =~ /^[^A-Fa-f0-9]$/i) {
			warn "You must pass 6 digit hexadecimal color codes to color_fade.";
			return;
		}
		push (@nodes,$ccode);
	}

	# Get the length of the string.
	my $len = length $text;

	# Divide the length into segments (number of colors - 1)
	my $sections = $len / (scalar(@nodes) - 1);
	if ($sections =~ /\./) {
		# If it was a decimal, add one and int it.
		$sections += 1;
	}
	$sections = int($sections);

	# If the length of a given segment of text is too great, no fading will
	# occur (for ex: 255-0-0 to 0-0-0 has a delta of -255 in the red. If the
	# length of this segment is >255 characters, 255/(>255) will result in
	# a fraction less than 1, so no per-character offset will be computed.
	# So, if the length of the segments is gonna be too long, double the
	# number of nodes...
	my $giveup = 0;
	while ($sections > 128) {
		my @newNodes = ();
		for (my $i = 0; $i < scalar(@nodes); $i++) {
			my $color = $nodes[$i];
			push (@newNodes,$color);

			# If we have another color after the one we're looping
			# on right now--good.
			if ($i < scalar(@nodes)) {
				my $neighbor = $nodes[$i + 1];
				$neighbor = $color unless defined $neighbor;

				# Find the average between these two colors.
				my $average = Color::Fade::average_colors($color,$neighbor);
				push (@newNodes,$average);
			}
		}
		(@nodes) = @newNodes;

		$sections = $len / (scalar(@nodes) - 1);
		if ($sections =~ /\./) {
			$sections += 1;
		}
		$sections = int($sections);
		$giveup++;
		if ($giveup > 100) {
			# After 100 tries to factor this down, let's just give up.
			last;
		}
	}

	# Split the string into individual characters.
	my @chars = split(//, $text);
	my @faded = ();

	print "Color::Fade: preparing to fade a string.\n"
		. "length of string:           $len\n"
		. "number of nodes (colors):   " . scalar(@nodes) . "\n"
		. "number of char per segment: $sections\n" if $debug;

	if ($giveup > 0) {
		print "Note: the input string was very long: a given\n"
			. "segment would be >128 characters in length, which\n"
			. "doesn't make for a good fade effect. It was factors\n"
			. "down $giveup times.\n" if $debug;
	}

	print "Color::Fade: beginning the segment loop\n" if $debug;

	my $nodeStart = 0;
	for (my $i = 0; $i < $len; $i += $sections) {
		# Find the length of this segment.
		my $seglen = ($i + $sections) - $i;

		# Separate the RGB components of the start and end colors.
		my (@RGB_Hex_Start) = $nodes[$nodeStart]     =~ /^(..)(..)(..)$/i; # /^([0-9A-Fa-f]{2}){3}$/i;
		my (@RGB_Hex_End)   = $nodes[$nodeStart + 1] =~ /^(..)(..)(..)$/i; # /^([0-9A-Fa-f]{2}){3}$/i;
		(@RGB_Hex_End) = (@RGB_Hex_Start) unless scalar(@RGB_Hex_End);

		# Convert hexadecimal to decimal.
		my @RGB_Dec_Start = (
			hex ("0x" . $RGB_Hex_Start[0]),
			hex ("0x" . $RGB_Hex_Start[1]),
			hex ("0x" . $RGB_Hex_Start[2]),
		);
		my @RGB_Dec_End = (
			hex ("0x" . $RGB_Hex_End[0]),
			hex ("0x" . $RGB_Hex_End[1]),
			hex ("0x" . $RGB_Hex_End[2]),
		);

		# Find the distances in Red/Green/Blue values.
		my $distR = $RGB_Dec_Start[0] - $RGB_Dec_End[0];
		my $distG = $RGB_Dec_Start[1] - $RGB_Dec_End[1];
		my $distB = $RGB_Dec_Start[2] - $RGB_Dec_End[2];

		$distR < 0 ? $distR = abs($distR) : $distR = -$distR;
		$distG < 0 ? $distG = abs($distG) : $distG = -$distG;
		$distB < 0 ? $distB = abs($distB) : $distB = -$distB;

		# Divide each distance by the length of this segment,
		# so we can find out how many characters to operate on.
		my $charsR = int($distR / $seglen);
		my $charsG = int($distG / $seglen);
		my $charsB = int($distB / $seglen);

		print "  Segment length: $seglen\n"
			. "  RGB Start: " . join("-",@RGB_Dec_Start) . "\n"
			. "  RGB End:   " . join("-",@RGB_Dec_End) . "\n"
			. "  RGB Delta: " . join(" : ",$distR,$distG,$distB) . "\n"
			. "  RGB Chars: " . join(" : ",$charsR,$charsG,$charsB) . "\n" if $debug;

		# For each character in this segment...
		my ($r,$g,$b) = @RGB_Dec_Start;
		for (my $c = $i; $c < ($i + $seglen); $c++) {
			next unless defined $chars[$c];
			print "    Working with character $chars[$c]\n" if $debug;

			# Convert each color value back into hex.
			my $hexR = sprintf ("%02x", $r);
			my $hexG = sprintf ("%02x", $g);
			my $hexB = sprintf ("%02x", $b);

			# Turn the hex values into a color code.
			my $code = join ("", $hexR, $hexG, $hexB);

			print "      Hex code: $code => $chars[$c]\n" if $debug;

			# Prepare an easy to parse color marker for this character.
			$chars[$c] = " " if $chars[$c] =~ /^[\x0d\x0a]$/;
			my $marker = "<color #" . $code . ">" . $chars[$c];

			# Append this color information to the output array.
			push (@faded,$marker);

			# Increment each color by charsR, charsG, and charsB at a time.
			$r += $charsR;
			$g += $charsG;
			$b += $charsB;

			# Keep the numbers within a valid range.
			$r = 0 if $r < 0;
			$g = 0 if $g < 0;
			$b = 0 if $b < 0;
			$r = 255 if $r > 255;
			$g = 255 if $g > 255;
			$b = 255 if $b > 255;

			print "    RGB for next char: $r-$g-$b\n" if $debug;
		}

		$nodeStart++;
	}

	return wantarray ? @faded : join ("",@faded);
}

sub average_colors {
	my ($alpha,$beta) = @_;

	# This function, given two hex colors, returns the value of the color
	# directly between the two colors (an average of two).

	# Separate the hex values.
	my (@hexStart) = $alpha =~ /^(..)(..)(..)$/i;
	my (@hexEnd)   = $beta  =~ /^(..)(..)(..)$/i;

	# Get their numeric counterparts.
	my @decStart = (
		hex("0x" . $hexStart[0]),
		hex("0x" . $hexStart[1]),
		hex("0x" . $hexStart[2]),
	);
	my @decEnd = (
		hex("0x" . $hexEnd[0]),
		hex("0x" . $hexEnd[1]),
		hex("0x" . $hexEnd[2]),
	);

	# Get the averages of each color.
	my $avRed = int( ($decStart[0] + $decEnd[0]) / 2 );
	my $avGrn = int( ($decStart[1] + $decEnd[1]) / 2 );
	my $avBlu = int( ($decStart[2] + $decEnd[2]) / 2 );

	# And convert the averages back into hex.
	my @hexAvg = (
		sprintf ("%02x", $avRed),
		sprintf ("%02x", $avGrn),
		sprintf ("%02x", $avBlu),
	);
	return join("",@hexAvg);
}

1;
__END__

=head1 NAME

Color::Fade - Perl extension for fading text colors.

=head1 SYNOPSIS

  use Color::Fade qw(color_fade format_color);

  print format_color ("html", color_fade (
    'Jackdaws love my big sphynx of quartz.',
    '#FF0000', '#00FF00', '#0000FF',
  ));

=head1 DESCRIPTION

Color::Fade uses mathematical formulas to take an input string of virtually any length,
and virtually any number of colors, and assign an individual color to each character to
fade between each of the input colors.

In other words, it makes your sentences look really pretty. :)

=head2 EXPORT

Exports color_fade and format_color on demand.

=head1 METHODS

=head2 color_fade ($string, @colors)

Fade C<$string> among the colors in C<@colors>, where C<$string> is a string of length
greater than zero, and C<@colors> is an array of colors in six byte hexadecimal format,
with or without the leading octothorpe. C<@colors> must have at least two elements.

When called in array context, the method returns an array in which each element is of
the format:

  <color #xxxxxx>y

For each character, where C<xxxxxx> is a hexadecimal color code and C<y> is one character
from the original string.

When called in scalar context, this array is joined before being returned.

B<Note:> It is perfectly possible to have more colors than you have characters in the
original string. All that will happen is that each character of output will have a color
from the original array, in the order the array was passed in, until there are no characters
left.

B<Debug mode:> To activate debug mode, set the global variable C<$Color::Fade::debug>
to a true value.

=head2 format_color ($format,@codes)

Formats the color data for display. C<$format> is a format to use and C<@colors>
is the B<array> you got from C<color_fade()>. C<$format> can either be a format
or a built-in name of a predefined format. If given as a format, use the placeholders
C<$color> and C<$char> as literals.

The pre-defined formats are:

  html   <font color="$color">$char</font>
  ubb    [color=$color]$char[/color]
  css    <span style="color: $color">$char</span>

Some examples:

  # Get an array of color codes.
  my @codes = color_fade ("Hello, world!", '#FF0000', '#0000FF');

  # Format it for HTML using the built-in format.
  my $html = format_color ('html', @codes);

  # Format it for AOL IM (meaning: no </font> tags allowed, as these mess
  # up the whole format of the IM message, at least as of AIM 5.9)
  my $aim = format_color ('<font color="$color">$char', @codes);

Having said that, the previous methods C<format_html>, C<format_ubb>,
C<format_css>, and C<format_aim> are now absolute.

=head2 average_colors ($color_a, $color_b) *Internal

This function is not exportable. Given two formatted hex colors (6 bytes and no
# symbol), it returns the hex code of the color directly in between them (or,
the average of 2). See L<"BUG TRACKER">.

=head1 SEE ALSO

I<Cuvou's Text Fader>, an online implementation of this module.
http://www.cuvou.com/wizards/fader.cgi

=head1 CHANGES

  0.02  Aug  1 2008
  - Major bugfix: If the input string was so massive and not enough colors were
    sent in with it, the length of a given segment of the string might've been
    greater than 255, meaning that the delta of a RGB value against the length
    of the segment would be a number less than 1. Long story short, the fading
    would fail miserably. This has been fixed by detecting segment lengths higher
    than 128 characters, and looping through the provided colors and adding more
    to the list. So if the provide colors are red and yellow, it would make the
    list contain (red, orange, yellow), and then (red, orange-red, orange,
    yellow-orange, yellow), until the length of a segment divided by the new
    color selection is less than 128 characters. If you send something so massive
    that it fails to factor it down 100 times, it gives up and continues.
  - Minor bugfix: I was using oct() instead of hex() to convert hex into
    decimal.

  0.01  Jan 29 2007
  - Initial release.

=head1 BUG TRACKER

Since this module was released in 2007, at least one large bug has been uncovered.
This section of the POD is for describing this bug.

The bug was encountered on my web-based text fader tool. Going through the HTTP
access logs I saw somebody format a very large chunk of text (or, the entire body
of an "About Me" section for a MySpace profile). They initially faded it among
6 rainbow colors and then against shades of blue (white, blue, black). Both
attempts looked terrible. Instead of actually fading the text from node to node,
the color would remain constant until the next node was reached. On the
white/blue/black one, 50% of the text was white and 50% was blue. The black node
was at the end of the string and was therefore never applied entirely to any
character.

The bug was a result of the length of a segment being 380 characters (or, the
input length was 1142, divided by 3 colors). The colors were extremes: white
(C<FFFFFF>), blue (C<0000FF>), and black (C<000000>). Therefore, the deltas
between each node were 255 on at least one of the red, green, or blue colors.
But since 380 is greater than 255, when it calculated how many shades it should
move for each character, it calculated a number less than 1, which got C<int>ed
down to zero. Thus, the first 380 characters were completely white, because it
was trying to subtract 0 from 255 for each color -- which doesn't do anything.
When the blue node hit, again, C<255 / 380> ints down to zero.

The way I fixed the bug was by adding a check to see if the length of the
segments is unreasonable. 255 is an extreme number which only affects extreme
colors, so I programmed the module around the number 128. If the length of
segments is greater than 128, it needs to add more colors to your provided
array and try again. So, for each pair of colors in your array, it inserts a
new color which is an average of the two around it. So if your initial array
was this:

  FFFFFF (white)
  0000FF (blue)
  000000 (black)

It would add these in:

     FFFFFF (white)
  -> 8080FF (light blue)
     0000FF (blue)
  -> 000080 (dark blue)
     000000 (black)

If the new array of colors can't divide up your string so that the length of a
segment is under 128 characters, it tries again. This process repeats until the
segment length is less than 128, or until it has tried more than 100 times to
factor it down. In the latter case, it stops trying and continues anyway,
knowing that your result won't look exactly how you expected it to.

Thus I've added C<average_colors> for calculating the average of two colors.

=head1 AUTHOR

Casey Kirsle, E<lt>casey at cuvou.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Casey Kirsle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
