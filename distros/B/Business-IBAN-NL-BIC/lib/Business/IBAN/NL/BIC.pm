package Business::IBAN::NL::BIC;

use warnings;
use strict;

our $VERSION = '1.00';

my %bic;
my %name;

foreach ( <DATA> ) {
  my ( $bic, $bankcode, @name ) = split /\s+/;
  $bic{$bankcode} = $bic;
  $name{$bankcode} = join ( ' ', @name );
}
close DATA;

sub new {
  bless {}, shift;
}

sub bic {
  my $self = shift if ref $_[0];
  my $iban = uc ( shift );
  
  if ( $iban =~ /^NL[0-9]{2}([A-Z]{4})[0-9]+$/ ) {
    return $bic{$1};
  }
  return undef;
  
}

sub name {
  my $self = shift if ref $_[0];
  my $iban = uc ( shift );
  
  if ( $iban =~ /^NL[0-9]{2}([A-Z]{4})[0-9]+$/ ) {
    return $name{$1};
  }
  return undef;
  
}

1;

=head1 NAME

Business::IBAN::NL::BIC - Lookup Dutch BIC and bank names from IBAN numbers.

=head1 DESCRIPTION

For Dutch IBAN numbers the bank code is contained within the account number.
The bank code can be used to determine the BIC and the name of the bank at
which the account is located.

The information contained in this module is taken from
https://www.betaalvereniging.nl/giraal-en-online-betalen/sepa-documentatie-voor-nederland/bic-afleiden-uit-iban/
and contains correct information as of the date of the upload of this
module. Last changes on that page were made on 4th of March 2016.

=head1 LIMITATIONS

This module works only for valid Dutch IBAN numbers. It does not check IBAN
numbers for correctness, please take a look at Business::IBAN::Validator for
that.

=head1 METHODS

This module provides an object oriented interface but all methods can also
be called as regular functions (specify full package name in those cases,
function names are not exported).

=head2 new

Constructor; does not take any arguments.

=head2 bic($iban)

Return the BIC code for a specific Dutch IBAN. If the IBAN is not Dutch or
the bank code contained in the IBAN is not recognized this method returns
undef.

=head2 name($iban)

Return the name of the bank controlling the specified Dutch IBAN account. If
the IBAN is not Dutch or the bank code contained in the IBAN is not
recognized this method returns undef.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__DATA__
ABNANL2A	ABNA	ABN AMRO BANK
ABNANL2A	FTSB	ABN AMRO BANK (ex FORTIS)
AEGONL2U	AEGO	AEGON BANK
ANAANL21	ANAA	ALLIANZ NEDERLAND ASSET MANAGEMENT
ANDLNL2A	ANDL	ANADOLUBANK
ARBNNL22	ARBN	ACHMEA BANK
ARSNNL21	ARSN	ARGENTA SPAARBANK
ASNBNL21	ASNB	ASN BANK
ATBANL2A	ATBA	AMSTERDAM TRADE BANK
BCDMNL22	BCDM	BANQUE CHAABI DU MAROC
BCITNL2A	BCIT	INTESA SANPAOLO
BICKNL2A	BICK	BINCKBANK
BINKNL21	BINK	BINCKBANK, PROF
BKCHNL2R	BKCH	BANK OF CHINA
BKMGNL2A	BKMG	BANK MENDES GANS
BLGWNL21	BLGW	BLG WONEN
BMEUNL21	BMEU	BMCE EUROSERVICES
BNGHNL2G	BNGH	BANK NEDERLANDSE GEMEENTEN
BNPANL2A	BNPA	BNP PARIBAS
BOFANLNX	BOFA	BANK OF AMERICA
BOFSNL21002	BOFS	BANK OF SCOTLAND, AMSTERDAM
BOTKNL2X	BOTK	MUFG BANK
BUNQNL2A	BUNQ	BUNQ
CHASNL2X	CHAS	JPMORGAN CHASE
CITCNL2A	CITC	CITCO BANK
CITINL2X	CITI	CITIBANK INTERNATIONAL
COBANL2X	COBA	COMMERZBANK
DEUTNL2N	DEUT	DEUTSCHE BANK (bij alle SEPA transacties)
DHBNNL2R	DHBN	DEMIR-HALK BANK
DLBKNL2A	DLBK	DELTA LLOYD BANK
DNIBNL2G	DNIB	NIBC BANK
FBHLNL2A	FBHL	CREDIT EUROPE BANK
FLORNL2A	FLOR	DE NEDERLANDSCHE BANK
FRGHNL21	FRGH	FGH BANK
FVLBNL22	FVLB	F. VAN LANSCHOT BANKIERS
GILLNL2A	GILL	THEODOOR GILISSEN
HANDNL2A	HAND	SVENSKA HANDELSBANKEN
HHBANL22	HHBA	HOF HOORNEMAN BANKIERS
HSBCNL2A	HSBC	HSBC BANK
ICBKNL2A	ICBK	INDUSTRIAL & COMMERCIAL BANK OF CHINA
INGBNL2A	INGB	ING BANK
INSINL2A	INSI	INSINGER DE BEAUFORT
ISBKNL2A	ISBK	ISBANK
KABANL2A	KABA	YAPI KREDI BANK
KASANL2A	KASA	KAS BANK
KNABNL2H	KNAB	KNAB
KOEXNL2A	KOEX	KOREA EXCHANGE BANK
KREDNL2X	KRED	KBC BANK
LOCYNL2A	LOCY	LOMBARD ODIER DARIER HENTSCH & CIE
LOYDNL2A	LOYD	LLOYDS TSB BANK
LPLNNL2F	LPLN	LEASEPLAN CORPORATION
MHCBNL2A	MHCB	MIZUHO CORPORATE BANK
NNBANL2G	NNBA	NATIONALE-NEDERLANDEN BANK
NWABNL2G	NWAB	NEDERLANDSE WATERSCHAPSBANK
PCBCNL2A	PCBC	CHINA CONSTRUCTION BANK, AMSTERDAM BRANCH
RABONL2U	RABO	RABOBANK
RBOSNL2A	RBOS	ROYAL BANK OF SCOTLAND
RBRBNL21	RBRB	REGIOBANK
SNSBNL2A	SNSB	SNS BANK
SOGENL2A	SOGE	SOCIETE GENERALE
STALNL2G	STAL	STAALBANKIERS
TEBUNL2A	TEBU	THE ECONOMY BANK
TRIONL2U	TRIO	TRIODOS BANK
UBSWNL2A	UBSW	UBS BANK
UGBINL2A	UGBI	GARANTIBANK INTERNATIONAL
VOWANL21	VOWA	VOLKSWAGEN BANK
ZWLBNL21	ZWLB	ZWITSERLEVENBANK
