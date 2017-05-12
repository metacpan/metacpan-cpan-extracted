use strict;
use warnings;
use Test::More;
use Cache::KyotoTycoon;
use t::Util;
use Data::Dumper;

test_kt(
    sub {
        my $port = shift;
        my $kt = Cache::KyotoTycoon->new(port => $port);
        my $cursor = $kt->make_cursor(1);
        is $cursor->jump(), 0;
        $kt->set_bulk({a => 1, b => 2, c => 3});
        $kt->set(d => 4, 24*60*60);
        is $cursor->jump('b'), 1;
        {
            is $cursor->get_key(),   'b';
            is $cursor->get_value(), '2';
            $cursor->set_value("OK");
            is $cursor->get_value(), 'OK';
            my ($k, $v, $xt) = $cursor->get(1);
            is $k, 'b';
            is $v, 'OK';
            is $xt, undef;
        }
        {
            my ($k, $v) = $cursor->get();
            isnt $k, 'b';
        }
        my $k = $cursor->get_key();
        ok $kt->get($k);
        is $cursor->remove(), 1;
        is $kt->get($k), undef;

        subtest 'xt' => sub {
            ok $cursor->jump('d');
            my ($key, $val, $xt) = $cursor->get();
            is $key, 'd';
            is $val, 4;
            cmp_ok abs($xt-(24*60*60+time())), '<', 10, 'xt';
        };

        $cursor->delete;
        done_testing;
    },
);

