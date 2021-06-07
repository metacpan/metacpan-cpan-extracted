package Tests::TestBase;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;


sub test_01_spawn_workers : Test(5) {
    my $self = shift;

    my @pids = $self->start_workers( 'Tests::Service::Worker', workers_count => 2 );

    is( scalar @pids, 2, "Spawned 2 workers");

    my $running_1 = kill(0, $pids[0]);
    my $running_2 = kill(0, $pids[1]);

    is($running_1, 1, 'Worker 1 is running');
    is($running_2, 1, 'Worker 2 is running');


    $self->stop_workers('INT', @pids);

    $running_1 = kill(0, $pids[0]);
    $running_2 = kill(0, $pids[1]);

    is($running_1, 0, 'Worker 1 was stopped');
    is($running_2, 0, 'Worker 2 was stopped');
}

1;
