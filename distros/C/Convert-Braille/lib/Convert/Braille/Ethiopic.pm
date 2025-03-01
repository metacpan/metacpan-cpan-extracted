package Convert::Braille;
package Convert::Braille::Ethiopic;
use utf8;

BEGIN
{
require 5.006;
use warnings;
use base qw(Exporter);

use strict;
use vars qw( @EXPORT @EXPORT_OK $VERSION
	 %Ethiopic_To_BrailleUnicode %BrailleUnicode_To_Ethiopic
	 %EthiopicNumerals_To_BrailleUnicode %BrailleUnicode_To_EthiopicNumerals
	 %EthiopicPunctuation_To_BrailleUnicode %BrailleUnicode_To_EthiopicPunctuation
	 @EthiopicForms %EthiopicForms $n
);
use Convert::Braille qw(
	%BrailleAscii_To_Unicode
	brailleAscii_To_Unicode
	brailleDotNumbers_To_Unicode
	brailleUnicode_To_Ascii
	brailleUnicode_To_DotNumbers
);

$VERSION = 0.06;

@EXPORT = qw(
	ethiopic_To_BrailleUnicode
	ethiopic_To_BrailleAscii
	ethiopic_To_BrailleDotNumbers

	brailleAscii_To_Ethiopic
	brailleDotNumbers_To_Ethiopic
	brailleUnicode_To_Ethiopic
);
@EXPORT_OK = qw(
	ethiopic_To_BrailleUnicode
	ethiopic_To_BrailleAscii
	ethiopic_To_BrailleDotNumbers

	brailleAscii_To_Ethiopic
	brailleDotNumbers_To_Ethiopic
	brailleUnicode_To_Ethiopic

	%Ethiopic_To_BrailleUnicode %BrailleUnicode_To_Ethiopic
	%EthiopicNumerals_To_BrailleUnicode %BrailleUnicode_To_EthiopicNumerals
	%EthiopicPunctuation_To_BrailleUnicode %BrailleUnicode_To_EthiopicPunctuation
	@EthiopicForms
);

%Ethiopic_To_BrailleUnicode =(
	ህ	=> $BrailleAscii_To_Unicode{H},
	ል	=> $BrailleAscii_To_Unicode{L},
	ሕ	=> $BrailleAscii_To_Unicode{H},
	ም	=> $BrailleAscii_To_Unicode{M},
	ሥ	=> $BrailleAscii_To_Unicode{S},
	ር	=> $BrailleAscii_To_Unicode{R},
	ስ	=> $BrailleAscii_To_Unicode{S},
	ሽ	=> $BrailleAscii_To_Unicode{'%'},
	ቅ	=> $BrailleAscii_To_Unicode{Q},
	ቍ	=> "$BrailleAscii_To_Unicode{Q}$BrailleAscii_To_Unicode{W}",
	ቕ	=> $BrailleAscii_To_Unicode{Q},
	ቝ	=> "$BrailleAscii_To_Unicode{Q}$BrailleAscii_To_Unicode{W}",
	ብ	=> $BrailleAscii_To_Unicode{B},
	ቭ	=> $BrailleAscii_To_Unicode{V},
	ት	=> $BrailleAscii_To_Unicode{T},
	ች	=> $BrailleAscii_To_Unicode{'*'},
	ኅ	=> $BrailleAscii_To_Unicode{H},
	ኍ	=> "$BrailleAscii_To_Unicode{H}$BrailleAscii_To_Unicode{W}",
	ን	=> $BrailleAscii_To_Unicode{N},
	ኝ	=> $BrailleAscii_To_Unicode{'+'},
	እ	=> $BrailleAscii_To_Unicode{'('},
	ክ	=> $BrailleAscii_To_Unicode{K},
	ኵ	=> "$BrailleAscii_To_Unicode{K}$BrailleAscii_To_Unicode{W}",
	ኽ	=> $BrailleAscii_To_Unicode{8},
	ዅ	=> "$BrailleAscii_To_Unicode{8}$BrailleAscii_To_Unicode{W}",
	ው	=> $BrailleAscii_To_Unicode{W},
	ዕ	=> $BrailleAscii_To_Unicode{'('},
	ዝ	=> $BrailleAscii_To_Unicode{Z},
	ዥ	=> $BrailleAscii_To_Unicode{0},
	ይ	=> $BrailleAscii_To_Unicode{Y},
	ድ	=> $BrailleAscii_To_Unicode{D},
	ዽ	=> $BrailleAscii_To_Unicode{D},
	ጅ	=> $BrailleAscii_To_Unicode{J},
	ግ	=> $BrailleAscii_To_Unicode{G},
	ጕ	=> "$BrailleAscii_To_Unicode{G}$BrailleAscii_To_Unicode{W}",
	ጝ	=> $BrailleAscii_To_Unicode{G},
	ጥ	=> $BrailleAscii_To_Unicode{')'},
	ጭ	=> $BrailleAscii_To_Unicode{C},
	ጵ	=> $BrailleAscii_To_Unicode{6},
	ጽ	=> $BrailleAscii_To_Unicode{'&'},
	ፅ	=> $BrailleAscii_To_Unicode{'&'},
	ፍ	=> $BrailleAscii_To_Unicode{F},
	ፕ	=> $BrailleAscii_To_Unicode{P},
	ፘ	=> "$BrailleAscii_To_Unicode{R}$BrailleAscii_To_Unicode{Y}$BrailleAscii_To_Unicode{A}",
	ፙ	=> "$BrailleAscii_To_Unicode{M}$BrailleAscii_To_Unicode{Y}$BrailleAscii_To_Unicode{A}",
	ፚ	=> "$BrailleAscii_To_Unicode{F}$BrailleAscii_To_Unicode{Y}$BrailleAscii_To_Unicode{A}",
	ኧ	=> "$BrailleAscii_To_Unicode{'\"'}$BrailleAscii_To_Unicode{'('}"
);


foreach ( sort keys %Ethiopic_To_BrailleUnicode ) {
	next if ( exists($BrailleUnicode_To_Ethiopic{$Ethiopic_To_BrailleUnicode{$_}}) );
	$BrailleUnicode_To_Ethiopic{$Ethiopic_To_BrailleUnicode{$_}} = $_;
}
$BrailleUnicode_To_Ethiopic{$BrailleAscii_To_Unicode{S}} = 'ስ';


@EthiopicForms = ( 
	$BrailleAscii_To_Unicode{5},
	$BrailleAscii_To_Unicode{U},
	$BrailleAscii_To_Unicode{I},
	$BrailleAscii_To_Unicode{A},
	$BrailleAscii_To_Unicode{E},
	"",
	$BrailleAscii_To_Unicode{O},
	"$BrailleAscii_To_Unicode{W}$BrailleAscii_To_Unicode{A}"
);
%EthiopicForms = ( 
	$BrailleAscii_To_Unicode{5} => -5,
	$BrailleAscii_To_Unicode{U} => -4,
	$BrailleAscii_To_Unicode{I} => -3,
	$BrailleAscii_To_Unicode{A} => -2,
	$BrailleAscii_To_Unicode{E} => -1,
	$BrailleAscii_To_Unicode{O} =>  1,
	$BrailleAscii_To_Unicode{W} =>  2
);

%EthiopicNumerals_To_BrailleUnicode = (
	'፩'	=> $BrailleAscii_To_Unicode{1},
	'፪'	=> $BrailleAscii_To_Unicode{2},
	'፫'	=> $BrailleAscii_To_Unicode{3},
	'፬'	=> $BrailleAscii_To_Unicode{4},
	'፭'	=> $BrailleAscii_To_Unicode{5},
	'፮'	=> $BrailleAscii_To_Unicode{6},
	'፯'	=> $BrailleAscii_To_Unicode{7},
	'፰'	=> $BrailleAscii_To_Unicode{8},
	'፱'	=> $BrailleAscii_To_Unicode{9},
	'፲'	=> "$BrailleAscii_To_Unicode{1}$BrailleAscii_To_Unicode{0}",
	'፳'	=> "$BrailleAscii_To_Unicode{2}$BrailleAscii_To_Unicode{0}",
	'፴'	=> "$BrailleAscii_To_Unicode{3}$BrailleAscii_To_Unicode{0}",
	'፵'	=> "$BrailleAscii_To_Unicode{4}$BrailleAscii_To_Unicode{0}",
	'፶'	=> "$BrailleAscii_To_Unicode{5}$BrailleAscii_To_Unicode{0}",
	'፷'	=> "$BrailleAscii_To_Unicode{6}$BrailleAscii_To_Unicode{0}",
	'፸'	=> "$BrailleAscii_To_Unicode{7}$BrailleAscii_To_Unicode{0}",
	'፹'	=> "$BrailleAscii_To_Unicode{8}$BrailleAscii_To_Unicode{0}",
	'፺'	=> "$BrailleAscii_To_Unicode{9}$BrailleAscii_To_Unicode{0}",
	'፻'	=> "$BrailleAscii_To_Unicode{1}$BrailleAscii_To_Unicode{0}$BrailleAscii_To_Unicode{0}",
	'፼'	=> "$BrailleAscii_To_Unicode{1}$BrailleAscii_To_Unicode{0}$BrailleAscii_To_Unicode{0}$BrailleAscii_To_Unicode{0}$BrailleAscii_To_Unicode{0}"
);


foreach ( keys %EthiopicNumerals_To_BrailleUnicode ) {
	$BrailleUnicode_To_EthiopicNumerals{$EthiopicNumerals_To_BrailleUnicode{$_}} = $_;
}


%EthiopicPunctuation_To_BrailleUnicode = (
	'፡'	=> $BrailleAscii_To_Unicode{2},
	'።'	=> $BrailleAscii_To_Unicode{4},
	'፣'	=> $BrailleAscii_To_Unicode{1},
	'፤'	=> $BrailleAscii_To_Unicode{1},  # undefined in ethiopic
	'፥'	=> $BrailleAscii_To_Unicode{1},  # undefined in ethiopic
	'፦'	=> $BrailleAscii_To_Unicode{1},  # undefined in ethiopic
	'፧'	=> $BrailleAscii_To_Unicode{8},  # undefined in ethiopic
	'፨'	=> " ",
);


foreach ( keys %EthiopicPunctuation_To_BrailleUnicode ) {
	next if ( exists($BrailleUnicode_To_EthiopicPunctuation{$EthiopicPunctuation_To_BrailleUnicode{$_}}) );
	$BrailleUnicode_To_EthiopicPunctuation{$EthiopicPunctuation_To_BrailleUnicode{$_}} = $_;
}


require Convert::Number::Ethiopic;

$n = new Convert::Number::Ethiopic;
	
}


sub	brailleUnicode_To_Ethiopic
{

	return unless ( $_[0] );
	my @chars  = split ( //, $_[0] );

	my $zemede_rabi = 0;
	my ($base,$trans);

	foreach  ( @chars ) { # the ኧ problem forces shifting


		if ( exists($BrailleUnicode_To_Ethiopic{$_}) ) {
			if (
			      $base && $base !~ /[እዕውይ]/ &&
			      $BrailleUnicode_To_Ethiopic{$_} eq 'ው' 
			   )
			{
				$base = 'ኅ' if ( $base eq 'ህ' );
				if ( $base =~ /[ኅቅቕክኽግ]/ ) {
					$base = chr(ord($base)+8);
				}
				else {
					$zemede_rabi = 1;
					$trans .= chr(ord($base)+$EthiopicForms{$_});
				}
			}
			elsif ( $_ eq '⠷'  && $trans && $trans =~ /⠐$/ ) {
				$trans =~ s/⠐$/ኧ/;
			}
			else {
				$trans .= $base if( $base );
				$base = $BrailleUnicode_To_Ethiopic{$_};
			}
		}
		elsif ( exists($EthiopicForms{$_}) ) {
			$trans .= chr(ord($base)+$EthiopicForms{$_}) unless ( $zemede_rabi );
			$base = undef;
			$zemede_rabi = 0;
		}
		else {
			if ( $base ) {
				$trans .= $base;
				$base = undef;
			}
			if ( exists($BrailleUnicode_To_EthiopicNumerals{$_}) ) {
				$trans .= $base.$BrailleUnicode_To_EthiopicNumerals{$_};
			}
			elsif ( exists($BrailleUnicode_To_EthiopicPunctuation{$_}) ) {
				$trans .= $base.$BrailleUnicode_To_EthiopicPunctuation{$_};
			}
			else {
				# something  rouge
				$trans .= $_;
			}
		}
	}

	$trans .= $base if ( $base );
	$trans;
}


sub	ethiopic_To_BrailleUnicode
{

	return unless ( $_[0] );

	my @chars  = split ( //, $_[0] );

	my $trans;

	#
	# change to for loop
	#
	while  ( $_ = shift @chars ) {

		if ( exists($Ethiopic_To_BrailleUnicode{$_}) ) {
			$trans .= $Ethiopic_To_BrailleUnicode{$_};
		}
		elsif ( /[ሀ-ፗ]/ ) {
			my $uni  = $_;
			if ( $uni eq 'ኧ' ) {
				$trans .= '⠐⠷';
			}
			else {
				my $addr = ord($uni);
				my $form  = ord($uni)%8;
				my $sadis = chr( ord($uni)-$form+5 );
				$trans .= $Ethiopic_To_BrailleUnicode{$sadis}.$EthiopicForms[$form];
			}
		}
		elsif ( /[፡-፨]/ ) {
			$trans .= "$EthiopicPunctuation_To_BrailleUnicode{$_}";
		}
		elsif ( /[፩-፼]/ ) {
			my $number = $_;
			my $c;
			while ( @chars && (($c = shift @chars) =~ /[፩-፼]/) ) {
					$number .= $c;
			}
			unshift ( @chars, $c ) if ( $c );  # might have end of string

			my $result = brailleAscii_To_Unicode ( $n->convert ( $number ) );
			$trans .= "$BrailleAscii_To_Unicode{'#'}$result";
		}
		else {
			#	
			#  anything else should convert as per english rules (including
			#  guillemts => " ), do so when english module is ready	
			#	
			$trans .= $_;
		}
	}

	$trans;
}


sub	ethiopic_To_BrailleAscii
{
	brailleUnicode_To_Ascii ( ethiopic_To_BrailleUnicode ( @_ ) );
}


sub	ethiopic_To_BrailleDotNumbers
{
	brailleUnicode_To_DotNumbers ( ethiopic_To_BrailleUnicode ( @_ ) );
}


sub	brailleAscii_To_Ethiopic
{
	brailleUnicode_To_Ethiopic ( brailleAscii_To_Unicode ( @_ ) );
}


sub	brailleDotNumbers_To_Ethiopic
{
	brailleUnicode_To_Ethiopic ( brailleDotNumbers_To_Unicode ( @_ ) );
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__

=encoding utf8

=head1 NAME

 Convert::Braille::Ethiopic - Convert Between Braille Encodings.

=head1 SYNOPSIS

 use Convert::Braille::Ethiopic;

 print ethiopic_To_BrailleUnicode ( "ሰላምታ" ), "\n";
 print brailleDots_To_Ethiopic  ( "234261231134" ), "\n";


=head1 REQUIRES

perl5.6.1 or later, L<Convert::Number::Ethiopic>

=head1 EXPORTS

=over 4

=item brailleAscii_To_Ethiopic( $arg )

  Convert an Amharic-Braille-ASCII ([A-Z0-9]) $arg into Ethiopic. E.g.:

  S5LAMTA => ሰላምታ

=item ethiopic_To_BrailleAscii( $arg )

  Convert an Ethiopic $arg into an Amharic-ASCII string. E.g.:

  ሰላምታ => S5LAMTA

=item ethiopic_To_BrailleUnicode( $arg )

  Convert a Ethiopic $arg into an Unicode Braille codes. E.g.:

  ሰላምታ => ⠎⠢⠇⠁⠍⠞⠁

=item brailleUnicode_To_Ethiopic( $arg )

  Convert a Unicode Braille $arg into an Ethiopic. E.g.:

  ⠎⠢⠇⠁⠍⠞⠁ => ሰላምታ

=item ethiopic_To_BrailleDotNumberss( $arg )

  Convert a Ethiopic $arg into a Braille "dot numbers". E.g.:

  ሰላምታ => 234-26-123-1-134-2345-1

=item brailleDotNumberss_To_Ethiopic( $arg )

  Convert a Braille "dot numbers" $arg into Ethiopic. E.g.:

  234-26-123-1-134-2345-1 => ሰላምታ


=back

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob, L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Convert::Braille> , L<Convert::Braille::English>

Included with this package:

  examples/demo.pl        examples/makeethiopic.pl
  examples/ethiopic.pl    examples/english.pl

=cut
