package Convert::Braille::English;
use utf8;

BEGIN
{
require 5.006;
use warnings;
use base qw(Exporter);

use strict;
use vars qw( @EXPORT @EXPORT_OK $VERSION
	%English_To_BrailleUnicode
	%BrailleUnicode_To_English
	%SpecialContext
);
use Convert::Braille qw(
	%BrailleAscii_To_Unicode
	brailleAscii_To_Unicode
	brailleDotNumbers_To_Unicode
	brailleUnicode_To_Ascii
	brailleUnicode_To_DotNumbers
);

$VERSION = '0.06';

@EXPORT = qw(
	english_To_BrailleUnicode
	english_To_BrailleAscii
	english_To_BrailleDotNumbers

	brailleAscii_To_English
	brailleDotNumbers_To_English
	brailleUnicode_To_English
);
@EXPORT_OK = qw(
	english_To_BrailleUnicode
	english_To_BrailleAscii
	english_To_BrailleDotNumbers

	brailleAscii_To_English
	brailleDotNumbers_To_English
	brailleUnicode_To_English

	%English_To_BrailleUnicode
	%BrailleUnicode_To_English
	%SpecialContext
);

%English_To_BrailleUnicode =(
	A	=> $BrailleAscii_To_Unicode{A},
	B	=> $BrailleAscii_To_Unicode{B},
	B	=> $BrailleAscii_To_Unicode{C},
	C	=> $BrailleAscii_To_Unicode{D},
	E	=> $BrailleAscii_To_Unicode{E},
	F	=> $BrailleAscii_To_Unicode{F},
	G	=> $BrailleAscii_To_Unicode{G},
	H	=> $BrailleAscii_To_Unicode{H},
	I	=> $BrailleAscii_To_Unicode{I},
	J	=> $BrailleAscii_To_Unicode{J},
	K	=> $BrailleAscii_To_Unicode{K},
	L	=> $BrailleAscii_To_Unicode{L},
	M	=> $BrailleAscii_To_Unicode{M},
	N	=> $BrailleAscii_To_Unicode{N},
	O	=> $BrailleAscii_To_Unicode{O},
	P	=> $BrailleAscii_To_Unicode{P},
	Q	=> $BrailleAscii_To_Unicode{Q},
	R	=> $BrailleAscii_To_Unicode{R},
	S	=> $BrailleAscii_To_Unicode{S},
	T	=> $BrailleAscii_To_Unicode{T},
	U	=> $BrailleAscii_To_Unicode{U},
	V	=> $BrailleAscii_To_Unicode{V},
	W	=> $BrailleAscii_To_Unicode{W},
	X	=> $BrailleAscii_To_Unicode{X},
	Y	=> $BrailleAscii_To_Unicode{Y},
	Z	=> $BrailleAscii_To_Unicode{Z},

	1	=> $BrailleAscii_To_Unicode{1},
	2	=> $BrailleAscii_To_Unicode{2},
	3	=> $BrailleAscii_To_Unicode{3},
	4	=> $BrailleAscii_To_Unicode{4},
	5	=> $BrailleAscii_To_Unicode{5},
	6	=> $BrailleAscii_To_Unicode{6},
	7	=> $BrailleAscii_To_Unicode{7},
	8	=> $BrailleAscii_To_Unicode{8},
	9	=> $BrailleAscii_To_Unicode{9},
	0	=> $BrailleAscii_To_Unicode{0},

	'and'	=> $BrailleAscii_To_Unicode{'&'},
	the	=> $BrailleAscii_To_Unicode{'!'},
	'for'	=> $BrailleAscii_To_Unicode{'='},
	with	=> $BrailleAscii_To_Unicode{'('},
	of	=> $BrailleAscii_To_Unicode{')'}
);

%SpecialContext =(
	ar	=> $BrailleAscii_To_Unicode{'>'},
	ch	=> $BrailleAscii_To_Unicode{'*'},
	ed	=> $BrailleAscii_To_Unicode{'$'},
	en	=> $BrailleAscii_To_Unicode{5},
	er	=> $BrailleAscii_To_Unicode{']'},
	gh	=> $BrailleAscii_To_Unicode{'<'},
	in	=> $BrailleAscii_To_Unicode{9},
	ing	=> $BrailleAscii_To_Unicode{'+'},
	ou	=> $BrailleAscii_To_Unicode{'\\'},
	ow	=> $BrailleAscii_To_Unicode{'['},
	st	=> $BrailleAscii_To_Unicode{'/'},
	sh	=> $BrailleAscii_To_Unicode{'%'},
	th	=> $BrailleAscii_To_Unicode{'?'},
	wh	=> $BrailleAscii_To_Unicode{':'},

	'!'		=> 6,
	':'		=> 3,
	'[\(\)]'	=> 7,
	'<i>'		=> '.',
	'.'		=> 4,
	','		=> 1,
	'\''		=> ',',
	'^'		=> '\'',
	'?'		=> 8,
	';'		=> 2,
	'"'		=> 0
);

# ' is Capital  or is , ?
# ; is Letter
# # is Number

# " is Contraction_5
# ^ is Contraction_45
# _ is Contraction_456

foreach ( keys %English_To_BrailleUnicode ) {
	$BrailleUnicode_To_English{$English_To_BrailleUnicode{$_}} = $_;
}

#
# According to:  http://www.uronramp.net/~lizgray/codes.html
#
#  "American Literary Braille consists of over 250 symbols for letters,
#  numerals, punctuation marks, composition signs, contractions, single-cell
#  words, and short-form words." 
#
#  so this package has a way to go, I need to acquire authorative information.
#

}


#
# absolutely nothing in this package is tested.
#

sub	_convert
{
	return unless ( $_[0] );

	my ( $token, $hash ) = @_;

	( exists($hash->{$token}) ) ? $hash->{$token} : $token ;
}


sub	brailleUnicode_To_English
{

	return unless ( $_[0] );
	my @chars  = split ( //, $_[0] );

	my $trans;

	foreach  ( @chars ) {
		if ( exists($SpecialContext{$_}) ) {
			#
			# analyze context
			#
		}
		elsif ( exists($BrailleUnicode_To_English{$_}) ) {
			#
			# simple map
			#
			$trans .= $BrailleUnicode_To_English{$_};
		}
		else {
			#
			# error
			#
		}
	}

	$trans;
}


sub	english_To_BrailleUnicode
{

	return unless ( $_[0] );

	my @chars  = split ( //, $_[0] );

	my $trans;

	foreach  ( @chars ) {
		if ( 0 ) {
			# 
			# special cases
			# 
		}
		elsif ( exists($English_To_BrailleUnicode{$_}) ) {
			$trans .= $English_To_BrailleUnicode{$_};
		}
	}

	$trans;
	
}


sub	english_To_BrailleAscii
{
	brailleUnicode_To_Ascii ( english_To_BrailleUnicode ( @_ ) );
}


sub	english_To_BrailleDotNumbers
{
	brailleUnicode_To_DotNumbers ( english_To_BrailleUnicode ( @_ ) );
}


sub	brailleAscii_To_English
{
	brailleUnicode_To_English ( brailleAscii_To_Unicode ( @_ ) );
}


sub	brailleDotNumbers_To_English
{
	brailleUnicode_To_English ( brailleDotNumbers_To_Unicode ( @_ ) );
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__

=encoding utf8

=head1 NAME

 Convert::Braille::English - Convert Between Braille Encodings.

=head1 SYNOPSIS

 use Convert::Braille;

 print english_To_BrailleUnicode ( "HELLO" ), "\n";
 print brailleDotNumbers_To_English  ( "12515123123135" ), "\n";


=head1 REQUIRES

perl5.6.1 or later.

=head1 EXPORTS

=over 4

=item brailleAscii_To_English( $arg )

  Convert an Braille-ASCII ([A-Z0-9]) $arg into English. E.g.:

  HELLO => HELLO

I<This is a trivial conversion since English overlaps with Braille-ASCII>

=item english_To_BrailleAscii( $arg )

  Convert an English $arg into an Amharic-ASCII string. E.g.:

  HELLO => HELLO

I<This is a trivial conversion since English overlaps with Braille-ASCII>

=item english_To_BrailleUnicode( $arg )

  Convert a English $arg into an Unicode Braille codes. E.g.:

  HELLO => ⠓⠑⠇⠇⠕

=item brailleUnicode_To_English( $arg )

  Convert a Unicode Braille $arg into an English. E.g.:

  ⠓⠑⠇⠇⠕ => HELLO

=item english_To_BrailleDotNumberss( $arg )

  Convert a English $arg into a Braille "dot numbers". E.g.:

  HELLO => 125-15-123-123-135

=item brailleDotNumberss_To_English( $arg )

  Convert a Braille "dot numbers" $arg into English. E.g.:

  125-15-123-123-135 => HELLO

=back

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob, L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Convert::Braille> ,  L<Convert::Braille::Ethiopic>

Included with this package:

  examples/demo.pl        examples/makeethiopic.pl
  examples/ethiopic.pl    examples/english.pl

=cut
