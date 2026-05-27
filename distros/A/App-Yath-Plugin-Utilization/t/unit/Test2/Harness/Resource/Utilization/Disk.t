use Test2::V0;

BEGIN {
    eval { require Filesys::Df; 1 } or skip_all "Filesys::Df not installed";
}

use Test2::Harness::Resource::Utilization::Disk;
my $CLASS = 'Test2::Harness::Resource::Utilization::Disk';

subtest construct => sub {
    my $r = $CLASS->new(mounts => {'/tmp' => {min_free => {kind => 'pct', value => 1}}});
    is(ref($r->mounts), 'HASH', 'mounts stored');

    like(
        dies { $CLASS->new(mounts => {'/nonexistent_path_abc_xyz' => {min_free => {kind => 'pct', value => 1}}}) },
        qr/does not exist/,
        'missing mount rejected',
    );

    like(dies { $CLASS->new(mounts => {}) }, qr/at least one --disk-mount/, 'empty mounts rejected');
};

subtest evaluate_threshold => sub {
    my $ok  = Test2::Harness::Resource::Utilization::Disk::_evaluate_threshold(
        {kind => 'pct', value => 10}, 500, 1000);
    is($ok, 'ok', '50% free above 10% threshold');

    my $low = Test2::Harness::Resource::Utilization::Disk::_evaluate_threshold(
        {kind => 'pct', value => 60}, 500, 1000);
    is($low, 'low', '50% free below 60% threshold');

    is(Test2::Harness::Resource::Utilization::Disk::_evaluate_threshold(
        {kind => 'bytes', value => 1000}, 2000, 5000), 'ok', '2k bytes above 1k threshold');
    is(Test2::Harness::Resource::Utilization::Disk::_evaluate_threshold(
        {kind => 'bytes', value => 3000}, 2000, 5000), 'low', '2k bytes below 3k threshold');
};

subtest sample_failure_permanent => sub {
    my $r = $CLASS->new(mounts => {'/tmp' => {min_free => {kind => 'pct', value => 1}}});

    no warnings 'redefine';
    local *Filesys::Df::df = sub { die "boom" };

    $r->_take_sample('/tmp');
    is($r->{+Test2::Harness::Resource::Utilization::Disk::PERMANENT_BROKEN()}, 0, 'no permanent break after 1 failure');
    $r->_take_sample('/tmp');
    is($r->{+Test2::Harness::Resource::Utilization::Disk::PERMANENT_BROKEN()}, 0, 'no permanent break after 2 failures');
    $r->_take_sample('/tmp');
    is($r->{+Test2::Harness::Resource::Utilization::Disk::PERMANENT_BROKEN()}, 1, 'permanent after 3');

    is($r->available({}), -1, 'available returns -1 when broken');
};

done_testing;
