#!/usr/bin/env perl -wT

use strict;
use warnings;

BEGIN {
    use Cwd 'abs_path';
    my ($dir) = abs_path(__FILE__);
    ($dir) = $dir =~ m|(.*)/|;
    unshift @INC, "$dir/lib", "$dir/../lib";
}

use Test::More;

plan tests => 18;

unless ($^O eq 'linux' || $^O eq 'freebsd') {
    BAIL_OUT "OS unsupported";
}

use_ok $_ for qw(
    Beekeeper
    Beekeeper::JSONRPC
    Beekeeper::MQTT
    Beekeeper::Config
    Beekeeper::Logger
    Beekeeper::Client
    Beekeeper::Worker
    Beekeeper::WorkerPool::Daemon
    Beekeeper::WorkerPool
    Beekeeper::Worker::Extension::SharedCache
    Beekeeper::Worker::Extension::RemoteSession
    Beekeeper::Service::Supervisor
    Beekeeper::Service::Supervisor::Worker
    Beekeeper::Service::LogTail
    Beekeeper::Service::LogTail::Worker
    Beekeeper::Service::Router::Worker
    Beekeeper::Service::ToyBroker::Worker
    Beekeeper::Service::Sinkhole::Worker
);

diag( "Testing Beekeeper $Beekeeper::VERSION, Perl $]" );
