#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use FindBin qw($Bin);
use Test::More;
use App::EventStreamr::DVswitch::Mixer;
use App::EventStreamr::DVswitch::Standby;
use App::EventStreamr::Status;
use Test::App::EventStreamr::ProcessTest;

# Added 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $status = App::EventStreamr::Status->new();

my $config = {
  run => 1, 
  control => {
    dvfile => {
      run => 1,
    },
  },
  mixer => {
    host => '127.0.0.1',
    port => 1234,
    loop => "$Bin/../../../data/Test.dv",
  },
  write_config => sub { },
};
bless $config, "App::EventStreamr::Config";

my $dvswitch = App::EventStreamr::DVswitch::Mixer->new(
  config => $config,
  status => $status,
);

my $proc = App::EventStreamr::DVswitch::Standby->new(
  config => $config,
  status => $status,
);


SKIP: {
  skip "DVswitch||DVsource not installed", 5, unless ( -e "/usr/bin/dvswitch" && -e "/usr/bin/dvsource-file" );
  
  $dvswitch->start();

  Test::App::EventStreamr::ProcessTest->new(
    process => $proc,
    config => $config,
    id => 'dvfile',
  )->run_tests();

  $dvswitch->stop();
}

done_testing();
