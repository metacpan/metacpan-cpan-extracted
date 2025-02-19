package ANSI::Palette;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.05';
use base 'Import::Export';

our %EX = (
	reset => [qw/all/],
	palette_8 => [qw/all/],
	palette_16 => [qw/all/],
	palette_256 => [qw/all/],
	text_8 => [qw/all text ansi_8/],
	text_16 => [qw/all text ansi_16/],
	text_256 => [qw/all text ansi_256/],
	bold_8 => [qw/all bold ansi_8/],
	bold_16 => [qw/all bold ansi_16/],
	bold_256 => [qw/all bold ansi_256/],
	underline_8 => [qw/all underline ansi_8/],
	underline_16 => [qw/all underline ansi_16/],
	underline_256 => [qw/all underline ansi_256/],
	italic_8 => [qw/all italic ansi_8/],
	italic_16 => [qw/all italic ansi_16/],
	italic_256 => [qw/all italic ansi_256/],
	background_text_8 => [qw/all background_text ansi_8/],
	background_text_16 => [qw/all background_text ansi_16/],
	background_text_256 => [qw/all background_text ansi_256/],
	background_bold_8 => [qw/all background_bold ansi_8/],
	background_bold_16 => [qw/all background_bold ansi_16/],
	background_bold_256 => [qw/all background_bold ansi_256/],
	background_underline_8 => [qw/all background_underline ansi_8/],
	background_underline_16 => [qw/all background_underline ansi_16/],
	background_underline_256 => [qw/all background_underline ansi_256/],
	background_italic_8 => [qw/all background_italic ansi_8/],
	background_italic_16 => [qw/all background_italic ansi_16/],
	background_italic_256 => [qw/all background_italic ansi_256/],
);


sub palette_8 {
	print "ANSI palette -> \\e[Nm\n";
	for (30..37) {
		print "\e[" . $_ . "m " . $_;
	}
	reset;
}

sub palette_16 {
	print "ANSI palette -> \\e[Nm\n";
	for (30..37) {
		print "\e[" . $_ . "m " . $_;
	}
	print "\nANSI palette -> \\e[N;1m\n";
	for (30..37) {
		print "\e[" . $_ . ";1m " . $_;
	}
	reset;
}

sub palette_256 {
	print "ANSI palette -> \\e[38;5;Nm\n";
	for my $i (0..15) {
		for my $j (0..16) {
			my $code = $i * 16 + $j;
			print "\e[38;5;" . $code . "m " . $code;
		}
		print "\n";
	}
	reset;
}

sub text_8 {
	print "\e[" . $_[0] . "m" . $_[1];
	reset();
}

sub text_16 {
	print "\e[" . $_[0] . ($_[1] ? ";1" : "") . "m" . $_[2];
	reset();
}

sub text_256 {
	print "\e[38;5;" . $_[0] . "m" . $_[1];
	reset();
}

sub bold_8 {
	print "\e[" . $_[0] . ";1m" . $_[1];
	reset();
}

sub bold_16 {
	print "\e[" . $_[0] . ($_[1] ? ";1" : ";0") . ";1m" . $_[2];
	reset();
}

sub bold_256 {
	print "\e[38;5;" . $_[0] . ";1m" . $_[1];
	reset();
}

sub underline_8 {
	print "\e[" . $_[0] . ";4m" . $_[1];
	reset();
}

sub underline_16 {
	print "\e[" . $_[0] . ($_[1] ? ";1" : "") . ";4m" . $_[2];
	reset();
}

sub underline_256 {
	print "\e[38;5;" . $_[0] . ";4m" . $_[1];
	reset();
}

sub italic_8 {
	print "\e[" . $_[0] . ";3m" . $_[1];
	reset();
}

sub italic_16 {
	print "\e[" . $_[0] . ($_[1] ? ";1" : "") . ";3m" . $_[2];
	reset();
}

sub italic_256 {
	print "\e[38;5;" . $_[0] . ";3m" . $_[1];
	reset();
}

sub background_text_8 {
	print "\e[" . $_[0] . ";" . $_[1] . "m" . $_[2];
	reset();
}

sub background_text_16 {
	print "\e[" . $_[0] . ($_[1] ? ";1" : ";0") . ";" . $_[2] . "m" . $_[3];
	reset();
}

sub background_text_256 {
	print "\e[48;5;" . $_[0] . ";38;5;" . $_[1] . "m" . $_[2];
	reset();
}

sub background_bold_8 {
	print "\e[" . $_[0] . ";" . $_[1] . ";1m" . $_[2];
	reset();
}

sub background_bold_16 {
	print "\e[" . $_[0] . ($_[1] ? ";1" : ";0") . ";" . $_[2] . ";1m" . $_[3];
	reset();
}

sub background_bold_256 {
	print "\e[48;5;" . $_[0] . ";38;5;" . $_[1] . ";1m" . $_[2];
	reset();
}

sub background_underline_8 {
	print "\e[" . $_[0] . ";" . $_[1] . ";4m" . $_[2];
	reset();
}

sub background_underline_16 {
	print "\e[" . $_[0] . ($_[1] ? ";1" : ";0") . ';' . $_[2] . ";4m" . $_[3];
	reset();
}

sub background_underline_256 {
	print "\e[48;5;" . $_[0] . ";38;5;" . $_[1] . ";4m" . $_[2];
	reset();
}

sub background_italic_8 {
	print "\e[" . $_[0] . ";" . $_[1] . ";3m" . $_[2];
	reset();
}

sub background_italic_16 {
	print "\e[" . $_[0] . ($_[1] ? ";1" : ";0") . ";" . $_[2] . ";3m" . $_[3];
	reset();
}

sub background_italic_256 {
	print "\e[48;5;" . $_[0] . ";38;5;" . $_[1] . ";3m" . $_[2];
	reset();
}

sub reset { print "\e[0m"; }

__END__

1;

=head1 NAME

ANSI::Palette - ANSI Color palettes

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use ANSI::Palette qw/palette_256/;
	palette_256();

	... 

	use ANSI::Palette qw/ansi_256/;

	background_text_256(208, 33, "This is a test for background_text_256\n");
	background_bold_256(160, 33, "This is a test for background_bold_256\n");
	background_underline_256(226, 33, "This is a test for background_underline_256\n");
	background_italic_256(118, 33, "This is a test for background_italic_256\n");	

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head2 reset
	
=cut

=head2 palette_8

prints a font color palette containing the 8 base colors

	\e[Nm
	31 32 33 34 35 36 37	

=cut

=head2 palette_16 

prints a font color palette containing the 8 base colors and the bright variation.

	\e[Nm
	30 31 32 33 34 35 36 37
	\e[N;1m
	30 31 32 33 34 35 36 37

=cut

=head2 palette_256 

prints a font color palette containing the extended 256 terminal colour codes.

	\e[38;5;Nm
	0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
	16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32
	32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48
	48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64
	64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80
	80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96
	96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112
	112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128
	128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144
	144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160
	160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176
	176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192
	192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208
	208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224
	224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240
	240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256

=cut

=head2 text_8

print text using one of the 8 base colors.

	text_8(32, "This is a test for text_8\n");

=cut

=head2 text_16

print text using one of the 16 base colors.

	text_16(32, 1, "This is a test for text_16\n");

=cut

=head2 text_256

print text using one of the 256 base colors.

	text_256(32, "This is a test for text_256\n");

=cut

=head2 bold_8

print bold text using one of the 8 base colors.

	bold_8(32, "This is a test for bold_8\n");

=cut

=head2 bold_16 

print bold text using one of the 16 base colors.

	bold_16(32, 1, "This is a test for bold_16\n");

=cut

=head2 bold_256

print bold text using one of the 256 base colors.

	bold_256(32, "this is a test for bold_256\n");

=cut

=head2 underline_8

print underlined text using one of the 8 base colors.

	underline_8(32, "This is a test for underline_8\n");

=cut

=head2 underline_16

print underlined text using one of the 16 base colors.

	underline_16(32, 1, "This is a test for underline_16\n");

=cut

=head2 underline_256

print underlined text using one of the 256 base colors.

	underline_256(32, "This is a test for underline_256\n");

=cut

=head2 italic_8

print italic text using one of the 8 base colors.

	italic_8(32, "This is a test for italic_8\n");

=cut

=head2 italic_16

print italic text using one of the 16 base colors.

	italic_16(32, 1, "This is a test for italic_16\n");

=cut

=head2 italic_256

print italic text using one of the 256 base colors.

	italic_256(32, "This is a test for italic_256\n");

=cut

=head2 background_text_8

print text using one of the 8 base colors on a background using one of the 8 base colors.

	background_text_8(32, 40, "This is a test for background_text_8\n");

=cut

=head2 background_text_16

print text using one of the 16 base colors on a background using one of the 16 base colors (40-47) (100-107).

	background_text_16(32, 1, 41, "This is a test for background_text_16\n");

=cut

=head2 background_text_256

print text using one of the 256 base colors on a background using one of the 256 base colors.

	background_text_256(208, 33, "This is a test for background_text_256\n");

=cut

=head2 background_bold_8

print bold text using one of the 8 base colors on a background using one of the 8 base colors.

	background_bold_8(32, 40, "This is a test for background_bold_8\n");

=cut

=head2 background_bold_16

print bold text using one of the 16 base colors on a background using one of the 16 base colors (40-47) (100-107).

	background_bold_16(32, 1, 40, "This is a test for background_bold_16\n");

=cut

=head2 background_bold_256

print bold text using one of the 256 base colors on a background using one of the 256 base colors.

	background_bold_256(208, 33, "this is a test for background_bold_256\n");

=cut

=head2 background_underline_8

print underlined text using one of the 8 base colors on a background using one of the 8 base colors.

	background_underline_8(32, 40, "This is a test for background_underline_8\n");

=cut

=head2 background_underline_16

print underlined text using one of the 16 base colors using one of the 16 base colors (40-47) (100-107).

	background_underline_16(32, 1, 40, "This is a test for background_underline_16\n");

=cut

=head2 background_underline_256

print underlined text using one of the 256 base colors on a background using one of the 256 base colors.

	background_underline_256(208, 33, "This is a test for background_underline_256\n");

=cut

=head2 background_italic_8

print italic text using one of the 8 base colors on a background using one of the 8 base colors.

	background_italic_8(32, 40, "This is a test for background_italic_8\n");

=cut

=head2 italic_16

print italic text using one of the 16 base colors on a background using one of the 16 base colors (40-47) (100-107).

	background_italic_16(32, 1, 40, "This is a test for background_italic_16\n");

=cut

=head2 italic_256

print italic text using one of the 256 base colors on a background using on the 256 base colors.

	background_italic_256(32, "This is a test for background_italic_256\n");

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ansi-palette at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=ANSI-Palette>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ANSI::Palette

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=ANSI-Palette>

=item * Search CPAN

L<https://metacpan.org/release/ANSI-Palette>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023-2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of ANSI::Palette
