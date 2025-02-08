package Convert::CEGH::Transliterate;
use warnings;
use strict;
use utf8;
use Regexp::Ethiopic qw(:forms setForm);

BEGIN
{
use base qw( Exporter );
use vars qw( $COPTIC @EXPORT_OK $VERSION );

	@EXPORT_OK = qw( transliterate );

	$VERSION = "0.06";

	$COPTIC = qr/[ϚCϢϤϦϨϬϮϪ]/;
}


sub fromIPA
{
my ($string, $script) = @_;

	$_ = $string;

	if ( $script =~ /^et/ ) {
		tr/ʤʧΘv/ztzb/;
		s/k'/q/g;
		s/p'/P/g;
		s/s'/S/g;
		s/t'/T/g;
		s/d'/D/g;
		tr/abgdhwzħTjklmnsʕfSqrʃtξDPp/አበገደሀወዘሐጠየከለመነሠዐፈጸቀረሰተኀፀጰፐ/;
	}
	elsif ( $script =~ /^he/ ) {
		tr/xfʤʧv/kpztb/;
		s/k'/q/g;
		s/s'/S/g;
		s/d'/d/g;
		s/p'/p/g;
		s/t'/t/g;
		s/ξ/h/g;
		tr/abgdhwzħΘjklmnsʕpSqrʃt/אבגדהוזחטיכלמנסעפצקרשת/;
		$_ = scalar reverse ( $_ );
	}
	elsif ( $script =~ /^el/ || $script =~ /^co/ ) {
		tr/ʤʧʕwv/ztabb/;
		s/ps/P/g;
		s/d'/d/g;
		s/p'/p/g;
		s/t'/t/g;
		s/ξ/h/g;
		tr/abgdazaΘaklmnxaprstafʧPa/ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΧΨΩ/;
		#
		# this is broken, the coptic extras are missing
		# and greek isn't mapping the extras, what is "w" is greek?
	}

	$_
}


sub toIPA
{

	$_ = $_[0];

	if ( /$COPTIC/ || /\p{Greek}/ ) {
		$_ = uc($_);
		tr/ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ/abgdazaΘaklmnKaprstafxPa/;
		if ( /$COPTIC/ ) {
			tr/ϚCϢϤϦϨϪϬ/ssʃfxhʤʧ/;
			s/Ϯ/t/g;  # really "ti" but we ignore the vowel.
		}
		s/[ϚϜ]/w/g;
		s/[ϘϞ]/k'/g;
		s/K/kh/g;
		s/P/ps/g;
	}
	if ( /\p{Ethiopic}/ ) {
		s/(.)/setForm($1,$ግዕዝ)/eg;
		tr/አበገደሀወዘሐጠየከለመነሠዐፈጸቀረሰተኀፀጰፐ/abgdhwzħTjklmnsʕfSqrʃtξDPp/;
		#
		# convert placeholder symbols to multiple symbols:
		#
		s/q/k'/g;
		s/P/p'/g;
		s/S/s'/g;
		s/T/t'/g;
		s/C/ʧ'/g;
		s/D/d'/g;
	}
	if ( /\p{Hebrew}/ ) {
		$_ = scalar reverse ( $_ );
		#
		# map finals to initials/medials:
		#
		s/ך/כ/g;
		s/ץ/צ/g;
		s/ף/פ/g;
		s/ם/מ/g;
		s/ן/נ/g;
		tr/אבגדהוזחטיכלמנסעפצקרשת/abgdhwzħΘjklmnsʕpSqrʃt/;
		#
		# convert placeholder symbols to multiple symbols:
		#
		s/q/k'/;
		s/S/s'/;
	}
	s/(.)a/$1/g;  # strip vowels except first

	$_;
}


sub transliterate
{
my ( $to, @strings ) = @_;

	my ( @trans ) = ();
	foreach ( @strings ) {
		push ( @trans, fromIPA ( toIPA ( $_ ), $to ) );
	}

	( wantarray ) ? @trans : $trans[0] ;
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__

=encoding utf8

=head1 NAME

Convert::CEGH::Transliterate - Coptic/Ethiopic/Greek/Hebrew Transliteration.

=head1 SYNOPSIS

  use utf8;
  binmode (STDOUT, ":utf8");
  use Convert::CEGH::Transliterate 'transliterate';

  print transliterate ( "he", "አዳም" ), "\n";

=head1 DESCRIPTION

This package makes available a single function C<transliterate> which will
convert a word (or list of words) into the script specified in the first
argument.  Valid scripts values are "cop", "eth", "ell", "heb" and
"co", "et", "el", "he".  These are the 3 and 2 letter ISO 15924 script
codes for Coptic, Ethiopic, Greek and Hebrew.


=head1 LIMITATIONS

The Metaphone rule of stripping out all but the first vowel of a word is
applied.  Leading vowels are otherwise converted into 'a'.

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 REFERENCES

=over 4

=item Greek:

=over 4

=item L<http://www.omniglot.com/writing/greek.htm>

=item L<http://www.ancientscripts.com/greek.html>

=back

=item Coptic:

=over 4

=item L<http://www.omniglot.com/writing/coptic.htm>

=item L<http://www.ancientscripts.com/coptic.html>

=back

=item Hebrew:

=over 4

=item L<http://www.ancient-hebrew.org/4_chart.html>

=back

=back

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<Convert::CEGH::Gematria>

Included with this package:

  examples/transliterate.pl

=cut
