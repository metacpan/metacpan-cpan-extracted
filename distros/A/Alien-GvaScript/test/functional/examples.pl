use strict;
use warnings;

use CGI;
use HTTP::Daemon;
use HTTP::Status;
use URI::Escape;
use JSON;
use Encode qw/decode_utf8/;

my $query;
my @countries = <DATA>;
chomp foreach @countries;

my $port = $ARGV[0] || 8085;

my $consonnes = qr/[bcdfghjklmnpqrstvwxyz]/;

my $daemon = HTTP::Daemon->new(LocalPort => $port) || die;
print "Please contact me at: <URL:", $daemon->url, ">\n";
while (my $client_connection = $daemon->accept) {
  while (my $req = $client_connection->get_request) {
    my $path_info = decode_utf8(substr(uri_unescape($req->url->path), 1));

    print STDERR "REQUEST: $path_info\n";

    $client_connection->force_last_request;

    if ($path_info =~ s[^ac/country/][]) {
      my @countries_list = grep /^$path_info|.*\t$path_info/i, @countries;
      my @choices = map { my ($c, $l) = split /\t/, $_;
                          {value => $l,
                           label => '<tt>['.$c.']</tt>  '.$l,
                           code  => $c, } } @countries_list;

      my $json = to_json(\@choices, {ascii => 1});
      print STDERR "RESPONSE: $json\n";
      
      my $response = HTTP::Response->new(RC_OK);
      $response->header(
        'Content-Type'  => 'text/javascript; charset=ISO-8859-1',
        'Cache-Control' => 'no-cache, must-revalidate, max-age=0',
        'Pragma'        => 'no-cache',
        'Expires'       => '0');
      $response->content($json);
      $client_connection->send_response($response);
    }
    elsif ($path_info =~ s[^g/country/][]) {
      $query = new CGI($req->content);
      
      my $db_index = $query->param('INDEX') ? $query->param('INDEX') - 1 : 0;
      my $step     = $query->param('STEP') || 11;

      my @countries_list = grep /^$path_info|.*\t$path_info/i, @countries;
      my @choices = map {  my ($c, $l) = split /\t/, $_;
                          {value => $l, 
                           code  => $c } } @countries_list;

      my $total       = scalar @choices;
      my $start_index = $db_index;
      my $end_index   = $db_index + $step;
      my @tranche     = splice @choices, $start_index, $step;

      my $resp = {
        liste => \@tranche,
        total => $total,
      };

      my $json = to_json($resp, {ascii => 1});
      
      my $response = HTTP::Response->new(RC_OK);
      $response->header(
        'Content-Type'  => 'application/json; charset=ISO-8859-1',
        'Cache-Control' => 'no-cache, must-revalidate, max-age=0',
        'Pragma'        => 'no-cache',
        'Expires'       => '0');
      $response->content( $json );
      $client_connection->send_response($response);
    }
    elsif ($path_info =~ /^.*\.css$/) {
      print STDERR "CSS $path_info\n";
      my $response = HTTP::Response->new(RC_OK);
      $response->header('Content-Type'  => 'text/css; charset=utf-8');
      $client_connection->send_file("../$path_info");
    } 
    elsif ($path_info =~ /^.*\.(gif|png|jpg|jpeg)$/) {
      print STDERR "IMAGE $path_info\n";
      $client_connection->send_file_response("../$path_info");
    }
    else {
      $client_connection->send_file_response("../../$path_info");
    } 
  }
  $client_connection->close;
  undef($client_connection);
}

__DATA__
AD	Andorra
AE	United Arab Emirates
AF	Afghanistan
AG	Antigua & Barbuda
AI	Anguilla
AL	Albania
AM	Armenia
AN	Netherlands Antilles
AO	Angola
AQ	Antarctica
AR	Argentina
AS	American Samoa
AT	Austria
AU	Australia
AW	Aruba
AZ	Azerbaijan
BA	Bosnia and Herzegovina
BB	Barbados
BD	Bangladesh
BE	Belgium
BF	Burkina Faso
BG	Bulgaria
BH	Bahrain
BI	Burundi
BJ	Benin
BM	Bermuda
BN	Brunei Darussalam
BO	Bolivia
BR	Brazil
BS	Bahama
BT	Bhutan
BU	Burma (no longer exists)
BV	Bouvet Island
BW	Botswana
BY	Belarus
BZ	Belize
CA	Canada
CC	Cocos (Keeling) Islands
CF	Central African Republic
CG	Congo
CH	Switzerland
CI	Côte D'ivoire (Ivory Coast)
CK	Cook Iislands
CL	Chile
CM	Cameroon
CN	China
CO	Colombia
CR	Costa Rica
CS	Czechoslovakia (no longer exists)
CU	Cuba
CV	Cape Verde
CX	Christmas Island
CY	Cyprus
CZ	Czech Republic
DD	German Democratic Republic (no longer exists)
DE	Germany
DJ	Djibouti
DK	Denmark
DM	Dominica
DO	Dominican Republic
DZ	Algeria
EC	Ecuador
EE	Estonia
EG	Egypt
EH	Western Sahara
ER	Eritrea
ES	Spain
ET	Ethiopia
FI	Finland
FJ	Fiji
FK	Falkland Islands (Malvinas)
FM	Micronesia
FO	Faroe Islands
FR	France
FX	France, Metropolitan
GA	Gabon
GB	United Kingdom (Great Britain)
GD	Grenada
GE	Georgia
GF	French Guiana
GH	Ghana
GI	Gibraltar
GL	Greenland
GM	Gambia
GN	Guinea
GP	Guadeloupe
GQ	Equatorial Guinea
GR	Greece
GS	South Georgia and the South Sandwich Islands
GT	Guatemala
GU	Guam
GW	Guinea-Bissau
GY	Guyana
HK	Hong Kong
HM	Heard & McDonald Islands
HN	Honduras
HR	Croatia
HT	Haiti
HU	Hungary
ID	Indonesia
IE	Ireland
IL	Israel
IN	India
IO	British Indian Ocean Territory
IQ	Iraq
IR	Islamic Republic of Iran
IS	Iceland
IT	Italy
JM	Jamaica
JO	Jordan
JP	Japan
KE	Kenya
KG	Kyrgyzstan
KH	Cambodia
KI	Kiribati
KM	Comoros
KN	St. Kitts and Nevis
KP	Korea, Democratic People's Republic of
KR	Korea, Republic of
KW	Kuwait
KY	Cayman Islands
KZ	Kazakhstan
LA	Lao People's Democratic Republic
LB	Lebanon
LC	Saint Lucia
LI	Liechtenstein
LK	Sri Lanka
LR	Liberia
LS	Lesotho
LT	Lithuania
LU	Luxembourg
LV	Latvia
LY	Libyan Arab Jamahiriya
MA	Morocco
MC	Monaco
MD	Moldova, Republic of
MG	Madagascar
MH	Marshall Islands
ML	Mali
MN	Mongolia
MM	Myanmar
MO	Macau
MP	Northern Mariana Islands
MQ	Martinique
MR	Mauritania
MS	Monserrat
MT	Malta
MU	Mauritius
MV	Maldives
MW	Malawi
MX	Mexico
MY	Malaysia
MZ	Mozambique
NA	Namibia
NC	New Caledonia
NE	Niger
NF	Norfolk Island
NG	Nigeria
NI	Nicaragua
NL	Netherlands
NO	Norway
NP	Nepal
NR	Nauru
NT	Neutral Zone (no longer exists)
NU	Niue
NZ	New Zealand
OM	Oman
PA	Panama
PE	Peru
PF	French Polynesia
PG	Papua New Guinea
PH	Philippines
PK	Pakistan
PL	Poland
PM	St. Pierre & Miquelon
PN	Pitcairn
PR	Puerto Rico
PT	Portugal
PW	Palau
PY	Paraguay
QA	Qatar
RE	Réunion
RO	Romania
RU	Russian Federation
RW	Rwanda
SA	Saudi Arabia
SB	Solomon Islands
SC	Seychelles
SD	Sudan
SE	Sweden
SG	Singapore
SH	St. Helena
SI	Slovenia
SJ	Svalbard & Jan Mayen Islands
SK	Slovakia
SL	Sierra Leone
SM	San Marino
SN	Senegal
SO	Somalia
SR	Suriname
ST	Sao Tome & Principe
SU	Union of Soviet Socialist Republics (no longer exists)
SV	El Salvador
SY	Syrian Arab Republic
SZ	Swaziland
TC	Turks & Caicos Islands
TD	Chad
TF	French Southern Territories
TG	Togo
TH	Thailand
TJ	Tajikistan
TK	Tokelau
TM	Turkmenistan
TN	Tunisia
TO	Tonga
TP	East Timor
TR	Turkey
TT	Trinidad & Tobago
TV	Tuvalu
TW	Taiwan, Province of China
TZ	Tanzania, United Republic of
UA	Ukraine
UG	Uganda
UM	United States Minor Outlying Islands
US	United States of America
UY	Uruguay
UZ	Uzbekistan
VA	Vatican City State (Holy See)
VC	St. Vincent & the Grenadines
VE	Venezuela
VG	British Virgin Islands
VI	United States Virgin Islands
VN	Viet Nam
VU	Vanuatu
WF	Wallis & Futuna Islands
WS	Samoa
YD	Democratic Yemen (no longer exists)
YE	Yemen
YT	Mayotte
YU	Yugoslavia
ZA	South Africa
ZM	Zambia
ZR	Zaire
ZW	Zimbabwe
ZZ	Unknown or unspecified country
