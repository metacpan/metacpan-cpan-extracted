#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use FindBin qw($Bin);
use Test::More;
use App::EventStreamr::DVswitch::Mixer;
use App::EventStreamr::DVswitch::Ingest::V4L;
use App::EventStreamr::Status;
use Test::App::EventStreamr::ProcessTest;

# Added 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $status = App::EventStreamr::Status->new();

my $config = {
  run => 1, 
  control => {
    video0 => {
      run => 1,
    },
  },
  mixer => {
    host => '127.0.0.1',
    port => 1234,
  },
  write_config => sub { },
};
bless $config, "App::EventStreamr::Config";

my $dvswitch = App::EventStreamr::DVswitch::Mixer->new(
  config => $config,
  status => $status,
);

my $proc = App::EventStreamr::DVswitch::Ingest::V4L->new(
  config => $config,
  status => $status,
  id => 'video0',
  device => '/dev/video0',
);

SKIP: {
  # TODO: Detect and use the first available V4L device
  skip "No /dev/video0 device", 5, unless ( -e "/dev/video0" );
  skip "DVsource not available", 5, unless ( -e "/usr/bin/dvsource" );
  
  $dvswitch->start();

  Test::App::EventStreamr::ProcessTest->new(
    process => $proc,
    config => $config,
    id => 'video0',
  )->run_tests();

  $dvswitch->stop();
}

done_testing();
