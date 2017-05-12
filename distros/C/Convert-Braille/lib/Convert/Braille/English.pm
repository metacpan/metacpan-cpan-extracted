package Convert::Braille::English;
use utf8;

BEGIN
{
require 5.006;

use base qw(Exporter);

use strict;
use vars qw( @EXPORT @EXPORT_OK $VERSION
	%EnglishToBrailleUnicode
	%BrailleUnicodeToEnglish
	%SpecialContext
);
use Convert::Braille qw(
	%BrailleAsciiToUnicode
	brailleAsciiToUnicode
	brailleDotsToUnicode
	brailleUnicodeToAscii
	brailleUnicodeToDots
);

$VERSION = '0.02';

@EXPORT = qw(
	englishToBrailleUnicode
	englishToBrailleAscii
	englishToBrailleDots

	brailleAsciiToEnglish
	brailleDotsToEnglish
	brailleUnicodeToEnglish
);
@EXPORT_OK = qw(
	englishToBrailleUnicode
	englishToBrailleAscii
	englishToBrailleDots

	brailleAsciiToEnglish
	brailleDotsToEnglish
	brailleUnicodeToEnglish

	%EnglishToBrailleUnicode
	%BrailleUnicodeToEnglish
	%SpecialContext
);

%EnglishToBrailleUnicode =(
	A	=> $BrailleAsciiToUnicode{A},
	B	=> $BrailleAsciiToUnicode{B},
	B	=> $BrailleAsciiToUnicode{C},
	C	=> $BrailleAsciiToUnicode{D},
	E	=> $BrailleAsciiToUnicode{E},
	F	=> $BrailleAsciiToUnicode{F},
	G	=> $BrailleAsciiToUnicode{G},
	H	=> $BrailleAsciiToUnicode{H},
	I	=> $BrailleAsciiToUnicode{I},
	J	=> $BrailleAsciiToUnicode{J},
	K	=> $BrailleAsciiToUnicode{K},
	L	=> $BrailleAsciiToUnicode{L},
	M	=> $BrailleAsciiToUnicode{M},
	N	=> $BrailleAsciiToUnicode{N},
	O	=> $BrailleAsciiToUnicode{O},
	P	=> $BrailleAsciiToUnicode{P},
	Q	=> $BrailleAsciiToUnicode{Q},
	R	=> $BrailleAsciiToUnicode{R},
	S	=> $BrailleAsciiToUnicode{S},
	T	=> $BrailleAsciiToUnicode{T},
	U	=> $BrailleAsciiToUnicode{U},
	V	=> $BrailleAsciiToUnicode{V},
	W	=> $BrailleAsciiToUnicode{W},
	X	=> $BrailleAsciiToUnicode{X},
	Y	=> $BrailleAsciiToUnicode{Y},
	Z	=> $BrailleAsciiToUnicode{Z},

	1	=> $BrailleAsciiToUnicode{1},
	2	=> $BrailleAsciiToUnicode{2},
	3	=> $BrailleAsciiToUnicode{3},
	4	=> $BrailleAsciiToUnicode{4},
	5	=> $BrailleAsciiToUnicode{5},
	6	=> $BrailleAsciiToUnicode{6},
	7	=> $BrailleAsciiToUnicode{7},
	8	=> $BrailleAsciiToUnicode{8},
	9	=> $BrailleAsciiToUnicode{9},
	0	=> $BrailleAsciiToUnicode{0},

	'and'	=> $BrailleAsciiToUnicode{'&'},
	the	=> $BrailleAsciiToUnicode{'!'},
	'for'	=> $BrailleAsciiToUnicode{'='},
	with	=> $BrailleAsciiToUnicode{'('},
	of	=> $BrailleAsciiToUnicode{')'}
);

%SpecialContext =(
	ar	=> $BrailleAsciiToUnicode{'>'},
	ch	=> $BrailleAsciiToUnicode{'*'},
	ed	=> $BrailleAsciiToUnicode{'$'},
	en	=> $BrailleAsciiToUnicode{5},
	er	=> $BrailleAsciiToUnicode{']'},
	gh	=> $BrailleAsciiToUnicode{'<'},
	in	=> $BrailleAsciiToUnicode{9},
	ing	=> $BrailleAsciiToUnicode{'+'},
	ou	=> $BrailleAsciiToUnicode{'\\'},
	ow	=> $BrailleAsciiToUnicode{'['},
	st	=> $BrailleAsciiToUnicode{'/'},
	sh	=> $BrailleAsciiToUnicode{'%'},
	th	=> $BrailleAsciiToUnicode{'?'},
	wh	=> $BrailleAsciiToUnicode{':'},

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

foreach ( keys %EnglishToBrailleUnicode ) {
	$BrailleUnicodeToEnglish{$EnglishToBrailleUnicode{$_}} = $_;
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


sub	brailleUnicodeToEnglish
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
		elsif ( exists($BrailleUnicodeToEnglish{$_}) ) {
			#
			# simple map
			#
			$trans .= $BrailleUnicodeToEnglish{$_};
		}
		else {
			#
			# error
			#
		}
	}

	$trans;
}


sub	englishToBrailleUnicode
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
		elsif ( exists($EnglishToBrailleUnicode{$_}) ) {
			$trans .= $EnglishToBrailleUnicode{$_};
		}
	}
	
}


sub	englishToBrailleAscii
{
	brailleUnicodeToAscii ( englishToBrailleUnicode ( @_ ) );
}


sub	englishToBrailleDots
{
	brailleUnicodeToDots ( englishToBrailleUnicode ( @_ ) );
}


sub	brailleAsciiToEnglish
{
	brailleUnicodeToEnglish ( brailleAsciiToUnicode ( @_ ) );
}


sub	brailleDotsToEnglish
{
	brailleUnicodeToEnglish ( brailleDotsToUnicode ( @_ ) );
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

 Convert::Braille::English - Convert Between Braille Encodings.

=head1 SYNOPSIS

 use Convert::Braille;

 print brailleAsciiToEnglish ( "HELLO" ), "\n";
 print brailleDotsToEnglish  ( "12515123123135" ), "\n";


=head1 REQUIRES

perl5.6.0 or later.

=head1 EXPORTS

=over 4

=item englishToBrailleUnicode

=item englishToBrailleAscii

=item englishToBrailleDots

=item brailleAsciiToEnglish

=item brailleDotsToEnglish

=item brailleUnicodeToEnglish

=back

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Convert::Braille>    L<Convert::Braille::Ethiopic>

Included with this package:

  examples/demo.pl

=cut
