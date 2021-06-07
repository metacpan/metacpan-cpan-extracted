package App::cryp::Role::Exchange;

our $DATE = '2021-05-26'; # DATE
our $VERSION = '0.012'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

requires qw(
               new

               cancel_order
               create_limit_order
               data_canonical_currencies
               data_native_pair_separator
               data_native_pair_is_uppercase
               get_order
               list_balances
               list_pairs
       );

sub data_reverse_canonical_currencies {
    my $self = shift;

    return $self->{_reverse_canonical_currencies}
        if $self->{_reverse_canonical_currencies};

    $self->{_reverse_canonical_currencies} = {
        reverse %{ $self->data_canonical_currencies }
    };
}

sub to_canonical_currency {
    my ($self, $cur) = @_;
    $cur = uc $cur;
    my $cur2 = $self->data_canonical_currencies->{$cur};
    $cur2 // $cur;
}

sub to_native_currency {
    my ($self, $cur) = @_;
    $cur = uc $cur;
    my $cur2 = $self->data_reverse_canonical_currencies->{$cur};
    $cur = $cur2 if defined $cur2;
    $self->data_native_pair_is_uppercase ? $cur : lc $cur;
}

sub to_canonical_pair {
    my ($self, $pair) = @_;

    my ($cur1, $cur2) = $pair =~ /([\w\$]+)[\W_]([\w\$]+)/
        or die "Invalid pair '$pair'";
    sprintf "%s/%s",
        $self->to_canonical_currency($cur1),
        $self->to_canonical_currency($cur2);
}

sub to_native_pair {
    my ($self, $pair) = @_;

    my ($cur1, $cur2) = $pair =~ /(\w+)[\W_](\w+)/
        or die "Invalid pair '$pair'";
    sprintf "%s%s%s",
        $self->to_native_currency($cur1),
        $self->data_native_pair_separator,
        $self->to_native_currency($cur2);
}

1;
# ABSTRACT: Role for interacting with an exchange

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Role::Exchange - Role for interacting with an exchange

=head1 VERSION

This document describes version 0.012 of App::cryp::Role::Exchange (from Perl distribution App-cryp-exchange), released on 2021-05-26.

=head1 DESCRIPTION

This role describes the common API for interacting with an exchange that all
C<App::cryp::Exchange::*> modules follow.

=head1 ENVELOPED RESULT

All methods, unless specified otherwise, must return enveloped result:

 [$status, $reason, $payload, \%extra]

This result is analogous to an HTTP response; in fact C<$status> mostly uses
HTTP response codes. C<$reason> is analogous to HTTP status message. C<$payload>
is the actual content (optional if C<$status> is error status). C<%extra> is
optional and analogous to HTTP response headers to specify flags or attributes
or other metadata.

Some examples of enveloped result:

 [200, "OK", ["BTC/USD", "ETH/BTC"]]
 [404, "Not found"]

For more details about enveloped result, see L<Rinci::function>.

=head1 PROVIDED METHODS

=head2 to_canonical_currency

Usage:

 $xchg->to_canonical_currency($cur) => str

Convert native currency code to canonical/standardized currency code. Canonical
codes are listed in L<CryptoCurrency::Catalog>.

=head2 to_native_currency

Usage:

 $xchg->to_native_currency($cur) => str

Convert canonical/standardized currency code to exchange-native currency code.
Canonical codes are listed in L<CryptoCurrency::Catalog>.

=head2 to_canonical_pair

Usage:

 $xchg->to_canonical_pair($pair) => str

=head2 to_native_pair

Usage:

 $xchg->to_native_pair($pair) => str

=head1 REQUIRED METHODS

=head2 cancel_order

Usage:

 $xchg->cancel_order(%args) => [$status, $reason, $payload, \%resmeta]

Cancel an open order.

Known arguments (C<*> marks required arguments):

=over

=item * type*

=item * pair*

=item * order_id*

=back

=head2 create_limit_order

Usage:

 $xchg->create_limit_order(%args) => [$status, $reason, $payload, \%resmeta]

Create a buy/sell order at a specified price.

B<Specifying size (amount)>. When creating a buy order, some exchanges require
specifying size (amount) in quote currency, e.g. in BTC/USD pair when buying USD
we specify how much in USD we want to buy bitcoin. Some other exchanges require
specifying size in base currency, i.e. how many bitcoins we want to buy.
Similarly, when creating a sell order, some exchanges require specifying base
currency while others want size in quote currency. B<For flexibility, this role
method requires drivers to accept either base_size or quote_size.>

B<Minimum_size>. Exchanges have a minimum order size (amount) either in the
quote currency or base currency or both. Check the C<min_base_size> and
C<min_quote_size> field returned by L</"list_pairs">. The API server typically
will reject order when size is less than the minimum.

B<Maximum precision>. Exchanges also have restriction on the maximum precision
of price (see the C<quote_increment> field returned by L</"list_pairs">. For
example, if C<quote_increment> for C<BTC/USD> pair is 0.01 then the price
7000.51 is okay but 7000.526 is too precise. Some exchanges will reject
overprecise price, but some exchanges will simply round the price to the nearest
precision (e.g. 7000.524 to 7000.52) and some exchanges might round up or down
or truncate etc. B<For more consistent behavior, this role method requires
drivers to round down the overprecise price to the nearest quote increment.>

Known arguments (C<*> marks required arguments):

=over

=item * pair*

String. Pair.

=item * type*

String. Either "buy" or "sell".

=item * price*

Number. Price in the quote currency. If price is too precise, will be rounded
down to the nearest precision (see method description above for details).

=item * base_size

Specify amount to buy/sell in base currency. For example, in BTC/USD pair, we
specify how many bitcoins to buy or sell.

You have to specify one of base_size or quote_size, but not both.

=item * quote_size

Specify amount to buy/sell in quote currency. For example, in BTC/USD pair, we
specify how many USD to buy or sell bitcoins.

You have to specify one of base_size or quote_size, but not both.

=back

Some specific exchanges might require more credentials or arguments (e.g.
C<api_passphrase> on Coinbase Pro); please check with the specific drivers.

When successful, payload in response must be a hashref which contains at least
these keys: C<type> ("buy" or "sell"), C<pair>, C<order_id> (str, usually a
number, can also be a UUID, etc), C<price> (number, actual price of the order),
C<base_size> (actual size of the order, specified in base currency),
C<quote_size> (actual size of the order, specified in quote currency), C<status>
(current status of the order).

=head2 get_ticker

Usage:

 $xchg->get_ticker(%args) => [$status, $reason, $payload, \%resmeta]

Get a pair's last 24h price and volume information.

Known arguments (C<*> marks required arguments):

=over

=item * pair*

=back

When successful, payload in response must be a hashref which contains at least
these keys: C<high> (last 24h highest price), C<low> (last 24h lowest price),
C<last> (last trade's price), C<volume> (last 24h volume, in base currency),
C<buy> (last buy price), C<sell> (last sell price). Optional keys: C<open> (last
24h opening/first price), , C<quote_volume> (last 24h volume in quote currency).
Hash may contain additional keys. All prices are in quote currency, all volumes
(except C>quote_volume>) are in base currency.

=head2 data_canonical_currencies

Should return a hashref, a mapping between exchange-native currency codes to
canonical/standardized currency codes. All codes must be in uppercase. Used to
convert native pair/currency to canonical or vice versa. See also:
L</"data_reverse_canonical_currencies">.

=head2 data_native_pair_is_uppercase

Should return an integer value, 1 if native pair is in uppercase, 0 if native
pair is in lowercase. Used to convert native pair/currency to canonical or vice
versa.

=head2 data_native_pair_separator

Should return a single-character string. Used to convert native pair/currency to
canonical or vice versa.

=head2 data_reverse_canonical_currencies

Returns hashref, a mapping of canonical/standardized currency codes to exchange
native codes. All codes must be in uppercase. Used to convert native
pair/currency to canonical or vice versa.

This role already provides an implementation, which calculates the hashref by
reversing the hash returned by C</"data_canonical_currencies"> and caching the
result in the instance's C<_reverse_canonical_currencies> key. Driver can
provide its own implementation.

See also: L</"data_canonical_currencies">.

=head2 get_order

Usage:

 $xchg->get_order(%args) => [$status, $reason, $payload, \%resmeta]

Get information about a specific order.

Note that some exchanges do not allow getting information on order that is
already cancelled or fulfilled.

B<Identifying order.> Some exchanges provide UUID to uniquely identify an order,
while some others provide a regular integer and you must also specify pair and
type to uniquely identify a particular order. For consistency, this rule method
requires driver to ask for all of C<type>, C<pair>, and C<order_id>.

Known arguments (C<*> marks required arguments):

=over

=item * type*

=item * pair*

=item * order_id*

=back

Payload must be a hashref with at least these keys:

=over

=item * type

=item * pair

=item * order_id

=item * create_time

Float. Unix epoch.

=item * status

Str. E.g.: C<open>, C<cancelled>, C<done>. TODO: standardize status across
exchanges.

=item * base_size

=item * quote_size

=item * filled_base_size

Number.

=item * filled_quote_size

Number.

=back

=head2 get_order_book

Usage:

 $xchg->get_order_book(%args) => [$status, $reason, $payload, \%resmeta]

Method should return this payload:

 {
     buy => [
         [100, 10 ] , # price, amount
         [ 99,  4.1], # price, amount
         ...
     ],
     sell => [
         [101  , 5.5], # price, amount
         [101.5, 3.1], # price, amount
         ...
     ],
 }

Buy (bid, purchase) records must be sorted from highest price to lowest price.
Sell (ask, offer) records must be sorted from lowest price to highest.

Known arguments (C<*> marks required arguments):

=over

=item * pair*

String. Pair.

=back

=head2 list_balances

Usage:

 $xchg->list_balances(%args) => [$status, $reason, $payload, \%resmeta]

List account balances.

Method must return enveloped result. Payload must be an array of hashrefs. Each
hashref must contain at least these keys:

=over

=item * currency

fiat_or_crpytocurrency.

=item * available

num, balance available for trading i.e. buying.

=item * hold

num, balance that is currently held so not available for trading, e.g. balance
currently tied on open buy orders.

=item * total

num, usually C<available> + C<hold> but can also be C<available> + C<hold> +
C<pending_withdraw>. Generally not very useful.

=back

Hashref may also contain these keys: C<pending_withdraw> (balance that is in the
process of withdrawn to another exchange, etc), C<unconfirmed> (balance that has
recently been deposited but unconfirmed e.g. has not reached the minimum number
of confirmations).

Hashref may contain additional keys.

=head2 list_open_orders

Usage:

 $xchg->list_open_orders(%args) => [$status, $reason, $payload, \%resmeta]

List all open orders.

Known arguments (C<*> marks required arguments):

=over

=item * pair

Only list orders for a specific pair. It's a good idea to include this argument
if you only need a specific pair's orders because in some exchanges you need a
separate API call for each pair.

=back

When successful, the payload in response is an array of orders. Each order
information is a hashref, with the following required keys (see L</"get_order">
for more details on each key):

=over

=item * type

=item * pair

=item * order_id

=item * price

=item * create_time

=item * status

=item * base_size

=item * filled_base_size

=item * filled_quote_size

=back

Note: the role does not require the orders to be returned in a specific sorting
order.

=head2 list_pairs

Usage:

 $xchg->list_pairs(%args) => [$status, $reason, $payload, \%resmeta]

List all pairs available for trading.

Method must return enveloped result. Payload must be an array containing pair
names (except when C<detail> argument is set to true, in which case method must
return array of records/hashrefs (see the C<detail> option for more details).

Pair names must be in the form of I<< <currency1>/<currency2> >> where
I<currency1> is the base currency and must be a cryptocurrency code while I<<
<currency2> >> is the quote currency and can be a fiat or cryptocurrency code.
Some example pair names: BTC/USD, ETH/BTC.

Known arguments (C<*> marks required arguments):

=over

=item * native

Boolean. Default 0. If set to 1, method must return pair codes and currency
codes in native exchange form instead of canonical/standardized form.

=item * detail

Boolean. Default 0. If set to 1, method must return array of records/hashrefs
instead of just array of strings (pair names).

Record must contain these keys:

=over

=item * name

str, pair name. Affected by the L</"native"> option.

=item * base_currency

str. Affected by the L</"native"> option.

=item * quote_currency

str. Affected by the L</"native"> option.

=item * min_base_size

Num, minimum order amount in the base currency.

=item * min_quote_size

Num, minimum order amount in the quote currency.

=item * quote_increment

Num, minimum increment in the quote currency.

=back

Record can contain additional keys.

=back

=head2 new

Usage:

 new(%args) => obj

Constructor. Known arguments (C<*> marks required arguments):

=over

=item * api_key

String. Required.

=item * api_secret

String. Required.

=back

Some specific exchanges might require more credentials or arguments (e.g.
C<api_passphrase> on GDAX); please check with the specific drivers.

Method must return object.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-exchange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-exchange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-cryp-exchange/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
