package Amethyst::Brain::Infobot::Module::Exchange;

use strict;
use vars qw(@ISA
		%CODE2CODE %TLD2CODE %CURR2CODE %COUNTRY2CODE
		%CODE2CURR
				$REFERER $CONVERTER);
use Data::Dumper;
use POE;
use POE::Component::Client::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;
use LWP::UserAgent;	# For init
use Amethyst::Message;
use Amethyst::Brain::Infobot;
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(
					Name		=> 'Exchange',
					Regex		=> qr/^(?:ex)?change\s+(\d+)\s+(\w+)\s+(?:into|to|for)\s+(\w+)/x,
					Usage		=> '(ex)?change 100 USD for DEM',
					Description	=> "Convert currencies",
					@_
						);

	return bless $self, $class;
}

sub init {
	my $self = shift;

	eval { spawn POE::Component::Client::UserAgent; };
	if ($@) {
		die $@ unless $@ =~ /^alias is in use by another session/;
	}

	$REFERER = 'http://www.xe.net/ucc/full.shtml';
	$CONVERTER ='http://www.xe.net/ucc/convert.cgi';

	my $ua = new LWP::UserAgent;
	my $uri = new URI($REFERER);
	my $request = new HTTP::Request(GET => $uri);

	print STDERR "Requesting $uri\n";

	my $response = $ua->request($request);

	unless ($response->is_success) {
		print STDERR $response->error_as_HTML;
		die "Failed to contact currency converter";
	}

	my $html = $response->content;
	$html =~ s|.*<SELECT[^>]*>(.*?)</SELECT.*|$1|s;

	my @data =
			map {
				[ $_ =~ /=\"([^\"]+)\">(.*?)(?:,\s*(.*?))? \(...\)</g ]
			}
			grep /\S/,
			split /\n/, $html;

	%CURR2CODE = map { defined $_->[2]
					? (lc $_->[2] => uc $_->[0])
					: () } @data;
	%COUNTRY2CODE = map { lc $_->[1] => uc $_->[0] } @data;
	%CODE2CODE = map { lc $_->[0] => uc $_->[0] } @data;

	%CODE2CURR = reverse %CURR2CODE;

TLD:
	while (<DATA>) {
		chomp;

		my ($tld, $country) = split /\s+/, $_, 2;
		if (exists $COUNTRY2CODE{lc $country}) {
			$TLD2CODE{lc $tld} = $COUNTRY2CODE{lc $country};
			next TLD;
		}

		($tld, $country) = split /\s+/, $_, 3;
		if (exists $COUNTRY2CODE{lc $country}) {
			$TLD2CODE{lc $tld} = $COUNTRY2CODE{lc $country};
			next TLD;
		}

		# print STDERR "Unable to identify $_\n";
	}
}

sub action {
    my ($self, $message, $number, $from, $to) = @_;

	$from = lc $from;
	$to = lc $to;

	my @all = (keys %CODE2CODE, keys %CURR2CODE, keys %COUNTRY2CODE,
	keys %TLD2CODE);

	print STDERR join(", ", sort @all);

	my $fcode = $CODE2CODE{$from}
				|| $CURR2CODE{$from}
				|| $COUNTRY2CODE{$from}
				|| $TLD2CODE{$from};

	my $tcode = $CODE2CODE{$to}
				|| $CURR2CODE{$to}
				|| $COUNTRY2CODE{$to}
				|| $TLD2CODE{$to};

	unless (defined $fcode) {
		my $reply = $self->reply_to($message, "Unknown currency $from");
		$reply->send;
		return;
	}

	unless (defined $tcode) {
		my $reply = $self->reply_to($message, "Unknown currency $to");
		$reply->send;
		return;
	}

	my %states = map { $_ => "handler_$_" } qw(
					_start response
						);

	print STDERR "Creating child session for exchange\n";

	POE::Session->create(
		package_states	=> [ ref($self) => \%states ],
		args			=> [ $self, $message, $number, $fcode, $tcode ],
			);

	return 1;
}

sub handler_response {
	my ($kernel, $heap, $session, $pbargs) =
					@_[KERNEL, HEAP, SESSION, ARG1];
	my ($request, $response, $entry) = @$pbargs;

	unless ($response->is_success) {
		my $reply = $heap->{Module}->reply_to($heap->{Message},
						"HTTP Request failed");
		$reply->send;
		print STDERR $response->error_as_HTML;
		return;
	}

	my $html = $response->content;

	unless ($html =~ /Live Rates.*\+1><B>([^\n]*)\n(?:.*)\+1><B>([^\n]*)/si)
	{
		my $reply = $heap->{Module}->reply_to($heap->{Message},
						"Failed to parse response");
		$reply->send;
		print STDERR $response->content;
		return;
	}

	my $out = "$1 = $2";
	$out =~ s/<.*?>/ /g;
	$out =~ s/\s+/ /g;

	my $reply = $heap->{Module}->reply_to($heap->{Message}, $out);
	$reply->send;
}

sub handler__start {
	my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
	my ($module, $message, $number, $fcode, $tcode) = @_[ARG0..$#_];

	$heap->{Module} = $module;
	$heap->{Message} = $message;

	my $uri = new URI($CONVERTER);
	$uri->query_form(
			From		=> $fcode,
			To			=> $tcode,
			Amount		=> $number,
				);
	$uri = $uri->canonical;
	my $request = new HTTP::Request(GET => $uri);
	$request->referer($REFERER);

	my $postback = $session->postback('response');

	$kernel->post('useragent', 'request',
					request		=> $request,
					response	=> $postback,
						);
}

1;

__DATA__
AF	AFGHANISTAN
AL	ALBANIA
DZ	ALGERIA
AS	AMERICAN SAMOA
AD	ANDORRA
AO	ANGOLA
AI	ANGUILLA
AQ	ANTARCTICA
AG	ANTIGUA AND BARBUDA
AR	ARGENTINA
AM	ARMENIA
AW	ARUBA
AU	AUSTRALIA
AT	AUSTRIA
AZ	AZERBAIJAN
BS	BAHAMAS
BH	BAHRAIN
BD	BANGLADESH
BB	BARBADOS
BY	BELARUS
BE	BELGIUM
BZ	BELIZE
BJ	BENIN
BM	BERMUDA
BT	BHUTAN
BO	BOLIVIA
BA	BOSNIA AND HERZEGOWINA
BW	BOTSWANA
BV	BOUVET ISLAND
BR	BRAZIL
IO	BRITISH INDIAN OCEAN TERRITORY
BN	BRUNEI DARUSSALAM
BG	BULGARIA
BF	BURKINA FASO
BI	BURUNDI
KH	CAMBODIA
CM	CAMEROON
CA	CANADA
CV	CAPE VERDE
KY	CAYMAN ISLANDS
CF	CENTRAL AFRICAN REPUBLIC
TD	CHAD
CL	CHILE
CN	CHINA
CX	CHRISTMAS ISLAND
CC	COCOS (KEELING) ISLANDS
CO	COLOMBIA
KM	COMOROS
CG	CONGO
CD	CONGO	THE DEMOCRATIC REPUBLIC OF THE
CK	COOK ISLANDS
CR	COSTA RICA
CI	COTE D'IVOIRE
HR	CROATIA (local name: Hrvatska)
CU	CUBA
CY	CYPRUS
CZ	CZECH REPUBLIC
DK	DENMARK
DJ	DJIBOUTI
DM	DOMINICA
DO	DOMINICAN REPUBLIC
TP	EAST TIMOR
EC	ECUADOR
EG	EGYPT
SV	EL SALVADOR
GQ	EQUATORIAL GUINEA
ER	ERITREA
EE	ESTONIA
ET	ETHIOPIA
EU	EURO
FK	FALKLAND ISLANDS (MALVINAS)
FO	FAROE ISLANDS
FJ	FIJI
FI	FINLAND
FR	FRANCE
FX	FRANCE	METROPOLITAN
GF	FRENCH GUIANA
PF	FRENCH POLYNESIA
TF	FRENCH SOUTHERN TERRITORIES
GA	GABON
GM	GAMBIA
GE	GEORGIA
DE	GERMANY
GH	GHANA
GI	GIBRALTAR
GR	GREECE
GL	GREENLAND
GD	GRENADA
GP	GUADELOUPE
GU	GUAM
GT	GUATEMALA
GN	GUINEA
GW	GUINEA-BISSAU
GY	GUYANA
HT	HAITI
HM	HEARD AND MC DONALD ISLANDS
VA	HOLY SEE (VATICAN CITY STATE)
HN	HONDURAS
HK	HONG KONG
HU	HUNGARY
IS	ICELAND
IN	INDIA
ID	INDONESIA
IR	IRAN (ISLAMIC REPUBLIC OF)
IQ	IRAQ
IE	IRELAND
IL	ISRAEL
IT	ITALY
JM	JAMAICA
JP	JAPAN
JO	JORDAN
KZ	KAZAKHSTAN
KE	KENYA
KI	KIRIBATI
KP	KOREA	DEMOCRATIC PEOPLE'S REPUBLIC OF
KR	KOREA	REPUBLIC OF
KW	KUWAIT
KG	KYRGYZSTAN
LA	LAO PEOPLE'S DEMOCRATIC REPUBLIC
LV	LATVIA
LB	LEBANON
LS	LESOTHO
LR	LIBERIA
LY	LIBYAN ARAB JAMAHIRIYA
LI	LIECHTENSTEIN
LT	LITHUANIA
LU	LUXEMBOURG
MO	MACAU
MK	MACEDONIA	THE FORMER YUGOSLAV REPUBLIC OF
MG	MADAGASCAR
MW	MALAWI
MY	MALAYSIA
MV	MALDIVES
ML	MALI
MT	MALTA
MH	MARSHALL ISLANDS
MQ	MARTINIQUE
MR	MAURITANIA
MU	MAURITIUS
YT	MAYOTTE
MX	MEXICO
FM	MICRONESIA	FEDERATED STATES OF
MD	MOLDOVA	REPUBLIC OF
MC	MONACO
MN	MONGOLIA
MS	MONTSERRAT
MA	MOROCCO
MZ	MOZAMBIQUE
MM	MYANMAR
NA	NAMIBIA
NR	NAURU
NP	NEPAL
NL	NETHERLANDS
AN	NETHERLANDS ANTILLES
NC	NEW CALEDONIA
NZ	NEW ZEALAND
NI	NICARAGUA
NE	NIGER
NG	NIGERIA
NU	NIUE
NF	NORFOLK ISLAND
MP	NORTHERN MARIANA ISLANDS
NO	NORWAY
OM	OMAN
PK	PAKISTAN
PW	PALAU
PA	PANAMA
PG	PAPUA NEW GUINEA
PY	PARAGUAY
PE	PERU
PH	PHILIPPINES
PN	PITCAIRN
PL	POLAND
PT	PORTUGAL
PR	PUERTO RICO
QA	QATAR
RE	REUNION
RO	ROMANIA
RU	RUSSIAN FEDERATION
RW	RWANDA
KN	SAINT KITTS AND NEVIS
LC	SAINT LUCIA
VC	SAINT VINCENT AND THE GRENADINES
WS	SAMOA
SM	SAN MARINO
ST	SAO TOME AND PRINCIPE
SA	SAUDI ARABIA
SN	SENEGAL
SC	SEYCHELLES
SL	SIERRA LEONE
SG	SINGAPORE
SK	SLOVAKIA (Slovak Republic)
SI	SLOVENIA
SB	SOLOMON ISLANDS
SO	SOMALIA
ZA	SOUTH AFRICA
GS	SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS
ES	SPAIN
LK	SRI LANKA
SH	ST. HELENA
PM	ST. PIERRE AND MIQUELON
SD	SUDAN
SR	SURINAME
SJ	SVALBARD AND JAN MAYEN ISLANDS
SZ	SWAZILAND
SE	SWEDEN
CH	SWITZERLAND
SY	SYRIAN ARAB REPUBLIC
TW	TAIWAN	PROVINCE OF CHINA
TJ	TAJIKISTAN
TZ	TANZANIA	UNITED REPUBLIC OF
TH	THAILAND
TG	TOGO
TK	TOKELAU
TO	TONGA
TT	TRINIDAD AND TOBAGO
TN	TUNISIA
TR	TURKEY
TM	TURKMENISTAN
TC	TURKS AND CAICOS ISLANDS
TV	TUVALU
UG	UGANDA
UA	UKRAINE
AE	UNITED ARAB EMIRATES
GB	UNITED KINGDOM
UK	UNITED KINGDOM
US	UNITED STATES
UM	UNITED STATES MINOR OUTLYING ISLANDS
UY	URUGUAY
UZ	UZBEKISTAN
VU	VANUATU
VE	VENEZUELA
VN	VIET NAM
VG	VIRGIN ISLANDS (BRITISH)
VI	VIRGIN ISLANDS (U.S.)
WF	WALLIS AND FUTUNA ISLANDS
EH	WESTERN SAHARA
YE	YEMEN
YU	YUGOSLAVIA
ZM	ZAMBIA
ZW	ZIMBABWE
