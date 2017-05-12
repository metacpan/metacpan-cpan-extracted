# Country::Codes.pm
# Countries to be used for decoding to the full name of a country.
# Jason C. Rochon
# 01/29/2014

package Country::Codes;
use strict;
use warnings;

our (@ISA, @EXPORT, $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA = qw(Exporter);

@EXPORT = qw(country);

sub country
{
    my $ans = uc shift;
    
    our %codes = ("US" => "United States",
		  "AF" => "Afghanistan",
		  "AL" => "Albania",
		  "DZ" => "Algeria",
		  "AS" => "American Samoa",
		  "AD" => "Andorra",
		  "AO" => "Angola",
		  "AI" => "Anguilla",
		  "AQ" => "Antarctica",
		  "AG" => "Antigua and Barbuda",
		  "AR" => "Argentina",
		  "AM" => "Armenia",
		  "AW" => "Aruba",
		  "AU" => "Australia",
		  "AT" => "Austria",
		  "AZ" => "Azerbaijan",
		  "BS" => "Bahamas",
		  "BH" => "Bahrain",
		  "BD" => "Bangladesh",
		  "BB" => "Barbados",
		  "BY" => "Belarus",
		  "BE" => "Belgium",
		  "BZ" => "Belize",
		  "BJ" => "Benin",
		  "BM" => "Bermuda",
		  "BT" => "Bhutan",
		  "BO" => "Bolivia",
		  "BA" => "Bosnia and Herzegovina", 
		  "BW" => "Botswana", 
		  "BV" => "Bouvet Island",       
		  "BR" => "Brazil",   
		  "IO" => "British Indian Ocean Territory",
		  "BN" => "Brunei Darussalam",   
		  "BG" => "Bulgaria", 
		  "BF" => "Burkina Faso",        
		  "BI" => "Burundi",  
		  "KH" => "Cambodia", 
		  "CM" => "Cameroon", 
		  "CA" => "Canada",
		  "CV" => "Cape Verde",          
		  "KY" => "Cayman Islands",      
		  "CF" => "Central African Republic", 
		  "TD" => "Chad",     
		  "CL" => "Chile",    
		  "CN" => "China",    
		  "CX" => "Christmas Island",    
		  "CC" => "Cocos (Keeling) Islands",
		  "CO" => "Colombia", 
		  "KM" => "Comoros",  
		  "CD" => "Congo, the Democratic Republic of the",         
		  "CG" => "Congo",    
		  "CK" => "Cook Islands",        
		  "CR" => "Costa Rica",          
		  "CI" => "Cote d'Ivoire",       
		  "HR" => "Croatia",  
		  "CU" => "Cuba",     
		  "CY" => "Cyprus",   
		  "CZ" => "Czech Republic",      
		  "DK" => "Denmark",  
		  "DJ" => "Djibouti", 
		  "DM" => "Dominica", 
		  "DO" => "Dominican Republic",  
		  "EC" => "Ecuador",  
		  "EG" => "Egypt",    
		  "SV" => "El Salvador",         
		  "GQ" => "Equatorial Guinea",   
		  "ER" => "Eritrea",  
		  "EE" => "Estonia",  
		  "ET" => "Ethiopia", 
		  "FK" => "Falkland Islands (Malvinas)",
		  "FO" => "Faroe Islands",       
		  "FJ" => "Fiji",     
		  "FI" => "Finland",  
		  "FR" => "France",   
		  "GF" => "French Guiana",       
		  "PF" => "French Polynesia",    
		  "TF" => "French Southern Territories",
		  "GA" => "Gabon",    
		  "GM" => "Gambia",   
		  "GE" => "Georgia",  
		  "DE" => "Germany",  
		  "GH" => "Ghana",    
		  "GI" => "Gibraltar",
		  "GR" => "Greece",   
		  "GL" => "Greenland",
		  "GD" => "Grenada",  
		  "GP" => "Guadeloupe",          
		  "GU" => "Guam",     
		  "GT" => "Guatemala",
		  "GG" => "Guernsey", 
		  "GW" => "Guinea-Bissau",       
		  "GN" => "Guinea",   
		  "GY" => "Guyana",   
		  "HT" => "Haiti",    
		  "HM" => "Heard Island and McDonald Islands", 
		  "VA" => "Holy See (Vatican City State)",
		  "HN" => "Honduras", 
		  "HK" => "Hong Kong",
		  "HU" => "Hungary",  
		  "IS" => "Iceland",  
		  "IN" => "India",    
		  "ID" => "Indonesia",
		  "IR" => "Iran, Islamic Republic of",
		  "IQ" => "Iraq",     
		  "IE" => "Ireland",  
		  "IM" => "Isle of Man",         
		  "IL" => "Israel",   
		  "IT" => "Italy",    
		  "JM" => "Jamaica",  
		  "JC" => "Jason C. Rochon",
		  "JP" => "Japan",    
		  "JE" => "Jersey",   
		  "JO" => "Jordan",   
		  "KZ" => "Kazakhstan",          
		  "KE" => "Kenya",    
		  "KI" => "Kiribati", 
		  "KP" => "Korea, Democratic People's Republic of",        
		  "KR" => "Korea, Republic of",  
		  "KW" => "Kuwait",   
		  "KG" => "Kyrgyzstan",          
		  "LA" => "Lao People's Democratic Republic",
		  "LV" => "Latvia",   
		  "LB" => "Lebanon",  
		  "LS" => "Lesotho",  
		  "LR" => "Liberia",  
		  "LY" => "Libyan Arab Jamahiriya", 
		  "LI" => "Liechtenstein",
		  "LT" => "Lithuania",
		  "LU" => "Luxembourg",          
		  "MO" => "Macao",    
		  "MK" => "Macedonia, the former Yugoslav Republic of",    
		  "MG" => "Madagascar",          
		  "MW" => "Malawi",   
		  "MY" => "Malaysia", 
		  "MV" => "Maldives", 
		  "ML" => "Mali",     
		  "MT" => "Malta",    
		  "MH" => "Marshall Islands",    
		  "MQ" => "Martinique",          
		  "MR" => "Mauritania",          
		  "MU" => "Mauritius",
		  "YT" => "Mayotte",  
		  "MX" => "Mexico",   
		  "FM" => "Micronesia, Federated States of",
		  "MD" => "Moldova, Republic of",
		  "MC" => "Monaco",   
		  "MN" => "Mongolia", 
		  "ME" => "Montenegro",          
		  "MS" => "Montserrat",          
		  "MA" => "Morocco",  
		  "MZ" => "Mozambique",          
		  "MM" => "Myanmar",  
		  "NA" => "Namibia",  
		  "NR" => "Nauru",    
		  "NP" => "Nepal",    
		  "AN" => "Netherlands Antilles",
		  "NL" => "Netherlands",         
		  "NC" => "New Caledonia",       
		  "NZ" => "New Zealand",         
		  "NI" => "Nicaragua",
		  "NE" => "Niger",    
		  "NG" => "Nigeria",  
		  "NU" => "Niue",     
		  "NF" => "Norfolk Island",      
		  "MP" => "Northern Mariana Islands", 
		  "NO" => "Norway",   
		  "OM" => "Oman",     
		  "PK" => "Pakistan", 
		  "PW" => "Palau",    
		  "PS" => "Palestinian Territory, Occupied",
		  "PA" => "Panama",   
		  "PG" => "Papua New Guinea",    
		  "PY" => "Paraguay", 
		  "PE" => "Peru",     
		  "PH" => "Philippines",         
		  "PN" => "Pitcairn", 
		  "PL" => "Poland",   
		  "PT" => "Portugal", 
		  "PR" => "Puerto Rico",         
		  "QA" => "Qatar",    
		  "RE" => "Reunion",  
		  "RO" => "Romania",  
		  "RU" => "Russian Federation",  
		  "RW" => "Rwanda",   
		  "BL" => "Saint Barthelemy",    
		  "SH" => "Saint Helena",        
		  "KN" => "Saint Kitts and Nevis",  
		  "LC" => "Saint Lucia",         
		  "MF" => "Saint Martin (French part)",
		  "PM" => "Saint Pierre and Miquelon",
		  "VC" => "Saint Vincent and the Grenadines",
		  "WS" => "Samoa",    
		  "SM" => "San Marino",          
		  "ST" => "Sao Tome and Principe",  
		  "SA" => "Saudi Arabia",        
		  "SN" => "Senegal",  
		  "RS" => "Serbia",   
		  "SC" => "Seychelles",          
		  "SL" => "Sierra Leone",        
		  "SG" => "Singapore",
		  "SK" => "Slovakia", 
		  "SI" => "Slovenia", 
		  "SB" => "Solomon Islands",     
		  "SO" => "Somalia",  
		  "ZA" => "South Africa",        
		  "GS" => "South Georgia and the South Sandwich Islands",  
		  "ES" => "Spain",    
		  "LK" => "Sri Lanka",
		  "SD" => "Sudan",    
		  "SR" => "Suriname", 
		  "SJ" => "Svalbard and Jan Mayen", 
		  "SZ" => "Swaziland",
		  "SE" => "Sweden",   
		  "CH" => "Switzerland",         
		  "SY" => "Syrian Arab Republic",
		  "TW" => "Taiwan, Province of China",
		  "TJ" => "Tajikistan",          
		  "TZ" => "Tanzania, United Republic of",
		  "TH" => "Thailand", 
		  "TL" => "Timor-Leste",         
		  "TG" => "Togo",     
		  "TK" => "Tokelau",  
		  "TO" => "Tonga",    
		  "TT" => "Trinidad and Tobago", 
		  "TN" => "Tunisia",  
		  "TR" => "Turkey",   
		  "TM" => "Turkmenistan",        
		  "TC" => "Turks and Caicos Islands", 
		  "TV" => "Tuvalu",   
		  "UG" => "Uganda",   
		  "UA" => "Ukraine",   
		  "AE" => "United Arab Emirates",
		  "GB" => "United Kingdom",      
		  "UM" => "United States Minor Outlying Islands",          
		  "US" => "United States",       
		  "UY" => "Uruguay",  
		  "UZ" => "Uzbekistan",          
		  "VU" => "Vanuatu",  
		  "VE" => "Venezuela",
		  "VN" => "Viet Nam", 
		  "VG" => "Virgin Islands, British",
		  "VI" => "Virgin Islands, U.S.",
		  "WF" => "Wallis and Futuna",   
		  "EH" => "Western Sahara",      
		  "YE" => "Yemen",    
		  "ZM" => "Zambia",   
		  "ZW" => "Zimbabwe"
    );
    
    return $codes{$ans};
}

1;

__END__

=head1 NAME

Country::Codes - Perl extension for converting from a two-letter (ISO 3166-1 alpha-2) to the Country's full name.

=head1 SYNOPSIS

  use Country::Codes;
  
  $country_code = country($code);

=head1 DESCRIPTION

Country::Codes, is used converting from a two-letter (ISO 3166-1 alpha-2) to the Country's full name.

=head2 EXAMPLE USAGE

  use Country::Codes;

  print "What is the Country Code? ";

  my $code = <STDIN>;
  chop($code);

  unless (country($code)) { print "This country does not exist yet :-("; exit;}
  print "\nCountry Code is " . country($code) . " !";

=head2 EXPORT

@EXPORT = qw(country);

=head1 SEE ALSO

Country codes are short alphabetic or numeric geographical codes (geocodes) developed to represent countries and 
dependent areas, for use in data processing and communications. Several different systems have been developed to 
do this. The best known of these is ISO 3166-1.

http://en.wikipedia.org/wiki/Country_code

=head1 AUTHOR

Jason C. Rochon, E<lt>jcrochon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jason C. Rochon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
