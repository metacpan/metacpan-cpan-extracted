package Business::Zahlschein;

use warnings;
use strict;

our $VERSION = '0.02';

BEGIN {
	use Exporter;
	our @ISA         = qw( Exporter );
	our @EXPORT      = qw( );
	our %EXPORT_TAGS = ( );
	our @EXPORT_OK   = qw( &PzMehrzweckfeld &Mehrzweckfeld );
}

sub PzMehrzweckfeld {

	my $mehrzweckfeld = shift;
	my $zwischensumme = 0;
	my $gesamtsumme   = 0;

	my $tab = "12121212121";

	for (my $i = 0; $i <= 10; $i++) {
		$zwischensumme = substr($mehrzweckfeld,$i,1) * substr($tab,$i,1);
		$gesamtsumme   = $gesamtsumme + Quersumme($zwischensumme);
	} # for

	$zwischensumme = 10 - ($gesamtsumme % 10);
	$zwischensumme = 0 if $zwischensumme == 10;

	$zwischensumme;

} # PzMehrzweckfeld

sub Mehrzweckfeld {

	my ($mehrzweckfeld, $pzMehrzweckfeld, $kontonummer, $blz, $belegart) = @_;

	my $mzfKontoNrBlz = $mehrzweckfeld.$pzMehrzweckfeld.$kontonummer.substr($blz,- 5);

	my $zwischensumme = 0;
	my $gesamtsumme   = 0;
	my $summe         = 0;
	my $pzBlz         = "";
	my $lz            = "";

	my $tab = "1791791791791791791791791791";

	for (my $i = 0; $i <= 27; $i++) {
		$zwischensumme = substr($mzfKontoNrBlz,$i,1) * substr($tab,$i,1);
		$gesamtsumme   = $gesamtsumme + $zwischensumme;
	} # for

	$zwischensumme = $gesamtsumme % 10;
	$pzBlz         = $zwischensumme;

	$lz = $mehrzweckfeld.$pzMehrzweckfeld."< ".$kontonummer."+ ".$pzBlz.$blz.">              ".$belegart."+";

	$lz;

} # Mehrzweckfeld

sub Quersumme {

   my $zwischensumme = shift;
	my $quersumme     = 0;

	for (my $i = 0; $i < length($zwischensumme); $i++) {
		$quersumme = $quersumme + substr($zwischensumme,$i,1);
	} # for

	$quersumme;

} # Quersumme


1;
__END__

=pod

=head1 NAME

Zahlschein - a module for check digit computation

=head1 SYNOPSIS

  use warnings;
  use strict;
  use Business::Zahlschein qw( PzMehrzweckfeld Mehrzweckfeld );

  # fuer Berechnung mit Pruefziffer im Mehrzweckfeld
  use Business::Zahlschein qw( PzMehrzweckfeld Mehrzweckfeld );
  my $mehrzweckfeld   = "01234567890";
  my $kontoNr         = "00000012345";
  my $blz             = "10"."12000"; # ohne Betrag + BLZ
  my $belegart        = "42";
  my $pzMehrzweckfeld = PzMehrzweckfeld($mehrzweckfeld);
  my $lesezone        = Mehrzweckfeld($mehrzweckfeld, $pzMehrzweckfeld, $kontoNr, $blz, $belegart);

  # fuer Berechnung ohne Pruefziffer im Mehrzweckfeld
  use Business::Zahlschein qw( Mehrzweckfeld );
  my $mehrzweckfeld = "012345678901";
  my $kontoNr       = "00000012345";
  my $blz           = "10"."12000"; # ohne Betrag + BLZ
  my $belegart      = "42";
  my $lesezone      = Mehrzweckfeld($mehrzweckfeld, $pzMehrzweckfeld, $kontoNr, $blz, $belegart);

=head1 DESCRIPTION

...

=head1 AUTHOR AND LICENSE

copyright 2009 (c)
Gernot Havranek

=cut
