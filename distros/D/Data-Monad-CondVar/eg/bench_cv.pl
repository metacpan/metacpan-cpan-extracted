use strict;
use warnings;
use Data::Monad::CondVar;
use Data::Monad::Base::Sugar;
use AnyEvent;
use Coro;
use Coro::AnyEvent;
use Benchmark qw(:hireswallclock);

my ($delay, $count) = @ARGV;
$delay //= 0;
$count //= 20000;
sub cv($) {
    my $v = shift;
    my $cv = AE::cv;
    my $t; $t = AE::timer $delay, 0, sub {
        $cv->($v);
        undef $t;
    };
    return $cv;
}

sub bare_ae($$) {
    my ($cv1, $cv2) = @_;
    my $cv = AE::cv;
    $cv1->cb(sub {
        my $x = eval {$_[0]->recv};
        $@ and $cv->croak($@);
        $cv2->cb(sub {
            my $y = eval {$_[0]->recv};
            $@ and $cv->croak($@);
            $cv->send($x * $y);
        });
    });
    $cv->recv;
}

sub monad($$) {
    my ($cv1, $cv2) = @_;
    $cv1->flat_map(sub {
        my $x = shift;
        $cv2->map(sub {
            my $y = shift;
            $x * $y;
        });
    })->recv;
}

sub monad_lift($$) {
    my ($cv1, $cv2) = @_;
    cv_lift(sub {$_[0] * $_[1]})->($cv1, $cv2)->recv;
}

sub monad_for($$) {
    my ($cv1, $cv2) = @_;
    Data::Monad::Base::Sugar::for {
        pick \my $x => sub { $cv1 };
        pick \my $y => sub { $cv2 };
        yield {$x * $y};
    }->recv;
}

sub coro($$) {
    my ($cv1, $cv2) = @_;
    async {
        my $x = $cv1->recv;
        my $y = $cv2->recv;
        $x * $y;
    }->join;
}

my $r = Benchmark::timethese($count => {
    bare_ae   => sub { bare_ae(cv 5, cv 4)   },
    monad_for => sub { monad_for(cv 5, cv 4) },
    monad     => sub { monad(cv 5, cv 4)     },
    monad_lift=> sub { monad_lift(cv 5, cv 4)},
    coro      => sub { coro(cv 5, cv 4)      },
});
for my $v (values %$r) {
    $v->[1] = $v->[3] = $v->[0];
    $v->[2] = $v->[4] = 0;
}
Benchmark::cmpthese($r);

__END__

% perl -Ilib eg/bench_cv.pl .0001 10000
Benchmark: timing 10000 iterations of bare_ae, coro, monad, monad_for, monad_lift...
   bare_ae: 1.16068 wallclock secs ( 0.72 usr +  0.06 sys =  0.78 CPU) @ 12820.51/s (n=10000)
      coro: 1.16513 wallclock secs ( 0.72 usr +  0.06 sys =  0.78 CPU) @ 12820.51/s (n=10000)
     monad: 1.10253 wallclock secs ( 0.87 usr +  0.05 sys =  0.92 CPU) @ 10869.57/s (n=10000)
 monad_for: 1.21874 wallclock secs ( 1.18 usr +  0.03 sys =  1.21 CPU) @ 8264.46/s (n=10000)
monad_lift: 1.33561 wallclock secs ( 1.30 usr +  0.03 sys =  1.33 CPU) @ 7518.80/s (n=10000)
             Rate monad_lift  monad_for       coro    bare_ae      monad
monad_lift 3744/s         --        -9%       -13%       -13%       -17%
monad_for  4103/s        10%         --        -4%        -5%       -10%
coro       4291/s        15%         5%         --        -0%        -5%
bare_ae    4308/s        15%         5%         0%         --        -5%
monad      4535/s        21%        11%         6%         5%         --

% perl -Ilib eg/bench_cv.pl 0 20000
Benchmark: timing 20000 iterations of bare_ae, coro, monad, monad_for, monad_lift...
   bare_ae: 0.991276 wallclock secs ( 0.94 usr +  0.04 sys =  0.98 CPU) @ 20408.16/s (n=20000)
      coro: 1.01837 wallclock secs ( 0.97 usr +  0.05 sys =  1.02 CPU) @ 19607.84/s (n=20000)
     monad: 1.7295 wallclock secs ( 1.68 usr +  0.04 sys =  1.72 CPU) @ 11627.91/s (n=20000)
 monad_for: 2.51117 wallclock secs ( 2.44 usr +  0.06 sys =  2.50 CPU) @ 8000.00/s (n=20000)
monad_lift: 2.69432 wallclock secs ( 2.63 usr +  0.07 sys =  2.70 CPU) @ 7407.41/s (n=20000)
              Rate monad_lift  monad_for      monad       coro    bare_ae
monad_lift  3712/s         --        -7%       -36%       -62%       -63%
monad_for   3982/s         7%         --       -31%       -59%       -61%
monad       5782/s        56%        45%         --       -41%       -43%
coro        9820/s       165%       147%        70%         --        -3%
bare_ae    10088/s       172%       153%        74%         3%         --
