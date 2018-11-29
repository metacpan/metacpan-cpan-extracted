package CryptoExchange::Catalog;

our $DATE = '2018-11-29'; # DATE
our $VERSION = '20181129.0.0'; # VERSION

use 5.010001;
use strict;
use warnings;

my %by_name_lc;
my %by_safename;
my %by_code_lc;
my @all_data;

sub new {
    my $class = shift;

    unless (keys %by_name_lc) {
        while (defined(my $line = <DATA>)) {
            chomp $line;
            my @ff = split /\t/, $line;
            my ($name, $safename, $code) = @ff;
            $by_name_lc{lc $name}   = \@ff;
            $by_safename{$safename} = \@ff;
            $by_code_lc{lc $code} = \@ff if defined $code;
            push @all_data, \@ff;
        }
    }

    bless {}, $class;
}

sub by_name {
    my ($self, $name) = @_;
    die "Can't find cryptoexchange with name '$name'"
        unless my $rec = $by_name_lc{lc $name};
    return {
        name=>$rec->[0],
        safename=>$rec->[1],
        code=>$rec->[2],
    };
}

sub by_safename {
    my ($self, $safename) = @_;
    $safename = lc($safename);
    die "Can't find cryptoexchange with safename '$safename'"
        unless my $rec = $by_safename{$safename};
    return {
        name=>$rec->[0],
        safename=>$rec->[1],
        code=>$rec->[2],
    };
}

sub by_code {
    my ($self, $code) = @_;
    die "Can't find cryptoexchange with code '$code'"
        unless my $rec = $by_code_lc{lc $code};
    return {
        name=>$rec->[0],
        safename=>$rec->[1],
        code=>$rec->[2],
    };
}

sub by_slug { by_safename(@_) }

sub all_names {
    my $self = shift;
    my @res;
    for (@all_data) {
        push @res, $_->[0];
    }
    @res;
}

sub all_codes {
    my $self = shift;
    my @res;
    for (@all_data) {
        push @res, $_->[2] if defined $_->[2];
    }
    @res;
}

sub all_data {
    my $self = shift;
    my @res;
    for (@all_data) {
        push @res, {name=>$_->[0], safename=>$_->[1], code=>$_->[2]};
    }
    @res;
}

1;
# ABSTRACT: Catalog of cryptoexchanges

=pod

=encoding UTF-8

=head1 NAME

CryptoExchange::Catalog - Catalog of cryptoexchanges

=head1 VERSION

This document describes version 20181129.0.0 of CryptoExchange::Catalog (from Perl distribution CryptoExchange-Catalog), released on 2018-11-29.

=head1 SYNOPSIS

 use CryptoExchange::Catalog;

 my $cat = CryptoExchange::Catalog->new;

 my $record;
 $record = $cat->by_name("BX Thailand");     # note: case-insensitive. => {name=>"BX Thailand", safename=>"bx-thailand", code=>"BX"}
 $record = $cat->by_safename("bx-thailand");
 $record = $cat->by_slug("bx-thailand");     # alias for by_safename(), mixed case also works
 $record = $cat->by_code("BX");              # note: currently not all exchanges are assign (short) code

 my @names = $cat->all_names(); # => ("BX Thailand", "Binance", ...)

 my @codes = $cat->all_codes(); # => ("BX", "BINANCE", ...)

 my @data = $cat->all_data; # => ({name=>"BX Thailand", safename=>"bx-thailand", code=>"BX"}, {name=>"Binance", safename=>"binance", code=>"BINANCE"}, {...}, ...)

=head1 DESCRIPTION

This class attempts to provide a list/catalog of cryptocurrency exchanges. The
main source for this catalog is the Cryptocurrency Market Capitalizations
website (L<https://coinmarketcap.com/>, or CMC for short).

=head1 METHODS

=head2 new

=head2 by_name

=head2 by_safename

=head2 by_code

=head2 by_slug

Alias for L</"by_safename">.

=head2 all_names

=head2 all_codes

=head2 all_data

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CryptoExchange-Catalog>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CryptoExchange-Catalog>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CryptoExchange-Catalog>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CryptoCurrency::Catalog>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
ABCC	abcc	ABCC
ACX	acx	ACX
AidosMarket	aidos-market
AirSwap	airswap	AIRSWAP
Allbit	allbit	ALLBIT
Allcoin	allcoin	ALLCOIN
Altcoin Trader	altcoin-trader
B2BX	b2bx	B2BX
BCEX	bcex	BCEX
BCoin.sg	bcoin-sg	BCOINSG
BITBOX	bitbox	BITBOX
BTC Markets	btc-markets	BTCMARKETS
BTC Trade UA	btc-trade-ua	BTCTRADEUA
BTC-Alpha	btc-alpha	BTCALPHA
BTCBOX	btcbox	BTCBOX
BTCC	btcc	BTCC
BX Thailand	bx-thailand	BX
Bancor Network	bancor-network
Bgogo	bgogo	BGOGO
Bibox	bibox	BIBOX
BigONE	bigone	BIGONE
Bilaxy	bilaxy	BILAXY
Binance	binance	BINANCE
Bisq	bisq	BISQ
Bit-Z	bit-z	BITZ
Bit2C	bit2c	BIT2C
BitBay	bitbay	BITBAY
BitForex	bitforex	BITFOREX
BitMEX	bitmex	BITMEX
BitMarket	bitmarket	BITMARKET
BitMart	bitmart	BITMART
BitShares Asset Exchange	bitshares-asset-exchange
Bitbank	bitbank	BITBANK
Bitbns	bitbns	BITBNS
BitcoinToYou	bitcointoyou
BitcoinTrade	bitcointrade
BiteBTC	bitebtc	BITEBTC
Bitex.la	bitex-la	BITEXLA
Bitfinex	bitfinex	BITFINEX
Bithesap	bithesap	BITHESAP
Bithumb	bithumb	BITHUMB
Bitibu	bitibu	BITIBU
Bitinka	bitinka	BITINKA
Bitkub	bitkub	BITKUB
Bitlish	bitlish	BITLISH
Bitonic	bitonic	BITONIC
Bitrue	bitrue	BITRUE
Bits Blockchain	bits-blockchain
Bitsane	bitsane	BITSANE
Bitso	bitso	BITSO
Bitstamp	bitstamp	BITSTAMP
Bitstamp (Ripple Gateway)	bitstamp-ripple-gateway
Bittrex	bittrex	BITTREX
Bittylicious	bittylicious
Bleutrade	bleutrade	BLEUTRADE
Braziliex	braziliex	BRAZILIEX
BtcTrade.im	btctrade-im	BTCTRADEIM
BtcTurk	btcturk	BTCTURK
Buda	buda	BUDA
Bytex	bytex	BYTEX
C-CEX	c-cex	CCEX
C-Patex	c-patex	CPATEX
C2CX	c2cx	C2CX
CEX.IO	cex-io	CEXIO
CHAOEX	chaoex	CHAOEX
COSS	coss	COSS
CPDAX	cpdax	CPDAX
CRXzone	crxzone	CRXZONE
Cashierest	cashierest	CASHIEREST
Cobinhood	cobinhood	COBINHOOD
CoinBene	coinbene	COINBENE
CoinCorner	coincorner	COINCORNER
CoinEgg	coinegg	COINEGG
CoinEx	coinex	COINEX
CoinExchange	coinexchange
CoinFalcon	coinfalcon	COINFALCON
CoinMate	coinmate	COINMATE
CoinTiger	cointiger	COINTIGER
CoinZest	coinzest	COINZEST
Coinall	coinall	COINALL
Coinbase Pro	coinbase-pro
Coinbe	coinbe	COINBE
Coinbit	coinbit	COINBIT
Coincheck	coincheck	COINCHECK
Coindeal	coindeal	COINDEAL
Coinfloor	coinfloor	COINFLOOR
Coingi	coingi	COINGI
Coinhub	coinhub	COINHUB
Coinnest	coinnest	COINNEST
Coinone	coinone	COINONE
Coinrail	coinrail	COINRAIL
Coinrate	coinrate	COINRATE
Coinroom	coinroom	COINROOM
CoinsBank	coinsbank	COINSBANK
Coinsquare	coinsquare	COINSQUARE
Coinsuper	coinsuper	COINSUPER
Coinut	coinut	COINUT
Crex24	crex24	CREX24
CryptalDash	cryptaldash
CryptoBridge	cryptobridge
CryptoMarket	cryptomarket
Cryptology	cryptology	CRYPTOLOGY
Cryptomate	cryptomate	CRYPTOMATE
Cryptonex	cryptonex	CRYPTONEX
Cryptopia	cryptopia	CRYPTOPIA
DDEX	ddex	DDEX
DEx.top	dextop	DEXTOP
DOBI trade	dobitrade	DOBITRADE
DSX	dsx	DSX
DigiFinex	digifinex	DIGIFINEX
DragonEX	dragonex	DRAGONEX
EXX	exx	EXX
Escodex	escodex	ESCODEX
EtherDelta (ForkDelta)	forkdelta	FORKDELTA
Ethfinex	ethfinex	ETHFINEX
Exmo	exmo	EXMO
Exrates	exrates	EXRATES
FCoin	fcoin	FCOIN
Fatbtc	fatbtc	FATBTC
Fisco	fisco	FISCO
FreiExchange	freiexchange
GBX Digital Asset Exchange	gbx-digital-asset-exchange
GDAC	gdac	GDAC
GOPAX	gopax	GOPAX
Gate.io	gate-io	GATEIO
Gatecoin	gatecoin	GATECOIN
Gatehub	gatehub	GATEHUB
Gemini	gemini	GEMINI
Graviex	graviex	GRAVIEX
GuldenTrader	guldentrader
HADAX	hadax	HADAX
HBUS	hbus	HBUS
Heat Wallet	heat-wallet	HEATWALLET
HitBTC	hitbtc	HITBTC
Hotbit	hotbit	HOTBIT
Huobi	huobi	HUOBI
IDAX	idax	IDAX
IDCM	idcm	IDCM
IDEX	idex	IDEX
ISX	isx	ISX
Independent Reserve	independent-reserve
Indodax	indodax	INDODAX
InfinityCoin Exchange	infinitycoin-exchange
Instant Bitex	instant-bitex
Iquant	iquant	IQUANT
Koineks	koineks	KOINEKS
Koinex	koinex	KOINEX
Koinim	koinim	KOINIM
Korbit	korbit	KORBIT
Kraken	kraken	KRAKEN
Kryptono	kryptono	KRYPTONO
Kucoin	kucoin	KUCOIN
Kuna	kuna	KUNA
Kyber Network	kyber-network
LATOKEN	latoken	LATOKEN
LBank	lbank	LBANK
LakeBTC	lakebtc	LAKEBTC
Liqui	liqui	LIQUI
Liquid	liquid	LIQUID
LiteBit.eu	litebit	LITEBIT
Livecoin	livecoin	LIVECOIN
LocalTrade	localtrade	LOCALTRADE
Luno	luno	LUNO
Lykke Exchange	lykke-exchange
MBAex	mbaex	MBAEX
Mercado Bitcoin	mercado-bitcoin
Mercatox	mercatox	MERCATOX
Nanex	nanex	NANEX
Negocie Coins	negocie-coins
Neraex	neraexpro	NERAEX
Nocks	nocks	NOCKS
Novaexchange	novaexchange
OEX	oex	OEX
OKCoin International	okcoin-intl	OKCOININTL
OKEx	okex	OKEX
OOOBTC	ooobtc	OOOBTC
OTCBTC	otcbtc	OTCBTC
OasisDEX	oasisdex	OASISDEX
OpenLedger DEX	openledger	OPENLEDGER
Ovis	ovis	OVIS
P2PB2B	p2pb2b	P2PB2B
Paribu	paribu	PARIBU
Paymium	paymium	PAYMIUM
Poloniex	poloniex	POLONIEX
QuadrigaCX	quadrigacx	QUADRIGACX
Radar Relay	radar-relay	RADARRELAY
Rfinex	rfinex	RFINEX
RightBTC	rightbtc	RIGHTBTC
Ripple China	ripple-china
RippleFox	ripplefox	RIPPLEFOX
RuDEX	rudex	RUDEX
STEX	stex	STEX
Simex	simex	SIMEX
Sistemkoin	sistemkoin	SISTEMKOIN
SouthXchange	southxchange
Stellar Decentralized Exchange	stellar-decentralized-exchange
Stellarport	stellarport
Stronghold	stronghold	STRONGHOLD
Switcheo Network	switcheo	SWITCHEO
TDAX	tdax	TDAX
TOPBTC	topbtc	TOPBTC
The Rock Trading	therocktrading
Tidebit	tidebit	TIDEBIT
Tidex	tidex	TIDEX
Token Store	token-store	TOKENSTORE
Tokenomy	tokenomy	TOKENOMY
Trade By Trade	trade-by-trade
Trade Satoshi	trade-satoshi
TradeOgre	tradeogre	TRADEOGRE
Tripe Dice Exchange	triple-dice-exchange
Tux Exchange	tux-exchange
UEX	uex	UEX
Upbit	upbit	UPBIT
Vebitcoin	vebitcoin	VEBITCOIN
Waves Decentralized Exchange	waves-dex	WAVESDEX
WazirX	wazirx	WAZIRX
YoBit	yobit	YOBIT
YunEx	yunex	YUNEX
ZB.COM	zb-com	ZBCOM
ZBG	zbg	ZBG
Zaif	zaif	ZAIF
Zebpay	zebpay	ZEBPAY
bitFlyer	bitflyer	BITFLYER
ezBtc	ezbtc	EZBTC
itBit	itbit	ITBIT
