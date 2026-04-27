use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Async::Redis::Pool;
use Async::Redis;

plan skip_all => 'REDIS_HOST not set' unless $ENV{REDIS_HOST};

sub new_pool {
    Async::Redis::Pool->new(
        host => $ENV{REDIS_HOST},
        port => $ENV{REDIS_PORT} // 6379,
        max  => 4,
    );
}

subtest 'release(undef) is a silent no-op' => sub {
    my $p = new_pool();
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $p->release(undef);
    is scalar @warnings, 0, 'no warn';
};

subtest 'double release warns and does not double-pool' => sub {
    (async sub {
        my $p = new_pool();
        my $c = await $p->acquire;
        $p->release($c);

        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $p->release($c);
        like join('', @warnings), qr/unknown|already.released/i,
            'warned about double release';
        is scalar @{$p->{_idle}}, 1, 'connection in idle list exactly once';
        $p->shutdown;
    })->()->get;
};

subtest 'shutdown fails pending acquires and rejects future acquires' => sub {
    (async sub {
        my $p = new_pool();
        $p->shutdown;
        my $ok = eval { await $p->acquire; 1 };
        ok !$ok, 'acquire after shutdown fails';
    })->()->get;
};

subtest 'release after shutdown destroys instead of pooling' => sub {
    (async sub {
        my $p = new_pool();
        my $c = await $p->acquire;
        $p->shutdown;
        $p->release($c);
        is scalar @{$p->{_idle}}, 0, 'not returned to idle';
    })->()->get;
};

done_testing;
