#!/usr/bin/perl -w

use Convert::Braille;
use utf8;

# $Convert::Braille::dot_separator ="-";

if ( $] > 5.007 ) {
	binmode(STDOUT, ":utf8");
}

my $ascii = "HELLO";

print "[0/6] Testing Braill-ASCII : \"$ascii\"\n";

my $unicode = brailleAsciiToUnicode ( $ascii );
print "[1/6] brailleAsciiToUnicode:  $ascii => $unicode  (has length: ", length($unicode), ")\n";

my $dots = brailleAsciiToDots ( $ascii );
print "[2/6] brailleAsciiToDots   :  $ascii => $dots\n";

$ascii = brailleDotsToAscii ( $dots );
print "[3/6] brailleDotsToAscii   :  $dots => $ascii\n";

$unicode = brailleDotsToUnicode ( $dots );
print "[4/6] brailleDotsToUnicode :  $dots => $unicode  (has length: ", length($unicode), ")\n";

$dots = brailleUnicodeToDots ( $unicode );
print "[5/6] brailleUnicodeToDots :  $unicode => $dots\n";

$ascii = brailleUnicodeToAscii ( $unicode );
print "[6/6] brailleUnicodeToAscii:  $unicode => $ascii\n";


__END__

=head1 NAME

demo.pl - Unicode, ASCII, Dots, Conversion Demonstration of Braille.

=head1 SYNOPSIS

./demo.pl

=head1 DESCRIPTION

A demonstrator script to illustrate L<Convert::Braille> usage.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
