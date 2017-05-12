#!/usr/bin/env perl
use Test::More;

use App::RoboBot::Test::Mock;

plan tests => 5;
use_ok('App::RoboBot::Plugin::Types::Vector');

my ($bot, $net, $chn, $msg, $plg);
my $rpl = {};

SKIP: {
    skip App::RoboBot::Test::Mock::envset_message(), 1 unless $ENV{'R_DBTEST'};

    ($bot, $net, $chn, $msg) = mock_all("foo");
    $plg = (grep { $_->name eq 'Types::Vector' } @{$bot->plugins})[0];

    is(ref($plg), 'App::RoboBot::Plugin::Types::Vector', 'plugin class correct');
}

my @ret = App::RoboBot::Plugin::Types::Vector::vec_vec(
    $plg, $msg, 'vec', $rpl, qw( a b c )
);

is(scalar(@ret), 1, 'single return value');
is(ref($ret[0]), 'ARRAY', 'vector as arrayref');
is_deeply($ret[0], ["a", "b", "c"], 'elements in expected order');
