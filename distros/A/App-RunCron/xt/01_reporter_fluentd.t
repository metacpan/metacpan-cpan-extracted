use strict;
use warnings;
use utf8;
use Test::Requires 'Fluent::Logger';
use Test::More;
use Test::App::RunCron;

use_ok 'App::RunCron::Reporter::Fluentd';

subtest mock => sub {
    my $mock = mock_runcron;
    App::RunCron::Reporter::Fluentd->new->run($mock);
    pass 'ok';
};

done_testing;
