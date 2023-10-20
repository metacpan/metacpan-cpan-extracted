package Business::IBAN::Database;
use warnings;
use strict;

our $VERSION = 0.095; # Release of the document

use Business::IBAN::Util qw/numify_iban mod97/;
use Hash::Util 'lock_hash';

use Exporter 'import';
our @EXPORT = qw/iban_db numify_iban mod97/;

my %iban_db = (
  'AD' => {
    'country' => 'Andorra',
    'iban_length' => '24',
    'iban_structure' => 'AD[0-9]{2}[0-9]{4}[0-9]{4}[A-Za-z0-9]{12}',
    'is_sepa' => 1,
    'pattern' => 'AD2!n4!n4!n12!c'
  },
  'AE' => {
    'country' => 'United Arab Emirates (The)',
    'iban_length' => '23',
    'iban_structure' => 'AE[0-9]{2}[0-9]{3}[0-9]{16}',
    'is_sepa' => 0,
    'pattern' => 'AE2!n3!n16!n'
  },
  'AL' => {
    'country' => 'Albania',
    'iban_length' => '28',
    'iban_structure' => 'AL[0-9]{2}[0-9]{8}[A-Za-z0-9]{16}',
    'is_sepa' => 0,
    'pattern' => 'AL2!n8!n16!c'
  },
  'AT' => {
    'country' => 'Austria',
    'iban_length' => '20',
    'iban_structure' => 'AT[0-9]{2}[0-9]{5}[0-9]{11}',
    'is_sepa' => 1,
    'pattern' => 'AT2!n5!n11!n'
  },
  'AZ' => {
    'country' => 'Azerbaijan',
    'iban_length' => '28',
    'iban_structure' => 'AZ[0-9]{2}[A-Z]{4}[A-Za-z0-9]{20}',
    'is_sepa' => 0,
    'pattern' => 'AZ2!n4!a20!c'
  },
  'BA' => {
    'country' => 'Bosnia and Herzegovina',
    'iban_length' => '20',
    'iban_structure' => 'BA[0-9]{2}[0-9]{3}[0-9]{3}[0-9]{8}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'BA2!n3!n3!n8!n2!n'
  },
  'BE' => {
    'country' => 'Belgium',
    'iban_length' => '16',
    'iban_structure' => 'BE[0-9]{2}[0-9]{3}[0-9]{7}[0-9]{2}',
    'is_sepa' => 1,
    'pattern' => 'BE2!n3!n7!n2!n'
  },
  'BG' => {
    'country' => 'Bulgaria',
    'iban_length' => '22',
    'iban_structure' => 'BG[0-9]{2}[A-Z]{4}[0-9]{4}[0-9]{2}[A-Za-z0-9]{8}',
    'is_sepa' => 1,
    'pattern' => 'BG2!n4!a4!n2!n8!c'
  },
  'BH' => {
    'country' => 'Bahrain',
    'iban_length' => '22',
    'iban_structure' => 'BH[0-9]{2}[A-Z]{4}[A-Za-z0-9]{14}',
    'is_sepa' => 0,
    'pattern' => 'BH2!n4!a14!c'
  },
  'BI' => {
    'country' => 'Burundi',
    'iban_length' => '27',
    'iban_structure' => 'BI[0-9]{2}[0-9]{5}[0-9]{5}[0-9]{11}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'BI2!n5!n5!n11!n2!n'
  },
  'BR' => {
    'country' => 'Brazil',
    'iban_length' => '29',
    'iban_structure' => 'BR[0-9]{2}[0-9]{8}[0-9]{5}[0-9]{10}[A-Z]{1}[A-Za-z0-9]{1}',
    'is_sepa' => 0,
    'pattern' => 'BR2!n8!n5!n10!n1!a1!c'
  },
  'BY' => {
    'country' => 'Republic of Belarus',
    'iban_length' => '28',
    'iban_structure' => 'BY[0-9]{2}[A-Za-z0-9]{4}[0-9]{4}[A-Za-z0-9]{16}',
    'is_sepa' => 0,
    'pattern' => 'BY2!n4!c4!n16!c'
  },
  'CH' => {
    'country' => 'Switzerland',
    'iban_length' => '21',
    'iban_structure' => 'CH[0-9]{2}[0-9]{5}[A-Za-z0-9]{12}',
    'is_sepa' => 1,
    'pattern' => 'CH2!n5!n12!c'
  },
  'CR' => {
    'country' => 'Costa Rica',
    'iban_length' => '22',
    'iban_structure' => 'CR[0-9]{2}[0-9]{4}[0-9]{14}',
    'is_sepa' => 0,
    'pattern' => 'CR2!n4!n14!n'
  },
  'CY' => {
    'country' => 'Cyprus',
    'iban_length' => '28',
    'iban_structure' => 'CY[0-9]{2}[0-9]{3}[0-9]{5}[A-Za-z0-9]{16}',
    'is_sepa' => 1,
    'pattern' => 'CY2!n3!n5!n16!c'
  },
  'CZ' => {
    'country' => 'Czechia',
    'iban_length' => '24',
    'iban_structure' => 'CZ[0-9]{2}[0-9]{4}[0-9]{6}[0-9]{10}',
    'is_sepa' => 1,
    'pattern' => 'CZ2!n4!n6!n10!n'
  },
  'DE' => {
    'country' => 'Germany',
    'iban_length' => '22',
    'iban_structure' => 'DE[0-9]{2}[0-9]{8}[0-9]{10}',
    'is_sepa' => 1,
    'pattern' => 'DE2!n8!n10!n'
  },
  'DJ' => {
    'country' => 'Djibouti',
    'iban_length' => '27',
    'iban_structure' => 'DJ[0-9]{2}[0-9]{5}[0-9]{5}[0-9]{11}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'DJ2!n5!n5!n11!n2!n'
  },
  'DK' => {
    'country' => 'Denmark',
    'iban_length' => '18',
    'iban_structure' => 'DK[0-9]{2}[0-9]{4}[0-9]{9}[0-9]{1}',
    'is_sepa' => 1,
    'pattern' => 'DK2!n4!n9!n1!n'
  },
  'DO' => {
    'country' => 'Dominican Republic',
    'iban_length' => '28',
    'iban_structure' => 'DO[0-9]{2}[A-Za-z0-9]{4}[0-9]{20}',
    'is_sepa' => 0,
    'pattern' => 'DO2!n4!c20!n'
  },
  'EE' => {
    'country' => 'Estonia',
    'iban_length' => '20',
    'iban_structure' => 'EE[0-9]{2}[0-9]{2}[0-9]{2}[0-9]{11}[0-9]{1}',
    'is_sepa' => 1,
    'pattern' => 'EE2!n2!n2!n11!n1!n'
  },
  'EG' => {
    'country' => 'Egypt',
    'iban_length' => '29',
    'iban_structure' => 'EG[0-9]{2}[0-9]{4}[0-9]{4}[0-9]{17}',
    'is_sepa' => 0,
    'pattern' => 'EG2!n4!n4!n17!n'
  },
  'ES' => {
    'country' => 'Spain',
    'iban_length' => '24',
    'iban_structure' => 'ES[0-9]{2}[0-9]{4}[0-9]{4}[0-9]{1}[0-9]{1}[0-9]{10}',
    'is_sepa' => 1,
    'pattern' => 'ES2!n4!n4!n1!n1!n10!n'
  },
  'FI' => {
    'country' => 'Finland',
    'iban_length' => '18',
    'iban_structure' => 'FI[0-9]{2}[0-9]{3}[0-9]{11}',
    'is_sepa' => 1,
    'pattern' => 'FI2!n3!n11!n'
  },
  'FK' => {
    'country' => 'Falkland Islands',
    'iban_length' => '18',
    'iban_structure' => 'FK[0-9]{2}[A-Z]{2}[0-9]{12}',
    'is_sepa' => 0,
    'pattern' => 'FK2!n2!a12!n'
  },
  'FO' => {
    'country' => 'Faroe Islands',
    'iban_length' => '18',
    'iban_structure' => 'FO[0-9]{2}[0-9]{4}[0-9]{9}[0-9]{1}',
    'is_sepa' => 0,
    'pattern' => 'FO2!n4!n9!n1!n'
  },
  'FR' => {
    'country' => 'France',
    'iban_length' => '27',
    'iban_structure' => 'FR[0-9]{2}[0-9]{5}[0-9]{5}[A-Za-z0-9]{11}[0-9]{2}',
    'is_sepa' => 1,
    'pattern' => 'FR2!n5!n5!n11!c2!n'
  },
  'GB' => {
    'country' => 'United Kingdom',
    'iban_length' => '22',
    'iban_structure' => 'GB[0-9]{2}[A-Z]{4}[0-9]{6}[0-9]{8}',
    'is_sepa' => 1,
    'pattern' => 'GB2!n4!a6!n8!n'
  },
  'GE' => {
    'country' => 'Georgia',
    'iban_length' => '22',
    'iban_structure' => 'GE[0-9]{2}[A-Z]{2}[0-9]{16}',
    'is_sepa' => 0,
    'pattern' => 'GE2!n2!a16!n'
  },
  'GI' => {
    'country' => 'Gibraltar',
    'iban_length' => '23',
    'iban_structure' => 'GI[0-9]{2}[A-Z]{4}[A-Za-z0-9]{15}',
    'is_sepa' => 1,
    'pattern' => 'GI2!n4!a15!c'
  },
  'GL' => {
    'country' => 'Greenland',
    'iban_length' => '18',
    'iban_structure' => 'GL[0-9]{2}[0-9]{4}[0-9]{9}[0-9]{1}',
    'is_sepa' => 0,
    'pattern' => 'GL2!n4!n9!n1!n'
  },
  'GR' => {
    'country' => 'Greece',
    'iban_length' => '27',
    'iban_structure' => 'GR[0-9]{2}[0-9]{3}[0-9]{4}[A-Za-z0-9]{16}',
    'is_sepa' => 1,
    'pattern' => 'GR2!n3!n4!n16!c'
  },
  'GT' => {
    'country' => 'Guatemala',
    'iban_length' => '28',
    'iban_structure' => 'GT[0-9]{2}[A-Za-z0-9]{4}[A-Za-z0-9]{20}',
    'is_sepa' => 0,
    'pattern' => 'GT2!n4!c20!c'
  },
  'HR' => {
    'country' => 'Croatia',
    'iban_length' => '21',
    'iban_structure' => 'HR[0-9]{2}[0-9]{7}[0-9]{10}',
    'is_sepa' => 1,
    'pattern' => 'HR2!n7!n10!n'
  },
  'HU' => {
    'country' => 'Hungary',
    'iban_length' => '28',
    'iban_structure' => 'HU[0-9]{2}[0-9]{3}[0-9]{4}[0-9]{1}[0-9]{15}[0-9]{1}',
    'is_sepa' => 1,
    'pattern' => 'HU2!n3!n4!n1!n15!n1!n'
  },
  'IE' => {
    'country' => 'Ireland',
    'iban_length' => '22',
    'iban_structure' => 'IE[0-9]{2}[A-Z]{4}[0-9]{6}[0-9]{8}',
    'is_sepa' => 1,
    'pattern' => 'IE2!n4!a6!n8!n'
  },
  'IL' => {
    'country' => 'Israel',
    'iban_length' => '23',
    'iban_structure' => 'IL[0-9]{2}[0-9]{3}[0-9]{3}[0-9]{13}',
    'is_sepa' => 0,
    'pattern' => 'IL2!n3!n3!n13!n'
  },
  'IQ' => {
    'country' => 'Iraq',
    'iban_length' => '23',
    'iban_structure' => 'IQ[0-9]{2}[A-Z]{4}[0-9]{3}[0-9]{12}',
    'is_sepa' => 0,
    'pattern' => 'IQ2!n4!a3!n12!n'
  },
  'IS' => {
    'country' => 'Iceland',
    'iban_length' => '26',
    'iban_structure' => 'IS[0-9]{2}[0-9]{4}[0-9]{2}[0-9]{6}[0-9]{10}',
    'is_sepa' => 0,
    'pattern' => 'IS2!n4!n2!n6!n10!n'
  },
  'IT' => {
    'country' => 'Italy',
    'iban_length' => '27',
    'iban_structure' => 'IT[0-9]{2}[A-Z]{1}[0-9]{5}[0-9]{5}[A-Za-z0-9]{12}',
    'is_sepa' => 1,
    'pattern' => 'IT2!n1!a5!n5!n12!c'
  },
  'JO' => {
    'country' => 'Jordan',
    'iban_length' => '30',
    'iban_structure' => 'JO[0-9]{2}[A-Z]{4}[0-9]{4}[A-Za-z0-9]{18}',
    'is_sepa' => 0,
    'pattern' => 'JO2!n4!a4!n18!c'
  },
  'KW' => {
    'country' => 'Kuwait',
    'iban_length' => '30',
    'iban_structure' => 'KW[0-9]{2}[A-Z]{4}[A-Za-z0-9]{22}',
    'is_sepa' => 0,
    'pattern' => 'KW2!n4!a22!c'
  },
  'KZ' => {
    'country' => 'Kazakhstan',
    'iban_length' => '20',
    'iban_structure' => 'KZ[0-9]{2}[0-9]{3}[A-Za-z0-9]{13}',
    'is_sepa' => 0,
    'pattern' => 'KZ2!n3!n13!c'
  },
  'LB' => {
    'country' => 'Lebanon',
    'iban_length' => '28',
    'iban_structure' => 'LB[0-9]{2}[0-9]{4}[A-Za-z0-9]{20}',
    'is_sepa' => 0,
    'pattern' => 'LB2!n4!n20!c'
  },
  'LC' => {
    'country' => 'Saint Lucia',
    'iban_length' => '32',
    'iban_structure' => 'LC[0-9]{2}[A-Z]{4}[A-Za-z0-9]{24}',
    'is_sepa' => 0,
    'pattern' => 'LC2!n4!a24!c'
  },
  'LI' => {
    'country' => 'Liechtenstein',
    'iban_length' => '21',
    'iban_structure' => 'LI[0-9]{2}[0-9]{5}[A-Za-z0-9]{12}',
    'is_sepa' => 1,
    'pattern' => 'LI2!n5!n12!c'
  },
  'LT' => {
    'country' => 'Lithuania',
    'iban_length' => '20',
    'iban_structure' => 'LT[0-9]{2}[0-9]{5}[0-9]{11}',
    'is_sepa' => 1,
    'pattern' => 'LT2!n5!n11!n'
  },
  'LU' => {
    'country' => 'Luxembourg',
    'iban_length' => '20',
    'iban_structure' => 'LU[0-9]{2}[0-9]{3}[A-Za-z0-9]{13}',
    'is_sepa' => 1,
    'pattern' => 'LU2!n3!n13!c'
  },
  'LV' => {
    'country' => 'Latvia',
    'iban_length' => '21',
    'iban_structure' => 'LV[0-9]{2}[A-Z]{4}[A-Za-z0-9]{13}',
    'is_sepa' => 1,
    'pattern' => 'LV2!n4!a13!c'
  },
  'LY' => {
    'country' => 'Libya',
    'iban_length' => '25',
    'iban_structure' => 'LY[0-9]{2}[0-9]{3}[0-9]{3}[0-9]{15}',
    'is_sepa' => 0,
    'pattern' => 'LY2!n3!n3!n15!n'
  },
  'MC' => {
    'country' => 'Monaco',
    'iban_length' => '27',
    'iban_structure' => 'MC[0-9]{2}[0-9]{5}[0-9]{5}[A-Za-z0-9]{11}[0-9]{2}',
    'is_sepa' => 1,
    'pattern' => 'MC2!n5!n5!n11!c2!n'
  },
  'MD' => {
    'country' => 'Moldova',
    'iban_length' => '24',
    'iban_structure' => 'MD[0-9]{2}[A-Za-z0-9]{2}[A-Za-z0-9]{18}',
    'is_sepa' => 0,
    'pattern' => 'MD2!n2!c18!c'
  },
  'ME' => {
    'country' => 'Montenegro',
    'iban_length' => '22',
    'iban_structure' => 'ME[0-9]{2}[0-9]{3}[0-9]{13}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'ME2!n3!n13!n2!n'
  },
  'MK' => {
    'country' => 'Macedonia',
    'iban_length' => '19',
    'iban_structure' => 'MK[0-9]{2}[0-9]{3}[A-Za-z0-9]{10}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'MK2!n3!n10!c2!n'
  },
  'MN' => {
    'country' => 'Mongolia',
    'iban_length' => '20',
    'iban_structure' => 'MN[0-9]{2}[0-9]{4}[0-9]{12}',
    'is_sepa' => 0,
    'pattern' => 'MN2!n4!n12!n'
  },
  'MR' => {
    'country' => 'Mauritania',
    'iban_length' => '27',
    'iban_structure' => 'MR[0-9]{2}[0-9]{5}[0-9]{5}[0-9]{11}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'MR2!n5!n5!n11!n2!n'
  },
  'MT' => {
    'country' => 'Malta',
    'iban_length' => '31',
    'iban_structure' => 'MT[0-9]{2}[A-Z]{4}[0-9]{5}[A-Za-z0-9]{18}',
    'is_sepa' => 1,
    'pattern' => 'MT2!n4!a5!n18!c'
  },
  'MU' => {
    'country' => 'Mauritius',
    'iban_length' => '30',
    'iban_structure' => 'MU[0-9]{2}[A-Z]{4}[0-9]{2}[0-9]{2}[0-9]{12}[0-9]{3}[A-Z]{3}',
    'is_sepa' => 0,
    'pattern' => 'MU2!n4!a2!n2!n12!n3!n3!a'
  },
  'NI' => {
    'country' => 'Nicaragua',
    'iban_length' => '28',
    'iban_structure' => 'NI[0-9]{2}[A-Z]{4}[0-9]{20}',
    'is_sepa' => 0,
    'pattern' => 'NI2!n4!a20!n'
  },
  'NL' => {
    'country' => 'Netherlands (The)',
    'iban_length' => '18',
    'iban_structure' => 'NL[0-9]{2}[A-Z]{4}[0-9]{10}',
    'is_sepa' => 1,
    'pattern' => 'NL2!n4!a10!n'
  },
  'NO' => {
    'country' => 'Norway',
    'iban_length' => '15',
    'iban_structure' => 'NO[0-9]{2}[0-9]{4}[0-9]{6}[0-9]{1}',
    'is_sepa' => 1,
    'pattern' => 'NO2!n4!n6!n1!n'
  },
  'PK' => {
    'country' => 'Pakistan',
    'iban_length' => '24',
    'iban_structure' => 'PK[0-9]{2}[A-Z]{4}[A-Za-z0-9]{16}',
    'is_sepa' => 0,
    'pattern' => 'PK2!n4!a16!c'
  },
  'PL' => {
    'country' => 'Poland',
    'iban_length' => '28',
    'iban_structure' => 'PL[0-9]{2}[0-9]{8}[0-9]{16}',
    'is_sepa' => 1,
    'pattern' => 'PL2!n8!n16!n'
  },
  'PS' => {
    'country' => '"Palestine, State of"',
    'iban_length' => '29',
    'iban_structure' => 'PS[0-9]{2}[A-Z]{4}[A-Za-z0-9]{21}',
    'is_sepa' => 0,
    'pattern' => 'PS2!n4!a21!c'
  },
  'PT' => {
    'country' => 'Portugal',
    'iban_length' => '25',
    'iban_structure' => 'PT[0-9]{2}[0-9]{4}[0-9]{4}[0-9]{11}[0-9]{2}',
    'is_sepa' => 1,
    'pattern' => 'PT2!n4!n4!n11!n2!n'
  },
  'QA' => {
    'country' => 'Qatar',
    'iban_length' => '29',
    'iban_structure' => 'QA[0-9]{2}[A-Z]{4}[A-Za-z0-9]{21}',
    'is_sepa' => 0,
    'pattern' => 'QA2!n4!a21!c'
  },
  'RO' => {
    'country' => 'Romania',
    'iban_length' => '24',
    'iban_structure' => 'RO[0-9]{2}[A-Z]{4}[A-Za-z0-9]{16}',
    'is_sepa' => 1,
    'pattern' => 'RO2!n4!a16!c'
  },
  'RS' => {
    'country' => 'Serbia',
    'iban_length' => '22',
    'iban_structure' => 'RS[0-9]{2}[0-9]{3}[0-9]{13}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'RS2!n3!n13!n2!n'
  },
  'RU' => {
    'country' => 'Russia',
    'iban_length' => '33',
    'iban_structure' => 'RU[0-9]{2}[0-9]{9}[0-9]{5}[A-Za-z0-9]{15}',
    'is_sepa' => 0,
    'pattern' => 'RU2!n9!n5!n15!c'
  },
  'SA' => {
    'country' => 'Saudi Arabia',
    'iban_length' => '24',
    'iban_structure' => 'SA[0-9]{2}[0-9]{2}[A-Za-z0-9]{18}',
    'is_sepa' => 0,
    'pattern' => 'SA2!n2!n18!c'
  },
  'SC' => {
    'country' => 'Seychelles',
    'iban_length' => '31',
    'iban_structure' => 'SC[0-9]{2}[A-Z]{4}[0-9]{2}[0-9]{2}[0-9]{16}[A-Z]{3}',
    'is_sepa' => 0,
    'pattern' => 'SC2!n4!a2!n2!n16!n3!a'
  },
  'SD' => {
    'country' => 'Sudan',
    'iban_length' => '18',
    'iban_structure' => 'SD[0-9]{2}[0-9]{2}[0-9]{12}',
    'is_sepa' => 0,
    'pattern' => 'SD2!n2!n12!n'
  },
  'SE' => {
    'country' => 'Sweden',
    'iban_length' => '24',
    'iban_structure' => 'SE[0-9]{2}[0-9]{3}[0-9]{16}[0-9]{1}',
    'is_sepa' => 1,
    'pattern' => 'SE2!n3!n16!n1!n'
  },
  'SI' => {
    'country' => 'Slovenia',
    'iban_length' => '19',
    'iban_structure' => 'SI[0-9]{2}[0-9]{5}[0-9]{8}[0-9]{2}',
    'is_sepa' => 1,
    'pattern' => 'SI2!n5!n8!n2!n'
  },
  'SK' => {
    'country' => 'Slovakia',
    'iban_length' => '24',
    'iban_structure' => 'SK[0-9]{2}[0-9]{4}[0-9]{6}[0-9]{10}',
    'is_sepa' => 1,
    'pattern' => 'SK2!n4!n6!n10!n'
  },
  'SM' => {
    'country' => 'San Marino',
    'iban_length' => '27',
    'iban_structure' => 'SM[0-9]{2}[A-Z]{1}[0-9]{5}[0-9]{5}[A-Za-z0-9]{12}',
    'is_sepa' => 1,
    'pattern' => 'SM2!n1!a5!n5!n12!c'
  },
  'SO' => {
    'country' => 'Somalia',
    'iban_length' => '23',
    'iban_structure' => 'SO[0-9]{2}[0-9]{4}[0-9]{3}[0-9]{12}',
    'is_sepa' => 0,
    'pattern' => 'SO2!n4!n3!n12!n'
  },
  'ST' => {
    'country' => 'Sao Tome and Principe',
    'iban_length' => '25',
    'iban_structure' => 'ST[0-9]{2}[0-9]{4}[0-9]{4}[0-9]{11}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'ST2!n4!n4!n11!n2!n'
  },
  'SV' => {
    'country' => 'El Salvador',
    'iban_length' => '28',
    'iban_structure' => 'SV[0-9]{2}[A-Z]{4}[0-9]{20}',
    'is_sepa' => 0,
    'pattern' => 'SV2!n4!a20!n'
  },
  'TL' => {
    'country' => 'Timor-Leste',
    'iban_length' => '23',
    'iban_structure' => 'TL[0-9]{2}[0-9]{3}[0-9]{14}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'TL2!n3!n14!n2!n'
  },
  'TN' => {
    'country' => 'Tunisia',
    'iban_length' => '24',
    'iban_structure' => 'TN[0-9]{2}[0-9]{2}[0-9]{3}[0-9]{13}[0-9]{2}',
    'is_sepa' => 0,
    'pattern' => 'TN2!n2!n3!n13!n2!n'
  },
  'TR' => {
    'country' => 'Turkey',
    'iban_length' => '26',
    'iban_structure' => 'TR[0-9]{2}[0-9]{5}[0-9]{1}[A-Za-z0-9]{16}',
    'is_sepa' => 0,
    'pattern' => 'TR2!n5!n1!n16!c'
  },
  'UA' => {
    'country' => 'Ukraine',
    'iban_length' => '29',
    'iban_structure' => 'UA[0-9]{2}[0-9]{6}[A-Za-z0-9]{19}',
    'is_sepa' => 0,
    'pattern' => 'UA2!n6!n19!c'
  },
  'VA' => {
    'country' => 'Vatican City State',
    'iban_length' => '22',
    'iban_structure' => 'VA[0-9]{2}[0-9]{3}[0-9]{15}',
    'is_sepa' => 1,
    'pattern' => 'VA2!n3!n15!n'
  },
  'VG' => {
    'country' => 'Virgin Islands',
    'iban_length' => '24',
    'iban_structure' => 'VG[0-9]{2}[A-Z]{4}[0-9]{16}',
    'is_sepa' => 0,
    'pattern' => 'VG2!n4!a16!n'
  }
);

sub iban_db {
    lock_hash(%iban_db);
    return \%iban_db;
}

1;

=head1 NAME

Business::IBAN::Database - Simple database for checking IBANs

=head1 SYNOPSIS

    use Business::IBAN::Database;

    my $iso3166a2 = uc substr $iban, 0, 2;
    if (!exists iban_db->{$iso3166a2}) {
        die "Countrycode '$iso3166a2' not in IBAN.\n";
    }
    if (length($iban) != iban_db->{$iso3166a2}{iban_length}) {
        die "Invalid length for '$iban'.\n";
    }
    if ($iban !~ iban_db->{$iso3166a2}{iban_structure}) {
        die "Invalid pattern for '$iban'.\n";
    }
    if (mod97(numify_iban($iban)) != 1) {
        die "Invalid checksum for '$iban'.\n";
    }

=head1 DESCRIPTION

This module was generated from the F<swift_iban_registry_0.txt> document supplied by
SWIFT version 93 February 2023 (also F<swift_iban_registry_v93.pdf>).

All functions are exported by default.

=head2 iban_db()

Returns a reference to the "database" of known IBAN entities, keyed on the
two letter code for participating countries (See ISO 3166 alpha 2 codes).

=head1 COPYRIGHT

E<copy> MMXXIII - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
