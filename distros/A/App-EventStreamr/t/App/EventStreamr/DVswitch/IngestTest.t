#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use Test::More tests => 6;
use App::EventStreamr::Ingest;
use App::EventStreamr::Status;
use App::EventStreamr::Config;
use File::Path qw(remove_tree make_path);

my $command = 'ping 127.0.0.1';
my $id = 'ping';
my $status = App::EventStreamr::Status->new();

make_path('/tmp/eventstreamr');

open(my $fh, '>', '/tmp/config.json');
print $fh '{"run" : "1", "control" : { "ping" : { "run" : "1" } }, "devices" : [{"device" : "ping 127.0.0.1","id" : "ping", "name" : "EventStreamr Testing", "type" : "IngestTest" }]}';
close $fh;

my $config = App::EventStreamr::Config->new(
  config_path => '/tmp',
);

my $proc = App::EventStreamr::Ingest->new(
  cmd => $command,
  id => $id,
  config => $config,
  status => $status,
);

subtest 'Instantiation' => sub {
  can_ok($proc, qw(run_stop));
};

subtest 'Start/Stop' => sub {
  $proc->start();
  sleep 1;
  is($proc->_devices->{$id}->running, 1, "Process was Started");
  
  $proc->stop();
  sleep 1;
  isnt($proc->_devices->{$id}->running, 1, "Process was Stop");
};

subtest 'Run Stop Starting' => sub {
  $proc->run_stop();
  sleep 1;

  is($proc->_devices->{$id}->running, 1, "Process was Started");
};

$config->{control}{ping}{run} = 0;
subtest 'Run Stop Stopping' => sub {
  $proc->run_stop();

  sleep 1;
  isnt($proc->_devices->{$id}->running, 1, "Process was Stopped");
};

$config->{control}{ping}{run} = 2;
subtest 'Run Stop Restarting' => sub {
  $proc->run_stop();
  $proc->run_stop();

  sleep 1;
  is($proc->_devices->{$id}->running, 1, "Process was Restarted");
};

subtest 'Cleanup' => sub {
  $proc->stop();
  sleep 1;
  isnt($proc->_devices->{$id}->running, 1, "Process was Stopped");

  unlink('/tmp/config.json');
  isnt( ( -e "/tmp/config.json" ),1 ,"Temp Config Removed" );
};

