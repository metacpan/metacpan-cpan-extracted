package Tests::LogTail;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;
use Time::HiRes 'sleep';


sub start_test_workers : Test(startup) {
    my $self = shift;

    $self->start_workers('Tests::Service::Worker');
    $self->start_workers('Beekeeper::Service::LogTail::Worker');
};

sub test_00_compile_client : Test(2) {
    my $self = shift;

    use_ok('Beekeeper::Service::LogTail');
    use_ok('Tests::Service::Client');
}


sub test_01_client : Test(11) {
    my $self = shift;

    # Cause a warning
    Tests::Service::Client->notify( 'test.fail' => { 'warn' => 'Foo' });

    sleep 0.01;

    my $svc = 'Beekeeper::Service::LogTail';

    my $logged = $svc->tail;
    my $last = $logged->[-1];

    is($last->{type}, 'warning', 'Got warning');
    is($last->{level}, 5, 'level');
    like($last->{message}, qr/Foo/, 'message');
    is($last->{pool}, 'test-pool', 'pool');
    is($last->{service}, 'tests-service', 'service');

    # Cause an error
    Tests::Service::Client->notify( 'test.fail' => { 'die'  => 'Bar' });

    sleep 0.01;

    $logged = $svc->tail;
    $last = $logged->[-1];

    is($last->{type}, 'error', 'Got error');
    is($last->{level}, 4, 'level');
    like($last->{message}, qr/Bar/, 'message');
    is($last->{pool}, 'test-pool', 'pool');
    is($last->{service}, 'tests-service', 'service');

    $logged = $svc->tail( count => 3 );
    is(scalar @$logged, 3, 'count');

    #TODO: test filters
}

1;
