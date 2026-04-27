use strict;
use warnings;
use Test2::V0;
use Time::HiRes qw(time);
use Async::Redis;

my $c = Async::Redis->new(
    host => 'x', port => 1,
    request_timeout         => 30,
    blocking_timeout_buffer => 2,
);

sub approx_eq {
    my ($got, $expected, $slop, $label) = @_;
    $slop //= 0.5;
    return if !defined $got && !defined $expected;
    ok defined($got) && abs($got - $expected) < $slop, "$label ($got vs $expected)";
}

subtest 'BLPOP timeout is last arg' => sub {
    my $d = $c->_calculate_deadline('BLPOP', 'mykey', 5);
    approx_eq($d, time() + 5 + 2, undef, 'BLPOP 5 deadline');
};

subtest 'BLPOP 0 means indefinite' => sub {
    my $d = $c->_calculate_deadline('BLPOP', 'mykey', 0);
    is $d, undef, 'no client-side deadline';
};

subtest 'BLMPOP timeout is position 0' => sub {
    my $d = $c->_calculate_deadline('BLMPOP', 2, 2, 'a', 'b', 'LEFT');
    approx_eq($d, time() + 2 + 2, undef, 'BLMPOP 2 deadline (timeout from pos 0)');
};

subtest 'BZMPOP timeout is position 0' => sub {
    my $d = $c->_calculate_deadline('BZMPOP', 5, 1, 'zset', 'MIN', 'COUNT', 3);
    approx_eq($d, time() + 5 + 2, undef, 'BZMPOP 5 deadline');
};

subtest 'BZMPOP 0 means indefinite' => sub {
    my $d = $c->_calculate_deadline('BZMPOP', 0, 1, 'zset', 'MIN');
    is $d, undef, 'no client-side deadline';
};

subtest 'XREAD BLOCK timeout in ms' => sub {
    my $d = $c->_calculate_deadline('XREAD', 'BLOCK', 5000, 'STREAMS', 's', '$');
    approx_eq($d, time() + 5 + 2, undef, 'XREAD BLOCK 5000ms');
};

subtest 'XREAD BLOCK 0 means indefinite' => sub {
    my $d = $c->_calculate_deadline('XREAD', 'BLOCK', 0, 'STREAMS', 's', '$');
    is $d, undef, 'no client-side deadline';
};

subtest 'XREAD without BLOCK uses request_timeout' => sub {
    my $d = $c->_calculate_deadline('XREAD', 'STREAMS', 's', '$');
    approx_eq($d, time() + 30, undef, 'request_timeout fallback');
};

subtest 'WAIT timeout in ms, last arg' => sub {
    my $d = $c->_calculate_deadline('WAIT', 0, 5000);
    approx_eq($d, time() + 5 + 2, undef, 'WAIT 5000ms');
};

subtest 'WAITAOF timeout in ms, last arg' => sub {
    my $d = $c->_calculate_deadline('WAITAOF', 0, 0, 3000);
    approx_eq($d, time() + 3 + 2, undef, 'WAITAOF 3000ms');
};

subtest 'non-blocking GET uses request_timeout' => sub {
    my $d = $c->_calculate_deadline('GET', 'k');
    approx_eq($d, time() + 30, undef, 'normal request_timeout');
};

subtest 'non-numeric timeout falls back with warn' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $d = $c->_calculate_deadline('BLPOP', 'key', 'notanumber');
    approx_eq($d, time() + 30, undef, 'falls back to request_timeout');
    like join('', @warnings), qr/BLPOP/i, 'warned about bad timeout';
};

done_testing;
