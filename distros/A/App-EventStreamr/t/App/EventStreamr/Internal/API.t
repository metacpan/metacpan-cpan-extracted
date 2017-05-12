#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use FindBin '$Bin';
use Test::More;
use App::EventStreamr::Internal::API;
use App::EventStreamr::Status;
use Test::App::EventStreamr::ProcessTest;

# Added 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $status = App::EventStreamr::Status->new();

my $config = {
  run => 0, 
  write_config => sub { },
};
bless $config, "App::EventStreamr::Config";

# This assumes tests are run from root of repo 
my $proc = App::EventStreamr::Internal::API->new(
  config => $config,
  status => $status,
  cmd => "plackup -s Twiggy -p 3000 $Bin/../../../../bin/eventstreamr-api.pl",
);

TODO: {
  local $TODO = "Process tests broken with Travis" if ($ENV{TRAVIS});

  $proc->run_stop;
  
  is($proc->running, 1, "Process was Started");
  
  $proc->stop;
}

done_testing();
