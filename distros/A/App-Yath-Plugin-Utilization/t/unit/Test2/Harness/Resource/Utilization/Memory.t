use Test2::V0;

BEGIN { skip_all "Linux only" unless $^O eq 'linux' }

use Test2::Harness::Resource::Utilization::Memory;
my $CLASS = 'Test2::Harness::Resource::Utilization::Memory';

subtest construct => sub {
    my $r = $CLASS->new(min_free => {kind => 'pct', value => 10});
    is($r->min_free, {kind => 'pct', value => 10}, 'min_free stored');

    my $r2 = $CLASS->new;
    is($r2->min_free, {kind => 'pct', value => 5}, 'default min_free 5%');

    like(dies { $CLASS->new(min_free => {kind => 'bogus', value => 1}) }, qr/min_free.kind must be/, 'bad kind');
    like(dies { $CLASS->new(min_free => {kind => 'pct', value => 100}) }, qr/min_free.value \(pct\)/, '100 pct rejected');
};

subtest threshold_math => sub {
    my $r = $CLASS->new(min_free => {kind => 'pct', value => 10});
    is($r->_effective_min_free_bytes(1000), 100, '10% of 1000 = 100');

    $r = $CLASS->new(min_free => {kind => 'bytes', value => 500});
    is($r->_effective_min_free_bytes(1000), 500, 'absolute bytes');

    $r = $CLASS->new(min_free => {kind => 'pct', value => 5}, utilize_percent => 80);
    # utilize -> need 20% free = 200; explicit = 50; max = 200
    is($r->_effective_min_free_bytes(1000), 200, 'utilize wins when more conservative');

    $r = $CLASS->new(min_free => {kind => 'pct', value => 30}, utilize_percent => 80);
    # explicit = 300; utilize = 200; max = 300
    is($r->_effective_min_free_bytes(1000), 300, 'explicit wins when more conservative');
};

subtest available => sub {
    my $r = $CLASS->new(min_free => {kind => 'pct', value => 10}, min_concurrent => 0);

    no warnings 'redefine';
    local *Test2::Harness::Resource::Utilization::Memory::_read_meminfo = sub {
        ['MemTotal:        1000 kB', 'MemAvailable:     200 kB'];
    };
    is($r->available({}), 1, '200 > 100 (10% of 1000) => allow');

    local *Test2::Harness::Resource::Utilization::Memory::_read_meminfo = sub {
        ['MemTotal:        1000 kB', 'MemAvailable:      50 kB'];
    };
    is($r->available({}), 0, '50 < 100 => defer');
};

done_testing;
