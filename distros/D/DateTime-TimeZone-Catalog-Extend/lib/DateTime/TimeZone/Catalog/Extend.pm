##----------------------------------------------------------------------------
## Extend DateTime::TimeZone catalog - ~/lib/DateTime/TimeZone/Catalog/Extend.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/11/29
## Modified 2022/12/01
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::TimeZone::Catalog::Extend;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use Exporter ();
    use vars qw( $VERSION @ISA $ALIAS_CATALOG );
    our @ISA = qw( Exporter );
    use DateTime::TimeZone::Alias;
    use Nice::Try;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

# <https://en.wikipedia.org/wiki/List_of_time_zone_abbreviations>
$ALIAS_CATALOG =
{
  ACDT  => {
             comment => "Australian Central Daylight Saving Time",
             offset  => ["+10:30"],
           },
  ACST  => { comment => "Australian Central Standard Time", offset => ["+09:30"] },
  ACT   => { comment => "ASEAN Common Time (proposed)", offset => ["+08:00"] },
  ACWST => {
             comment => "Australian Central Western Standard Time (unofficial)",
             offset  => ["+08:45"],
           },
  ADT   => { comment => "Atlantic Daylight Time", offset => ["-03:00"] },
  AEDT  => {
             comment => "Australian Eastern Daylight Saving Time",
             offset  => ["+11:00"],
           },
  AEST  => { comment => "Australian Eastern Standard Time", offset => ["+10:00"] },
  AET   => {
             comment => "Australian Eastern Time",
             offset  => ["+10:00", "+11:00"],
           },
  AFT   => { comment => "Afghanistan Time", offset => ["+04:30"] },
  AKDT  => { comment => "Alaska Daylight Time", offset => ["-08:00"] },
  AKST  => { comment => "Alaska Standard Time", offset => ["-09:00"] },
  ALMT  => { comment => "Alma-Ata Time[1]", offset => ["+06:00"] },
  AMST  => { comment => "Amazon Summer Time (Brazil)[2]", offset => ["-03:00"] },
  AMT   => { comment => "Armenia Time", offset => ["+04:00"] },
  ANAT  => { comment => "Anadyr Time[4]", offset => ["+12:00"] },
  AQTT  => { comment => "Aqtobe Time[5]", offset => ["+05:00"] },
  ART   => { comment => "Argentina Time", offset => ["-03:00"] },
  AST   => { comment => "Atlantic Standard Time", offset => ["-04:00"] },
  AWST  => { comment => "Australian Western Standard Time", offset => ["+08:00"] },
  AZOST => { comment => "Azores Summer Time", offset => ["UTC"] },
  AZOT  => { comment => "Azores Standard Time", offset => ["-01:00"] },
  AZT   => { comment => "Azerbaijan Time", offset => ["+04:00"] },
  BIOT  => { comment => "British Indian Ocean Time", offset => ["+06:00"] },
  BIT   => { comment => "Baker Island Time", offset => ["-12:00"] },
  BNT   => { comment => "Brunei Time", offset => ["+08:00"] },
  BOT   => { comment => "Bolivia Time", offset => ["-04:00"] },
  BRST  => { comment => "Bras\xEDlia Summer Time", offset => ["-02:00"] },
  BRT   => { comment => "Bras\xEDlia Time", offset => ["-03:00"] },
  BST   => {
             comment => "British Summer Time (British Standard Time from Feb 1968 to Oct 1971)",
             offset  => ["+01:00"],
           },
  BTT   => { comment => "Bhutan Time", offset => ["+06:00"] },
  CAT   => { comment => "Central Africa Time", offset => ["+02:00"] },
  CCT   => { comment => "Cocos Islands Time", offset => ["+06:30"] },
  CDT   => { comment => "Cuba Daylight Time[7]", offset => ["-04:00"] },
  CEST  => { comment => "Central European Summer Time", offset => ["+02:00"] },
  CET   => { comment => "Central European Time", offset => ["+01:00"] },
  CHADT => { comment => "Chatham Daylight Time", offset => ["+13:45"] },
  CHAST => { comment => "Chatham Standard Time", offset => ["+12:45"] },
  CHOST => { comment => "Choibalsan Summer Time", offset => ["+09:00"] },
  CHOT  => { comment => "Choibalsan Standard Time", offset => ["+08:00"] },
  CHST  => { comment => "Chamorro Standard Time", offset => ["+10:00"] },
  CHUT  => { comment => "Chuuk Time", offset => ["+10:00"] },
  CIST  => { comment => "Clipperton Island Standard Time", offset => ["-08:00"] },
  CKT   => { comment => "Cook Island Time", offset => ["-10:00"] },
  CLST  => { comment => "Chile Summer Time", offset => ["-03:00"] },
  CLT   => { comment => "Chile Standard Time", offset => ["-04:00"] },
  COST  => { comment => "Colombia Summer Time", offset => ["-04:00"] },
  COT   => { comment => "Colombia Time", offset => ["-05:00"] },
  CST   => { comment => "Cuba Standard Time", offset => ["-05:00"] },
  CT    => { comment => "Central Time", offset => ["-06:00", "-05:00"] },
  CVT   => { comment => "Cape Verde Time", offset => ["-01:00"] },
  CWST  => {
             comment => "Central Western Standard Time (Australia) unofficial",
             offset  => ["+08:45"],
           },
  CXT   => { comment => "Christmas Island Time", offset => ["+07:00"] },
  DAVT  => { comment => "Davis Time", offset => ["+07:00"] },
  DDUT  => { comment => "Dumont d'Urville Time", offset => ["+10:00"] },
  DFT   => {
             comment => "AIX-specific equivalent of Central European Time[NB 1]",
             offset  => ["+01:00"],
           },
  EASST => { comment => "Easter Island Summer Time", offset => ["-05:00"] },
  EAST  => { comment => "Easter Island Standard Time", offset => ["-06:00"] },
  EAT   => { comment => "East Africa Time", offset => ["+03:00"] },
  ECT   => { comment => "Ecuador Time", offset => ["-05:00"] },
  EDT   => {
             comment => "Eastern Daylight Time (North America)",
             offset  => ["-04:00"],
           },
  EEST  => { comment => "Eastern European Summer Time", offset => ["+03:00"] },
  EET   => { comment => "Eastern European Time", offset => ["+02:00"] },
  EGST  => { comment => "Eastern Greenland Summer Time", offset => ["UTC"] },
  EGT   => { comment => "Eastern Greenland Time", offset => ["-01:00"] },
  EST   => {
             comment => "Eastern Standard Time (North America)",
             offset  => ["-05:00"],
           },
  ET    => {
             comment => "Eastern Time (North America) UTC-05 /",
             offset  => ["-04:00"],
           },
  FET   => { comment => "Further-eastern European Time", offset => ["+03:00"] },
  FJT   => { comment => "Fiji Time", offset => ["+12:00"] },
  FKST  => { comment => "Falkland Islands Summer Time", offset => ["-03:00"] },
  FKT   => { comment => "Falkland Islands Time", offset => ["-04:00"] },
  FNT   => { comment => "Fernando de Noronha Time", offset => ["-02:00"] },
  GALT  => { comment => "Gal\xE1pagos Time", offset => ["-06:00"] },
  GAMT  => { comment => "Gambier Islands Time", offset => ["-09:00"] },
  GET   => { comment => "Georgia Standard Time", offset => ["+04:00"] },
  GFT   => { comment => "French Guiana Time", offset => ["-03:00"] },
  GILT  => { comment => "Gilbert Island Time", offset => ["+12:00"] },
  GIT   => { comment => "Gambier Island Time", offset => ["-09:00"] },
  GMT   => { comment => "Greenwich Mean Time", offset => ["UTC"] },
  GST   => { comment => "Gulf Standard Time", offset => ["+04:00"] },
  GYT   => { comment => "Guyana Time", offset => ["-04:00"] },
  HAEC  => {
             comment => "Heure Avanc\xE9e d'Europe Centrale French-language name for CEST",
             offset  => ["+02:00"],
           },
  HDT   => {
             comment => "Hawaii\x{2013}Aleutian Daylight Time",
             offset  => ["-09:00"],
           },
  HKT   => { comment => "Hong Kong Time", offset => ["+08:00"] },
  HMT   => { comment => "Heard and McDonald Islands Time", offset => ["+05:00"] },
  HOVST => {
             comment => "Hovd Summer Time (not used from 2017-present)",
             offset  => ["+08:00"],
           },
  HOVT  => { comment => "Hovd Time", offset => ["+07:00"] },
  HST   => {
             comment => "Hawaii\x{2013}Aleutian Standard Time",
             offset  => ["-10:00"],
           },
  ICT   => { comment => "Indochina Time", offset => ["+07:00"] },
  IDLW  => {
             comment => "International Day Line West time zone",
             offset  => ["-12:00"],
           },
  IDT   => { comment => "Israel Daylight Time", offset => ["+03:00"] },
  IOT   => { comment => "Indian Ocean Time", offset => ["+03:00"] },
  IRDT  => { comment => "Iran Daylight Time", offset => ["+04:30"] },
  IRKT  => { comment => "Irkutsk Time", offset => ["+08:00"] },
  IRST  => { comment => "Iran Standard Time", offset => ["+03:30"] },
  IST   => { comment => "Israel Standard Time", offset => ["+02:00"] },
  JST   => { comment => "Japan Standard Time", offset => ["+09:00"] },
  KALT  => { comment => "Kaliningrad Time", offset => ["+02:00"] },
  KGT   => { comment => "Kyrgyzstan Time", offset => ["+06:00"] },
  KOST  => { comment => "Kosrae Time", offset => ["+11:00"] },
  KRAT  => { comment => "Krasnoyarsk Time", offset => ["+07:00"] },
  KST   => { comment => "Korea Standard Time", offset => ["+09:00"] },
  LHST  => { comment => "Lord Howe Summer Time", offset => ["+11:00"] },
  LINT  => { comment => "Line Islands Time", offset => ["+14:00"] },
  MAGT  => { comment => "Magadan Time", offset => ["+12:00"] },
  MART  => { comment => "Marquesas Islands Time", offset => ["-09:30"] },
  MAWT  => { comment => "Mawson Station Time", offset => ["+05:00"] },
  MDT   => {
             comment => "Mountain Daylight Time (North America)",
             offset  => ["-06:00"],
           },
  MEST  => {
             comment => "Middle European Summer Time (same zone as CEST)",
             offset  => ["+02:00"],
           },
  MET   => {
             comment => "Middle European Time (same zone as CET)",
             offset  => ["+01:00"],
           },
  MHT   => { comment => "Marshall Islands Time", offset => ["+12:00"] },
  MIST  => { comment => "Macquarie Island Station Time", offset => ["+11:00"] },
  MIT   => { comment => "Marquesas Islands Time", offset => ["-09:30"] },
  MMT   => { comment => "Myanmar Standard Time", offset => ["+06:30"] },
  MSK   => { comment => "Moscow Time", offset => ["+03:00"] },
  MST   => {
             comment => "Mountain Standard Time (North America)",
             offset  => ["-07:00"],
           },
  MUT   => { comment => "Mauritius Time", offset => ["+04:00"] },
  MVT   => { comment => "Maldives Time", offset => ["+05:00"] },
  MYT   => { comment => "Malaysia Time", offset => ["+08:00"] },
  NCT   => { comment => "New Caledonia Time", offset => ["+11:00"] },
  NDT   => { comment => "Newfoundland Daylight Time", offset => ["-02:30"] },
  NFT   => { comment => "Norfolk Island Time", offset => ["+11:00"] },
  NOVT  => { comment => "Novosibirsk Time [9]", offset => ["+07:00"] },
  NPT   => { comment => "Nepal Time", offset => ["+05:45"] },
  NST   => { comment => "Newfoundland Standard Time", offset => ["-03:30"] },
  NT    => { comment => "Newfoundland Time", offset => ["-03:30"] },
  NUT   => { comment => "Niue Time", offset => ["-11:00"] },
  NZDT  => { comment => "New Zealand Daylight Time", offset => ["+13:00"] },
  NZST  => { comment => "New Zealand Standard Time", offset => ["+12:00"] },
  OMST  => { comment => "Omsk Time", offset => ["+06:00"] },
  ORAT  => { comment => "Oral Time", offset => ["+05:00"] },
  PDT   => {
             comment => "Pacific Daylight Time (North America)",
             offset  => ["-07:00"],
           },
  PET   => { comment => "Peru Time", offset => ["-05:00"] },
  PETT  => { comment => "Kamchatka Time", offset => ["+12:00"] },
  PGT   => { comment => "Papua New Guinea Time", offset => ["+10:00"] },
  PHOT  => { comment => "Phoenix Island Time", offset => ["+13:00"] },
  PHST  => { comment => "Philippine Standard Time", offset => ["+08:00"] },
  PHT   => { comment => "Philippine Time", offset => ["+08:00"] },
  PKT   => { comment => "Pakistan Standard Time", offset => ["+05:00"] },
  PMDT  => {
             comment => "Saint Pierre and Miquelon Daylight Time",
             offset  => ["-02:00"],
           },
  PMST  => {
             comment => "Saint Pierre and Miquelon Standard Time",
             offset  => ["-03:00"],
           },
  PONT  => { comment => "Pohnpei Standard Time", offset => ["+11:00"] },
  PST   => {
             comment => "Pacific Standard Time (North America)",
             offset  => ["-08:00"],
           },
  PWT   => { comment => "Palau Time[10]", offset => ["+09:00"] },
  PYST  => { comment => "Paraguay Summer Time[11]", offset => ["-03:00"] },
  PYT   => { comment => "Paraguay Time[12]", offset => ["-04:00"] },
  RET   => { comment => "R\xE9union Time", offset => ["+04:00"] },
  ROTT  => { comment => "Rothera Research Station Time", offset => ["-03:00"] },
  SAKT  => { comment => "Sakhalin Island Time", offset => ["+11:00"] },
  SAMT  => { comment => "Samara Time", offset => ["+04:00"] },
  SAST  => { comment => "South African Standard Time", offset => ["+02:00"] },
  SBT   => { comment => "Solomon Islands Time", offset => ["+11:00"] },
  SCT   => { comment => "Seychelles Time", offset => ["+04:00"] },
  SDT   => { comment => "Samoa Daylight Time", offset => ["-10:00"] },
  SGT   => { comment => "Singapore Time", offset => ["+08:00"] },
  SLST  => { comment => "Sri Lanka Standard Time", offset => ["+05:30"] },
  SRET  => { comment => "Srednekolymsk Time", offset => ["+11:00"] },
  SRT   => { comment => "Suriname Time", offset => ["-03:00"] },
  SST   => { comment => "Singapore Standard Time", offset => ["+08:00"] },
  SYOT  => { comment => "Showa Station Time", offset => ["+03:00"] },
  TAHT  => { comment => "Tahiti Time", offset => ["-10:00"] },
  TFT   => {
             comment => "French Southern and Antarctic Time[13]",
             offset  => ["+05:00"],
           },
  THA   => { comment => "Thailand Standard Time", offset => ["+07:00"] },
  TJT   => { comment => "Tajikistan Time", offset => ["+05:00"] },
  TKT   => { comment => "Tokelau Time", offset => ["+13:00"] },
  TLT   => { comment => "Timor Leste Time", offset => ["+09:00"] },
  TMT   => { comment => "Turkmenistan Time", offset => ["+05:00"] },
  TOT   => { comment => "Tonga Time", offset => ["+13:00"] },
  TRT   => { comment => "Turkey Time", offset => ["+03:00"] },
  TVT   => { comment => "Tuvalu Time", offset => ["+12:00"] },
  ULAST => { comment => "Ulaanbaatar Summer Time", offset => ["+09:00"] },
  ULAT  => { comment => "Ulaanbaatar Standard Time", offset => ["+08:00"] },
  UTC   => { comment => "Coordinated Universal Time", offset => ["UTC"] },
  UYST  => { comment => "Uruguay Summer Time", offset => ["-02:00"] },
  UYT   => { comment => "Uruguay Standard Time", offset => ["-03:00"] },
  UZT   => { comment => "Uzbekistan Time", offset => ["+05:00"] },
  VET   => { comment => "Venezuelan Standard Time", offset => ["-04:00"] },
  VLAT  => { comment => "Vladivostok Time", offset => ["+10:00"] },
  VOLT  => { comment => "Volgograd Time", offset => ["+03:00"] },
  VOST  => { comment => "Vostok Station Time", offset => ["+06:00"] },
  VUT   => { comment => "Vanuatu Time", offset => ["+11:00"] },
  WAKT  => { comment => "Wake Island Time", offset => ["+12:00"] },
  WAST  => { comment => "West Africa Summer Time", offset => ["+02:00"] },
  WAT   => { comment => "West Africa Time", offset => ["+01:00"] },
  WEST  => { comment => "Western European Summer Time", offset => ["+01:00"] },
  WET   => { comment => "Western European Time", offset => ["UTC"] },
  WGST  => { comment => "West Greenland Summer Time[14]", offset => ["-02:00"] },
  WGT   => { comment => "West Greenland Time[15]", offset => ["-03:00"] },
  WIB   => { comment => "Western Indonesian Time", offset => ["+07:00"] },
  WIT   => { comment => "Eastern Indonesian Time", offset => ["+09:00"] },
  WITA  => { comment => "Central Indonesia Time", offset => ["+08:00"] },
  WST   => { comment => "Western Standard Time", offset => ["+08:00"] },
  YAKT  => { comment => "Yakutsk Time", offset => ["+09:00"] },
  YEKT  => { comment => "Yekaterinburg Time", offset => ["+05:00"] },
};

sub import
{
    my $class = shift( @_ );
    foreach my $alias ( keys( %$ALIAS_CATALOG ) )
    {
        next if( DateTime::TimeZone::Alias->is_defined( $alias ) );
        try
        {
            DateTime::TimeZone::Alias->add( $alias => $ALIAS_CATALOG->{ $alias }->{offset}->[0] );
        }
        catch( $e )
        {
            warnings::warn( "Warning only: error trying to add time zone alias '$alias' (" . $ALIAS_CATALOG->{ $alias }->{comment} . ") with time zone offset '" . $ALIAS_CATALOG->{ $alias }->{offset}->[0] . "': $e\n" ) if( warnings::enabled() );
        }
    }
}

sub aliases { return( [sort(keys( %$ALIAS_CATALOG ) )] ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DateTime::TimeZone::Catalog::Extend - Extend DateTime::TimeZone catalog

=head1 SYNOPSIS

    use DateTime::TimeZone;
    # After DateTime::TimeZone is loaded, let's extend it
    use DateTime::TimeZone::Catalog::Extend;
    # That's it; nothing more

    # This would normally trigger an exception, but not anymore
    my $tz = DateTime::TimeZone->new( name => 'JST' );

    # Get the list of all aliases
    my $aliases = DateTime::TimeZone::Catalog::Extend->aliases;

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This is a very simple module based on the L<list of time zone aliases|https://en.wikipedia.org/wiki/List_of_time_zone_abbreviations> that are sometimes found in dates.

Upon using this module, it will add to the L<DateTime::TimeZone::Catalog> those aliases with their corresponding time zone offset. When there is more than one time zone offset in the list, only the first one is set.

Here is the list of those time zone aliases and their offset:

=over 4

=item 1. C<ACDT> +10:30 (Australian Central Daylight Saving Time)

=item 2. C<ACST> +09:30 (Australian Central Standard Time)

=item 3. C<ACT> +08:00 (ASEAN Common Time (proposed))

=item 4. C<ACWST> +08:45 (Australian Central Western Standard Time (unofficial))

=item 5. C<ADT> -03:00 (Atlantic Daylight Time)

=item 6. C<AEDT> +11:00 (Australian Eastern Daylight Saving Time)

=item 7. C<AEST> +10:00 (Australian Eastern Standard Time)

=item 8. C<AET> +10:00 (Australian Eastern Time)

=item 9. C<AFT> +04:30 (Afghanistan Time)

=item 10. C<AKDT> -08:00 (Alaska Daylight Time)

=item 11. C<AKST> -09:00 (Alaska Standard Time)

=item 12. C<ALMT> +06:00 (Alma-Ata Time[1])

=item 13. C<AMST> -03:00 (Amazon Summer Time (Brazil)[2])

=item 14. C<AMT> +04:00 (Armenia Time)

=item 15. C<ANAT> +12:00 (Anadyr Time[4])

=item 16. C<AQTT> +05:00 (Aqtobe Time[5])

=item 17. C<ART> -03:00 (Argentina Time)

=item 18. C<AST> -04:00 (Atlantic Standard Time)

=item 19. C<AWST> +08:00 (Australian Western Standard Time)

=item 20. C<AZOST> UTC (Azores Summer Time)

=item 21. C<AZOT> -01:00 (Azores Standard Time)

=item 22. C<AZT> +04:00 (Azerbaijan Time)

=item 23. C<BIOT> +06:00 (British Indian Ocean Time)

=item 24. C<BIT> -12:00 (Baker Island Time)

=item 25. C<BNT> +08:00 (Brunei Time)

=item 26. C<BOT> -04:00 (Bolivia Time)

=item 27. C<BRST> -02:00 (Brasília Summer Time)

=item 28. C<BRT> -03:00 (Brasília Time)

=item 29. C<BST> +01:00 (British Summer Time (British Standard Time from Feb 1968 to Oct 1971))

=item 30. C<BTT> +06:00 (Bhutan Time)

=item 31. C<CAT> +02:00 (Central Africa Time)

=item 32. C<CCT> +06:30 (Cocos Islands Time)

=item 33. C<CDT> -04:00 (Cuba Daylight Time[7])

=item 34. C<CEST> +02:00 (Central European Summer Time)

=item 35. C<CET> +01:00 (Central European Time)

=item 36. C<CHADT> +13:45 (Chatham Daylight Time)

=item 37. C<CHAST> +12:45 (Chatham Standard Time)

=item 38. C<CHOST> +09:00 (Choibalsan Summer Time)

=item 39. C<CHOT> +08:00 (Choibalsan Standard Time)

=item 40. C<CHST> +10:00 (Chamorro Standard Time)

=item 41. C<CHUT> +10:00 (Chuuk Time)

=item 42. C<CIST> -08:00 (Clipperton Island Standard Time)

=item 43. C<CKT> -10:00 (Cook Island Time)

=item 44. C<CLST> -03:00 (Chile Summer Time)

=item 45. C<CLT> -04:00 (Chile Standard Time)

=item 46. C<COST> -04:00 (Colombia Summer Time)

=item 47. C<COT> -05:00 (Colombia Time)

=item 48. C<CST> -05:00 (Cuba Standard Time)

=item 49. C<CT> -06:00 (Central Time)

=item 50. C<CVT> -01:00 (Cape Verde Time)

=item 51. C<CWST> +08:45 (Central Western Standard Time (Australia) unofficial)

=item 52. C<CXT> +07:00 (Christmas Island Time)

=item 53. C<DAVT> +07:00 (Davis Time)

=item 54. C<DDUT> +10:00 (Dumont d'Urville Time)

=item 55. C<DFT> +01:00 (AIX-specific equivalent of Central European Time[NB 1])

=item 56. C<EASST> -05:00 (Easter Island Summer Time)

=item 57. C<EAST> -06:00 (Easter Island Standard Time)

=item 58. C<EAT> +03:00 (East Africa Time)

=item 59. C<ECT> -05:00 (Ecuador Time)

=item 60. C<EDT> -04:00 (Eastern Daylight Time (North America))

=item 61. C<EEST> +03:00 (Eastern European Summer Time)

=item 62. C<EET> +02:00 (Eastern European Time)

=item 63. C<EGST> UTC (Eastern Greenland Summer Time)

=item 64. C<EGT> -01:00 (Eastern Greenland Time)

=item 65. C<EST> -05:00 (Eastern Standard Time (North America))

=item 66. C<ET> -04:00 (Eastern Time (North America) UTC-05 /)

=item 67. C<FET> +03:00 (Further-eastern European Time)

=item 68. C<FJT> +12:00 (Fiji Time)

=item 69. C<FKST> -03:00 (Falkland Islands Summer Time)

=item 70. C<FKT> -04:00 (Falkland Islands Time)

=item 71. C<FNT> -02:00 (Fernando de Noronha Time)

=item 72. C<GALT> -06:00 (Galápagos Time)

=item 73. C<GAMT> -09:00 (Gambier Islands Time)

=item 74. C<GET> +04:00 (Georgia Standard Time)

=item 75. C<GFT> -03:00 (French Guiana Time)

=item 76. C<GILT> +12:00 (Gilbert Island Time)

=item 77. C<GIT> -09:00 (Gambier Island Time)

=item 78. C<GMT> UTC (Greenwich Mean Time)

=item 79. C<GST> +04:00 (Gulf Standard Time)

=item 80. C<GYT> -04:00 (Guyana Time)

=item 81. C<HAEC> +02:00 (Heure Avancée d'Europe Centrale French-language name for CEST)

=item 82. C<HDT> -09:00 (Hawaii–Aleutian Daylight Time)

=item 83. C<HKT> +08:00 (Hong Kong Time)

=item 84. C<HMT> +05:00 (Heard and McDonald Islands Time)

=item 85. C<HOVST> +08:00 (Hovd Summer Time (not used from 2017-present))

=item 86. C<HOVT> +07:00 (Hovd Time)

=item 87. C<HST> -10:00 (Hawaii–Aleutian Standard Time)

=item 88. C<ICT> +07:00 (Indochina Time)

=item 89. C<IDLW> -12:00 (International Day Line West time zone)

=item 90. C<IDT> +03:00 (Israel Daylight Time)

=item 91. C<IOT> +03:00 (Indian Ocean Time)

=item 92. C<IRDT> +04:30 (Iran Daylight Time)

=item 93. C<IRKT> +08:00 (Irkutsk Time)

=item 94. C<IRST> +03:30 (Iran Standard Time)

=item 95. C<IST> +02:00 (Israel Standard Time)

=item 96. C<JST> +09:00 (Japan Standard Time)

=item 97. C<KALT> +02:00 (Kaliningrad Time)

=item 98. C<KGT> +06:00 (Kyrgyzstan Time)

=item 99. C<KOST> +11:00 (Kosrae Time)

=item 100. C<KRAT> +07:00 (Krasnoyarsk Time)

=item 101. C<KST> +09:00 (Korea Standard Time)

=item 102. C<LHST> +11:00 (Lord Howe Summer Time)

=item 103. C<LINT> +14:00 (Line Islands Time)

=item 104. C<MAGT> +12:00 (Magadan Time)

=item 105. C<MART> -09:30 (Marquesas Islands Time)

=item 106. C<MAWT> +05:00 (Mawson Station Time)

=item 107. C<MDT> -06:00 (Mountain Daylight Time (North America))

=item 108. C<MEST> +02:00 (Middle European Summer Time (same zone as CEST))

=item 109. C<MET> +01:00 (Middle European Time (same zone as CET))

=item 110. C<MHT> +12:00 (Marshall Islands Time)

=item 111. C<MIST> +11:00 (Macquarie Island Station Time)

=item 112. C<MIT> -09:30 (Marquesas Islands Time)

=item 113. C<MMT> +06:30 (Myanmar Standard Time)

=item 114. C<MSK> +03:00 (Moscow Time)

=item 115. C<MST> -07:00 (Mountain Standard Time (North America))

=item 116. C<MUT> +04:00 (Mauritius Time)

=item 117. C<MVT> +05:00 (Maldives Time)

=item 118. C<MYT> +08:00 (Malaysia Time)

=item 119. C<NCT> +11:00 (New Caledonia Time)

=item 120. C<NDT> -02:30 (Newfoundland Daylight Time)

=item 121. C<NFT> +11:00 (Norfolk Island Time)

=item 122. C<NOVT> +07:00 (Novosibirsk Time [9])

=item 123. C<NPT> +05:45 (Nepal Time)

=item 124. C<NST> -03:30 (Newfoundland Standard Time)

=item 125. C<NT> -03:30 (Newfoundland Time)

=item 126. C<NUT> -11:00 (Niue Time)

=item 127. C<NZDT> +13:00 (New Zealand Daylight Time)

=item 128. C<NZST> +12:00 (New Zealand Standard Time)

=item 129. C<OMST> +06:00 (Omsk Time)

=item 130. C<ORAT> +05:00 (Oral Time)

=item 131. C<PDT> -07:00 (Pacific Daylight Time (North America))

=item 132. C<PET> -05:00 (Peru Time)

=item 133. C<PETT> +12:00 (Kamchatka Time)

=item 134. C<PGT> +10:00 (Papua New Guinea Time)

=item 135. C<PHOT> +13:00 (Phoenix Island Time)

=item 136. C<PHST> +08:00 (Philippine Standard Time)

=item 137. C<PHT> +08:00 (Philippine Time)

=item 138. C<PKT> +05:00 (Pakistan Standard Time)

=item 139. C<PMDT> -02:00 (Saint Pierre and Miquelon Daylight Time)

=item 140. C<PMST> -03:00 (Saint Pierre and Miquelon Standard Time)

=item 141. C<PONT> +11:00 (Pohnpei Standard Time)

=item 142. C<PST> -08:00 (Pacific Standard Time (North America))

=item 143. C<PWT> +09:00 (Palau Time[10])

=item 144. C<PYST> -03:00 (Paraguay Summer Time[11])

=item 145. C<PYT> -04:00 (Paraguay Time[12])

=item 146. C<RET> +04:00 (Réunion Time)

=item 147. C<ROTT> -03:00 (Rothera Research Station Time)

=item 148. C<SAKT> +11:00 (Sakhalin Island Time)

=item 149. C<SAMT> +04:00 (Samara Time)

=item 150. C<SAST> +02:00 (South African Standard Time)

=item 151. C<SBT> +11:00 (Solomon Islands Time)

=item 152. C<SCT> +04:00 (Seychelles Time)

=item 153. C<SDT> -10:00 (Samoa Daylight Time)

=item 154. C<SGT> +08:00 (Singapore Time)

=item 155. C<SLST> +05:30 (Sri Lanka Standard Time)

=item 156. C<SRET> +11:00 (Srednekolymsk Time)

=item 157. C<SRT> -03:00 (Suriname Time)

=item 158. C<SST> +08:00 (Singapore Standard Time)

=item 159. C<SYOT> +03:00 (Showa Station Time)

=item 160. C<TAHT> -10:00 (Tahiti Time)

=item 161. C<TFT> +05:00 (French Southern and Antarctic Time[13])

=item 162. C<THA> +07:00 (Thailand Standard Time)

=item 163. C<TJT> +05:00 (Tajikistan Time)

=item 164. C<TKT> +13:00 (Tokelau Time)

=item 165. C<TLT> +09:00 (Timor Leste Time)

=item 166. C<TMT> +05:00 (Turkmenistan Time)

=item 167. C<TOT> +13:00 (Tonga Time)

=item 168. C<TRT> +03:00 (Turkey Time)

=item 169. C<TVT> +12:00 (Tuvalu Time)

=item 170. C<ULAST> +09:00 (Ulaanbaatar Summer Time)

=item 171. C<ULAT> +08:00 (Ulaanbaatar Standard Time)

=item 172. C<UTC> UTC (Coordinated Universal Time)

=item 173. C<UYST> -02:00 (Uruguay Summer Time)

=item 174. C<UYT> -03:00 (Uruguay Standard Time)

=item 175. C<UZT> +05:00 (Uzbekistan Time)

=item 176. C<VET> -04:00 (Venezuelan Standard Time)

=item 177. C<VLAT> +10:00 (Vladivostok Time)

=item 178. C<VOLT> +03:00 (Volgograd Time)

=item 179. C<VOST> +06:00 (Vostok Station Time)

=item 180. C<VUT> +11:00 (Vanuatu Time)

=item 181. C<WAKT> +12:00 (Wake Island Time)

=item 182. C<WAST> +02:00 (West Africa Summer Time)

=item 183. C<WAT> +01:00 (West Africa Time)

=item 184. C<WEST> +01:00 (Western European Summer Time)

=item 185. C<WET> UTC (Western European Time)

=item 186. C<WGST> -02:00 (West Greenland Summer Time[14])

=item 187. C<WGT> -03:00 (West Greenland Time[15])

=item 188. C<WIB> +07:00 (Western Indonesian Time)

=item 189. C<WIT> +09:00 (Eastern Indonesian Time)

=item 190. C<WITA> +08:00 (Central Indonesia Time)

=item 191. C<WST> +08:00 (Western Standard Time)

=item 192. C<YAKT> +09:00 (Yakutsk Time)

=item 193. C<YEKT> +05:00 (Yekaterinburg Time)

=back

=head1 METHODS

=head2 aliases

Returns an array reference of the time zone aliases.

    my $aliases = DateTime::TimeZone::Catalog::Extend->aliases;

You can also achieve the same result by accessing directly the package variable C<$ALIAS_CATALOG>

    my $aliases = [sort( keys( %$DateTime::TimeZone::Catalog::Extend::ALIAS_CATALOG ) )];

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DateTime::TimeZone::Catalog>, L<DateTime::TimeZone::Alias>, L<DateTime::TimeZone>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
