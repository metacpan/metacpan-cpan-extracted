use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Coro;
use Coro::AnyEvent;
use Benchmark qw(:hireswallclock);

my ($delay, $count) = @ARGV;
$delay //= 0;
$count //= 20000;
sub plus2($) {
    my $v = shift;
    my $cv = AE::cv;
    my $t; $t = AE::timer $delay, 0, sub {
        $cv->($v + 2);
        undef $t;
    };
    return $cv;
}

sub mult2($) {
    my $v = shift;
    my $cv = AE::cv;
    my $t; $t = AE::timer $delay, 0, sub {
        $cv->($v * 2);
        undef $t;
    };
    return $cv;
}

sub bare_ae() {
    my $done = AE::cv;
    plus2(1)->cb(sub {
        my $v = eval { $_[0]->recv };
        $@ and $done->croak($@);
        mult2($v)->cb(sub {
            my $v = eval { $_[0]->recv };
            $@ and $done->croak($@);
            $done->send($v);
        });
    });
    $done->recv;
}

sub monad() {
    plus2(1)->flat_map(\&mult2)->recv;
}

sub coro() {
    async {
        mult2(plus2(1)->recv)->recv;
    }->join;
}

my $r = Benchmark::timethese($count => {
    bare_ae => \&bare_ae,
    monad   => \&monad,
    coro    => \&coro,
});
for my $v (values %$r) {
    $v->[1] = $v->[3] = $v->[0];
    $v->[2] = $v->[4] = 0;
}
Benchmark::cmpthese($r);

__END__

% perl -Ilib eg/bench_cv_light.pl 0 20000
Benchmark: timing 20000 iterations of bare_ae, coro, monad...
   bare_ae: 1.05725 wallclock secs ( 0.98 usr +  0.07 sys =  1.05 CPU) @ 19047.62/s (n=20000)
      coro: 1.02733 wallclock secs ( 0.95 usr +  0.08 sys =  1.03 CPU) @ 19417.48/s (n=20000)
     monad: 1.10444 wallclock secs ( 1.03 usr +  0.07 sys =  1.10 CPU) @ 18181.82/s (n=20000)
          Rate   monad bare_ae    coro
monad   9054/s      --     -4%     -7%
bare_ae 9458/s      4%      --     -3%
coro    9734/s      8%      3%      --
