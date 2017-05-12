package Acme::Flip;

use strict;
use warnings;

our $VERSION = '1.0';

our %table = (
	"a"	=> "\x{0250}",
	"b"	=> "q",
	"c"	=> "\x{0254}",
	"d"	=> "p",
	"e"	=> "\x{01dd}",
	"f"	=> "\x{025f}",
	"g"	=> "\x{0183}",
	"h"	=> "\x{0265}",
	"i"	=> "\x{0131}",
	"j"	=> "\x{027e}",
	"k"	=> "\x{029e}",
	"l"	=> "l",
	"m"	=> "\x{026f}",
	"n"	=> "u",
	"o"	=> "o",
	"p"	=> "d",
	"q"	=> "b",
	"r"	=> "\x{0279}",
	"s"	=> "s",
	"t"	=> "\x{0287}",
	"u"	=> "n",
	"v"	=> "\x{028c}",
	"w"	=> "\x{028d}",
	"y"	=> "\x{028e}",
	"z"	=> "z",
	"1"	=> "\x{21c2}",
#	"2"	=> "\x{1105}",
	"2"	=> "Z",
#	"3"	=> "\x{1110}",
	"3"	=> "E",
#	"4"	=> "\x{3123}",
#	"5"	=> "\x{078e}",
	"5"	=> "S",
	"6"	=> "9",
#	"7"	=> "\x{3125}",
	"7"	=> "L",
	"8"	=> "8",
	"9"	=> "6",
	"0"	=> "0",
	"."	=> "\x{02d9}",
	","	=> "'",
	"'"	=> ",",
	"\""	=> ",,",
	"´"	=> ",",
	"`"	=> ",",
	";"	=> "\x{061b}",
	"!"	=> "\x{00a1}",
	"\x{00a1}"	=> "!",
	"?"	=> "\x{00bf}",
	"\x{00bf}"	=> "?",
	"["	=> "]",
	"]"	=> "[",
	"("	=> ")",
	")"	=> "(",
	"{"	=> "}",
	"}"	=> "{",
	"<"	=> ">",
	">"	=> "<",
	"_"	=> "\x{203e}",
);

sub flip
{
	$_ = shift;
	my $width = (shift or 80);
	while (s/\t+/' ' x (length($&) * 8 - length($`) % 8)/e) {};
	join ("\n", map {
		sprintf "%${width}s", join '', map {
			$_ = lc $_; exists $table{$_} ? $table{$_} : $_
		} reverse split (/\B|\b/, $_)
	} reverse split (/\n/, $_))."\n";
}

1;

=head1 NAME

Acme::Flip - Replace alphanumeric characters in text with ones that look flipped

=head1 SYNOPSIS

    use Acme::Flip;
    binmode STDOUT, ':encoding(utf8)';
    print Acme::Flip::flip ('Hello world');

=head1 DESCRIPTION

Replace alphanumeric characters in text with ones that look flipped.

=head1 BUGS

=over

=item Not all capitalizations, characters and numbers
have adequate "flipped" representation

=back

=head1 AUTHOR

Lubomir Rintel C<< <lkundrak@v3.sk> >>

=head1 COPYRIGHT

Copyright 2009 Lubomir Rintel, All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
