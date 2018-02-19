package CryptoCurrency::Catalog;

our $DATE = '2018-02-10'; # DATE
our $VERSION = '20180210'; # VERSION

use 5.010001;
use strict;
use warnings;

my %by_symbol;
my %by_name_lc;
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
            $by_name_lc{lc $name}   = \@ff;
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
        unless my $rec = $by_name_lc{lc $name};
    return {
        name=>$rec->[1],
        symbol=>$rec->[0],
        safename=>$rec->[2],
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

This document describes version 20180210 of CryptoCurrency::Catalog (from Perl distribution CryptoCurrency-Catalog), released on 2018-02-10.

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
(L<https://coinmarketcap.com/>, or CMC for short).

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

L<CryptoExchange::Catalog>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
$$$	Money	money
10MT	10M Token	10mtoken
1337	Elite	1337coin
1ST	FirstBlood	firstblood
2GIVE	2GIVE	2give
300	300 Token	300-token
42	42-coin	42-coin
611	SixEleven	sixeleven
808	808Coin	808coin
888	OctoCoin	octocoin
8BIT	8Bit	8bit
AAC	Acute Angle Cloud	acute-angle-cloud
ABC	Alphabit	alphabitcoinfund
ABJ	Abjcoin	abjcoin
ABN	Abncoin	abncoin
ABY	ArtByte	artbyte
AC	AsiaCoin	asiacoin
ACC	Accelerator Network	accelerator-network
ACE	Ace	ace
ACES	Aces	aces
ACN	Avoncoin	avoncoin
ACOIN	Acoin	acoin
ACP	AnarchistsPrime	anarchistsprime
ACT	Achain	achain
ADA	Cardano	cardano
ADB	adbank	adbank
ADC	AudioCoin	audiocoin
ADCN	Asiadigicoin	asiadigicoin
ADCOIN	AdCoin	adcoin
ADK	Aidos Kuneen	aidos-kuneen
ADL	Adelphoi	adelphoi
ADST	AdShares	adshares
ADT	adToken	adtoken
ADX	AdEx	adx-net
ADZ	Adzcoin	adzcoin
AE	Aeternity	aeternity
AEON	Aeon	aeon
AERM	Aerium	aerium
AGI	SingularityNET	singularitynet
AGLC	AgrolifeCoin	agrolifecoin
AGRS	Agoras Tokens	agoras-tokens
AHT	Bowhead	bowhead
AI	POLY AI	poly-ai
AIB	Advanced Internet Blocks	advanced-internet-blocks
AID	AidCoin	aidcoin
AIDOC	AI Doctor	aidoc
AION	Aion	aion
AIR	AirToken	airtoken
AIT	AICHAIN	aichain
AIX	Aigang	aigang
AKY	Akuya Coin	akuya-coin
ALIS	ALIS	alis
ALL	Allion	allion
ALQO	ALQO	alqo
ALT	Altcoin	altcoin-alt
ALTC	Antilitecoin	antilitecoin
ALTCOM	SONO	altcommunity-coin
AMB	Ambrosus	amber
AMBER	AmberCoin	ambercoin
AMM	MicroMoney	micromoney
AMMO	Ammo Reloaded	ammo-rewards
AMP	Synereo	synereo
AMS	AmsterdamCoin	amsterdamcoin
ANC	Anoncoin	anoncoin
ANI	Animecoin	animecoin
ANT	Aragon	aragon
ANTI	AntiBitcoin	antibitcoin
ANTX	Antimatter	antimatter
APC	AlpaCoin	alpacoin
APPC	AppCoins	appcoins
APW	AppleCoin	applecoin-apw
APX	APX	apx
ARB	ARbit	arbit
ARC	ArcticCoin	arcticcoin
ARCO	AquariusCoin	aquariuscoin
ARCT	ArbitrageCT	arbitragect
ARDR	Ardor	ardor
ARG	Argentum	argentum
ARGUS	Argus	argus
ARI	Aricoin	aricoin
ARK	Ark	ark
ARN	Aeron	aeron
ART	Maecenas	maecenas
ARY	Block Array	block-array
ASAFE2	AllSafe	allsafe
ASN	Aseancoin	aseancoin
AST	AirSwap	airswap
ASTRO	Astro	astro
ATB	ATBCoin	atbcoin
ATL	ATLANT	atlant
ATM	ATMChain	attention-token-of-media
ATMC	ATMCoin	atmcoin
ATMS	Atmos	atmos
ATN	ATN	atn
ATOM	Atomic Coin	atomic-coin
ATS	Authorship	authorship
ATX	Artex Coin	artex-coin
AU	AurumCoin	aurumcoin
AUR	Auroracoin	auroracoin
AURA	Aurora DAO	aurora-dao
AV	AvatarCoin	avatarcoin
AVT	Aventus	aventus
AWR	AWARE	aware
AXIOM	Axiom	axiom
AXP	aXpire	axpire
B2B	B2B	b2bx
B2X	SegWit2x	segwit2x
B@	Bankcoin	bankcoin
BAC	BitAlphaCoin	bitalphacoin
BAR	Titanium Blockchain	titanium-blockchain
BAS	BitAsean	bitasean
BASH	LuckChain	luckchain
BAT	Basic Attention Token	basic-attention-token
BAY	BitBay	bitbay
BBP	BiblePay	biblepay
BBR	Boolberry	boolberry
BBT	BitBoost	bitboost
BCA	Bitcoin Atom	bitcoin-atom
BCAP	BCAP	bcap
BCC	BitConnect	bitconnect
BCD	Bitcoin Diamond	bitcoin-diamond
BCDN	BlockCDN	blockcdn
BCF	Bitcoin Fast	bitcoinfast
BCH	Bitcoin Cash	bitcoin-cash
BCN	Bytecoin	bytecoin-bcn
BCO	BridgeCoin	bridgecoin
BCPT	BlockMason Credit Protocol	blockmason
BCX	BitcoinX	bitcoinx
BCY	Bitcrystals	bitcrystals
BDG	BitDegree	bitdegree
BDL	Bitdeal	bitdeal
BELA	Bela	belacoin
BENJI	BenjiRolls	benjirolls
BERN	BERNcash	berncash
BEST	BestChain	bestchain
BET	DAO.Casino	dao-casino
BETACOIN	BetaCoin	betacoin
BIG	BigONE Token	bigone-token
BIGUP	BigUp	bigup
BIOB	BioBar	biobar
BIOS	BiosCrypto	bios-crypto
BIP	BipCoin	bipcoin
BIRDS	Birds	birds
BIS	Bismuth	bismuth
BIT	First Bitcoin	first-bitcoin
BITB	Bean Cash	bean-cash
BITBTC	bitBTC	bitbtc
BITCF	First Bitcoin Capital	first-bitcoin-capital
BITCLAVE	BitClave	bitclave
BITCNY	bitCNY	bitcny
BITEUR	bitEUR	biteur
BITGEM	Bitgem	bitgem
BITGOLD	bitGold	bitgold
BITMARK	Bitmark	bitmark
BITOK	Bitok	bitok
BITS	Bitstar	bitstar
BITSILVER	bitSilver	bitsilver
BITUSD	bitUSD	bitusd
BITZ	Bitz	bitz
BIX	Bibox Token	bibox-token
BKX	Bankex	bankex
BLAS	BlakeStar	blakestar
BLAZE	BlazeCoin	blazecoin
BLAZR	BlazerCoin	blazercoin
BLC	Blakecoin	blakecoin
BLITZ	Blitzcash	blitzcash
BLK	BlackCoin	blackcoin
BLN	Bolenum	bolenum
BLOCK	Blocknet	blocknet
BLOCKPAY	BlockPay	blockpay
BLRY	BillaryCoin	billarycoin
BLT	Bloom	bloomtoken
BLU	BlueCoin	bluecoin
BLUE	BLUE	ethereum-blue
BLX	Blockchain Index	blockchain-index
BLZ	Bluzelle	bluzelle
BMC	Blackmoon	blackmoon
BNB	Binance Coin	binance-coin
BNT	Bancor	bancor
BNTY	Bounty0x	bounty0x
BNX	BnrtxCoin	bnrtxcoin
BOAT	BOAT	doubloon
BOLI	Bolivarcoin	bolivarcoin
BON	Bonpay	bonpay
BOS	BOScoin	boscoin
BOT	Bodhi	bodhi
BPC	Bitpark Coin	bitpark-coin
BPL	Blockpool	blockpool
BPT	Blockport	blockport
BQ	bitqy	bitqy
BRAIN	Braincoin	braincoin
BRAT	BROTHER	brat
BRD	Bread	bread
BRIA	BriaCoin	briacoin
BRIT	BritCoin	britcoin
BRK	Breakout	breakout
BRO	Bitradio	bitradio
BRX	Breakout Stake	breakout-stake
BSC	BowsCoin	bowscoin
BSD	BitSend	bitsend
BSN	Bastonet	bastonet
BSR	BitSoar	bitsoar
BSTAR	Blackstar	blackstar
BSTY	GlobalBoost-Y	globalboost-y
BT2	BT2 [CST]	bt2-cst
BTA	Bata	bata
BTB	BitBar	bitbar
BTBc	Bitbase	bitbase
BTC	Bitcoin	bitcoin
BTC2X	Bitcoin2x	bitcoin2x
BTCA	Bitair	bitair
BTCD	BitcoinDark	bitcoindark
BTCL	Bitcoin Lightning	bitcoin-lightning
BTCM	BTCMoon	btcmoon
BTCR	Bitcurrency	bitcurrency
BTCRED	Bitcoin Red	bitcoin-red
BTCS	Bitcoin Scrypt	bitcoin-scrypt
BTCSILVER	Bitcoin Silver	bitcoin-silver
BTCZ	BitcoinZ	bitcoinz
BTDX	Bitcloud	bitcloud
BTE	BitSerial	bitserial
BTG	Bitcoin Gold	bitcoin-gold
BTM	Bytom	bytom
BTO	Bottos	bottos
BTPL	Bitcoin Planet	bitcoin-planet
BTQ	BitQuark	bitquark
BTS	BitShares	bitshares
BTSR	BTSR	btsr
BTW	Bitcoin White	bitcoin-white
BTWTY	Bit20	bit20
BTX	Bitcore	bitcore
BUB	Bubble	bubble
BUCKS	SwagBucks	swagbucks
BUMBA	BumbaCoin	bumbacoin
BUN	BunnyCoin	bunnycoin
BURST	Burst	burst
BUZZ	BuzzCoin	buzzcoin
BWK	Bulwark	bulwark
BXC	Bitcedi	bitcedi
BXT	BitTokens	bittokens
BYC	Bytecent	bytecent
C2	Coin2.1	coin2-1
C20	CRYPTO20	c20
CAB	Cabbage	cabbage
CACH	CacheCoin	cachecoin
CAG	Change	change
CALC	CaliphCoin	caliphcoin
CAN	CanYaCoin	canyacoin
CANDY	Candy	candy
CANETWORK	Content and AD Network	content-and-ad-network
CANN	CannabisCoin	cannabiscoin
CAPP	Cappasity	cappasity
CARBON	Carboncoin	carboncoin
CASH	Cashcoin	cashcoin
CASHPOKERPRO	Cash Poker Pro	cash-poker-pro
CAT	BlockCAT	blockcat
CATCOIN	Catcoin	catcoin
CBX	Crypto Bullion	cryptogenic-bullion
CC	CyberCoin	cybercoin
CCM100	CCMiner	ccminer
CCN	CannaCoin	cannacoin
CCO	Ccore	ccore
CCRB	CryptoCarbon	cryptocarbon
CCT	Crystal Clear 	crystal-clear
CDN	Canada eCoin	canada-ecoin
CDT	CoinDash	coindash
CDX	Commodity Ad Network	commodity-ad-network
CEFS	CryptopiaFeeShares	cryptopiafeeshares
CESC	CryptoEscudo	cryptoescudo
CF	Californium	californium
CFC	CoffeeCoin	coffeecoin
CFD	Confido	confido
CFI	Cofound.it	cofound-it
CFT	CryptoForecast	cryptoforecast
CFUN	CFun	cfun
CHAN	ChanCoin	chancoin
CHAT	ChatCoin	chatcoin
CHC	ChainCoin	chaincoin
CHEAP	Cheapcoin	cheapcoin
CHESS	ChessCoin	chesscoin
CHIPS	CHIPS	chips
CHSB	SwissBorg	swissborg
CJ	Cryptojacks	cryptojacks
CL	Coinlancer	coinlancer
CLAM	Clams	clams
CLD	Cloud	cloud
CLOAK	CloakCoin	cloakcoin
CLUB	ClubCoin	clubcoin
CME	Cashme	cashme
CMP	Compcoin	compcoin
CMPCO	CampusCoin	campuscoin
CMSETH	COMSA [ETH]	comsa-eth
CMSXEM	COMSA [XEM]	comsa-xem
CMT	CyberMiles	cybermiles
CND	Cindicator	cindicator
CNNC	Cannation	cannation
CNO	Coin(O)	coin
CNT	Centurion	centurion
CNX	Cryptonex	cryptonex
COAL	BitCoal	bitcoal
COB	Cobinhood	cobinhood
COFI	CoinFi	coinfi
COLX	ColossusCoinXT	colossuscoinxt
COMET	Comet	comet
CON	PayCon	paycon
CONX	Concoin	concoin
COR	CORION	corion
COSS	COSS	coss
COUPE	Coupecoin	coupecoin
COV	Covesting	covesting
COVAL	Circuits of Value	circuits-of-value
COXST	CoExistCoin	coexistcoin
CPAY	Cryptopay	cryptopay
CPC	Capricoin	capricoin
CPCHAIN	CPChain	cpchain
CPN	CompuCoin	compucoin
CRAVE	Crave	crave
CRB	Creditbit	creditbit
CRC	CrowdCoin	crowdcoin
CRDNC	Credence Coin	credence-coin
CREA	Creativecoin	creativecoin
CRED	Verify	verify
CREDO	Credo	credo
CREVA	CrevaCoin	crevacoin
CRM	Cream	cream
CRPT	Crypterium	crypterium
CRT	CRTCoin	crtcoin
CRTM	Corethum	corethum
CRW	Crown	crown
CRX	Chronos	chronos
CSC	CasinoCoin	casinocoin
CSNO	BitDice	bitdice
CTIC2	Coimatic 2.0	coimatic-2
CTIC3	Coimatic 3.0	coimatic-3
CTO	Crypto	crypto
CTR	Centra	centra
CTX	CarTaxi Token	cartaxi-token
CUBE	DigiCube	digicube
CUBIT	Cubits	cubits
CURE	Curecoin	curecoin
CV	carVertical	carvertical
CV2	Colossuscoin V2	colossuscoin-v2
CVC	Civic	civic
CVCOIN	CVCoin	cvcoin
CWXT	CryptoWorldX Token	cryptoworldx-token
CXO	CargoX	cargox
CXT	Coinonat	coinonat
CYC	Cycling Coin	cycling-coin
CYDER	Cyder	cyder
CYP	Cypher	cypher
DAI	Dai	dai
DALC	Dalecoin	dalecoin
DAR	Darcrus	darcrus
DASH	Dash	dash
DASHS	Dashs	dashs
DAT	Datum	datum
DATA	Streamr DATAcoin	streamr-datacoin
DAV	DavorCoin	davorcoin
DAXX	DaxxCoin	daxxcoin
DAY	Chronologic	chronologic
DBC	DeepBrain Chain	deepbrain-chain
DBET	DecentBet	decent-bet
DBG	Digital Bullion Gold	digital-bullion-gold
DBIX	DubaiCoin	dubaicoin-dbix
DBTC	Debitcoin	debitcoin
DCN	Dentacoin	dentacoin
DCR	Decred	decred
DCRE	DeltaCredits	deltacredits
DCT	DECENT	decent
DCY	Dinastycoin	dinastycoin
DDD	Scry.info	scryinfo
DDF	DigitalDevelopersFund	digital-developers-fund
DEM	Deutsche eMark	deutsche-emark
DENT	Dent	dent
DES	Destiny	destiny
DEUS	DeusCoin	deuscoin
DEW	DEW	dew
DFS	DFSCoin	dfscoin
DFT	DraftCoin	draftcoin
DGB	DigiByte	digibyte
DGC	Digitalcoin	digitalcoin
DGCS	Digital Credits	digital-credits
DGD	DigixDAO	digixdao
DGPT	DigiPulse	digipulse
DIBC	DIBCOIN	dibcoin
DICE	Etheroll	etheroll
DIM	DIMCOIN	dimcoin
DIME	Dimecoin	dimecoin
DISK	DarkLisk	darklisk
DIVX	Divi	divi
DIX	Dix Asset	dix-asset
DLC	Dollarcoin	dollarcoin
DLISK	DAPPSTER	dappster
DLT	Agrello	agrello-delta
DMB	Digital Money Bits	digital-money-bits
DMC	DynamicCoin	dynamiccoin
DMD	Diamond	diamond
DMT	DMarket	dmarket
DNA	EncrypGen	encrypgen
DNR	Denarius	denarius-dnr
DNT	district0x	district0x
DOGE	Dogecoin	dogecoin
DOLLAR	Dollar Online	dollar-online
DON	Donationcoin	donationcoin
DOPE	DopeCoin	dopecoin
DOT	Dotcoin	dotcoin
DOVU	Dovu	dovu
DP	DigitalPrice	digitalprice
DPY	Delphy	delphy
DRGN	Dragonchain	dragonchain
DRM	Dreamcoin	dreamcoin
DRP	DCORP	dcorp
DRPU	DRP Utility	drp-utility
DRS	Digital Rupees	digital-rupees
DRT	DomRaider	domraider
DRXNE	DROXNE	droxne
DSH	Dashcoin	dashcoin
DSR	Desire	desire
DTA	DATA	data
DTB	Databits	databits
DTR	Dynamic Trading Rights	dynamic-trading-rights
DUB	Dubstep	dubstep
DUBI	Decentralized Universal Basic Income	decentralized-universal-basic-income
DUO	ParallelCoin	parallelcoin
DUTCH	Dutch Coin	dutch-coin
DXT	Datawallet	datawallet
DYN	Dynamic	dynamic
EAC	EarthCoin	earthcoin
EAG	EA Coin	ea-coin
EAGLE	EagleCoin	eaglecoin
EBCH	eBitcoinCash	ebitcoin-cash
EBET	EthBet	ethbet
EBIT	eBIT	ebit
EBST	eBoost	eboostcoin
EBT	Ebittree Coin	ebittree-coin
EBTC	eBitcoin	ebtcnew
ECA	Electra	electra
ECASH	Ethereum Cash	ethereumcash
ECC	ECC	eccoin
ECN	E-coin	e-coin
ECO	EcoCoin	ecocoin
ECOB	Ecobit	ecobit
EDG	Edgeless	edgeless
EDO	Eidoo	eidoo
EDR	E-Dinar Coin	e-dinar-coin
EDRC	EDRCoin	edrcoin
EDT	EtherDelta Token	etherdelta-token
EFL	e-Gulden	e-gulden
EFYT	Ergo	ergo
EGAS	ETHGAS	ethgas
EGC	EverGreenCoin	evergreencoin
EGG	EggCoin	eggcoin
EGO	EGO	ego
EGOLD	eGold	egold
EKO	EchoLink	echolink
EKT	EDUCare	educare
EL	Elcoin	elcoin-el
ELA	Elastos	elastos
ELC	Elacoin	elacoin
ELE	Elementrem	elementrem
ELF	aelf	aelf
ELITE	Ethereum Lite	ethereum-lite
ELIX	Elixir	elixir
ELLA	Ellaism	ellaism
ELS	Elysium	elysium
ELTC2	eLTC	eltc
ELTCOIN	ELTCOIN	eltcoin
EMC	Emercoin	emercoin
EMC2	Einsteinium	einsteinium
EMD	Emerald Crypto	emerald
EMV	Ethereum Movie Venture	ethereum-movie-venture
ENG	Enigma Project	enigma-project
ENJ	Enjin Coin	enjin-coin
ENRG	Energycoin	energycoin
ENT	Eternity	eternity
ENTCASH	ENTCash	entcash
EOS	EOS	eos
EOT	EOT Token	eot-token
EPC	Electronic PK Chain	electronic-pk-chain
EPY	Emphy	emphy
EQL	Equal	equal
EQT	EquiTrader	equitrader
ERC	EuropeCoin	europecoin
ERC20	ERC20	erc20
EREAL	eREAL	ereal
ERO	Eroscoin	eroscoin
ERY	Eryllium	eryllium
ESC	Escroco	escoro
ESP	Espers	espers
ESZ	EtherSportz	ethersportz
ETBS	Ethbits	ethbits
ETC	Ethereum Classic	ethereum-classic
ETG	Ethereum Gold	ethereum-gold
ETH	Ethereum	ethereum
ETHD	Ethereum Dark	ethereum-dark
ETHOS	Ethos	ethos
ETN	Electroneum	electroneum
ETP	Metaverse ETP	metaverse
ETTETH	encryptotel-eth	encryptotel-eth
ETTWAVES	EncryptoTel [WAVES]	encryptotel
EUC	Eurocoin	eurocoin
EUSD	eUSD	eusd
EVC	EventChain	eventchain
EVE	Devery	devery
EVIL	Evil Coin	evil-coin
EVO	Evotion	evotion
EVR	Everus	everus
EVX	Everex	everex
EXCL	ExclusiveCoin	exclusivecoin
EXN	ExchangeN	exchangen
EXP	Expanse	expanse
EXRN	EXRNchain	exrnchain
FAIR	FairCoin	faircoin
FAIRGAME	FairGame	fairgame
FAP	FAPcoin	fapcoin
FAZZ	Fazzcoin	fazzcoin
FBL	Faceblock	faceblock
FC	Facecoin	facecoin
FC2	FuelCoin	fuelcoin
FCN	Fantomcoin	fantomcoin
FCT	Factom	factom
FDX	FidentiaX	fidentiax
FFC	FireFlyCoin	fireflycoin
FID	BITFID	bitfid
FIL	Filecoin [Futures]	filecoin
FIMK	FIMKrypto	fimkrypto
FIRE	Firecoin	firecoin
FJC	FujiCoin	fujicoin
FLAP	FlappyCoin	flappycoin
FLASH	Flash	flash
FLAX	Flaxscript	flaxscript
FLDC	FoldingCoin	foldingcoin
FLIK	FLiK	flik
FLIXX	Flixxo	flixxo
FLO	FlorinCoin	florincoin
FLT	FlutterCoin	fluttercoin
FLY	Flycoin	flycoin
FNC	FinCoin	fincoin
FONZ	Fonziecoin	fonziecoin
FOR	FORCE	force
FOTA	Fortuna	fortuna
FRC	Freicoin	freicoin
FRCT	Farstcoin	farstcoin
FRD	Farad	farad
FRGC	Fargocoin	fargocoin
FRK	Franko	franko
FRN	Francs	francs
FRST	FirstCoin	firstcoin
FRWC	FrankyWillCoin	frankywillcoin
FST	Fastcoin	fastcoin
FTC	Feathercoin	feathercoin
FUCK	FuckToken	fucktoken
FUEL	Etherparty	etherparty
FUN	FunFair	funfair
FUNC	FUNCoin	funcoin
FUTC	FutCoin	futcoin
FUZZ	FuzzBalls	fuzzballs
FXE	FuturXe	futurexe
FYN	FundYourselfNow	fundyourselfnow
FYP	FlypMe	flypme
G3N	G3N	genstake
GAIA	GAIA	gaia
GAIN	UGAIN	ugain
GAM	Gambit	gambit
GAME	GameCredits	gamecredits
GAME2	Game.com	game
GAP	Gapcoin	gapcoin
GARY	President Johnson	president-johnson
GAS	Gas	gas
GAT	Gatcoin	gatcoin
GAY	GAY Money	gaycoin
GB	GoldBlocks	goldblocks
GBC	GBCGoldCoin	gbcgoldcoin
GBG	Golos Gold	golos-gold
GBX	GoByte	gobyte
GBYTE	Byteball Bytes	byteball
GCC	TheGCCcoin	thegcccoin
GCN	GCN Coin	gcn-coin
GCR	Global Currency Reserve	global-currency-reserve
GCS	GameChain System	gamechain
GDC	GrandCoin	grandcoin
GEERT	GeertCoin	geertcoin
GET	GET Protocol	guts-tickets
GIM	Gimli	gimli
GJC	Global Jobcoin	global-jobcoin
GLC	GlobalCoin	globalcoin
GLD	GoldCoin	goldcoin
GLS	GlassCoin	glasscoin
GLT	GlobalToken	globaltoken
GML	GameLeagueCoin	gameleaguecoin
GMT	Mercury Protocol	mercury-protocol
GMX	GoldMaxCoin	goldmaxcoin
GNO	Gnosis	gnosis-gno
GNT	Golem	golem-network-tokens
GNX	Genaro Network	genaro-network
GOD	Bitcoin God	bitcoin-god
GOLF	Golfcoin	golfcoin
GOLOS	Golos	golos
GOOD	Goodomy	goodomy
GP	GoldPieces	goldpieces
GPL	Gold Pressed Latinum	gold-pressed-latinum
GPU	GPU Coin	gpu-coin
GRC	GridCoin	gridcoin
GRE	Greencoin	greencoin
GRID	Grid+	grid
GRIM	Grimcoin	grimcoin
GRLC	Garlicoin	garlicoin
GRN	Granite	granitecoin
GRS	Groestlcoin	groestlcoin
GRWI	Growers International	growers-international
GRX	GOLD Reward Token	gold-reward-token
GSR	GeyserCoin	geysercoin
GTC	Global Tour Coin	global-tour-coin
GTO	Gifto	gifto
GUCCIONE	GuccioneCoin	guccionecoin
GUN	Guncoin	guncoin
GUP	Matchpool	guppy
GVT	Genesis Vision	genesis-vision
GXS	GXShares	gxshares
HAC	Hackspace Capital	hackspace-capital
HAL	Halcyon	halcyon
HALLO	Halloween Coin	halloween-coin
HAT	Hawala.Today	hawala-today
HBC	HomeBlockCoin	homeblockcoin
HBN	HoboNickels	hobonickels
HBT	Hubii Network	hubii-network
HC	Harvest Masternode Coin	harvest-masternode-coin
HCC	Happy Creator Coin	happy-creator-coin
HDG	Hedge	hedge
HDLB	HODL Bucks	hodl-bucks
HEAT	HEAT	heat-ledger
HERO	Sovereign Hero	sovereign-hero
HGT	HelloGold	hellogold
HIGH	High Gain	high-gain
HKN	Hacken	hacken
HLC	HalalChain	halalchain
HMC	HarmonyCoin	harmonycoin-hmc
HMP	HempCoin (HMP)	hempcoin-hmp
HMQ	Humaniq	humaniq
HMSC	Health Mutual Society	health-mutual-society
HNC	Helleniccoin	helleniccoin
HODL	HOdlcoin	hodlcoin
HOLD	Interstellar Holdings	interstellar-holdings
HONEY	Honey	honey
HORSE	Ethorse	ethorse
HOT	Hydro Protocol	hydro-protocol
HPB	High Performance Blockchain	high-performance-blockchain
HPC	Happycoin	happycoin
HPY	Hyper Pay	hyper-pay
HSR	Hshare	hshare
HST	Decision Token	decision-token
HT	Huobi Token	huobi-token
HTC	HitCoin	hitcoin
HTML	HTMLCOIN	html-coin
HTML5	HTML5COIN	htmlcoin
HUC	HunterCoin	huntercoin
HUNCOIN	Huncoin	huncoin
HUSH	Hush	hush
HVCO	High Voltage	high-voltage
HVN	Hive	hive
HWC	HollyWoodCoin	hollywoodcoin
HXX	Hexx	hexx
HYP	HyperStake	hyperstake
HYPER	Hyper	hyper
HYTV	Hyper TV	hyper-tv
I0C	I0Coin	i0coin
IBANK	iBank	ibank
IBTC	iBTC	ibtc
IC	Ignition	ignition
ICE	iDice	idice
ICN	Iconomi	iconomi
ICOB	ICOBID	icobid
ICOIN	iCoin	icoin
ICON	Iconic	iconic
ICOO	ICO OpenLedger	ico-openledger
ICOS	ICOS	icos
ICX	ICON	icon
IDH	indaHash	indahash
IDT	InvestDigital	investdigital
IDXM	IDEX Membership	idex-membership
IETH	iEthereum	iethereum
IFC	Infinitecoin	infinitecoin
IFLT	InflationCoin	inflationcoin
IFT	InvestFeed	investfeed
IGNIS	Ignis	ignis
IMPS	ImpulseCoin	impulsecoin
IMS	Independent Money System	independent-money-system
IMX	Impact	impact
INCNT	Incent	incent
IND	Indorse Token	indorse-token
INDIA	India Coin	india-coin
INF	InfChain	infchain
INFX	Influxcoin	influxcoin
ING	Iungo	iungo
INK	Ink	ink
INN	Innova	innova
INPAY	InPay	inpay
INS	INS Ecosystem	ins-ecosystem
INSN	InsaneCoin	insanecoin-insn
INT	Internet Node Token	internet-node-token
INTLDIAMOND	International Diamond	international-diamond
INXT	Internxt	internxt
IOC	I/O Coin	iocoin
ION	ION	ion
IOP	Internet of People	internet-of-people
IOST	IOStoken	iostoken
IPC	IPChain	ipchain
IPL	InsurePal	insurepal
IPY	Infinity Pay	infinity-pay
IQT	iQuant	iquant
IRL	IrishCoin	irishcoin
ISL	IslaCoin	islacoin
ITC	IoT Chain	iot-chain
ITI	iTicoin	iticoin
ITNS	IntenseCoin	intensecoin
ITT	Intelligent Trading Tech	intelligent-trading-tech
IVZ	InvisibleCoin	invisiblecoin
IXC	Ixcoin	ixcoin
IXT	iXledger	ixledger
J	Joincoin	joincoin
JET	Jetcoin	jetcoin
JIN	Jin Coin	jin-coin
JINN	Jinn	jinn
JIYO	Jiyo	jiyo
JNS	Janus	janus
JNT	Jibrel Network	jibrel-network
JOBS	JobsCoin	jobscoin
JS	JavaScript Token	javascript-token
JWL	Jewels	jewels
KARMA	Karmacoin	karmacoin
KASHH	KashhCoin	kashhcoin
KAYI	Kayicoin	kayicoin
KB3	B3Coin	b3coin
KBR	Kubera Coin	kubera-coin
KCASH	Kcash	kcash
KCS	KuCoin Shares	kucoin-shares
KDC	KlondikeCoin	klondikecoin
KED	Darsek	darsek
KEK	KekCoin	kekcoin
KEY	Selfkey	selfkey
KICK	KickCoin	kickico
KIN	Kin	kin
KINGN	KingN Coin	kingn-coin
KLC	KiloCoin	kilocoin
KLN	Kolion	kolion
KMD	Komodo	komodo
KNC	Kyber Network	kyber-network
KOBO	Kobocoin	kobocoin
KORE	Kore	korecoin
KRB	Karbo	karbowanec
KRM	Karma	karma
KRONE	Kronecoin	kronecoin
KURT	Kurrent	kurrent
KUSH	KushCoin	kushcoin
KZC	Kzcash	kzcash
LA	LAToken	latoken
LANA	LanaCoin	lanacoin
LAZ	Lazaruscoin	lazaruscoin
LBC	LBRY Credits	library-credit
LBTC	LiteBitcoin	litebitcoin
LCP	Litecoin Plus	litecoin-plus
LCT	LendConnect	lendconnect
LDCN	LandCoin	landcoin
LDOGE	LiteDoge	litedoge
LEA	LeaCoin	leacoin
LEND	ETHLend	ethlend
LEO	LEOcoin	leocoin
LEPEN	LePen	lepen
LET	LinkEye	linkeye
LEV	Leverj	leverj
LGD	Legends Room	legends-room
LIFE	LIFE	life
LIGHT	LightChain	lightchain
LIGHTNINGBTC	Lightning Bitcoin	lightning-bitcoin
LINDA	Linda	linda
LINK	ChainLink	chainlink
LINX	Linx	linx
LIR	LetItRide	letitride
LKC	LinkedCoin	linkedcoin
LKK	Lykke	lykke
LLT	LLToken	lltoken
LMC	LoMoCoin	lomocoin
LNK	Link Platform	link-platform
LOC	LockChain	lockchain
LOG	Woodcoin	woodcoin
LRC	Loopring	loopring
LSK	Lisk	lisk
LTB	LiteBar	litebar
LTC	Litecoin	litecoin
LTCR	Litecred	litecred
LTCU	LiteCoin Ultra	litecoin-ultra
LTG	LiteCoin Gold	litecoin-gold
LTH	LAthaan	lathaan
LUN	Lunyr	lunyr
LUNA	Luna Coin	luna-coin
LUX	LUXCoin	luxcoin
LVPS	LevoPlus	levoplus
MAC	Machinecoin	machinecoin
MAD	SatoshiMadness	satoshimadness
MAG	Magnet	magnet
MAGE	MagicCoin	magiccoin
MAGGIE	Maggie	maggie
MAGN	Magnetcoin	magnetcoin
MAID	MaidSafeCoin	maidsafecoin
MAN	Matrix AI Network	matrix-ai-network
MANA	Decentraland	decentraland
MAO	Mao Zedong	mao-zedong
MAR	Marijuanacoin	marijuanacoin
MARS	Marscoin	marscoin
MARX	MarxCoin	marxcoin
MAX	MaxCoin	maxcoin
MAY	Theresa May Coin	theresa-may-coin
MBI	Monster Byte	monster-byte
MBL	MobileCash	mobilecash
MBRS	Embers	embers
MCAP	MCAP	mcap
MCI	Musiconomi	musiconomi
MCO	Monaco	monaco
MCR	Macro	macro1
MCRN	MACRON	macron
MDA	Moeda Loyalty Points	moeda-loyalty-points
MDC	Madcoin	madcoin
MDS	MediShares	medishares
MDT	Measurable Data Token	measurable-data-token
MEC	Megacoin	megacoin
MED	MediBloc	medibloc
MEE	CoinMeet	coinmeet
MEME	Memetic (PepeCoin)	memetic
MEN	PeopleCoin	peoplecoin
MER	Mercury	mercury
METAL	MetalCoin	metalcoin
MGC	MergeCoin	mergecoin
MGM	Magnum	magnum
MGO	MobileGo	mobilego
MILO	MiloCoin	milocoin
MINEX	Minex	minex
MINT	Mintcoin	mintcoin
MIOTA	IOTA	iota
MIXIN	Mixin	mixin
MKR	Maker	maker
MLN	Melon	melon
MMXVI	MMXVI	mmxvi
MNC	Mincoin	mincoin
MND	MindCoin	mindcoin
MNE	Minereum	minereum
MNM	Mineum	mineum
MNTP	GoldMint	goldmint
MNX	MinexCoin	minexcoin
MOAC	MOAC	moac
MOBI	Mobius	mobius
MOD	Modum	modum
MOF	Molecular Future	molecular-future
MOIN	Moin	moin
MOJO	MojoCoin	mojocoin
MONA	MonaCoin	monacoin
MONETA	Moneta	moneta2
MONEY	MoneyCoin	moneycoin
MONK	Monkey Project	monkey-project
MOON	Mooncoin	mooncoin
MOT	Olympus Labs	olympus-labs
MOTO	Motocoin	motocoin
MRJA	GanjaCoin	ganjacoin
MRT	Miners' Reward Token	miners-reward-token
MSCN	Master Swiscoin	master-swiscoin
MSD	MSD	msd
MSP	Mothership	mothership
MST	MustangCoin	mustangcoin
MTH	Monetha	monetha
MTL	Metal	metal
MTLMC3	Metal Music Coin	metal-music-coin
MTN	Medicalchain	medical-chain
MTNC	Masternodecoin	masternodecoin
MTX	Matryx	matryx
MUE	MonetaryUnit	monetaryunit
MUSIC	Musicoin	musicoin
MVC	Maverick Chain	maverick-chain
MXT	MarteXcoin	martexcoin
MYB	MyBit Token	mybit-token
MYST	Mysterium	mysterium
MZC	MAZA	mazacoin
NAMO	NamoCoin	namocoin
NANOX	Project-X	project-x
NAS	Nebulas	nebulas-token
NAV	NAV Coin	nav-coin
NBIT	netBit	netbit
NDC	NEVERDIE	neverdie
NEBL	Neblio	neblio
NEO	NEO	neo
NEOG	NEO GOLD	neo-gold
NEOS	NeosCoin	neoscoin
NET	Nimiq	nimiq
NETCOIN	NetCoin	netcoin
NETKO	Netko	netko
NEU	Neumark	neumark
NEVA	NevaCoin	nevacoin
NEWB	Newbium	newbium
NGC	NAGA	naga
NIMFA	Nimfamoney	nimfamoney
NIO	Autonio	autonio
NKA	IncaKoin	incakoin
NKC	Nework	nework
NLC2	NoLimitCoin	nolimitcoin
NLG	Gulden	gulden
NMC	Namecoin	namecoin
NMR	Numeraire	numeraire
NMS	Numus	numus
NOBL	NobleCoin	noblecoin
NODC	NodeCoin	nodecoin
NOTE	DNotes	dnotes
NOX	Nitro	nitro
NRO	Neuro	neuro
NSR	NuShares	nushares
NTC	Natcoin	natcoin
NTO	Fujinto	fujinto
NTRN	Neutron	neutron
NTWK	Network Token	network-token
NUKO	Nekonium	nekonium
NULS	Nuls	nuls
NUMUS	NumusCash	numuscash
NVC	Novacoin	novacoin
NVST	NVO	nvo
NXC	Nexium	nexium
NXS	Nexus	nexus
NXT	Nxt	nxt
NYAN	Nyancoin	nyancoin
NYC	NewYorkCoin	newyorkcoin
OAX	OAX	oax
OBITS	OBITS	obits
OC	OceanChain	oceanchain
OCL	Oceanlab	oceanlab
OCN	Odyssey	odyssey
OCT	OracleChain	oraclechain
ODN	Obsidian	obsidian
OF	OFCOIN	ofcoin
OFF	Cthulhu Offerings	cthulhu-offerings
OK	OKCash	okcash
OMC	Omicron	omicron
OMG	OmiseGO	omisego
OMNI	Omni	omni
ONG	onG.social	ongsocial
ONION	DeepOnion	deeponion
ONX	Onix	onix
OP	Operand	operand
OPAL	Opal	opal
OPC	OP Coin	op-coin
OPES	Opescoin	opescoin
OPT	Opus	opus
ORB	Orbitcoin	orbitcoin
ORE	Galactrum	galactrum
ORLY	Orlycoin	orlycoin
ORME	Ormeus Coin	ormeus-coin
OS76	OsmiumCoin	osmiumcoin
OST	Simple Token	simple-token
OTN	Open Trading Network	open-trading-network
OTX	Octanox	octanox
OX	OX Fina	ox-fina
OXY	Oxycoin	oxycoin
P7C	P7Coin	p7coin
PAC	PACcoin	paccoin
PAK	Pakcoin	pakcoin
PARETO	Pareto Network	pareto-network
PART	Particl	particl
PASC	Pascal Coin	pascal-coin
PASL	Pascal Lite	pascal-lite
PAY	TenX	tenx
PAYP	PayPeer	paypeer
PAYX	Paypex	paypex
PBL	Publica	publica
PBT	Primalbase Token	primalbase
PCN	PeepCoin	peepcoin
PCOIN	Pioneer Coin	pioneer-coin
PCS	Pabyosi Coin Special	pabyosi-coin-special
PDC	Project Decorum	project-decorum
PDG	PinkDog	pinkdog
PEC	Peacecoin	peacecoin
PEPECASH	Pepe Cash	pepe-cash
PEX	PosEx	posex
PFR	Payfair	payfair
PGL	Prospectors Gold	prospectors-gold
PHO	Photon	photon
PHR	Phore	phore
PHS	Philosopher Stones	philosopher-stones
PIE	PIECoin	piecoin
PIGGY	Piggycoin	piggycoin
PING	CryptoPing	cryptoping
PINK	PinkCoin	pinkcoin
PIPL	PiplCoin	piplcoin
PIRL	Pirl	pirl
PIVX	PIVX	pivx
PIX	Lampix	lampix
PIZZA	PizzaCoin	pizzacoin
PKB	ParkByte	parkbyte
PKT	Playkey	playkey
PLACO	PlayerCoin	playercoin
PLAY	HEROcoin	herocoin
PLBT	Polybius	polybius
PLC	PlusCoin	pluscoin
PLNC	PLNcoin	plncoin
PLR	Pillar	pillar
PLU	Pluton	pluton
PLX	PlexCoin	plexcoin
PND	Pandacoin	pandacoin-pnd
PNX	Phantomx	phantomx
POE	Po.et	poet
POKE	PokeCoin	pokecoin
POLIS	Polis	polis
POLL	ClearPoll	clearpoll
POLY	Polymath Network	polymath-network
PONZI	PonziCoin	ponzicoin
POP	PopularCoin	popularcoin
POS	PoSToken	postoken
POST	PostCoin	postcoin
POSW	PoSW Coin	posw-coin
POT	PotCoin	potcoin
POWR	Power Ledger	power-ledger
PPC	Peercoin	peercoin
PPP	PayPie	paypie
PPT	Populous	populous
PPY	Peerplays	peerplays-ppy
PR	Prototanium	prototanium
PRC	PRCoin	prcoin
PRE	Presearch	presearch
PRES	President Trump	president-trump
PRG	Paragon	paragon
PRIMU	Primulon	primulon
PRIX	Privatix	privatix
PRL	Oyster	oyster
PRM	PrismChain	prismchain
PRN	Protean	protean
PRO	Propy	propy
PROCHAIN	ProChain	prochain
PROCURRENCY	ProCurrency	procurrency
PRS	PressOne	pressone
PRX	Printerium	printerium
PST	Primas	primas
PSY	Psilocybin	psilocybin
PTC	Pesetacoin	pesetacoin
PTOY	Patientory	patientory
PULSE	Pulse	pulse
PURA	Pura	pura
PURE	Pure	pure
PUT	PutinCoin	putincoin
PUTOKEN	Profile Utility Token	profile-utility-token
PX	PX	px
PXC	Phoenixcoin	phoenixcoin
PXI	Prime-XI	prime-xi
PXS	Pundi X	pundi-x
PYLNT	Pylon Network	pylon-network
PZM	PRIZM	prizm
Q2C	QubitCoin	qubitcoin
QASH	QASH	qash
QAU	Quantum	quantum
QBC	Quebecoin	quebecoin
QBIC	Qbic	qbic
QBT	Qbao	qbao
QCN	QuazarCoin	quazarcoin
QLC	QLINK	qlink
QORA	Qora	qora
QRK	Quark	quark
QRL	Quantum Resistant Ledger	quantum-resistant-ledger
QSP	Quantstamp	quantstamp
QTL	Quatloo	quatloo
QTUM	Qtum	qtum
QUBE	Qube	qube
QUN	QunQun	qunqun
QVT	Qvolta	qvolta
QWARK	Qwark	qwark
R	Revain	revain
RADS	Radium	radium
RAIN	Condensate	condensate
RBBT	RabbitCoin	rabbitcoin
RBIES	Rubies	rubies
RBT	Rimbit	rimbit
RBX	Ripto Bux	ripto-bux
RBY	Rubycoin	rubycoin
RC	RussiaCoin	russiacoin
RCN	Ripio Credit Network	ripio-credit-network
RCOIN	Rcoin	rcoin
RCT	RealChain	realchain
RDD	ReddCoin	reddcoin
RDN	Raiden Network Token	raiden-network-token
READ	Read	read
REAL	REAL	real
REBL	Rebellious	rebellious
REC	Regalcoin	regalcoin
RED	RedCoin	redcoin
REE	ReeCoin	reecoin
REF	RefToken	reftoken
REGA	Regacoin	regacoin
REMI	Remicoin	remicoin
REP	Augur	augur
REQ	Request Network	request-network
REX	REX	real-estate-tokens
RHFC	RHFCoin	rhfcoin
RHOC	RChain	rchain
RIC	Riecoin	riecoin
RICHX	RichCoin	richcoin
RIDE	Ride My Car	ride-my-car
RISE	Rise	rise
RIYA	Etheriya	etheriya
RKC	Royal Kingdom Coin	royal-kingdom-coin
RLC	iExec RLC	rlc
RLT	RouletteToken	roulettetoken
RMC	Russian Mining Coin	russian-mining-coin
RNS	Renos	renos
RNT	OneRoot Network	oneroot-network
ROC	Rasputin Online Coin	rasputin-online-coin
ROOFS	Roofs	roofs
RPC	RonPaulCoin	ronpaulcoin
RPX	Red Pulse	red-pulse
RSGP	RSGPcoin	rsgpcoin
RUBIT	RubleBit	rublebit
RUFF	Ruff	ruff
RUNNERS	Runners	runners
RUP	Rupee	rupee
RUPX	Rupaya	rupaya
RUPXOLD	Rupaya [OLD]	rupaya-old
RUSTBITS	Rustbits	rustbits
RVT	Rivetz	rivetz
RYZ	ANRYZE	anryze
SAC	SACoin	sacoin
SAFEX	Safe Exchange Coin	safe-exchange-coin
SAGA	SagaCoin	sagacoin
SAK	Sharkcoin	sharkcoin
SALT	SALT	salt
SAN	Santiment Network Token	santiment
SANDG	Save and Gain	save-and-gain
SBC	StrikeBitClub	strikebitclub
SBD	Steem Dollars	steem-dollars
SBTC	Super Bitcoin	super-bitcoin
SC	Siacoin	siacoin
SCL	Social	social
SCORE	Scorecoin	scorecoin
SCRT	SecretCoin	secretcoin
SCS	Speedcash	speedcash
SCT	Soma	soma
SDC	ShadowCash	shadowcash
SDP	SydPak	sydpak
SDRN	Senderon	senderon
SEND	Social Send	social-send
SENSE	Sense	sense
SEQ	Sequence	sequence
SEXC	ShareX	sharex
SFC	Solarflarecoin	solarflarecoin
SFE	SafeCoin	safecoin
SGR	Sugar Exchange	sugar-exchange
SH	Shilling	shilling
SHA	SHACoin	shacoin
SHDW	Shadow Token	shadow-token
SHELL	ShellCoin	shellcoin
SHIFT	Shift	shift
SHND	StrongHands	stronghands
SHORTY	Shorty	shorty
SHOW	Show	show
SIB	SIBCoin	sibcoin
SIC	Swisscoin	swisscoin
SIFT	Smart Investment Fund Token	smart-investment-fund-token
SIGMA	SIGMAcoin	sigmacoin
SIGT	Signatum	signatum
SISA	SISA	sisa
SJCX	Storjcoin X	storjcoin-x
SKC	Skeincoin	skeincoin
SKIN	SkinCoin	skincoin
SKR	Sakuracoin	sakuracoin
SKULL	Pirate Blocks	pirate-blocks
SKY	Skycoin	skycoin
SLEVIN	Slevin	slevin
SLFI	Selfiecoin	selfiecoin
SLG	Sterlingcoin	sterlingcoin
SLR	SolarCoin	solarcoin
SLS	SaluS	salus
SLT	Smartlands	smartlands
SMART	SmartCash	smartcash
SMARTBILLIONS	SmartBillions	smartbillions
SMC	SmartCoin	smartcoin
SMLY	SmileyCoin	smileycoin
SMS	Speed Mining Service	speed-mining-service
SMT	SmartMesh	smartmesh
SNAKE	SnakeEyes	snakeeyes
SNC	SunContract	suncontract
SND	Sand Coin	sand-coin
SNGLS	SingularDTV	singulardtv
SNM	SONM	sonm
SNOV	Snovio	snovio
SNRG	Synergy	synergy
SNT	Status	status
SOAR	Soarcoin	soarcoin
SOC	All Sports	all-sports
SOCC	SocialCoin	socialcoin-socc
SOIL	SOILcoin	soilcoin
SOJ	Sojourn	sojourn
SONG	SongCoin	songcoin
SOON	SoonCoin	sooncoin
SPACE	SpaceCoin	spacecoin
SPANK	SpankChain	spankchain
SPC	SpaceChain	spacechain
SPEX	SproutsExtreme	sproutsextreme
SPF	SportyCo	sportyco
SPHR	Sphere	sphere
SPHTX	SophiaTX	sophiatx
SPK	Sparks	sparks
SPORT	SportsCoin	sportscoin
SPR	SpreadCoin	spreadcoin
SPRTS	Sprouts	sprouts
SPT	Spots	spots
SRC	SecureCoin	securecoin
SRN	SIRIN LABS Token	sirin-labs-token
SSC	SelfSell	selfsell
SSS	Sharechain	sharechain
STA	Starta	starta
STAK	STRAKS	straks
STAR	Starbase	starbase
STARS	StarCash Network	starcash-network
START	Startcoin	startcoin
STC	StarChain	starchain
STEEM	Steem	steem
STEPS	Steps	steps
STEX	STEX	stex
STK	STK	stk
STN	Steneum Coin	steneum-coin
STORJ	Storj	storj
STORM	Storm	storm
STRAT	Stratis	stratis
STRC	StarCredits	starcredits
STU	bitJob	student-coin
STV	Sativacoin	sativacoin
STX	Stox	stox
SUB	Substratum	substratum
SUMO	Sumokoin	sumokoin
SUPER	SuperCoin	supercoin
SUR	Suretly	suretly
SWFTC	SwftCoin	swftcoin
SWING	Swing	swing
SWM	Swarm	swarm-fund
SWP	Swapcoin	swapcoin
SWT	Swarm City	swarm-city
SWTC	Jingtum Tech	jingtum-tech
SXC	Sexcoin	sexcoin
SXDT	Spectre.ai Dividend Token	spectre-dividend
SXUT	Spectre.ai Utility	spectre-utility
SYNX	Syndicate	syndicate
SYS	Syscoin	syscoin
TAAS	TaaS	taas
TAG	TagCoin	tagcoin
TAGR	TAGRcoin	tagrcoin
TAJ	TajCoin	tajcoin
TALK	BTCtalkcoin	btctalkcoin
TAU	Lamden	lamden
TBX	Tokenbox	tokenbox
TCC	The ChampCoin	the-champcoin
TCOIN	T-coin	t-coin
TCR	TheCreed	thecreed
TCT	TokenClub	tokenclub
TEAM	TeamUp	teamup
TEK	TEKcoin	tekcoin
TEL	Telcoin	telcoin
TELL	Tellurion	tellurion
TER	TerraNova	terranova
TERA	TeraCoin	teracoin
TES	TeslaCoin	teslacoin
TESLA	TeslaCoilCoin	teslacoilcoin
TFL	TrueFlip	trueflip
TGC	Tigercoin	tigercoin
TGT	Target Coin	target-coin
THC	HempCoin	hempcoin
THETA	Theta Token	theta-token
THS	TechShares	techshares
TIE	TIES Network	ties-network
TIME	Chronobank	chronobank
TIO	Trade Token	trade-token
TIPS	FedoraCoin	fedoracoin
TIT	Titcoin	titcoin
TIX	Blocktix	blocktix
TKN	TokenCard	tokencard
TKR	CryptoInsight	trackr
TKS	Tokes	tokes
TKY	THEKEY	thekey
TLE	TattooCoin (Limited)	tattoocoin-limited
TMC	TimesCoin	timescoin
TNB	Time New Bank	time-new-bank
TNC	Trinity Network Credit	trinity-network-credit
TNT	Tierion	tierion
TOA	ToaCoin	toacoin
TODAY	TodayCoin	todaycoin
TOK	Tokugawa	tokugawa
TOKC	TOKYO	tokyo
TOP	TopCoin	topcoin
TOPAZ	Topaz Coin	topaz
TOPC	TopChain	topchain
TOR	Torcoin	torcoin-tor
TRAC	OriginTrail	origintrail
TRC	Terracoin	terracoin
TRCT	Tracto	tracto
TRDT	Trident Group	trident
TRF	Travelflex	travelflex
TRI	Triangles	triangles
TRIA	Triaconta	triaconta
TRICK	TrickyCoin	trickycoin
TRIG	Triggers	triggers
TRK	Truckcoin	truckcoin
TROLL	Trollcoin	trollcoin
TRST	WeTrust	trust
TRUE	True Chain	true-chain
TRUMP	TrumpCoin	trumpcoin
TRUST	TrustPlus	trustplus
TRX	TRON	tron
TSE	TattooCoin (Standard Edition)	tattoocoin
TSL	Energo	energo
TSTR	Tristar Coin	tristar-coin
TTC	TittieCoin	tittiecoin
TURBO	TurboCoin	turbocoin
TX	TransferCoin	transfercoin
TYCHO	Tychocoin	tychocoin
TZC	TrezarCoin	trezarcoin
UAHPAY	UAHPay	uahpay
UBQ	Ubiq	ubiq
UBTC	United Bitcoin	united-bitcoin
UCASH	U.CASH	ucash
UET	Useless Ethereum Token	useless-ethereum-token
UFO	UFO Coin	ufo-coin
UFR	Upfiring	upfiring
UGC	ugChain	ugchain
UGT	UG Token	ug-token
UIP	UnlimitedIP	unlimitedip
UIS	Unitus	unitus
UKG	Unikoin Gold	unikoin-gold
ULA	Ulatech	ulatech
UNB	UnbreakableCoin	unbreakablecoin
UNC	UNCoin	uncoin
UNI	Universe	universe
UNIC	UniCoin	unicoin
UNIFY	Unify	unify
UNIT	Universal Currency	universal-currency
UNITS	GameUnits	gameunits
UNITY	SuperNET	supernet-unity
UNO	Unobtanium	unobtanium
UNRC	UniversalRoyalCoin	universalroyalcoin
UNY	Unity Ingot	unity-ingot
UQC	Uquid Coin	uquid-coin
UR	UR	ur
URC	Unrealcoin	unrealcoin
URO	Uro	uro
USC	Ultimate Secure Cash	ultimate-secure-cash
USDT	Tether	tether
USNBT	NuBits	nubits
UTA	UtaCoin	utacoin
UTC	UltraCoin	ultracoin
UTK	UTRUST	utrust
UTT	United Traders Token	uttoken
V	Version	version
VAL	Valorbit	valorbit
VASH	VPNCoin	vpncoin
VC	VirtualCoin	virtualcoin
VEC2	VectorAI	vector
VEE	BLOCKv	blockv
VEN	VeChain	vechain
VERI	Veritaseum	veritaseum
VIA	Viacoin	viacoin
VIB	Viberate	viberate
VIBE	VIBE	vibe
VIDZ	PureVidz	purevidz
VIP	VIP Tokens	vip-tokens
VISIO	Visio	visio
VIU	Viuly	viuly
VIVO	VIVO	vivo
VLC	ValueChain	valuechain
VLT	Veltor	veltor
VLTC	Vault Coin	vault-coin
VOISE	Voise	voisecom
VOLT	Bitvolt	bitvolt
VOT	VoteCoin	votecoin
VOX	Voxels	voxels
VOYA	Voyacoin	voyacoin
VPRC	VapersCoin	vaperscoin
VRC	VeriCoin	vericoin
VRM	VeriumReserve	veriumreserve
VRS	Veros	veros
VSL	vSlice	vslice
VSX	Vsync	vsync-vsx
VTA	Virtacoin	virtacoin
VTC	Vertcoin	vertcoin
VTR	vTorrent	vtorrent
VUC	Virta Unique Coin	virta-unique-coin
VULC	Vulcano	vulcano
VZT	Vezt	vezt
WA	WA Space	wa-space
WABI	WaBi	wabi
WAND	WandX	wandx
WARP	WARP	warp
WAVES	Waves	waves
WAX	WAX	wax
WAY	WayGuide	wayguide
WAYKI	WaykiChain	waykichain
WBB	Wild Beast Block	wild-beast-block
WC	WINCOIN	win-coin
WCT	Waves Community Token	waves-community-token
WDC	WorldCoin	worldcoin
WETH	WETH	weth
WGO	WavesGo	wavesgo
WGR	Wagerr	wagerr
WHL	WhaleCoin	whalecoin
WIC	Wi Coin	wi-coin
WILD	Wild Crypto	wild-crypto
WINGS	Wings	wings
WINK	Wink	wink
WISH	MyWish	mywish
WOMEN	WomenCoin	women
WORM	HealthyWormCoin	healthywormcoin
WOW	Wowcoin	wowcoin
WPR	WePower	wepower
WRC	Worldcore	worldcore
WSX	WeAreSatoshi	wearesatoshi
WTC	Walton	walton
WTT	Giga Watt Token	giga-watt-token
X2	X2	x2
XAS	Asch	asch
XAU	Xaucoin	xaucoin
XAUR	Xaurum	xaurum
XBC	Bitcoin Plus	bitcoin-plus
XBL	Billionaire Token	billionaire-token
XBTC21	Bitcoin 21	bitcoin-21
XBTS	Beatcoin	beatcoin
XBY	XTRABYTES	xtrabytes
XCN	Cryptonite	cryptonite
XCO	X-Coin	x-coin
XCP	Counterparty	counterparty
XCPO	Copico	copico
XCRE	Creatio	creatio
XCS	CybCSec	cybcsec
XCT	C-Bit	c-bit
XCXT	CoinonatX	coinonatx
XDE2	XDE II	xde-ii
XDN	DigitalNote	digitalnote
XEL	Elastic	elastic
XEM	NEM	nem
XFT	Footy Cash	footy-cash
XGOX	XGOX	xgox
XGR	GoldReserve	goldreserve
XHI	HiCoin	hicoin
XID	Sphre AIR 	sphre-air
XIN	Infinity Economics	infinity-economics
XIOS	Xios	xios
XJO	Joulecoin	joulecoin
XLC	LeviarCoin	leviarcoin
XLM	Stellar	stellar
XLR	Solaris	solaris
XMCC	Monoeci	monacocoin
XMG	Magi	magi
XMR	Monero	monero
XMRG	Monero Gold	monero-gold
XMY	Myriad	myriad
XNG	Enigma	enigma
XNN	Xenon	xenon
XOC	Xonecoin	xonecoin
XOT	Internet of Things	internet-of-things
XP	Experience Points	experience-points
XPA	XPlay	xplay
XPD	PetroDollar	petrodollar
XPM	Primecoin	primecoin
XPTX	PlatinumBAR	platinumbar
XPY	PayCoin	paycoin2
XQN	Quotient	quotient
XRA	Ratecoin	ratecoin
XRB	Nano	raiblocks
XRC	Rawcoin	rawcoin2
XRE	RevolverCoin	revolvercoin
XRL	Rialto	rialto
XRP	Ripple	ripple
XRY	Royalties	royalties
XSH	SHIELD	shield-xsh
XSPEC	Spectrecoin	spectrecoin
XST	Stealthcoin	stealthcoin
XSTC	Safe Trade Coin	safe-trade-coin
XTD	XTD Coin	xtd-coin
XTO	Tao	tao
XTZ	Tezos (Pre-Launch)	tezos
XUC	Exchange Union	exchange-union
XVC	Vcash	vcash
XVE	The Vegan Initiative	the-vegan-initiative
XVG	Verge	verge
XVP	Virtacoinplus	virtacoinplus
XWC	WhiteCoin	whitecoin
XZC	ZCoin	zcoin
YAC	Yacoin	yacoin
YEE	Yee	yee
YEL	Yellow Token	yellow-token
YES	Yescoin	yescoin
YOC	Yocoin	yocoin
YOYOW	YOYOW	yoyow
YTN	YENTEN	yenten
ZAP	Zap	zap
ZBC	Zilbercoin	zilbercoin
ZCG	Zlancer	zcash-gold
ZCL	ZClassic	zclassic
ZEC	Zcash	zcash
ZEIT	Zeitcoin	zeitcoin
ZEN	ZenCash	zencash
ZENGOLD	ZenGold	zengold
ZENI	Zennies	zennies
ZEPH	Zephyr	zephyr
ZER	Zero	zero
ZET	Zetacoin	zetacoin
ZIL	Zilliqa	zilliqa
ZLA	Zilla	zilla
ZMC	ZetaMicron	zetamicron
ZNE	Zonecoin	zonecoin
ZNY	Bitzeny	bitzeny
ZOI	Zoin	zoin
ZPT	Zeepin	zeepin
ZRC	ZrCoin	zrcoin
ZRX	0x	0x
ZSC	Zeusshield	zeusshield
ZSE	ZSEcoin	zsecoin
ZUR	Zurcoin	zurcoin
ZYD	Zayedcoin	zayedcoin
ZZC	ZoZoCoin	zozocoin
