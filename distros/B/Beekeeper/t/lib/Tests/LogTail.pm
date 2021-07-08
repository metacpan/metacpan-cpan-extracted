package Tests::LogTail;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;


sub start_test_workers : Test(startup) {
    my $self = shift;

    $self->start_workers('Tests::Service::Worker');
    $self->start_workers('Beekeeper::Service::LogTail::Worker');
};

sub test_01_compile : Test(2) {
    my $self = shift;

    use_ok('Tests::Service::Client');
    use_ok('Beekeeper::Service::LogTail');
}

sub test_02_client : Test(9) {
    my $self = shift;

    # Cause a warning
    Tests::Service::Client->notify( 'test.fail' => { 'warn' => 'Foo' });

    $self->_sleep( 0.2 );

    my $svc = 'Beekeeper::Service::LogTail';

    my $logged = $svc->tail;
    my $last = $logged->[-1];

    is($last->{level}, 5, 'level 5 warning');
    like($last->{message}, qr/Foo/, 'message');
    is($last->{pool}, 'test-pool', 'pool');
    is($last->{service}, 'tests-service', 'service');

    # Cause an error
    Tests::Service::Client->notify( 'test.fail' => { 'die'  => 'Bar' });

    $self->_sleep( 0.2 );

    $logged = $svc->tail;
    $last = $logged->[-1];

    is($last->{level}, 4, 'level 4 error');
    like($last->{message}, qr/Bar/, 'message');
    is($last->{pool}, 'test-pool', 'pool');
    is($last->{service}, 'tests-service', 'service');

    $logged = $svc->tail( count => 3 );
    is(scalar @$logged, 3, 'count');

    #TODO: test filters
}

1;
