#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/App/cryp/Cmd/Exchange/accounts.pm','lib/App/cryp/Cmd/Exchange/balance.pm','lib/App/cryp/Cmd/Exchange/cancel_order.pm','lib/App/cryp/Cmd/Exchange/create_limit_order.pm','lib/App/cryp/Cmd/Exchange/exchanges.pm','lib/App/cryp/Cmd/Exchange/get_order.pm','lib/App/cryp/Cmd/Exchange/open_orders.pm','lib/App/cryp/Cmd/Exchange/orderbook.pm','lib/App/cryp/Cmd/Exchange/pairs.pm','lib/App/cryp/Cmd/Exchange/ticker.pm','lib/App/cryp/Exchange/coinbase_pro.pm','lib/App/cryp/Exchange/indodax.pm','lib/App/cryp/Role/Exchange.pm','lib/App/cryp/exchange.pm','script/cryp-exchange'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
