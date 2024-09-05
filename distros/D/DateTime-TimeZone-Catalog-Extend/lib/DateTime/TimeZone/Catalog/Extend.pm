##----------------------------------------------------------------------------
## Extend DateTime::TimeZone catalog - ~/lib/DateTime/TimeZone/Catalog/Extend.pm
## Version v0.3.3
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/11/29
## Modified 2024/09/05
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
    use vars qw( $VERSION @ISA $ALIAS_CATALOG $ZONE_MAP );
    our @ISA = qw( Exporter );
    use DateTime::TimeZone::Alias;
    our $VERSION = 'v0.3.3';
};

use strict;
use warnings;
use utf8;

# <https://en.wikipedia.org/wiki/List_of_time_zone_abbreviations>
$ALIAS_CATALOG =
{
  "A"      => { comment => "Alpha Military Time Zone", offset => ["+0100"] },
  "ACDT"   => {
                comment => "Australian Central Daylight Saving Time",
                offset  => ["+10:30"],
              },
  "ACST"   => { comment => "Australian Central Standard Time", offset => ["+09:30"] },
  "ACT"    => { comment => "ASEAN Common Time", offset => ["+08:00"] },
  "ACWST"  => {
                comment => "Australian Central Western Standard Time",
                offset  => ["+08:45"],
              },
  "ADT"    => { comment => "Atlantic Daylight Time", offset => ["-03:00"] },
  "AEDT"   => {
                comment => "Australian Eastern Daylight Saving Time",
                offset  => ["+11:00"],
              },
  "AES"    => { comment => "Australian Eastern Standard Time", offset => ["+10:00"] },
  "AEST"   => { comment => "Australian Eastern Standard Time", offset => ["+10:00"] },
  "AET"    => {
                comment => "Australian Eastern Time",
                offset  => ["+10:00", "+11:00"],
              },
  "AFT"    => { comment => "Afghanistan Time", offset => ["+04:30"] },
  "AHDT"   => { comment => "Alaska-Hawaii Daylight Time", offset => ["-0900"] },
  "AHST"   => { comment => "Alaska-Hawaii Standard Time", offset => [-1000] },
  "AKDT"   => { comment => "Alaska Daylight Time", offset => ["-08:00"] },
  "AKST"   => { comment => "Alaska Standard Time", offset => ["-09:00"] },
  "ALMT"   => { comment => "Alma-Ata Time", offset => ["+06:00"] },
  "AMST"   => { comment => "Amazon Summer Time (Brazil)", offset => ["-03:00"] },
  "AMT"    => { comment => "Armenia Time", offset => ["+04:00"] },
  "ANAST"  => { comment => "Anadyr Summer Time", offset => ["+1300"] },
  "ANAT"   => { comment => "Anadyr Time", offset => ["+12:00"] },
  "AQTT"   => { comment => "Aqtobe Time", offset => ["+05:00"] },
  "ART"    => { comment => "Argentina Time", offset => ["-03:00"] },
  "AST"    => { comment => "Atlantic Standard Time", offset => ["-04:00"] },
  "AT"     => { comment => "Azores Time", offset => ["-0100"] },
  "AWST"   => { comment => "Australian Western Standard Time", offset => ["+08:00"] },
  "AZOST"  => { comment => "Azores Summer Time", offset => ["UTC"] },
  "AZOT"   => { comment => "Azores Standard Time", offset => ["-01:00"] },
  "AZST"   => { comment => "Azerbaijan Summer Time", offset => ["+0500"] },
  "AZT"    => { comment => "Azerbaijan Time", offset => ["+04:00"] },
  "B"      => { comment => "Bravo Military Time Zone", offset => ["+0200"] },
  "BADT"   => { comment => "Baghdad Daylight Time", offset => ["+0400"] },
  "BAT"    => { comment => "Baghdad Time", offset => ["+0600"] },
  "BDST"   => { comment => "British Double Summer Time", offset => ["+0200"] },
  "BDT"    => { comment => "Bangladesh Time", offset => ["+0600"] },
  "BET"    => { comment => "Bering Standard Time", offset => [-1100] },
  "BIOT"   => { comment => "British Indian Ocean Time", offset => ["+06:00"] },
  "BIT"    => { comment => "Baker Island Time", offset => ["-12:00"] },
  "BNT"    => { comment => "Brunei Time", offset => ["+08:00"] },
  "BORT"   => { comment => "Borneo Time (Indonesia)", offset => ["+0800"] },
  "BOT"    => { comment => "Bolivia Time", offset => ["-04:00"] },
  "BRA"    => { comment => "Brazil Time", offset => ["-0300"] },
  "BRST"   => { comment => "Brasília Summer Time", offset => ["-02:00"] },
  "BRT"    => { comment => "Brasília Time", offset => ["-03:00"] },
  "BST"    => {
                comment => "British Summer Time (British Standard Time from Feb 1968 to Oct 1971)",
                offset  => ["+01:00"],
              },
  "BTT"    => { comment => "Bhutan Time", offset => ["+06:00"] },
  "C"      => { comment => "Charlie Military Time Zone", offset => ["+0300"] },
  "CAST"   => { comment => "Casey Time Zone", offset => ["+0930"] },
  "CAT"    => { comment => "Central Africa Time", offset => ["+02:00"] },
  "CCT"    => { comment => "Cocos Islands Time", offset => ["+06:30"] },
  "CDT"    => { comment => "Cuba Daylight Time", offset => ["-04:00"] },
  "CEST"   => { comment => "Central European Summer Time", offset => ["+02:00"] },
  "CET"    => { comment => "Central European Time", offset => ["+01:00"] },
  "CETDST" => { comment => "Central Europe Summer Time", offset => ["+0200"] },
  "CHADT"  => { comment => "Chatham Daylight Time", offset => ["+13:45"] },
  "CHAST"  => { comment => "Chatham Standard Time", offset => ["+12:45"] },
  "CHOST"  => { comment => "Choibalsan Summer Time", offset => ["+09:00"] },
  "CHOT"   => { comment => "Choibalsan Standard Time", offset => ["+08:00"] },
  "CHST"   => { comment => "Chamorro Standard Time", offset => ["+10:00"] },
  "ChST"   => { comment => "Chamorro Standard Time", offset => ["+1000"] },
  "CHUT"   => { comment => "Chuuk Time", offset => ["+10:00"] },
  "CIST"   => { comment => "Clipperton Island Standard Time", offset => ["-08:00"] },
  "CKT"    => { comment => "Cook Island Time", offset => ["-10:00"] },
  "CLST"   => { comment => "Chile Summer Time", offset => ["-03:00"] },
  "CLT"    => { comment => "Chile Standard Time", offset => ["-04:00"] },
  "COST"   => { comment => "Colombia Summer Time", offset => ["-04:00"] },
  "COT"    => { comment => "Colombia Time", offset => ["-05:00"] },
  "CST"    => { comment => "Cuba Standard Time", offset => ["-05:00"] },
  "CSuT"   => { comment => "Australian Central Daylight", offset => ["+1030"] },
  "CT"     => { comment => "Central Time", offset => ["-06:00", "-05:00"] },
  "CUT"    => { comment => "Coordinated Universal Time", offset => ["+0000"] },
  "CVT"    => { comment => "Cape Verde Time", offset => ["-01:00"] },
  "CWST"   => {
                comment => "Central Western Standard Time (Australia)",
                offset  => ["+08:45"],
              },
  "CXT"    => { comment => "Christmas Island Time", offset => ["+07:00"] },
  "D"      => { comment => "Delta Military Time Zone", offset => ["+0400"] },
  "DAVT"   => { comment => "Davis Time", offset => ["+07:00"] },
  "DDUT"   => { comment => "Dumont d'Urville Time", offset => ["+10:00"] },
  "DFT"    => {
                comment => "AIX-specific equivalent of Central European Time",
                offset  => ["+01:00"],
              },
  "DNT"    => { comment => "Dansk Normal", offset => ["+0100"] },
  "DST"    => { comment => "Dansk Summer", offset => ["+0200"] },
  "E"      => { comment => "Echo Military Time Zone", offset => ["+0500"] },
  "EASST"  => { comment => "Easter Island Summer Time", offset => ["-05:00"] },
  "EAST"   => { comment => "Easter Island Standard Time", offset => ["-06:00"] },
  "EAT"    => { comment => "East Africa Time", offset => ["+03:00"] },
  "ECT"    => { comment => "Ecuador Time", offset => ["-05:00"] },
  "EDT"    => {
                comment => "Eastern Daylight Time (North America)",
                offset  => ["-04:00"],
              },
  "EEST"   => { comment => "Eastern European Summer Time", offset => ["+03:00"] },
  "EET"    => { comment => "Eastern European Time", offset => ["+02:00"] },
  "EETDST" => { comment => "European Eastern Summer", offset => ["+0300"] },
  "EGST"   => { comment => "Eastern Greenland Summer Time", offset => ["UTC"] },
  "EGT"    => { comment => "Eastern Greenland Time", offset => ["-01:00"] },
  "EMT"    => { comment => "Norway Time", offset => ["+0100"] },
  "EST"    => {
                comment => "Eastern Standard Time (North America)",
                offset  => ["-05:00"],
              },
  "ESuT"   => { comment => "Australian Eastern Daylight", offset => ["+1100"] },
  "ET"     => { comment => "Eastern Time (North America)", offset => ["-04:00"] },
  "F"      => { comment => "Foxtrot Military Time Zone", offset => ["+0600"] },
  "FET"    => { comment => "Further-eastern European Time", offset => ["+03:00"] },
  "FJST"   => { comment => "Fiji Summer Time", offset => ["+1300"] },
  "FJT"    => { comment => "Fiji Time", offset => ["+12:00"] },
  "FKST"   => { comment => "Falkland Islands Summer Time", offset => ["-03:00"] },
  "FKT"    => { comment => "Falkland Islands Time", offset => ["-04:00"] },
  "FNT"    => { comment => "Fernando de Noronha Time", offset => ["-02:00"] },
  "FWT"    => { comment => "French Winter Time", offset => ["+0100"] },
  "G"      => { comment => "Golf Military Time Zone", offset => ["+0700"] },
  "GALT"   => { comment => "Galapagos Time", offset => ["-06:00"] },
  "GAMT"   => { comment => "Gambier Islands Time", offset => ["-09:00"] },
  "GEST"   => { comment => "Georgia Summer Time", offset => ["+0500"] },
  "GET"    => { comment => "Georgia Standard Time", offset => ["+04:00"] },
  "GFT"    => { comment => "French Guiana Time", offset => ["-03:00"] },
  "GILT"   => { comment => "Gilbert Island Time", offset => ["+12:00"] },
  "GIT"    => { comment => "Gambier Island Time", offset => ["-09:00"] },
  "GMT"    => { comment => "Greenwich Mean Time", offset => ["UTC"] },
  "GST"    => { comment => "Gulf Standard Time", offset => ["+04:00"] },
  "GT"     => { comment => "Greenwich Time", offset => ["+0000"] },
  "GYT"    => { comment => "Guyana Time", offset => ["-04:00"] },
  "GZ"     => { comment => "Greenwichzeit", offset => ["+0000"] },
  "H"      => { comment => "Hotel Military Time Zone", offset => ["+0800"] },
  "HAA"    => { comment => "Heure Avanc\xE9e de l'Atlantique", offset => ["-0300"] },
  "HAC"    => { comment => "Heure Avancee du Centre", offset => ["-0500"] },
  "HAE"    => { comment => "Heure Avancee de l'Est", offset => ["-0400"] },
  "HAEC"   => {
                comment => "Heure Avanc\xE9e d'Europe Centrale",
                offset  => ["+02:00"],
              },
  "HAP"    => { comment => "Heure Avancee du Pacifique", offset => ["-0700"] },
  "HAR"    => { comment => "Heure Avancee des Rocheuses", offset => ["-0600"] },
  "HAT"    => { comment => "Heure Avancee de Terre-Neuve", offset => ["-0230"] },
  "HAY"    => { comment => "Heure Avancee du Yukon", offset => ["-0800"] },
  "HDT"    => {
                comment => "Hawaii\x{2013}Aleutian Daylight Time",
                offset  => ["-09:00"],
              },
  "HFE"    => { comment => "Heure Fancais d'Ete", offset => ["+0200"] },
  "HFH"    => { comment => "Heure Fancais d'Hiver", offset => ["+0100"] },
  "HG"     => { comment => "Heure de Greenwich", offset => ["+0000"] },
  "HKT"    => { comment => "Hong Kong Time", offset => ["+08:00"] },
  "HL"     => { comment => "Heure locale", offset => ["local"] },
  "HMT"    => { comment => "Heard and McDonald Islands Time", offset => ["+05:00"] },
  "HNA"    => { comment => "Heure Normale de l'Atlantique", offset => ["-0400"] },
  "HNC"    => { comment => "Heure Normale du Centre", offset => ["-0600"] },
  "HNE"    => { comment => "Heure Normale de l'Est", offset => ["-0500"] },
  "HNP"    => { comment => "Heure Normale du Pacifique", offset => ["-0800"] },
  "HNR"    => { comment => "Heure Normale des Rocheuses", offset => ["-0700"] },
  "HNT"    => { comment => "Heure Normale de Terre-Neuve", offset => ["-0330"] },
  "HNY"    => { comment => "Heure Normale du Yukon", offset => ["-0900"] },
  "HOE"    => { comment => "Spain Time", offset => ["+0100"] },
  "HOVST"  => {
                comment => "Hovd Summer Time (not used from 2017-present)",
                offset  => ["+08:00"],
              },
  "HOVT"   => { comment => "Hovd Time", offset => ["+07:00"] },
  "HST"    => {
                comment => "Hawaii\x{2013}Aleutian Standard Time",
                offset  => ["-10:00"],
              },
  "I"      => { comment => "India Military Time Zone", offset => ["+0900"] },
  "ICT"    => { comment => "Indochina Time", offset => ["+07:00"] },
  "IDLE"   => { comment => "Internation Date Line East", offset => ["+1200"] },
  "IDLW"   => {
                comment => "International Day Line West time zone",
                offset  => ["-12:00"],
              },
  "IDT"    => { comment => "Israel Daylight Time", offset => ["+03:00"] },
  "IOT"    => { comment => "Indian Ocean Time", offset => ["+03:00"] },
  "IRDT"   => { comment => "Iran Daylight Time", offset => ["+04:30"] },
  "IRKST"  => { comment => "Irkutsk Summer Time", offset => ["+0900"] },
  "IRKT"   => { comment => "Irkutsk Time", offset => ["+08:00"] },
  "IRST"   => { comment => "Iran Standard Time", offset => ["+03:30"] },
  "IRT"    => { comment => "Iran Time", offset => ["+0330"] },
  "IST"    => { comment => "Israel Standard Time", offset => ["+02:00"] },
  "IT"     => { comment => "Iran Time", offset => ["+0330"] },
  "ITA"    => { comment => "Italy Time", offset => ["+0100"] },
  "JAVT"   => { comment => "Java Time", offset => ["+0700"] },
  "JAYT"   => { comment => "Jayapura Time (Indonesia)", offset => ["+0900"] },
  "JST"    => { comment => "Japan Standard Time", offset => ["+09:00"] },
  "JT"     => { comment => "Java Time", offset => ["+0700"] },
  "K"      => { comment => "Kilo Military Time Zone", offset => ["+1000"] },
  "KALT"   => { comment => "Kaliningrad Time", offset => ["+02:00"] },
  "KDT"    => { comment => "Korean Daylight Time", offset => ["+1000"] },
  "KGST"   => { comment => "Kyrgyzstan Summer Time", offset => ["+0600"] },
  "KGT"    => { comment => "Kyrgyzstan Time", offset => ["+06:00"] },
  "KOST"   => { comment => "Kosrae Time", offset => ["+11:00"] },
  "KRAST"  => { comment => "Krasnoyarsk Summer Time", offset => ["+0800"] },
  "KRAT"   => { comment => "Krasnoyarsk Time", offset => ["+07:00"] },
  "KST"    => { comment => "Korea Standard Time", offset => ["+09:00"] },
  "L"      => { comment => "Lima Military Time Zone", offset => ["+1100"] },
  "LHDT"   => { comment => "Lord Howe Daylight Time", offset => ["+1100"] },
  "LHST"   => { comment => "Lord Howe Summer Time", offset => ["+11:00"] },
  "LIGT"   => { comment => "Melbourne, Australia", offset => ["+1000"] },
  "LINT"   => { comment => "Line Islands Time", offset => ["+14:00"] },
  "LKT"    => { comment => "Lanka Time", offset => ["+0600"] },
  "LST"    => { comment => "Local Sidereal Time", offset => ["local"] },
  "LT"     => { comment => "Local Time", offset => ["local"] },
  "M"      => { comment => "Mike Military Time Zone", offset => ["+1200"] },
  "MAGST"  => { comment => "Magadan Summer Time", offset => ["+1200"] },
  "MAGT"   => { comment => "Magadan Time", offset => ["+12:00"] },
  "MAL"    => { comment => "Malaysia Time", offset => ["+0800"] },
  "MART"   => { comment => "Marquesas Islands Time", offset => ["-09:30"] },
  "MAT"    => { comment => "Turkish Standard Time", offset => ["+0300"] },
  "MAWT"   => { comment => "Mawson Station Time", offset => ["+05:00"] },
  "MDT"    => {
                comment => "Mountain Daylight Time (North America)",
                offset  => ["-06:00"],
              },
  "MED"    => { comment => "Middle European Daylight", offset => ["+0200"] },
  "MEDST"  => { comment => "Middle European Summer", offset => ["+0200"] },
  "MEST"   => { comment => "Middle European Summer Time", offset => ["+02:00"] },
  "MESZ"   => { comment => "Mitteieuropaische Sommerzeit", offset => ["+0200"] },
  "MET"    => { comment => "Middle European Time", offset => ["+01:00"] },
  "MEWT"   => { comment => "Middle European Winter Time", offset => ["+0100"] },
  "MEX"    => { comment => "Mexico Time", offset => ["-0600"] },
  "MEZ"    => { comment => "Mitteieuropaische Zeit", offset => ["+0100"] },
  "MHT"    => { comment => "Marshall Islands Time", offset => ["+12:00"] },
  "MIST"   => { comment => "Macquarie Island Station Time", offset => ["+11:00"] },
  "MIT"    => { comment => "Marquesas Islands Time", offset => ["-09:30"] },
  "MMT"    => { comment => "Myanmar Standard Time", offset => ["+06:30"] },
  "MPT"    => { comment => "North Mariana Islands Time", offset => ["+1000"] },
  "MSD"    => { comment => "Moscow Summer Time", offset => ["+0400"] },
  "MSK"    => { comment => "Moscow Time", offset => ["+03:00"] },
  "MSKS"   => { comment => "Moscow Summer Time", offset => ["+0400"] },
  "MST"    => { comment => "Mountain Standard Time", offset => ["-07:00"] },
  "MT"     => { comment => "Moluccas", offset => ["+0830"] },
  "MUT"    => { comment => "Mauritius Time", offset => ["+04:00"] },
  "MVT"    => { comment => "Maldives Time", offset => ["+05:00"] },
  "MYT"    => { comment => "Malaysia Time", offset => ["+08:00"] },
  "N"      => { comment => "November Military Time Zone", offset => ["-0100"] },
  "NCT"    => { comment => "New Caledonia Time", offset => ["+11:00"] },
  "NDT"    => { comment => "Newfoundland Daylight Time", offset => ["-02:30"] },
  "NFT"    => { comment => "Norfolk Island Time", offset => ["+11:00"] },
  "NOR"    => { comment => "Norway Time", offset => ["+0100"] },
  "NOVST"  => { comment => "Novosibirsk Summer Time (Russia)", offset => ["+0700"] },
  "NOVT"   => { comment => "Novosibirsk Time", offset => ["+07:00"] },
  "NPT"    => { comment => "Nepal Time", offset => ["+05:45"] },
  "NRT"    => { comment => "Nauru Time", offset => ["+1200"] },
  "NST"    => { comment => "Newfoundland Standard Time", offset => ["-03:30"] },
  "NSUT"   => { comment => "North Sumatra Time", offset => ["+0630"] },
  "NT"     => { comment => "Newfoundland Time", offset => ["-03:30"] },
  "NUT"    => { comment => "Niue Time", offset => ["-11:00"] },
  "NZDT"   => { comment => "New Zealand Daylight Time", offset => ["+13:00"] },
  "NZST"   => { comment => "New Zealand Standard Time", offset => ["+12:00"] },
  "NZT"    => { comment => "New Zealand Standard Time", offset => ["+1200"] },
  "O"      => { comment => "Oscar Military Time Zone", offset => ["-0200"] },
  "OESZ"   => { comment => "Osteuropaeische Sommerzeit", offset => ["+0300"] },
  "OEZ"    => { comment => "Osteuropaische Zeit", offset => ["+0200"] },
  "OMSST"  => { comment => "Omsk Summer Time", offset => ["+0700"] },
  "OMST"   => { comment => "Omsk Time", offset => ["+06:00"] },
  "ORAT"   => { comment => "Oral Time", offset => ["+05:00"] },
  "OZ"     => { comment => "Ortszeit", offset => ["local"] },
  "P"      => { comment => "Papa Military Time Zone", offset => ["-0300"] },
  "PDT"    => {
                comment => "Pacific Daylight Time (North America)",
                offset  => ["-07:00"],
              },
  "PET"    => { comment => "Peru Time", offset => ["-05:00"] },
  "PETST"  => { comment => "Kamchatka Summer Time", offset => ["+1300"] },
  "PETT"   => { comment => "Kamchatka Time", offset => ["+12:00"] },
  "PGT"    => { comment => "Papua New Guinea Time", offset => ["+10:00"] },
  "PHOT"   => { comment => "Phoenix Island Time", offset => ["+13:00"] },
  "PHST"   => { comment => "Philippine Standard Time", offset => ["+08:00"] },
  "PHT"    => { comment => "Philippine Time", offset => ["+08:00"] },
  "PKT"    => { comment => "Pakistan Standard Time", offset => ["+05:00"] },
  "PMDT"   => {
                comment => "Saint Pierre and Miquelon Daylight Time",
                offset  => ["-02:00"],
              },
  "PMST"   => {
                comment => "Saint Pierre and Miquelon Standard Time",
                offset  => ["-03:00"],
              },
  "PMT"    => { comment => "Pierre & Miquelon Standard Time", offset => ["-0300"] },
  "PNT"    => { comment => "Pitcairn Time", offset => ["-0830"] },
  "PONT"   => { comment => "Pohnpei Standard Time", offset => ["+11:00"] },
  "PST"    => {
                comment => "Pacific Standard Time (North America)",
                offset  => ["-08:00"],
              },
  "PWT"    => { comment => "Palau Time", offset => ["+09:00"] },
  "PYST"   => { comment => "Paraguay Summer Time", offset => ["-03:00"] },
  "PYT"    => { comment => "Paraguay Time", offset => ["-04:00"] },
  "Q"      => { comment => "Quebec Military Time Zone", offset => ["-0400"] },
  "R"      => { comment => "Romeo Military Time Zone", offset => ["-0500"] },
  "R1T"    => { comment => "Russia Zone 1", offset => ["+0200"] },
  "R2T"    => { comment => "Russia Zone 2", offset => ["+0300"] },
  "RET"    => { comment => "R\xE9union Time", offset => ["+04:00"] },
  "ROK"    => { comment => "Korean Standard Time", offset => ["+0900"] },
  "ROTT"   => { comment => "Rothera Research Station Time", offset => ["-03:00"] },
  "S"      => { comment => "Sierra Military Time Zone", offset => ["-0600"] },
  "SADT"   => { comment => "Australian South Daylight Time", offset => ["+1030"] },
  "SAKT"   => { comment => "Sakhalin Island Time", offset => ["+11:00"] },
  "SAMT"   => { comment => "Samara Time", offset => ["+04:00"] },
  "SAST"   => { comment => "South African Standard Time", offset => ["+02:00"] },
  "SBT"    => { comment => "Solomon Islands Time", offset => ["+11:00"] },
  "SCT"    => { comment => "Seychelles Time", offset => ["+04:00"] },
  "SDT"    => { comment => "Samoa Daylight Time", offset => ["-10:00"] },
  "SET"    => { comment => "Prague, Vienna Time", offset => ["+0100"] },
  "SGT"    => { comment => "Singapore Time", offset => ["+08:00"] },
  "SLST"   => { comment => "Sri Lanka Standard Time", offset => ["+05:30"] },
  "SRET"   => { comment => "Srednekolymsk Time", offset => ["+11:00"] },
  "SRT"    => { comment => "Suriname Time", offset => ["-03:00"] },
  "SST"    => { comment => "Singapore Standard Time", offset => ["+08:00"] },
  "SWT"    => { comment => "Swedish Winter", offset => ["+0100"] },
  "SYOT"   => { comment => "Showa Station Time", offset => ["+03:00"] },
  "T"      => { comment => "Tango Military Time Zone", offset => ["-0700"] },
  "TAHT"   => { comment => "Tahiti Time", offset => ["-10:00"] },
  "TFT"    => {
                comment => "French Southern and Antarctic Time",
                offset  => ["+05:00"],
              },
  "THA"    => { comment => "Thailand Standard Time", offset => ["+07:00"] },
  "THAT"   => { comment => "Tahiti Time", offset => [-1000] },
  "TJT"    => { comment => "Tajikistan Time", offset => ["+05:00"] },
  "TKT"    => { comment => "Tokelau Time", offset => ["+13:00"] },
  "TLT"    => { comment => "Timor Leste Time", offset => ["+09:00"] },
  "TMT"    => { comment => "Turkmenistan Time", offset => ["+05:00"] },
  "TOT"    => { comment => "Tonga Time", offset => ["+13:00"] },
  "TRT"    => { comment => "Turkey Time", offset => ["+03:00"] },
  "TRUT"   => { comment => "Truk Time", offset => ["+1000"] },
  "TST"    => { comment => "Turkish Standard Time", offset => ["+0300"] },
  "TUC "   => { comment => "Temps Universel Coordonn\xE9", offset => ["+0000"] },
  "TVT"    => { comment => "Tuvalu Time", offset => ["+12:00"] },
  "U"      => { comment => "Uniform Military Time Zone", offset => ["-0800"] },
  "ULAST"  => { comment => "Ulaanbaatar Summer Time", offset => ["+09:00"] },
  "ULAT"   => { comment => "Ulaanbaatar Standard Time", offset => ["+08:00"] },
  "USZ1"   => { comment => "Russia Zone 1", offset => ["+0200"] },
  "USZ1S"  => { comment => "Kaliningrad Summer Time (Russia)", offset => ["+0300"] },
  "USZ3"   => { comment => "Volga Time (Russia)", offset => ["+0400"] },
  "USZ3S"  => { comment => "Volga Summer Time (Russia)", offset => ["+0500"] },
  "USZ4"   => { comment => "Ural Time (Russia)", offset => ["+0500"] },
  "USZ4S"  => { comment => "Ural Summer Time (Russia)", offset => ["+0600"] },
  "USZ5"   => { comment => "West-Siberian Time (Russia)", offset => ["+0600"] },
  "USZ5S"  => { comment => "West-Siberian Summer Time", offset => ["+0700"] },
  "USZ6"   => { comment => "Yenisei Time (Russia)", offset => ["+0700"] },
  "USZ6S"  => { comment => "Yenisei Summer Time (Russia)", offset => ["+0800"] },
  "USZ7"   => { comment => "Irkutsk Time (Russia)", offset => ["+0800"] },
  "USZ7S"  => { comment => "Irkutsk Summer Time", offset => ["+0900"] },
  "USZ8"   => { comment => "Amur Time (Russia)", offset => ["+0900"] },
  "USZ8S"  => { comment => "Amur Summer Time (Russia)", offset => ["+1000"] },
  "USZ9"   => { comment => "Vladivostok Time (Russia)", offset => ["+1000"] },
  "USZ9S"  => { comment => "Vladivostok Summer Time (Russia)", offset => ["+1100"] },
  "UTC"    => { comment => "Coordinated Universal Time", offset => ["UTC"] },
  "UTZ"    => { comment => "Greenland Western Standard Time", offset => ["-0300"] },
  "UYST"   => { comment => "Uruguay Summer Time", offset => ["-02:00"] },
  "UYT"    => { comment => "Uruguay Standard Time", offset => ["-03:00"] },
  "UZ10"   => { comment => "Okhotsk Time (Russia)", offset => ["+1100"] },
  "UZ10S"  => { comment => "Okhotsk Summer Time (Russia)", offset => ["+1200"] },
  "UZ11"   => { comment => "Kamchatka Time (Russia)", offset => ["+1200"] },
  "UZ11S"  => { comment => "Kamchatka Summer Time (Russia)", offset => ["+1300"] },
  "UZ12"   => { comment => "Chukot Time (Russia)", offset => ["+1200"] },
  "UZ12S"  => { comment => "Chukot Summer Time (Russia)", offset => ["+1300"] },
  "UZT"    => { comment => "Uzbekistan Time", offset => ["+05:00"] },
  "V"      => { comment => "Victor Military Time Zone", offset => ["-0900"] },
  "VET"    => { comment => "Venezuelan Standard Time", offset => ["-04:00"] },
  "VLAST"  => { comment => "Vladivostok Summer Time", offset => ["+1100"] },
  "VLAT"   => { comment => "Vladivostok Time", offset => ["+10:00"] },
  "VOLT"   => { comment => "Volgograd Time", offset => ["+03:00"] },
  "VOST"   => { comment => "Vostok Station Time", offset => ["+06:00"] },
  "VTZ"    => { comment => "Greenland Eastern Standard Time", offset => ["-0200"] },
  "VUT"    => { comment => "Vanuatu Time", offset => ["+11:00"] },
  "W"      => { comment => "Whiskey Military Time Zone", offset => [-1000] },
  "WAKT"   => { comment => "Wake Island Time", offset => ["+12:00"] },
  "WAST"   => { comment => "West Africa Summer Time", offset => ["+02:00"] },
  "WAT"    => { comment => "West Africa Time", offset => ["+01:00"] },
  "WEST"   => { comment => "Western European Summer Time", offset => ["+01:00"] },
  "WESZ"   => { comment => "Westeuropaische Sommerzeit", offset => ["+0100"] },
  "WET"    => { comment => "Western European Time", offset => ["UTC"] },
  "WETDST" => { comment => "European Western Summer", offset => ["+0100"] },
  "WEZ"    => { comment => "Western Europe Time", offset => ["+0000"] },
  "WFT"    => { comment => "Wallis and Futuna Time", offset => ["+1200"] },
  "WGST"   => { comment => "West Greenland Summer Time", offset => ["-02:00"] },
  "WGT"    => { comment => "West Greenland Time", offset => ["-03:00"] },
  "WIB"    => { comment => "Western Indonesian Time", offset => ["+07:00"] },
  "WIT"    => { comment => "Eastern Indonesian Time", offset => ["+09:00"] },
  "WITA"   => { comment => "Central Indonesia Time", offset => ["+08:00"] },
  "WST"    => { comment => "Western Standard Time", offset => ["+08:00"] },
  "WTZ"    => { comment => "Greenland Eastern Daylight Time", offset => ["-0100"] },
  "WUT"    => { comment => "Austria Time", offset => ["+0100"] },
  "X"      => { comment => "X-ray Military Time Zone", offset => [-1100] },
  "Y"      => { comment => "Yankee Military Time Zone", offset => [-1200] },
  "YAKST"  => { comment => "Yakutsk Summer Time", offset => ["+1000"] },
  "YAKT"   => { comment => "Yakutsk Time", offset => ["+09:00"] },
  "YAPT"   => { comment => "Yap Time (Micronesia)", offset => ["+1000"] },
  "YDT"    => { comment => "Yukon Daylight Time", offset => ["-0800"] },
  "YEKST"  => { comment => "Yekaterinburg Summer Time", offset => ["+0600"] },
  "YEKT"   => { comment => "Yekaterinburg Time", offset => ["+05:00"] },
  "YST"    => { comment => "Yukon Standard Time", offset => ["-0900"] },
  "Z"      => { comment => "Zulu", offset => ["+0000"] },
};

sub import
{
    my $class = shift( @_ );
    local $@;
    foreach my $alias ( keys( %$ALIAS_CATALOG ) )
    {
        next if( DateTime::TimeZone::Alias->is_defined( $alias ) );
        # try-catch
        eval
        {
            DateTime::TimeZone::Alias->add( $alias => $ALIAS_CATALOG->{ $alias }->{offset}->[0] );
        };
        if( $@ )
        {
            warnings::warn( "Warning only: error trying to add time zone alias '$alias' (" . $ALIAS_CATALOG->{ $alias }->{comment} . ") with time zone offset '" . $ALIAS_CATALOG->{ $alias }->{offset}->[0] . "': $@\n" ) if( warnings::enabled() );
        }
    }
}

sub aliases { return( [sort(keys( %$ALIAS_CATALOG ) )] ); }

sub zone_map
{
    if( defined( $ZONE_MAP ) )
    {
        return( $ZONE_MAP );
    }
    $ZONE_MAP = +{ map{ $_ => $ALIAS_CATALOG->{ $_ }->{offset}->[0] } keys( %$ALIAS_CATALOG ) };
    return( $ZONE_MAP );
}

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

    my $map = DateTime::TimeZone::Catalog::Extend->zone_map;
    my $fmt = DateTime::Format::Strptime->new(
        pattern => $pattern,
        zone_map => $map,
    );
    my $dt = $fmt->parse_datetime( $str );
    die( $fmt->errmsg ) if( !defined( $dt ) );

=head1 VERSION

    v0.3.3

=head1 DESCRIPTION

This is a very simple module based on the L<list of time zone aliases|https://en.wikipedia.org/wiki/List_of_time_zone_abbreviations> that are sometimes found in dates.

Upon using this module, it will add to the L<DateTime::TimeZone::Catalog> those aliases with their corresponding time zone offset. When there is more than one time zone offset in the list, only the first one is set.

Here is the list of those time zone aliases and their offset:

=over 4

=item 1. C<A> +0100 (Alpha Military Time Zone)

=item 2. C<ACDT> +10:30 (Australian Central Daylight Saving Time)

=item 3. C<ACST> +09:30 (Australian Central Standard Time)

=item 4. C<ACT> +08:00 (ASEAN Common Time)

=item 5. C<ACWST> +08:45 (Australian Central Western Standard Time)

=item 6. C<ADT> -03:00 (Atlantic Daylight Time)

=item 7. C<AEDT> +11:00 (Australian Eastern Daylight Saving Time)

=item 8. C<AES> +10:00 (Australian Eastern Standard Time)

=item 9. C<AEST> +10:00 (Australian Eastern Standard Time)

=item 10. C<AET> +10:00 (Australian Eastern Time)

=item 11. C<AFT> +04:30 (Afghanistan Time)

=item 12. C<AHDT> -0900 (Alaska-Hawaii Daylight Time)

=item 13. C<AHST> -1000 (Alaska-Hawaii Standard Time)

=item 14. C<AKDT> -08:00 (Alaska Daylight Time)

=item 15. C<AKST> -09:00 (Alaska Standard Time)

=item 16. C<ALMT> +06:00 (Alma-Ata Time)

=item 17. C<AMST> -03:00 (Amazon Summer Time (Brazil))

=item 18. C<AMT> +04:00 (Armenia Time)

=item 19. C<ANAST> +1300 (Anadyr Summer Time)

=item 20. C<ANAT> +12:00 (Anadyr Time)

=item 21. C<AQTT> +05:00 (Aqtobe Time)

=item 22. C<ART> -03:00 (Argentina Time)

=item 23. C<AST> -04:00 (Atlantic Standard Time)

=item 24. C<AT> -0100 (Azores Time)

=item 25. C<AWST> +08:00 (Australian Western Standard Time)

=item 26. C<AZOST> UTC (Azores Summer Time)

=item 27. C<AZOT> -01:00 (Azores Standard Time)

=item 28. C<AZST> +0500 (Azerbaijan Summer Time)

=item 29. C<AZT> +04:00 (Azerbaijan Time)

=item 30. C<B> +0200 (Bravo Military Time Zone)

=item 31. C<BADT> +0400 (Baghdad Daylight Time)

=item 32. C<BAT> +0600 (Baghdad Time)

=item 33. C<BDST> +0200 (British Double Summer Time)

=item 34. C<BDT> +0600 (Bangladesh Time)

=item 35. C<BET> -1100 (Bering Standard Time)

=item 36. C<BIOT> +06:00 (British Indian Ocean Time)

=item 37. C<BIT> -12:00 (Baker Island Time)

=item 38. C<BNT> +08:00 (Brunei Time)

=item 39. C<BORT> +0800 (Borneo Time (Indonesia))

=item 40. C<BOT> -04:00 (Bolivia Time)

=item 41. C<BRA> -0300 (Brazil Time)

=item 42. C<BRST> -02:00 (Brasília Summer Time)

=item 43. C<BRT> -03:00 (Brasília Time)

=item 44. C<BST> +01:00 (British Summer Time (British Standard Time from Feb 1968 to Oct 1971))

=item 45. C<BTT> +06:00 (Bhutan Time)

=item 46. C<C> +0300 (Charlie Military Time Zone)

=item 47. C<CAST> +0930 (Casey Time Zone)

=item 48. C<CAT> +02:00 (Central Africa Time)

=item 49. C<CCT> +06:30 (Cocos Islands Time)

=item 50. C<CDT> -04:00 (Cuba Daylight Time)

=item 51. C<CEST> +02:00 (Central European Summer Time)

=item 52. C<CET> +01:00 (Central European Time)

=item 53. C<CETDST> +0200 (Central Europe Summer Time)

=item 54. C<CHADT> +13:45 (Chatham Daylight Time)

=item 55. C<CHAST> +12:45 (Chatham Standard Time)

=item 56. C<CHOST> +09:00 (Choibalsan Summer Time)

=item 57. C<CHOT> +08:00 (Choibalsan Standard Time)

=item 58. C<CHST> +10:00 (Chamorro Standard Time)

=item 59. C<CHUT> +10:00 (Chuuk Time)

=item 60. C<CIST> -08:00 (Clipperton Island Standard Time)

=item 61. C<CKT> -10:00 (Cook Island Time)

=item 62. C<CLST> -03:00 (Chile Summer Time)

=item 63. C<CLT> -04:00 (Chile Standard Time)

=item 64. C<COST> -04:00 (Colombia Summer Time)

=item 65. C<COT> -05:00 (Colombia Time)

=item 66. C<CST> -05:00 (Cuba Standard Time)

=item 67. C<CSuT> +1030 (Australian Central Daylight)

=item 68. C<CT> -06:00 (Central Time)

=item 69. C<CUT> +0000 (Coordinated Universal Time)

=item 70. C<CVT> -01:00 (Cape Verde Time)

=item 71. C<CWST> +08:45 (Central Western Standard Time (Australia))

=item 72. C<CXT> +07:00 (Christmas Island Time)

=item 73. C<ChST> +1000 (Chamorro Standard Time)

=item 74. C<D> +0400 (Delta Military Time Zone)

=item 75. C<DAVT> +07:00 (Davis Time)

=item 76. C<DDUT> +10:00 (Dumont d'Urville Time)

=item 77. C<DFT> +01:00 (AIX-specific equivalent of Central European Time)

=item 78. C<DNT> +0100 (Dansk Normal)

=item 79. C<DST> +0200 (Dansk Summer)

=item 80. C<E> +0500 (Echo Military Time Zone)

=item 81. C<EASST> -05:00 (Easter Island Summer Time)

=item 82. C<EAST> -06:00 (Easter Island Standard Time)

=item 83. C<EAT> +03:00 (East Africa Time)

=item 84. C<ECT> -05:00 (Ecuador Time)

=item 85. C<EDT> -04:00 (Eastern Daylight Time (North America))

=item 86. C<EEST> +03:00 (Eastern European Summer Time)

=item 87. C<EET> +02:00 (Eastern European Time)

=item 88. C<EETDST> +0300 (European Eastern Summer)

=item 89. C<EGST> UTC (Eastern Greenland Summer Time)

=item 90. C<EGT> -01:00 (Eastern Greenland Time)

=item 91. C<EMT> +0100 (Norway Time)

=item 92. C<EST> -05:00 (Eastern Standard Time (North America))

=item 93. C<ESuT> +1100 (Australian Eastern Daylight)

=item 94. C<ET> -04:00 (Eastern Time (North America))

=item 95. C<F> +0600 (Foxtrot Military Time Zone)

=item 96. C<FET> +03:00 (Further-eastern European Time)

=item 97. C<FJST> +1300 (Fiji Summer Time)

=item 98. C<FJT> +12:00 (Fiji Time)

=item 99. C<FKST> -03:00 (Falkland Islands Summer Time)

=item 100. C<FKT> -04:00 (Falkland Islands Time)

=item 101. C<FNT> -02:00 (Fernando de Noronha Time)

=item 102. C<FWT> +0100 (French Winter Time)

=item 103. C<G> +0700 (Golf Military Time Zone)

=item 104. C<GALT> -06:00 (Galapagos Time)

=item 105. C<GAMT> -09:00 (Gambier Islands Time)

=item 106. C<GEST> +0500 (Georgia Summer Time)

=item 107. C<GET> +04:00 (Georgia Standard Time)

=item 108. C<GFT> -03:00 (French Guiana Time)

=item 109. C<GILT> +12:00 (Gilbert Island Time)

=item 110. C<GIT> -09:00 (Gambier Island Time)

=item 111. C<GMT> UTC (Greenwich Mean Time)

=item 112. C<GST> +04:00 (Gulf Standard Time)

=item 113. C<GT> +0000 (Greenwich Time)

=item 114. C<GYT> -04:00 (Guyana Time)

=item 115. C<GZ> +0000 (Greenwichzeit)

=item 116. C<H> +0800 (Hotel Military Time Zone)

=item 117. C<HAA> -0300 (Heure Avancée de l'Atlantique)

=item 118. C<HAC> -0500 (Heure Avancee du Centre)

=item 119. C<HAE> -0400 (Heure Avancee de l'Est)

=item 120. C<HAEC> +02:00 (Heure Avancée d'Europe Centrale)

=item 121. C<HAP> -0700 (Heure Avancee du Pacifique)

=item 122. C<HAR> -0600 (Heure Avancee des Rocheuses)

=item 123. C<HAT> -0230 (Heure Avancee de Terre-Neuve)

=item 124. C<HAY> -0800 (Heure Avancee du Yukon)

=item 125. C<HDT> -09:00 (Hawaii–Aleutian Daylight Time)

=item 126. C<HFE> +0200 (Heure Fancais d'Ete)

=item 127. C<HFH> +0100 (Heure Fancais d'Hiver)

=item 128. C<HG> +0000 (Heure de Greenwich)

=item 129. C<HKT> +08:00 (Hong Kong Time)

=item 130. C<HL> local (Heure locale)

=item 131. C<HMT> +05:00 (Heard and McDonald Islands Time)

=item 132. C<HNA> -0400 (Heure Normale de l'Atlantique)

=item 133. C<HNC> -0600 (Heure Normale du Centre)

=item 134. C<HNE> -0500 (Heure Normale de l'Est)

=item 135. C<HNP> -0800 (Heure Normale du Pacifique)

=item 136. C<HNR> -0700 (Heure Normale des Rocheuses)

=item 137. C<HNT> -0330 (Heure Normale de Terre-Neuve)

=item 138. C<HNY> -0900 (Heure Normale du Yukon)

=item 139. C<HOE> +0100 (Spain Time)

=item 140. C<HOVST> +08:00 (Hovd Summer Time (not used from 2017-present))

=item 141. C<HOVT> +07:00 (Hovd Time)

=item 142. C<HST> -10:00 (Hawaii–Aleutian Standard Time)

=item 143. C<I> +0900 (India Military Time Zone)

=item 144. C<ICT> +07:00 (Indochina Time)

=item 145. C<IDLE> +1200 (Internation Date Line East)

=item 146. C<IDLW> -12:00 (International Day Line West time zone)

=item 147. C<IDT> +03:00 (Israel Daylight Time)

=item 148. C<IOT> +03:00 (Indian Ocean Time)

=item 149. C<IRDT> +04:30 (Iran Daylight Time)

=item 150. C<IRKST> +0900 (Irkutsk Summer Time)

=item 151. C<IRKT> +08:00 (Irkutsk Time)

=item 152. C<IRST> +03:30 (Iran Standard Time)

=item 153. C<IRT> +0330 (Iran Time)

=item 154. C<IST> +02:00 (Israel Standard Time)

=item 155. C<IT> +0330 (Iran Time)

=item 156. C<ITA> +0100 (Italy Time)

=item 157. C<JAVT> +0700 (Java Time)

=item 158. C<JAYT> +0900 (Jayapura Time (Indonesia))

=item 159. C<JST> +09:00 (Japan Standard Time)

=item 160. C<JT> +0700 (Java Time)

=item 161. C<K> +1000 (Kilo Military Time Zone)

=item 162. C<KALT> +02:00 (Kaliningrad Time)

=item 163. C<KDT> +1000 (Korean Daylight Time)

=item 164. C<KGST> +0600 (Kyrgyzstan Summer Time)

=item 165. C<KGT> +06:00 (Kyrgyzstan Time)

=item 166. C<KOST> +11:00 (Kosrae Time)

=item 167. C<KRAST> +0800 (Krasnoyarsk Summer Time)

=item 168. C<KRAT> +07:00 (Krasnoyarsk Time)

=item 169. C<KST> +09:00 (Korea Standard Time)

=item 170. C<L> +1100 (Lima Military Time Zone)

=item 171. C<LHDT> +1100 (Lord Howe Daylight Time)

=item 172. C<LHST> +11:00 (Lord Howe Summer Time)

=item 173. C<LIGT> +1000 (Melbourne, Australia)

=item 174. C<LINT> +14:00 (Line Islands Time)

=item 175. C<LKT> +0600 (Lanka Time)

=item 176. C<LST> local (Local Sidereal Time)

=item 177. C<LT> local (Local Time)

=item 178. C<M> +1200 (Mike Military Time Zone)

=item 179. C<MAGST> +1200 (Magadan Summer Time)

=item 180. C<MAGT> +12:00 (Magadan Time)

=item 181. C<MAL> +0800 (Malaysia Time)

=item 182. C<MART> -09:30 (Marquesas Islands Time)

=item 183. C<MAT> +0300 (Turkish Standard Time)

=item 184. C<MAWT> +05:00 (Mawson Station Time)

=item 185. C<MDT> -06:00 (Mountain Daylight Time (North America))

=item 186. C<MED> +0200 (Middle European Daylight)

=item 187. C<MEDST> +0200 (Middle European Summer)

=item 188. C<MEST> +02:00 (Middle European Summer Time)

=item 189. C<MESZ> +0200 (Mitteieuropaische Sommerzeit)

=item 190. C<MET> +01:00 (Middle European Time)

=item 191. C<MEWT> +0100 (Middle European Winter Time)

=item 192. C<MEX> -0600 (Mexico Time)

=item 193. C<MEZ> +0100 (Mitteieuropaische Zeit)

=item 194. C<MHT> +12:00 (Marshall Islands Time)

=item 195. C<MIST> +11:00 (Macquarie Island Station Time)

=item 196. C<MIT> -09:30 (Marquesas Islands Time)

=item 197. C<MMT> +06:30 (Myanmar Standard Time)

=item 198. C<MPT> +1000 (North Mariana Islands Time)

=item 199. C<MSD> +0400 (Moscow Summer Time)

=item 200. C<MSK> +03:00 (Moscow Time)

=item 201. C<MSKS> +0400 (Moscow Summer Time)

=item 202. C<MST> -07:00 (Mountain Standard Time)

=item 203. C<MT> +0830 (Moluccas)

=item 204. C<MUT> +04:00 (Mauritius Time)

=item 205. C<MVT> +05:00 (Maldives Time)

=item 206. C<MYT> +08:00 (Malaysia Time)

=item 207. C<N> -0100 (November Military Time Zone)

=item 208. C<NCT> +11:00 (New Caledonia Time)

=item 209. C<NDT> -02:30 (Newfoundland Daylight Time)

=item 210. C<NFT> +11:00 (Norfolk Island Time)

=item 211. C<NOR> +0100 (Norway Time)

=item 212. C<NOVST> +0700 (Novosibirsk Summer Time (Russia))

=item 213. C<NOVT> +07:00 (Novosibirsk Time)

=item 214. C<NPT> +05:45 (Nepal Time)

=item 215. C<NRT> +1200 (Nauru Time)

=item 216. C<NST> -03:30 (Newfoundland Standard Time)

=item 217. C<NSUT> +0630 (North Sumatra Time)

=item 218. C<NT> -03:30 (Newfoundland Time)

=item 219. C<NUT> -11:00 (Niue Time)

=item 220. C<NZDT> +13:00 (New Zealand Daylight Time)

=item 221. C<NZST> +12:00 (New Zealand Standard Time)

=item 222. C<NZT> +1200 (New Zealand Standard Time)

=item 223. C<O> -0200 (Oscar Military Time Zone)

=item 224. C<OESZ> +0300 (Osteuropaeische Sommerzeit)

=item 225. C<OEZ> +0200 (Osteuropaische Zeit)

=item 226. C<OMSST> +0700 (Omsk Summer Time)

=item 227. C<OMST> +06:00 (Omsk Time)

=item 228. C<ORAT> +05:00 (Oral Time)

=item 229. C<OZ> local (Ortszeit)

=item 230. C<P> -0300 (Papa Military Time Zone)

=item 231. C<PDT> -07:00 (Pacific Daylight Time (North America))

=item 232. C<PET> -05:00 (Peru Time)

=item 233. C<PETST> +1300 (Kamchatka Summer Time)

=item 234. C<PETT> +12:00 (Kamchatka Time)

=item 235. C<PGT> +10:00 (Papua New Guinea Time)

=item 236. C<PHOT> +13:00 (Phoenix Island Time)

=item 237. C<PHST> +08:00 (Philippine Standard Time)

=item 238. C<PHT> +08:00 (Philippine Time)

=item 239. C<PKT> +05:00 (Pakistan Standard Time)

=item 240. C<PMDT> -02:00 (Saint Pierre and Miquelon Daylight Time)

=item 241. C<PMST> -03:00 (Saint Pierre and Miquelon Standard Time)

=item 242. C<PMT> -0300 (Pierre & Miquelon Standard Time)

=item 243. C<PNT> -0830 (Pitcairn Time)

=item 244. C<PONT> +11:00 (Pohnpei Standard Time)

=item 245. C<PST> -08:00 (Pacific Standard Time (North America))

=item 246. C<PWT> +09:00 (Palau Time)

=item 247. C<PYST> -03:00 (Paraguay Summer Time)

=item 248. C<PYT> -04:00 (Paraguay Time)

=item 249. C<Q> -0400 (Quebec Military Time Zone)

=item 250. C<R> -0500 (Romeo Military Time Zone)

=item 251. C<R1T> +0200 (Russia Zone 1)

=item 252. C<R2T> +0300 (Russia Zone 2)

=item 253. C<RET> +04:00 (Réunion Time)

=item 254. C<ROK> +0900 (Korean Standard Time)

=item 255. C<ROTT> -03:00 (Rothera Research Station Time)

=item 256. C<S> -0600 (Sierra Military Time Zone)

=item 257. C<SADT> +1030 (Australian South Daylight Time)

=item 258. C<SAKT> +11:00 (Sakhalin Island Time)

=item 259. C<SAMT> +04:00 (Samara Time)

=item 260. C<SAST> +02:00 (South African Standard Time)

=item 261. C<SBT> +11:00 (Solomon Islands Time)

=item 262. C<SCT> +04:00 (Seychelles Time)

=item 263. C<SDT> -10:00 (Samoa Daylight Time)

=item 264. C<SET> +0100 (Prague, Vienna Time)

=item 265. C<SGT> +08:00 (Singapore Time)

=item 266. C<SLST> +05:30 (Sri Lanka Standard Time)

=item 267. C<SRET> +11:00 (Srednekolymsk Time)

=item 268. C<SRT> -03:00 (Suriname Time)

=item 269. C<SST> +08:00 (Singapore Standard Time)

=item 270. C<SWT> +0100 (Swedish Winter)

=item 271. C<SYOT> +03:00 (Showa Station Time)

=item 272. C<T> -0700 (Tango Military Time Zone)

=item 273. C<TAHT> -10:00 (Tahiti Time)

=item 274. C<TFT> +05:00 (French Southern and Antarctic Time)

=item 275. C<THA> +07:00 (Thailand Standard Time)

=item 276. C<THAT> -1000 (Tahiti Time)

=item 277. C<TJT> +05:00 (Tajikistan Time)

=item 278. C<TKT> +13:00 (Tokelau Time)

=item 279. C<TLT> +09:00 (Timor Leste Time)

=item 280. C<TMT> +05:00 (Turkmenistan Time)

=item 281. C<TOT> +13:00 (Tonga Time)

=item 282. C<TRT> +03:00 (Turkey Time)

=item 283. C<TRUT> +1000 (Truk Time)

=item 284. C<TST> +0300 (Turkish Standard Time)

=item 285. C<TUC > +0000 (Temps Universel Coordonné)

=item 286. C<TVT> +12:00 (Tuvalu Time)

=item 287. C<U> -0800 (Uniform Military Time Zone)

=item 288. C<ULAST> +09:00 (Ulaanbaatar Summer Time)

=item 289. C<ULAT> +08:00 (Ulaanbaatar Standard Time)

=item 290. C<USZ1> +0200 (Russia Zone 1)

=item 291. C<USZ1S> +0300 (Kaliningrad Summer Time (Russia))

=item 292. C<USZ3> +0400 (Volga Time (Russia))

=item 293. C<USZ3S> +0500 (Volga Summer Time (Russia))

=item 294. C<USZ4> +0500 (Ural Time (Russia))

=item 295. C<USZ4S> +0600 (Ural Summer Time (Russia))

=item 296. C<USZ5> +0600 (West-Siberian Time (Russia))

=item 297. C<USZ5S> +0700 (West-Siberian Summer Time)

=item 298. C<USZ6> +0700 (Yenisei Time (Russia))

=item 299. C<USZ6S> +0800 (Yenisei Summer Time (Russia))

=item 300. C<USZ7> +0800 (Irkutsk Time (Russia))

=item 301. C<USZ7S> +0900 (Irkutsk Summer Time)

=item 302. C<USZ8> +0900 (Amur Time (Russia))

=item 303. C<USZ8S> +1000 (Amur Summer Time (Russia))

=item 304. C<USZ9> +1000 (Vladivostok Time (Russia))

=item 305. C<USZ9S> +1100 (Vladivostok Summer Time (Russia))

=item 306. C<UTC> UTC (Coordinated Universal Time)

=item 307. C<UTZ> -0300 (Greenland Western Standard Time)

=item 308. C<UYST> -02:00 (Uruguay Summer Time)

=item 309. C<UYT> -03:00 (Uruguay Standard Time)

=item 310. C<UZ10> +1100 (Okhotsk Time (Russia))

=item 311. C<UZ10S> +1200 (Okhotsk Summer Time (Russia))

=item 312. C<UZ11> +1200 (Kamchatka Time (Russia))

=item 313. C<UZ11S> +1300 (Kamchatka Summer Time (Russia))

=item 314. C<UZ12> +1200 (Chukot Time (Russia))

=item 315. C<UZ12S> +1300 (Chukot Summer Time (Russia))

=item 316. C<UZT> +05:00 (Uzbekistan Time)

=item 317. C<V> -0900 (Victor Military Time Zone)

=item 318. C<VET> -04:00 (Venezuelan Standard Time)

=item 319. C<VLAST> +1100 (Vladivostok Summer Time)

=item 320. C<VLAT> +10:00 (Vladivostok Time)

=item 321. C<VOLT> +03:00 (Volgograd Time)

=item 322. C<VOST> +06:00 (Vostok Station Time)

=item 323. C<VTZ> -0200 (Greenland Eastern Standard Time)

=item 324. C<VUT> +11:00 (Vanuatu Time)

=item 325. C<W> -1000 (Whiskey Military Time Zone)

=item 326. C<WAKT> +12:00 (Wake Island Time)

=item 327. C<WAST> +02:00 (West Africa Summer Time)

=item 328. C<WAT> +01:00 (West Africa Time)

=item 329. C<WEST> +01:00 (Western European Summer Time)

=item 330. C<WESZ> +0100 (Westeuropaische Sommerzeit)

=item 331. C<WET> UTC (Western European Time)

=item 332. C<WETDST> +0100 (European Western Summer)

=item 333. C<WEZ> +0000 (Western Europe Time)

=item 334. C<WFT> +1200 (Wallis and Futuna Time)

=item 335. C<WGST> -02:00 (West Greenland Summer Time)

=item 336. C<WGT> -03:00 (West Greenland Time)

=item 337. C<WIB> +07:00 (Western Indonesian Time)

=item 338. C<WIT> +09:00 (Eastern Indonesian Time)

=item 339. C<WITA> +08:00 (Central Indonesia Time)

=item 340. C<WST> +08:00 (Western Standard Time)

=item 341. C<WTZ> -0100 (Greenland Eastern Daylight Time)

=item 342. C<WUT> +0100 (Austria Time)

=item 343. C<X> -1100 (X-ray Military Time Zone)

=item 344. C<Y> -1200 (Yankee Military Time Zone)

=item 345. C<YAKST> +1000 (Yakutsk Summer Time)

=item 346. C<YAKT> +09:00 (Yakutsk Time)

=item 347. C<YAPT> +1000 (Yap Time (Micronesia))

=item 348. C<YDT> -0800 (Yukon Daylight Time)

=item 349. C<YEKST> +0600 (Yekaterinburg Summer Time)

=item 350. C<YEKT> +05:00 (Yekaterinburg Time)

=item 351. C<YST> -0900 (Yukon Standard Time)

=item 352. C<Z> +0000 (Zulu)

=back

=head1 METHODS

=head2 aliases

Returns an array reference of the time zone aliases.

    my $aliases = DateTime::TimeZone::Catalog::Extend->aliases;

You can also achieve the same result by accessing directly the package variable C<$ALIAS_CATALOG>

    my $aliases = [sort( keys( %$DateTime::TimeZone::Catalog::Extend::ALIAS_CATALOG ) )];

=head2 zone_map

Returns an hash reference of time zone alias to their offset. This class function caches the hash reference so the second time it returns the cached value.

The returned hash reference is suitable to be passed to L<DateTime::Format::Strptime/new> with the argument C<zone_map>

    my $str = 'Fri Mar 25 2011 12:16:25 ADT';
    my $map = DateTime::TimeZone::Catalog::Extend->zone_map;
    my $fmt = DateTime::Format::Strptime->new(
        pattern => $pattern,
        zone_map => $map,
    );
    my $dt = $fmt->parse_datetime( $str );
    die( $fmt->errmsg ) if( !defined( $dt ) );

Without passing the C<zone_map>, L<DateTime::Format::Strptime> would have returned the error c<The time zone abbreviation that was parsed is ambiguous>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DateTime::TimeZone::Catalog>, L<DateTime::TimeZone::Alias>, L<DateTime::TimeZone>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
