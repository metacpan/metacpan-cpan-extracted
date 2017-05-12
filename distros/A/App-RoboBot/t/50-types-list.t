#!/usr/bin/env perl
use Test::More;

use App::RoboBot::Test::Mock;

plan tests => 32;
use_ok('App::RoboBot::Plugin::Types::List');

my ($bot, $net, $chn, $msg, $plg);
my $rpl = {};

SKIP: {
    skip App::RoboBot::Test::Mock::envset_message(), 1 unless $ENV{'R_DBTEST'};

    ($bot, $net, $chn, $msg) = mock_all("foo");
    $plg = (grep { $_->name eq 'Types::List' } @{$bot->plugins})[0];

    is(ref($plg), 'App::RoboBot::Plugin::Types::List', 'plugin class correct');
}

my @ret = App::RoboBot::Plugin::Types::List::list_nth(
    $plg, $msg, 'nth', $rpl, 3, qw( James Alice Frank Janet )
);

is(scalar(@ret), 1,     'positive nth single return value');
ok(!ref($ret[0]),       'positive nth bare string return');
is($ret[0], 'Frank',    'positive nth string matches');

@ret = App::RoboBot::Plugin::Types::List::list_nth(
    $plg, $msg, 'nth', $rpl, -3, qw( James Alice Frank Janet )
);

is(scalar(@ret), 1,     'negative nth single return value');
ok(!ref($ret[0]),       'negative nth bare string return');
is($ret[0], 'Alice',    'negative nth string matches');

SKIP: {
    skip App::RoboBot::Test::Mock::envset_message(), 5 unless $ENV{'R_DBTEST'};

    # Need to skip these without the DB setup because of the raised error side
    # effect that depends on a mocked-up message object
    @ret = App::RoboBot::Plugin::Types::List::list_nth(
        $plg, $msg, 'nth', $rpl, 10, qw( James Alice Frank Janet )
    );

    is(scalar(@ret), 0,   'out-of-bounds nth no return value');

    @ret = App::RoboBot::Plugin::Types::List::list_nth(
        $plg, $msg, 'nth', $rpl, -10, qw( James Alice Frank Janet )
    );

    is(scalar(@ret), 0,   'out-of-bounds negative nth no return value');

    # Need to skip this without DB, because it uses list_nth underneath.
    @ret = App::RoboBot::Plugin::Types::List::list_first(
        $plg, $msg, 'first', $rpl, qw( James Alice Frank Janet )
    );

    is(scalar(@ret), 1,     'first single return value');
    ok(!ref($ret[0]),       'first bare string return');
    is($ret[0], 'James',    'first string matches');
}

# We can't really test the randomness here, but we'll at least make sure we get
# back the structure we expect and don't lose any of the input values.
@ret = App::RoboBot::Plugin::Types::List::list_shuffle(
    $plg, $msg, 'shuffle', $rpl, qw( James Alice Frank Janet )
);

is(scalar(@ret), 4,                                             'shuffle return value count same as input');
is(scalar(grep { ref($_) } @ret), 0,                            'shuffle return only bare strings');
is_deeply([sort @ret], [sort qw( Alice Frank James Janet )],    'shuffle returns expected elements');

@ret = App::RoboBot::Plugin::Types::List::list_sort(
    $plg, $msg, 'sort', $rpl, qw( James Alice Frank Janet )
);

is(scalar(@ret), 4,                                 'sort return value count same as input');
is(scalar(grep { ref($_) } @ret), 0,                'sort return only bare strings');
is_deeply(\@ret, [qw( Alice Frank James Janet )],   'sort returns expected list order');

@ret = App::RoboBot::Plugin::Types::List::list_seq(
    $plg, $msg, 'seq', $rpl, 1, 10
);

is(scalar(@ret), 10,                            'seq return value count correct');
is(scalar(grep { $_ !~ m{^\d+$} } @ret), 0,     'seq return only bare numbers');
is_deeply(\@ret, [1,2,3,4,5,6,7,8,9,10],        'seq returns expected numbers in order');

@ret = App::RoboBot::Plugin::Types::List::list_seq(
    $plg, $msg, 'seq', $rpl, 1, 10, 2
);

is(scalar(@ret), 5,                             'step-seq return value count correct');
is(scalar(grep { $_ !~ m{^\d+$} } @ret), 0,     'step-seq return only bare numbers');
is_deeply(\@ret, [1,3,5,7,9],                   'step-seq returns expected numbers in order');

@ret = App::RoboBot::Plugin::Types::List::list_any(
    $plg, $msg, 'any', $rpl, 'foo', 'foo', 'bar', 'baz'
);

is(scalar(@ret), 1,     'matching any return value count correct');
ok($ret[0] == 1,        'matching any returned 1');

@ret = App::RoboBot::Plugin::Types::List::list_any(
    $plg, $msg, 'any', $rpl, 'xyzzy', 'foo', 'bar', 'baz'
);

is(scalar(@ret), 0,     'non-matching any return value count correct');

@ret = App::RoboBot::Plugin::Types::List::list_count(
    $plg, $msg, 'count', $rpl, 'foo', 'bar', 'baz'
);

is(scalar(@ret), 1,     'count return value count correct');
ok($ret[0] == 3,        'count returned correct number');

@ret = App::RoboBot::Plugin::Types::List::list_count(
    $plg, $msg, 'count', $rpl
);

is(scalar(@ret), 1,     'empty-count return value count correct');
ok($ret[0] == 0,        'empty-count returned correct number');


