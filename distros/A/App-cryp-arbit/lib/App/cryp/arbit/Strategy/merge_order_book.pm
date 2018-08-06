package App::cryp::arbit::Strategy::merge_order_book;

our $DATE = '2018-08-04'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::cryp::arbit;
use Finance::Currency::FiatX;
use List::Util qw(min max shuffle);
use Storable qw(dclone);
use Time::HiRes qw(time);

use Role::Tiny::With;

with 'App::cryp::Role::ArbitStrategy';

sub _calculate_order_pairs_for_base_currency {
    my %args = @_;

    my $base_currency         = $args{base_currency};
    my $all_buy_orders        = $args{all_buy_orders};
    my $all_sell_orders       = $args{all_sell_orders};
    my $min_net_profit_margin = $args{min_net_profit_margin} // 0;
    my $max_order_quote_size  = $args{max_order_quote_size};
    my $max_order_pairs       = $args{max_order_pairs};
    my $max_order_size_as_book_item_size_pct = $args{max_order_size_as_book_item_size_pct} // 100;
    my $account_balances      = $args{account_balances};
    my $min_account_balances  = $args{min_account_balances};
    my $exchange_pairs        = $args{exchange_pairs};
    my $forex_spreads         = $args{forex_spreads};

    my @order_pairs;
    my $opportunity;

    for (@{ $all_buy_orders }, @{ $all_sell_orders }) {
        $_->{base_size} *= $max_order_size_as_book_item_size_pct/100;
    }

    if ($account_balances && $min_account_balances) {
        for my $e (keys %$account_balances) {
            my $balances = $account_balances->{$e};
            for my $cur (keys %$balances) {
                my $curbalances = $balances->{$cur};
                for my $rec (@$curbalances) {
                    my $eacc = "$e/$rec->{account}";
                    if (defined $min_account_balances->{$eacc} &&
                            defined $min_account_balances->{$eacc}{$cur}) {
                        $rec->{available} -= $min_account_balances->{$eacc}{$cur};
                    }
                }
            }
        }
        App::cryp::arbit::_sort_account_balances($account_balances);
    }

  CREATE:
    while (1) {
        last CREATE if defined $max_order_pairs &&
            @order_pairs >= $max_order_pairs;

        my ($sell, $sell_index);
      FIND_BUYER:
        {
            $sell_index = 0;
            while ($sell_index < @$all_buy_orders) {
                $sell = $all_buy_orders->[$sell_index];
                if ($account_balances) {
                    # we don't have any inventory left to sell on this selling
                    # exchange
                    unless (@{ $account_balances->{ $sell->{exchange} }{$base_currency} // [] }) {
                        $sell_index++; next;
                    }
                }
                last;
            }
            # there are no more buyers left we can sell to
            last CREATE unless $sell_index < @$all_buy_orders;
        }

        my ($buy, $buy_index);
      FIND_SELLER:
        {
            $buy_index = 0;
            while ($buy_index < @$all_sell_orders) {
                $buy = $all_sell_orders->[$buy_index];
                # shouldn't happen though
                if ($buy->{exchange} eq $sell->{exchange}) {
                    $buy_index++; next;
                }
                if ($account_balances) {
                    # we don't have any inventory left to buy from this exchange
                    unless (@{ $account_balances->{ $buy->{exchange} }{$buy->{quote_currency}} // [] }) {
                        $buy_index++; next;
                    }
                }
                last;
            }
            # there are no more sellers left we can buy from
            last CREATE unless $buy_index < @$all_sell_orders;
        }

        my $gross_profit_margin = ($sell->{gross_price} - $buy->{gross_price}) /
            min($sell->{gross_price}, $buy->{gross_price}) * 100;
        my $trading_profit_margin = ($sell->{net_price} - $buy->{net_price}) /
            min($sell->{net_price}, $buy->{net_price}) * 100;

        # record opportunity, the currently highest trading profit margin
        unless ($opportunity) {
            my $quote_currency = $sell->{quote_currency};
            if (App::cryp::arbit::_is_fiat($quote_currency)) {
                $quote_currency = "USD";
            }
            $opportunity = {
                time => time(),
                base_currency         => $base_currency,
                quote_currency        => $quote_currency,
                buy_exchange          => $buy->{exchange},
                buy_price             => $buy->{gross_price},
                sell_exchange         => $sell->{exchange},
                sell_price            => $sell->{gross_price},
                gross_profit_margin   => $gross_profit_margin,
                trading_profit_margin => $trading_profit_margin,
            };
        }

        if ($trading_profit_margin < $min_net_profit_margin) {
            log_trace "Ending matching buy->sell because trading profit margin is too low (%.4f%%, wants >= %.4f%%%)",
                $trading_profit_margin, $min_net_profit_margin;
            last CREATE;
        }

        my $order_pair = {
            sell => {
                exchange         => $sell->{exchange},
                pair             => "$base_currency/$sell->{quote_currency}",
                gross_price_orig => $sell->{gross_price_orig},
                gross_price      => $sell->{gross_price},
                net_price_orig   => $sell->{net_price_orig},
                net_price        => $sell->{net_price},
            },
            buy => {
                exchange         => $buy->{exchange},
                pair             => "$base_currency/$buy->{quote_currency}",
                gross_price_orig => $buy->{gross_price_orig},
                gross_price      => $buy->{gross_price},
                net_price_orig   => $buy->{net_price_orig},
                net_price        => $buy->{net_price},
            },
            gross_profit_margin => $gross_profit_margin,
            trading_profit_margin => $trading_profit_margin,
        };

        if ($account_balances) {
            $order_pair->{sell}{account} = $account_balances->{ $sell->{exchange} }{$base_currency}[0]{account};
            $order_pair->{buy}{account}  = $account_balances->{ $buy ->{exchange} }{$buy->{quote_currency}}[0]{account};
        }

        # limit maximum size of order
        my @sizes = (
            {which => 'buy order' , size => $sell->{base_size}},
            {which => 'sell order', size => $buy ->{base_size}},
        );
        if (defined $max_order_quote_size) {
            push @sizes, (
                {which => 'max_order_quote_size', size => $max_order_quote_size / max($sell->{gross_price}, $buy->{gross_price})},
            );
        }
        if ($account_balances) {
            push @sizes, (
                {
                    which => 'sell exchange balance',
                    size => $account_balances->{ $sell->{exchange} }{$base_currency}[0]{available},
                },
                {
                    which => 'buy exchange balance',
                    size => $account_balances->{ $buy ->{exchange} }{$buy->{quote_currency}}[0]{available}
                        / $buy->{gross_price_orig},
                },
            );
        }
        @sizes = sort { $a->{size} <=> $b->{size} } @sizes;
        my $order_size = $sizes[0]{size};

        $order_pair->{base_size} = $order_size;
        $order_pair->{gross_profit} = $order_size *
            ($order_pair->{sell}{gross_price} - $order_pair->{buy}{gross_price});
        $order_pair->{trading_profit} = $order_size *
            ($order_pair->{sell}{net_price} - $order_pair->{buy}{net_price});

      UPDATE_INVENTORY_BALANCES:
        for my $i (0..$#sizes) {
            my $size  = $sizes[$i]{size};
            my $which = $sizes[$i]{which};
            my $used_up = $size - $order_size <= 1e-8;
            if ($which eq 'buy order') {
                if ($used_up) {
                    splice @$all_buy_orders, $sell_index, 1;
                } else {
                    $all_buy_orders->[$sell_index]{base_size} -= $order_size;
                }
            } elsif ($which eq 'sell order') {
                if ($used_up) {
                    splice @$all_sell_orders, $buy_index, 1;
                } else {
                    $all_sell_orders->[$buy_index]{base_size} -= $order_size;
                }
            } elsif ($which eq 'sell exchange balance') {
                if ($used_up) {
                    shift @{ $account_balances->{ $sell->{exchange} }{$base_currency} };
                } else {
                    $account_balances->{ $sell->{exchange} }{$base_currency}[0]{available} -=
                        $order_size;
                }
            } elsif ($which eq 'buy exchange balance') {
                my $c = $buy->{quote_currency};
                if ($used_up) {
                    shift @{ $account_balances->{ $buy->{exchange} }{$c} };
                } else {
                    $account_balances->{ $buy->{exchange} }{$c}[0]{available} -=
                        $order_size * $buy->{gross_price_orig};
                }
            }
        } # UPDATE_INVENTORY_BALANCES

        if ($account_balances) {
            App::cryp::arbit::_sort_account_balances($account_balances);
        }

      CHECK_MINIMUM_BUY_SIZE:
        {
            last unless $exchange_pairs;
            my $pair_recs = $exchange_pairs->{ $buy->{exchange} };
            last unless $pair_recs;
            my $pair_rec;
            for (@$pair_recs) {
                if ($_->{base_currency} eq $base_currency) {
                    $pair_rec = $_; last;
                }
            }
            last unless $pair_rec;
            if (defined($pair_rec->{min_base_size}) && $order_pair->{base_size} < $pair_rec->{min_base_size}) {
                log_trace "buy order base size is too small (%.4f < %.4f), skipping this order pair: %s",
                    $order_pair->{base_size}, $pair_rec->{min_base_size}, $order_pair;
                next CREATE;
            }
            my $quote_size = $order_pair->{base_size}*$buy->{gross_price_orig};
            if (defined($pair_rec->{min_quote_size}) && $quote_size < $pair_rec->{min_quote_size}) {
                log_trace "buy order quote size is too small (%.4f < %.4f), skipping this order pair: %s",
                    $quote_size, $pair_rec->{min_quote_size}, $order_pair;
                next CREATE;
            }
        } # CHECK_MINIMUM_BUY_SIZE

      CHECK_MINIMUM_SELL_SIZE:
        {
            last unless $exchange_pairs;
            my $pair_recs = $exchange_pairs->{ $sell->{exchange} };
            last unless $pair_recs;
            my $pair_rec;
            for (@$pair_recs) {
                if ($_->{base_currency} eq $base_currency) {
                    $pair_rec = $_; last;
                }
            }
            last unless $pair_rec;
            if (defined $pair_rec->{min_base_size} && $order_pair->{base_size} < $pair_rec->{min_base_size}) {
                log_trace "sell order base size is too small (%.4f < %.4f), skipping this order pair: %s",
                    $order_pair->{base_size}, $pair_rec->{min_base_size}, $order_pair;
                next CREATE;
            }
            my $quote_size = $order_pair->{base_size}*$sell->{gross_price_orig};
            if (defined $pair_rec->{min_quote_size} && $quote_size < $pair_rec->{min_quote_size}) {
                log_trace "sell order quote size is too small (%.4f < %.4f), skipping this order pair: %s",
                    $quote_size, $pair_rec->{min_quote_size}, $order_pair;
                next CREATE;
            }
        } # CHECK_MINIMUM_SELL_SIZE

        push @order_pairs, $order_pair;

    } # CREATE

  ADJUST_FOREX_SPREAD:
    {
        my @tmp = @order_pairs;
        @order_pairs = ();
        my $i = 0;
      ORDER_PAIR:
        for my $op (@tmp) {
            $i++;
            my ($bcur) = $op->{buy}{pair}  =~ m!/(.+)!;
            my ($scur) = $op->{sell}{pair} =~ m!/(.+)!;

            if ($bcur eq $scur) {
                # there is no forex spread
                $op->{net_profit_margin} = $op->{trading_profit_margin};
                $op->{net_profit} = $op->{trading_profit};
                goto ADD;
            }

            my $spread;
            $spread = $forex_spreads->{"$bcur/$scur"} if $forex_spreads;

            unless (defined $spread) {
                log_warn "Order pair #%d (buy %s - sell %s): didn't find ".
                    "forex spread for %s/%s, not adjusting for forex spread",
                    $i, $op->{buy}{pair}, $op->{sell}{pair}, $bcur, $scur;
                next ORDER_PAIR;
            }
            log_trace "Order pair #%d (buy %s - sell %s, trading profit margin %.4f%%): adjusting ".
                "with %s/%s forex spread %.4f%%",
                $i, $op->{buy}{pair}, $op->{sell}{pair}, $op->{trading_profit_margin}, $bcur, $scur, $spread;
            $op->{forex_spread} = $spread;
            $op->{net_profit_margin} = $op->{trading_profit_margin} - $spread;
            $op->{net_profit} = $op->{trading_profit} * $op->{net_profit_margin} / $op->{trading_profit_margin};
            if ($op->{net_profit_margin} < $min_net_profit_margin) {
                log_trace "Order pair #%d: After forex spread adjustment, net profit margin is too small (%.4f%%, wants >= %.4f%%), skipping this order pair",
                    $i, $op->{net_profit_margin}, $min_net_profit_margin;
                next ORDER_PAIR;
            }

          ADD:
            push @order_pairs, $op;
        }
    } # ADJUST_FOREX_SPREAD

    # re-sort
    @order_pairs = sort { $b->{net_profit_margin} <=> $a->{net_profit_margin} } @order_pairs;

    (\@order_pairs, $opportunity);
}

sub calculate_order_pairs {
    my ($pkg, %args) = @_;

    my $r = $args{r};
    my $dbh = $r->{_stash}{dbh};

    my @order_pairs;

  GET_ACCOUNT_BALANCES:
    {
        last if $r->{args}{ignore_balance};
        App::cryp::arbit::_get_account_balances($r, 'no-cache');
    } # GET_ACCOUNT_BALANCES

  GET_FOREX_RATES:
    {
        # get foreign fiat currency vs USD exchange rate. we'll use the average
        # rate for this first. but we'll adjust the price difference percentage
        # with the buy-sell spread later.

        my %seen;

        $r->{_stash}{forex_rates} = {};

        for my $cur (@{ $r->{_stash}{quote_currencies} }) {
            next unless App::cryp::arbit::_is_fiat($cur);
            next if $cur eq 'USD';
            next if $seen{$cur}++;

            require Finance::Currency::FiatX;

            my $fxres_low  = Finance::Currency::FiatX::get_spot_rate(
                dbh => $dbh, from => $cur, to => 'USD', type => 'buy', source => ':lowest');
            if ($fxres_low->[0] != 200) {
                return [412, "Couldn't get conversion rate (lowest buy) from ".
                            "$cur to USD: $fxres_low->[0] - $fxres_low->[1]"];
            }

            my $fxres_high = Finance::Currency::FiatX::get_spot_rate(
                dbh => $dbh, from => $cur, to => 'USD', type => 'sell', source => ':highest');
            if ($fxres_high->[0] != 200) {
                return [412, "Couldn't get conversion rate (highest sell) ".
                            "from $cur to USD: $fxres_high->[0] - ".
                            "$fxres_high->[1]"];
            }

            my $fxrate_avg = ($fxres_low->[2]{rate} + $fxres_high->[2]{rate})/2;
            $r->{_stash}{forex_rates}{"$cur/USD"} = $fxrate_avg;
        }
    } # GET_FOREX_RATES

  GET_FOREX_SPREADS:
    {
        # when we arbitrage using two different fiat currencies, e.g. BTC/USD
        # and BTC/IDR, we want to take into account the USD/IDR buy-sell spread
        # (the "forex spread") and subtract this from the price difference
        # percentage to be safer.

        $r->{_stash}{forex_spreads} = {};

        my @curs;
        for my $cur (@{ $r->{_stash}{quote_currencies} }) {
            next unless App::cryp::arbit::_is_fiat($cur);
            push @curs, $cur unless grep { $cur eq $_ } @curs;
        }
        last unless @curs;

        require Finance::Currency::FiatX;

        for my $cur1 (@curs) {
            for my $cur2 (@curs) {
                next if $cur1 eq $cur2;

                my $fxres_low = Finance::Currency::FiatX::get_spot_rate(
                    dbh => $dbh, from => $cur1, to => $cur2, type => 'buy', source => ':lowest');
                if ($fxres_low->[0] != 200) {
                    return [412, "Couldn't get conversion rate (lowest buy) for ".
                                "$cur1/$cur2: $fxres_low->[0] - $fxres_low->[1]"];
                }

                my $fxres_high = Finance::Currency::FiatX::get_spot_rate(
                    dbh => $dbh, from => $cur1, to => $cur2, type => 'sell', source => ':highest');
                if ($fxres_high->[0] != 200) {
                    return [412, "Couldn't get conversion rate (highest sell) ".
                                "for $cur1/$cur2: $fxres_high->[0] - ".
                                "$fxres_high->[1]"];
                }

                my $r1 = $fxres_low->[2]{rate};
                my $r2 = $fxres_high->[2]{rate};
                my $spread = $r1 > $r2 ? ($r1-$r2)/$r2*100 : ($r2-$r1)/$r1*100;
                $r->{_stash}{forex_spreads}{"$cur1/$cur2"} = abs $spread;
            }
        }
    } # GET_FOREX_SPREADS

    my %exchanges_for; # key="base currency"/"quote cryptocurrency or ':fiat'", value => [exchange, ...]
    my %fiat_for;      # key=exchange safename, val=[fiat currency, ...]
    my %pairs_for;     # key=exchange safename, val=[pair, ...]
  DETERMINE_SETS:
    for my $exchange (sort keys %{ $r->{_stash}{exchange_clients} }) {
        my $pair_recs = $r->{_stash}{exchange_pairs}{$exchange};
        for my $pair_rec (@$pair_recs) {
            my $pair = $pair_rec->{name};
            my ($basecur, $quotecur) = $pair =~ m!(.+)/(.+)!;
            next unless grep { $_ eq $basecur  } @{ $r->{_stash}{base_currencies}  };
            next unless grep { $_ eq $quotecur } @{ $r->{_stash}{quote_currencies} };

            my $key;
            if (App::cryp::arbit::_is_fiat($quotecur)) {
                $key = "$basecur/:fiat";
                $fiat_for{$exchange} //= [];
                push @{ $fiat_for{$exchange} }, $quotecur
                    unless grep { $_ eq $quotecur } @{ $fiat_for{$exchange} };
            } else {
                $key = "$basecur/$quotecur";
            }
            $exchanges_for{$key} //= [];
            push @{ $exchanges_for{$key} }, $exchange;

            $pairs_for{$exchange} //= [];
            push @{ $pairs_for{$exchange} }, $pair
                unless grep { $_ eq $pair } @{ $pairs_for{$exchange} };
        }
    } # DETERMINE_SETS

  SET:
    for my $set (shuffle keys %exchanges_for) {
        my ($base_currency, $quote_currency0) = $set =~ m!(.+)/(.+)!;

        my %sell_orders; # key = exchange safename
        my %buy_orders ; # key = exchange safename

        # the final merged order book. each entry will be a hashref containing
        # these keys:
        #
        # - currency (the base/target currency to arbitrage)
        #
        # - gross_price_orig (ask/bid price in exchange's original quote
        #   currency)
        #
        # - gross_price (like gross_price_orig, but price will be converted to
        #   USD if quote currency is fiat)
        #
        # - net_price_orig (net price after adding [if sell order, because we'll
        #   be buying these] or subtracting [if buy order, because we'll be
        #   selling these] trading fee from the original ask/bid price. in
        #   exchange's original quote currency)
        #
        # - net_price (like net_price_orig, but price will be converted to USD
        #   if quote currency is fiat)
        #
        # - exchange (exchange safename)

        my @all_buy_orders;
        my @all_sell_orders;

        # produce final merged order book.
      EXCHANGE:
        for my $exchange (sort keys %{ $r->{_stash}{exchange_clients} }) {
            my $eid = App::cryp::arbit::_get_exchange_id($r, $exchange);
            my $clients = $r->{_stash}{exchange_clients}{$exchange};
            my $client = $clients->{ (sort keys %$clients)[0] };

            my @pairs;
            if ($quote_currency0 eq ':fiat') {
                push @pairs, map { "$base_currency/$_" } @{ $fiat_for{$exchange} };
            } else {
                push @pairs, $set;
            }

          PAIR:
            for my $pair (@pairs) {
                my ($basecur, $quotecur) = split m!/!, $pair;
                next unless grep { $_ eq $pair } @{ $pairs_for{$exchange} };

                my $time = time();
                log_debug "Getting orderbook %s on %s ...", $pair, $exchange;
                my $res = $client->get_order_book(pair => $pair);
                unless ($res->[0] == 200) {
                    log_error "Couldn't get orderbook %s on %s: %s, skipping this pair",
                        $pair, $exchange, $res;
                    next PAIR;
                }
                #log_trace "orderbook %s on %s: %s", $pair, $exchange, $res->[2]; # too much info to log

                # sanity checks
                unless (@{ $res->[2]{sell} }) {
                    log_warn "No sell orders for %s on %s, skipping this pair",
                        $pair, $exchange;
                    next PAIR;
                }
                unless (@{ $res->[2]{buy} }) {
                    log_warn "No buy orders for %s on %s, skipping this pair",
                        $pair, $exchange;
                    last PAIR;
                }

                my $buy_fee_pct = App::cryp::arbit::_get_trading_fee(
                    $r, $exchange, $base_currency);
                for (@{ $res->[2]{buy} }) {
                    push @{ $buy_orders{$exchange} }, {
                        quote_currency   => $quotecur,
                        gross_price_orig => $_->[0],
                        net_price_orig   => $_->[0]*(1-$buy_fee_pct/100),
                        base_size        => $_->[1],
                    };
                }

                my $sell_fee_pct = App::cryp::arbit::_get_trading_fee(
                    $r, $exchange, $base_currency);
                for (@{ $res->[2]{sell} }) {
                    push @{ $sell_orders{$exchange} }, {
                        quote_currency   => $quotecur,
                        gross_price_orig => $_->[0],
                        net_price_orig   => $_->[0]*(1+$sell_fee_pct/100),
                        base_size        => $_->[1],
                    };
                }

                if (!App::cryp::arbit::_is_fiat($quotecur) || $quotecur eq 'USD') {
                    for (@{ $buy_orders{$exchange} }, @{ $sell_orders{$exchange} }) {
                        $_->{gross_price} = $_->{gross_price_orig};
                        $_->{net_price}   = $_->{net_price_orig};
                    }
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                             $time, $base_currency, $quotecur, $buy_orders{$exchange}[0]{gross_price_orig}, $eid, "buy");
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                             $time, $base_currency, $quotecur, $sell_orders{$exchange}[0]{gross_price_orig}, $eid, "sell");
                } else {
                    # convert fiat to USD
                    my $fxrate = $r->{_stash}{forex_rates}{"$quotecur/USD"}
                        or die "BUG: Didn't get forex rate for $quotecur/USD?";

                    for (@{ $buy_orders{$exchange} }) {
                        $_->{gross_price} = $_->{gross_price_orig} * $fxrate;
                        $_->{net_price}   = $_->{net_price_orig}   * $fxrate;;
                    }

                    my $fxrate_note = join(
                        " ",
                        sprintf("$quotecur/USD forex rate: %.8f", $fxrate),
                    );

                    for (@{ $sell_orders{$exchange} }) {
                        $_->{gross_price} = $_->{gross_price_orig} * $fxrate;
                        $_->{net_price}   = $_->{net_price_orig}   * $fxrate;
                    }

                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                             $time, $base_currency, $quotecur, $buy_orders{$exchange}[0]{gross_price_orig}, $eid, "buy");
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                         $time, $base_currency, $quotecur, $sell_orders{$exchange}[0]{gross_price_orig}, $eid, "sell");
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type, note) VALUES (?,?,?,?,?,?, ?)", {},
                             $time, $base_currency, "USD", $buy_orders{$exchange}[0]{gross_price}, $eid, "buy",
                             $fxrate_note);
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type, note) VALUES (?,?,?,?,?,?, ?)", {},
                             $time, $base_currency, "USD", $sell_orders{$exchange}[0]{gross_price}, $eid, "sell",
                             $fxrate_note);
                } # convert fiat currency to USD
            } # for pair
        } # for exchange

        # sanity checks
        if (keys(%buy_orders) < 2) {
            log_info "There are less than two exchanges that buy %s, ".
                "skipping this base currency";
            next SET;
        }
        if (keys(%sell_orders) < 2) {
            log_debug "There are less than two exchanges that sell %s, skipping this base currency",
                $base_currency;
            next SET;
        }

        # merge all buys from all exchanges, sort from highest net price
        for my $exchange (keys %buy_orders) {
            for (@{ $buy_orders{$exchange} }) {
                $_->{exchange} = $exchange;
                push @all_buy_orders, $_;
            }
        }
        @all_buy_orders = sort { $b->{net_price} <=> $a->{net_price} }
            @all_buy_orders;

        # merge all sells from all exchanges, sort from lowest price
        for my $exchange (keys %sell_orders) {
            for (@{ $sell_orders{$exchange} }) {
                $_->{exchange} = $exchange;
                push @all_sell_orders, $_;
            }
        }
        @all_sell_orders = sort { $a->{net_price} <=> $b->{net_price} }
            @all_sell_orders;

        #log_trace "all_buy_orders  for %s: %s", $base_currency, \@all_buy_orders;
        #log_trace "all_sell_orders for %s: %s", $base_currency, \@all_sell_orders;

        my $account_balances = $r->{_stash}{account_balances};

        my ($coin_order_pairs, $opportunity) = _calculate_order_pairs_for_base_currency(
            base_currency => $base_currency,
            all_buy_orders => \@all_buy_orders,
            all_sell_orders => \@all_sell_orders,
            min_net_profit_margin => $r->{args}{min_net_profit_margin},
            max_order_quote_size => $r->{args}{max_order_quote_size},
            max_order_size_as_book_item_size_pct => $r->{_cryp}{arbit_strategies}{merge_order_book}{max_order_size_as_book_item_size_pct},
            max_order_pairs      => $r->{args}{max_order_pairs_per_round},
            (account_balances    => $account_balances) x !$r->{args}{ignore_balance},
            min_account_balances => $r->{args}{min_account_balances},
            (exchange_pairs       => $r->{_stash}{exchange_pairs}) x !$r->{args}{ignore_min_order_size},
            forex_spreads        => $r->{_stash}{forex_spreads},
        );
        for (@$coin_order_pairs) {
            $_->{base_currency} = $base_currency;
        }
        push @order_pairs, @$coin_order_pairs;
        if ($opportunity) {
            $dbh->do("INSERT INTO arbit_opportunity
                        (time,base_currency,quote_currency,buy_exchange_id,buy_price,sell_exchange_id,sell_price,gross_profit_margin,trading_profit_margin) VALUES
                        (?   ,?            ,?             ,?              ,?        ,?               ,?         ,?                  ,?                    )", {},
                     $opportunity->{time},
                     $opportunity->{base_currency},
                     $opportunity->{quote_currency},
                     App::cryp::arbit::_get_exchange_id($r, $opportunity->{buy_exchange}),
                     $opportunity->{buy_price},
                     App::cryp::arbit::_get_exchange_id($r, $opportunity->{sell_exchange}),
                     $opportunity->{sell_price},
                     $opportunity->{gross_profit_margin},
                     $opportunity->{trading_profit_margin},
                 );
        }
    } # for set (base currency)

    [200, "OK", \@order_pairs];
}

1;
# ABSTRACT: Using merged order books for arbitration

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::arbit::Strategy::merge_order_book - Using merged order books for arbitration

=head1 VERSION

This document describes version 0.003 of App::cryp::arbit::Strategy::merge_order_book (from Perl distribution App-cryp-arbit), released on 2018-08-04.

=head1 SYNOPSIS

=head2 Using this strategy

In your F<cryp.conf>:

 [program=cryp-arbit arbit]
 strategy=merge-order-book

or in your F<cryp-arbit.conf>:

 [arbit]
 strategy=merge-order-book

This is actually the default strategy, so you don't have to explicitly set
C<strategy> to this strategy.

=head2 Configuration

In your F<cryp.conf>:

 [arbit-strategy/merge-order-book]
 ...

=head1 DESCRIPTION

This arbitration strategy uses information from merged order books. Below is the
description of the algorithm. Suppose we are arbitraging the pair BTC/USD.
I<E1>, I<E2>, ... I<En> are exchanges. I<P*> are prices. I<S*> are sizes. I<i>
denotes exchange index.

B<First step:> get order books from all of the involved exchanges, for example:

 # buy orders on E1            # sell orders on E1
 price  size                   price  size
 -----  ----                   -----  ----
 P1b1   S1b1                   P1s1   S1s1
 P1b2   S1b2                   P1s2   S1s2
 P1b3   S1b3                   P1s3   S1s3
 ...                           ...

 # buy orders on E2            # sell orders on E2
 price  size                   price  size
 -----  ----                   -----  ----
 P2b1   S2b1                   P2s1   S2s1
 P2b2   S2b2                   P2s2   S2s2
 P2b3   S2b3                   P2s3   S2s3
 ...                           ...

 ...

Note that buy orders are sorted from highest to lowest price (I<Pib1> > I<Pib2>
> I<Pib3> > ...) while sell orders are sorted from lowest to highest price
(I<Pis1> < I<Pis2> < I<Pis3> < ...). Also note that I<P1b*> < I<P1s*>, unless
something weird is going on.

B<Second step:> merge all the orders from exchanges into just two lists: buy and
sell orders. Sort buy orders, as usual, from highest to lowest price. Sort sell
orders, as usual, from lowest to highest. For example:

 # buy orders                  # sell orders
 price  size                   price  size
 -----  ----                   -----  ----
 P1b1   S1b1                   P2s1   S2s1
 P2b1   S2b1                   P3s1   S3s1
 P2b2   S2b2                   P3s2   S3s2
 P1b2   S1b2                   P1s1   S1s1
 ...

Arbitrage can happen if we can buy cheap bitcoin and sell our expensive bitcoin.
This means I<P1b1> must be I<above> I<P2s1>, because we want to buy bitcoins on
I<E1> from trader that is willing to sell at I<P2s1> then sell it on I<E1> to
the trader that is willing to buy the bitcoins at I<P2b1>. Pocketing the
difference (minus trading fees) as profit.

No actual bitcoins will be transferred from I<E2> to I<E1> as that would take a
long time and incurs relatively high network fees. Instead, we maintain bitcoin
and USD balances on each exchange to be able to buy/sell quickly. The balances
serve as "working capital" or "inventory".

The minimum net profit margin is I<min_net_profit_margin>. We create buy/sell
order pairs starting from the topmost of the merged order book, until we can't
get I<min_net_profit_margin> anymore.

Then we monitor our order pairs and cancel them if they remain unfilled for a
while.

Then we retrieve order books from the exchanges and start the process again.

=head2 Strengths

Order books contain information about prices and volumes at each price level.
This serves as a guide on what size our orders should be, so we do not have to
explicitly set order size. This is especially useful if we are not familiar with
the typical volume of the pair on an exchange.

By sorting the buy and sell orders, we get maximum price difference.

=for Pod::Coverage ^(.+)$

=head1 Weaknesses

Order books are changing rapidly. By the time we get the order book from the
exchange API, that information is already stale. In the course of milliseconds,
the order book can change, sometimes significantly. So when we submit an order
to buy X BTC at price P, it might not get fulfilled completely or at all because
the market price has moved above P, for example.

=head1 CONFIGURATION

=over

=item * max_order_size_as_book_item_size_pct

Number 0-100. Default is 100. This setting is used for more safety since order
books are rapidly changing. For example, there is an item in the merged order
book as follows:

 type  exchange   price  size     item#
 ----  --------   -----  ----     -----
 buy   exchange1  800.1  12       B1
 buy   exchange1  798.1  24       B2
 ...
 sell  exchange2  780.1   5       S1
 sell  exchange2  782.9   8       S2
 ...

If `max_order_size_as_book_item_size_pct` is set to 100, then this will create
order pairs as follows:

 size  buy from   buy price  sell to    sell price  item#
 ----  --------   ---------  -------    ----------  -----
 5     exchange2  780.1      exchange1  800.1       OP1
 7     exchange2  782.9      exchange1  800.1       OP2
 ...

The OP1 will use up (100%) of item #S1 from the order book, then OP2 will use up
(100%) item #B1 from the order book.

However, if `max_order_size_as_book_item_size_pct` is set to 75, then this will
create order pairs as follows:

 size  buy from   buy price  sell to    sell price  item#
 ----  --------   ---------  -------    ----------  -----
 3.75  exchange2  780.1      exchange1  800.1       OP1
 5.25  exchange2  782.9      exchange1  800.1       OP2

OP1 will use 75% item S1 from the order book, then the strategy will move on to
the next sell order (S2). OP2 will also use only 75% of item B1 (3.75 + 5.25 =
9, which is 75% of 12) before moving on to the next buy order.

=back

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=head1 SEE ALSO

L<App::cryp::arbit>

Other C<App::cryp::arbit::Strategy::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
