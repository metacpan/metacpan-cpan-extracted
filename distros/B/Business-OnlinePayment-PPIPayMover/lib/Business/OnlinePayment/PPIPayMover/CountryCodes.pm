package Business::OnlinePayment::PPIPayMover::CountryCodes;

use strict;
use vars qw(@ISA @EXPORT %countryHash);
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(getCountry
  getNumericCountryCode
  isValidCountryCode
getCCodeFromCName);

# Two Character Country Codes */
%countryHash = ("DZ" => "ALGERIA:012",
  "BJ" => "BENIN:204",
  "BW" => "BOTSWANA:072",
  "BF" => "BURKINA FASO:854",
  "BI" => "BURUNDI:108",
  "CM" => "CAMEROON:120",
  "CV" => "CAPE VERDE:132",
  "CF" => "CENTRAL AFRICAN REPUBLIC:140",
  "TD" => "CHAD:148",
  "KM" => "COMOROS:174",
  "CG" => "CONGO:178",
  "CI" => "COTE DIVOIRE:384",
  "DJ" => "DJIBOUTI:262",
  "EG" => "EGYPT:818",
  "GQ" => "EQUATORIAL GUINEA:226",
  "ER" => "ERITREA:232",
  "ET" => "ETHIOPIA:231",
  "GA" => "GABON:266",
  "GM" => "GAMBIA:270",
  "GH" => "GHANA:288",
  "GN" => "GUINEA:324",
  "GW" => "GUINEA BISSAU:624",
  "KE" => "KENYA:404",
  "LS" => "LESOTHO:426",
  "LR" => "LIBERIA:430",
  "MG" => "MADAGASCAR:450",
  "MW" => "MALAWI:454",
  "ML" => "MALI:466",
  "MR" => "MAURITANIA:478",
  "YT" => "MAYOTTE:175",
  "MA" => "MOROCCO:504",
  "MZ" => "MOZAMBIQUE:508",
  "NA" => "NAMIBIA:516",
  "NE" => "NIGER:562",
  "NG" => "NIGERIA:566",
  "RE" => "REUNION:638",
  "ST" => "SAO TOME AND PRINCIPE:678",
  "SN" => "SENEGAL:686",
  "SL" => "SIERRA LEONE:694",
  "SO" => "SOMALIA:706",
  "ZA" => "SOUTH AFRICA:710",
  "SH" => "ST HELENA:654",
  "SD" => "SUDAN:736",
  "SZ" => "SWAZILAND:748",
  "TZ" => "TANZANIA:834",
  "TG" => "TOGO:768",
  "TN" => "TUNISIA:788",
  "UG" => "UGANDA:800",
  "EH" => "WESTERN SAHARA:732",
  "ZR" => "ZAIRE:180",
  "ZM" => "ZAMBIA:894",
  "ZW" => "ZIMBABWE:716",
  
# Antartica
  "AQ" => "ANTARCTICA:010",
  
# Asia
  "AF" => "AFGHANISTAN:004",
  "BD" => "BANGLADESH:050",
  "BT" => "BHUTAN:064",
  "BN" => "BRUNEI:096",
  "KH" => "CAMBODIA:116",
  "CN" => "CHINA:156",
  "HK" => "HONG KONG:344",
  "IN" => "INDIA:356",
  "ID" => "INDONESIA:360",
  "JP" => "JAPAN:392",
  "KZ" => "KAZAKHSTAN:398",
  "KG" => "KYRGYZSTAN:417",
  "LA" => "LAOS:418",
  "MO" => "MACAU:446",
  "MY" => "MALAYSIA:458",
  "MV" => "MALDIVES:462",
  "MN" => "MONGOLIA:496",
  "NP" => "NEPAL:524",
  "PK" => "PAKISTAN:586",
  "PH" => "PHILIPPINES:608",
  "KR" => "REPUBLIC OF KOREA:410",
  "RU" => "RUSSIA:643",
  "SC" => "SEYCHELLES:690",
  "SG" => "SINGAPORE:702",
  "LK" => "SRI LANKA:144",
  "TW" => "TAIWAN:158",
  "TJ" => "TAJIKISTAN:762",
  "TH" => "THAILAND:764",
  "TM" => "TURKMENISTAN:795",
  "UZ" => "UZBEKISTAN:860",
  "VN" => "VIETNAM:704",
  
# Australia
  "AS" => "AMERICAN SAMOA:016",
  "AU" => "AUSTRALIA:036",
  "FM" => "FEDERATED STATES OF MICRONESIA:583",
  "FJ" => "FIJI:242",
  "PF" => "FRENCH POLYNESIA:258",
  "GU" => "GUAM:316",
  "KI" => "KIRIBATI:296",
  "MH" => "MARSHALL ISLANDS:584",
  "NR" => "NAURU:520",
  "NC" => "NEW CALEDONIA:540",
  "NZ" => "NEW ZEALAND:554",
  "MP" => "NORTHERN MARIANA ISLANDS:580",
  "PW" => "PALAU:585",
  "PG" => "PAPUA NEW GUINEA:598",
  "PN" => "PITCAIRN:612",
  "SB" => "SOLOMON ISLANDS:090",
  "TO" => "TONGA:776",
  "TV" => "TUVALU:798",
  "VU" => "VANUATU:548",
  
# Caribbean
  "AI" => "ANGUILLA:660",
  "AG" => "ANTIGUA AND BARBUDA:028",
  "AW" => "ARUBA:533",
  "BS" => "BAHAMAS:044",
  "BB" => "BARBADOS:052",
  "BM" => "BERMUDA:060",
  "KY" => "CAYMAN ISLANDS:136",
  "DM" => "DOMINICA:212",
  "DO" => "DOMINICAN REPUBLIC:214",
  "GD" => "GRENADA:308",
  "GP" => "GUADELOUPE:312",
  "HT" => "HAITI:332",
  "JM" => "JAMAICA:388",
  "MQ" => "MARTINIQUE:474",
  "AN" => "NETHERLANDS ANTILLES:530",
  "PR" => "PUERTO RICO:630",
  "KN" => "ST KITTS AND NEVIS:659",
  "LC" => "ST LUCIA:662",
  "VC" => "ST VINCENT AND THE GRENADINES:670",
  "TT" => "TRINIDAD AND TOBAGO:780",
  "TC" => "TURKS AND CAICOS ISLANDS:796",
  "VG" => "VIRGIN ISLANDS BRITISH:092",
  "VI" => "VIRGIN ISLANDS USA:850",
  
# Central America
  "BZ" => "BELIZE:084",
  "CR" => "COSTA RICA:188",
  "SV" => "EL SALVADOR:222",
  "GT" => "GUATEMALA:320",
  "HN" => "HONDURAS:340",
  "NI" => "NICARAGUA:558",
  "PA" => "PANAMA:591",
  
#  Europe
  "AL" => "ALBANIA:008",
  "AD" => "ANDORRA:020",
  "AM" => "ARMENIA:051",
  "AT" => "AUSTRIA:040",
  "AZ" => "AZERBAIJAN:031",
  "BY" => "BELARUS:112",
  "BE" => "BELGIUM:056",
  "BG" => "BULGARIA:100",
  "HR" => "CROATIA:191",
  "CY" => "CYPRUS:196",
  "CZ" => "CZECH REPUBLIC:203",
  "DK" => "DENMARK:208",
  "EE" => "ESTONIA:233",
  "FO" => "FAROE ISLANDS:234",
  "FI" => "FINLAND:246",
  "FR" => "FRANCE:250",
  "GE" => "GEORGIA:268",
  "DE" => "GERMANY:276",
  "GI" => "GIBRALTAR:292",
  "GR" => "GREECE:300",
  "GL" => "GREENLAND:304",
  "HU" => "HUNGARY:348",
  "IS" => "ICELAND:352",
  "IE" => "IRELAND:372",
  "IT" => "ITALY:380",
  "LV" => "LATVIA:428",
  "LI" => "LIECHTENSTEIN:438",
  "LT" => "LITHUANIA:440",
  "LU" => "LUXEMBOURG:442",
  "MT" => "MALTA:470",
  "FX" => "METROPOLITAN FRANCE:249",
  "MD" => "MOLDOVA:498",
  "NL" => "NETHERLANDS:528",
  "NO" => "NORWAY:578",
  "PL" => "POLAND:616",
  "PT" => "PORTUGAL:620",
  "RO" => "ROMANIA:642",
  "SK" => "SLOVAKIA:703",
  "SI" => "SLOVENIA:705",
  "ES" => "SPAIN:724",
  "SJ" => "SVALBARD AND JAN MAYEN ISLANDS:744",
  "SE" => "SWEDEN:752",
  "CH" => "SWITZERLAND:756",
  "MK" => "REPUBLIC OF MACEDONIA:807",
  "TR" => "TURKEY:792",
  "UA" => "UKRAINE:804",
  "GB" => "UNITED KINGDOM:826",
  "VA" => "VATICAN CITY:336",
  "YU" => "YUGOSLAVIA:891",
  
# Middle East
  "IL" => "ISRAEL:376",
  "JO" => "JORDAN:400",
  "KW" => "KUWAIT:414",
  "LB" => "LEBANON:422",
  "OM" => "OMAN:512",
  "QA" => "QATAR:634",
  "SA" => "SAUDI ARABIA:682",
  "SY" => "SYRIA:760",
  "AE" => "UNITED ARAB EMIRATES:784",
  "YE" => "YEMEN:887",
  
# North America
  "CA" => "CANADA:124",
  "MX" => "MEXICO:484",
  "US" => "UNITED STATES:840",
  
# South America
  "AR" => "ARGENTINA:032",
  "BO" => "BOLIVIA:068",
  "BR" => "BRAZIL:076",
  "CL" => "CHILE:152",
  "CO" => "COLOMBIA:170",
  "EC" => "EQUADOR:218",
  "FK" => "FALKLAND ISLANDS:238",
  "GF" => "FRENCH GUIANA:254",
  "GY" => "GUYANA:328",
  "PY" => "PARAGUAY:600",
  "PE" => "PERU:604",
  "SR" => "SURINAME:740",
  "UY" => "URUGUAY:858",
  "VE" => "VENEZUELA:862",
  
# Others
  "BH" => "BAHRAIN:048",
  "BV" => "BOUVET ISLANDS:074",
  "IO" => "BRITISH INDIAN OCEAN TERRITORY:086",
  "CX" => "CHRISTMAS ISLANDS:162",
  "CC" => "COCOS KEELING ISLANDS:166",
  "CK" => "COOK ISLAND:184",
  "TP" => "EAST TIMOR:626",
  "TF" => "FRENCH SOUTHERN TERRITORIES:260",
  "HM" => "HEARD AND MCDONALD ISLANDS:334",
  "MU" => "MAURITIUS:480",
  "MC" => "MONACO:492",
  "MS" => "MONTSERRAT:500",
  "MM" => "MYANMAR:104",
  "NU" => "NIUE:570",
  "NF" => "NORFOLK ISLAND:574",
  "WS" => "SAMOA:882",
  "SM" => "SAN MARINO:674",
  "PM" => "ST PIERRE AND MIQUELON:666",
  "TK" => "TOKELAU:772",
  "UM" => "UNITED STATES MINOR OUTLYING ISLANDS:581",
  "WF" => "WALLIS AND FUTUNA ISLANDS:876",
  
  "AO" => "ANGOLA:024",
  "BA" => "BOSNIA AND HERZEGOWINA:070",
  "CU" => "CUBA:192",
  "IR" => "ISLAMIC REPUBLIC OF IRAN:364",
  "IQ" => "IRAQ:368",
  "KP" => "DEMOCRATIC PEOPLES REPUBLIC OF KOREA:408",
  "LY" => "LIBYAN ARAB JAMAHIRIYA:434",
  "RW" => "RWANDA:646",
  "GS" => "SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS:39",
  "CD" => "DEMOCRATIC REPUBLIC OF THE CONGO:180",
  "PS" => "OCCUPIED PALESTINIAN TERRITORY:275"
);


sub getCountry {
  my $countryCode = shift; # give country code as an arguement to get country name
  if(exists $CountryCodes::countryHash{$countryCode}){
    my $countryName;
    my $countryNumber;
    ($countryName, $countryNumber) = split(/:/, $CountryCodes::countryHash{$countryCode});
    return $countryName;
  }
  else { return undef }
}

sub getNumericCountryCode {
  my $countryCode = shift; # give country code as an arguement to get numeric country code
  if(exists $CountryCodes::countryHash{$countryCode}) {
    my $countryName;
    my $countryNumber;
    ($countryName, $countryNumber) = split(/:/, $CountryCodes::countryHash{$countryCode});
    return $countryNumber;
  }
  else {return undef}
}


sub isValidCountryCode {
  my $countryCode = shift;
  return (exists $CountryCodes::countryHash{$countryCode});
}

sub getCCodeFromCName {
  my $country = shift; # give country name as an arguement to get country code
  $country = uc($country);
  my $key;
  my $countryName;
  my $countryNumber;
  foreach $key (keys(%CountryCodes::countryHash)){
    ($countryName, $countryNumber) = split(/:/, $CountryCodes::countryHash{$key});
    if ($country  eq  $countryName) { return $key}
  }
  return undef;
}
