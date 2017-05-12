package Convert::EastAsianWidth;

use 5.008;
use strict;
use Exporter;

our $VERSION = '1.02';
our @ISA = 'Exporter';
our @EXPORT = qw(to_fullwidth to_halfwidth);

sub to_fullwidth {
    my $text;
    my $enc  = $_[1];

    if ($enc) {
	require Encode;
	$text = Encode::decode($enc => $_[0]);
    }
    else {
	$text = $_[0];
    }

    $text =~ tr/ -~/\x{3000}\x{FF01}-\x{FF5E}/; 

    return ( $enc ? Encode::encode($enc => $text) : $text );
}

sub to_halfwidth {
    my $text;
    my $enc = $_[1];

    if ($enc) {
	require Encode;
	$text = Encode::decode($enc => $_[0]);
    }
    else {
	$text = $_[0];
    }

    $text =~ tr/\x{3000}\x{FF01}-\x{FF5E}/ -~/;

    return ( $enc ? Encode::encode($enc => $text) : $text );
}
1;

__END__

=encoding utf8

=head1 NAME

Convert::EastAsianWidth - Convert between full/half-width ASCII characters

=head1 VERSION

This document describes version 1.01 of Convert:EastAsianWidth,
released November 7, 2010.

=head1 SYNOPSIS

    # Exports to_fullwidth() and to_halfwidth() by default
    use Convert::EastAsianWidth;

    my $u = to_fullwidth('ABC');	    # Full-width variant of 'ABC'
    my $b = to_fullwidth('ABC', 'big5');    # Ditto, but in big5 encoding
    my $x = to_halfwidth($u);		    # Gets back 'ABC'
    my $y = to_halfwidth($b, 'big5');	    # Same as above

=head1 DESCRIPTION

This module efficiently convert between full- and half-width ASCII
characters, including alphanumerics and punctuations.

The first argument is the string to be converted; the second one
represents the input and encodings.  If omitted, both are assumed
to be Unicode strings.

=head1 CAVEATS

This module does not handle conversion of full/half width katakana, which
is a slightly more complicated problem because of the need to incorporate
diacritics.

Many thanks to BKB for the disclaimer above and for suggesting a more
efficient conversion algorithm based on C<tr///>.

=head1 SEE ALSO

L<Encode>

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to Convert-EastAsianWidth.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
