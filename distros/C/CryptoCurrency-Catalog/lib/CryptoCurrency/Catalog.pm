package CryptoCurrency::Catalog;

our $DATE = '2018-11-29'; # DATE
our $VERSION = '20181129.0.0'; # VERSION

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

This document describes version 20181129.0.0 of CryptoCurrency::Catalog (from Perl distribution CryptoCurrency-Catalog), released on 2018-11-29.

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
2GO	CoinToGo	cointogo
300	300 Token	300-token
42	42-coin	42-coin
611	SixEleven	sixeleven
808	808Coin	808coin
8BIT	8Bit	8bit
AAA	Abulaba	abulaba
AAC	Acute Angle Cloud	acute-angle-cloud
ABBC	Alibabacoin	alibabacoin
ABC	Alphabit	alphabitcoinfund
ABDT	Atlantis Blue Digital Token	atlantis-blue-digital-token
ABL	Airbloc	airbloc
ABS	Absolute	absolute
ABT	Arcblock	arcblock
ABX	Arbidex	arbidex
ABY	ArtByte	artbyte
ABYSS	The Abyss	the-abyss
AC	AsiaCoin	asiacoin
AC3	AC3	ac3
ACAT	Alphacat	alphacat
ACC	Accelerator Network	accelerator-network
ACCHAIN	ACChain	acchain
ACDC	Volt	volt
ACE	ACE (TokenStars)	ace
ACED	AceD	aced
ACES	Aces	aces
ACM	Actinium	actinium
ACOIN	Acoin	acoin
ACP	AnarchistsPrime	anarchistsprime
ACRE	ACRE	acre
ACT	Achain	achain
ACTP	Archetypal Network	archetypal-network
ADA	Cardano	cardano
ADB	adbank	adbank
ADC	AudioCoin	audiocoin
ADCN	Asiadigicoin	asiadigicoin
ADCOIN	AdCoin	adcoin
ADH	AdHive	adhive
ADI	Aditus	aditus
ADK	Aidos Kuneen	aidos-kuneen
ADL	Adelphoi	adelphoi
ADST	AdShares	adshares
ADT	adToken	adtoken
ADX	AdEx	adx-net
ADZ	Adzcoin	adzcoin
AE	Aeternity	aeternity
AEC	EmaratCoin	emaratcoin
AEG	Aegeus	aegeus
AEON	Aeon	aeon
AGI	SingularityNET	singularitynet
AGLT	Agrolot	agrolot
AI	POLY AI	poly-ai
AIB	Advanced Internet Blocks	advanced-internet-blocks
AID	AidCoin	aidcoin
AIDOC	AI Doctor	aidoc
AION	Aion	aion
AIT	AICHAIN	aichain
AIX	Aigang	aigang
AKA	Akroma	akroma
ALC	ALLCOIN	allcoin
ALI	AiLink Token	ailink-token
ALIS	ALIS	alis
ALL	Allion	allion
ALT	Alt.Estate token	alt-estate-token
ALTCOIN	Altcoin	altcoin-alt
ALTX	Alttex	alttex
ALX	ALAX	alax
AMB	Ambrosus	amber
AMLT	AMLT	amlt
AMM	MicroMoney	micromoney
AMMO	Ammo Reloaded	ammo-reloaded
AMN	Amon	amon
AMO	AMO Coin	amo-coin
AMP	Synereo	synereo
AMS	AmsterdamCoin	amsterdamcoin
ANC	Anoncoin	anoncoin
ANI	Animecoin	animecoin
ANON	ANON	anon
ANT	Aragon	aragon
AOA	Aurora	aurora
AOG	smARTOFGIVING	smartofgiving
APC	Alpha Coin	alpha-coin
APH	Aphelion	aphelion
APIS	APIS	apis
APL	Apollo Currency	apollo-currency
APOT	APOT	apot
APPC	AppCoins	appcoins
APR	APR Coin	apr-coin
APX	APX	apx
ARB	ARBITRAGE	arbitrage
ARBIT	ARbit	arbit
ARC	Advanced Technology Coin	arcticcoin
ARCO	AquariusCoin	aquariuscoin
ARCT	ArbitrageCT	arbitragect
ARDR	Ardor	ardor
AREPA	Arepacoin	arepacoin
ARG	Argentum	argentum
ARGUS	Argus	argus
ARI	Aricoin	aricoin
ARION	Arion	arion
ARK	Ark	ark
ARN	Aeron	aeron
ARO	Arionum	arionum
ART	Maecenas	maecenas
ARY	Block Array	block-array
ASA	Asura Coin	asura-coin
ASAFE2	AllSafe	allsafe
AST	AirSwap	airswap
ASTON	Aston	aston
AT	ABCC Token	abcc-token
ATB	ATBCoin	atbcoin
ATC	Arbitracoin	arbitracoin
ATCC	ATC Coin	atc-coin
ATD	Atidium	atidium
ATH	Atheios	atheios
ATL	ATLANT	atlant
ATM	ATMChain	attention-token-of-media
ATMI	Atonomi	atonomi
ATMOS	Atmos	atmos
ATN	ATN	atn
ATOM	Atomic Coin	atomic-coin
ATP	Atlas Protocol	atlas-protocol
ATS	Authorship	authorship
AU	AurumCoin	aurumcoin
AUC	Auctus	auctus
AUR	Auroracoin	auroracoin
AURA	Aurora DAO	aurora-dao
AUTO	Cube	cube
AUX	Auxilium	auxilium
AV	AvatarCoin	avatarcoin
AVA	Travala	travala
AVH	Animation Vision Cash	animation-vision-cash
AVINOC	AVINOC	avinoc
AVT	Aventus	aventus
AWARE	AWARE	aware
AXIOM	Axiom	axiom
AXPR	aXpire	axpire
AZART	Azart	azart
B2B	B2BX	b2bx
B2X	SegWit2x	segwit2x
B@	Bankcoin	bankcoin
BAAS	BaaSid	baasid
BANCA	Banca	banca
BANK	Bank Coin	bank-coin
BAT	Basic Attention Token	basic-attention-token
BAX	BABB	babb
BAY	BitBay	bitbay
BBC	TraDove B2BCoin	b2bcoin
BBK	Brickblock	brickblock
BBN	Banyan Network	banyan-network
BBO	Bigbom	bigbom
BBP	BiblePay	biblepay
BBR	Boolberry	boolberry
BBS	BBSCoin	bbscoin
BC	Block-Chain.com	block-chain-com
BCA	Bitcoin Atom	bitcoin-atom
BCAC	Business Credit Alliance Chain	business-credit-alliance-chain
BCARD	CARDbuyers	cardbuyers
BCD	Bitcoin Diamond	bitcoin-diamond
BCDN	BlockCDN	blockcdn
BCDT	Blockchain Certified Data Token	blockchain-certified-data-token
BCF	Bitcoin Fast	bitcoinfast
BCH	Bitcoin Cash	bitcoin-cash
BCI	Bitcoin Interest	bitcoin-interest
BCN	Bytecoin	bytecoin-bcn
BCO	BridgeCoin	bridgecoin
BCPT	BlockMason Credit Protocol	blockmason
BCV	BitCapitalVendor	bitcapitalvendor
BCX	BitcoinX	bitcoinx
BCY	BitCrystals	bitcrystals
BCZERO	Buggyra Coin Zero	buggyra-coin-zero
BDG	BitDegree	bitdegree
BDL	Bitdeal	bitdeal
BDT	BDT Token	bdt-token
BEAT	BEAT	beat
BEE	Bee Token	bee-token
BEET	Beetle Coin	beetle-coin
BELA	Bela	belacoin
BEN	BitCoen	bitcoen
BENJI	BenjiRolls	benjirolls
BENZ	Benz	benz
BERN	BERNcash	berncash
BERRY	Rentberry	rentberry
BET	DAO.Casino	dao-casino
BETACOIN	BetaCoin	betacoin
BETHER	Bethereum	bethereum
BETR	BetterBetting	betterbetting
BEZ	Bezop	bezop
BFF	BFFDoom	bffdoom
BFT	BnkToTheFuture	bnktothefuture
BGG	Bgogo Token	bgogo-token
BHPC	BHPCash	bhpcash
BIFI	Bitcoin File	bitcoin-file
BIGUP	BigUp	bigup
BIO	BioCoin	biocoin
BIR	Birake	birake
BIRDS	Birds	birds
BIS	Bismuth	bismuth
BIT	BitRewards	bitrewards
BITB	Bean Cash	bean-cash
BITBAR	BitBar	bitbar
BITBLOCKS	Bitblocks	bitblocks
BITBTC	bitBTC	bitbtc
BITCF	First Bitcoin Capital	first-bitcoin-capital
BITCLAVE	BitClave	bitclave
BITCNY	bitCNY	bitcny
BITCOINUS	Bitcoinus	bitcoinus
BITEUR	bitEUR	biteur
BITF	BitF	bitf
BITG	Bitcoin Green	bitcoin-green
BITGOLD	bitGold	bitgold
BITMARK	Bitmark	bitmark
BITMONEY	BitMoney	bitmoney
BITS	Bitswift	bitswift
BITSILVER	bitSilver	bitsilver
BITSTAR	Bitstar	bitstar
BITUSD	bitUSD	bitusd
BITX	BitScreener Token	bitscreener-token
BIX	Bibox Token	bibox-token
BKBT	BeeKan	beekan
BKX	BANKEX	bankex
BLACK	eosBLACK	eosblack
BLAST	BLAST	blast
BLAZE	BlazeCoin	blazecoin
BLAZR	BlazerCoin	blazercoin
BLC	Blakecoin	blakecoin
BLK	BlackCoin	blackcoin
BLN	Bolenum	bolenum
BLOC	BLOC.MONEY	bloc-money
BLOCK	Blocknet	blocknet
BLOCKLANCER	Blocklancer	blocklancer
BLT	Bloom	bloomtoken
BLU	BlueCoin	bluecoin
BLUE	Blue Protocol	ethereum-blue
BLZ	Bluzelle	bluzelle
BMC	Blackmoon	blackmoon
BMH	BlockMesh	blockmesh
BMX	BitMart Token	bitmart-token
BNB	Binance Coin	binance-coin
BNC	Bionic	bionic
BND	Blocknode	blocknode
BNK	Bankera	bankera
BNN	BrokerNekoNetwork	brokernekonetwork
BNT	Bancor	bancor
BNTY	Bounty0x	bounty0x
BOAT	BOAT	doubloon
BOB	Bob&#39;s Repair	bobs-repair
BOC	BingoCoin	bingocoin
BOE	Bodhi [ETH]	bodhi-eth
BOLI	Bolivarcoin	bolivarcoin
BON	Bonpay	bonpay
BOS	BOScoin	boscoin
BOST	BoostCoin	boostcoin
BOT	Bodhi	bodhi
BOUTS	BoutsPro	boutspro
BOX	BOX Token	box-token
BOXX	BOXX Token [Blockparty]	boxx-token-blockparty
BPL	Blockpool	blockpool
BPT	Blockport	blockport
BQ	bitqy	bitqy
BQT	Blockchain Quotations Index Token	blockchain-quotations-index-token
BRAT	BROTHER	brat
BRD	Bread	bread
BRIA	BriaCoin	briacoin
BRIT	BritCoin	britcoin
BRK	Breakout	breakout
BRM	BrahmaOS	brahmaos
BRO	Bitradio	bitradio
BRX	Breakout Stake	breakout-stake
BRZC	Breezecoin	breezecoin
BSC	BowsCoin	bowscoin
BSD	BitSend	bitsend
BSM	Bitsum	bitsum
BSN	Bastonet	bastonet
BSTN	BitStation	bitstation
BSTY	GlobalBoost-Y	globalboost-y
BSV	Bitcoin SV	bitcoin-sv
BSX	Bitspace	bitspace
BTA	Bata	bata
BTAD	Bitcoin Adult	bitcoin-adult
BTB	Bitibu Coin	bitibu-coin
BTBc	Bitbase	bitbase
BTC	Bitcoin	bitcoin
BTCM	BTCMoon	btcmoon
BTCN	BitcoiNote	bitcoinote
BTCONE	BitCoin One	bitcoin-one
BTCP	Bitcoin Private	bitcoin-private
BTCRED	Bitcoin Red	bitcoin-red
BTCS	Bitcoin Scrypt	bitcoin-scrypt
BTCX	Bitcoin X	bitcoin-x
BTCZ	BitcoinZ	bitcoinz
BTDX	Bitcloud	bitcloud
BTG	Bitcoin Gold	bitcoin-gold
BTK	Bitcoin Token	bitcoin-token
BTM	Bytom	bytom
BTN	BitNewChain	bitnewchain
BTNT	BitNautic Token	bitnautic-token
BTO	Bottos	bottos
BTPL	Bitcoin Planet	bitcoin-planet
BTQ	BitQuark	bitquark
BTR	Bitether	bitether
BTRN	Biotron	biotron
BTS	BitShares	bitshares
BTT	Blocktrade Token	blocktrade-token
BTW	BitWhite	bitwhite
BTWTY	Bit20	bit20
BTX	Bitcore	bitcore
BTXC	Bettex Coin	bettex-coin
BU	BUMO	bumo
BUB	Bubble	bubble
BUBO	Budbo	budbo
BUMBA	BumbaCoin	bumbacoin
BUN	BunnyCoin	bunnycoin
BUNNY	BunnyToken	bunnytoken
BURST	Burst	burst
BUT	BitUP Token	bitup-token
BUZZ	BuzzCoin	buzzcoin
BWK	Bulwark	bulwark
BWS	Bitcoin W Spectrum	bitcoin-w-spectrum
BWT	Bittwatt	bittwatt
BWX	Blue Whale Token	blue-whale-token
BZ	Bit-Z Token	bit-z-token
BZL	BZLCOIN	bzlcoin
BZNT	Bezant	bezant
BZX	Bitcoin Zero	bitcoin-zero
C2	Coin2.1	coin2-1
C20	CRYPTO20	c20
C2C	C2C System	c2c-system
C2P	Coin2Play	coin2play
C8	Carboneum [C8] Token	carboneum-c8-token
CAB	Cabbage	cabbage
CAG	Change	change
CAN	CanYaCoin	canyacoin
CANDY	Candy	candy
CANETWORK	Content and AD Network	content-and-ad-network
CANN	CannabisCoin	cannabiscoin
CAPP	Cappasity	cappasity
CAR	CarBlock	carblock
CARAT	CARAT	carat
CARBON	Carboncoin	carboncoin
CARD	Cardstack	cardstack
CARE	Carebit	carebit
CAS	Cashaa	cashaa
CASH	Cashcoin	cashcoin
CASHBERY	Cashbery Coin	cashbery-coin
CAT	BlockCAT	blockcat
CATO	CatoCoin	catocoin
CAZ	Cazcoin	cazcoin
CBC	CashBet Coin	cashbet-coin
CBT	CommerceBlock	commerceblock
CBX	Bullion	bullion
CCC	Concierge Coin	concierge-coin
CCCX	Clipper Coin	clipper-coin
CCL	CYCLEAN	cyclean
CCO	Ccore	ccore
CCRB	CryptoCarbon	cryptocarbon
CCT	Crystal Clear 	crystal-clear
CDC	Commerce Data Connection	commerce-data-connection
CDM	Condominium	condominium
CDN	Canada eCoin	canada-ecoin
CDT	Blox	blox
CDX	Commodity Ad Network	commodity-ad-network
CEDEX	CEDEX Coin	cedex-coin
CEEK	CEEK VR	ceek-vr
CEFS	CryptopiaFeeShares	cryptopiafeeshares
CEL	Celsius	celsius
CEN	Coinsuper Ecosystem Network	coinsuper-ecosystem-network
CENNZ	Centrality	centrality
CENTAURE	Centaure	centaure
CET	CoinEx Token	coinex-token
CF	Californium	californium
CFC	CoffeeCoin	coffeecoin
CFI	Cofound.it	cofound-it
CFL	CryptoFlow	cryptoflow
CFUN	CFun	cfun
CGEN	CommunityGeneration	communitygeneration
CHAT	ChatCoin	chatcoin
CHE	Crypto Harbor Exchange	crypto-harbor-exchange
CHEESE	Cheesecoin	cheesecoin
CHESS	ChessCoin	chesscoin
CHEX	CHEX	chex
CHIPS	CHIPS	chips
CHP	CoinPoker	coinpoker
CHSB	SwissBorg	swissborg
CHX	Own	own
CIF	Crypto Improvement Fund	crypto-improvement-fund
CIT	CariNet	carinet
CIV	Civitas	civitas
CJ	Cryptojacks	cryptojacks
CJS	CJs	cjs
CJT	ConnectJob	connectjob
CKUSD	CK USD	ckusd
CL	Coinlancer	coinlancer
CLAM	Clams	clams
CLN	Colu Local Network	colu-local-network
CLO	Callisto Network	callisto-network
CLOAK	CloakCoin	cloakcoin
CLUB	ClubCoin	clubcoin
CMCT	Crowd Machine	crowd-machine
CMIT	CMITCOIN	cmitcoin
CMM	Commercium	commercium
CMOVCT	Cyber Movie Chain	cyber-movie-chain
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
COBRA	Cobrabytes	cobrabytes
COFI	CoinFi	coinfi
COIN	Coinvest	coinvest
COLX	ColossusXT	colossusxt
COMET	Comet	comet
COMP	Compound Coin	compound-coin
CONI	Coni	coni
CONTENTBOX	ContentBox	contentbox
CONX	Concoin	concoin
COR	CORION	corion
COSM	Cosmo Coin	cosmo-coin
COSS	COSS	coss
COTN	CottonCoin	cottoncoin
COU	Couchain	couchain
COUPE	Coupecoin	coupecoin
COV	Covesting	covesting
COVAL	Circuits of Value	circuits-of-value
CPAY	Cryptopay	cryptopay
CPC	Capricoin	capricoin
CPCHAIN	CPChain	cpchain
CPLO	Cpollo	cpollo
CPN	CompuCoin	compucoin
CPT	Cryptaur	cryptaur
CPX	Apex	apex
CPY	COPYTRACK	copytrack
CRAVE	Crave	crave
CRB	Creditbit	creditbit
CRBT	Cruisebit	cruisebit
CRC	CryCash	crycash
CRD	CryptalDash	cryptaldash
CRE	Cybereits	cybereits
CREA	CREA	crea
CRED	Verify	verify
CREDO	Credo	credo
CREVA	CrevaCoin	crevacoin
CRM	Cream	cream
CROAT	CROAT	croat
CROP	Cropcoin	cropcoin
CROWD	CrowdCoin	crowdcoin
CRPT	Crypterium	crypterium
CRW	Crown	crown
CRYP	CrypticCoin	crypticcoin
CRYPTOSOUL	CryptoSoul	cryptosoul
CS	Credits	credits
CSC	CasinoCoin	casinocoin
CSM	Consentium	consentium
CSNO	BitDice	bitdice
CST	Cryptosolartech	cryptosolartech
CSTL	Castle	castle
CTC	Credit Tag Chain	credit-tag-chain
CTIC2	Coimatic 2.0	coimatic-2
CTIC3	Coimatic 3.0	coimatic-3
CTL	Citadel	citadel
CTRT	Cryptrust	cryptrust
CTX	CarTaxi Token	cartaxi-token
CTXC	Cortex	cortex
CUBIT	Cubits	cubits
CURE	Curecoin	curecoin
CV	carVertical	carvertical
CVC	Civic	civic
CVN	CVCoin	cvcoin
CVT	CyberVein	cybervein
CWV	CWV Chain	cwv-chain
CXO	CargoX	cargox
CXT	Coinonat	coinonat
CYFM	CyberFM	cyberfm
CYL	Crystal Token	crystal-token
CYMT	CyberMusic	cybermusic
CZR	CanonChain	cononchain
D	Denarius	denarius-dnr
DAC	Davinci Coin	davinci-coin
DACC	DACC	dacc
DACH	DACH Coin	dach-coin
DACS	DACSEE	dacsee
DADI	DADI	dadi
DAG	Constellation	constellation
DAGT	Digital Asset Guarantee Token	digital-asset-guarantee-token
DAI	Dai	dai
DALC	Dalecoin	dalecoin
DAN	Daneel	daneel
DAPS	DAPS Token	daps-token
DAR	Darcrus	darcrus
DART	DarexTravel	darextravel
DASC	DasCoin	dascoin
DASH	Dash	dash
DAT	Datum	datum
DATA	Streamr DATAcoin	streamr-datacoin
DATP	Decentralized Asset Trading Platform	decentralized-asset-trading-platform
DATX	DATx	datx
DAV	DAV Coin	dav-coin
DAX	DAEX	daex
DAXT	Digital Asset Exchange Token	digital-asset-exchange-token
DAXX	DaxxCoin	daxxcoin
DAY	Chronologic	chronologic
DBC	DeepBrain Chain	deepbrain-chain
DBET	DecentBet	decent-bet
DBIX	DubaiCoin	dubaicoin-dbix
DCC	Distributed Credit Chain	distributed-credit-chain
DCN	Dentacoin	dentacoin
DCR	Decred	decred
DCT	DECENT	decent
DCY	Dinastycoin	dinastycoin
DDD	Scry.info	scryinfo
DDX	dietbitcoin	dietbitcoin
DEAL	iDealCash	idealcash
DEB	Debitum	debitum-network
DEC	Darico Ecosystem Coin	darcio-ecosystem-coin
DEEX	DEEX	deex
DELIZ	Delizia	delizia
DELTA	DeltaChain	delta-chain
DEM	Deutsche eMark	deutsche-emark
DENT	Dent	dent
DERO	Dero	dero
DEUS	DeusCoin	deuscoin
DEV	DeviantCoin	deviantcoin
DEW	DEW	dew
DEX	DEX	dex
DFT	DraftCoin	draftcoin
DGB	DigiByte	digibyte
DGC	Digitalcoin	digitalcoin
DGD	DigixDAO	digixdao
DGS	Dragonglass	dragonglass
DGTX	Digitex Futures	digitex-futures
DGX	Digix Gold Token	digix-gold-token
DICE	Etheroll	etheroll
DIG	Dignity	dignity
DIGIFINEX	DigiFinexToken	digifinextoken
DIM	DIMCOIN	dimcoin
DIME	Dimecoin	dimecoin
DIN	Dinero	dinero
DIT	Digital Insurance Token	digital-insurance-token
DIVI	Divi	divi
DIVX	Divi Exchange Token	divi-exchange-token
DIX	Dix Asset	dix-asset
DKPC	DarkPayCoin	darkpaycoin
DLC	Dollarcoin	dollarcoin
DLT	Agrello	agrello-delta
DMB	Digital Money Bits	digital-money-bits
DMC	DynamicCoin	dynamiccoin
DMD	Diamond	diamond
DML	Decentralized Machine Learning	decentralized-machine-learning
DMT	DMarket	dmarket
DNA	EncrypGen	encrypgen
DNT	district0x	district0x
DNZ	Adenz	adenz
DOCK	Dock	dock
DOGE	Dogecoin	dogecoin
DOLLAR	Dollar Online	dollar-online
DOPE	DopeCoin	dopecoin
DOR	Dorado	dorado
DOT	Dotcoin	dotcoin
DOV	Dovu	dovu
DOW	DOWCOIN	dowcoin
DP	DigitalPrice	digitalprice
DPN	DIPNET	dipnet
DPY	Delphy	delphy
DRG	Dragon Coins	dragon-coins
DRGN	Dragonchain	dragonchain
DRM	Dreamcoin	dreamcoin
DROP	Dropil	dropil
DRPU	DCORP Utility	drp-utility
DRT	DomRaider	domraider
DRXNE	DROXNE	droxne
DSR	Desire	desire
DT	Dragon Token	dragon-token
DTA	DATA	data
DTB	Databits	databits
DTC	Datacoin	datacoin
DTEM	Dystem	dystem
DTH	Dether	dether
DTR	Dynamic Trading Rights	dynamic-trading-rights
DTRC	Datarius Credit	datarius-credit
DTX	DaTa eXchange	data-exchange
DUO	ParallelCoin	parallelcoin
DUTCH	Dutch Coin	dutch-coin
DWS	DWS	dws
DX	DxChain Token	dxchain-token
DXT	Datawallet	datawallet
DYN	Dynamic	dynamic
EAG	EA Coin	ea-coin
EARTH	Earth Token	earth-token
EBC	EBCoin	ebcoin
EBET	EthBet	ethbet
EBST	eBoost	eboostcoin
EBTC	eBitcoin	ebtcnew
ECA	Electra	electra
ECASH	Ethereum Cash	ethereumcash
ECC	ECC	eccoin
ECO	EcoCoin	ecocoin
ECOB	Ecobit	ecobit
ECOM	Omnitude	omnitude
ECOREAL	Ecoreal Estate	ecoreal-estate
ECT	SuperEdge	superedge
EDG	Edgeless	edgeless
EDN	Eden	eden
EDO	Eidoo	eidoo
EDR	E-Dinar Coin	e-dinar-coin
EDRCOIN	EDRCoin	edrcoin
EDS	Endorsit	endorsit
EDT	EtherDelta Token	etherdelta-token
EDU	EduCoin	edu-coin
EFL	e-Gulden	e-gulden
EFX	Effect.AI	effect-ai
EFYT	Ergo	ergo
EGC	EverGreenCoin	evergreencoin
EGCC	Engine	engine
EGEM	EtherGem	ethergem
EGT	Egretia	egretia
EGX	EagleX	eaglex
EJOY	EJOY	ejoy
EKO	EchoLink	echolink
EKT	EDUCare	educare
EL	Elcoin	elcoin-el
ELA	Elastos	elastos
ELE	Elementrem	elementrem
ELEC	Electrify.Asia	electrifyasia
ELF	aelf	aelf
ELI	Eligma Token	eligma-token
ELITE	Ethereum Lite	ethereum-lite
ELIX	Elixir	elixir
ELLA	Ellaism	ellaism
ELLI	Elliot Coin	elliot-coin
ELS	Elysium	elysium
ELTCOIN	ELTCOIN	eltcoin
ELY	Elysian	elysian
EMB	EmberCoin	embercoin
EMC	Emercoin	emercoin
EMC2	Einsteinium	einsteinium
EMD	Emerald Crypto	emerald
EMPR	empowr coin	empowr-coin
ENDOR	Endor Protocol	endor-protocol
ENG	Enigma	enigma
ENGT	Engagement Token	engagement-token
ENJ	Enjin Coin	enjin-coin
ENT	Eternity	eternity
ENTS	EUNOMIA	eunomia
EOS	EOS	eos
EOSDAC	eosDAC	eosdac
EPLUS	EPLUS Coin	eplus-coin
EPY	Emphy	emphy
EQL	Equal	equal
EQT	EquiTrader	equitrader
ERA	ERA	blakestar
ERC20	ERC20	erc20
ERO	Eroscoin	eroscoin
ERT	Eristica	eristica
ERY	Eryllium	eryllium
ESCE	Escroco Emerald	escroco-emerald
ESCO	EscrowCoin	escrowcoin
ESN	Ethersocial	ethersocial
ESP	Espers	espers
ESS	Essentia	essentia
EST	Esports Token	esports-token
ESZ	EtherSportz	ethersportz
ETA	Etheera	etheera
ETBS	Ethbits	ethbits
ETC	Ethereum Classic	ethereum-classic
ETG	Ethereum Gold	ethereum-gold
ETH	Ethereum	ethereum
ETHD	Ethereum Dark	ethereum-dark
ETHM	Ethereum Meta	ethereum-meta
ETHO	Ether-1	ether-1
ETHOS	Ethos	ethos
ETI	EtherInc	etherinc
ETK	EnergiToken	energitoken
ETN	Electroneum	electroneum
ETP	Metaverse ETP	metaverse
ETTETH	encryptotel-eth	encryptotel-eth
ETTWAVES	EncryptoTel [WAVES]	encryptotel
ETZ	Ether Zero	ether-zero
EUC	Eurocoin	eurocoin
EUNO	EUNO	euno
EURS	STASIS EURS	stasis-eurs
EVC	EventChain	eventchain
EVE	Devery	devery
EVENCOIN	EvenCoin	evencoin
EVI	Evimeria	evimeria
EVIL	Evil Coin	evil-coin
EVN	Envion	envion
EVR	Everus	everus
EVX	Everex	everex
EXC	Eximchain	eximchain
EXCALIBUR	Excaliburcoin	excaliburcoin
EXCL	ExclusiveCoin	exclusivecoin
EXMR	EXMR	exmr
EXP	Expanse	expanse
EXRN	EXRNchain	exrnchain
EXT	Experience Token	experience-token
EXY	Experty	experty
EZT	EZToken	eztoken
EZW	EZOOW	ezoow
F1C	Future1coin	future1coin
FACE	Faceter	faceter
FAIR	FairCoin	faircoin
FAIRGAME	FairGame	fairgame
FANS	Fantasy Cash	fantasy-cash
FBN	Fivebalance	fivebalance
FCOIN	FCoin Token	fcoin-token
FCT	Factom	factom
FDX	FidentiaX	fidentiax
FDZ	Friendz	friends
FGC	FantasyGold	fantasygold
FID	Fidelium	fidelium
FIL	Filecoin [Futures]	filecoin
FIRSTBIT	First Bitcoin	first-bitcoin
FJC	FujiCoin	fujicoin
FKX	Knoxstertoken	knoxstertoken
FLASH	Flash	flash
FLAX	Flaxscript	flaxscript
FLDC	FoldingCoin	foldingcoin
FLIK	FLiK	flik
FLIXX	Flixxo	flixxo
FLM	FolmCoin	folmcoin
FLO	FLO	flo
FLOT	Fire Lotto	fire-lotto
FLP	FLIP	flip
FLT	FlutterCoin	fluttercoin
FLUZ	Fluz Fluz	fluz-fluz
FMF	Formosa Financial	formosa-financial
FND	FundRequest	fundrequest
FNKOS	FNKOS	fnkos
FNTB	Fintab	fintab
FOIN	FOIN	foin
FOOD	FoodCoin	food
FOR	FORCE	force
FORK	Forkcoin	forkcoin
FOTA	Fortuna	fortuna
FOX	SmartFox	smartfox
FOXT	Fox Trading	fox-trading
FRC	Freicoin	freicoin
FREC	Freyrchain	freyrchain
FREE	FREE Coin	free-coin
FRGC	Fargocoin	fargocoin
FRN	Francs	francs
FRST	FirstCoin	firstcoin
FSBT	FSBT API Token	fsbt-api-token
FSN	Fusion	fusion
FST	Fastcoin	fastcoin
FT	Fabric Token	fabric-token
FTC	Feathercoin	feathercoin
FTI	FansTime	fanstime
FTM	Fantom	fantom
FTO	FuturoCoin	futurocoin
FTT	FarmaTrust	farmatrust
FTX	FintruX Network	fintrux-network
FTXT	FUTURAX	futurax
FUEL	Etherparty	etherparty
FUN	FunFair	funfair
FUNDZ	FundToken	fundtoken
FUZZ	FuzzBalls	fuzzballs
FXT	FuzeX	fuzex
FYP	FlypMe	flypme
GAM	Gambit	gambit
GAME	GameCredits	gamecredits
GAME2	Game.com	game
GAP	Gapcoin	gapcoin
GARD	Hashgard	hashgard
GARY	President Johnson	president-johnson
GAS	Gas	gas
GAT	Global Awards Token	global-awards-token
GB	GoldBlocks	goldblocks
GBC	Gold Bits Coin	gold-bits-coin
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
GENE	Gene Source Code Chain	gene-source-code-chain
GEO	GeoCoin	geocoin
GET	GET Protocol	get-protocol
GETX	Guaranteed Ethurance Token Extra	guaranteed-ethurance-token-extra
GIC	Giant	giant-coin
GIN	GINcoin	gincoin
GIO	Graviocoin	graviocoin
GLA	Gladius Token	gladius-token
GLD	GoldCoin	goldcoin
GLT	GlobalToken	globaltoken
GMCN	GambleCoin	gamblecoin
GNO	Gnosis	gnosis-gno
GNR	Gainer	gainer
GNT	Golem	golem-network-tokens
GNX	Genaro Network	genaro-network
GO	GoChain	gochain
GOD	Bitcoin God	bitcoin-god
GOLF	Golfcoin	golfcoin
GOLOS	Golos	golos
GOOD	Goodomy	goodomy
GOSS	Gossipcoin	gossipcoin
GOT	GoNetwork	gonetwork
GPKR	Gold Poker	gold-poker
GRC	GridCoin	gridcoin
GRFT	Graft	graft
GRID	Grid+	grid
GRIM	Grimcoin	grimcoin
GRLC	Garlicoin	garlicoin
GRMD	GreenMed	greenmed
GRPH	Graphcoin	graphcoin
GRS	Groestlcoin	groestlcoin
GRWI	Growers International	growers-international
GRX	GOLD Reward Token	gold-reward-token
GSC	Global Social Chain	global-social-chain
GSE	GSENetwork	gsenetwork
GSR	GeyserCoin	geysercoin
GST	Game Stars	game-stars
GTM	Gentarium	gentarium
GTO	Gifto	gifto
GUCCIONE	GuccioneCoin	guccionecoin
GUESS	Peerguess	guess
GUP	Matchpool	guppy
GUSD	Gemini Dollar	gemini-dollar
GVE	Globalvillage Ecosystem	globalvillage-ecosystem
GVT	Genesis Vision	genesis-vision
GXS	GXChain	gxchain
GZE	GazeCoin	gazecoin
GZRO	Gravity	gravity
HAC	Hackspace Capital	hackspace-capital
HAL	Halcyon	halcyon
HALLO	Halloween Coin	halloween-coin
HAND	ShowHand	showhand
HARVEST	Harvest Masternode Coin	harvest-masternode-coin
HAV	Havven	havven
HAVY	Havy	havy
HB	HeartBout	heartbout
HBC	HomeBlockCoin	homeblockcoin
HBT	Hubii Network	hubii-network
HBZ	Helbiz	helbiz
HC	HyperCash	hypercash
HDAC	Hdac	hdac
HEAT	HEAT	heat-ledger
HELP	GoHelpFund	gohelpfund
HER	HeroNode	heronode
HERO	Sovereign Hero	sovereign-hero
HERO2	Hero	hero
HGT	HelloGold	hellogold
HIMUTUAL	Hi Mutual Society	hi-mutual-society
HIRE	HireMatch	hirematch
HIT	HitChain	hitchain
HKN	Hacken	hacken
HLC	HalalChain	halalchain
HLM	Helium	helium
HMC	HarmonyCoin	harmonycoin-hmc
HMQ	Humaniq	humaniq
HNC	Helleniccoin	helleniccoin
HNDC	HondaisCoin	hondaiscoin
HODL	HOdlcoin	hodlcoin
HOLD	HOLD	hold
HONEY	Honey	honey
HORSE	Ethorse	ethorse
HORUS	HorusPay	horuspay
HOT	Holo	holo
HPB	High Performance Blockchain	high-performance-blockchain
HPC	Happycoin	happycoin
HPY	Hyper Pay	hyper-pay
HQT	HyperQuant	hyperquant
HQX	HOQU	hoqu
HRC	Haracoin	haracoin
HSC	HashCoin	hashcoin
HSN	Helper Search Token	helper-search-token
HST	Decision Token	decision-token
HT	Huobi Token	huobi-token
HTH	Help The Homeless Coin	help-the-homeless-coin
HTML	HTMLCOIN	html-coin
HUC	HunterCoin	huntercoin
HUM	Humanscape	humanscape
HUNCOIN	Huncoin	huncoin
HUR	Hurify	hurify
HUSH	Hush	hush
HUZU	HUZU	huzu
HVCO	High Voltage	high-voltage
HVN	Hiveterminal Token	hiveterminal-token
HWC	HollyWoodCoin	hollywoodcoin
HXX	Hexx	hexx
HYB	Hybrid Block	hybrid-block
HYC	HYCON	hycon
HYDRO	Hydro Protocol	hydro-protocol
HYDROGEN	Hydro	hydrogen
HYP	HyperStake	hyperstake
I0C	I0Coin	i0coin
IBANK	iBank	ibank
IBTC	iBTC	ibtc
IC	Ignition	ignition
ICN	Iconomi	iconomi
ICNQ	Iconiq Lab Token	iconiq-lab-token
ICOB	ICOBID	icobid
ICON	Iconic	iconic
ICOO	ICO OpenLedger	ico-openledger
ICR	InterCrone	intercrone
ICX	ICON	icon
IDH	indaHash	indahash
IDOL	IDOL COIN	idol-coin
IDT	InvestDigital	investdigital
IDXM	IDEX Membership	idex-membership
IETH	iEthereum	iethereum
IFC	Infinitecoin	infinitecoin
IFLT	InflationCoin	inflationcoin
IFOOD	Ifoods Chain	ifoods-chain
IFP	Infinipay	infinipay
IFT	InvestFeed	investfeed
IG	IGToken	igtoken
IGNIS	Ignis	ignis
IHF	Invictus Hyperion Fund	invictus-hyperion-fund
IHT	IHT Real Estate Protocol	iht-real-estate-protocol
IIC	Intelligent Investment Chain	intelligent-investment-chain
ILC	ILCoin	ilcoin
IMP	Ether Kingdoms Token	ether-kingdoms-token
IMS	Independent Money System	independent-money-system
IMT	Moneytoken	moneytoken
IMX	Impact	impact
INB	Insight Chain	insight-chain
INC	Influence Chain	influence-chain
INCNT	Incent	incent
INCO	Incodium	incodium
INCX	International Diamond	internationalcryptox
IND	Indorse Token	indorse-token
INDI	Indicoin	indicoin
INFX	Influxcoin	influxcoin
ING	Iungo	iungo
INK	Ink	ink
INN	Innova	innova
INO	INO COIN	ino-coin
INS	Insolar	insolar
INSN	InsaneCoin	insanecoin-insn
INSTAR	Insights Network	insights-network
INSUR	InsurChain	insurchain
INT	Internet Node Token	internet-node-token
INV	Invacio	invacio
INVE	InterValue	intervalue
INXT	Internxt	internxt
IOC	I/O Coin	iocoin
IOG	Playgroundz	playgroundz
ION	ION	ion
IONC	IONChain	ionchain
IOP	Internet of People	internet-of-people
IOST	IOST	iostoken
IOTX	IoTeX	iotex
IOV	Carlive Chain	carlive-chain
IPC	IPChain	ipchain
IPL	VouchForMe	insurepal
IPSX	IP Exchange	ip-exchange
IQ	Everipedia	everipedia
IQCASH	IQ.cash	iqcash
IQN	IQeon	iqeon
IQT	iQuant	iquant
IRD	Iridium	iridium
IRL	IrishCoin	irishcoin
ISR	Insureum	insureum
ITC	IoT Chain	iot-chain
ITI	iTicoin	iticoin
ITL	Italian Lira	italian-lira
ITT	Intelligent Trading Tech	intelligent-trading-foundation
ITZ	Interzone	interzone
IVY	Ivy	ivy
IXC	Ixcoin	ixcoin
IXE	IXTUS Edutainment	ixtus-edutainment
IXT	IXT	ixledger
J	Joincoin	joincoin
J8T	JET8	jet8
JC	Jesus Coin	jesus-coin
JET	Jetcoin	jetcoin
JEW	Shekel	shekel
JIN	Jin Coin	jin-coin
JIYO	Jiyo [OLD]	jiyo-old
JIYOX	JIYO	jiyo
JNT	Jibrel Network	jibrel-network
JOINT	Joint Ventures	joint-ventures
JOT	Jury.Online Token	jury-online-token
JS	JavaScript Token	javascript-token
JSE	JSECOIN	jsecoin
KAN	BitKan	bitkan
KARMAEOS	Karma (EOS)	karma-eos
KB3	B3Coin	b3coin
KBC	Karatgold Coin	karatgold-coin
KBR	Kubera Coin	kubera-coin
KCASH	Kcash	kcash
KCS	KuCoin Shares	kucoin-shares
KED	Darsek	darsek
KEK	KekCoin	kekcoin
KEY	Selfkey	selfkey
KEY2	KEY	key
KICK	KickCoin	kickico
KIN	Kin	kin
KIND	Kind Ads Token	kind-ads-token
KINGN	KingN Coin	kingn-coin
KLKS	Kalkulus	kalkulus
KLN	Kolion	kolion
KMD	Komodo	komodo
KNC	Kyber Network	kyber-network
KNDC	KanadeCoin	kanadecoin
KNEKTED	Knekted	knekted
KNOW	KNOW	know
KNT	Kora Network Token	kora-network-token
KOBO	Kobocoin	kobocoin
KORE	Kore	korecoin
KRB	Karbo	karbo
KRL	Kryll	kryll
KRM	Karma	karma
KRONE	Kronecoin	kronecoin
KST	StarCoin	starcointv
KUN	KUN	kun
KURT	Kurrent	kurrent
KWATT	4NEW	4new
KWH	KWHCoin	kwhcoin
KXC	KingXChain	kingxchain
KZC	KZ Cash	kz-cash
LA	LATOKEN	latoken
LABH	Labh Coin	labh-coin
LALA	LALA World	lala-world
LANA	LanaCoin	lanacoin
LATX	LatiumX	latiumx
LBA	Cred	libra-credit
LBC	LBRY Credits	library-credit
LBTC	LiteBitcoin	litebitcoin
LCC	Litecoin Cash	litecoin-cash
LCP	Litecoin Plus	litecoin-plus
LCS	LocalCoinSwap	local-coin-swap
LDC	Leadcoin	leadcoin
LDOGE	LiteDoge	litedoge
LEDU	Education Ecosystem	education-ecosystem
LEMO	LemoChain	lemochain
LEND	ETHLend	ethlend
LEO	LEOcoin	leocoin
LET	LinkEye	linkeye
LEV	Leverj	leverj
LFT	Linfinity	linfinity
LGO	LGO Exchange	legolas-exchange
LGS	LogisCoin	logiscoin
LIF	Winding Tree	winding-tree
LIFE	LIFE	life
LIGHT	LightChain	lightchain
LIGHTNINGBTC	Lightning Bitcoin	lightning-bitcoin
LIKE	LikeCoin	likecoin
LINA	Lina	lina
LINDA	Linda	linda
LINK	Chainlink	chainlink
LINX	Linx	linx
LION	Coin Lion	coin-lion
LIVE	Live Stars	live-stars
LKK	Lykke	lykke
LKY	Linkey	linkey
LMC	LoMoCoin	lomocoin
LNC	Linker Coin	linker-coin
LND	Lendingblock	lendingblock
LOBS	Lobstex	lobstex
LOC	LockTrip	lockchain
LOCI	LOCIcoin	locicoin
LOG	Woodcoin	woodcoin
LOKI	Loki	loki
LOOM	Loom Network	loom-network
LPC	Lightpaycoin	lightpaycoin
LQD	Liquidity Network	liquidity-network
LRC	Loopring	loopring
LRN	Loopring [NEO]	loopring-neo
LSK	Lisk	lisk
LST	Lendroid Support Token	lendroid-support-token
LSTR	Luna Stars	luna-stars
LTB	LiteBar	litebar
LTC	Litecoin	litecoin
LTCR	Litecred	litecred
LTCU	LiteCoin Ultra	litecoin-ultra
LTHN	Lethean	lethean
LUC	Level Up Coin	level-up
LUN	Lunyr	lunyr
LUNA	Luna Coin	luna-coin
LUX	LUXCoin	luxcoin
LWF	Local World Forwarders	local-world-forwarders
LXT	Litex	litex
LYL	LoyalCoin	loyalcoin
LYM	Lympo	lympo
LYNX	Lynx	lynx
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
MAS	MidasProtocol	midasprotocol
MASH	MASTERNET	masternet
MAX	MaxCoin	maxcoin
MAY	Theresa May Coin	theresa-may-coin
MBC	MicroBitcoin	microbitcoin
MBI	Monster Byte	monster-byte
MBRS	Embers	embers
MCAP	MCAP	mcap
MCC	Moving Cloud Coin	moving-cloud-coin
MCI	Musiconomi	musiconomi
MCO	Crypto.com	crypto-com
MCRN	MACRON	macron
MCT	Master Contract Token	master-contract-token
MDA	Moeda Loyalty Points	moeda-loyalty-points
MDS	MediShares	medishares
MDT	Measurable Data Token	measurable-data-token
MEC	Megacoin	megacoin
MED	MediBloc [QRC20]	medibloc
MEDIBIT	MediBit	medibit
MEDIC	MedicCoin	mediccoin
MEDX	MediBloc [ERC20]	medx
MEET	CoinMeet	coinmeet
MEETONE	MEET.ONE	meetone
MEME	Memetic (PepeCoin)	memetic
MER	Mercury	mercury
MERO	Mero	mero
MESSE	MESSE TOKEN	messe-token
MET	Metronome	metronome
META	Metadium	metadium
METM	MetaMorph	metamorph
MEX	MEX	mex
MFG	SyncFab	syncfab
MFIT	MFIT COIN	mfit-coin
MFT	Mainframe	mainframe
MFTU	Mainstream For The Underground	mainstream-for-the-underground
MGD	MassGrid	massgrid
MGM	Magnum	magnum
MGO	MobileGo	mobilego
MIB	MIB Coin	mib-coin
MIC	Mindexcoin	mindexcoin
MICRO	Micromines	micromines
MILO	MiloCoin	milocoin
MINEX	Minex	minex
MINT	MintCoin	mintcoin
MIOTA	IOTA	iota
MIR	MIR COIN	mir-coin
MITH	Mithril	mithril
MITHRIL	Mithril Ore	mithril-ore
MITX	Morpheus Labs	morpheus-labs
MIXIN	Mixin	mixin
MKR	Maker	maker
MLC	Mallcoin	mallcoin
MLM	MktCoin	mktcoin
MLN	Melon	melon
MMO	MMOCoin	mmocoin
MNC	Mincoin	mincoin
MNE	Minereum	minereum
MNP	MNPCoin	mnpcoin
MNTP	GoldMint	goldmint
MNX	MinexCoin	minexcoin
MOAC	MOAC	moac
MOBI	Mobius	mobius
MOC	Moss Coin	moss-coin
MOD	Modum	modum
MODX	MODEL-X-coin	model-x-coin
MOF	Molecular Future	molecular-future
MOIN	Moin	moin
MOJO	MojoCoin	mojocoin
MOL	Molecule	molecule
MOLK	MobilinkToken	mobilinktoken
MONA	MonaCoin	monacoin
MONK	Monkey Project	monkey-project
MOON	Mooncoin	mooncoin
MORE	More Coin	more-coin
MOT	Olympus Labs	olympus-labs
MOTO	Motocoin	motocoin
MRI	Mirai	mirai
MRK	MARK.SPACE	mark-space
MRPH	Morpheus.Network	morpheus-network
MRQ	MIRQ	mirq
MRT	Miners' Reward Token	miners-reward-token
MSCN	Master Swiscoin	master-swiscoin
MSD	MSD	msd
MSP	Mothership	mothership
MSR	Masari	masari
MST	MustangCoin	mustangcoin
MT	MyToken	mytoken
MTC	doc.com Token	doc-com-token
MTCMESH	MTC Mesh Network	mtc-mesh-network
MTH	Monetha	monetha
MTL	Metal	metal
MTN	Medicalchain	medical-chain
MTNC	Masternodecoin	masternodecoin
MTRC	ModulTrade	modultrade
MTX	Matryx	matryx
MUE	MonetaryUnit	monetaryunit
MUSIC	Musicoin	musicoin
MVC	Maverick Chain	maverick-chain
MVL	Mass Vehicle Ledger	mass-vehicle-ledger
MVP	Merculet	merculet
MWAT	Restart Energy MWAT	restart-energy-mwat
MXM	Maximine Coin	maximine-coin
MXT	MarteXcoin	martexcoin
MYB	MyBit	mybit
MYST	Mysterium	mysterium
NAM	NAM COIN	nam-coin
NANJ	NANJCOIN	nanjcoin
NANO	Nano	nano
NANOX	Project-X	project-x
NAS	Nebulas	nebulas-token
NAV	NavCoin	nav-coin
NAVI	Naviaddress	naviaddress
NBAI	Nebula AI	nebula-ai
NBC	Niobium Coin	niobium-coin
NBR	Niobio Cash	niobio-cash
NCASH	Nucleus Vision	nucleus-vision
NCC	NeuroChain	neurochain
NCP	Newton Coin Project	newton-coin-project
NCT	PolySwarm	polyswarm
NDC	NEVERDIE	neverdie
NDX	nDEX	ndex
NEBL	Neblio	neblio
NEC	Nectar	nectar
NEO	NEO	neo
NEOG	NEO GOLD	neo-gold
NEOS	NeosCoin	neoscoin
NER	Nerves	nerves
NET	Nimiq Exchange Token	nimiq-exchange-token
NETKO	Netko	netko
NETKOIN	NetKoin	netkoin
NEU	Neumark	neumark
NEVA	NevaCoin	nevacoin
NEWOS	NewsToken	newstoken
NEXO	Nexo	nexo
NGC	NAGA	naga
NIM	Nimiq	nimiq
NIO	Autonio	autonio
NIX	NIX	nix
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
NOBS	No BS Crypto	no-bs-crypto
NOKU	Noku	noku
NOR	Noir	noir
NOTE	DNotes	dnotes
NOX	Nitro	nitro
NPER	NPER	nper
NPW	New Power Coin	new-power-coin
NPX	NaPoleonX	napoleonx
NPXS	Pundi X	pundi-x
NPXSXEM	Pundi X NEM	pundi-x-nem
NRG	Energi	energi
NRO	Neuro	neuro
NRP	Neural Protocol	neural-protocol
NRVE	Narrative	narrative
NSD	Nasdacoin	nasdacoin
NSR	NuShares	nushares
NTK	Neurotoken	neurotoken
NTO	Fujinto	fujinto
NTRN	Neutron	neutron
NTWK	Network Token	network-token
NTY	Nexty	nexty
NUG	Nuggets	nuggets
NUKO	Nekonium	nekonium
NULS	Nuls	nuls
NUSD	nUSD	nusd
NVC	Novacoin	novacoin
NXC	Nexium	nexium
NXS	Nexus	nexus
NXT	Nxt	nxt
NYAN	Nyancoin	nyancoin
NYC	NewYorkCoin	newyorkcoin
NYEX	Nyerium	nyerium
OAX	OAX	oax
OBITS	OBITS	obits
OBT	Orbis Token	orbis-token
OBTC	Obitan Chain	obitan-chain
OBX	OBXcoin	obxcoin
OC	OceanChain	oceanchain
OCC	Octoin Coin	octoin-coin
OCL	Oceanlab	oceanlab
OCN	Odyssey	odyssey
OCT	OracleChain	oraclechain
ODE	ODEM	odem
ODN	Obsidian	obsidian
OF	OFCOIN	ofcoin
OK	OKCash	okcash
OLE	Olive	olive
OLMP	Olympic	olympic
OLT	OneLedger	oneledger
OMEN	OmenCoin	omencoin
OMG	OmiseGO	omisego
OMNI	Omni	omni
OMX	Shivom	shivom
ONE	Menlo One	menlo-one
ONG	SoMee.Social	ongsocial
ONGCOIN	ONG	ong
ONION	DeepOnion	deeponion
ONL	On.Live	on-live
ONT	Ontology	ontology
ONX	Onix	onix
OOT	Utrum	utrum
OPAL	Opal	opal
OPC	OP Coin	op-coin
OPCX	OPCoinX	opcoinx
OPEN	Open Platform	open-platform
OPT	Opus	opus
OPTI	OptiToken	optitoken
ORB	Orbitcoin	orbitcoin
ORE	Galactrum	galactrum
ORI	Origami	origami
ORME	Ormeus Coin	ormeus-coin
ORS	Origin Sport	origin-sport
ORSGROUP	ORS Group	ors-group
OSA	Optimal Shelf Availability Token	optimal-shelf-availability-token
OST	OST	ost
OTB	OTCBTC Token	otcbtc-token
OTN	Open Trading Network	open-trading-network
OUR	Ourcoin	ourcoin
OWN	OWNDATA	owndata
OXY	Oxycoin	oxycoin
PAI	PCHAIN	pchain
PAK	Pakcoin	pakcoin
PAL	Pal Network	pal-network
PARETO	Pareto Network	pareto-network
PARKGENE	Parkgene	parkgene
PARKINGO	ParkinGo	parkingo
PART	Particl	particl
PASC	Pascal Coin	pascal-coin
PASL	Pascal Lite	pascal-lite
PASS	Blockpass	blockpass
PAT	Patron	patron
PAWS	PAWS Fund	paws-fund
PAX	Paxos Standard Token	paxos-standard-token
PAXEX	PAXEX	paxex
PAY	TenX	tenx
PAYX	Paypex	paypex
PBL	Publica	publica
PBT	Primalbase Token	primalbase
PC	Promotion Coin	promotion-coin
PCH	POPCHAIN	popchain
PCL	Peculium	peculium
PCN	PeepCoin	peepcoin
PCO	Pecunio	pecunio
PCOIN	Pioneer Coin	pioneer-coin
PCS	Pabyosi Coin Special	pabyosi-coin-special
PDX	PayDay Coin	payday-coin
PEDI	Pedity	pedity
PENG	Penguin Coin	penguin-coin
PEPECASH	Pepe Cash	pepe-cash
PEX	PosEx	posex
PFR	Payfair	payfair
PGN	Pigeoncoin	pigeoncoin
PGT	Puregold Token	puregold-token
PHI	PHI Token	phi-token
PHO	Photon	photon
PHON	Phonecoin	phonecoin
PHR	Phore	phore
PHX	Red Pulse Phoenix	red-pulse
PIGGY	Piggycoin	piggycoin
PING	CryptoPing	cryptoping
PINK	PinkCoin	pinkcoin
PIPL	PiplCoin	piplcoin
PIRL	Pirl	pirl
PIVX	PIVX	pivx
PIX	Lampix	lampix
PIXIE	Pixie Coin	pixie-coin
PKB	ParkByte	parkbyte
PKC	PikcioChain	pikciochain
PKG	PKG Token	pkg-token
PKT	Playkey	playkey
PLACO	PlayerCoin	playercoin
PLAN	Plancoin	plancoin
PLAY	HEROcoin	herocoin
PLBT	Polybius	polybius
PLC	PLATINCOIN	platincoin
PLNC	PLNcoin	plncoin
PLR	Pillar	pillar
PLU	Pluton	pluton
PLURA	PluraCoin	pluracoin
PLUS1	PlusOneCoin	plusonecoin
PLX	PlexCoin	plexcoin
PLY	PlayCoin [ERC20]	playcoin-erc20
PLYQRC20	PlayCoin [QRC20]	playcoin
PMA	PumaPay	pumapay
PMNT	Paymon	paymon
PND	Pandacoin	pandacoin-pnd
PNDM	Pandemia	pandemia
PNK	Kleros	kleros
PNT	Penta	penta
PNX	Phantomx	phantomx
PNY	Peony	peony
POA	POA Network	poa-network
POE	Po.et	poet
POLCOIN	Polcoin	polcoin
POLIS	Polis	polis
POLL	ClearPoll	clearpoll
POLY	Polymath	polymath-network
PONZI	PonziCoin	ponzicoin
POP	PopularCoin	popularcoin
POS	PoSToken	postoken
POSS	Posscoin	posscoin
POST	PostCoin	postcoin
POSW	PoSW Coin	posw-coin
POT	PotCoin	potcoin
POWR	Power Ledger	power-ledger
PPC	Peercoin	peercoin
PPP	PayPie	paypie
PPT	Populous	populous
PPY	Peerplays	peerplays-ppy
PRC	PRCoin	prcoin
PRE	Presearch	presearch
PRES	President Trump	president-trump
PRG	Paragon	paragon
PRIV	PRiVCY	privcy
PRIX	Privatix	privatix
PRJ	Project Coin	project-coin
PRL	Oyster	oyster
PRO	Propy	propy
PROCHAIN	ProChain	prochain
PROCURRENCY	ProCurrency	procurrency
PROJPAI	Project Pai	project-pai
PROUD	PROUD Money	proud-money
PRS	PressOne	pressone
PRTX	Printex	printex
PSC	PrimeStone	primestone
PSM	PRASM	prasm
PST	Primas	primas
PTC	Pesetacoin	pesetacoin
PTN	PalletOne	palletone
PTOY	Patientory	patientory
PTS	PitisCoin	pitiscoin
PTT	Proton Token	proton-token
PURA	Pura	pura
PUREX	Pure	purex
PUT	PutinCoin	putincoin
PUTOKEN	Profile Utility Token	profile-utility-token
PWR	PWR Coin	powercoin
PXC	Phoenixcoin	phoenixcoin
PXI	Prime-XI	prime-xi
PYLNT	Pylon Network	pylon-network
PYN	PAYCENT	paycent
PYX	PyrexCoin	pyrexcoin
PZM	PRIZM	prizm
Q2C	QubitCoin	qubitcoin
QAC	Quasarcoin	quasarcoin
QASH	QASH	qash
QBC	Quebecoin	quebecoin
QBIC	Qbic	qbic
QBIT	Qubitica	qubitica
QBT	Qbao	qbao
QCH	QChi	qchi
QKC	QuarkChain	quarkchain
QLC	QLC Chain	qlink
QNO	QYNO	qyno
QNT	Quant	quant
QNTU	Quanta Utility Token	quanta-utility-token
QRK	Quark	quark
QRL	Quantum Resistant Ledger	quantum-resistant-ledger
QSP	Quantstamp	quantstamp
QTL	Quatloo	quatloo
QTUM	Qtum	qtum
QUAN	Quantis Network	quantis-network
QUBE	Qube	qube
QUN	QunQun	qunqun
QURO	Qurito	qurito
QVT	Qvolta	qvolta
QWARK	Qwark	qwark
R	Revain	revain
RADS	Radium	radium
RAGNA	Ragnarok	ragnarok
RAIN	Condensate	condensate
RATE	Ratecoin	ratecoin
RATING	DPRating	dprating
RBBT	RabbitCoin	rabbitcoin
RBIES	Rubies	rubies
RBLX	Rublix	rublix
RBMC	Rubex Money	rubex-money
RBT	Rimbit	rimbit
RBY	Rubycoin	rubycoin
RC	RussiaCoin	russiacoin
RCD	RECORD	record
RCN	Ripio Credit Network	ripio-credit-network
RCT	RealChain	realchain
RDC	Ordocoin	ordocoin
RDD	ReddCoin	reddcoin
RDN	Raiden Network Token	raiden-network-token
READ	Read	read
REAL	REAL	real
REBL	REBL	rebl
REC	Regalcoin	regalcoin
RED	RedCoin	redcoin
RED2	RED	red
REF	RefToken	reftoken
REM	Remme	remme
REN	Republic Protocol	republic-protocol
REP	Augur	augur
REPO	REPO	repo
REQ	Request Network	request-network
RET	RealTract	realtract
REX	imbrex	imbrex
RFR	Refereum	refereum
RGS	RusGas	rusgas
RHOC	RChain	rchain
RISE	Rise	rise
RIYA	Etheriya	etheriya
RKC	Rookiecoin	rookiecoin
RKT	Rock	rock
RLC	iExec RLC	rlc
RLT	RouletteToken	roulettetoken
RLX	Relex	relex
RMC	Russian Mining Coin	russian-mining-coin
RMESH	RightMesh	rightmesh
RMT	SureRemit	sureremit
RNS	Renos	renos
RNT	OneRoot Network	oneroot-network
RNTB	BitRent	bitrent
ROBET	RoBET	robet
ROCK	Rocketcoin	rocketcoin
ROCK2	ICE ROCK MINING	ice-rock-mining
ROX	Robotina	robotina
ROYALKC	Royal Kingdom Coin	royal-kingdom-coin
RPC	RonPaulCoin	ronpaulcoin
RPD	Rapids	rapids
RPI	RPICoin	rpicoin
RPL	Rocket Pool	rocket-pool
RPM	Repme	repme
RRC	RRCoin	rrcoin
RSTR	Ondori	ondori
RTB	AB-Chain RTB	ab-chain-rtb
RTE	Rate3	rate3
RTH	Rotharium	rotharium
RUFF	Ruff	ruff
RUNNERS	Runners	runners
RUP	Rupee	rupee
RUPX	Rupaya	rupaya
RVN	Ravencoin	ravencoin
RVR	RevolutionVR	revolutionvr
RVT	Rivetz	rivetz
RYO	Ryo Currency	ryo-currency
S	Sharpay	sharpay
SAC	Smart Application Chain	smart-application-chain
SAFEX	Safe Exchange Coin	safe-exchange-coin
SAGA	SagaCoin	sagacoin
SAKE	SAKECOIN	sakecoin
SAL	SalPay	salpay
SALT	SALT	salt
SAN	Santiment Network Token	santiment
SANDG	Save and Gain	save-and-gain
SBD	Steem Dollars	steem-dollars
SBTC	Super Bitcoin	super-bitcoin
SC	Siacoin	siacoin
SCC	SiaCashCoin	siacashcoin
SCL	Sociall	sociall
SCR	Scorum Coins	scorum-coins
SCRIV	SCRIV NETWORK	scriv-network
SCRL	SCRL	scroll
SCRT	SecretCoin	secretcoin
SCS	SpeedCash	speedcash
SCT	Soma	soma
SDA	Six Domain Chain	six-domain-chain
SDRN	Senderon	senderon
SDS	Alchemint Standards	alchemint-standards
SEAL	Seal Network	seal-network
SEELE	Seele	seele
SEER	SEER	seer
SEM	Semux	semux
SEN	Consensus	consensus
SENC	Sentinel Chain	sentinel-chain
SEND	Social Send	social-send
SENSE	Sense	sense
SENT	Sentinel	sentinel
SEQ	Sequence	sequence
SETH	Sether	sether
SEXC	ShareX	sharex
SGN	Signals Network	signals-network
SGP	SGPay	sgpay
SGR	Sugar Exchange	sugar-exchange
SHADE	SHADE Token	shade-token
SHARD	Shard	shard
SHB	SkyHub Coin	skyhub-coin
SHDW	Shadow Token	shadow-token
SHE	ShineChain	shinechain
SHIFT	Shift	shift
SHIP	ShipChain	shipchain
SHND	StrongHands	stronghands
SHOW	Show	show
SHP	Sharpe Platform Token	sharpe-platform-token
SHPING	SHPING	shping
SIB	SIBCoin	sibcoin
SIC	Swisscoin	swisscoin
SIG	Spectiv	signal-token
SIGMA	SIGMAcoin	sigmacoin
SIGT	Signatum	signatum
SIM	Simmitri	simmitri
SINS	SafeInsure	safeinsure
SIX	SIX	six
SJCX	Storjcoin X	storjcoin-x
SJW	SJWCoin	sjwcoin
SKB	Sakura Bloom	sakura-bloom
SKC	Skeincoin	skeincoin
SKIN	SkinCoin	skincoin
SKM	Skrumble Network	skrumble-network
SKR	Sakuracoin	sakuracoin
SKY	Skycoin	skycoin
SLR	SolarCoin	solarcoin
SLS	SaluS	salus
SLT	Smartlands	smartlands
SMART	SmartCash	smartcash
SMC	SmartCoin	smartcoin
SMLY	SmileyCoin	smileycoin
SMOKE	Smoke	smoke
SMQ	SIMDAQ	simdaq
SMS	Speed Mining Service	speed-mining-service
SMT	SmartMesh	smartmesh
SNC	SunContract	suncontract
SND	SnodeCoin	snodecoin
SNET	Snetwork	snetwork
SNGLS	SingularDTV	singulardtv
SNIP	SnipCoin	snipcoin
SNM	SONM	sonm
SNO	SaveNode	savenode
SNOV	Snovian.Space	snovio
SNR	SONDER	sonder
SNRG	Synergy	synergy
SNT	Status	status
SNTR	Silent Notary	silent-notary
SOAR	Soarcoin	soarcoin
SOC	All Sports	all-sports
SOCC	SocialCoin	socialcoin-socc
SOCLEND	Social Lending Token	social-lending-token
SOIL	SOILcoin	soilcoin
SOL	Sola Token	sola-token
SONG	SongCoin	songcoin
SONIQ	Soniq	soniq
SONO	SONO	altcommunity-coin
SOON	SoonCoin	sooncoin
SOP	SoPay	sopay
SOUL	Phantasma	phantasma
SPANK	SpankChain	spankchain
SPC	SpaceChain	spacechain
SPD	Stipend	stipend
SPF	SportyCo	sportyco
SPHR	Sphere	sphere
SPHTX	SophiaTX	sophiatx
SPINDLE	SPINDLE	spindle
SPK	Sparks	sparks
SPN	Sapien	sapien
SPND	Spendcoin	spendcoin
SPR	SpreadCoin	spreadcoin
SPRTS	Sprouts	sprouts
SPX	Sp8de	sp8de
SRC	SecureCoin	securecoin
SRCOIN	SRCOIN	srcoin
SRN	SIRIN LABS Token	sirin-labs-token
SS	Sharder	sharder
SSC	SelfSell	selfsell
SSP	Smartshare	smartshare
SSS	Sharechain	sharechain
STA	Starta	starta
STAC	StarterCoin	startercoin
STACS	STACS	stacs
STAK	STRAKS	straks
STAR	Starbase	starbase
START	Startcoin	startcoin
STC	StarChain	starchain
STEEM	Steem	steem
STEEP	SteepCoin	steepcoin
STEX	STEX	stex
STK	STK	stk
STN	Steneum Coin	steneum-coin
STOCKCHAIN	StockChain	stockchain
STORJ	Storj	storj
STORM	Storm	storm
STQ	Storiqa	storiqa
STR	Staker	staker
STRAT	Stratis	stratis
STU	bitJob	student-coin
STX	Stox	stox
SUB	Substratum	substratum
SUBX	Sub Invest	sub-invest
SUMO	Sumokoin	sumokoin
SUP	Superior Coin	superior-coin
SUPER	SuperCoin	supercoin
SUQA	SUQA	suqa
SUR	Suretly	suretly
SURE	SURETY	surety
SVD	savedroid	savedroid
SWFTC	SwftCoin	swftcoin
SWING	Swing	swing
SWM	Swarm	swarm-fund
SWT	Swarm City	swarm-city
SWTC	Jingtum Tech	jingtum-tech
SWTH	Switcheo	switcheo
SXDT	Spectre.ai Dividend Token	spectre-dividend
SXUT	Spectre.ai Utility	spectre-utility
SYNX	Syndicate	syndicate
SYS	Syscoin	syscoin
SZC	ShopZcoin	shopzcoin
TAAS	TaaS	taas
TAC	Traceability Chain	traceability-chain
TAG	TagCoin	tagcoin
TAJ	TajCoin	tajcoin
TALAO	Talao	talao
TALK	BTCtalkcoin	btctalkcoin
TAU	Lamden	lamden
TBX	Tokenbox	tokenbox
TCC	The ChampCoin	the-champcoin
TCH	Thore Cash	thore-cash
TCN	TCOIN	tcoin
TCT	TokenClub	tokenclub
TDC	Trendercoin	trendercoin
TDP	TrueDeck	truedeck
TDS	TokenDesk	tokendesk
TDX	Tidex Token	tidex-token
TEAM	TEAM (TokenStars)	tokenstars
TEK	TEKcoin	tekcoin
TEL	Telcoin	telcoin
TELL	Tellurion	tellurion
TELOS	Teloscoin	teloscoin
TEN	Tokenomy	tokenomy
TER	TerraNova	terranova
TERN	Ternio	ternio
TES	TeslaCoin	teslacoin
TESLA	TeslaCoilCoin	teslacoilcoin
TFD	TE-FOOD	te-food
TFL	TrueFlip	trueflip
TGAME	Truegame	tgame
TGT	Target Coin	target-coin
THC	HempCoin	hempcoin
THEMIS	Themis	themis
THETA	Theta Token	theta-token
THR	ThoreCoin	thorecoin
THRT	Thrive Token	thrive-token
TIC	Thingschain	thingschain
TIE	Ties.DB	tiesdb
TIG	Tigereum	tigereum
TIME	Chronobank	chronobank
TIPS	FedoraCoin	fedoracoin
TIT	Titcoin	titcoin
TITTIE	TittieCoin	tittiecoin
TIX	Blocktix	blocktix
TKA	Tokia	tokia
TKN	TokenCard	tokencard
TKR	CryptoInsight	trackr
TKS	Tokes	tokes
TKT	Twinkle	twinkle
TKY	THEKEY	thekey
TMC	Timicoin	timicoin
TMT	TRAXIA	traxia
TMTG	The Midas Touch Gold	the-midas-touch-gold
TNB	Time New Bank	time-new-bank
TNC	Trinity Network Credit	trinity-network-credit
TNS	Transcodium	transcodium
TNT	Tierion	tierion
TOA	ToaCoin	toacoin
TOK	Tokugawa	tokugawa
TOKC	TOKYO	tokyo
TOL	Tolar	tolar
TOLL	Bridge Protocol	bridge-protocol
TOMO	TomoChain	tomochain
TOPC	TopChain	topchain
TOS	ThingsOperatingSystem	thingsoperatingsystem
TOTO	Tourist Token	tourist-token
TPAY	TokenPay	tokenpay
TRAC	OriginTrail	origintrail
TRAID	Traid	traid
TRAK	TrakInvest	trakinvest
TRC	Terracoin	terracoin
TRCT	Tracto	tracto
TRDT	Trident Group	trident
TRF	Travelflex	travelflex
TRI	Triangles	triangles
TRIO	Tripio	tripio
TRK	Truckcoin	truckcoin
TROLL	Trollcoin	trollcoin
TRST	WeTrust	trust
TRTL	Turtlecoin	turtlecoin
TRTT	Trittium	trittium
TRUE	TrueChain	truechain
TRUMP	TrumpCoin	trumpcoin
TRX	TRON	tron
TRXC	TRONCLASSIC	tronclassic
TSC	Thunderstake	thunderstake
TSL	Energo	energo
TTC	TTC Protocol	ttc-protocol
TTT	TrustNote	trustnote
TTU	TaTaTu	tatatu
TTV	TV-TWO	tv-two
TUBE	BitTube	bit-tube
TUSD	TrueUSD	trueusd
TV	Ti-Value	ti-value
TWIST	TWIST	twist
TX	TransferCoin	transfercoin
TYPE	Typerium	typerium
TZC	TrezarCoin	trezarcoin
UBC	Ubcoin Market	ubcoin-market
UBEX	Ubex	ubex
UBQ	Ubiq	ubiq
UBT	Unibright	unibright
UBTC	United Bitcoin	united-bitcoin
UC	YouLive Coin	youlive-coin
UCASH	UNIVERSAL CASH	ucash
UCN	UChain	uchain
UCT	Ubique Chain Of Things	ubique-chain-of-things
UDOO	Howdoo	howdoo
UFO	Uniform Fiscal Object	uniform-fiscal-object
UFR	Upfiring	upfiring
UGC	ugChain	ugchain
UIP	UnlimitedIP	unlimitedip
UIS	Unitus	unitus
UKG	Unikoin Gold	unikoin-gold
UNI	Universe	universe
UNIFY	Unify	unify
UNIT	Universal Currency	universal-currency
UNO	Unobtanium	unobtanium
UNRC	UniversalRoyalCoin	universalroyalcoin
UP	UpToken	uptoken
UPP	Sentinel Protocol	sentinel-protocol
UQC	Uquid Coin	uquid-coin
URALS	UralsCoin	uralscoin
USC	Ultimate Secure Cash	ultimate-secure-cash
USDC	USD Coin	usd-coin
USDT	Tether	tether
USE	Usechain Token	usechain-token
USNBT	NuBits	nubits
UST	Ultra Salescloud	ultra-salescoud
UT	Ulord	ulord
UTC	UltraCoin	ultracoin
UTK	UTRUST	utrust
UTNP	Universa	universa
UTT	United Traders Token	uttoken
UUU	U Network	u-network
V	Version	version
VCT	ValueCyberToken	valuecybertoken
VDG	VeriDocGlobal	veridocglobal
VEC2	VectorAI	vector
VEE	BLOCKv	blockv
VERI	Veritaseum	veritaseum
VEST	VestChain	vestchain
VET	VeChain	vechain
VEX	Vexanium	vexanium
VIA	Viacoin	viacoin
VIB	Viberate	viberate
VIBE	VIBE	vibe
VIDZ	PureVidz	purevidz
VIEW	View	view
VIKKY	VikkyToken	vikkytoken
VIN	VINchain	vinchain
VIPS	Vipstar Coin	vipstar-coin
VIT	Vice Industry Token	vice-industry-token
VITAE	Vitae	vitae
VITE	VITE	vite
VITES	Vites	vites
VIU	Viuly	viuly
VIVID	Vivid Coin	vivid-coin
VIVO	VIVO	vivo
VLC	ValueChain	valuechain
VLD	Vetri	vetri
VLT	Veltor	veltor
VLU	Valuto	valuto
VME	VeriME	verime
VNX	VisionX	visionx
VOCO	Provoco Token	provoco-token
VOISE	Voise	voisecom
VOLT	Bitvolt	bitvolt
VOT	VoteCoin	votecoin
VPRC	VapersCoin	vaperscoin
VRC	VeriCoin	vericoin
VRM	VeriumReserve	veriumreserve
VRS	Veros	veros
VSC	vSportCoin	vsportcoin
VSL	vSlice	vslice
VSTR	Vestoria	vestoria
VSX	Vsync	vsync-vsx
VTA	Virtacoin	virtacoin
VTC	Vertcoin	vertcoin
VTHO	VeThor Token	vethor-token
VULC	VULCANO	vulcano
VZT	Vezt	vezt
W3C	W3Coin	w3coin
WA	WA Space	wa-space
WAB	WABnetwork	wabnetwork
WABI	WaBi	wabi
WAGE	Digiwage	digiwage
WAN	Wanchain	wanchain
WAND	WandX	wandx
WAVES	Waves	waves
WAX	WAX	wax
WAYKI	WaykiChain	waykichain
WBB	Wild Beast Block	wild-beast-block
WBL	WIZBL	wizbl
WC	WINCOIN	win-coin
WCT	Waves Community Token	waves-community-token
WDC	WorldCoin	worldcoin
WEB	Webcoin	webcoin
WEBCHAIN	Webchain	webchain
WELL	WELL	well
WET	WeShow Token	weshow-token
WETH	WETH	weth
WGO	WavesGo	wavesgo
WGR	Wagerr	wagerr
WHL	WhaleCoin	whalecoin
WIC	Wi Coin	wi-coin
WIKI	Wiki Token	wiki-token
WILD	Wild Crypto	wild-crypto
WIN	WinToken	wintoken
WINGS	Wings	wings
WINK	Wink	wink
WIRE	AirWire	airwire
WISH	MyWish	mywish
WIT	WITChain	witchain
WIX	Wixlar	wixlar
WIZ	CrowdWiz	crowdwiz
WOMEN	WomenCoin	women
WPR	WePower	wepower
WRC	Worldcore	worldcore
WSD	White Standard	white-standard
WSP	Wispr	wispr
WSX	WeAreSatoshi	wearesatoshi
WT	WeToken	wetoken
WTC	Waltonchain	waltonchain
WTL	Welltrado	welltrado
WTN	Waletoken	waletoken
WWB	Wowbit	wowbit
WXC	WXCOINS	wxcoins
WYS	wys Token	wys-token
X12	X12 Coin	x12-coin
X8X	X8X Token	x8x-token
XAP	Apollon	apollon
XAS	Asch	asch
XAUR	Xaurum	xaurum
XBC	Bitcoin Plus	bitcoin-plus
XBI	Bitcoin Incognito	bitcoin-incognito
XBL	Billionaire Token	billionaire-token
XBP	BlitzPredict	blitzpredict
XBTC21	Bitcoin 21	bitcoin-21
XBY	XTRABYTES	xtrabytes
XCASH	X-Cash	x-cash
XCD	CapdaxToken	capdaxtoken
XCEL	XcelToken	xceltoken
XCG	Xchange	xchange
XCLR	ClearCoin	clearcoin
XCN	Cryptonite	cryptonite
XCO	X-Coin	x-coin
XCP	Counterparty	counterparty
XCT	C-Bit	c-bit
XCXT	CoinonatX	coinonatx
XDCE	XinFin Network	xinfin-network
XDN	DigitalNote	digitalnote
XDNA	XDNA	xdna
XEL	XEL	xel
XEM	NEM	nem
XES	Proxeus	proxeus
XET	ETERNAL TOKEN	eternal-token
XG	GIGA	giga
XGOX	XGOX	xgox
XGS	GenesisX	genesisx
XHI	HiCoin	hicoin
XHV	Haven Protocol	haven-protocol
XID	Sphre AIR 	sphre-air
XIN	Infinity Economics	infinity-economics
XIND	INDINODE	indinode
XJO	Joulecoin	joulecoin
XLC	Leviar	leviar
XLM	Stellar	stellar
XLQ	ALQO	alqo
XLR	Solaris	solaris
XMC	Monero Classic	monero-classic
XMCC	Monoeci	monacocoin
XMCT	XMCT	xmct
XMG	Magi	magi
XMO	Monero Original	monero-original
XMR	Monero	monero
XMX	XMax	xmax
XMY	Myriad	myriad
XNK	Ink Protocol	ink-protocol
XNN	Xenon	xenon
XNV	Nerva	nerva
XOT	Internet of Things	internet-of-things
XOV	XOVBank	xovbank
XP	Experience Points	experience-points
XPA	XPA	xpa
XPAT	Bitnation	bitnation
XPD	PetroDollar	petrodollar
XPM	Primecoin	primecoin
XPTX	PlatinumBAR	platinumbar
XPX	ProximaX	proximax
XPY	PayCoin	paycoin2
XQN	Quotient	quotient
XRA	Xriba	xriba
XRE	RevolverCoin	revolvercoin
XRH	Rhenium	rhenium
XRL	Rialto	rialto
XRP	XRP	ripple
XRT	XRT Token	xrt-token
XSD	SounDAC	bitshares-music
XSG	SnowGem	snowgem
XSH	SHIELD	shield-xsh
XSN	Stakenet	stakenet
XSPEC	Spectrecoin	spectrecoin
XST	Stealth	stealth
XSTC	Safe Trade Coin	safe-trade-coin
XTL	Stellite	stellite
XTO	Tao	tao
XTRD	XTRD	xtrd
XTZ	Tezos	tezos
XUC	Exchange Union	exchange-union
XUN	UltraNote Coin	ultranote-coin
XVG	Verge	verge
XWC	WhiteCoin	whitecoin
XXX	AdultChain	adultchain
XYO	XYO Network	xyo-network
XZC	Zcoin	zcoin
YCC	Yuan Chain Coin	yuan-chain-coin
YEE	YEE	yee
YEED	YGGDRASH	yeed
YLC	YoloCash	yolocash
YOC	Yocoin	yocoin
YOU	YOU COIN	you-coin
YOYOW	YOYOW	yoyow
YTN	YENTEN	yenten
YUKI	YUKI	yuki
YUP	Crowdholding	crowdholding
ZAP	Zap	zap
ZB	ZB	zb
ZBA	Zoomba	zoomba
ZCL	ZClassic	zclassic
ZCN	0chain	0chain
ZCO	Zebi	zebi
ZCR	ZCore	zcore
ZEC	Zcash	zcash
ZEIT	Zeitcoin	zeitcoin
ZEL	ZelCash	zelcash
ZEN	Horizen	zencash
ZENGOLD	ZenGold	zengold
ZENI	Zennies	zennies
ZEPH	Zephyr	zephyr
ZER	Zero	zero
ZEST	ZEST	zest
ZET	Zetacoin	zetacoin
ZEUS	ZeusCrowdfunding	zeuscrowdfunding
ZIL	Zilliqa	zilliqa
ZINC	ZINC	zinc
ZIP	Zipper	zip
ZIPT	Zippie	zippie
ZLA	Zilla	zilla
ZMN	ZMINE	zmine
ZNT	Zenswap Network Token	zenswap-network-token
ZNY	Bitzeny	bitzeny
ZP	Zen Protocol	zen-protocol
ZPR	ZPER	zper
ZPT	Zeepin	zeepin
ZRC	ZrCoin	zrcoin
ZRX	0x	0x
ZSC	Zeusshield	zeusshield
ZT	ZTCoin	ztcoin
ZUR	Zurcoin	zurcoin
ZXC	0xcert	0xcert
ZYD	Zayedcoin	zayedcoin
ZZC	ZoZoCoin	zozocoin
