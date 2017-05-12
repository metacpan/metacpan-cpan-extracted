use strict;
use warnings;
use AnyEvent::Hiredis;
use AnyEvent::Redis;
use Benchmark qw/cmpthese/;
use feature 'say';

sub ae_hiredis_1000 {
    my $key   = 'OHHAI';
    my $value = 'lolcat';
    my $i     = 1000;
    my $ii    = $i;
    my $done  = AE::cv;
    my $redis = AnyEvent::Hiredis->new;

    my $set; $set = sub {
        $i--;
        $redis->command(['SET', $key.$i => $value], $i < 0 ? $done : $set);
    };
    $set->() for 1..100;

    $done->recv;
}

sub ae_redis_1000 {
    my $key   = 'OHHAI';
    my $value = 'lolcat';
    my $i     = 1000;
    my $ii    = $i;
    my $done  = AE::cv;
    my $redis = AnyEvent::Redis->new;

    my $set; $set = sub {
        $i--;
        $redis->set($key.$i => $value, $i < 0 ? $done : $set);
    };
    $set->() for 1..100;

    $done->recv;
}

cmpthese(-5,  {
    'ae_redis_1000'   => \&ae_redis_1000,
    'ae_hiredis_1000' => \&ae_hiredis_1000,
});
