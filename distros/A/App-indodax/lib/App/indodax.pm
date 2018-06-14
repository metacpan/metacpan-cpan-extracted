package App::indodax;

our $DATE = '2018-06-12'; # DATE
our $VERSION = '0.024'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

use App::cryp::Exchange::indodax;

our %Canonical_Currencies = (map {lc} %{ App::cryp::Exchange::indodax->data_canonical_currencies });
our %Rev_Canonical_Currencies = (map {lc} %{ App::cryp::Exchange::indodax->data_reverse_canonical_currencies });

our @Markets = qw(idr btc);

our @Market_Pairs = (map {
    my $canon = $_->{name};
    my ($basecur, $quotecur) = split m!/!, $canon;
    lc($basecur) . '_' . lc($quotecur);
} @{ App::cryp::Exchange::indodax->data_pairs });

our @Currencies = do {
    my %res;
    for (@Market_Pairs) { /\A(\w+)_(\w+)\z/ or die; $res{$1}++; $res{$2}++ }
    sort keys %res;
};
our @Idr_Market_Currencies = do {
    my %res;
    for (@Market_Pairs) { /\A(\w+)_idr\z/ and $res{$1}++ }
    sort keys %res;
};
our @Btc_Market_Currencies = do {
    my %res;
    for (@Market_Pairs) { /\A(\w+)_btc\z/ and $res{$1}++ }
    sort keys %res;
};

my $sch_type = ['str*', in=>['buy','sell']];
my $sch_txtype = ['str*', in=>['deposit','withdraw']];
my $sch_currency = ['str*', in=>\@Currencies];
my $sch_pair = ['str*', {
    match=>qr/\A\w{3,4}_\w{3,4}\z/,
    in=>\@Market_Pairs,
}];
my $sch_market = ['str*', {
    in=>\@Markets,
}];

my %args_tapi = (
    key => {
        schema => ['str*', match=>qr/\A\w{8}-\w{8}-\w{8}-\w{8}-\w{8}\z/],
        req => 1,
    },
    secret => {
        schema => ['str*', match=>qr/\A[0-9a-z]{80}\z/],
        req => 1,
    },
);

my %arg_filter_type = (
    type => {
        summary => 'Filter by type (buy/sell)',
        schema => $sch_type,
        tags => ['category:filtering'],
    },
);

my %arg_filter_txtype = (
    txtype => {
        summary => 'Filter by transaction type (deposit/withdraw)',
        schema => $sch_txtype,
        tags => ['category:filtering'],
    },
);

my %arg_filter_pair = (
    pair => {
        summary => 'Filter by pair',
        schema => $sch_pair,
        tags => ['category:filtering'],
    },
);

my %arg_filter_currency = (
    currency => {
        summary => 'Filter by currency',
        schema => $sch_currency,
        tags => ['category:filtering'],
    },
);

my %args_filter_time = (
    time_from => {
        summary => 'Filter by beginning time',
        schema => 'date*',
        tags => ['category:filtering'],
    },
    time_to => {
        summary => 'Filter by ending time',
        schema => 'date*',
        tags => ['category:filtering'],
    },
);

my %args_filter_trade_id = (
    trade_id_from => {
        summary => 'Filter by beginning trade ID',
        schema => 'int*',
        tags => ['category:filtering'],
    },
    trade_id_to => {
        summary => 'Filter by ending trade ID',
        schema => 'int*',
        tags => ['category:filtering'],
    },
);

my %arg_pair = (
    pair => {
        summary => 'Pair',
        schema => $sch_pair,
        default => 'btc_idr',
    },
);

my %arg_0_pair = (
    pair => {
        summary => 'Pair',
        schema => $sch_pair,
        default => 'btc_idr',
        pos => 0,
    },
);

my %arg_market = (
    market => {
        summary => 'Market',
        schema => $sch_market,
        default => 'idr',
    },
);

my %arg_0_market = (
    market => {
        summary => 'Market',
        schema => $sch_market,
        default => 'idr',
        pos => 0,
    },
);

my %arg_0_type = (
    type => {
        schema => $sch_type,
        req => 1,
        pos => 0,
        cmdline_aliases => {
            buy  => {is_flag=>1, summary => 'Alias for --type buy' , code => sub { $_[0]{type} = 'buy'  }},
            sell => {is_flag=>1, summary => 'Alias for --type sell', code => sub { $_[0]{type} = 'sell' }},
        },
    },
);

my %arg_0_currency = (
    currency => {
        summary => 'Currency name',
        schema => $sch_currency,
        default => 'idr',
        pos => 0,
    },
);

my %args_public_api = (
    method => {
        schema => ['str*'],
        default => 'GET',
    },
    uri => {
        schema => ['str*', match => qr!\A/!],
        pos => 0,
        req => 1,
    },
    args => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'arg',
        schema => ['hash*', of=>'str'],
        pos => 1,
        greedy => 1,
    },
);

my %args_private_api = (
    args => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'arg',
        schema => ['hash*', of=>'str'],
        pos => 1,
        greedy => 1,
    },
);

my $indodax;

sub _init {
    require Finance::Indodax;
    my ($args) = @_;
    $indodax //= Finance::Indodax->new(
        (key    => $args->{key}   ) x !!(defined $args->{key}),
        (secret => $args->{secret}) x !!(defined $args->{secret}),
    );
}

# convert CLI-level pair to API-level
sub _convert_pair {
    my $pair = shift;
    my ($cur1, $cur2) = $pair =~ /\A(\w{3,5})_(\w{3,5})\z/
        or return $pair;
    for ($cur1, $cur2) {
        $_ = $Rev_Canonical_Currencies{$_} // $_;
    }
    "${cur1}_$cur2";
}

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI for Indodax.com',
};

$SPEC{pairs} = {
    v => 1.1,
    summary => 'List available pairs',
    args => {
    },
};
sub pairs {
    my %args = @_;
    _init(\%args);
    [200, "OK", \@Market_Pairs];
}

$SPEC{public} = {
    v => 1.1,
    summary => 'Perform public API request',
    args => {
        %args_public_api,
    },
};
sub public {
    my %args = @_;

    _init(\%args);
    my $uri = $args{uri}; $uri = "/api$uri" unless $uri =~ m!\A/api/!; # XXX args
    my $url = "https://indodax.com$uri";
    [200, "OK", $indodax->_get_json($url)];
}

$SPEC{private} = {
    v => 1.1,
    summary => 'Perform private API (TAPI) request',
    args => {
        %args_private_api,
    },
};
sub private {
    my %args = @_;

    _init(\%args);

    my $args = $args{args};
    my $method = delete $args->{method}
        or return [400, "Please supply 'method' argument"];

    [200, "OK", $indodax->tapi($method, $method, $args)];
}

$SPEC{ticker} = {
    v => 1.1,
    summary => 'Show ticker',
    args => {
        %arg_0_pair,
    },
};
sub ticker {
    my %args = @_;
    _init(\%args);
    [200, "OK", $indodax->get_ticker(pair => $args{pair})->{ticker}];
}

$SPEC{trades} = {
    v => 1.1,
    summary => 'Show latest trades',
    args => {
        %arg_0_pair,
        %arg_filter_type,
    },
};
sub trades {
    my %args = @_;
    _init(\%args);

    my $res = $indodax->get_trades(
        pair => $args{pair},
    );

    my @rows;
    for my $row (@$res) {
        if ($args{type}) {
            next unless $row->{type} eq $args{type};
        }
        $row->{idr} = int($row->{amount} * $row->{price});
        push @rows, $row;
    }

    my $fnum0 = [number => {precision=>0}];
    my $fnum8 = [number => {precision=>8}];

    my $resmeta = {};
    $resmeta->{'table.fields'}        = [qw/date tid    type price  amount idr/];
    $resmeta->{'table.field_aligns'}  = [qw/left number left right  right  right/];
    $resmeta->{'table.field_formats'} = ['iso8601_datetime', undef, undef, $fnum0, $fnum8, $fnum0];

    [200, "OK", \@rows, $resmeta];
}

$SPEC{depth} = {
    v => 1.1,
    summary => 'Show depth',
    args => {
        %arg_0_pair,
        %arg_filter_type,
    },
};
sub depth {
    my %args = @_;
    _init(\%args);

    my $res = $indodax->get_depth(
        pair => $args{pair},
    );
    my @rows;
    for my $type (keys %$res) {
        next if $args{type} && $type ne $args{type};
        my $v1 = $res->{$type};
        for my $row0 (@$v1) {
            my $row = {
                type => $type,
                idr  => $row0->[0],
                btc  => $row0->[1],
            };
            push @rows, $row;
        }
    }

    my $fnum0 = [number => {precision=>0}];
    my $fnum8 = [number => {precision=>8}];

    my $resmeta = {};
    $resmeta->{'table.fields'}        = [qw/type idr btc/];
    $resmeta->{'table.field_aligns'}  = [qw/left right right/];
    $resmeta->{'table.field_formats'} = [undef, $fnum0, $fnum8];

    [200, "OK", \@rows, $resmeta];
}

$SPEC{price_history} = {
    v => 1.1,
    summary => 'Show price history, which can be used to draw candlestick chart',
    description => <<'_',

The function will return an array of records. Each record is an array with the
following data:

    [timestamp-in-unix-epoch, open, high, low, close]

_
    args => {
        period => {
            schema => ['str*', in=>[qw/day all/]],
            default => 'day',
        },
        # XXX pair (API chartdata only available for btc_idr at the moment)
        # %arg_0_pair,
    },
};
sub price_history {
    my %args = @_;
    _init(\%args);

    my $res = $indodax->get_price_history(
        period => $args{period},
        # pair => $args{pair},
    )->{chart};

    my @rows;
    for my $row (@$res) {
        $row->[0] /= 1000;
        push @rows, $row;
    }

    my $fnum0 = [number => {precision=>0}];

    my $resmeta = {};
    $resmeta->{'table.fields'}        = [qw/time open high low close vol_btc/];
    $resmeta->{'table.field_aligns'}  = [qw/left right right right right number/];
    $resmeta->{'table.field_formats'} = ['iso8601_datetime', $fnum0, $fnum0, $fnum0, $fnum0, undef];

    [200, "OK", \@rows, $resmeta];
}

$SPEC{info} = {
    v => 1.1,
    summary => 'Show balance, server timestamp, and some other information',
    args => {
        %args_tapi,
    },
};
sub info {
    my %args = @_;
    _init(\%args);

    my $res = $indodax->get_info;
    [200, "OK", $res];
}

$SPEC{balance} = {
    v => 1.1,
    summary => 'Show current balances',
    args => {
        %args_tapi,
        with_idr_estimates => {
            summary => 'Also show the value of all assets in IDR, using current prices information',
            schema => 'bool*',
            cmdline_aliases => {e=>{}},
        },
    },
};
sub balance {
    my %args = @_;
    _init(\%args);

    my $res = $indodax->get_info;
    my @recs;
    my @idr_markets;
    my @btc_markets;
    for my $currency0 (sort keys %{$res->{return}{balance}}) {
        my $currency = $Canonical_Currencies{$currency0} // $currency0;
        my $rec = {};
        $rec->{currency} = $currency;
        $rec->{bal_avail} = $res->{return}{balance}{$currency0} // 0;
        $rec->{bal_held}  = $res->{return}{balance_hold}{$currency0} // 0;
        $rec->{bal_total} = ($res->{return}{balance}{$currency0} // 0) + ($res->{return}{balance_hold}{$currency0} // 0);
        if ($currency eq 'idr') {
            # do nothing
        } elsif (grep {$currency eq $_} @Idr_Market_Currencies) {
            if ($rec->{bal_total} > 0) {
                push @idr_markets, $currency;
            }
        } elsif (grep {$currency eq $_} @Btc_Market_Currencies) {
            if ($rec->{bal_total} > 0) {
                push @idr_markets, "btc" unless grep {$_ eq 'btc'} @idr_markets;
                push @btc_markets, $currency;
            }
        } else {
            if ($rec->{bal_total} > 0) {
                log_error "Don't know where to find current price for ".
                    "'$currency' (not found in IDR markets nor BTC markets), skipped";
            }
        }
        push @recs, $rec;
    }

    my $fnum0 = [number => {precision=>0}];
    my $fnum8 = [number => {precision=>8}];

    my %resmeta;
    if ($args{with_idr_estimates}) {
        my %idr_prices;
        for my $currency (@idr_markets) {
            my $res = $indodax->get_ticker(pair => _convert_pair("${currency}_idr"));
            $idr_prices{$currency} = ($res->{ticker}{buy} + $res->{ticker}{sell})/2;
        }
        my %btc_prices;
        for my $currency (@btc_markets) {
            my $res = $indodax->get_ticker(pair => _convert_pair("${currency}_btc"));
            $btc_prices{$currency} = ($res->{ticker}{buy} + $res->{ticker}{sell})/2;
        }

        my $tot_avail_est_idr = 0;
        my $tot_held_est_idr  = 0;
        my $tot_total_est_idr = 0;
        for my $rec (@recs) {
            my $currency = $rec->{currency};
            if ($currency eq 'idr') {
                $rec->{avail_est_idr} = $rec->{bal_avail};
                $rec->{held_est_idr}  = $rec->{bal_held};
                $rec->{total_est_idr} = $rec->{bal_total};
            } elsif (grep {$currency eq $_} @idr_markets) {
                $rec->{price_idr}     = $idr_prices{$currency};
                $rec->{avail_est_idr} = ($idr_prices{$currency} // 0) * $rec->{bal_avail};
                $rec->{held_est_idr}  = ($idr_prices{$currency} // 0) * $rec->{bal_held};
                $rec->{total_est_idr} = ($idr_prices{$currency} // 0) * $rec->{bal_total};
            } else {
                # btc markets
                $rec->{price_btc}     = $btc_prices{$currency};
                $rec->{price_idr}     = ($idr_prices{btc} // 0) * ($btc_prices{$currency} // 0);
                $rec->{avail_est_idr} = ($idr_prices{btc} // 0) * ($btc_prices{$currency} // 0) * $rec->{bal_avail};
                $rec->{held_est_idr}  = ($idr_prices{btc} // 0) * ($btc_prices{$currency} // 0) * $rec->{bal_held};
                $rec->{total_est_idr} = ($idr_prices{btc} // 0) * ($btc_prices{$currency} // 0) * $rec->{bal_total};
            }
            $tot_avail_est_idr += $rec->{avail_est_idr};
            $tot_held_est_idr  += $rec->{held_est_idr};
            $tot_total_est_idr += $rec->{total_est_idr};
        }

        # calculate percentages
        for my $rec (@recs) {
            if ($tot_total_est_idr > 0) {
                $rec->{pct_est_idr} = $rec->{total_est_idr} / $tot_total_est_idr;
            } else {
                $rec->{pct_est_idr} = 0;
            }
        }

        push @recs, {
            currency => 'est_idr',
            avail_est_idr => $tot_avail_est_idr,
            held_est_idr  => $tot_held_est_idr,
            total_est_idr => $tot_total_est_idr,
            pct_est_idr   => 1,
        };
        $resmeta{'table.fields'}        = [qw/currency bal_avail price_btc price_idr avail_est_idr bal_held held_est_idr bal_total total_est_idr pct_est_idr/];
        $resmeta{'table.field_aligns'}  = [qw/left     right     right     right     right         right    right        right     right         right/];
        $resmeta{'table.field_formats'} = [undef,      undef,    $fnum8,   $fnum0,   $fnum0,       $fnum8,  $fnum0,      $fnum8,   $fnum0,       'percent'];
    } else {
        $resmeta{'table.fields'}        = [qw/currency bal_avail bal_held bal_total/];
        $resmeta{'table.field_aligns'}  = [qw/left     right     right    right/];
        $resmeta{'table.field_formats'} = [undef,      $fnum8,   $fnum8,  $fnum8,];
    }

    [200, "OK", \@recs, \%resmeta];
}

$SPEC{hold_details} = {
    v => 1.1,
    summary => 'Show in which open orders your currency is being held',
    args => {
        %args_tapi,
        %arg_0_currency,
    },
};
sub hold_details {
    my %args = @_;
    _init(\%args);

    my $currency = $args{currency};
    my $currency0 = $Rev_Canonical_Currencies{$currency} // $currency;
    my $res = $indodax->get_info;
    my $bal      = $res->{return}{balance}{$currency0}      // 0;
    my $bal_held = $res->{return}{balance_hold}{$currency0} // 0;

    my @rows;
    if ($bal_held > 0) {
        for my $pair (@Market_Pairs) {
            #log_trace "pair=%s", $pair;
            my $buy_with_currency;
            my $currency2;
            if ($pair =~ /\A(\w+)_\Q$currency\E\z/) {
                $buy_with_currency = 1;
                $currency2 = $1;
            } elsif ($pair =~ /\A\Q$currency\E_(\w+)\z/) {
                $buy_with_currency = 0;
                $currency2 = $1;
            } else {
                next;
            }
            my $orders;
            eval {
                $orders = $indodax->get_open_orders(
                    pair => _convert_pair($pair),
                )->{return}{orders};
            };
            if ($@) {
                log_warn "Can't get open orders for pair $pair: $@, skipped";
                next;
            }
            for my $order (@$orders) {
                if ($buy_with_currency) {
                    next unless $order->{type} eq 'buy';
                    push @rows, {
                        order_id          => $order->{order_id},
                        pair              => $pair,
                        submit_time       => $order->{submit_time},
                        type              => $order->{type},
                        price             => $order->{price},
                        amount            => $order->{"remain_$currency"},
                    };
                } else {
                    next unless $order->{type} eq 'sell';
                    push @rows, {
                        order_id          => $order->{order_id},
                        pair              => $pair,
                        submit_time       => $order->{submit_time},
                        type              => $order->{type},
                        price             => $order->{price},
                        amount            => $order->{"remain_$currency"},
                    };
                }
            }
        } # for pair
        push @rows, {
            pair => 'TOTAL',
            amount => $bal_held,
        };
    }

    my $fnum0 = [number => {precision=>0}];
    my $fnum8 = [number => {precision=>8}];

    my $fnum  = $currency eq 'idr' ? $fnum0 : $fnum8;

    my %resmeta;
    $resmeta{'table.fields'}        = [qw/order_id pair submit_time type price amount/];
    $resmeta{'table.field_formats'} = [undef, undef, 'iso8601_datetime', undef, $fnum, $fnum];
    $resmeta{'table.field_aligns'}  = [qw/right    left left        left right right/];

    [200, "OK", \@rows, \%resmeta];
}

$SPEC{profit} = {
    v => 1.1,
    summary => 'Calculate your profit',
    args => {
        %args_tapi,
        %arg_0_pair,
        %args_filter_time,
    },
};
sub profit {
    my %args = @_;
    _init(\%args);

    my $res = trade_history(%args);
    return $res unless $res->[0] == 200;

    my $fmt = "%.8f";

    my ($currency1, $currency2) = $args{pair} =~ /(\w{3})_(\w{3})/;

    my %buy_amts ; # key = formatted price, val = amount
    my %sell_amts; # key = formatted price, val = amount
    my $profit = 0;

    my $code_sell_or_buy_or_remove = sub {
        my $rec = shift;
        log_trace "record: %s", $rec;
        my $price = sprintf($fmt, $rec->{price} + ($rec->{fee} // 0));
        my $amt = $rec->{$currency1};
        if ($rec->{type} eq 'buy') {
            $buy_amts{$price} += $amt;
            $profit -= $price * $amt;
        } elsif ($rec->{type} eq 'sell' || $rec->{type} eq 'remove') {
            if ($rec->{type} eq 'sell') {
                $sell_amts{$price} += $amt;
                $profit += $price * $amt;
            }

            # calculate current stock, eliminate the cheapest first
            while ($amt > 1e-10) {
                # sanity check (can happen if we pick time range)
                #die "BUG: Selling more than bought" unless keys %buy_amts;

                for my $price (sort {$a<=>$b} keys %buy_amts) {
                    if ($amt - $buy_amts{$price} >= 1e-10) {
                        $amt -= delete $buy_amts{$price};
                    } else {
                        $buy_amts{$price} -= $amt;
                        $amt = 0;
                    }
                    last if $amt <= 1e-10;
                }
            }
        } else {
            die "BUG: unknown type '$rec->{type}'";
        }
        log_trace "stock: %s", \%buy_amts;
    };

    for my $rec (reverse @{ $res->[2] }) {
        $code_sell_or_buy_or_remove->($rec);
    }

  AGAIN:
    my $tot_buy_price = 0;
    my $tot_buy_amts  = 0;
    my $avg_buy_price = 0;
    for my $price (keys %buy_amts) {
        $tot_buy_price += $buy_amts{$price} * $price;
        $tot_buy_amts  += $buy_amts{$price};
    }
    $avg_buy_price = $tot_buy_price / $tot_buy_amts if $tot_buy_amts > 0;

    my $tot_sell_price = 0;
    my $tot_sell_amts  = 0;
    my $avg_sell_price = 0;
    for my $price (keys %sell_amts) {
        $tot_sell_price += $sell_amts{$price} * $price;
        $tot_sell_amts  += $sell_amts{$price};
    }
    $avg_sell_price = $tot_sell_price / $tot_sell_amts if $tot_sell_amts > 0;

    my $resbal = balance(%args);
    return $resbal unless $resbal->[0] == 200;
    my $actual_bal = 0;
    for my $rec (@{$resbal->[2]}) {
        if ($rec->{currency} eq $currency1) {
            $actual_bal = $rec->{bal_total};
            last;
        }
    }

    #if ($tot_$actual_bal > 1e-10) {
        # actual balance is smaller, remove
    #}
    # XXX if actual balance is larger?

    my $res2 = $indodax->get_ticker(pair => _convert_pair($args{pair}));
    my $cur_price = ($res2->{ticker}{buy} + $res2->{ticker}{sell}) / 2;

    [200, "OK", {
        avg_buy_price  => $avg_buy_price,
        avg_sell_price => $avg_sell_price,
        profit         => $profit,
        amount_in_hand => $tot_buy_amts,
        cur_price      => $cur_price,
        asset_in_hand  => $tot_buy_amts * $cur_price,
        profit_plus_asset_in_hand => $profit + $tot_buy_amts * $cur_price,
    }, {
        'func.buy_amts'  => \%buy_amts,
        'func.sell_amts' => \%sell_amts,
    }];
}

$SPEC{tx_history} = {
    v => 1.1,
    summary => 'Show history of deposits and withdrawals',
    args => {
        %args_tapi,
        %arg_filter_txtype,
        %arg_filter_currency,
    },
};
sub tx_history {
    my %args = @_;
    _init(\%args);

    my $res = $indodax->get_tx_history->{return};

    # rearrange into a single table
    my @rows;
    for my $txtype (sort keys %$res) {
        my $v1 = $res->{$txtype};
        for my $currency (sort keys %$v1) {
            my $v2 = $v1->{$currency};
            for my $row (@$v2) {
                next if $args{txtype} && $txtype ne $args{txtype};
                next if $args{currency} && $currency ne $args{currency};
                $row->{txtype} = $txtype;
                $row->{currency} = $currency;
                push @rows, $row;
            }
        }
    }

    my $fnum0 = [number => {precision=>0}];

    my $resmeta = {};
    $resmeta->{'table.fields'}        = [qw/txtype currency type deposit_id amount rp fee submit_time success_time status/];
    $resmeta->{'table.field_formats'} = [undef, undef, undef, undef, $fnum0, $fnum0, $fnum0, 'iso8601_datetime', 'iso8601_datetime', undef];
    $resmeta->{'table.field_aligns'}  = [qw/left left left right right right right left left left/];

    [200, "OK", \@rows, $resmeta];
}

$SPEC{trade_history} = {
    v => 1.1,
    summary => 'Show history of trades',
    args => {
        %args_tapi,
        %arg_0_pair,
        # XXX count
        # XXX order asc/desc
        %args_filter_trade_id,
        %args_filter_time,
    },
};
sub trade_history {
    my %args = @_;
    _init(\%args);

    my $res = $indodax->get_trade_history(
        pair => _convert_pair($args{pair}),
        (since => $args{time_from}) x !!(defined $args{time_from}),
        (end   => $args{time_to}  ) x !!(defined $args{time_to}  ),
        (from_id => $args{trade_id_from}) x !!(defined $args{trade_id_from}),
        (end_id  => $args{trade_id_to}  ) x !!(defined $args{trade_id_to}  ),
    )->{return};

    # rearrange into a single table
    my @rows;
    for my $row (@{ $res->{trades} }) {
        push @rows, $row;
    }

    my $fnum0 = [number => {precision=>0}];
    my $fnum8 = [number => {precision=>8}];

    my $resmeta = {};
    $resmeta->{'table.fields'}        = [qw/trade_id order_id trade_time type btc price fee/];
    $resmeta->{'table.field_formats'} = [undef, undef, 'iso8601_datetime', undef, $fnum8, $fnum8, $fnum8];
    $resmeta->{'table.field_aligns'}  = [qw/right right left left right right right/];

    [200, "OK", \@rows, $resmeta];
}

$SPEC{trade_history_total} = {
    v => 1.1,
    summary => 'Show total amount of trades',
    args => {
        %args_tapi,
        %arg_0_market,
        %args_filter_time,
    },
};
sub trade_history_total {
    my %args = @_;
    _init(\%args);

    my %res = (
        num_sells => 0,
        num_buys  => 0,
        total_amount => 0,
        total_fee    => 0,
    );

    for my $pair (@Market_Pairs) {
        my ($cur1, $cur2) = $pair =~ /(\w+)_(\w+)$/;
        next unless $cur2 eq $args{market};

        my $pair0 = _convert_pair($pair);
        my ($cur10, $cur20) = $pair0 =~ /(\w+)_(\w+)$/;

        my $res0;
        eval {
            $res0 = $indodax->get_trade_history(
                pair => $pair0,
                (since => $args{time_from}) x !!(defined $args{time_from}),
                (end   => $args{time_to}  ) x !!(defined $args{time_to}  ),
            )->{return};
        };
        if ($@) {
            log_warn "Can't get trade history for pair $pair: $@, skipped";
            next;
        }

        for my $row (@{ $res0->{trades} }) {
            if ($row->{type} eq 'sell') {
                $res{num_sells}++;
            } elsif ($row->{type} eq 'buy') {
                $res{num_buys}++;
            }
            $res{total_amount} += $row->{$cur10} * $row->{price};
            $res{total_fee}    += $row->{fee};
        }
    }

    [200, "OK", \%res];
}

$SPEC{open_orders} = {
    v => 1.1,
    summary => 'Show open orders',
    args => {
        %args_tapi,
        %arg_filter_pair,
        %arg_filter_type,
    },
};
sub open_orders {
    my %args = @_;
    _init(\%args);

    my @rows;
  PAIR:
    for my $pair (@Market_Pairs) {
        #log_trace "pair=%s", $pair;
        if ($args{pair}) {
            next PAIR unless $pair eq $args{pair};
        }
        my $orders;
        eval {
            $orders = $indodax->get_open_orders(
                pair => _convert_pair($pair),
            )->{return}{orders};
        };

      ORDER:
        for my $row (@$orders) {
            if ($args{type}) {
                next ORDER unless $row->{type} eq $args{type};
            }
            $row->{pair} = $pair unless $args{pair};
            push @rows, $row;
        }
    }

    my $fnum0 = [number => {precision=>0}];
    my $fnum8 = [number => {precision=>8}];

    my $resmeta = {};
    $resmeta->{'table.fields'}        = [qw/pair order_id submit_time type/];
    $resmeta->{'table.field_formats'} = [undef, undef, 'iso8601_datetime', undef];
    $resmeta->{'table.field_aligns'}  = [qw/left right left left right right right right right/];

    [200, "OK", \@rows, $resmeta];
}

$SPEC{create_order} = {
    v => 1.1,
    summary => 'Create a new order',
    args => {
        %args_tapi,
        %arg_pair,
        %arg_0_type,
        price => {
            schema => 'posint*',
            req => 1,
            pos => 1,
        },
        idr => {
            schema => 'posint*',
            # Perinci::Sub::GetArgs::Argv not smart enough yet
            #pos => 2,
        },
        btc => {
            schema => 'float*',
            # Perinci::Sub::GetArgs::Argv not smart enough yet
            #pos => 2,
        },
    },
    args_rels => {
        req_one => [qw/idr btc/],
    },
};
sub create_order {
    my %args = @_;
    _init(\%args);

    my $res = $indodax->create_order(
        pair => _convert_pair($args{pair}),
        type => $args{type},
        price => $args{price},
        (idr => $args{idr}) x !!(defined $args{idr}),
        (btc => $args{btc}) x !!(defined $args{btc}),
    )->{return};

    [200, "OK"];
}

$SPEC{cancel_order} = {
    v => 1.1,
    summary => 'Cancel an existing open order',
    args => {
        %args_tapi,
        %arg_pair,
        %arg_0_type,
        order_id => {
            schema => 'posint*',
            req => 1,
            pos => 1,
        },
    },
    features => {
        dry_run => 1,
    },
};
sub cancel_order {
    my %args = @_;
    _init(\%args);

    if ($args{-dry_run}) {
        # XXX check if order exists
        [200, "OK (dry-run)"];
    } else {
        $indodax->cancel_order(
            type => $args{type},
            pair => _convert_pair($args{pair}),
            order_id => $args{order_id},
        );
        [200, "OK"];
    }
}

$SPEC{cancel_orders} = {
    v => 1.1,
    summary => 'Cancel one or more open orders matching criteria',
    args => {
        %args_tapi,
        %arg_filter_pair,
        %arg_filter_type,
        %arg_filter_currency,
    },
    features => {
        dry_run => 1,
    },
};
sub cancel_orders {
    my %args = @_;
    _init(\%args);

  PAIR:
    for my $pair (@Market_Pairs) {
        #log_trace "pair=%s", $pair;
        if ($args{pair}) {
            unless ($pair eq $args{pair}) {
                log_trace "Skipped pair '$pair' because of pair filter";
                next PAIR;
            }
        }
        if ($args{currency}) {
            unless ($pair =~ /\A\w+_\Q$args{currency}\E\z|\A\Q$args{currency}\E_\w+\z/) {
                log_trace "Skipped pair '$pair' because of currency filter";
                next PAIR;
            }
        }
        my $orders;
        eval {
            $orders = $indodax->get_open_orders(
                pair => _convert_pair($pair),
            )->{return}{orders};
        };
        if ($@) {
            log_warn "Can't get open orders for pair $pair: $@, skipped";
            next;
        }
      ORDER:
        for my $order (@$orders) {
            if ($args{type}) {
                unless ($order->{type} eq $args{type}) {
                    log_trace "Skipped order #$order->{order_id} (pair '$pair', type '$order->{type}') because of type filter";
                    next ORDER;
                }
            }
            if ($args{-dry_run}) {
                log_info "[DRY RUN] Cancelling order #$order->{order_id} (pair $pair) ...";
            } else {
                log_info "Cancelling order #$order->{order_id} (pair $pair) ...";
                eval {
                    $indodax->cancel_order(
                        type => $order->{type},
                        pair => _convert_pair($pair),
                        order_id => $order->{order_id},
                    );
                };
                if ($@) {
                    log_error "Failed cancelling order #$order->{order_id} (pair $pair): $@";
                }
            }
        } # for order
    } # for pair

    [200, "OK"];
}

$SPEC{cancel_all_orders} = {
    v => 1.1,
    summary => 'Cancel all existing open orders',
    args => {
        %args_tapi,
    },
    features => {
        dry_run => 1,
    },
};
sub cancel_all_orders {
    my %args = @_;
    cancel_orders(%args);
}

1;
# ABSTRACT: CLI for Indodax.com

__END__

=pod

=encoding UTF-8

=head1 NAME

App::indodax - CLI for Indodax.com

=head1 VERSION

This document describes version 0.024 of App::indodax (from Perl distribution App-indodax), released on 2018-06-12.

=head1 SYNOPSIS

Please see included script L<indodax>.

=head1 DESCRIPTION

B<DEPRECATION WARNING:> This app is being deprecated in favor of
L<App::cryp::Exchange::indodax> and L<cryp-exchange>.

=head1 FUNCTIONS


=head2 balance

Usage:

 balance(%args) -> [status, msg, result, meta]

Show current balances.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

=item * B<secret>* => I<str>

=item * B<with_idr_estimates> => I<bool>

Also show the value of all assets in IDR, using current prices information.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 cancel_all_orders

Usage:

 cancel_all_orders(%args) -> [status, msg, result, meta]

Cancel all existing open orders.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

=item * B<secret>* => I<str>

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 cancel_order

Usage:

 cancel_order(%args) -> [status, msg, result, meta]

Cancel an existing open order.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

=item * B<order_id>* => I<posint>

=item * B<pair> => I<str> (default: "btc_idr")

Pair.

=item * B<secret>* => I<str>

=item * B<type>* => I<str>

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 cancel_orders

Usage:

 cancel_orders(%args) -> [status, msg, result, meta]

Cancel one or more open orders matching criteria.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<currency> => I<str>

Filter by currency.

=item * B<key>* => I<str>

=item * B<pair> => I<str>

Filter by pair.

=item * B<secret>* => I<str>

=item * B<type> => I<str>

Filter by type (buy/sell).

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 create_order

Usage:

 create_order(%args) -> [status, msg, result, meta]

Create a new order.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<btc> => I<float>

=item * B<idr> => I<posint>

=item * B<key>* => I<str>

=item * B<pair> => I<str> (default: "btc_idr")

Pair.

=item * B<price>* => I<posint>

=item * B<secret>* => I<str>

=item * B<type>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 depth

Usage:

 depth(%args) -> [status, msg, result, meta]

Show depth.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<pair> => I<str> (default: "btc_idr")

Pair.

=item * B<type> => I<str>

Filter by type (buy/sell).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 hold_details

Usage:

 hold_details(%args) -> [status, msg, result, meta]

Show in which open orders your currency is being held.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<currency> => I<str> (default: "idr")

Currency name.

=item * B<key>* => I<str>

=item * B<secret>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 info

Usage:

 info(%args) -> [status, msg, result, meta]

Show balance, server timestamp, and some other information.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

=item * B<secret>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 open_orders

Usage:

 open_orders(%args) -> [status, msg, result, meta]

Show open orders.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

=item * B<pair> => I<str>

Filter by pair.

=item * B<secret>* => I<str>

=item * B<type> => I<str>

Filter by type (buy/sell).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pairs

Usage:

 pairs() -> [status, msg, result, meta]

List available pairs.

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


=head2 price_history

Usage:

 price_history(%args) -> [status, msg, result, meta]

Show price history, which can be used to draw candlestick chart.

The function will return an array of records. Each record is an array with the
following data:

 [timestamp-in-unix-epoch, open, high, low, close]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<period> => I<str> (default: "day")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 private

Usage:

 private(%args) -> [status, msg, result, meta]

Perform private API (TAPI) request.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 profit

Usage:

 profit(%args) -> [status, msg, result, meta]

Calculate your profit.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

=item * B<pair> => I<str> (default: "btc_idr")

Pair.

=item * B<secret>* => I<str>

=item * B<time_from> => I<date>

Filter by beginning time.

=item * B<time_to> => I<date>

Filter by ending time.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 public

Usage:

 public(%args) -> [status, msg, result, meta]

Perform public API request.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args> => I<hash>

=item * B<method> => I<str> (default: "GET")

=item * B<uri>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 ticker

Usage:

 ticker(%args) -> [status, msg, result, meta]

Show ticker.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<pair> => I<str> (default: "btc_idr")

Pair.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 trade_history

Usage:

 trade_history(%args) -> [status, msg, result, meta]

Show history of trades.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

=item * B<pair> => I<str> (default: "btc_idr")

Pair.

=item * B<secret>* => I<str>

=item * B<time_from> => I<date>

Filter by beginning time.

=item * B<time_to> => I<date>

Filter by ending time.

=item * B<trade_id_from> => I<int>

Filter by beginning trade ID.

=item * B<trade_id_to> => I<int>

Filter by ending trade ID.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 trade_history_total

Usage:

 trade_history_total(%args) -> [status, msg, result, meta]

Show total amount of trades.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

=item * B<market> => I<str> (default: "idr")

Market.

=item * B<secret>* => I<str>

=item * B<time_from> => I<date>

Filter by beginning time.

=item * B<time_to> => I<date>

Filter by ending time.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 trades

Usage:

 trades(%args) -> [status, msg, result, meta]

Show latest trades.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<pair> => I<str> (default: "btc_idr")

Pair.

=item * B<type> => I<str>

Filter by type (buy/sell).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 tx_history

Usage:

 tx_history(%args) -> [status, msg, result, meta]

Show history of deposits and withdrawals.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<currency> => I<str>

Filter by currency.

=item * B<key>* => I<str>

=item * B<secret>* => I<str>

=item * B<txtype> => I<str>

Filter by transaction type (deposit/withdraw).

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

Please visit the project's homepage at L<https://metacpan.org/release/App-indodax>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-indodax>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-indodax>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Finance::Indodax>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
