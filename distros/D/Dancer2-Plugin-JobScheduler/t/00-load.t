#!perl
use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use Dancer2;
use Dancer2::Plugin::JobScheduler;

subtest 'Load' => sub {
    pass('Can load module');
    done_testing;
};

done_testing;
