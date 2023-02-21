package ANSI::Palette;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';
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
	print "\e[" . $_[0] . ($_[1] ? ";1" : ";0") . $_[2] . ($_[3] ? ";1" : ";0"). "m" . $_[4];
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
	print "\e[" . $_[0] . ($_[1] ? ";1" : ";0") . $_[2] . ($_[3] ? ";1" : ";0") . ";1m" . $_[4];
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
	print "\e[" . $_[0] . ($_[1] ? ";1" : ";0") . $_[2] . ($_[3] ? ";1" : ";0") . ";4m" . $_[4];
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
	print "\e[" . $_[0] . ($_[1] ? ";1" : ";0") . $_[2] . ($_[3] ? ";1" : ";0") . ";3m" . $_[4];
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

ANSI::Palette - The great new ANSI::Palette!

=head1 VERSION

Version 0.02

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
	
=cut

=head2 palette_16 

=cut

=head2 palette_256 

=cut

=head2 text_8

=cut

=head2 text_16

=cut

=head2 text_256

=cut

=head2 bold_8

=cut

=head2 bold_16 

=cut

=head2 bold_256

=cut

=head2 underline_8

=cut

=head2 underline_16

=cut

=head2 underline_256

=cut

=head2 italic_8

=cut

=head2 italic_16

=cut

=head2 italic_256

=cut

=head2 background_text_8

=cut

=head2 background_text_16

=cut

=head2 background_text_256

=cut

=head2 background_bold_8

=cut

=head2 background_bold_16 

=cut

=head2 background_bold_256

=cut

=head2 background_underline_8

=cut

=head2 background_underline_16

=cut

=head2 background_underline_256

=cut

=head2 background_italic_8

=cut

=head2 background_italic_16

=cut

=head2 background_italic_256

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

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/ANSI-Palette>

=item * Search CPAN

L<https://metacpan.org/release/ANSI-Palette>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of ANSI::Palette
