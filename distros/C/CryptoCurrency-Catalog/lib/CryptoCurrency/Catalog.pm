package CryptoCurrency::Catalog;

our $DATE = '2018-06-06'; # DATE
our $VERSION = '20180606'; # VERSION

use 5.010001;
use strict;
use warnings;

my %by_code;
my %by_name_lc;
my %by_safename;
my @all_data;

sub new {
    my $class = shift;

    unless (keys %by_code) {
        while (defined(my $line = <DATA>)) {
            chomp $line;
            my @ff = split /\t/, $line;
            my ($code, $name, $safename) = @ff;
            $by_code{$code}         = \@ff;
            $by_name_lc{lc $name}   = \@ff;
            $by_safename{$safename} = \@ff;
            push @all_data, \@ff;
        }
    }

    bless {}, $class;
}

sub by_code {
    my ($self, $code) = @_;
    $code = uc($code);
    die "Can't find cryptocurrency with code '$code'"
        unless $by_code{$code};
    return {
        code=>$code,
        name=>$by_code{$code}[1],
        safename=>$by_code{$code}[2],
    };
}

sub by_ticker { by_code(@_) }

sub by_name {
    my ($self, $name) = @_;
    die "Can't find cryptocurrency with name '$name'"
        unless my $rec = $by_name_lc{lc $name};
    return {
        name=>$rec->[1],
        code=>$rec->[0],
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
        code=>$by_safename{$safename}[0],
        name=>$by_safename{$safename}[1],
    };
}

sub by_slug { by_safename(@_) }

sub all_codes {
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
        push @res, {code=>$_->[0], name=>$_->[1], safename=>$_->[2]};
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

This document describes version 20180606 of CryptoCurrency::Catalog (from Perl distribution CryptoCurrency-Catalog), released on 2018-06-06.

=head1 SYNOPSIS

 use CryptoCurrency::Catalog;

 my $cat = CryptoCurrency::Catalog->new;

 my $record = $cat->by_code("ETH");          # => { code=>"ETH", name=>"Ethereum", safename=>"ethereum" }
 my $record = $cat->by_ticker("eth");        # alias for by_code(), lowercase also works
 my $record = $cat->by_name("Ethereum");     # note: case-sensitive
 my $record = $cat->by_safename("ethereum");
 my $record = $cat->by_slug("Ethereum");     # alias for by_safename(), mixed case also works

 my @codes = $cat->all_codes(); # => ("BTC", "ETH", ...)

 my @data = $cat->all_data; # => ({code=>"BTC", name=>"Bitcoin", safename=>"bitcoin"}, {...}, ...)

=head1 DESCRIPTION

This class attempts to provide a list/catalog of cryptocurrencies. The main
source for this catalog is the Cryptocurrency Market Capitalizations website
(L<https://coinmarketcap.com/>, or CMC for short).

CMC does not provide unique codes nor unique names, only unique "safenames"
(slugs). Whenever there is a clash, this catalog modifies the clashing code
and/or unique name to make code and name to be unique again (usually the
coin/token with the smaller market cap "loses" the name).

There is no guarantee that the code/name/safename of old/unlisted coins or
tokens will not be reused.

=head1 METHODS

=head2 new

=head2 by_code

=head2 by_ticker

Alias for L</"by_code">.

=head2 by_name

=head2 by_safename

=head2 by_slug

Alias for L</"by_safename">.

=head2 all_codes

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
$PAC	PACcoin	paccoin
0xBTC	0xBitcoin	0xbtc
1337	Elite	1337coin
1ST	FirstBlood	firstblood
1WO	1World	1world
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
ABT	Arcblock	arcblock
ABY	ArtByte	artbyte
AC	AsiaCoin	asiacoin
AC3	AC3	ac3
ACAT	Alphacat	alphacat
ACC	Accelerator Network	accelerator-network
ACCHAIN	ACChain	acchain
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
ADH	AdHive	adhive
ADI	Aditus	aditus
ADK	Aidos Kuneen	aidos-kuneen
ADST	AdShares	adshares
ADT	adToken	adtoken
ADX	AdEx	adx-net
ADZ	Adzcoin	adzcoin
AE	Aeternity	aeternity
AEON	Aeon	aeon
AERM	Aerium	aerium
AGI	SingularityNET	singularitynet
AGLC	AgrolifeCoin	agrolifecoin
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
AMB	Ambrosus	amber
AMBER	AmberCoin	ambercoin
AMLT	AMLT	amlt
AMM	MicroMoney	micromoney
AMMO	Ammo Reloaded	ammo-reloaded
AMN	Amon	amon
AMP	Synereo	synereo
AMS	AmsterdamCoin	amsterdamcoin
ANC	Anoncoin	anoncoin
ANI	Animecoin	animecoin
ANT	Aragon	aragon
ANTX	Antimatter	antimatter
APH	Aphelion	aphelion
APIS	APIS	apis
APPC	AppCoins	appcoins
APR	APR Coin	apr-coin
APX	APX	apx
ARB	ARbit	arbit
ARC	Advanced Technology Coin	arcticcoin
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
ASTON	Aston	aston
ASTRO	Astro	astro
ATB	ATBCoin	atbcoin
ATC	Arbitracoin	arbitracoin
ATL	ATLANT	atlant
ATM	ATMChain	attention-token-of-media
ATMC	ATMCoin	atmcoin
ATMOS	Atmos	atmos
ATN	ATN	atn
ATOM	Atomic Coin	atomic-coin
ATS	Authorship	authorship
ATX	Artex Coin	artex-coin
AU	AurumCoin	aurumcoin
AUC	Auctus	auctus
AUR	Auroracoin	auroracoin
AURA	Aurora DAO	aurora-dao
AUTO	Cube	cube
AV	AvatarCoin	avatarcoin
AVA	Travala	travala
AVH	Animation Vision Cash	animation-vision-cash
AVT	Aventus	aventus
AWR	AWARE	aware
AXIOM	Axiom	axiom
AXP	aXpire	axpire
B2B	B2BX	b2bx
B2X	SegWit2x	segwit2x
B@	Bankcoin	bankcoin
BANCA	Banca	banca
BANK	Bank Coin	bank-coin
BAR	Titanium Blockchain	titanium-blockchain
BAS	BitAsean	bitasean
BASH	LuckChain	luckchain
BAT	Basic Attention Token	basic-attention-token
BAX	BABB	babb
BAY	BitBay	bitbay
BBC	TraDove B2BCoin	b2bcoin
BBI	BelugaPay	belugapay
BBN	Banyan Network	banyan-network
BBO	Bigbom	bigbom
BBP	BiblePay	biblepay
BBR	Boolberry	boolberry
BCA	Bitcoin Atom	bitcoin-atom
BCC	BitConnect	bitconnect
BCD	Bitcoin Diamond	bitcoin-diamond
BCDN	BlockCDN	blockcdn
BCF	Bitcoin Fast	bitcoinfast
BCH	Bitcoin Cash	bitcoin-cash
BCI	Bitcoin Interest	bitcoin-interest
BCN	Bytecoin	bytecoin-bcn
BCO	BridgeCoin	bridgecoin
BCPT	BlockMason Credit Protocol	blockmason
BCX	BitcoinX	bitcoinx
BCY	Bitcrystals	bitcrystals
BDG	BitDegree	bitdegree
BDL	Bitdeal	bitdeal
BEE	Bee Token	bee-token
BELA	Bela	belacoin
BENJI	BenjiRolls	benjirolls
BERN	BERNcash	berncash
BERRY	Rentberry	rentberry
BEST	BestChain	bestchain
BET	DAO.Casino	dao-casino
BETACOIN	BetaCoin	betacoin
BETR	BetterBetting	betterbetting
BEZ	Bezop	bezop
BFT	BnkToTheFuture	bnktothefuture
BIG	BigONE Token	bigone-token
BIGUP	BigUp	bigup
BIO	BioCoin	biocoin
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
BITG	Bitcoin Green	bitcoin-green
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
BLAZE	BlazeCoin	blazecoin
BLAZR	BlazerCoin	blazercoin
BLC	Blakecoin	blakecoin
BLK	BlackCoin	blackcoin
BLN	Bolenum	bolenum
BLOCK	Blocknet	blocknet
BLOCKLANCER	Blocklancer	blocklancer
BLOCKPAY	BlockPay	blockpay
BLT	Bloom	bloomtoken
BLU	BlueCoin	bluecoin
BLUE	Blue Protocol	ethereum-blue
BLZ	Bluzelle	bluzelle
BMC	Blackmoon	blackmoon
BMH	BlockMesh	blockmesh
BNB	Binance Coin	binance-coin
BNK	Bankera	bankera
BNT	Bancor	bancor
BNTY	Bounty0x	bounty0x
BNX	BnrtxCoin	bnrtxcoin
BOAT	BOAT	doubloon
BOLI	Bolivarcoin	bolivarcoin
BON	Bonpay	bonpay
BOS	BOScoin	boscoin
BOST	BoostCoin	boostcoin
BOT	Bodhi	bodhi
BOUTS	BoutsPro	boutspro
BPC	Bitpark Coin	bitpark-coin
BPL	Blockpool	blockpool
BPT	Blockport	blockport
BQ	bitqy	bitqy
BRAT	BROTHER	brat
BRD	Bread	bread
BRIA	BriaCoin	briacoin
BRIT	BritCoin	britcoin
BRK	Breakout	breakout
BRM	BrahmaOS	brahmaos
BRO	Bitradio	bitradio
BRX	Breakout Stake	breakout-stake
BSC	BowsCoin	bowscoin
BSD	BitSend	bitsend
BSM	Bitsum	bitsum
BSN	Bastonet	bastonet
BSR	BitSoar	bitsoar
BSTN	BitStation	bitstation
BSTY	GlobalBoost-Y	globalboost-y
BT2	BT2 [CST]	bt2-cst
BTA	Bata	bata
BTB	BitBar	bitbar
BTBc	Bitbase	bitbase
BTC	Bitcoin	bitcoin
BTCA	Bitair	bitair
BTCD	BitcoinDark	bitcoindark
BTCM	BTCMoon	btcmoon
BTCP	Bitcoin Private	bitcoin-private
BTCR	Bitcurrency	bitcurrency
BTCRED	Bitcoin Red	bitcoin-red
BTCS	Bitcoin Scrypt	bitcoin-scrypt
BTCZ	BitcoinZ	bitcoinz
BTDX	Bitcloud	bitcloud
BTE	BitSerial	bitserial
BTG	Bitcoin Gold	bitcoin-gold
BTM	Bytom	bytom
BTO	Bottos	bottos
BTPL	Bitcoin Planet	bitcoin-planet
BTQ	BitQuark	bitquark
BTRN	Biotron	biotron
BTS	BitShares	bitshares
BTW	BitWhite	bitwhite
BTWTY	Bit20	bit20
BTX	Bitcore	bitcore
BUB	Bubble	bubble
BUBO	Budbo	budbo
BUMBA	BumbaCoin	bumbacoin
BUN	BunnyCoin	bunnycoin
BURST	Burst	burst
BUZZ	BuzzCoin	buzzcoin
BWK	Bulwark	bulwark
BXT	BitTokens	bittokens
BYC	Bytecent	bytecent
BZNT	Bezant	bezant
C2	Coin2.1	coin2-1
C20	CRYPTO20	c20
CAB	Cabbage	cabbage
CACH	CacheCoin	cachecoin
CAG	Change	change
CAN	CanYaCoin	canyacoin
CANDY	Candy	candy
CANETWORK	Content and AD Network	content-and-ad-network
CANN	CannabisCoin	cannabiscoin
CAPP	Cappasity	cappasity
CARBON	Carboncoin	carboncoin
CAS	Cashaa	cashaa
CASH	Cashcoin	cashcoin
CAT	BlockCAT	blockcat
CATCOIN	Catcoin	catcoin
CAZ	Cazcoin	cazcoin
CBT	CommerceBlock	commerceblock
CBX	Bullion	bullion
CCN	CannaCoin	cannacoin
CCO	Ccore	ccore
CCRB	CryptoCarbon	cryptocarbon
CCT	Crystal Clear 	crystal-clear
CDN	Canada eCoin	canada-ecoin
CDT	Blox	blox
CDX	Commodity Ad Network	commodity-ad-network
CEFS	CryptopiaFeeShares	cryptopiafeeshares
CENNZ	Centrality	centrality
CF	Californium	californium
CFC	CoffeeCoin	coffeecoin
CFI	Cofound.it	cofound-it
CFUN	CFun	cfun
CHAN	ChanCoin	chancoin
CHAT	ChatCoin	chatcoin
CHC	ChainCoin	chaincoin
CHEAP	Cheapcoin	cheapcoin
CHESS	ChessCoin	chesscoin
CHIPS	CHIPS	chips
CHP	CoinPoker	coinpoker
CHSB	SwissBorg	swissborg
CHX	Chainium	chainium
CJ	Cryptojacks	cryptojacks
CJT	ConnectJob	connectjob
CKUSD	CK USD	ckusd
CL	Coinlancer	coinlancer
CLAM	Clams	clams
CLD	Cloud	cloud
CLN	Colu Local Network	colu-local-network
CLO	Callisto Network	callisto-network
CLOAK	CloakCoin	cloakcoin
CLR	ClearCoin	clearcoin
CLUB	ClubCoin	clubcoin
CMCT	Crowd Machine	crowd-machine
CMPCO	CampusCoin	campuscoin
CMSETH	COMSA [ETH]	comsa-eth
CMSXEM	COMSA [XEM]	comsa-xem
CMT	CyberMiles	cybermiles
CND	Cindicator	cindicator
CNET	ContractNet	contractnet
CNN	Content Neutrality Network	content-neutrality-network
CNNC	Cannation	cannation
CNO	Coin(O)	coin
CNT	Centurion	centurion
CNX	Cryptonex	cryptonex
COAL	BitCoal	bitcoal
COB	Cobinhood	cobinhood
COFI	CoinFi	coinfi
COLX	ColossusXT	colossusxt
COMET	Comet	comet
CON	PayCon	paycon
CONX	Concoin	concoin
COR	CORION	corion
COSS	COSS	coss
COUPE	Coupecoin	coupecoin
COV	Covesting	covesting
COVAL	Circuits of Value	circuits-of-value
CPAY	Cryptopay	cryptopay
CPC	Capricoin	capricoin
CPCHAIN	CPChain	cpchain
CPN	CompuCoin	compucoin
CPT	Cryptaur	cryptaur
CPX	Apex	apex
CPY	COPYTRACK	copytrack
CRAVE	Crave	crave
CRB	Creditbit	creditbit
CRC	CryCash	crycash
CRDNC	Credence Coin	credence-coin
CRE	Cybereits	cybereits
CREA	Creativecoin	creativecoin
CRED	Verify	verify
CREDO	Credo	credo
CREVA	CrevaCoin	crevacoin
CRM	Cream	cream
CROP	Cropcoin	cropcoin
CROWD	CrowdCoin	crowdcoin
CRPT	Crypterium	crypterium
CRW	Crown	crown
CRX	Chronos	chronos
CRYPT	CryptCoin	cryptcoin
CS	Credits	credits
CSC	CasinoCoin	casinocoin
CSNO	BitDice	bitdice
CTIC2	Coimatic 2.0	coimatic-2
CTIC3	Coimatic 3.0	coimatic-3
CTO	Crypto	crypto
CTR	Centra	centra
CTX	CarTaxi Token	cartaxi-token
CTXC	Cortex	cortex
CUBE	DigiCube	digicube
CUBIT	Cubits	cubits
CURE	Curecoin	curecoin
CV	carVertical	carvertical
CVC	Civic	civic
CVCOIN	CVCoin	cvcoin
CVH	Curriculum Vitae	curriculum-vitae
CVT	CyberVein	cybervein
CWXT	CryptoWorldX Token	cryptoworldx-token
CXO	CargoX	cargox
CXT	Coinonat	coinonat
CYC	Cycling Coin	cycling-coin
CYDER	Cyder	cyder
DADI	DADI	dadi
DAI	Dai	dai
DALC	Dalecoin	dalecoin
DAN	Daneel	daneel
DAR	Darcrus	darcrus
DASC	Dascoin	dascoin
DASH	Dash	dash
DASHS	Dashs	dashs
DAT	Datum	datum
DATA	Streamr DATAcoin	streamr-datacoin
DATX	DATx	datx
DAV	DavorCoin	davorcoin
DAX	DAEX	daex
DAXX	DaxxCoin	daxxcoin
DAY	Chronologic	chronologic
DBC	DeepBrain Chain	deepbrain-chain
DBET	DecentBet	decent-bet
DBIX	DubaiCoin	dubaicoin-dbix
DBTC	Debitcoin	debitcoin
DCN	Dentacoin	dentacoin
DCR	Decred	decred
DCRE	DeltaCredits	deltacredits
DCT	DECENT	decent
DCY	Dinastycoin	dinastycoin
DDD	Scry.info	scryinfo
DDF	DigitalDevelopersFund	digital-developers-fund
DEB	Debitum	debitum-network
DEM	Deutsche eMark	deutsche-emark
DENT	Dent	dent
DERO	Dero	dero
DES	Destiny	destiny
DEUS	DeusCoin	deuscoin
DEV	DeviantCoin	deviantcoin
DEW	DEW	dew
DFT	DraftCoin	draftcoin
DGB	DigiByte	digibyte
DGC	Digitalcoin	digitalcoin
DGD	DigixDAO	digixdao
DGPT	DigiPulse	digipulse
DGTX	Digitex Futures	digitex-futures
DGX	Digix Gold Token	digix-gold-token
DICE	Etheroll	etheroll
DIG	Dignity	dignity
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
DML	Decentralized Universal Basic Income	decentralized-machine-learning
DMT	DMarket	dmarket
DNA	EncrypGen	encrypgen
DNR	Denarius	denarius-dnr
DNT	district0x	district0x
DOCK	Dock	dock
DOGE	Dogecoin	dogecoin
DOLLAR	Dollar Online	dollar-online
DON	Donationcoin	donationcoin
DOPE	DopeCoin	dopecoin
DOT	Dotcoin	dotcoin
DOVU	Dovu	dovu
DP	DigitalPrice	digitalprice
DPY	Delphy	delphy
DRG	Dragon Coins	dragon-coins
DRGN	Dragonchain	dragonchain
DRM	Dreamcoin	dreamcoin
DROP	Dropil	dropil
DRPU	DCORP Utility	drp-utility
DRS	Digital Rupees	digital-rupees
DRT	DomRaider	domraider
DRXNE	DROXNE	droxne
DSH	Dashcoin	dashcoin
DSR	Desire	desire
DTA	DATA	data
DTB	Databits	databits
DTC	Datacoin	datacoin
DTH	Dether	dether
DTR	Dynamic Trading Rights	dynamic-trading-rights
DTRC	Datarius Credit	datarius-credit
DUO	ParallelCoin	parallelcoin
DUTCH	Dutch Coin	dutch-coin
DXT	Datawallet	datawallet
DYN	Dynamic	dynamic
EAG	EA Coin	ea-coin
EAGLE	EagleCoin	eaglecoin
EARTH	Earth Token	earth-token
EBCH	EBCH	ebitcoin-cash
EBET	EthBet	ethbet
EBST	eBoost	eboostcoin
EBT	Ebittree Coin	ebittree-coin
EBTC	eBitcoin	ebtcnew
ECA	Electra	electra
ECASH	Ethereum Cash	ethereumcash
ECC	ECC	eccoin
ECH	Etherecash	etherecash
ECN	E-coin	e-coin
ECO	EcoCoin	ecocoin
ECOB	Ecobit	ecobit
EDG	Edgeless	edgeless
EDO	Eidoo	eidoo
EDR	E-Dinar Coin	e-dinar-coin
EDRCOIN	EDRCoin	edrcoin
EDT	EtherDelta Token	etherdelta-token
EDU	EduCoin	edu-coin
EFL	e-Gulden	e-gulden
EFX	Effect.AI	effect-ai
EFYT	Ergo	ergo
EGC	EverGreenCoin	evergreencoin
EGG	EggCoin	eggcoin
EJOY	EJOY	ejoy
EKO	EchoLink	echolink
EKT	EDUCare	educare
EL	Elcoin	elcoin-el
ELA	Elastos	elastos
ELE	Elementrem	elementrem
ELEC	Electrify.Asia	electrifyasia
ELF	aelf	aelf
ELITE	Ethereum Lite	ethereum-lite
ELIX	Elixir	elixir
ELLA	Ellaism	ellaism
ELS	Elysium	elysium
ELTCOIN	ELTCOIN	eltcoin
EMB	EmberCoin	embercoin
EMC	Emercoin	emercoin
EMC2	Einsteinium	einsteinium
EMD	Emerald Crypto	emerald
EMV	Ethereum Movie Venture	ethereum-movie-venture
ENDOR	Endor Protocol	endor-protocol
ENG	Enigma Project	enigma-project
ENJ	Enjin Coin	enjin-coin
ENRG	Energycoin	energycoin
ENT	Eternity	eternity
ENTCASH	ENTCash	entcash
EOS	EOS	eos
EOSDAC	eosDAC	eosdac
EPC	Electronic PK Chain	electronic-pk-chain
EPY	Emphy	emphy
EQL	Equal	equal
EQT	EquiTrader	equitrader
ERA	ERA	blakestar
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
ETZ	Ether Zero	ether-zero
EUC	Eurocoin	eurocoin
EVC	EventChain	eventchain
EVE	Devery	devery
EVIL	Evil Coin	evil-coin
EVN	Envion	envion
EVR	Everus	everus
EVX	Everex	everex
EXC	Eximchain	eximchain
EXCL	ExclusiveCoin	exclusivecoin
EXN	ExchangeN	exchangen
EXP	Expanse	expanse
EXRN	EXRNchain	exrnchain
EXY	Experty	experty
EZT	EZToken	eztoken
FACE	Faceter	faceter
FAIR	FairCoin	faircoin
FAIRGAME	FairGame	fairgame
FANS	Fantasy Cash	fantasy-cash
FAP	FAPcoin	fapcoin
FAZZ	Fazzcoin	fazzcoin
FCN	Fantomcoin	fantomcoin
FCT	Factom	factom
FDX	FidentiaX	fidentiax
FDZ	Friendz	friends
FID	Fidelium	fidelium
FIL	Filecoin [Futures]	filecoin
FIRE	Firecoin	firecoin
FJC	FujiCoin	fujicoin
FLASH	Flash	flash
FLAX	Flaxscript	flaxscript
FLDC	FoldingCoin	foldingcoin
FLIK	FLiK	flik
FLIXX	Flixxo	flixxo
FLO	FlorinCoin	florincoin
FLT	FlutterCoin	fluttercoin
FLUZ	Fluz Fluz	fluz-fluz
FLY	Flycoin	flycoin
FNC	FinCoin	fincoin
FND	FundRequest	fundrequest
FOR	FORCE	force
FOTA	Fortuna	fortuna
FRC	Freicoin	freicoin
FRCT	Farstcoin	farstcoin
FRD	Farad	farad
FREC	Freyrchain	freyrchain
FRGC	Fargocoin	fargocoin
FRN	Francs	francs
FRST	FirstCoin	firstcoin
FRV	Fitrova	fitrova
FSN	Fusion	fusion
FST	Fastcoin	fastcoin
FT	Fabric Token	fabric-token
FTC	Feathercoin	feathercoin
FTX	FintruX Network	fintrux-network
FUEL	Etherparty	etherparty
FUN	FunFair	funfair
FUNC	FUNCoin	funcoin
FUNK	The Cypherfunks	the-cypherfunks
FUZZ	FuzzBalls	fuzzballs
FXE	FuturXe	futurexe
FXT	FuzeX	fuzex
FYN	FundYourselfNow	fundyourselfnow
FYP	FlypMe	flypme
GAIN	UGAIN	ugain
GAM	Gambit	gambit
GAME	GameCredits	gamecredits
GAME2	Game.com	game
GAP	Gapcoin	gapcoin
GARY	President Johnson	president-johnson
GAS	Gas	gas
GAT	Gatcoin	gatcoin
GB	GoldBlocks	goldblocks
GBC	GBCGoldCoin	gbcgoldcoin
GBG	Golos Gold	golos-gold
GBX	GoByte	gobyte
GBYTE	Byteball Bytes	byteball
GCC	Global Cryptocurrency	global-cryptocurrency
GCN	GCN Coin	gcn-coin
GCR	Global Currency Reserve	global-currency-reserve
GCS	GameChain System	gamechain
GDC	GrandCoin	grandcoin
GEERT	GeertCoin	geertcoin
GEM	Gems 	gems-protocol
GEN	DAOstack	daostack
GENE	Parkgene	parkgene
GEO	GeoCoin	geocoin
GET	GET Protocol	get-protocol
GETX	Guaranteed Ethurance Token Extra	guaranteed-ethurance-token-extra
GIN	GINcoin	gincoin
GJC	Global Jobcoin	global-jobcoin
GLA	Gladius Token	gladius-token
GLC	GlobalCoin	globalcoin
GLD	GoldCoin	goldcoin
GLS	GlassCoin	glasscoin
GLT	GlobalToken	globaltoken
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
GRC	GridCoin	gridcoin
GRFT	Graft	graft
GRID	Grid+	grid
GRIM	Grimcoin	grimcoin
GRLC	Garlicoin	garlicoin
GRMD	GreenMed	greenmed
GRN	Granite	granitecoin
GRS	Groestlcoin	groestlcoin
GRWI	Growers International	growers-international
GRX	GOLD Reward Token	gold-reward-token
GSC	Global Social Chain	global-social-chain
GSR	GeyserCoin	geysercoin
GTC	Global Tour Coin	global-tour-coin
GTO	Gifto	gifto
GUCCIONE	GuccioneCoin	guccionecoin
GUESS	Peerguess	guess
GUN	Guncoin	guncoin
GUP	Matchpool	guppy
GVT	Genesis Vision	genesis-vision
GXS	GXChain	gxchain
HAC	Hackspace Capital	hackspace-capital
HADE	Hade Platform	hade-platform
HAL	Halcyon	halcyon
HALLO	Halloween Coin	halloween-coin
HAT	Hat.Exchange	hat-exchange
HAV	Havven	havven
HBC	HomeBlockCoin	homeblockcoin
HBN	HoboNickels	hobonickels
HBT	Hubii Network	hubii-network
HBZ	Helbiz	helbiz
HC	Harvest Masternode Coin	harvest-masternode-coin
HDG	Hedge	hedge
HDLB	HODL Bucks	hodl-bucks
HEAT	HEAT	heat-ledger
HER	HeroNode	heronode
HERO	Sovereign Hero	sovereign-hero
HERO2	Hero	hero
HGT	HelloGold	hellogold
HIGH	High Gain	high-gain
HIMUTUAL	Hi Mutual Society	hi-mutual-society
HIRE	HireMatch	hirematch
HKN	Hacken	hacken
HLC	HalalChain	halalchain
HMC	HarmonyCoin	harmonycoin-hmc
HMP	HempCoin (HMP)	hempcoin-hmp
HMQ	Humaniq	humaniq
HNC	Helleniccoin	helleniccoin
HODL	HOdlcoin	hodlcoin
HOLD	Interstellar Holdings	interstellar-holdings
HONEY	Honey	honey
HORSE	Ethorse	ethorse
HOT	Holo	holo
HPB	High Performance Blockchain	high-performance-blockchain
HPC	Happycoin	happycoin
HPY	Hyper Pay	hyper-pay
HQX	HOQU	hoqu
HSR	Hshare	hshare
HST	Decision Token	decision-token
HT	Huobi Token	huobi-token
HTML	HTMLCOIN	html-coin
HUC	HunterCoin	huntercoin
HUNCOIN	Huncoin	huncoin
HUSH	Hush	hush
HVCO	High Voltage	high-voltage
HVN	Hive Project	hive-project
HWC	HollyWoodCoin	hollywoodcoin
HXX	Hexx	hexx
HYDRO	Hydro Protocol	hydro-protocol
HYDROGEN	Hydrogen	hydrogen
HYP	HyperStake	hyperstake
HYPER	Hyper	hyper
I0C	I0Coin	i0coin
IBANK	iBank	ibank
IC	Ignition	ignition
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
IHT	IHT Real Estate Protocol	iht-real-estate-protocol
IIC	Intelligent Investment Chain	intelligent-investment-chain
IMPS	ImpulseCoin	impulsecoin
IMS	Independent Money System	independent-money-system
IMX	Impact	impact
INC	Influence Chain	influence-chain
INCNT	Incent	incent
IND	Indorse Token	indorse-token
INDI	Indicoin	indicoin
INDIA	India Coin	india-coin
INFX	Influxcoin	influxcoin
ING	Iungo	iungo
INK	Ink	ink
INN	Innova	innova
INPAY	InPay	inpay
INS	INS Ecosystem	ins-ecosystem
INSN	InsaneCoin	insanecoin-insn
INSTAR	Insights Network	insights-network
INSUR	InsurChain	insurchain
INT	Internet Node Token	internet-node-token
INV	Invacio	invacio
INXT	Internxt	internxt
IOC	I/O Coin	iocoin
ION	ION	ion
IOP	Internet of People	internet-of-people
IOST	IOST	iostoken
IOTX	IoTeX	iotex
IPC	IPChain	ipchain
IPL	InsurePal	insurepal
IPSX	IP Exchange	ip-exchange
IQT	iQuant	iquant
IRL	IrishCoin	irishcoin
ISL	IslaCoin	islacoin
ITC	IoT Chain	iot-chain
ITI	iTicoin	iticoin
ITNS	IntenseCoin	intensecoin
ITT	Intelligent Trading Tech	intelligent-trading-foundation
ITZ	Interzone	interzone
IVY	Ivy	ivy
IXC	Ixcoin	ixcoin
IXT	iXledger	ixledger
J	Joincoin	joincoin
J8T	JET8	jet8
JC	Jesus Coin	jesus-coin
JET	Jetcoin	jetcoin
JEW	Shekel	shekel
JIN	Jin Coin	jin-coin
JIYO	Jiyo	jiyo
JNT	Jibrel Network	jibrel-network
JOBS	JobsCoin	jobscoin
JS	JavaScript Token	javascript-token
JWL	Jewels	jewels
KARMA	Karmacoin	karmacoin
KASHH	KashhCoin	kashhcoin
KB3	B3Coin	b3coin
KBR	Kubera Coin	kubera-coin
KCASH	Kcash	kcash
KCS	KuCoin Shares	kucoin-shares
KDC	KlondikeCoin	klondikecoin
KED	Darsek	darsek
KEK	KekCoin	kekcoin
KEY	Selfkey	selfkey
KEY2	KEY	key
KICK	KickCoin	kickico
KIN	Kin	kin
KINGN	KingN Coin	kingn-coin
KLC	KiloCoin	kilocoin
KLN	Kolion	kolion
KMD	Komodo	komodo
KNC	Kyber Network	kyber-network
KOBO	Kobocoin	kobocoin
KORE	Kore	korecoin
KRB	Karbo	karbo
KRM	Karma	karma
KRONE	Kronecoin	kronecoin
KST	StarCoin	starcointv
KURT	Kurrent	kurrent
KUSH	KushCoin	kushcoin
LA	LATOKEN	latoken
LALA	LALA World	lala-world
LANA	LanaCoin	lanacoin
LATX	LatiumX	latiumx
LBA	Libra Credit	libra-credit
LBC	LBRY Credits	library-credit
LBTC	LiteBitcoin	litebitcoin
LCC	Litecoin Cash	litecoin-cash
LCP	Litecoin Plus	litecoin-plus
LDC	Leadcoin	leadcoin
LDCN	LandCoin	landcoin
LDOGE	LiteDoge	litedoge
LEA	LeaCoin	leacoin
LEDU	Education Ecosystem	education-ecosystem
LEND	ETHLend	ethlend
LEO	LEOcoin	leocoin
LEPEN	LePen	lepen
LET	LinkEye	linkeye
LEV	Leverj	leverj
LEVO	Levocoin	levocoin
LGD	Legends Room	legends-room
LGO	Legolas Exchange	legolas-exchange
LIFE	LIFE	life
LIGHT	LightChain	lightchain
LIGHTNINGBTC	Lightning Bitcoin	lightning-bitcoin
LINDA	Linda	linda
LINK	ChainLink	chainlink
LINX	Linx	linx
LIR	LetItRide	letitride
LIVE	Live Stars	live-stars
LKC	LinkedCoin	linkedcoin
LKK	Lykke	lykke
LMC	LoMoCoin	lomocoin
LNC	Linker Coin	linker-coin
LND	Lendingblock	lendingblock
LOC	LockTrip	lockchain
LOCI	LOCIcoin	locicoin
LOG	Woodcoin	woodcoin
LOKI	Loki	loki
LOOM	Loom Network	loom-network
LRC	Loopring	loopring
LRN	Loopring [NEO]	loopring-neo
LSK	Lisk	lisk
LST	Lendroid Support Token	lendroid-support-token
LTB	LiteBar	litebar
LTC	Litecoin	litecoin
LTCR	Litecred	litecred
LTCU	LiteCoin Ultra	litecoin-ultra
LUC	Level Up Coin	level-up
LUN	Lunyr	lunyr
LUNA	Luna Coin	luna-coin
LUX	LUXCoin	luxcoin
LVPS	LevoPlus	levoplus
LWF	Local World Forwarders	local-world-forwarders
LYL	LoyalCoin	loyalcoin
LYM	Lympo	lympo
MAC	Machinecoin	machinecoin
MAD	SatoshiMadness	satoshimadness
MAG	Magnet	magnet
MAGE	MagicCoin	magiccoin
MAGGIE	Maggie	maggie
MAGN	Magnetcoin	magnetcoin
MAID	MaidSafeCoin	maidsafecoin
MAN	Matrix AI Network	matrix-ai-network
MANA	Decentraland	decentraland
MANNA	Manna	manna
MAO	Mao Zedong	mao-zedong
MAR	Marijuanacoin	marijuanacoin
MARS	Marscoin	marscoin
MARX	MarxCoin	marxcoin
MAX	MaxCoin	maxcoin
MAY	Theresa May Coin	theresa-may-coin
MBI	Monster Byte	monster-byte
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
MEDIC	MedicCoin	mediccoin
MEET	CoinMeet	coinmeet
MEME	Memetic (PepeCoin)	memetic
MER	Mercury	mercury
METAL	MetalCoin	metalcoin
MFG	SyncFab	syncfab
MGM	Magnum	magnum
MGO	MobileGo	mobilego
MILO	MiloCoin	milocoin
MINEX	Minex	minex
MINT	Mintcoin	mintcoin
MIOTA	IOTA	iota
MITH	Mithril	mithril
MITX	Morpheus Labs	morpheus-labs
MIXIN	Mixin	mixin
MKR	Maker	maker
MLM	MktCoin	mktcoin
MLN	Melon	melon
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
MONK	Monkey Project	monkey-project
MOON	Mooncoin	mooncoin
MORPH	Morpheus Network	morpheus-network
MOT	Olympus Labs	olympus-labs
MOTO	Motocoin	motocoin
MRK	MARK.SPACE	mark-space
MRT	Miners' Reward Token	miners-reward-token
MSCN	Master Swiscoin	master-swiscoin
MSD	MSD	msd
MSP	Mothership	mothership
MSR	Masari	masari
MST	MustangCoin	mustangcoin
MT	MyToken	mytoken
MTC	Docademic	docademic
MTH	Monetha	monetha
MTL	Metal	metal
MTLMC3	Metal Music Coin	metal-music-coin
MTN	Medicalchain	medical-chain
MTNC	Masternodecoin	masternodecoin
MTX	Matryx	matryx
MUE	MonetaryUnit	monetaryunit
MUSE	MUSE	bitshares-music
MUSIC	Musicoin	musicoin
MVC	Maverick Chain	maverick-chain
MWAT	Restart Energy MWAT	restart-energy-mwat
MXT	MarteXcoin	martexcoin
MYB	MyBit Token	mybit-token
MYST	Mysterium	mysterium
MZC	MAZA	mazacoin
NAMO	NamoCoin	namocoin
NANJ	NANJCOIN	nanjcoin
NANO	Nano	nano
NANOX	Project-X	project-x
NAS	Nebulas	nebulas-token
NAV	NavCoin	nav-coin
NAVI	Naviaddress	naviaddress
NBAI	Nebula AI	nebula-ai
NCASH	Nucleus Vision	nucleus-vision
NCT	PolySwarm	polyswarm
NDC	NEVERDIE	neverdie
NEBL	Neblio	neblio
NEC	Nectar	nectar
NEO	NEO	neo
NEOG	NEO GOLD	neo-gold
NEOS	NeosCoin	neoscoin
NET	Nimiq Exchange Token	nimiq
NETCOIN	NetCoin	netcoin
NETKO	Netko	netko
NEU	Neumark	neumark
NEVA	NevaCoin	nevacoin
NEWB	Newbium	newbium
NEXO	Nexo	nexo
NGC	NAGA	naga
NIO	Autonio	autonio
NKA	IncaKoin	incakoin
NKC	Nework	nework
NKN	NKN	nkn
NLC2	NoLimitCoin	nolimitcoin
NLG	Gulden	gulden
NLX	Nullex	nullex
NMC	Namecoin	namecoin
NMR	Numeraire	numeraire
NMS	Numus	numus
NOAH	Noah Coin	noah-coin
NOBL	NobleCoin	noblecoin
NODC	NodeCoin	nodecoin
NOX	Nitro	nitro
NPER	NPER	nper
NPX	NaPoleonX	napoleonx
NPXS	Pundi X	pundi-x
NRO	Neuro	neuro
NSR	NuShares	nushares
NTK	Neurotoken	neurotoken
NTO	Fujinto	fujinto
NTRN	Neutron	neutron
NTWK	Network Token	network-token
NTY	Nexty	nexty
NUKO	Nekonium	nekonium
NULS	Nuls	nuls
NUMUS	NumusCash	numuscash
NVC	Novacoin	novacoin
NXC	Nexium	nexium
NXS	Nexus	nexus
NXT	Nxt	nxt
NYAN	Nyancoin	nyancoin
NYC	NewYorkCoin	newyorkcoin
OAX	OAX	oax
OBITS	OBITS	obits
OC	OceanChain	oceanchain
OCC	Octoin Coin	octoin-coin
OCL	Oceanlab	oceanlab
OCN	Odyssey	odyssey
OCT	OracleChain	oraclechain
ODE	ODEM	odem
ODN	Obsidian	obsidian
OF	OFCOIN	ofcoin
OFF	Cthulhu Offerings	cthulhu-offerings
OK	OKCash	okcash
OMC	Omicron	omicron
OMG	OmiseGO	omisego
OMNI	Omni	omni
ONG	onG.social	ongsocial
ONION	DeepOnion	deeponion
ONT	Ontology	ontology
ONX	Onix	onix
OOT	Utrum	utrum
OP	Operand	operand
OPAL	Opal	opal
OPC	OP Coin	op-coin
OPEN	Open Platform	open-platform
OPES	Opescoin	opescoin
OPT	Opus	opus
ORB	Orbitcoin	orbitcoin
ORE	Galactrum	galactrum
ORI	Origami	origami
ORME	Ormeus Coin	ormeus-coin
OST	OST	ost
OTN	Open Trading Network	open-trading-network
OTX	Octanox	octanox
OX	OX Fina	ox-fina
OXY	Oxycoin	oxycoin
PAI	PCHAIN	pchain
PAK	Pakcoin	pakcoin
PAL	PolicyPal Network	policypal-network
PARETO	Pareto Network	pareto-network
PART	Particl	particl
PASC	Pascal Coin	pascal-coin
PASL	Pascal Lite	pascal-lite
PAT	Patron	patron
PAY	TenX	tenx
PAYX	Paypex	paypex
PBL	Publica	publica
PBT	Primalbase Token	primalbase
PCL	Peculium	peculium
PCN	PeepCoin	peepcoin
PCOIN	Pioneer Coin	pioneer-coin
PCS	Pabyosi Coin Special	pabyosi-coin-special
PEPECASH	Pepe Cash	pepe-cash
PEX	PosEx	posex
PFR	Payfair	payfair
PHI	PHI Token	phi-token
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
PIXIE	Pixie Coin	pixie-coin
PKB	ParkByte	parkbyte
PKT	Playkey	playkey
PLACO	PlayerCoin	playercoin
PLAN	Plancoin	plancoin
PLAY	HEROcoin	herocoin
PLBT	Polybius	polybius
PLC	PlusCoin	pluscoin
PLNC	PLNcoin	plncoin
PLR	Pillar	pillar
PLU	Pluton	pluton
PLX	PlexCoin	plexcoin
PND	Pandacoin	pandacoin-pnd
PNT	Penta	penta
PNX	Phantomx	phantomx
POA	POA Network	poa-network
POE	Po.et	poet
POKE	PokeCoin	pokecoin
POLCOIN	Polcoin	polcoin
POLIS	Polis	polis
POLL	ClearPoll	clearpoll
POLY	Polymath	polymath-network
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
PROUD	PROUD Money	proud-money
PRS	PressOne	pressone
PRX	Printerium	printerium
PST	Primas	primas
PTC	Pesetacoin	pesetacoin
PTOY	Patientory	patientory
PURA	Pura	pura
PURE	Pure	pure
PUT	PutinCoin	putincoin
PUTOKEN	Profile Utility Token	profile-utility-token
PWR	Powercoin	powercoin
PX	PX	px
PXC	Phoenixcoin	phoenixcoin
PXI	Prime-XI	prime-xi
PYLNT	Pylon Network	pylon-network
PZM	PRIZM	prizm
Q2C	QubitCoin	qubitcoin
QASH	QASH	qash
QAU	Quantum	quantum
QBC	Quebecoin	quebecoin
QBIC	Qbic	qbic
QBT	Qbao	qbao
QCN	QuazarCoin	quazarcoin
QKC	QuarkChain	quarkchain
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
RBLX	Rublix	rublix
RBT	Rimbit	rimbit
RBY	Rubycoin	rubycoin
RC	RussiaCoin	russiacoin
RCN	Ripio Credit Network	ripio-credit-network
RCOIN	Rcoin	rcoin
RCT	RealChain	realchain
RDD	ReddCoin	reddcoin
RDN	Raiden Network Token	raiden-network-token
READ	Read	read
REAL	REAL	real
REBL	REBL	rebl
REC	Regalcoin	regalcoin
RED	RedCoin	redcoin
RED2	RED	red
REE	ReeCoin	reecoin
REF	RefToken	reftoken
REGA	Regacoin	regacoin
REM	Remme	remme
REN	Republic Protocol	republic-protocol
REP	Augur	augur
REPO	REPO	repo
REQ	Request Network	request-network
REX	imbrex	imbrex
RFR	Refereum	refereum
RHOC	RChain	rchain
RIC	Riecoin	riecoin
RICHX	RichCoin	richcoin
RISE	Rise	rise
RIYA	Etheriya	etheriya
RKC	Royal Kingdom Coin	royal-kingdom-coin
RKT	Rock	rock
RLC	iExec RLC	rlc
RLT	RouletteToken	roulettetoken
RMC	Russian Mining Coin	russian-mining-coin
RMT	SureRemit	sureremit
RNS	Renos	renos
RNT	OneRoot Network	oneroot-network
RNTB	BitRent	bitrent
ROOFS	Roofs	roofs
ROYAL	RoyalCoin	royalcoin
RPC	RonPaulCoin	ronpaulcoin
RPX	Red Pulse	red-pulse
RSGP	RSGPcoin	rsgpcoin
RUFF	Ruff	ruff
RUNNERS	Runners	runners
RUP	Rupee	rupee
RUPX	Rupaya	rupaya
RVN	Ravencoin	ravencoin
RVR	RevolutionVR	revolutionvr
RVT	Rivetz	rivetz
RYZ	ANRYZE	anryze
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
SCC	StockChain	stockchain
SCL	Sociall	sociall
SCORE	Scorecoin	scorecoin
SCRT	SecretCoin	secretcoin
SCS	SpeedCash	speedcash
SCT	Soma	soma
SDC	ShadowCash	shadowcash
SDRN	Senderon	senderon
SEELE	Seele	seele
SEN	Consensus	consensus
SENC	Sentinel Chain	sentinel-chain
SEND	Social Send	social-send
SENSE	Sense	sense
SENT	Sentinel	sentinel
SEQ	Sequence	sequence
SETH	Sether	sether
SEXC	ShareX	sharex
SFC	Solarflarecoin	solarflarecoin
SGCC	Super Game Chain	super-game-chain
SGN	Signals Network	signals-network
SGR	Sugar Exchange	sugar-exchange
SH	Shilling	shilling
SHA	SHACoin	shacoin
SHDW	Shadow Token	shadow-token
SHELL	ShellCoin	shellcoin
SHIFT	Shift	shift
SHIP	ShipChain	shipchain
SHL	Oyster Shell	oyster-shell
SHND	StrongHands	stronghands
SHOP	Shopin	shopin
SHORTY	Shorty	shorty
SHOW	Show	show
SHP	Sharpe Platform Token	sharpe-platform-token
SIB	SIBCoin	sibcoin
SIC	Swisscoin	swisscoin
SIG	Spectiv	signal-token
SIGMA	SIGMAcoin	sigmacoin
SIGT	Signatum	signatum
SISA	SISA	sisa
SJCX	Storjcoin X	storjcoin-x
SJW	SJWCoin	sjwcoin
SKB	Sakura Bloom	sakura-bloom
SKC	Skeincoin	skeincoin
SKIN	SkinCoin	skincoin
SKM	Skrumble Network	skrumble-network
SKR	Sakuracoin	sakuracoin
SKULL	Pirate Blocks	pirate-blocks
SKY	Skycoin	skycoin
SLEVIN	Slevin	slevin
SLFI	Selfiecoin	selfiecoin
SLG	Sterlingcoin	sterlingcoin
SLOTH	Slothcoin	slothcoin
SLR	SolarCoin	solarcoin
SLS	SaluS	salus
SLT	Smartlands	smartlands
SMART	SmartCash	smartcash
SMC	SmartCoin	smartcoin
SMLY	SmileyCoin	smileycoin
SMOKE	Smoke	smoke
SMS	Speed Mining Service	speed-mining-service
SMT	SmartMesh	smartmesh
SNC	SunContract	suncontract
SND	Sand Coin	sand-coin
SNGLS	SingularDTV	singulardtv
SNIP	SnipCoin	snipcoin
SNM	SONM	sonm
SNOV	Snovio	snovio
SNRG	Synergy	synergy
SNT	Status	status
SNTR	Silent Notary	silent-notary
SOAR	Soarcoin	soarcoin
SOC	All Sports	all-sports
SOCC	SocialCoin	socialcoin-socc
SOIL	SOILcoin	soilcoin
SONG	SongCoin	songcoin
SONO	SONO	altcommunity-coin
SOON	SoonCoin	sooncoin
SOUL	Phantasma	phantasma
SPACE	SpaceCoin	spacecoin
SPANK	SpankChain	spankchain
SPC	SpaceChain	spacechain
SPD	Stipend	stipend
SPF	SportyCo	sportyco
SPHR	Sphere	sphere
SPHTX	SophiaTX	sophiatx
SPINDLE	SPINDLE	spindle
SPK	Sparks	sparks
SPORT	SportsCoin	sportscoin
SPR	SpreadCoin	spreadcoin
SPRTS	Sprouts	sprouts
SRC	SecureCoin	securecoin
SRCOIN	SRCOIN	srcoin
SRN	SIRIN LABS Token	sirin-labs-token
SS	Sharder	sharder
SSC	SelfSell	selfsell
SSS	Sharechain	sharechain
STA	Starta	starta
STAC	StarterCoin	startercoin
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
STQ	Storiqa	storiqa
STRAT	Stratis	stratis
STRC	StarCredits	starcredits
STU	bitJob	student-coin
STV	Sativacoin	sativacoin
STX	Stox	stox
SUB	Substratum	substratum
SUMO	Sumokoin	sumokoin
SUP	Superior Coin	superior-coin
SUPER	SuperCoin	supercoin
SUR	Suretly	suretly
SWFTC	SwftCoin	swftcoin
SWIFT	Bitswift	bitswift
SWING	Swing	swing
SWM	Swarm	swarm-fund
SWT	Swarm City	swarm-city
SWTC	Jingtum Tech	jingtum-tech
SWTH	Switcheo	switcheo
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
TBAR	Titanium BAR	titanium-bar
TBX	Tokenbox	tokenbox
TCC	The ChampCoin	the-champcoin
TCOIN	T-coin	t-coin
TCT	TokenClub	tokenclub
TDS	TokenDesk	tokendesk
TDX	Tidex Token	tidex-token
TEAM	TokenStars	tokenstars
TEK	TEKcoin	tekcoin
TEL	Telcoin	telcoin
TELL	Tellurion	tellurion
TEN	Tokenomy	tokenomy
TER	TerraNova	terranova
TES	TeslaCoin	teslacoin
TESLA	TeslaCoilCoin	teslacoilcoin
TFD	TE-FOOD	te-food
TFL	TrueFlip	trueflip
TGC	Tigercoin	tigercoin
TGT	Target Coin	target-coin
THC	HempCoin	hempcoin
THETA	Theta Token	theta-token
TIE	Ties.DB	tiesdb
TIG	Tigereum	tigereum
TIME	Chronobank	chronobank
TIO	Trade Token	trade-token
TIPS	FedoraCoin	fedoracoin
TIT	Titcoin	titcoin
TIX	Blocktix	blocktix
TKA	Tokia	tokia
TKN	TokenCard	tokencard
TKR	CryptoInsight	trackr
TKS	Tokes	tokes
TKY	THEKEY	thekey
TLE	TattooCoin (Limited)	tattoocoin-limited
TNB	Time New Bank	time-new-bank
TNC	Trinity Network Credit	trinity-network-credit
TNS	Transcodium	transcodium
TNT	Tierion	tierion
TOA	ToaCoin	toacoin
TODAY	TodayCoin	todaycoin
TOK	Tokugawa	tokugawa
TOKC	TOKYO	tokyo
TOMO	TomoChain	tomochain
TOP	TopCoin	topcoin
TOPC	TopChain	topchain
TPAY	TokenPay	tokenpay
TRAC	OriginTrail	origintrail
TRAK	TrakInvest	trakinvest
TRC	Terracoin	terracoin
TRCT	Tracto	tracto
TRDT	Trident Group	trident
TRF	Travelflex	travelflex
TRI	Triangles	triangles
TRIG	Triggers	triggers
TRIO	Tripio	tripio
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
TTT	TrustNote	trustnote
TUBE	BitTube	bit-tube
TURBO	TurboCoin	turbocoin
TUSD	TrueUSD	trueusd
TX	TransferCoin	transfercoin
TZC	TrezarCoin	trezarcoin
UBQ	Ubiq	ubiq
UBT	Unibright	unibright
UBTC	United Bitcoin	united-bitcoin
UCASH	U.CASH	ucash
UCOM	United Crypto Community	ucom
UET	Useless Ethereum Token	useless-ethereum-token
UFO	Uniform Fiscal Object	uniform-fiscal-object
UFR	Upfiring	upfiring
UGC	ugChain	ugchain
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
UP	UpToken	uptoken
UQC	Uquid Coin	uquid-coin
UR	UR	ur
URO	Uro	uro
USC	Ultimate Secure Cash	ultimate-secure-cash
USDT	Tether	tether
USNBT	NuBits	nubits
UTC	UltraCoin	ultracoin
UTK	UTRUST	utrust
UTNP	Universa	universa
UTT	United Traders Token	uttoken
UUU	U Network	u-network
V	Version	version
VEC2	VectorAI	vector
VEE	BLOCKv	blockv
VEN	VeChain	vechain
VERI	Veritaseum	veritaseum
VIA	Viacoin	viacoin
VIB	Viberate	viberate
VIBE	VIBE	vibe
VIDZ	PureVidz	purevidz
VIPS	Vipstar Coin	vipstar-coin
VISIO	Visio	visio
VIT	Vice Industry Token	vice-industry-token
VIU	Viuly	viuly
VIVO	VIVO	vivo
VLC	ValueChain	valuechain
VLT	Veltor	veltor
VLTC	Vault Coin	vault-coin
VME	VeriME	verime
VOISE	Voise	voisecom
VOLT	Bitvolt	bitvolt
VOT	VoteCoin	votecoin
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
W3C	W3Coin	w3coin
WA	WA Space	wa-space
WABI	WaBi	wabi
WAN	Wanchain	wanchain
WAND	WandX	wandx
WAVES	Waves	waves
WAX	WAX	wax
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
WIN	WCOIN	wawllet
WINGS	Wings	wings
WINK	Wink	wink
WISH	MyWish	mywish
WOMEN	WomenCoin	women
WORM	HealthyWormCoin	healthywormcoin
WPR	WePower	wepower
WRC	Worldcore	worldcore
WSX	WeAreSatoshi	wearesatoshi
WTC	Waltonchain	waltonchain
X2	X2	x2
XAS	Asch	asch
XAUR	Xaurum	xaurum
XBC	Bitcoin Plus	bitcoin-plus
XBL	Billionaire Token	billionaire-token
XBP	BlitzPredict	blitzpredict
XBTC21	Bitcoin 21	bitcoin-21
XBTS	Beatcoin	beatcoin
XBY	XTRABYTES	xtrabytes
XCN	Cryptonite	cryptonite
XCO	X-Coin	x-coin
XCP	Counterparty	counterparty
XCPO	Copico	copico
XCRE	Creatio	creatio
XCT	C-Bit	c-bit
XCXT	CoinonatX	coinonatx
XDCE	XinFin Network	xinfin-network
XDN	DigitalNote	digitalnote
XEL	Elastic	elastic
XEM	NEM	nem
XES	Proxeus	proxeus
XGOX	XGOX	xgox
XHI	HiCoin	hicoin
XHV	Haven Protocol	haven-protocol
XID	Sphre AIR 	sphre-air
XIN	Infinity Economics	infinity-economics
XIOS	Xios	xios
XJO	Joulecoin	joulecoin
XLC	Leviar	leviar
XLM	Stellar	stellar
XLR	Solaris	solaris
XMC	Monero Classic	monero-classic
XMCC	Monoeci	monacocoin
XMG	Magi	magi
XMO	Monero Original	monero-original
XMR	Monero	monero
XMY	Myriad	myriad
XNK	Ink Protocol	ink-protocol
XNN	Xenon	xenon
XOT	Internet of Things	internet-of-things
XP	Experience Points	experience-points
XPA	XPA	xpa
XPD	PetroDollar	petrodollar
XPM	Primecoin	primecoin
XPTX	PlatinumBAR	platinumbar
XPY	PayCoin	paycoin2
XQN	Quotient	quotient
XRA	Ratecoin	ratecoin
XRC	Rawcoin	rawcoin2
XRE	RevolverCoin	revolvercoin
XRH	Rhenium	rhenium
XRL	Rialto	rialto
XRP	Ripple	ripple
XRY	Royalties	royalties
XSH	SHIELD	shield-xsh
XSN	Stakenet	stakenet
XSPEC	Spectrecoin	spectrecoin
XST	Stealth	stealth
XSTC	Safe Trade Coin	safe-trade-coin
XTD	XTD Coin	xtd-coin
XTL	Stellite	stellite
XTO	Tao	tao
XTZ	Tezos (Pre-Launch)	tezos
XUC	Exchange Union	exchange-union
XVC	Vcash	vcash
XVG	Verge	verge
XWC	WhiteCoin	whitecoin
XYO	XYO Network	xyo-network
XZC	ZCoin	zcoin
YEE	YEE	yee
YOC	Yocoin	yocoin
YOYOW	YOYOW	yoyow
YTN	YENTEN	yenten
ZAP	Zap	zap
ZBC	Zilbercoin	zilbercoin
ZCL	ZClassic	zclassic
ZCO	Zebi	zebi
ZEC	Zcash	zcash
ZEIT	Zeitcoin	zeitcoin
ZEN	ZenCash	zencash
ZENGOLD	ZenGold	zengold
ZENI	Zennies	zennies
ZEPH	Zephyr	zephyr
ZER	Zero	zero
ZET	Zetacoin	zetacoin
ZIL	Zilliqa	zilliqa
ZIP	ZIP	zip
ZIPT	Zippie	zippie
ZLA	Zilla	zilla
ZMC	ZetaMicron	zetamicron
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
