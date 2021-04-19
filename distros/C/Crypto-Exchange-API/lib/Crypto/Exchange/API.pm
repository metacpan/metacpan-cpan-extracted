package Crypto::Exchange::API;
$Crypto::Exchange::API::VERSION = '0.01';
=head1 NAME

Crypto::Exchange::API - API module for Crypto Exchanges

=head1 USAGE

Use this class as parent for the exchanges API.

It defines the key, secret which evey crypto exchnages are requried.

The base_currencies is for the exchanges is useful to help to separate the coin and the base token

ie. Binance

XRPUSDT

OR XRPGBP

In the sub class define all the base tokens e.g. ['USDT', 'GBP', etc...]

And you can use the below example method to separate them in request and response

 sub response_attr_pair {
    my ($self, $pair) = @_; 
    my $bases = $self->base_currencies;

    foreach my $base(keys %$bases) {
        if ($pair =~ m/^$base(.+)/ || $pair =~ m/(.+)$base$/) {
            return { base => $base, coin => $1 },
        }   
    }   

    die "Pair [$pair] couldnn't find base currency";
 }

=cut

use Moo;
use Crypto::API;

extends 'Crypto::API';

has key => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

has secret => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

has phrase => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

has base_currencies => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

## leave the builders to the sub class

no Moo;

1;
