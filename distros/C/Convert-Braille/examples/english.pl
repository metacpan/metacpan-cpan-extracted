#!/usr/bin/perl -w

use Convert::Braille qw( brailleAscii_To_Unicode );
use Convert::Braille::English;
use utf8;

# $Convert::Braille::dot_separator ="-";

if ( $] > 5.007 ) {
	binmode(STDOUT, ":utf8");
}

my $ascii = "HELLO";

print "[0/6] Testing Braille-English     : \"$ascii\"\n";

my $english = brailleAscii_To_English ( $ascii );
print "[1/6] brailleAscii_To_English     :  $ascii => $english  (has length: ", length($english), ")\n";

$ascii = english_To_BrailleAscii ( $english );
print "[2/6] english_To_BrailleAscii     :  $english => $ascii\n";

my $unicode = english_To_BrailleUnicode ( $english );
print "[3/6] english_To_BrailleUnicode   :  $english => $unicode  (has length: ", length($unicode), ")\n";

$english = brailleUnicode_To_English ( $unicode );
print "[4/6] brailleUnicode_To_Englih    :  $unicode => $english\n";

$Convert::Braille::dot_separator ="-";

my $dots = english_To_BrailleDotNumbers ( $english );
print "[5/6] english_To_BrailleDotNumbers:  $english => $dots\n";

$english = brailleDotNumbers_To_English ( $dots );
print "[6/6] brailleDotNumbers_To_English:  $dots => $english\n";

$Convert::Braille::dot_separator = undef;

#	english_To_BrailleUnicode
#	english_To_BrailleAscii
#	english_To_BrailleDotNumbers

#	brailleAscii_To_English
#	brailleDotNumbers_To_English
#	brailleUnicode_To_English


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
