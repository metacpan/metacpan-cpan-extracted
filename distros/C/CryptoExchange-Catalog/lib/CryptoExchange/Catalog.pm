package CryptoExchange::Catalog;

our $DATE = '2018-01-09'; # DATE
our $VERSION = '20180109'; # VERSION

use 5.010001;
use strict;
use warnings;

my %by_name;
my %by_safename;
my @all_data;

sub new {
    my $class = shift;

    unless (keys %by_name) {
        while (defined(my $line = <DATA>)) {
            chomp $line;
            my @ff = split /\t/, $line;
            my ($name, $safename) = @ff;
            $by_name{$name}         = \@ff;
            $by_safename{$safename} = \@ff;
            push @all_data, \@ff;
        }
    }

    bless {}, $class;
}

sub by_name {
    my ($self, $name) = @_;
    die "Can't find cryptoexchange with name '$name'"
        unless $by_name{$name};
    return {
        name=>$name,
        safename=>$by_name{$name}[1],
    };
}

sub by_safename {
    my ($self, $safename) = @_;
    $safename = lc($safename);
    die "Can't find cryptoexchange with safename '$safename'"
        unless $by_safename{$safename};
    return {
        safename=>$safename,
        name=>$by_safename{$safename}[0],
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

sub all_data {
    my $self = shift;
    my @res;
    for (@all_data) {
        push @res, {name=>$_->[0], safename=>$_->[1]};
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

This document describes version 20180109 of CryptoExchange::Catalog (from Perl distribution CryptoExchange-Catalog), released on 2018-01-09.

=head1 SYNOPSIS

 use CryptoExchange::Catalog;

 my $cat = CryptoExchange::Catalog->new;

 my $record = $cat->by_name("BX Thailand");     # note: case-sensitive. => {name=>"BX Thailand", safename=>"bx-thailand"}
 my $record = $cat->by_safename("bx-thailand");
 my $record = $cat->by_slug("bx-thailand");     # alias for by_safename(), mixed case also works

 my @names = $cat->all_names(); # => ("Binance", "Bithumb", ...)

 my @data = $cat->all_data; # => ({name=>"Binance", safename=>"binance"}, {...}, ...)

=head1 DESCRIPTION

This class attempts to provide a list/catalog of cryptocurrency exchanges. The
main source for this catalog is the Cryptocurrency Market Capitalizations
website (L<https://coinmarketcap.com/>, or CMC for short).

=head1 METHODS

=head2 new

=head2 by_name

=head2 by_safename

=head2 by_slug

Alias for L</"by_safename">.

=head2 all_names

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
ACX	acx
AEX	aex
Abucoins	abucoins
AidosMarket	aidos-market
Allcoin	allcoin
Altcoin Trader	altcoin-trader
BCC Exchange	bcc-exchange
BCEX	bcex
BITHOLIC	bitholic
BL3P	bl3p
BTC Markets	btc-markets
BTC Trade UA	btc-trade-ua
BTC-Alpha	btc-alpha
BTCBOX	btcbox
BTCC	btcc
BTCTurk	btcturk
BX Thailand	bx-thailand
Bancor Network	bancor-network
Bibox	bibox
BigONE	bigone
Binance	binance
Bisq	bisq
Bit-Z	bit-z
Bit2C	bit2c
BitBay	bitbay
BitFlip	bitflip
BitGrail	bitgrail
BitKonan	bitkonan
BitMEX	bitmex
BitMarket	bitmarket
BitShares Asset Exchange	bitshares-asset-exchange
Bitbank	bitbank
Bitcoin Indonesia	bitcoin-indonesia
BitcoinToYou	bitcointoyou
BitcoinTrade	bitcointrade
Bitex.la	bitex-la
Bitfinex	bitfinex
Bithumb	bithumb
Bitlish	bitlish
Bitmaszyna	bitmaszyna
Bitonic	bitonic
Bits Blockchain	bits-blockchain
Bitsane	bitsane
Bitso	bitso
Bitstamp	bitstamp
Bitstamp (Ripple Gateway)	bitstamp-ripple-gateway
Bittrex	bittrex
Bittylicious	bittylicious
Bleutrade	bleutrade
Braziliex	braziliex
BtcTrade.im	btctrade-im
Burst Asset Exchange	burst-asset-exchange
C-CEX	c-cex
C2CX	c2cx
CEX.IO	cex-io
COSS	coss
ChaoEX	chaoex
CoinCorner	coincorner
CoinEgg	coinegg
CoinExchange	coinexchange
CoinFalcon	coinfalcon
CoinMate	coinmate
Coinbene	coinbene
Coinfloor	coinfloor
Coingi	coingi
Coinnest	coinnest
Coinone	coinone
Coinrail	coinrail
Coinrate	coinrate
Coinroom	coinroom
CoinsBank	coinsbank
CoinsMarkets	coinsmarkets
Coinsecure	coinsecure
Coinsquare	coinsquare
Coinut	coinut
CoolCoin	coolcoin
Counterparty DEX	counterparty-dex
CryptoBridge	cryptobridge
CryptoDerivatives	cryptoderivatives
CryptoMarket	cryptomarket
Cryptomate	cryptomate
Cryptopia	cryptopia
Cryptox	cryptox
DC-Ex	dc-ex
DSX	dsx
Dgtmarket	dgtmarket
ETHEXIndia	ethexindia
EXX	exx
EtherDelta	etherdelta
Ethfinex	ethfinex
ExcambrioRex	excambriorex
Exmo	exmo
Exrates	exrates
Fargobase	fargobase
Fisco	fisco
Foxbit	foxbit
FreiExchange	freiexchange
GDAX	gdax
GOPAX	gopax
Gate.io	gate-io
Gatecoin	gatecoin
Gatehub	gatehub
Gemini	gemini
GetBTC	getbtc
GuldenTrader	guldentrader
Heat Wallet	heat-wallet
HitBTC	hitbtc
Huobi	huobi
IDEX	idex
ISX	isx
Independent Reserve	independent-reserve
InfinityCoin Exchange	infinitycoin-exchange
Koineks	koineks
Koinex	koinex
Koinim	koinim
Korbit	korbit
Kraken	kraken
Kucoin	kucoin
Kuna	kuna
LEOxChange	leoxchange
LakeBTC	lakebtc
Lbank	lbank
Liqui	liqui
LiteBit.eu	litebit
Livecoin	livecoin
LocalTrade	localtrade
Luno	luno
Lykke Exchange	lykke-exchange
Mercado Bitcoin	mercado-bitcoin
Mercatox	mercatox
Mr. Exchange	mr-exchange
NIX-E	nix-e
Negocie Coins	negocie-coins
Nocks	nocks
Nxt Asset Exchange	nxt-asset-exchange
OEX	oex
OKCoin.cn	okcoin-cn
OKEx	okex
OasisDEX	oasisdex
OkCoin Intl.	okcoin-intl
Omni DEX	omni-dex
OpenLedger DEX	openledger
Paribu	paribu
Poloniex	poloniex
QBTC	qbtc
Qryptos	qryptos
QuadrigaCX	quadrigacx
Quoine	quoine
RightBTC	rightbtc
Rippex	rippex
Ripple China	ripple-china
RippleFox	ripplefox
SouthXchange	southxchange
Stellar Decentralized Exchange	stellar-decentralized-exchange
Stocks.Exchange	stocks-exchange
SurBTC	surbtc
TCC Exchange	tcc-exchange
TDAX	tdax
TOPBTC	topbtc
The Rock Trading	therocktrading
Tidebit	tidebit
Tidex	tidex
Token Store	token-store
Trade Satoshi	trade-satoshi
Tripe Dice Exchange	triple-dice-exchange
Tux Exchange	tux-exchange
VirtacoinWorld	virtacoinworld
WEX	wex
Waves Decentralized Exchange	waves-dex
YoBit	yobit
ZB.COM	zb-com
Zaif	zaif
alcurEX	alcurex
bitFlyer	bitflyer
ezBtc	ezbtc
itBit	itbit
xBTCe	xbtce
