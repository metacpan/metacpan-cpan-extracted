package Tests::Supervisor;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;


sub test_01_client : Test(9) {
    my $self = shift;

    $self->start_workers('Tests::Service::Worker');

    my $svc = 'Beekeeper::Service::Supervisor';

    my $workers = $svc->get_workers_status;

    @$workers = grep { $_->{class} ne 'Beekeeper::Service::ToyBroker::Worker' } @$workers;

    # $workers = [
    #
    # {
    #   'host'  => 'hostname',
    #   'pool'  => 'test-pool',
    #   'pid'   => 4916,
    #   'mem'   => '0.00',
    #   'cps'   => '0.00',
    #   'nps'   => '0.00',
    #   'cpu'   => '0.00',
    #   'load'  => '0.00',
    #   'queue' => ['test'],
    #   'class' => 'Tests::Service::Worker'
    # }, ...

    is( scalar @$workers, 3 );

    my $services = $svc->get_services_status;

    delete $services->{'Beekeeper::Service::ToyBroker::Worker'};

    ok( exists $workers->[0]->{'class'} );
    ok( exists $workers->[0]->{'queue'} );
    is( $workers->[0]->{'pool'}, 'test-pool' );

    # $sevices = {
    #
    # 'Tests::Service::Worker' => {
    #     'mem'   => '0.00',
    #     'cps'   => '0.00'
    #     'nps'   => '0.00',
    #     'cpu'   => '0.00',
    #     'load'  => '0.00',
    #     'count' => 2,
    # }, ...

    is( scalar keys %$services, 2 );
    ok( exists $services->{'Tests::Service::Worker'} );
    ok( exists $services->{'Beekeeper::Service::Supervisor::Worker'} );

    is( $services->{'Tests::Service::Worker'}->{count}, 2 );
    is( $services->{'Beekeeper::Service::Supervisor::Worker'}->{count}, 1 );
}

1;
