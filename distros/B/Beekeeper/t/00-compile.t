#!/usr/bin/env perl -T

use strict;
use warnings;

BEGIN {
    use Cwd 'abs_path';
    my ($dir) = abs_path(__FILE__);
    ($dir) = $dir =~ m|(.*)/|;
    unshift @INC, "$dir/lib", "$dir/../lib";
}

use Test::More;

plan tests => 17;

unless ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'darwin') {
    BAIL_OUT "OS unsupported";
}

use_ok $_ for qw(
    Beekeeper
    Beekeeper::JSONRPC
    Beekeeper::Bus::STOMP
    Beekeeper::Config
    Beekeeper::Logger
    Beekeeper::Client
    Beekeeper::Worker
    Beekeeper::WorkerPool::Daemon
    Beekeeper::WorkerPool
    Beekeeper::Worker::Util
    Beekeeper::Service::Supervisor
    Beekeeper::Service::Supervisor::Worker
    Beekeeper::Service::Sinkhole::Worker
    Beekeeper::Service::LogTail
    Beekeeper::Service::LogTail::Worker
    Beekeeper::Service::Router
    Beekeeper::Service::Router::Worker
);

diag( "Testing Beekeeper $Beekeeper::VERSION, Perl $]" );
