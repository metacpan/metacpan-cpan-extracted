use Test2::V0;

BEGIN { skip_all "Linux only" unless $^O eq 'linux' }

use Test2::Harness::Resource::Utilization::PipeLimits;
my $CLASS = 'Test2::Harness::Resource::Utilization::PipeLimits';

subtest construct => sub {
    my $r = $CLASS->new(cap_pages => 1024, pages_per_pipe => 16);
    is($r->pipes_per_test,    2, 'default pipes_per_test');
    is($r->pipes_per_service, 2, 'default pipes_per_service');
    is($r->service_count,     0, 'default service_count');
    is($r->headroom, {kind => 'pct', value => 10}, 'default headroom 10%');
    is($r->cap_pages, 1024, 'cap_pages override');

    like(
        dies { $CLASS->new(pipes_per_test => -1) },
        qr/non-negative integer/,
        'reject negative pipes_per_test',
    );
};

subtest threshold => sub {
    my $r = $CLASS->new(cap_pages => 1000, pages_per_pipe => 10, headroom => {kind => 'count', value => 50});
    is($r->_effective_min_free_pages, 50, 'count headroom');

    $r = $CLASS->new(cap_pages => 1000, pages_per_pipe => 10, headroom => {kind => 'pct', value => 10});
    is($r->_effective_min_free_pages, 100, '10% of 1000');

    $r = $CLASS->new(cap_pages => 1000, pages_per_pipe => 10, headroom => {kind => 'count', value => 50}, utilize_percent => 80);
    is($r->_effective_min_free_pages, 200, 'utilize wins (max)');
};

subtest available => sub {
    my $r = $CLASS->new(
        cap_pages          => 1000,
        pages_per_pipe     => 10,
        pipes_per_test     => 2,
        pipes_per_service  => 0,
        service_count      => 0,
        headroom           => {kind => 'count', value => 50},
        min_concurrent     => 0,
    );

    # in_flight=0 svc=0 tst=0 free=1000. next = 2*10=20. 1000-20=980 >= 50 => ok
    is($r->available({}), 1, 'capacious => allow');

    # Bump in_flight to 45: tst=45*2*10=900, free=100. next=20. 80 >= 50 => ok
    my $state;
    for my $i (1 .. 45) {
        $state = {};
        $r->assign({}, $state);
        $r->record("job$i", $state->{record});
    }
    is($r->available({}), 1, 'near cap but still above threshold');

    # Bump to 48: tst=960, free=40. 40-20 = 20 < 50 => defer
    for my $i (46 .. 48) {
        $state = {};
        $r->assign({}, $state);
        $r->record("job$i", $state->{record});
    }
    is($r->available({}), 0, 'over threshold => defer');

    $r->release("job$_") for 46 .. 48;
    is($r->available({}), 1, 'allow after release');
};

done_testing;
