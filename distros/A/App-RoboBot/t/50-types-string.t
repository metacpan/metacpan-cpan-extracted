#!/usr/bin/env perl
use Test::More;

use App::RoboBot::Test::Mock;

plan tests => 20;
use_ok('App::RoboBot::Plugin::Types::String');

my ($bot, $net, $chn, $msg, $plg);
my $rpl = {};

SKIP: {
    skip App::RoboBot::Test::Mock::envset_message(), 1 unless $ENV{'R_DBTEST'};

    ($bot, $net, $chn, $msg) = mock_all("foo");
    $plg = (grep { $_->name eq 'Types::String' } @{$bot->plugins})[0];

    is(ref($plg), 'App::RoboBot::Plugin::Types::String', 'plugin class correct');
}

my @ret = App::RoboBot::Plugin::Types::String::str_substring(
    $plg, $msg, 'substring', $rpl, 'the quick brown fox', 16
);

ok(scalar(@ret) == 1,   'substring unanchored single return value');
ok(!ref($ret[0]),       'substring unanchored bare string return');
ok($ret[0] eq 'fox',    'substring unanchored substring matches');

@ret = App::RoboBot::Plugin::Types::String::str_substring(
    $plg, $msg, 'substring', $rpl, 'the quick brown fox', 16, 2
);

ok(scalar(@ret) == 1,   'substring anchored single return value');
ok(!ref($ret[0]),       'substring anchored bare string return');
ok($ret[0] eq 'fo',     'substring anchored substring matches');

@ret = App::RoboBot::Plugin::Types::String::str_substring(
    $plg, $msg, 'substring', $rpl, 'the quick brown fox', -9, 5
);

ok(scalar(@ret) == 1,   'negative substring anchored single return value');
ok(!ref($ret[0]),       'negative substring anchored bare string return');
ok($ret[0] eq 'brown',  'negative substring anchored substring matches');

@ret = App::RoboBot::Plugin::Types::String::str_index(
    $plg, $msg, 'index', $rpl, 'the quick brown fox', 'fox'
);

ok(scalar(@ret) == 1,           'index single return value');
ok(ref($ret[0]) eq 'ARRAY',     'index vector return');
ok(scalar(@{$ret[0]}) == 1,     'index vector correct size');
ok($ret[0][0] == 16,            'index position correct');

@ret = App::RoboBot::Plugin::Types::String::str_index(
    $plg, $msg, 'index', $rpl, 'the quick brown fox', 'o'
);

ok(scalar(@{$ret[0]}) == 2,                 'multimatch index vector correct size');
ok($ret[0][0] == 12 && $ret[0][1] == 17,    'multimatch index positions correct');

SKIP: {
    skip App::RoboBot::Test::Mock::envset_message(), 3 unless $ENV{'R_DBTEST'};

    @ret = App::RoboBot::Plugin::Types::String::str_index_n(
        $plg, $msg, 'index-n', $rpl, 'the quick brown fox', 'o', 2
    );

    is(scalar(@ret), 1,     'multimatching index-n single return value');
    ok(!ref($ret[0]),       'multimatching index-n bare number return');
    is($ret[0], 17,         'multimatching index-n position correct');
}

