#!perl

use 5.010001;
use strict;
use warnings;
use Test::Deeply::Float;
use Test::More 0.98;

use App::cryp::arbit::Strategy::merge_order_book;

subtest 'opt:min_net_profit_margin' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.8,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.6,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.6,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 1.6,
        forex_spreads => {"USD/IDR" => 0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'opt:forex_spreads' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.8,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.6,
            forex_spread => 0.5,
            net_profit_margin => 1.12634681845904,
            net_profit => 1.1081,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 1.1,
        forex_spreads => {"USD/IDR" => 0.5},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'opt:max_order_pairs' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.8,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.6,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.6,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        max_order_pairs   => 1,
        forex_spreads => {"USD/IDR" => 0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'buy & sell size match' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.1,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.1,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 0.9,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 0.8,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 0.8,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        forex_spreads => {"USD/IDR"=>0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'buy size > sell size' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.8,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.6,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.6,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.8,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 5.68000000000002,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 4.71999999999998,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 4.71999999999998,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        forex_spreads => {"USD/IDR"=>0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'buy size < sell size' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.8,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.6,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.6,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.8,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.81225819588678,
            gross_profit => 7.11999999999998,
            trading_profit_margin => 1.60601748322831,
            trading_profit => 6.32000000000003,
            net_profit_margin => 1.60601748322831,
            net_profit => 6.32000000000003,
            forex_spread => 0,
            sell => {
                exchange => "indodax",
                gross_price => 500,
                gross_price_orig => 5000000,
                net_price => 499.8,
                net_price_orig => 4998000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        forex_spreads => {"USD/IDR"=>0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'selling account balance (1)' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>0.15}],
        },
        'coinbase-pro' => {
            USD => [{account=>'g1', available=>9999}],
        },
    };

    my $correct_order_pairs = [
        {
            base_size => 0.15,
            buy => {
                account => "g1",
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.35,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.2,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.2,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_net_profit_margin    => 0,
        forex_spreads => {"USD/IDR"=>0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'selling account balance (2)' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>0.15}, {account=>'i2', available=>0.03}],
        },
        'coinbase-pro' => {
            USD => [{account=>'g1', available=>9999}],
        },
    };

    my $correct_order_pairs = [
        {
            base_size => 0.15,
            buy => {
                account => "g1",
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.35,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.2,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.2,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.03,
            buy => {
                account => "g1",
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 0.27,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 0.24,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 0.24,
            sell => {
                account => "i2",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_net_profit_margin    => 0,
        forex_spreads => {"USD/IDR"=>0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'selling account balance (3: re-sorting)' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>0.21}, {account=>'i2', available=>0.03}],
        },
        'coinbase-pro' => {
            USD => [{account=>'g1', available=>9999}],
        },
    };

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                account => "g1",
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.8,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.6,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.6,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $correct_final_account_balances = {
        'coinbase-pro' => { USD => [{ account => "g1", available => 9900.78 }] },
        indodax => {
            ETH => [
                { account => "i2", available => 0.03 },
                { account => "i1", available => 0.00999999999999998 },
            ],
        },
    };

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_net_profit_margin    => 0,
        max_order_pairs   => 1,
        forex_spreads => {"USD/IDR"=>0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;

    is_deeply_float($account_balances, $correct_final_account_balances)
        or diag explain $account_balances;
};

subtest 'buying account balance (1)' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>9999}],
        },
        'coinbase-pro' => {
            USD => [{account=>'g1', available=>50}, {account=>'g2', available=>40}],
        },
    };

    my $correct_order_pairs = [
        {
            base_size => 0.101812258195887,
            buy => {
                account => "g1",
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 0.916310323762981,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 0.814498065567094,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 0.814498065567094,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.0814498065567094,
            buy => {
                account => "g2",
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 0.733048259010385,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 0.651598452453675,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 0.651598452453675,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $correct_final_account_balances = {
        'coinbase-pro' => { USD => [] },
        indodax => { ETH => [{ account => "i1", available => 9998.81673793525 }] },
    };

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_net_profit_margin    => 0,
        forex_spreads => {"USD/IDR"=>0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;

    is_deeply_float($account_balances, $correct_final_account_balances)
        or diag explain $account_balances;
};

subtest 'opt:max_order_quote_size' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.17996400719856,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.61967606478704,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.43971205758848,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.43971205758848,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.0200359928014397,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 0.180323935212958,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 0.160287942411518,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 0.160287942411518,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        }, #[1]
        {
            base_size => 0.17996400719856,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 1.27774445110978,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 1.0617876424715,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 1.0617876424715,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        }, #[2]
        {
            base_size => 0.17996400719856,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 1.27774445110978,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 1.0617876424715,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 1.0617876424715,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        }, #[3]
        {
            base_size => 0.17996400719856,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 1.27774445110978,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 1.0617876424715,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 1.0617876424715,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        }, #[4]
        {
            base_size => 0.17996400719856,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 1.27774445110978,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 1.0617876424715,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 1.0617876424715,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        }, #[5]
        {
            base_size => 0.0801439712057587,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 0.569022195560889,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 0.472849430113975,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 0.472849430113974,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        }, #[6]
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        max_order_quote_size => 90,
        forex_spreads => {"USD/IDR"=>0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'opt:max_order_size_as_book_item_size_pct' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1, # *80% = 0.08
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2, # *80% = 0.16
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9, # *80% = 0.72
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.16,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.44,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.28,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.28,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.64,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 4.54400000000001,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 3.77599999999999,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 3.77599999999999,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        max_order_size_as_book_item_size_pct => 80,
        forex_spreads => {"USD/IDR"=>0},
    );

    #use DD; dd $order_pairs;

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'opt:min_account_balance' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>0.15}, {account=>'i2', available=>1}, ],
        },
        'coinbase-pro' => {
            USD => [{account=>'g1', available=>9999}],
        },
    };

    my $min_account_balances = {
        "indodax/i1" => {ETH => 0.02},
        "indodax/i2" => {ETH => 0.98},
    };

    my $correct_order_pairs = [
        {
            base_size => 0.13,
            buy => {
                account => "g1",
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 1.17,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 1.04,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 1.04,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.02,
            buy => {
                account => "g1",
                exchange => "coinbase-pro",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.83262064752596,
            gross_profit => 0.18,
            trading_profit_margin => 1.62634681845904,
            trading_profit => 0.16,
            forex_spread => 0,
            net_profit_margin => 1.62634681845904,
            net_profit => 0.16,
            sell => {
                account => "i2",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $correct_final_account_balances = {
        'coinbase-pro' => { USD => [{account=>'g1', available=>9925.335}] },
        indodax => { ETH => [] },
    };

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_account_balances => $min_account_balances,
        min_net_profit_margin    => 0,
        forex_spreads => {"USD/IDR"=>0},
    );

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;

    is_deeply_float($account_balances, $correct_final_account_balances)
        or diag explain $account_balances;
};

subtest "minimum buy base size" => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.8,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 5.68000000000002,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 4.71999999999998,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 4.71999999999998,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        exchange_pairs    => {
            'coinbase-pro' => [{base_currency=>"ETH", min_base_size=>0.5}],
        },
        forex_spreads => {"USD/IDR"=>0},
    );

    #use DD; dd $order_pairs;

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest "minimum buy quote size" => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.8,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 5.68000000000002,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 4.71999999999998,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 4.71999999999998,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        exchange_pairs    => {
            'coinbase-pro' => [{base_currency=>"ETH", min_quote_size=>200}],
        },
        forex_spreads => {"USD/IDR"=>0},
    );

    #use DD; dd $order_pairs;

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest "minimum sell base size" => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.8,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.44016227180528,
            gross_profit => 5.68000000000002,
            trading_profit_margin => 1.19433198380566,
            trading_profit => 4.71999999999998,
            forex_spread => 0,
            net_profit_margin => 1.19433198380566,
            net_profit => 4.71999999999998,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        exchange_pairs    => {
            indodax => [{base_currency=>"ETH", min_base_size=>0.5}],
        },
        forex_spreads => {"USD/IDR"=>0},
    );

    #use DD; dd $order_pairs;

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

L1:
subtest "minimum sell quote size" => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 1.5,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.7,
            net_price_orig   => 4997_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "coinbase-pro",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "coinbase-pro",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.9,
            buy => {
                exchange => "coinbase-pro",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            gross_profit_margin => 1.41987829614604,
            gross_profit => 6.3,
            trading_profit_margin => 1.15384615384615,
            trading_profit => 5.12999999999999,
            forex_spread => 0,
            net_profit_margin => 1.15384615384615,
            net_profit => 5.12999999999999,
            sell => {
                exchange => "indodax",
                gross_price => 500,
                gross_price_orig => 5000000,
                net_price => 499.7,
                net_price_orig => 4997000,
                pair => "ETH/IDR",
            },
        },
    ];

    my ($order_pairs, $opp) = App::cryp::arbit::Strategy::merge_order_book::_calculate_order_pairs_for_base_currency(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_net_profit_margin    => 0,
        exchange_pairs    => {
            indodax => [{base_currency=>"ETH", min_quote_size=>1_000_000}],
        },
        forex_spreads => {"USD/IDR"=>0},
    );

    #use DD; dd $order_pairs;

    is_deeply_float($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

DONE_TESTING:
done_testing;
