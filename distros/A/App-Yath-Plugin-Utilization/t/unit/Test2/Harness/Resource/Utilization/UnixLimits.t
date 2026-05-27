use Test2::V0;

BEGIN { skip_all "Linux only" unless $^O eq 'linux' }

use Test2::Harness::Resource::Utilization::UnixLimits;
my $CLASS = 'Test2::Harness::Resource::Utilization::UnixLimits';

subtest construct => sub {
    my $r = $CLASS->new;
    is($r->nproc,  {kind => 'pct', value => 10}, 'default nproc=10%');
    is($r->nofile, {kind => 'pct', value => 10}, 'default nofile=10%');
    is($r->as,     undef, 'as off by default');

    my $r2 = $CLASS->new(
        nproc  => {kind => 'count', value => 128},
        nofile => {kind => 'count', value => 256},
        as     => {kind => 'bytes', value => 1024 * 1024 * 512},
    );
    is($r2->nproc->{value}, 128);
    is($r2->as->{kind}, 'bytes');

    like(dies { $CLASS->new(nproc => {kind => 'pct', value => 0}) }, qr/value must be > 0/, 'reject 0');
};

subtest assess => sub {
    my $r = $CLASS->new(nproc => {kind => 'pct', value => 10});
    # soft_cap=1000 explicit=100 utilize=undef
    my $a = $r->_assess_dimension('nproc', 1000, 900);
    is($a->{state}, 'ok', 'free=100 == effective=100 => ok');
    is($a->{free}, 100);

    $a = $r->_assess_dimension('nproc', 1000, 950);
    is($a->{state}, 'low', 'free=50 < effective=100 => low');

    # unlimited cap => always ok
    $a = $r->_assess_dimension('nproc', undef, 999_999);
    is($a->{state}, 'ok', 'unlimited cap => ok');

    # utilize layering
    my $r2 = $CLASS->new(nproc => {kind => 'count', value => 50}, utilize_percent => 80);
    # explicit=50; utilize-derived = 1000 * (100-80)/100 = 200; effective=200
    $a = $r2->_assess_dimension('nproc', 1000, 850);
    is($a->{state}, 'low', 'utilize raises threshold above explicit (free=150 < eff=200)');
};

subtest available => sub {
    my $r = $CLASS->new(min_concurrent => 0, nproc => {kind => 'pct', value => 10});

    no warnings 'redefine';
    local *Test2::Harness::Resource::Utilization::UnixLimits::_read_self_limits = sub {
        return {nproc => 1000, nofile => 1000, as => undef};
    };
    local *Test2::Harness::Resource::Utilization::UnixLimits::_read_self_status = sub {
        return {Threads => 500, VmSize => 0};
    };
    local *Test2::Harness::Resource::Utilization::UnixLimits::_count_self_fd = sub { 50 };

    is($r->available({}), 1, 'plenty of headroom => allow');

    local *Test2::Harness::Resource::Utilization::UnixLimits::_read_self_status = sub {
        return {Threads => 950, VmSize => 0};
    };
    is($r->available({}), 0, 'nproc near cap => defer');
};

done_testing;
