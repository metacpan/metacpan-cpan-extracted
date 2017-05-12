use strict;
use warnings;
use AnyEvent::Hiredis;
use feature 'say';

my $key   = 'OHHAI';
my $value = 'lolcat';
my $i     = 300_000;
my $ii    = $i;
my $done  = AE::cv;
my $redis = AnyEvent::Hiredis->new;

my $set; $set = sub {
    $i--;
    $redis->command(['SET', $key.$i, $value], $i < 0 ? $done : $set);
};
$set->() for 1..100;

my $timer = AnyEvent->timer( after => 3, interval => 3, cb => sub {
    say "$i items remaining";
});

my $start = AnyEvent->now;
$done->recv;
my $end = AnyEvent->now;

say "It took ". ($end - $start). " seconds";
say " that is ". ($ii/($end - $start)). " per second";
