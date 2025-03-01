#!/usr/bin/perl -w

use Convert::Braille qw( brailleAscii_To_Unicode );
use Convert::Braille::Ethiopic;
use utf8;

# $Convert::Braille::dot_separator ="-";

if ( $] > 5.007 ) {
	binmode(STDOUT, ":utf8");
}

my $ethio = "ሰላምታ";
my $ascii = "S5LAMTA";

print "[0/6] Testing Braille-Ethiopic     : \"$ascii\" & \"$ethio\"\n";

my $unicode = brailleAscii_To_Ethiopic ( $ascii );
print "[1/6] brailleAscii_To_Ethiopic     :  $ascii => $unicode  (has length: ", length($unicode), ")\n";

my $asciiOut = ethiopic_To_BrailleAscii ( $ethio );
print "[2/6] ethiopic_To_BrailleAscii     :  $ethio => $asciiOut\n";

my $braille = ethiopic_To_BrailleUnicode ( $ethio );
print "[3/6] ethiopic_To_BrailleUnicode   :  $ethio => $braille  (has length: ", length($braille), ")\n";

$ethioOut = brailleUnicode_To_Ethiopic ( $braille );
print "[4/6] brailleUnicode_To_Ethiopic   :  $braille => $ethioOut\n";

$Convert::Braille::dot_separator ="-";

my $dots = ethiopic_To_BrailleDotNumbers ( $ethio );
print "[5/6] ethiopic_To_BrailleDotNumbers:  $ethio => $dots\n";

$ethioOut = brailleDotNumbers_To_Ethiopic ( $dots );
print "[6/6] brailleDotNumbers_To_Ethiopic:  $dots => $ethioOut\n";

$Convert::Braille::dot_separator = undef;


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
