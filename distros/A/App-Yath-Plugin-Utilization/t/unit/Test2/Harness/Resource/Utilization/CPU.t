use Test2::V0;

BEGIN {
    skip_all "Linux only" unless $^O eq 'linux';
}

use Test2::Harness::Resource::Utilization::CPU;

my $CLASS = 'Test2::Harness::Resource::Utilization::CPU';

subtest construct => sub {
    my $r = $CLASS->new(utilize_percent => 80);
    is($r->utilize_percent, 80, 'utilize stored');
    is($r->min_concurrent, 1, 'default min_concurrent');

    like(dies { $CLASS->new(utilize_percent => 0) }, qr/must be > 0/, 'reject 0');
    like(dies { $CLASS->new(utilize_percent => 100) }, qr/must be > 0 and < 100/, 'reject 100');
    like(dies { $CLASS->new(utilize_percent => 'abc') }, qr/must be > 0/, 'reject non-numeric');
};

# Construct CPU resource with a controlled initial /proc/stat reading.
# init() primes PREV_STAT by reading /proc/stat, so we must mock before new().
sub make_cpu {
    my (%args) = @_;
    my $init_line = delete $args{init_line} // "cpu 100 0 100 800 0 0 0 0 0 0\n";
    # Disable EMA + min_dt threshold so tests deal in raw single-sample values.
    $args{ema_alpha} //= 1;
    $args{min_dt}    //= 1;
    no warnings 'redefine';
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { $init_line };
    return $CLASS->new(%args);
}

subtest sample_logic => sub {
    my $r = make_cpu(utilize_percent => 50, init_line => "cpu 100 0 100 800 0 0 0 0 0 0\n");

    no warnings 'redefine';
    # Increment idle by 50, total by 100. busy = 1 - 50/100 = 50%
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 125 0 125 850 0 0 0 0 0 0\n" };
    is($r->_sample, 50, '50% busy computed against init-primed PREV_STAT');

    # Same /proc/stat (dt=0) -> returns LAST_BUSY_PCT and does NOT clobber PREV_STAT.
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 125 0 125 850 0 0 0 0 0 0\n" };
    is($r->_sample, 50, 'dt=0 returns cached');

    # Next reading: prev now (total=1100, idle=850). New: total=1300, idle=875.
    # dt=200, di=25 => busy = 100*(1 - 25/200) = 87.5%
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 200 0 225 875 0 0 0 0 0 0\n" };
    is($r->_sample, 87.5, 'next real reading computed against accumulated PREV_STAT');
};

subtest available => sub {
    my $r = make_cpu(utilize_percent => 50, min_concurrent => 0, init_line => "cpu 100 0 100 800 0 0 0 0 0 0\n");

    no warnings 'redefine';
    # 80% busy: di=20 dt=100
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 180 0 180 820 0 0 0 0 0 0\n" };
    is($r->available({}), 0, 'defer when above utilize');

    # PREV_STAT now at (200,820). 20% busy: di=80 dt=100 -> di/dt=0.8 -> busy=20%
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 210 0 210 900 0 0 0 0 0 0\n" };
    is($r->available({}), 1, 'allow when below utilize');
};

subtest min_concurrent_floor => sub {
    my $r = make_cpu(utilize_percent => 50, min_concurrent => 2, init_line => "cpu 0 0 0 0 0 0 0 0 0 0\n");
    no warnings 'redefine';
    # Each call: total +100, idle +0 -> 100% busy
    my $t = 0;
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub {
        $t += 100;
        return "cpu $t 0 0 0 0 0 0 0 0 0\n";
    };
    $r->_sample; # sets busy=100 against init-primed prev

    is($r->available({}), 1, 'always allow under floor (in_flight=0)');

    my $state = {};
    $r->assign({}, $state);
    $r->record('job1', $state->{record});
    is($r->available({}), 1, 'still allow at in_flight=1 < min=2');

    $state = {};
    $r->assign({}, $state);
    $r->record('job2', $state->{record});
    is($r->available({}), 0, 'defer at in_flight=2 (>= min) when saturated');

    $r->release('job1');
    is($r->available({}), 1, 'allow after release (back under floor)');
};

subtest ema_smoothing => sub {
    # alpha=0.5 means new sample contributes 50%, prev smoothed 50%.
    # min_dt=1 so each call consumes.
    my $r = make_cpu(utilize_percent => 50, ema_alpha => 0.5, min_dt => 1,
                     init_line => "cpu 0 0 0 0 0 0 0 0 0 0\n");
    no warnings 'redefine';

    # 100% busy reading: total +100, idle +0
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 100 0 0 0 0 0 0 0 0 0\n" };
    is($r->_sample, 100, 'first sample seeds EMA directly');

    # 0% busy reading: total +100, idle +100. EMA = 0.5*0 + 0.5*100 = 50
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 100 0 0 100 0 0 0 0 0 0\n" };
    is($r->_sample, 50, 'second sample blended');

    # 0% busy again. EMA = 0.5*0 + 0.5*50 = 25
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 100 0 0 200 0 0 0 0 0 0\n" };
    is($r->_sample, 25, 'third sample blended further');
};

subtest min_dt_threshold => sub {
    # min_dt=100 jiffies; small dt should not consume PREV_STAT
    my $r = make_cpu(utilize_percent => 50, min_dt => 100, ema_alpha => 1,
                     init_line => "cpu 0 0 0 0 0 0 0 0 0 0\n");
    no warnings 'redefine';

    # dt = 50 (under threshold). Should return LAST_BUSY_PCT (0) and NOT update PREV_STAT.
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 25 0 25 0 0 0 0 0 0 0\n" };
    is($r->_sample, 0, 'small dt below threshold: returns cached');

    # Now a much larger reading: dt from original prev (0,0) = 200, idle delta=0 -> 100% busy
    local *Test2::Harness::Resource::Utilization::CPU::_read_stat_first_line = sub { "cpu 100 0 100 0 0 0 0 0 0 0\n" };
    is($r->_sample, 100, 'large dt: real computation against accumulated PREV_STAT');
};

done_testing;
