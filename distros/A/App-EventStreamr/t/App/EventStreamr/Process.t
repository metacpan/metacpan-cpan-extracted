#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use Test::More tests => 8;
use Test::App::EventStreamr::Process;
use App::EventStreamr::Status;
use App::EventStreamr::Config;
use Test::App::EventStreamr::ProcessTest;

my $command = 'ping 127.0.0.1';
my $id = 'ping';
my $status = App::EventStreamr::Status->new();

open(my $fh, '>', '/tmp/config.json');

print $fh '{"run":"1","control":{"ping":{"run":"1"}}}';
close $fh;

my $config = App::EventStreamr::Config->new(
  config_path => '/tmp',
);

my $proc = Test::App::EventStreamr::Process->new(
  cmd => $command,
  id => $id,
  config => $config,
  status => $status,
);

Test::App::EventStreamr::ProcessTest->new(
  process => $proc,
  config => $config,
  id => $id,
)->run_tests();

subtest 'State Changes' => sub {
  is($status->set_state($proc->running,$proc->{id},$proc->{type}), 0, "State not changed");
  $proc->start();
  sleep 1;
  is($status->set_state($proc->running,$proc->{id},$proc->{type}), 1, "State changed");
  $proc->stop();
  sleep 1;
};

$proc = Test::App::EventStreamr::Process->new(
  cmd => 'ls -lah',
  id => 'ls',
  config => $config,
  status => $status,
);

my $count = 0;
while (! $status->threshold('ls',$proc->{type}) && $count < 20) {
  $proc->run_stop;
  $count++;
  sleep 1;
}

is($count < 20, 1, "Threshold reached correctly in $count iterations");

unlink('/tmp/config.json');
isnt( ( -e "/tmp/config.json" ),1 ,"Temp Config Removed" );
