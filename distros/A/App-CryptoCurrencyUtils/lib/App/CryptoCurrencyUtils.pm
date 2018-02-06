package App::CryptoCurrencyUtils;

our $DATE = '2018-02-05'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

our %arg_coin = (
    coin => {
        schema => 'cryptocurrency::symbol_or_name*',
        req => 1,
        pos => 0,
    },
);

our %arg_coins = (
    coins => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'coin',
        schema => ['array*', of=>'cryptocurrency::symbol_or_name*'],
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

our %arg_coins_opt = (
    coins => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'coin',
        schema => ['array*', of=>'cryptocurrency::symbol_or_name*'],
        pos => 0,
        greedy => 1,
    },
);

our %arg_exchange = (
    exchange => {
        schema => 'cryptoexchange::name*',
        req => 1,
        pos => 0,
    },
);

our %arg_exchanges = (
    exchanges => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'exchange',
        schema => ['array*', of=>'cryptoexchange::name*'],
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

our %arg_convert = (
    convert => {
        schema => ['str*', in=>["AUD", "BRL", "CAD", "CHF", "CLP", "CNY", "CZK", "DKK", "EUR", "GBP", "HKD", "HUF", "IDR", "ILS", "INR", "JPY", "KRW", "MXN", "MYR", "NOK", "NZD", "PHP", "PKR", "PLN", "RUB", "SEK", "SGD", "THB", "TRY", "TWD", "ZAR"]],
    },
);

sub _get_json {
    require HTTP::Tiny;
    require JSON::MaybeXS;

    my ($url) = @_;

    my $res = HTTP::Tiny->new->get($url);
    return [$res->{status}, $res->{reason}] unless $res->{success};

    my $data;
    eval { $data = JSON::MaybeXS::decode_json($res->{content}) };
    return [500, "Can't decode JSON: $@"] if $@;

    [$res->{status}, $res->{reason}, $data];
}

sub _get_json_cmc {
    my $url = shift;
    my $res = _get_json($url);

    {
        last unless $res->[0] == 200;
        if (ref($res) eq 'HASH' && $res->{error}) {
            $res = [500, "Got error response from CMC API: $res->{error}"];
            last;
        }
    }
    $res;
}

$SPEC{coin_cmc_summary} = {
    v => 1.1,
    summary => "Get coin's CMC (coinmarketcap.com) summary",
    description => <<'_',

Currently retrieves https://api.coinmarketcap.com/v1/ticker/<coin-id>/ and
return the data in a table.

If no coins are specified, will return global data.

_
    args => {
        %arg_coins_opt,
        %arg_convert,
    },
};
sub coin_cmc_summary {
    require CryptoCurrency::Catalog;

    my %args = @_;

    my $cat = CryptoCurrency::Catalog->new;

    unless ($args{coins} && @{ $args{coins} }) {
        return global_cmc_summary();
    }

    my @rows;
  CURRENCY:
    for my $cur0 (@{ $args{coins} }) {

        my $cur;
        {
            eval { $cur = $cat->by_symbol($cur0) };
            last if $cur;
            eval { $cur = $cat->by_name($cur0) };
            last if $cur;
            warn "No such cryptocurrency symbol/name '$cur0'";
            next CURRENCY;
        }

        my $res = _get_json_cmc(
            "https://api.coinmarketcap.com/v1/ticker/$cur->{safename}/".
                ($args{convert} ? "?convert=$args{convert}" : ""));
        unless ($res->[0] == 200) {
            log_error("Can't get API result for $cur->{name}: $res->[0] - $res->[1]");
            next CURRENCY;
        }
        delete $res->[2][0]{id};
        push @rows, $res->[2][0];
    }

    my $resmeta = {
        'table.field_orders' => [qw/symbol name rank/, qr/^price_/ => sub { $_[0] cmp $_[1] }],
    };

    [200, "OK", \@rows, $resmeta];
}

$SPEC{global_cmc_summary} = {
    v => 1.1,
    summary => "Get global CMC (coinmarketcap.com) summary",
    description => <<'_',

Currently retrieves https://api.coinmarketcap.com/v1/ticker/<coin-id>/ and

_
    args => {
        %arg_convert,
    },
};
sub global_cmc_summary {
    my %args = @_;

    my $res = _get_json_cmc(
        "https://api.coinmarketcap.com/v1/global/".
            ($args{convert} ? "?convert=$args{convert}" : ""));
    unless ($res->[0] == 200) {
        return [500, "Can't get API result: $res->[0] - $res->[1]"];
    }

    [200, "OK", $res->[2]];
}

$SPEC{open_coin_cmc} = {
    v => 1.1,
    summary => "Open coin's CMC (coinmarketcap.com) currency page in the browser",
    args => {
        %arg_coins,
    },
};
sub open_coin_cmc {
    require CryptoCurrency::Catalog;
    my %args = @_;

    my $cat = CryptoCurrency::Catalog->new;

  CURRENCY:
    for my $cur0 (@{ $args{coins} }) {

        my $cur;
        {
            eval { $cur = $cat->by_symbol($cur0) };
            last if $cur;
            eval { $cur = $cat->by_name($cur0) };
            last if $cur;
            warn "No such cryptocurrency symbol/name '$cur0'";
            next CURRENCY;
        }

        require Browser::Open;
        my $url = "https://coinmarketcap.com/currencies/$cur->{safename}/";
        my $err = Browser::Open::open_browser($url);
        return [500, "Can't open browser for '$url'"] if $err;
    }
    [200];
}

$SPEC{open_coin_mno} = {
    v => 1.1,
    summary => "Open coin's MNO (masternodes.online) currency page in the browser",
    description => <<'_',

Currently does not perform any translation between CMC -> MNO currency code if
there is a difference.

_
    args => {
        %arg_coins,
    },
};
sub open_coin_mno {
    require CryptoCurrency::Catalog;
    require URI::Escape;

    my %args = @_;

    my $cat = CryptoCurrency::Catalog->new;

  CURRENCY:
    for my $cur0 (@{ $args{coins} }) {

        my $cur;
        {
            eval { $cur = $cat->by_symbol($cur0) };
            last if $cur;
            eval { $cur = $cat->by_name($cur0) };
            last if $cur;
            warn "No such cryptocurrency symbol/name '$cur0'";
            next CURRENCY;
        }

        require Browser::Open;
        my $url = "https://masternodes.online/currencies/" .
            URI::Escape::uri_escape($cur->{symbol})."/";
        my $err = Browser::Open::open_browser($url);
        return [500, "Can't open browser for '$url'"] if $err;
    }
    [200];
}

$SPEC{open_exchange_cmc} = {
    v => 1.1,
    summary => "Open exchange's CMC (coinmarketcap.com) exchange page in the browser",
    args => {
        %arg_exchanges,
    },
};
sub open_exchange_cmc {
    require CryptoExchange::Catalog;
    my %args = @_;

    my $cat = CryptoExchange::Catalog->new;

  CURRENCY:
    for my $xchg0 (@{ $args{exchanges} }) {

        my $xchg;
        {
            eval { $xchg = $cat->by_name($xchg0) };
            last if $xchg;
            warn "No such cryptoexchange name '$xchg0'";
            next CURRENCY;
        }

        require Browser::Open;
        my $url = "https://coinmarketcap.com/exchanges/$xchg->{safename}/";
        my $err = Browser::Open::open_browser($url);
        return [500, "Can't open browser for '$url'"] if $err;
    }
    [200];
}

$SPEC{list_coins} = {
    v => 1.1,
    summary => "List cryptocurrency coins",
    description => <<'_',

This utility lists coins from <pm:CryptoCurrency::Catalog>, which in turn gets
its list from <https://coinmarketcap.com/>.

_
    args => {
    },
};
sub list_coins {
    require CryptoCurrency::Catalog;

    [200, "OK", [CryptoCurrency::Catalog->new->all_data]];
}


$SPEC{list_exchanges} = {
    v => 1.1,
    summary => "List cryptocurrency exchanges",
    description => <<'_',

This utility lists cryptocurrency exchanges from <pm:CryptoExchange::Catalog>,
which in turn gets its list from <https://coinmarketcap.com/>.

_
    args => {
    },
};
sub list_exchanges {
    require CryptoExchange::Catalog;

    [200, "OK", [CryptoExchange::Catalog->new->all_data]];
}

$SPEC{list_cmc_coins} = {
    v => 1.1,
    summary => "List of all coins listed on coinmarketcap.com (CMC) ".
        "along with their marketcaps, ranks, etc",
    description => <<'_',

This utility basically parses <https://coinmarketcap.com/all/views/all/> into
table data.

_
    args => {
    },
};
sub list_cmc_coins {
    require HTTP::Tiny;

    my $res = HTTP::Tiny->new->get("https://coinmarketcap.com/all/views/all/");
    return [$res->{status}, $res->{reason}] unless $res->{success};

    my @coins;

    # we capture the records first to speed up otherwise-glacial matching
    my @trs;
    while ($res->{content} =~ m!(<tr \s id="id-[\w-]+".+?</tr>)!gsx) {
        push @trs, $1;
    }
    #say "D:found ", scalar(@trs), " coins";

    my $i = 0;
    for my $tr (@trs) {
        $i++;
        $tr =~
            m!<tr \s id="id-(?<safename>[\w-]+)"[^>]*>.+?
              <td \s class="text-center">\s*(?<rank>\d+)\s*</td>.+?
              <td \s class="[^"]*?col-symbol">(?<symbol>[^<]+)<.+?
              <td \s class="[^"]*?market-cap[^"]*" \s data-usd="(?<mktcap_usd>[^"]+)" \s data-btc="(?<mktcap_btc>[^"]+)".+?
              <a \s href="[^"]+" \s class="price" \s data-usd="(?<price_usd>[^"]+)" \s data-btc="(?<price_btc>[^"]+)".+?
              \s data-supply="(?<supply>[^"]+)".+?
              <a \s href="[^"]+" \s class="volume" \s data-usd="(?<volume_usd>[^"]+)" \s data-btc="(?<volume_btc>[^"]+)".+?
             !sx
                 or die "Can't parse row #$i";
        push @coins, {%+};
    }

    my $resmeta = {
        'table.fields'       => [qw/rank safename symbol mktcap_usd mktcap_btc price_usd price_btc supply volume_usd volume_btc/],
        #'table.field_aligns' => [qw/left left     left   right      right     right     right     right  right      right/], # ugh, makes rendering so slow
    };
    [200, "OK", \@coins, $resmeta];
}

1;
# ABSTRACT: CLI utilities related to cryptocurrencies

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CryptoCurrencyUtils - CLI utilities related to cryptocurrencies

=head1 VERSION

This document describes version 0.010 of App::CryptoCurrencyUtils (from Perl distribution App-CryptoCurrencyUtils), released on 2018-02-05.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<coin-cmc-summary>

=item * L<global-cmc-summary>

=item * L<grep-coin>

=item * L<grep-exchange>

=item * L<list-cmc-coins>

=item * L<list-coins>

=item * L<list-exchanges>

=item * L<open-coin-cmc>

=item * L<open-coin-mno>

=item * L<open-exchange-cmc>

=back

=head1 FUNCTIONS


=head2 coin_cmc_summary

Usage:

 coin_cmc_summary(%args) -> [status, msg, result, meta]

Get coin's CMC (coinmarketcap.com) summary.

Currently retrieves https://api.coinmarketcap.com/v1/ticker/<coin-id>/ and
return the data in a table.

If no coins are specified, will return global data.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<coins> => I<array[cryptocurrency::symbol_or_name]>

=item * B<convert> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 global_cmc_summary

Usage:

 global_cmc_summary(%args) -> [status, msg, result, meta]

Get global CMC (coinmarketcap.com) summary.

Currently retrieves https://api.coinmarketcap.com/v1/ticker/<coin-id>/ and

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<convert> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_cmc_coins

Usage:

 list_cmc_coins() -> [status, msg, result, meta]

List of all coins listed on coinmarketcap.com (CMC) along with their marketcaps, ranks, etc.

This utility basically parses L<https://coinmarketcap.com/all/views/all/> into
table data.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_coins

Usage:

 list_coins() -> [status, msg, result, meta]

List cryptocurrency coins.

This utility lists coins from L<CryptoCurrency::Catalog>, which in turn gets
its list from L<https://coinmarketcap.com/>.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_exchanges

Usage:

 list_exchanges() -> [status, msg, result, meta]

List cryptocurrency exchanges.

This utility lists cryptocurrency exchanges from L<CryptoExchange::Catalog>,
which in turn gets its list from L<https://coinmarketcap.com/>.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 open_coin_cmc

Usage:

 open_coin_cmc(%args) -> [status, msg, result, meta]

Open coin's CMC (coinmarketcap.com) currency page in the browser.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<coins>* => I<array[cryptocurrency::symbol_or_name]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 open_coin_mno

Usage:

 open_coin_mno(%args) -> [status, msg, result, meta]

Open coin's MNO (masternodes.online) currency page in the browser.

Currently does not perform any translation between CMC -> MNO currency code if
there is a difference.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<coins>* => I<array[cryptocurrency::symbol_or_name]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 open_exchange_cmc

Usage:

 open_exchange_cmc(%args) -> [status, msg, result, meta]

Open exchange's CMC (coinmarketcap.com) exchange page in the browser.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exchanges>* => I<array[cryptoexchange::name]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CryptoCurrencyUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CryptoCurrencyUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CryptoCurrencyUtils>

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
