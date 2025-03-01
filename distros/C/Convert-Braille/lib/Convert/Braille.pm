package Convert::Braille;
use utf8;

BEGIN
{
require 5.006;
use warnings;
use base qw(Exporter);

use strict;
use vars qw( @EXPORT @EXPORT_OK $VERSION %BrailleAscii_To_Unicode %BrailleUnicode_To_Ascii $dot_separator );

$VERSION = '0.06';

@EXPORT = qw(
	brailleDotNumbers_To_Unicode
	brailleUnicode_To_DotNumbers
	brailleUnicode_To_Ascii
	brailleAscii_To_Unicode

	brailleAscii_To_DotNumbers
	brailleDotNumbers_To_Ascii
);
@EXPORT_OK = qw(
	brailleDotNumbers_To_Unicode
	brailleUnicode_To_DotNumbers
	brailleUnicode_To_Ascii
	brailleAscii_To_Unicode

	brailleAscii_To_DotNumbers
	brailleDotNumbers_To_Ascii

	%BrailleAscii_To_Unicode
	%Unicode_To_BrailleAscii
);

%BrailleAscii_To_Unicode =(
	A	=> '⠁',
	B	=> '⠃',
	C	=> '⠉',
	D	=> '⠙',
	E	=> '⠑',
	F	=> '⠋',
	G	=> '⠛',
	H	=> '⠓',
	I	=> '⠊',
	J	=> '⠚',
	K	=> '⠅',
	L	=> '⠇',
	M	=> '⠍',
	N	=> '⠝',
	O	=> '⠕',
	P	=> '⠏',
	Q	=> '⠟',
	R	=> '⠗',
	S	=> '⠎',
	T	=> '⠞',
	U	=> '⠥',
	V	=> '⠧',
	W	=> '⠺',
	X	=> '⠭',
	Y	=> '⠽',
	Z	=> '⠵',

	1	=> '⠂',
	2	=> '⠆',
	3	=> '⠒',
	4	=> '⠲',
	5	=> '⠢',
	6	=> '⠖',
	7	=> '⠶',
	8	=> '⠦',
	9	=> '⠔',
	0	=> '⠴',

	','	=> '⠄',
	'@'	=> '⠈',
	'/'	=> '⠌',
	'"'	=> '⠐',
	'^'	=> '⠘',
	'>'	=> '⠜',
	'\''	=> '⠠',
	'*'	=> '⠡',
	'<'	=> '⠣',
	'-'	=> '⠤',
	'.'	=> '⠨',
	'%'	=> '⠩',
	'['	=> '⠪',
	'$'	=> '⠫',
	'+'	=> '⠬',
	'!'	=> '⠮',
	'&'	=> '⠯',
	';'	=> '⠰',
	':'	=> '⠱',
	'\\'	=> '⠳',
	'('	=> '⠷',
	'_'	=> '⠸',
	'?'	=> '⠹',
	']'	=> '⠻',
	'#'	=> '⠼',
	')'	=> '⠾',
	'='	=> '⠿'
);


foreach ( keys %BrailleAscii_To_Unicode ) {
	$BrailleUnicode_To_Ascii{$BrailleAscii_To_Unicode{$_}} = $_;
}

$dot_separator = "";

}

sub	_convert
{
	return unless ( defined($_[0]) );

	my ( $token, $hash ) = @_;

	( exists($hash->{$token}) ) ? $hash->{$token} : $token ;
}


sub	brailleAscii_To_Unicode
{

	return unless ( defined($_[0]) );

	my $ascii = uc($_[0]);
	$ascii =~ s/(.)/_convert ( $1, \%BrailleAscii_To_Unicode )/ge;
	$ascii;
}


sub	brailleUnicode_To_Ascii
{

	return unless ( defined($_[0]) );

	my $unicode = $_[0];

	#
	#  first strip off dots 7 and 8:
	#
	if ( $unicode =~ /⡀-⣿/ ) {
		$unicode =~ tr/⢀-⣿/⠀-⡿/;  # fold upper half
		$unicode =~ tr/⡀-⡿/⠀-⠿/;  # fold upper quarter
	}
	$unicode =~ s/(.)/_convert ( $1, \%BrailleUnicode_To_Ascii )/ge;
	$unicode;
}


sub	brailleUnicode_To_DotNumbers
{

	my $string = shift; # no || "" because fail for '0'
	return "" if !defined $string || $string eq ""; 
	my $braced = ( @_ ) ?  shift : 0 ;

	my @chars  = split ( //, $string );

	my ($trans, $dots);

	foreach  ( @chars ) {
		if ( /[⠀-⣿]/ ) {  # assume UTF8
			my $char = ord ( $_ ) - 0x2800;
			$trans .= $dot_separator if ( $dots );
			$dots  = undef;
			$dots  = "1" if ( $char & 0x1  );
			$dots .= "2" if ( $char & 0x2  );
			$dots .= "3" if ( $char & 0x4  );
			$dots .= "4" if ( $char & 0x8  );
			$dots .= "5" if ( $char & 0x10 );
			$dots .= "6" if ( $char & 0x20 );
			$dots .= "7" if ( $char & 0x40 );
			$dots .= "8" if ( $char & 0x80 );
			$trans .= ($braced) ? "[$dots]" : $dots;
		}
		else {
			$trans .= "$_";
			$dots = undef;
		}
	}

	$trans;
}


sub	brailleDotNumbers_To_Unicode
{

	my $string = shift;
	return "" if !defined $string || $string eq ""; 

	$string =~ s/$dot_separator//g if( $dot_separator );


	my @bits  = split ( //, $string );

	my ($char, $lastBit, $trans) = (0,0,"");

	foreach ( @bits ) {
		my $bit = $_;
		if ( $bit =~ /[1-8]/ ) {
			if ( $bit > $lastBit ) {
				# bit continues sequence
				$char += 2**($bit-1);
			}
			else {
				# bit starts new sequence
				$trans  .= chr ( 0x2800+$char ) if ( $char );  # first time problem
				$lastBit = $char = 0;
				$char    = 2**($bit-1);
			}
			$lastBit = $bit;
		}
		else {  # end of sequence
			$trans  .= chr ( 0x2800+$char ) if ( $char );  # first time problem
			$trans  .= $bit;
			$lastBit = $char = 0;
		}
	}
	$trans  .= chr ( 0x2800+$char ) if ( $char );  # last time problem
  
  $trans;
}


sub	brailleAscii_To_DotNumbers
{
	brailleUnicode_To_DotNumbers ( brailleAscii_To_Unicode ( @_ ) );
}


sub	brailleDotNumbers_To_Ascii
{
	brailleUnicode_To_Ascii ( brailleDotNumbers_To_Unicode ( @_ ) );
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__

=encoding utf8

=head1 NAME

 Convert::Braille - Convert Between Braille Encodings.

=head1 SYNOPSIS

 use Convert::Braille;

 print brailleAscii_To_Unicode ( "HELLO" ), "\n";
 print brailleDots_To_Ascii    ( "12515123123135" ), "\n";


=head1 REQUIRES

perl5.6.1 or later.

=head1 EXPORTS

=over 4

=item brailleAscii_To_Unicode( $arg )

  Convert an ASCII ([A-Z0-9]) $arg into Unicode Braille codes. E.g.:

  HELLO => ⠓⠑⠇⠇⠕

=item brailleUnicode_To_Ascii( $arg )

  Convert a Unicode Braille $arg into an ASCII string. E.g.:

  ⠓⠑⠇⠇⠕ => HELLO

=item brailleUnicode_To_DotNumbers( $arg )

  Convert a Unicode Braille $arg into a Braille "dot numbers". E.g.:

  ⠓⠑⠇⠇⠕ => 12515123123135

=item brailleDotNumbers_To_Unicode( $arg )

  Convert a Braille "dot numbers" $arg into Unicode Braille. E.g.:

  12515123123135 => ⠓⠑⠇⠇⠕ 

=item brailleAscii_To_DotNumbers( $arg )

  Convert an ASCII ([A-Z0-9]) $arg into Braille "dot numbers". E.g.:

  HELLO => 12515123123135

=item brailleDotNumbers_To_Ascii( $arg )

  Convert a Braille "dot numbers" $arg into an ASCII string. E.g.:

  12515123123135 => HELLO

=back

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob, L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<Convert::Braille::Ethiopic> , L<Convert::Braille::English>

Included with this package:

  examples/demo.pl        examples/makeethiopic.pl
  examples/ethiopic.pl    examples/english.pl

=cut
