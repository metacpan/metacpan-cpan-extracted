#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use Test::More tests => 5;
use Test::App::EventStreamr::ProcessControl;
use Proc::ProcessTable; # libproc-processtable-perl
#TODO: Add 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $command = 'ping 127.0.0.1';
my $id = 'ping';

my $proc = Test::App::EventStreamr::ProcessControl->new(
  cmd => $command,
  id => $id,
);

my $pt = Proc::ProcessTable->new;

subtest 'Instantiation' => sub {
  can_ok($proc, qw(start running stop));
};

subtest 'method: start' => sub {
  $proc->start();

  sleep 1;
  my @procs = grep { $_->cmndline =~ /$command/ } @{ $pt->table };

  my $pid = $procs[0]->pid;
  my $cmdline = $procs[0]->cmndline;

  is($proc->pid, $pid, "Pids Match for $cmdline");
};


subtest 'method: stop' => sub {
  $proc->stop();

  sleep 1;

  my @procs = grep { $_->cmndline =~ /$command/ } @{ $pt->table };
  isnt(@procs, defined, "Process Stopped");
};

subtest 'method: running' => sub {
  $proc->pid;
  is($proc->running, 0, "Process not running");
  $proc->start();
  sleep 1;
  is($proc->running, 1, "Process running");
  $proc->stop();
  sleep 1;
  is($proc->pid, 0, "Pid Cleared");
};

subtest 'cmd_regex' => sub {
  my $proc = Test::App::EventStreamr::ProcessControl->new(
    cmd => $command,
    regex => $id,
    id => $id,
  );
  
  $proc->start();
  sleep 1;
  is($proc->running, 1, "Process running");
  $proc->stop();
};

