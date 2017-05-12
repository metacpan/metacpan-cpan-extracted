#!perl -T

use strict;
use warnings;
use 5.006;
use lib 'lib';
use Test::Roo;

use MooX::Types::MooseLike::Base qw/Str ArrayRef/;
use IO::Iron::IronMQ::Client 0.12;

with 'Dancer2::Plugin::Queue::Role::Test';

# use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
# use Log::Any::Adapter ('File', './ironmq.t.log'); # Activate to get all log messages.

my $queue_name = 'test_dancer_plugin_queue_ironmq';
my $client = IO::Iron::IronMQ::Client->new('config' => 'ironmq.json');
my $queue = $client->create_and_get_queue( 'name' => $queue_name );

run_me( { 'backend' => 'IronMQ', 'options' => { 'config' => 'ironmq.json' } } );
run_me( {
        'backend' => 'IronMQ',
        'options' => {
            'config' => 'ironmq.json',
            'queue' => $queue_name,
        },
    } );
$client->delete_queue( 'name' => $queue_name );

done_testing;

