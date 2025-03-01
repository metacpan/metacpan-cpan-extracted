#!/usr/bin/perl -w

use Convert::Braille;
use utf8;

# $Convert::Braille::dot_separator ="-";

if ( $] > 5.007 ) {
	binmode(STDOUT, ":utf8");
}

my $ascii = "HELLO";

print "[0/6] Testing Braille-ASCII       : \"$ascii\"\n";

my $unicode = brailleAscii_To_Unicode ( $ascii );
print "[1/6] brailleAscii_To_Unicode     :  $ascii => $unicode  (has length: ", length($unicode), ")\n";

my $dots = brailleAscii_To_DotNumbers ( $ascii );
print "[2/6] brailleAscii_To_DotNumbers  :  $ascii => $dots\n";

$ascii = brailleDotNumbers_To_Ascii ( $dots );
print "[3/6] brailleDotNumbers_To_Ascii  :  $dots => $ascii\n";

$unicode = brailleDotNumbers_To_Unicode ( $dots );
print "[4/6] brailleDotNumbers_To_Unicode:  $dots => $unicode  (has length: ", length($unicode), ")\n";

$Convert::Braille::dot_separator ="-";

$dots = brailleUnicode_To_DotNumbers ( $unicode );
print "[5/6] brailleUnicode_To_DotNumbers:  $unicode => $dots\n";

$Convert::Braille::dot_separator = undef;

$ascii = brailleUnicode_To_Ascii ( $unicode );
print "[6/6] brailleUnicode_To_Ascii     :  $unicode => $ascii\n";


__END__

=head1 NAME

demo.pl - Unicode, ASCII, DotNumbers, Conversion Demonstration of Braille.

=head1 SYNOPSIS

./demo.pl

=head1 DESCRIPTION

A demonstrator script to illustrate L<Convert::Braille> usage.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
