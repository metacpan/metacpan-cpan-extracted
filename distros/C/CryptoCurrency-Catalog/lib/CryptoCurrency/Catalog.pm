package CryptoCurrency::Catalog;

our $DATE = '2018-01-06'; # DATE
our $VERSION = '20180106'; # VERSION

use 5.010001;
use strict;
use warnings;

my %by_symbol;
my %by_name;
my %by_safename;
my @all_data;

sub new {
    my $class = shift;

    unless (keys %by_symbol) {
        while (defined(my $line = <DATA>)) {
            chomp $line;
            my @ff = split /\t/, $line;
            my ($symbol, $name, $safename) = @ff;
            $by_symbol{$symbol}     = \@ff;
            $by_name{$name}         = \@ff;
            $by_safename{$safename} = \@ff;
            push @all_data, \@ff;
        }
    }

    bless {}, $class;
}

sub by_symbol {
    my ($self, $symbol) = @_;
    $symbol = uc($symbol);
    die "Can't find cryptocurrency with symbol '$symbol'"
        unless $by_symbol{$symbol};
    return {
        symbol=>$symbol,
        name=>$by_symbol{$symbol}[1],
        safename=>$by_symbol{$symbol}[2],
    };
}

sub by_ticker { by_symbol(@_) }

sub by_name {
    my ($self, $name) = @_;
    die "Can't find cryptocurrency with name '$name'"
        unless $by_name{$name};
    return {
        name=>$name,
        symbol=>$by_name{$name}[0],
        safename=>$by_name{$name}[2],
    };
}

sub by_safename {
    my ($self, $safename) = @_;
    $safename = lc($safename);
    die "Can't find cryptocurrency with safename '$safename'"
        unless $by_safename{$safename};
    return {
        safename=>$safename,
        symbol=>$by_safename{$safename}[0],
        name=>$by_safename{$safename}[1],
    };
}

sub by_slug { by_safename(@_) }

sub all_symbols {
    my $self = shift;
    my @res;
    for (@all_data) {
        push @res, $_->[0];
    }
    @res;
}

sub all_data {
    my $self = shift;
    my @res;
    for (@all_data) {
        push @res, {symbol=>$_->[0], name=>$_->[1], safename=>$_->[2]};
    }
    @res;
}

1;
# ABSTRACT: Catalog of cryptocurrencies

=pod

=encoding UTF-8

=head1 NAME

CryptoCurrency::Catalog - Catalog of cryptocurrencies

=head1 VERSION

This document describes version 20180106 of CryptoCurrency::Catalog (from Perl distribution CryptoCurrency-Catalog), released on 2018-01-06.

=head1 SYNOPSIS

 use CryptoCurrency::Catalog;

 my $cat = CryptoCurrency::Catalog->new;

 my $record = $cat->by_symbol("ETH");        # => { symbol => "ETH", name=>"Ethereum", safename=>"ethereum" }
 my $record = $cat->by_ticker("eth");        # alias for by_symbol(), lowercase also works
 my $record = $cat->by_name("Ethereum");     # note: case-sensitive
 my $record = $cat->by_safename("ethereum");
 my $record = $cat->by_slug("Ethereum");     # alias for by_safename(), mixed case also works

 my @symbols = $cat->all_symbols(); # => ("BTC", "ETH", ...)

 my @data = $cat->all_data; # => ({symbol=>"BTC", name=>"Bitcoin", safename=>"bitcoin"}, {...}, ...)

=head1 DESCRIPTION

This class attempts to provide a list/catalog of cryptocurrencies. The main
source for this catalog is the Cryptocurrency Market Capitalizations website
(L<https://coinmarketcap.com/>, or CMC for short). This catalog is updated to
the list on CMC as of Jan 6, 2018 (1384 coins and tokens).

CMC does not provide unique symbols nor unique names, only unique "safenames"
(slugs). Whenever there is a clash, this catalog modifies the clashing symbol
and/or unique name to make symbol and name to be unique again (usually the
coin/token with the smaller market cap "loses" the name).

There is no guarantee that the symbol/name/safename of old/unlisted coins or
tokens will not be reused.

=head1 METHODS

=head2 new

=head2 by_symbol

=head2 by_ticker

Alias for L</"by_symbol">.

=head2 by_name

=head2 by_safename

=head2 by_slug

Alias for L</"by_safename">.

=head2 all_symbols

=head2 all_data

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CryptoCurrency-Catalog>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CryptoCurrency-Catalog>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CryptoCurrency-Catalog>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
BTC	Bitcoin	bitcoin
XRP	Ripple	ripple
ETH	Ethereum	ethereum
BCH	Bitcoin Cash	bitcoin-cash
ADA	Cardano	cardano
TRX	TRON	tron
XEM	NEM	nem
LTC	Litecoin	litecoin
XLM	Stellar	stellar
MIOTA	IOTA	iota
DASH	Dash	dash
EOS	EOS	eos
NEO	NEO	neo
XMR	Monero	monero
QTUM	Qtum	qtum
BTG	Bitcoin Gold	bitcoin-gold
XRB	RaiBlocks	raiblocks
ETC	Ethereum Classic	ethereum-classic
LSK	Lisk	lisk
BCN	Bytecoin	bytecoin-bcn
SC	Siacoin	siacoin
ICX	ICON	icon
XVG	Verge	verge
BCC	BitConnect	bitconnect
BTS	BitShares	bitshares
OMG	OmiseGO	omisego
BNB	Binance Coin	binance-coin
ZEC	Zcash	zcash
SNT	Status	status
ARDR	Ardor	ardor
STRAT	Stratis	stratis
PPT	Populous	populous
USDT	Tether	tether
DOGE	Dogecoin	dogecoin
STEEM	Steem	steem
DGB	DigiByte	digibyte
WAVES	Waves	waves
XP	Experience Points	experience-points
VEN	VeChain	vechain
HSR	Hshare	hshare
DENT	Dent	dent
KMD	Komodo	komodo
KIN	Kin	kin
DRGN	Dragonchain	dragonchain
GNT	Golem	golem-network-tokens
REP	Augur	augur
VERI	Veritaseum	veritaseum
DCR	Decred	decred
NXS	Nexus	nexus
FUN	FunFair	funfair
KCS	KuCoin Shares	kucoin-shares
ETHOS	Ethos	ethos
ETN	Electroneum	electroneum
XDN	DigitalNote	digitalnote
ARK	Ark	ark
SALT	SALT	salt
QASH	QASH	qash
BAT	Basic Attention Token	basic-attention-token
RDD	ReddCoin	reddcoin
PAC	PACcoin	paccoin
FCT	Factom	factom
PIVX	PIVX	pivx
ZRX	0x	0x
BTM	Bytom	bytom
AE	Aeternity	aeternity
POWR	Power Ledger	power-ledger
NXT	Nxt	nxt
REQ	Request Network	request-network
RHOC	RChain	rchain
AION	Aion	aion
GBYTE	Byteball Bytes	byteball
SAN	Santiment Network Token	santiment
POE	Po.et	poet
GNO	Gnosis	gnosis-gno
MAID	MaidSafeCoin	maidsafecoin
WAX	WAX	wax
MONA	MonaCoin	monacoin
ENG	Enigma Project	enigma-project
BTCD	BitcoinDark	bitcoindark
STORM	Storm	storm
KNC	Kyber Network	kyber-network
ELF	aelf	aelf
GAS	Gas	gas
XZC	ZCoin	zcoin
SUB	Substratum	substratum
PAY	TenX	tenx
TNB	Time New Bank	time-new-bank
DCN	Dentacoin	dentacoin
ICN	Iconomi	iconomi
CVC	Civic	civic
SYS	Syscoin	syscoin
DGD	DigixDAO	digixdao
LINK	ChainLink	chainlink
SKY	Skycoin	skycoin
RDN	Raiden Network Token	raiden-network-token
XBY	XTRABYTES	xtrabytes
BNT	Bancor	bancor
GXS	GXShares	gxshares
ENJ	Enjin Coin	enjin-coin
GAME	GameCredits	gamecredits
QSP	Quantstamp	quantstamp
VTC	Vertcoin	vertcoin
STORJ	Storj	storj
WTC	Walton	walton
BLOCK	Blocknet	blocknet
DNT	district0x	district0x
R	Revain	revain
SMART	SmartCash	smartcash
CNX	Cryptonex	cryptonex
BAY	BitBay	bitbay
UBQ	Ubiq	ubiq
LEND	ETHLend	ethlend
CND	Cindicator	cindicator
RPX	Red Pulse	red-pulse
DBC	DeepBrain Chain	deepbrain-chain
MCO	Monaco	monaco
ZCL	ZClassic	zclassic
CTR	Centra	centra
AST	AirSwap	airswap
ACT	Achain	achain
SNGLS	SingularDTV	singulardtv
NAV	NAV Coin	nav-coin
VEE	BLOCKv	blockv
RLC	iExec RLC	rlc
TRIG	Triggers	triggers
BRD	Bread	bread
XPA	XPlay	xplay
ETP	Metaverse ETP	metaverse
ITC	IoT Chain	iot-chain
MED	Medibloc	medibloc
DATA	Streamr DATAcoin	streamr-datacoin
EDG	Edgeless	edgeless
BCO	BridgeCoin	bridgecoin
EMC2	Einsteinium	einsteinium
SNM	SONM	sonm
ECA	Electra	electra
MANA	Decentraland	decentraland
BURST	Burst	burst
RCN	Ripio Credit Network	ripio-credit-network
CMT	CyberMiles	cybermiles
ANT	Aragon	aragon
MOON	Mooncoin	mooncoin
PART	Particl	particl
AMB	Ambrosus	amber
PPP	PayPie	paypie
FUEL	Etherparty	etherparty
PLR	Pillar	pillar
DCT	DECENT	decent
ADX	AdEx	adx-net
EMC	Emercoin	emercoin
CDT	CoinDash	coindash
MLN	Melon	melon
PPC	Peercoin	peercoin
MTL	Metal	metal
ZEN	ZenCash	zencash
ST	Simple Token	simple-token
1ST	FirstBlood	firstblood
SRN	SIRIN LABS Token	sirin-labs-token
THC	HempCoin	hempcoin
WABI	WaBi	wabi
UKG	Unikoin Gold	unikoin-gold
MGO	MobileGo	mobilego
LBC	LBRY Credits	library-credit
YOYOW	YOYOW	yoyow
XAS	Asch	asch
NEBL	Neblio	neblio
COB	Cobinhood	cobinhood
TNT	Tierion	tierion
WINGS	Wings	wings
EDO	Eidoo	eidoo
VIA	Viacoin	viacoin
CLOAK	CloakCoin	cloakcoin
XCP	Counterparty	counterparty
NULS	Nuls	nuls
UTK	UTRUST	utrust
INK	Ink	ink
QRL	Quantum Resistant Ledger	quantum-resistant-ledger
GRS	Groestlcoin	groestlcoin
PRE	Presearch	presearch
WGR	Wagerr	wagerr
DPY	Delphy	delphy
MOD	Modum	modum
RISE	Rise	rise
AGRS	Agoras Tokens	agoras-tokens
ARN	Aeron	aeron
AEON	Aeon	aeon
SPANK	SpankChain	spankchain
ATM	ATMChain	attention-token-of-media
CFI	Cofound.it	cofound-it
ADT	adToken	adtoken
NLG	Gulden	gulden
VOX	Voxels	voxels
SHIFT	Shift	shift
MTH	Monetha	monetha
SLS	SaluS	salus
GTO	Gifto	gifto
XSH	SHIELD	shield-xsh
ZSC	Zeusshield	zeusshield
FTC	Feathercoin	feathercoin
XSPEC	Spectrecoin	spectrecoin
PAYX	Paypex	paypex
PURA	Pura	pura
GUP	Matchpool	guppy
GVT	Genesis Vision	genesis-vision
UNITY	SuperNET	supernet-unity
DTR	Dynamic Trading Rights	dynamic-trading-rights
DLT	Agrello	agrello-delta
GRID	Grid+	grid
VIB	Viberate	viberate
PRO	Propy	propy
DAT	Datum	datum
LMC	LoMoCoin	lomocoin
NSR	NuShares	nushares
LUN	Lunyr	lunyr
MER	Mercury	mercury
TIX	Blocktix	blocktix
TRST	WeTrust	trust
TKN	TokenCard	tokencard
MNX	MinexCoin	minexcoin
BITCNY	bitCNY	bitcny
POT	PotCoin	potcoin
NLC2	NoLimitCoin	nolimitcoin
HST	Decision Token	decision-token
AMP	Synereo	synereo
IOC	I/O Coin	iocoin
VIBE	VIBE	vibe
NMC	Namecoin	namecoin
LRC	Loopring	loopring
MDA	Moeda Loyalty Points	moeda-loyalty-points
DMD	Diamond	diamond
HMQ	Humaniq	humaniq
FLASH	Flash	flash
LA	LAToken	latoken
PRL	Oyster Pearl	oyster-pearl
IXT	iXledger	ixledger
PASC	Pascal Coin	pascal-coin
SIB	SIBCoin	sibcoin
TAAS	TaaS	taas
PEPECASH	Pepe Cash	pepe-cash
BLK	BlackCoin	blackcoin
PPY	Peerplays	peerplays-ppy
RVT	Rivetz	rivetz
XEL	Elastic	elastic
CRW	Crown	crown
BTX	Bitcore	bitcore
XWC	WhiteCoin	whitecoin
FAIR	FairCoin	faircoin
NET	Nimiq	nimiq
SNOV	Snovio	snovio
GRC	GridCoin	gridcoin
EVX	Everex	everex
ION	ION	ion
COLX	ColossusCoinXT	colossuscoinxt
MSP	Mothership	mothership
GOLOS	Golos	golos
KICK	KickCoin	kickico
BOT	Bodhi	bodhi
OMNI	Omni	omni
DRT	DomRaider	domraider
HVN	Hive	hive
EXP	Expanse	expanse
LKK	Lykke	lykke
WRC	Worldcore	worldcore
GEO	GeoCoin	geocoin
JINN	Jinn	jinn
STX	Stox	stox
BITB	BitBean	bitbean
MUE	MonetaryUnit	monetaryunit
PLBT	Polybius	polybius
OAX	OAX	oax
NEU	Neumark	neumark
ELIX	Elixir	elixir
BCPT	BlockMason Credit Protocol	blockmason
RBY	Rubycoin	rubycoin
NXC	Nexium	nexium
FLDC	FoldingCoin	foldingcoin
NEOS	NeosCoin	neoscoin
OK	OKCash	okcash
INCNT	Incent	incent
HEAT	HEAT	heat-ledger
DBET	DecentBet	decent-bet
TIPS	FedoraCoin	fedoracoin
VRC	VeriCoin	vericoin
XMY	Myriad	myriad
PRG	Paragon	paragon
RADS	Radium	radium
XRL	Rialto	rialto
ALIS	ALIS	alis
NMR	Numeraire	numeraire
AIR	AirToken	airtoken
PHR	Phore	phore
BCAP	BCAP	bcap
PND	Pandacoin	pandacoin-pnd
ECC	ECC	eccoin
GCR	Global Currency Reserve	global-currency-reserve
PTOY	Patientory	patientory
POSW	PoSW Coin	posw-coin
SBD	Steem Dollars	steem-dollars
XLR	Solaris	solaris
ORME	Ormeus Coin	ormeus-coin
COSS	COSS	coss
PST	Primas	primas
MYST	Mysterium	mysterium
XST	Stealthcoin	stealthcoin
COVAL	Circuits of Value	circuits-of-value
VOISE	Voise	voisecom
PBL	Publica	publica
PIX	Lampix	lampix
MUSIC	Musicoin	musicoin
WILD	Wild Crypto	wild-crypto
QAU	Quantum	quantum
WCT	Waves Community Token	waves-community-token
POLL	ClearPoll	clearpoll
OBITS	OBITS	obits
RMC	Russian Mining Coin	russian-mining-coin
BNTY	Bounty0x	bounty0x
OTN	Open Trading Network	open-trading-network
DTB	Databits	databits
FLO	FlorinCoin	florincoin
TIME	Chronobank	chronobank
ZOI	Zoin	zoin
XNN	Xenon	xenon
ENRG	Energycoin	energycoin
BQ	bitqy	bitqy
SWT	Swarm City	swarm-city
CLAM	Clams	clams
SLR	SolarCoin	solarcoin
IOP	Internet of People	internet-of-people
FRST	FirstCoin	firstcoin
AVT	Aventus	aventus
SNC	SunContract	suncontract
OCT	OracleChain	oraclechain
PKT	Playkey	playkey
GAM	Gambit	gambit
SOAR	Soarcoin	soarcoin
CSNO	BitDice	bitdice
ONION	DeepOnion	deeponion
TGT	Target Coin	target-coin
BIS	Bismuth	bismuth
DIVX	Divi	divi
DNA	EncrypGen	encrypgen
CURE	Curecoin	curecoin
FLIXX	Flixxo	flixxo
IFT	InvestFeed	investfeed
LOC	LockChain	lockchain
BITUSD	bitUSD	bitusd
OXY	Oxycoin	oxycoin
ATB	ATBCoin	atbcoin
BSD	BitSend	bitsend
DIME	Dimecoin	dimecoin
WISH	MyWish	mywish
MINT	Mintcoin	mintcoin
DOVU	Dovu	dovu
CAG	Change	change
BMC	Blackmoon Crypto	blackmoon-crypto
BITMARK	Bitmark	bitmark
BBR	Boolberry	boolberry
ART	Maecenas	maecenas
BLUE	BLUE	ethereum-blue
PINK	PinkCoin	pinkcoin
LEO	LEOcoin	leocoin
ECN	E-coin	e-coin
CRED	Verify	verify
CREDO	Credo	credo
XUC	Exchange Union	exchange-union
SEQ	Sequence	sequence
ESP	Espers	espers
BCY	Bitcrystals	bitcrystals
SPHR	Sphere	sphere
VRM	VeriumReserve	veriumreserve
ECOB	Ecobit	ecobit
SXC	Sexcoin	sexcoin
ETTWAVES	EncryptoTel [WAVES]	encryptotel
SPR	SpreadCoin	spreadcoin
ICOS	ICOS	icos
XVC	Vcash	vcash
NYC	NewYorkCoin	newyorkcoin
BET	DAO.Casino	dao-casino
DICE	Etheroll	etheroll
ATMS	Atmos	atmos
CANN	CannabisCoin	cannabiscoin
ABY	ArtByte	artbyte
ODN	Obsidian	obsidian
UNO	Unobtanium	unobtanium
CAT	BlockCAT	blockcat
BDL	Bitdeal	bitdeal
HDG	Hedge	hedge
NIO	Autonio	autonio
QWARK	Qwark	qwark
MYB	MyBit Token	mybit-token
DOPE	DopeCoin	dopecoin
BELA	Bela	belacoin
TX	TransferCoin	transfercoin
PLU	Pluton	pluton
XAUR	Xaurum	xaurum
SPRTS	Sprouts	sprouts
UNIT	Universal Currency	universal-currency
BWK	Bulwark	bulwark
ALQO	ALQO	alqo
GBX	GoByte	gobyte
INXT	Internxt	internxt
PHO	Photon	photon
NTRN	Neutron	neutron
GCN	GCoin	gcoin
PTC	Pesetacoin	pesetacoin
SNRG	Synergy	synergy
XPM	Primecoin	primecoin
AC	AsiaCoin	asiacoin
GLD	GoldCoin	goldcoin
LINDA	Linda	linda
UFO	UFO Coin	ufo-coin
AUR	Auroracoin	auroracoin
QVT	Qvolta	qvolta
DBIX	DubaiCoin	dubaicoin-dbix
HUSH	Hush	hush
FOR	FORCE	force
MEME	Memetic (PepeCoin)	memetic
HYP	HyperStake	hyperstake
XBC	Bitcoin Plus	bitcoin-plus
XMCC	Monoeci	monacocoin
NVC	Novacoin	novacoin
SPF	SportyFi	sportyfi
TZC	TrezarCoin	trezarcoin
START	Startcoin	startcoin
1337	1337	1337coin
CRB	Creditbit	creditbit
IND	Indorse Token	indorse-token
NVST	NVO	nvo
VSX	Vsync	vsync-vsx
TFL	TrueFlip	trueflip
ZNY	Bitzeny	bitzeny
BTDX	Bitcloud	bitcloud
PURE	Pure	pure
KORE	Kore	korecoin
MTNC	Masternodecoin	masternodecoin
BLITZ	Blitzcash	blitzcash
SUMO	Sumokoin	sumokoin
BPL	Blockpool	blockpool
FRD	Farad	farad
PIRL	Pirl	pirl
VSL	vSlice	vslice
APX	APX	apx
TOA	ToaCoin	toacoin
ZEPH	Zephyr	zephyr
2GIVE	2GIVE	2give
SYNX	Syndicate	syndicate
EAC	EarthCoin	earthcoin
CVCOIN	CVCoin	cvcoin
CRAVE	Crave	crave
RIC	Riecoin	riecoin
GMT	Mercury Protocol	mercury-protocol
EDR	E-Dinar Coin	e-dinar-coin
XMG	Magi	magi
B2B	B2B	b2bx
INN	Innova	innova
PZM	PRIZM	prizm
REX	REX	real-estate-tokens
BRX	Breakout Stake	breakout-stake
HGT	HelloGold	hellogold
EXCL	ExclusiveCoin	exclusivecoin
BON	Bonpay	bonpay
OPT	Opus	opus
SEND	Social Send	social-send
SSS	Sharechain	sharechain
MAG	Magnet	magnet
PDC	Project Decorum	project-decorum
CRC	CrowdCoin	crowdcoin
ERO	Eroscoin	eroscoin
SCL	Social	social
ASTRO	Astro	astro
BTCZ	BitcoinZ	bitcoinz
LUX	LUXCoin	luxcoin
NOTE	DNotes	dnotes
ERC	EuropeCoin	europecoin
USNBT	NuBits	nubits
CHIPS	CHIPS	chips
VTR	vTorrent	vtorrent
HWC	HollyWoodCoin	hollywoodcoin
DRP	DCORP	dcorp
BRK	Breakout	breakout
HBT	Hubii Network	hubii-network
REC	Regalcoin	regalcoin
CREA	Creativecoin	creativecoin
ADST	AdShares	adshares
DYN	Dynamic	dynamic
FYP	FlypMe	flypme
BUZZ	BuzzCoin	buzzcoin
LIFE	LIFE	life
TRUST	TrustPlus	trustplus
PFR	Payfair	payfair
ZEIT	Zeitcoin	zeitcoin
SWIFT	Bitswift	bitswift
TRC	Terracoin	terracoin
PRIX	Privatix	privatix
ITNS	IntenseCoin	intensecoin
EGC	EverGreenCoin	evergreencoin
VIVO	VIVO	vivo
PUT	PutinCoin	putincoin
KRB	Karbo	karbowanec
MXT	MarteXcoin	martexcoin
ANC	Anoncoin	anoncoin
REAL	REAL	real
ATL	ATLANT	atlant
QRK	Quark	quark
ZRC	ZrCoin	zrcoin
EQT	EquiTrader	equitrader
CHC	ChainCoin	chaincoin
HUC	HunterCoin	huntercoin
PKB	ParkByte	parkbyte
BLU	BlueCoin	bluecoin
YOC	Yocoin	yocoin
IXC	Ixcoin	ixcoin
CFT	CryptoForecast	cryptoforecast
MBRS	Embers	embers
GOOD	Goodomy	goodomy
WDC	WorldCoin	worldcoin
ADC	AudioCoin	audiocoin
DOT	Dotcoin	dotcoin
MCAP	MCAP	mcap
XFT	Footy Cash	footy-cash
EBST	eBoost	eboostcoin
RUP	Rupee	rupee
NOBL	NobleCoin	noblecoin
DNR	Denarius	denarius-dnr
BBT	BitBoost	bitboost
PING	CryptoPing	cryptoping
PBT	Primalbase Token	primalbase
BUN	BunnyCoin	bunnycoin
PGL	Prospectors Gold	prospectors-gold
EFL	e-Gulden	e-gulden
DAXX	DaxxCoin	daxxcoin
STAK	STRAKS	straks
EBTC	eBitcoin	ebtcnew
TKS	Tokes	tokes
UFR	Upfiring	upfiring
DAR	Darcrus	darcrus
EFYT	Ergo	ergo
ONG	onG.social	ongsocial
FLT	FlutterCoin	fluttercoin
SMARTBILLIONS	SmartBillions	smartbillions
RKC	Royal Kingdom Coin	royal-kingdom-coin
NKA	IncaKoin	incakoin
XCPO	Copico	copico
HOLD	Interstellar Holdings	interstellar-holdings
ATS	Authorship	authorship
LINX	Linx	linx
XGOX	XGOX	xgox
DGPT	DigiPulse	digipulse
VISIO	Visio	visio
ADL	Adelphoi	adelphoi
RAIN	Condensate	condensate
CARBON	Carboncoin	carboncoin
CBX	Crypto Bullion	cryptogenic-bullion
OCL	Oceanlab	oceanlab
ALT	Altcoin	altcoin-alt
BRO	Bitradio	bitradio
FLIK	FLiK	flik
STA	Starta	starta
STU	bitJob	student-coin
KLN	Kolion	kolion
DCY	Dinastycoin	dinastycoin
CTX	CarTaxi Token	cartaxi-token
BYC	Bytecent	bytecent
INFX	Influxcoin	influxcoin
ELTCOIN	ELTCOIN	eltcoin
XPD	PetroDollar	petrodollar
GIM	Gimli	gimli
MRT	Miners' Reward Token	miners-reward-token
ETBS	Ethbits	ethbits
ELLA	Ellaism	ellaism
HAT	Hawala.Today	hawala-today
IFLT	InflationCoin	inflationcoin
ICOO	ICO OpenLedger	ico-openledger
UIS	Unitus	unitus
XCN	Cryptonite	cryptonite
RC	RussiaCoin	russiacoin
BASH	LuckChain	luckchain
UNB	UnbreakableCoin	unbreakablecoin
DP	DigitalPrice	digitalprice
UNIFY	Unify	unify
FYN	FundYourselfNow	fundyourselfnow
DGC	Digitalcoin	digitalcoin
ZCG	Zlancer	zcash-gold
LDOGE	LiteDoge	litedoge
BBP	BiblePay	biblepay
NDC	NEVERDIE	neverdie
ARC	ArcticCoin	arcticcoin
FJC	FujiCoin	fujicoin
MEC	Megacoin	megacoin
RNS	Renos	renos
SOON	SoonCoin	sooncoin
LGD	Legends Room	legends-room
GRE	Greencoin	greencoin
NUKO	Nekonium	nekonium
KLC	KiloCoin	kilocoin
NETCOIN	NetCoin	netcoin
MZC	MazaCoin	mazacoin
FCN	Fantomcoin	fantomcoin
FST	Fastcoin	fastcoin
DAI	Dai	dai
SAGA	SagaCoin	sagacoin
I0C	I0Coin	i0coin
FC2	FuelCoin	fuelcoin
DFT	DraftCoin	draftcoin
INSN	InsaneCoin	insanecoin-insn
V	Version	version
KURT	Kurrent	kurrent
LOG	Woodcoin	woodcoin
ZET	Zetacoin	zetacoin
AHT	Bowhead	bowhead
GRWI	Growers International	growers-international
ELE	Elementrem	elementrem
UTC	UltraCoin	ultracoin
MOIN	Moin	moin
CDN	Canada eCoin	canada-ecoin
ERC20	ERC20	erc20
ACC	Accelerator Network	accelerator-network
BTA	Bata	bata
ZENI	Zennies	zennies
STRC	StarCredits	starcredits
DSR	Desire	desire
CRM	Cream	cream
OTX	Octanox	octanox
CPC	Capricoin	capricoin
EPY	Emphy	emphy
TES	TeslaCoin	teslacoin
FUNK	The Cypherfunks	the-cypherfunks
BITS	Bitstar	bitstar
PROCURRENCY	ProCurrency	procurrency
SIGT	Signatum	signatum
ZER	Zero	zero
CMPCO	CampusCoin	campuscoin
WHL	WhaleCoin	whalecoin
ADZ	Adzcoin	adzcoin
SMLY	SmileyCoin	smileycoin
CCN	CannaCoin	cannacoin
4CHN	ChanCoin	chancoin
BTCS	Bitcoin Scrypt	bitcoin-scrypt
XLC	LeviarCoin	leviarcoin
WGO	WavesGo	wavesgo
TRCT	Tracto	tracto
XIOS	Xios	xios
GB	GoldBlocks	goldblocks
MAC	Machinecoin	machinecoin
42	42-coin	42-coin
SMC	SmartCoin	smartcoin
ATOM	Atomic Coin	atomic-coin
TRI	Triangles	triangles
ORB	Orbitcoin	orbitcoin
BIGUP	BigUp	bigup
SKIN	SkinCoin	skincoin
NETKO	Netko	netko
PIGGY	Piggycoin	piggycoin
BLOCKPAY	BlockPay	blockpay
AU	AurumCoin	aurumcoin
CNT	Centurion	centurion
TIT	Titcoin	titcoin
POS	PoSToken	postoken
HTC	HitCoin	hitcoin
DEM	Deutsche eMark	deutsche-emark
XHI	HiCoin	hicoin
CCT	Crystal Clear 	crystal-clear
KEK	KekCoin	kekcoin
HODL	HOdlcoin	hodlcoin
TROLL	Trollcoin	trollcoin
PASL	Pascal Lite	pascal-lite
ENT	Eternity	eternity
BTB	BitBar	bitbar
POP	PopularCoin	popularcoin
SUPER	SuperCoin	supercoin
HPC	Happycoin	happycoin
SPACE	SpaceCoin	spacecoin
KOBO	Kobocoin	kobocoin
XBL	Billionaire Token	billionaire-token
EMV	Ethereum Movie Venture	ethereum-movie-venture
MNE	Minereum	minereum
CV2	Colossuscoin V2	colossuscoin-v2
CJ	Cryptojacks	cryptojacks
NYAN	Nyancoin	nyancoin
LOT	LottoCoin	lottocoin
HBN	HoboNickels	hobonickels
BTCRED	Bitcoin Red	bitcoin-red
ETG	Ethereum Gold	ethereum-gold
TRK	Truckcoin	truckcoin
NEWB	Newbium	newbium
GAIA	GAIA	gaia
LANA	LanaCoin	lanacoin
8BIT	8Bit	8bit
SCORE	Scorecoin	scorecoin
XPTX	PlatinumBAR	platinumbar
MAX	MaxCoin	maxcoin
VIDZ	PureVidz	purevidz
TRUMP	TrumpCoin	trumpcoin
SGR	Sugar Exchange	sugar-exchange
XCXT	CoinonatX	coinonatx
RED	RedCoin	redcoin
BPC	Bitpark Coin	bitpark-coin
XJO	Joulecoin	joulecoin
DDF	DigitalDevelopersFund	digital-developers-fund
XGR	GoldReserve	goldreserve
PXC	Phoenixcoin	phoenixcoin
SDRN	Senderon	senderon
VLT	Veltor	veltor
AMMO	Ammo Reloaded	ammo-rewards
WTT	Giga Watt Token	giga-watt-token
UNY	Unity Ingot	unity-ingot
C2	Coin2.1	coin2-1
OPAL	Opal	opal
FNC	FinCoin	fincoin
CUBE	DigiCube	digicube
ITZ	Interzone	interzone
FUCK	FuckToken	fucktoken
EBET	EthBet	ethbet
ONX	Onix	onix
ALTCOM	AltCommunity Coin	altcommunity-coin
XRA	Ratecoin	ratecoin
808	808Coin	808coin
BTSR	BTSR	btsr
TTC	TittieCoin	tittiecoin
NTO	Fujinto	fujinto
BLAS	BlakeStar	blakestar
DSH	Dashcoin	dashcoin
KRONE	Kronecoin	kronecoin
RLT	RouletteToken	roulettetoken
Q2C	QubitCoin	qubitcoin
LCP	Litecoin Plus	litecoin-plus
CNO	Coin(O)	coin
PXI	Prime-XI	prime-xi
TKR	CryptoInsight	trackr
RBX	Ripto Bux	ripto-bux
PCOIN	Pioneer Coin	pioneer-coin
CCRB	CryptoCarbon	cryptocarbon
MCRN	MACRON	macron
CCO	Ccore	ccore
EUC	Eurocoin	eurocoin
CFD	Confido	confido
CHESS	ChessCoin	chesscoin
XCT	C-Bit	c-bit
TRDT	Trident Group	trident
BITBTC	bitBTC	bitbtc
KUSH	KushCoin	kushcoin
HAL	Halcyon	halcyon
GAP	Gapcoin	gapcoin
MOJO	MojoCoin	mojocoin
NTWK	Network Token	network-token
BLC	Blakecoin	blakecoin
EOT	EOT Token	eot-token
ZZC	ZoZoCoin	zozocoin
SLG	Sterlingcoin	sterlingcoin
TAG	TagCoin	tagcoin
MRJA	GanjaCoin	ganjacoin
AMBER	AmberCoin	ambercoin
EVIL	Evil Coin	evil-coin
PAK	Pakcoin	pakcoin
BTCR	Bitcurrency	bitcurrency
ECASH	Ethereum Cash	ethereumcash
ABJ	Abjcoin	abjcoin
BCF	Bitcoin Fast	bitcoinfast
CNNC	Cannation	cannation
LBTC	LiteBitcoin	litebitcoin
AIB	Advanced Internet Blocks	advanced-internet-blocks
TSE	TattooCoin (Standard Edition)	tattoocoin
UNIC	UniCoin	unicoin
MNM	Mineum	mineum
DRXNE	DROXNE	droxne
BTWTY	Bit20	bit20
MAR	Marijuanacoin	marijuanacoin
MOTO	Motocoin	motocoin
CON	PayCon	paycon
STV	Sativacoin	sativacoin
BOLI	Bolivarcoin	bolivarcoin
VOT	VoteCoin	votecoin
HERO	Sovereign Hero	sovereign-hero
SRC	SecureCoin	securecoin
BRIA	BriaCoin	briacoin
EL	Elcoin	elcoin-el
GUN	Guncoin	guncoin
MARS	Marscoin	marscoin
JET	Jetcoin	jetcoin
BLZ	BlazeCoin	blazecoin
BSTY	GlobalBoost-Y	globalboost-y
CORG	CorgiCoin	corgicoin
EBCH	eBitcoinCash	ebitcoin-cash
ITI	iTicoin	iticoin
AMS	AmsterdamCoin	amsterdamcoin
XVP	Virtacoinplus	virtacoinplus
BERN	BERNcash	berncash
GTC	Global Tour Coin	global-tour-coin
CRX	Chronos	chronos
VPRC	VapersCoin	vaperscoin
DFS	DFSCoin	dfscoin
LTB	LiteBar	litebar
KED	Darsek	darsek
XPY	PayCoin	paycoin2
PR	Prototanium	prototanium
ARI	Aricoin	aricoin
XCS	CybCSec	cybcsec
HXX	Hexx	hexx
MUT	Mutual Coin	mutual-coin
MNC	Mincoin	mincoin
CATCOIN	Catcoin	catcoin
SWING	Swing	swing
WYV	Wyvern	wyvern
MONK	Monkey Project	monkey-project
KAYI	Kayicoin	kayicoin
FUNC	FUNCoin	funcoin
EMD	Emerald Crypto	emerald
BAS	BitAsean	bitasean
STARS	StarCash Network	starcash-network
ECO	EcoCoin	ecocoin
TEK	TEKcoin	tekcoin
ETHD	Ethereum Dark	ethereum-dark
TYCHO	Tychocoin	tychocoin
IETH	iEthereum	iethereum
POST	PostCoin	postcoin
QTL	Quatloo	quatloo
YTN	YENTEN	yenten
BITGEM	Bitgem	bitgem
GPU	GPU Coin	gpu-coin
888	OctoCoin	octocoin
VUC	Virta Unique Coin	virta-unique-coin
ZUR	Zurcoin	zurcoin
HMP	HempCoin (HMP)	hempcoin-hmp
HNC	Helleniccoin	helleniccoin
MST	MustangCoin	mustangcoin
ICOB	ICOBID	icobid
GRIM	Grimcoin	grimcoin
DALC	Dalecoin	dalecoin
LEA	LeaCoin	leacoin
PX	PX	px
SLING	Sling	sling
UNITS	GameUnits	gameunits
DUO	ParallelCoin	parallelcoin
GLT	GlobalToken	globaltoken
REE	ReeCoin	reecoin
ERY	Eryllium	eryllium
XCO	X-Coin	x-coin
USDE	USDe	usde
GRT	Grantcoin	grantcoin
BITSILVER	bitSilver	bitsilver
XRE	RevolverCoin	revolvercoin
SOIL	SOILcoin	soilcoin
MTLMC3	Metal Music Coin	metal-music-coin
RBT	Rimbit	rimbit
CXT	Coinonat	coinonat
HONEY	Honey	honey
ARCO	AquariusCoin	aquariuscoin
EREAL	eREAL	ereal
EAGLE	EagleCoin	eaglecoin
IMS	Independent Money System	independent-money-system
SFC	Solarflarecoin	solarflarecoin
ARG	Argentum	argentum
ACOIN	Acoin	acoin
ROC	Rasputin Online Coin	rasputin-online-coin
EVO	Evotion	evotion
CACH	CacheCoin	cachecoin
NRO	Neuro	neuro
CPN	CompuCoin	compucoin
BUMBA	BumbaCoin	bumbacoin
GP	GoldPieces	goldpieces
JIN	Jin Coin	jin-coin
LUNA	Luna Coin	luna-coin
TAJ	TajCoin	tajcoin
$$$	Money	money
FLAX	Flaxscript	flaxscript
COMET	Comet	comet
BIP	BipCoin	bipcoin
XCRE	Creatio	creatio
FUZZ	FuzzBalls	fuzzballs
RPC	RonPaulCoin	ronpaulcoin
BLN	Bolenum	bolenum
GPL	Gold Pressed Latinum	gold-pressed-latinum
EGAS	ETHGAS	ethgas
BRAT	BROTHER	brat
ALL	Allion	allion
COAL	BitCoal	bitcoal
611	SixEleven	sixeleven
MAY	Theresa May Coin	theresa-may-coin
WORM	HealthyWormCoin	healthywormcoin
BENJI	BenjiRolls	benjirolls
SPT	Spots	spots
MILO	MiloCoin	milocoin
QCN	QuazarCoin	quazarcoin
ZMC	ZetaMicron	zetamicron
XBTS	Beatcoin	beatcoin
NEVA	NevaCoin	nevacoin
ICON	Iconic	iconic
AERM	Aerium	aerium
BOAT	BOAT	doubloon
PRX	Printerium	printerium
300	300 Token	300-token
DRS	Digital Rupees	digital-rupees
EXN	ExchangeN	exchangen
OFF	Cthulhu Offerings	cthulhu-offerings
SONG	SongCoin	songcoin
ASAFE2	AllSafe	allsafe
DBTC	Debitcoin	debitcoin
PRC	PRCoin	prcoin
UET	Useless Ethereum Token	useless-ethereum-token
B3	B3Coin	b3coin
ACP	AnarchistsPrime	anarchistsprime
BITEUR	bitEUR	biteur
IMX	Impact	impact
BNX	BnrtxCoin	bnrtxcoin
PIE	PIECoin	piecoin
PLACO	PlayerCoin	playercoin
SLEVIN	Slevin	slevin
LTCU	LiteCoin Ultra	litecoin-ultra
CTIC3	Coimatic 3.0	coimatic-3
CTO	Crypto	crypto
TOR	Torcoin	torcoin-tor
BRAIN	Braincoin	braincoin
DOLLAR	Dollar Online	dollar-online
DIX	Dix Asset	dix-asset
ADCN	Asiadigicoin	asiadigicoin
XOC	Xonecoin	xonecoin
CWXT	CryptoWorldX Token	cryptoworldx-token
WOMEN	WomenCoin	women
LTCR	Litecred	litecred
GEERT	GeertCoin	geertcoin
MSCN	Master Swiscoin	master-swiscoin
RSGP	RSGPcoin	rsgpcoin
JOBS	JobsCoin	jobscoin
VLTC	Vault Coin	vault-coin
CRDNC	Credence Coin	credence-coin
ARGUS	Argus	argus
VRS	Veros	veros
MGM	Magnum	magnum
ELS	Elysium	elysium
KINGN	KingN Coin	kingn-coin
ROOFS	Roofs	roofs
CTIC2	Coimatic 2.0	coimatic-2
ALTC	Antilitecoin	antilitecoin
XRC	Rawcoin	rawcoin2
CREVA	CrevaCoin	crevacoin
VOLT	Bitvolt	bitvolt
NANOX	Project-X	project-x
LVPS	LevoPlus	levoplus
SOCC	SocialCoin	socialcoin-socc
XNG	Enigma	enigma
GSR	GeyserCoin	geysercoin
TSTR	Tristar Coin	tristar-coin
CONX	Concoin	concoin
HMC	HarmonyCoin	harmonycoin-hmc
ABN	Abncoin	abncoin
DMB	Digital Money Bits	digital-money-bits
TCC	The ChampCoin	the-champcoin
XTO	Tao	tao
ARCADE	Arcade Token	arcade-token
VTA	Virtacoin	virtacoin
GCC	TheGCCcoin	thegcccoin
SIFT	Smart Investment Fund Token	smart-investment-fund-token
YASH	YashCoin	yashcoin
INPAY	InPay	inpay
FIMK	FIMKrypto	fimkrypto
RUSTBITS	Rustbits	rustbits
ITT	Intelligent Trading Tech	intelligent-trading-tech
PIPL	PiplCoin	piplcoin
CRYPT	CryptCoin	cryptcoin
TOKEN	SwapToken	swaptoken
BRIT	BritCoin	britcoin
SHORTY	Shorty	shorty
MBI	Monster Byte	monster-byte
JNS	Janus	janus
RIYA	Etheriya	etheriya
SDC	ShadowCash	shadowcash
METAL	MetalCoin	metalcoin
LNK	Link Platform	link-platform
B@	Bankcoin	bankcoin
CASINO	Casino	casino
BXT	BitTokens	bittokens
STS	Stress	stress
USC	Ultimate Secure Cash	ultimate-secure-cash
VAL	Valorbit	valorbit
UNI	Universe	universe
J	Joincoin	joincoin
WAY	WayGuide	wayguide
GLC	GlobalCoin	globalcoin
BUCKS	SwagBucks	swagbucks
BITZ	Bitz	bitz
E4ROW	E4ROW	ether-for-the-rest-of-the-world
MAO	Mao Zedong	mao-zedong
TGC	Tigercoin	tigercoin
ICOIN	iCoin	icoin
SPEX	SproutsExtreme	sproutsextreme
ICE	iDice	idice
SH	Shilling	shilling
PHS	Philosopher Stones	philosopher-stones
TALK	BTCtalkcoin	btctalkcoin
FRC	Freicoin	freicoin
REMI	Remicoin	remicoin
SHDW	Shadow Token	shadow-token
CYP	Cypher	cypher
FLY	Flycoin	flycoin
RBIES	Rubies	rubies
VC	VirtualCoin	virtualcoin
SCRT	SecretCoin	secretcoin
FRK	Franko	franko
MAD	SatoshiMadness	satoshimadness
SAC	SACoin	sacoin
MEOW	Kittehcoin	kittehcoin
FIRE	Firecoin	firecoin
ISL	IslaCoin	islacoin
WMC	WMCoin	wmcoin
BITGOLD	bitGold	bitgold
WARP	WARP	warp
YAC	Yacoin	yacoin
ANTI	AntiBitcoin	antibitcoin
VEC2	VectorAI	vector
BTPL	Bitcoin Planet	bitcoin-planet
DLC	Dollarcoin	dollarcoin
XBTC21	Bitcoin 21	bitcoin-21
URO	Uro	uro
BOST	BoostCoin	boostcoin
URC	Unrealcoin	unrealcoin
RUPX	Rupaya	rupaya
GUCCIONE	GuccioneCoin	guccionecoin
DES	Destiny	destiny
CF	Californium	californium
BTQ	BitQuark	bitquark
COXST	CoExistCoin	coexistcoin
BVC	BeaverCoin	beavercoin
BLRY	BillaryCoin	billarycoin
QBK	Qibuck Asset	qibuck-asset
ATX	Artex Coin	artex-coin
BSTAR	Blackstar	blackstar
DRM	Dreamcoin	dreamcoin
CASH	Cashcoin	cashcoin
FLVR	FlavorCoin	flavorcoin
PULSE	Pulse	pulse
VIP	VIP Tokens	vip-tokens
JWL	Jewels	jewels
MND	MindCoin	mindcoin
ZYD	Zayedcoin	zayedcoin
QBC	Quebecoin	quebecoin
GBT	GameBet Coin	gamebet-coin
JS	JavaScript Token	javascript-token
MTM	MTMGaming	mtmgaming
MRNG	MorningStar	morningstar-payments
DIBC	DIBCOIN	dibcoin
EGO	EGO	ego
BIOS	BiosCrypto	bios-crypto
STEPS	Steps	steps
RIDE	Ride My Car	ride-my-car
IMPS	ImpulseCoin	impulsecoin
ORLY	Orlycoin	orlycoin
DLISK	DAPPSTER	dappster
ZNE	Zonecoin	zonecoin
CRT	CRTCoin	crtcoin
G3N	G3N	genstake
PLNC	PLNcoin	plncoin
WBB	Wild Beast Block	wild-beast-block
BSC	BowsCoin	bowscoin
OS76	OsmiumCoin	osmiumcoin
TAGR	TAGRcoin	tagrcoin
SCS	Speedcash	speedcash
PONZI	PonziCoin	ponzicoin
ARB	ARbit	arbit
CESC	CryptoEscudo	cryptoescudo
AGLC	AgrolifeCoin	agrolifecoin
HVCO	High Voltage	high-voltage
PEX	PosEx	posex
LIR	LetItRide	letitride
FXE	FuturXe	futurexe
CAB	Cabbage	cabbage
FRAZ	Frazcoin	frazcoin
IBANK	iBank	ibank
BIOB	BioBar	biobar
P7C	P7Coin	p7coin
SDP	SydPak	sydpak
LEX	Lex4All	lex4all
OCEAN	BurstOcean	burstocean
GBC	GBCGoldCoin	gbcgoldcoin
CRTM	Corethum	corethum
SLFI	Selfiecoin	selfiecoin
SANDG	Save and Gain	save-and-gain
SOJ	Sojourn	sojourn
NODC	NodeCoin	nodecoin
ULA	Ulatech	ulatech
CCM100	CCMiner	ccminer
EBT	Ebittree Coin	ebittree-coin
PIZZA	PizzaCoin	pizzacoin
DGCS	Digital Credits	digital-credits
CALC	CaliphCoin	caliphcoin
APW	AppleCoin	applecoin-apw
ATMC	ATMCoin	atmcoin
SMT	SmartMesh	smartmesh
GNX	Genaro Network	genaro-network
BIX	Bibox Token	bibox-token
NAS	Nebulas	nebulas-token
HTML	HTMLCOIN	html-coin
BCD	Bitcoin Diamond	bitcoin-diamond
GAME2	Game	game
TSL	Energo	energo
MOT	Olympus Labs	olympus-labs
QLC	QLINK	qlink
ENTCASH	ENTCash	entcash
PROCHAIN	ProChain	prochain
CAPP	Cappasity	cappasity
AMM	MicroMoney	micromoney
BCX	BitcoinX [Futures]	bitcoinx
SBTC	Super Bitcoin	super-bitcoin
AI	POLY AI	poly-ai
HPY	Hyper Pay	hyper-pay
BITCLAVE	BitClave	bitclave
B2X	Segwit2x [Futures]	segwit2x
SHND	StrongHands	stronghands
QBT	Qbao	qbao
NGC	NAGA	naga
EMB	EmberCoin	embercoin
SPHTX	SophiaTX	sophiatx
MKR	Maker	maker
XTZ	Tezos (Pre-Launch)	tezos
DEW	DEW	dew
VIU	Viuly	viuly
CMSETH	COMSA [ETH]	comsa-eth
LLT	LLToken	lltoken
CLUB	ClubCoin	clubcoin
HTML5	HTML5COIN	htmlcoin
MDS	MediShares	medishares
FRGC	Fargocoin	fargocoin
INF	InfChain	infchain
ACE	Ace	ace
HBC	HomeBlockCoin	homeblockcoin
CMSXEM	COMSA [XEM]	comsa-xem
UGT	UG Token	ug-token
DIM	DIMCOIN	dimcoin
BTE	BitSerial	bitserial
IGNIS	Ignis	ignis
WC	WINCOIN	win-coin
FIL	Filecoin [Futures]	filecoin
OX	OX Fina	ox-fina
BIG	BigONE Token	bigone-token
EAG	EA Coin	ea-coin
XRY	Royalties	royalties
ESC	Escroco	escoro
TOK	Tokugawa	tokugawa
LIGHTNINGBTC	Lightning Bitcoin	lightning-bitcoin
BSR	BitSoar	bitsoar
GBG	Golos Gold	golos-gold
XID	Sphre AIR 	sphre-air
HIGH	High Gain	high-gain
GRX	GOLD Reward Token	gold-reward-token
GAIN	UGAIN	ugain
BTCA	Bitair	bitair
XIN	Infinity Economics	infinity-economics
MAGE	MagicCoin	magiccoin
WIC	Wi Coin	wi-coin
UBTC	United Bitcoin	united-bitcoin
KBR	Kubera Coin	kubera-coin
BCDN	BlockCDN	blockcdn
SBC	StrikeBitClub	strikebitclub
CPAY	Cryptopay	cryptopay
ANI	Animecoin	animecoin
BT1	BT1 [CST]	bt1-cst
ZENGOLD	ZenGold	zengold
BATCOIN	BatCoin	batcoin
UQC	Uquid Coin	uquid-coin
SISA	SISA	sisa
THS	TechShares	techshares
MSD	MSD	msd
PLAY	HEROcoin	herocoin
DAV	DavorCoin	davorcoin
KARMA	Karmacoin	karmacoin
SIGMA	SIGMAcoin	sigmacoin
BEST	BestChain	bestchain
EXRN	EXRNchain	exrnchain
SUR	Suretly	suretly
ACES	Aces	aces
PCN	PeepCoin	peepcoin
NAMO	NamoCoin	namocoin
PEC	Peacecoin	peacecoin
SAFEX	Safe Exchange Coin	safe-exchange-coin
VASH	VPNCoin	vpncoin
PYLNT	Pylon Network	pylon-network
MGC	MergeCoin	mergecoin
DMC	DynamicCoin	dynamiccoin
FDX	FidentiaX	fidentiax
BOS	BOScoin	boscoin
RBBT	RabbitCoin	rabbitcoin
NEOG	NEO GOLD	neo-gold
TIE	TIES Network	ties-network
DAY	Chronologic	chronologic
WAND	WandX	wandx
BT2	BT2 [CST]	bt2-cst
ADCOIN	AdCoin	adcoin
PNX	Phantomx	phantomx
COR	CORION	corion
STAR	Starbase	starbase
SJCX	Storjcoin X	storjcoin-x
SKR	Sakuracoin	sakuracoin
LTG	LiteCoin Gold	litecoin-gold
GAY	GAY Money	gaycoin
TURBO	TurboCoin	turbocoin
TRIA	Triaconta	triaconta
UR	UR	ur
CMP	Compcoin	compcoin
MCI	Musiconomi	musiconomi
ETTETH	encryptotel-eth	encryptotel-eth
WOW	Wowcoin	wowcoin
DASHS	Dashs	dashs
PCS	Pabyosi Coin Special	pabyosi-coin-special
XTD	XTD Coin	xtd-coin
PRN	Protean	protean
PLC	PlusCoin	pluscoin
FRN	Francs	francs
FONZ	Fonziecoin	fonziecoin
FLAP	FlappyCoin	flappycoin
PLX	PlexCoin	plexcoin
DON	Donationcoin	donationcoin
ZBC	Zilbercoin	zilbercoin
TOP	TopCoin	topcoin
MARX	MarxCoin	marxcoin
RYZ	ANRYZE	anryze
SAK	Sharkcoin	sharkcoin
WINK	Wink	wink
RCOIN	Rcoin	rcoin
PRES	President Trump	president-trump
EVR	Everus	everus
SHA	SHACoin	shacoin
SCT	Soma	soma
ABC	Alphabit	alphabitcoinfund
EDRC	EDRCoin	edrcoin
MTX	Matryx	matryx
BTCM	BTCMoon	btcmoon
TER	TerraNova	terranova
IQT	iQuant	iquant
ELITE	Ethereum Lite	ethereum-lite
DEUS	DeusCoin	deuscoin
MCR	Macro	macro1
AKY	Akuya Coin	akuya-coin
MDC	Madcoin	madcoin
CUBIT	Cubits	cubits
POKE	PokeCoin	pokecoin
LEPEN	LePen	lepen
MINEX	Minex	minex
GRN	Granite	granitecoin
LDCN	LandCoin	landcoin
GOLF	Golfcoin	golfcoin
BTC2X	Bitcoin2x	bitcoin2x
ANTX	Antimatter	antimatter
GLS	GlassCoin	glasscoin
TCOIN	T-coin	t-coin
COUPE	Coupecoin	coupecoin
TELL	Tellurion	tellurion
FFC	FireFlyCoin	fireflycoin
IFC	Infinitecoin	infinitecoin
OCOW	OCOW	ocow
PRM	PrismChain	prismchain
BXC	Bitcedi	bitcedi
NBIT	netBit	netbit
CHEAP	Cheapcoin	cheapcoin
FUDD	DimonCoin	dimoncoin
HDLB	HODL Bucks	hodl-bucks
DBG	Digital Bullion Gold	digital-bullion-gold
ZSE	ZSEcoin	zsecoin
WSX	WeAreSatoshi	wearesatoshi
BUB	Bubble	bubble
RUNNERS	Runners	runners
INDIA	India Coin	india-coin
ELC	Elacoin	elacoin
VULC	Vulcano	vulcano
SKC	Skeincoin	skeincoin
CASHPOKERPRO	Cash Poker Pro	cash-poker-pro
CYDER	Cyder	cyder
MONETA	Moneta	moneta2
XQN	Quotient	quotient
TODAY	TodayCoin	todaycoin
HALLO	Halloween Coin	halloween-coin
DISK	DarkLisk	darklisk
BTCSILVER	Bitcoin Silver	bitcoin-silver
BITOK	Bitok	bitok
YES	Yescoin	yescoin
IRL	IrishCoin	irishcoin
QORA	Qora	qora
UAHPAY	UAHPay	uahpay
FAZZ	Fazzcoin	fazzcoin
UNRC	UniversalRoyalCoin	universalroyalcoin
GMX	GoldMaxCoin	goldmaxcoin
FAP	FAPcoin	fapcoin
XSTC	Safe Trade Coin	safe-trade-coin
PDG	PinkDog	pinkdog
DUTCH	Dutch Coin	dutch-coin
BLX	Blockchain Index	blockchain-index
STC	Santa Coin	santa-coin
HUNCOIN	Huncoin	huncoin
ACN	Avoncoin	avoncoin
IBTC	iBTC	ibtc
BITCF	First Bitcoin Capital	first-bitcoin-capital
BGR	Bongger	bongger
X2	X2	x2
REGA	Regacoin	regacoin
XOT	Internet of Things	internet-of-things
WA	WA Space	wa-space
APC	AlpaCoin	alpacoin
MAGN	Magnetcoin	magnetcoin
DCRE	DeltaCredits	deltacredits
BTBc	Bitbase	bitbase
EGOLD	eGold	egold
ASN	Aseancoin	aseancoin
PRIMU	Primulon	primulon
MMXVI	MMXVI	mmxvi
BIT	First Bitcoin	first-bitcoin
EVC	EventChain	eventchain
SFE	SafeCoin	safecoin
YEL	Yellow Token	yellow-token
EUSD	eUSD	eusd
LTH	LAthaan	lathaan
SND	Sand Coin	sand-coin
STEX	STEX	stex
CYC	Cycling Coin	cycling-coin
UNC	UNCoin	uncoin
UTA	UtaCoin	utacoin
SKULL	Pirate Blocks	pirate-blocks
ROYAL	RoyalCoin	royalcoin
BIRDS	Birds	birds
FRWC	FrankyWillCoin	frankywillcoin
CME	Cashme	cashme
OMC	Omicron	omicron
RUBIT	RubleBit	rublebit
HYPER	Hyper	hyper
BETACOIN	BetaCoin	betacoin
TRICK	TrickyCoin	trickycoin
TEAM	TeamUp	teamup
NTC	Natcoin	natcoin
TLE	TattooCoin (Limited)	tattoocoin-limited
BSN	Bastonet	bastonet
RUPXOLD	Rupaya [OLD]	rupaya-old
HYTV	Hyper TV	hyper-tv
10MT	10M Token	10mtoken
SPORT	SportsCoin	sportscoin
CC	CyberCoin	cybercoin
BLAZR	BlazerCoin	blazercoin
FBL	Faceblock	faceblock
XAU	Xaucoin	xaucoin
INTLDIAMOND	International Diamond	international-diamond
AV	AvatarCoin	avatarcoin
LAZ	Lazaruscoin	lazaruscoin
HCC	Happy Creator Coin	happy-creator-coin
9COIN	9COIN	9coin
FID	BITFID	bitfid
XVE	The Vegan Initiative	the-vegan-initiative
SNAKE	SnakeEyes	snakeeyes
KASHH	KashhCoin	kashhcoin
MAVRO	Mavro	mavro
TOPAZ	Topaz Coin	topaz
MONEY	MoneyCoin	moneycoin
FC	Facecoin	facecoin
ELTC2	eLTC	eltc
AXIOM	Axiom	axiom
DUB	Dubstep	dubstep
LKC	LinkedCoin	linkedcoin
TCR	TheCreed	thecreed
GML	GameLeagueCoin	gameleaguecoin
SHELL	ShellCoin	shellcoin
RHFC	RHFCoin	rhfcoin
PAYP	PayPeer	paypeer
MBL	MobileCash	mobilecash
EGG	EggCoin	eggcoin
EBIT	eBIT	ebit
VOYA	Voyacoin	voyacoin
IPY	Infinity Pay	infinity-pay
OP	Operand	operand
RICHX	RichCoin	richcoin
CBD	CBD Crystals	cbd-crystals
BAC	BitAlphaCoin	bitalphacoin
IVZ	InvisibleCoin	invisiblecoin
MEN	PeopleCoin	peoplecoin
FUTC	FutCoin	futcoin
OPES	Opescoin	opescoin
PSY	Psilocybin	psilocybin
TESLA	TeslaCoilCoin	teslacoilcoin
GARY	President Johnson	president-johnson
GBRC	Global Business Revolution	global-business-revolution
TERA	TeraCoin	teracoin
XDE2	XDE II	xde-ii
GUC	GoldUnionCoin	goldunioncoin
ADK	Aidos Kuneen	aidos-kuneen
XYLO	XYLO	xylo
CSC	CasinoCoin	casinocoin
BTU	Bitcoin Unlimited	bitcoin-unlimited
SWP	Swapcoin	swapcoin
QC	QCash	qcash
FRCT	Farstcoin	farstcoin
