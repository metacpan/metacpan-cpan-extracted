package Convert::Ascii85;

use warnings;
use strict;

our $VERSION = '0.01';

use Exporter qw(import);

our @EXPORT_OK = qw(ascii85_encode ascii85_decode);

my $_space_no = unpack 'N', ' ' x 4;

sub encode {
	my ($in, $opt) = @_;
	my $compress_zero = exists $opt->{compress_zero} ? $opt->{compress_zero} : 1;
	my $compress_space = $opt->{compress_space};

	my $padding = -length($in) % 4;
	$in .= "\0" x $padding;
	my $out = '';

	for my $n (unpack 'N*', $in) {
		if ($n == 0 && $compress_zero) {
			$out .= 'z';
			next;
		}
		if ($n == $_space_no && $compress_space) {
			$out .= 'y';
			next;
		}

		my $tmp = '';
		for my $i (reverse 0 .. 4) {
			my $mod = $n % 85;
			$n = int($n / 85);
			vec($tmp, $i, 8) = $mod + 33;
		}
		$out .= $tmp;
	}

	$padding or return $out;

	$out =~ s/z\z/!!!!!/;
	substr $out, 0, length($out) - $padding
}

*ascii85_encode = \&encode;

sub decode {
	my ($in) = @_;
	for ($in) {
		tr[ \t\r\n\f][]d;
		s/z/!!!!!/g;
		s/y/+<VdL/g;
	}

	my $padding = -length($in) % 5;
	$in .= 'u' x $padding;
	my $out = '';

	for my $n (unpack '(a5)*', $in) {
		my $tmp = 0;
		for my $i (unpack 'C*', $n) {
			$tmp *= 85;
			$tmp += $i - 33;
		}
		$out .= pack 'N', $tmp;
	}

	substr $out, 0, length($out) - $padding
}

*ascii85_decode = \&decode;

1

__END__

=head1 NAME

Convert::Ascii85 - Encoding and decoding of ascii85/base85 strings

=head1 SYNOPSIS

 use Convert::Ascii85;
 
 my $encoded = Convert::Ascii85::encode($data);
 my $decoded = Convert::Ascii85::decode($encoded);

 use Convert::Ascii85 qw(ascii85_encode ascii85_decode);
 
 my $encoded = ascii85_encode($data);
 my $decoded = ascii85_decode($encoded);

=head1 DESCRIPTION

This module implements the I<Ascii85> (also known as I<Base85>) algorithm for
encoding binary data as text. This is done by interpreting each group of four
bytes as a 32-bit integer, which is then converted to a five-digit base-85
representation using the digits from ASCII 33 (C<!>) to 117 (C<u>).

This is similar to L<MIME::Base64> but more space efficient: The overhead is
only 1/4 of the original data (as opposed to 1/3 for Base64).

=head1 FUNCTIONS

=over 4

=item Convert::Ascii85::encode DATA

=item Convert::Ascii85::encode DATA, OPTIONS

Converts the bytes in DATA to Ascii85 and returns the resulting text string.
OPTIONS is a hash reference in which the following keys may be set:

=over

=item compress_zero => 0

By default, four-byte chunks of null bytes (C<"\0\0\0\0">) are converted to
C<'z'> instead of C<'!!!!!'>. This can be avoided by passing a false value for
C<compress_zero> in OPTIONS.

=item compress_space => 1

By default, four-byte chunks of spaces (C<'    '>) are converted to C<'+<VdL'>.
If you pass a true value for C<compress_space> in OPTIONS, they will be
converted to C<'y'> instead.

=back

This function may be exported as C<ascii85_encode> into the caller's namespace.

=item Convert::Ascii85::decode TEXT

Converts the Ascii85-encoded TEXT back to bytes and returns the resulting byte
string. Spaces and linebreaks in TEXT are ignored.

This function may be exported as C<ascii85_decode> into the caller's namespace.

=back

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Ascii85>,
L<MIME::Base64>

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-convert-ascii85 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Convert-Ascii85>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Convert::Ascii85

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Convert-Ascii85>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Convert-Ascii85>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Convert-Ascii85>

=item * Search CPAN

L<http://search.cpan.org/dist/Convert-Ascii85/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

