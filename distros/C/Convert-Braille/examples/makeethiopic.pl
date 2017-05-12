#!/usr/bin/perl -w

use Convert::Braille;
use Convert::Braille::Ethiopic;
use utf8;
# $Convert::Braille::dot_separator=" ";

binmode ( STDOUT, ":utf8" );

print<<TOP;
<html>
  <title>Ethiopic in Braille Encodings</title>
<body bgcolor="#f0f0f0">
<h1 align="center">Ethiopic in Braille Encodings</h1>
<table border>
<tr>
  <th>&nbsp;</th>
TOP

foreach (0..0xf) {
 	printf "  <th>+%X</th>\n", $_;
}
print "</tr>\n";
for (my $i = 0x1200; $i<=0x137c; $i+=0x10) {
	print qq(<tr align="center" valign="top">\n);
 	printf "  <th>U+%X<br>UNI<br>ASCII<br>Dots</th>\n", $i;
    for (my $j=0; $j<=0xf; $j++) {
		my $fidel = chr($i+$j);
		if ( $fidel =~ /(\p{Ethiopic}|\p{P})/ ) {
			my $uni   = ethiopicToBrailleUnicode ( $fidel );
			my $ascii = ethiopicToBrailleAscii   ( $fidel );
			my $dots  = ethiopicToBrailleDots    ( $fidel );

			print "    <td>$fidel<br>$uni<br>$ascii<br>$dots</td>\n";
		}
		else {
			print "    <td>&nbsp;</td>\n";
		}
	}
	print "</tr>\n";
}
print "<tr>\n";
printf "  <th>&nbsp;</th>\n";
foreach (0..0xf) {
 	printf "  <th>+%X</th>\n", $_;
}
print<<BOTTOM;
</tr>
</table>
</body>
</html>
BOTTOM


__END__

=head1 NAME

makeethiopic.pl - Build the Ethiopic Syllabary in Braille.

=head1 SYNOPSIS

./makeethiopic.pl

=head1 DESCRIPTION

A demonstrator script to illustrate L<Convert::Braille::Ethiopic> usage.
This script builds a syllabary table in Braille.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
