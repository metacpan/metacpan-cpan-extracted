package Convert::Braille::Ethiopic;
use utf8;

BEGIN
{
require 5.006;

use base qw(Exporter);

use strict;
use vars qw( @EXPORT @EXPORT_OK $VERSION
	 %EthiopicToBrailleUnicode %BrailleUnicodeToEthiopic
	 %EthiopicNumeralsToBrailleUnicode %BrailleUnicodeToEthiopicNumerals
	 %EthiopicPunctuationToBrailleUnicode %BrailleUnicodeToEthiopicPunctuation
	 @EthiopicForms %EthiopicForms $n
);
use Convert::Braille qw(
	%BrailleAsciiToUnicode
	brailleAsciiToUnicode
	brailleDotsToUnicode
	brailleUnicodeToAscii
	brailleUnicodeToDots
);

$VERSION = 0.02;

@EXPORT = qw(
	ethiopicToBrailleUnicode
	ethiopicToBrailleAscii
	ethiopicToBrailleDots

	brailleAsciiToEthiopic
	brailleDotsToEthiopic
	brailleUnicodeToEthiopic
);
@EXPORT_OK = qw(
	ethiopicToBrailleUnicode
	ethiopicToBrailleAscii
	ethiopicToBrailleDots

	brailleAsciiToEthiopic
	brailleDotsToEthiopic
	brailleUnicodeToEthiopic

	%EthiopicToBrailleUnicode %BrailleUnicodeToEthiopic
	%EthiopicNumeralsToBrailleUnicode %BrailleUnicodeToEthiopicNumerals
	%EthiopicPunctuationToBrailleUnicode %BrailleUnicodeToEthiopicPunctuation
	@EthiopicForms
);

%EthiopicToBrailleUnicode =(
	ህ	=> $BrailleAsciiToUnicode{H},
	ል	=> $BrailleAsciiToUnicode{L},
	ሕ	=> $BrailleAsciiToUnicode{H},
	ም	=> $BrailleAsciiToUnicode{M},
	ሥ	=> $BrailleAsciiToUnicode{S},
	ር	=> $BrailleAsciiToUnicode{R},
	ስ	=> $BrailleAsciiToUnicode{S},
	ሽ	=> $BrailleAsciiToUnicode{'%'},
	ቅ	=> $BrailleAsciiToUnicode{Q},
	ቍ	=> "$BrailleAsciiToUnicode{Q}$BrailleAsciiToUnicode{W}",
	ቕ	=> $BrailleAsciiToUnicode{Q},
	ቝ	=> "$BrailleAsciiToUnicode{Q}$BrailleAsciiToUnicode{W}",
	ብ	=> $BrailleAsciiToUnicode{B},
	ቭ	=> $BrailleAsciiToUnicode{V},
	ት	=> $BrailleAsciiToUnicode{T},
	ች	=> $BrailleAsciiToUnicode{'*'},
	ኅ	=> $BrailleAsciiToUnicode{H},
	ኍ	=> "$BrailleAsciiToUnicode{H}$BrailleAsciiToUnicode{W}",
	ን	=> $BrailleAsciiToUnicode{N},
	ኝ	=> $BrailleAsciiToUnicode{'+'},
	እ	=> $BrailleAsciiToUnicode{'('},
	ክ	=> $BrailleAsciiToUnicode{K},
	ኵ	=> "$BrailleAsciiToUnicode{K}$BrailleAsciiToUnicode{W}",
	ኽ	=> $BrailleAsciiToUnicode{8},
	ዅ	=> "$BrailleAsciiToUnicode{8}$BrailleAsciiToUnicode{W}",
	ው	=> $BrailleAsciiToUnicode{W},
	ዕ	=> $BrailleAsciiToUnicode{'('},
	ዝ	=> $BrailleAsciiToUnicode{Z},
	ዥ	=> $BrailleAsciiToUnicode{0},
	ይ	=> $BrailleAsciiToUnicode{Y},
	ድ	=> $BrailleAsciiToUnicode{D},
	ዽ	=> $BrailleAsciiToUnicode{D},
	ጅ	=> $BrailleAsciiToUnicode{J},
	ግ	=> $BrailleAsciiToUnicode{G},
	ጕ	=> "$BrailleAsciiToUnicode{G}$BrailleAsciiToUnicode{W}",
	ጝ	=> $BrailleAsciiToUnicode{G},
	ጥ	=> $BrailleAsciiToUnicode{')'},
	ጭ	=> $BrailleAsciiToUnicode{C},
	ጵ	=> $BrailleAsciiToUnicode{6},
	ጽ	=> $BrailleAsciiToUnicode{'&'},
	ፅ	=> $BrailleAsciiToUnicode{'&'},
	ፍ	=> $BrailleAsciiToUnicode{F},
	ፕ	=> $BrailleAsciiToUnicode{P},
	ፘ	=> "$BrailleAsciiToUnicode{R}$BrailleAsciiToUnicode{Y}$BrailleAsciiToUnicode{A}",
	ፙ	=> "$BrailleAsciiToUnicode{M}$BrailleAsciiToUnicode{Y}$BrailleAsciiToUnicode{A}",
	ፚ	=> "$BrailleAsciiToUnicode{F}$BrailleAsciiToUnicode{Y}$BrailleAsciiToUnicode{A}",
	ኧ	=> "$BrailleAsciiToUnicode{'\"'}$BrailleAsciiToUnicode{'('}"
);


foreach ( sort keys %EthiopicToBrailleUnicode ) {
	next if ( exists($BrailleUnicodeToEthiopic{$EthiopicToBrailleUnicode{$_}}) );
	$BrailleUnicodeToEthiopic{$EthiopicToBrailleUnicode{$_}} = $_;
}


@EthiopicForms = ( 
	$BrailleAsciiToUnicode{5},
	$BrailleAsciiToUnicode{U},
	$BrailleAsciiToUnicode{I},
	$BrailleAsciiToUnicode{A},
	$BrailleAsciiToUnicode{E},
	"",
	$BrailleAsciiToUnicode{O},
	"$BrailleAsciiToUnicode{W}$BrailleAsciiToUnicode{A}"
);
%EthiopicForms = ( 
	$BrailleAsciiToUnicode{5} => -5,
	$BrailleAsciiToUnicode{U} => -4,
	$BrailleAsciiToUnicode{I} => -3,
	$BrailleAsciiToUnicode{A} => -2,
	$BrailleAsciiToUnicode{E} => -1,
	$BrailleAsciiToUnicode{O} =>  1,
	$BrailleAsciiToUnicode{W} =>  2
);

%EthiopicNumeralsToBrailleUnicode = (
	'፩'	=> $BrailleAsciiToUnicode{1},
	'፪'	=> $BrailleAsciiToUnicode{2},
	'፫'	=> $BrailleAsciiToUnicode{3},
	'፬'	=> $BrailleAsciiToUnicode{4},
	'፭'	=> $BrailleAsciiToUnicode{5},
	'፮'	=> $BrailleAsciiToUnicode{6},
	'፯'	=> $BrailleAsciiToUnicode{7},
	'፰'	=> $BrailleAsciiToUnicode{8},
	'፱'	=> $BrailleAsciiToUnicode{9},
	'፲'	=> "$BrailleAsciiToUnicode{1}$BrailleAsciiToUnicode{0}",
	'፳'	=> "$BrailleAsciiToUnicode{2}$BrailleAsciiToUnicode{0}",
	'፴'	=> "$BrailleAsciiToUnicode{3}$BrailleAsciiToUnicode{0}",
	'፵'	=> "$BrailleAsciiToUnicode{4}$BrailleAsciiToUnicode{0}",
	'፶'	=> "$BrailleAsciiToUnicode{5}$BrailleAsciiToUnicode{0}",
	'፷'	=> "$BrailleAsciiToUnicode{6}$BrailleAsciiToUnicode{0}",
	'፸'	=> "$BrailleAsciiToUnicode{7}$BrailleAsciiToUnicode{0}",
	'፹'	=> "$BrailleAsciiToUnicode{8}$BrailleAsciiToUnicode{0}",
	'፺'	=> "$BrailleAsciiToUnicode{9}$BrailleAsciiToUnicode{0}",
	'፻'	=> "$BrailleAsciiToUnicode{1}$BrailleAsciiToUnicode{0}$BrailleAsciiToUnicode{0}",
	'፼'	=> "$BrailleAsciiToUnicode{1}$BrailleAsciiToUnicode{0}$BrailleAsciiToUnicode{0}$BrailleAsciiToUnicode{0}$BrailleAsciiToUnicode{0}"
);


foreach ( keys %EthiopicNumeralsToBrailleUnicode ) {
	$BrailleUnicodeToEthiopicNumerals{$EthiopicNumeralsToBrailleUnicode{$_}} = $_;
}


%EthiopicPunctuationToBrailleUnicode = (
	'፡'	=> $BrailleAsciiToUnicode{2},
	'።'	=> $BrailleAsciiToUnicode{4},
	'፣'	=> $BrailleAsciiToUnicode{1},
	'፤'	=> $BrailleAsciiToUnicode{1},  # undefined in ethiopic
	'፥'	=> $BrailleAsciiToUnicode{1},  # undefined in ethiopic
	'፦'	=> $BrailleAsciiToUnicode{1},  # undefined in ethiopic
	'፧'	=> $BrailleAsciiToUnicode{8},  # undefined in ethiopic
	'፨'	=> " ",
);


foreach ( keys %EthiopicPunctuationToBrailleUnicode ) {
	next if ( exists($BrailleUnicodeToEthiopicPunctuation{$EthiopicPunctuationToBrailleUnicode{$_}}) );
	$BrailleUnicodeToEthiopicPunctuation{$EthiopicPunctuationToBrailleUnicode{$_}} = $_;
}


require Convert::Number::Ethiopic;

$n = new Convert::Number::Ethiopic;
	
}


sub	brailleUnicodeToEthiopic
{

	return unless ( $_[0] );
	my @chars  = split ( //, $_[0] );

	my $zemede_rabi = 0;
	my ($base,$trans);

	foreach  ( @chars ) { # the ኧ problem forces shifting

		if ( exists($BrailleUnicodeToEthiopic{$_}) ) {
			if (
			      $base && $base !~ /[እዕውይ]/ &&
			      $BrailleUnicodeToEthiopic{$_} eq 'ው' 
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
				$base = $BrailleUnicodeToEthiopic{$_};
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
			if ( exists($BrailleUnicodeToEthiopicNumerals{$_}) ) {
				$trans .= $base.$BrailleUnicodeToEthiopicNumerals{$_};
			}
			elsif ( exists($BrailleUnicodeToEthiopicPunctuation{$_}) ) {
				$trans .= $base.$BrailleUnicodeToEthiopicPunctuation{$_};
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


sub	ethiopicToBrailleUnicode
{

	return unless ( $_[0] );

	my @chars  = split ( //, $_[0] );

	my $trans;

	#
    # change to for loop
	#
	while  ( $_ = shift @chars ) {

		if ( exists($EthiopicToBrailleUnicode{$_}) ) {
			$trans .= $EthiopicToBrailleUnicode{$_};
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
				$trans .= $EthiopicToBrailleUnicode{$sadis}.$EthiopicForms[$form];
			}
		}
		elsif ( /[፡-፨]/ ) {
			$trans .= "$EthiopicPunctuationToBrailleUnicode{$_}";
		}
		elsif ( /[፩-፼]/ ) {
			my $number = $_;
			my $c;
			while ( @chars && (($c = shift @chars) =~ /[፩-፼]/) ) {
					$number .= $c;
			}
			unshift ( @chars, $c ) if ( $c );  # might have end of string

			my $result = brailleAsciiToUnicode ( $n->convert ( $number ) );
			$trans .= "$BrailleAsciiToUnicode{'#'}$result";
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


sub	ethiopicToBrailleAscii
{
	brailleUnicodeToAscii ( ethiopicToBrailleUnicode ( @_ ) );
}


sub	ethiopicToBrailleDots
{
	brailleUnicodeToDots ( ethiopicToBrailleUnicode ( @_ ) );
}


sub	brailleAsciiToEthiopic
{
	brailleUnicodeToEthiopic ( brailleAsciiToUnicode ( @_ ) );
}


sub	brailleDotsToEthiopic
{
	brailleUnicodeToEthiopic ( brailleDotsToUnicode ( @_ ) );
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

 Convert::Braille::Ethiopic - Convert Between Braille Encodings.

=head1 SYNOPSIS

 use Convert::Braille::Ethiopic;

 print brailleAsciiToEthiopic ( "S5LAM" ), "\n";
 print brailleDotsToEthiopic  ( "234261231134" ), "\n";


=head1 REQUIRES

perl5.6.0 or later, L<Convert::Number::Ethiopic>

=head1 EXPORTS

=over 4

=item ethiopicToBrailleUnicode

=item ethiopicToBrailleAscii

=item ethiopicToBrailleDots

=item brailleAsciiToEthiopic

=item brailleDotsToEthiopic

=item brailleUnicodeToEthiopic

=back

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Convert::Braille>    L<Convert::Braille::English>

Included with this package:

  examples/demo.pl    examples/makeethiopic.pl

=cut
