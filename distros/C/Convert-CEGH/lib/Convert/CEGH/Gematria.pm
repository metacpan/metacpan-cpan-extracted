package Convert::CEGH::Gematria;
use warnings;
use strict;
use utf8;
use Regexp::Ethiopic qw(:forms setForm);

BEGIN
{
use base qw( Exporter );
use vars qw( $አበገደ $ሀለሐመ  $תיבפלא $ΑΛΦΑΒΕΤ %Gematria @EXPORT_OK $VERSION $use_halehame );


	@EXPORT_OK = qw( enumerate );

	$VERSION = "0.07";

	#
	# Gematria Data:
	#
	$አበገደ    = "አበገደሀወዘሐጠየከለመነሠዐፈጸቀረሰተኀፀጰፐኈ"; # ቈ 1,000 እ 10,000
	$תיבפלא  = "אבגדהוזחטיכלמנסעפצקרשתךםןףץ";
	$ΑΛΦΑΒΕΤ = "ΑΒΓΔΕϚΖΗΘΙΚΛΜΝΞΟΠϘΡΣΤΥΦΧΨΩϠ"; #  Ϛ/Ϝ
	$ሀለሐመ    = "ሀለሐመሠረሰቀበተኀነአከወዐዘየደገጠጰጸፀፈፐ";
	# $Coptic  ="ΑΒΓΔΕϚΖΗϴΙΚΛΜΝΞΟΠ ΡCΤΥΦΧΨΩϢϤϦϨϪϬϮ";

	%Gematria =(
		eth => $አበገደ,
		heb => $תיבפלא,
		ell => $ΑΛΦΑΒΕΤ,
		et  => $አበገደ,
		he  => $תיבפלא,
		el  => $ΑΛΦΑΒΕΤ,
		et_halehame => $ሀለሐመ
	);

	$use_halehame = 0;
}


#
#  unfortunately the index function in Perl 5.8.0 is broken for some
#  Unicode sequences: http://rt.perl.org/rt2/Ticket/Display.html?id=22375
#
sub _index
{
my ( $haystack, $needle ) = @_;

	my $pos = my $found = 0;
	foreach (split (//, $haystack) ) {
		$found = 1 if ( /$needle/ );
		$pos++ unless ( $found );
	}

	$pos;
}


sub _simplify
{
my ($string) = @_;

	#
	# Allow mixed language Gematria:
	#
	if ( $string =~ /[$תיבפלא]/ ) {
		#
		#  Remove what we don't know.
		#  This also strips vowel markers
		#
		$string =~ s/[^$תיבפלא]//og;
		return ( $string, "heb" );
	}
	if ( $string =~ /[$ΑΛΦΑΒΕΤ]/ ) {
		#
		# this probably doesn't work, test it
		# and replace with a tr later if it fails:
		#
		$string = uc($string);
		$string =~ s/Ϝ/Ϛ/g;
		$string =~ s/Ϟ/Ϙ/g;
		return ( $string, "ell" );
	}
	if ( $string =~ /\p{Ethiopic}/ ) {
		$string =~ s/(.)/($1 eq "ኈ" ) ? "ኈ" : setForm($1,$ግዕዝ)/eg;
		if ( $use_halehame ) {
			$string =~ s/(ኈ)/setForm($1,$ግዕዝ)/eg;
			return ( $string, "et_halehame" );
		}
		else {
			return ( $string, "eth" );
		}
	}

}


sub enumerate
{
my ( @strings ) = @_;

	my ( @sums ) = ();
	foreach ( @strings ) {
		my ($string, $from) = _simplify ( $_ );

		my @letters = split ( //, $string );

		my $sum = 0;
		foreach my $letter (@letters) {
			my $pos = _index ( $Gematria{$from}, $letter );
			# my $value = (1+(int $pos/10)+$pos%10)*10**(int $pos/10);
			# my $exp = int $pos/10;
			# my $power = 10**$exp;
			# print "$letter => $pos / $exp / $power / $value\n";
			$sum += (1+(int $pos/10)+$pos%10)*10**(int $pos/10);
		}

		push ( @sums, $sum );
	}

	( wantarray ) ? @sums : $sums[0] ;
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__

=encoding utf8

=head1 NAME

Convert::CEGH::Gematria - Coptic/Ethiopic/Greek/Hebrew Gematria.

=head1 SYNOPSIS

  use utf8;
  binmode (STDOUT, ":utf8");
  use Convert::CEGH::Gematria 'enumerate';

  print "Hebrew: מדא  => ", enumerate ( "מדא" ), "\n";
  print "Ge'ez : አዳም  => ", enumerate ( "አዳም" ), "\n";
  print "Greek : ΑΔΑΜ => ", enumerate ( "ΑΔΑΜ" ), "\n";

=head1 DESCRIPTION

This package makes available a single function C<enumerate> which will
compute a numeric value based on Gematria rules.  Gematria calculations
are applicable to Coptic, Ethiopic, Greek and Hebrew scripts.

The enumerate function will accept a single word as an argument or a
list of words.

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 REFERENCES

=over 4

=item L<http://geez.org/Numerals/Numerology.html>

=item L<http://www.geocities.com/Athens/Parthenon/7069/key-1.html>

=back

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<Convert::CEGH::Transliterate>

Included with this package:

  examples/gematria.pl

=cut
