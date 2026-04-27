use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis qw(run);
use Test2::V0;
use Async::Redis;

subtest 'failed WATCH leaves local state clean' => sub {
    my $redis = Async::Redis->new;

    my $error = dies {
        run { $redis->watch('unit:watch') };
    };

    like("$error", qr/Not connected/, 'WATCH fails on disconnected client');
    ok(!$redis->watching, 'watching flag not set after failed WATCH');
    ok(!$redis->is_dirty, 'connection not marked dirty after failed WATCH');
};

subtest 'failed MULTI leaves local state clean' => sub {
    my $redis = Async::Redis->new;

    my $error = dies {
        run { $redis->multi_start };
    };

    like("$error", qr/Not connected/, 'MULTI fails on disconnected client');
    ok(!$redis->in_multi, 'in_multi flag not set after failed MULTI');
    ok(!$redis->is_dirty, 'connection not marked dirty after failed MULTI');
};

done_testing;
