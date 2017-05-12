#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use File::Path 'remove_tree';
use Test::More;
use Test::App::EventStreamr::ConfigAPI;

#TODO: Add 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $config = Test::App::EventStreamr::ConfigAPI->new();
my $example = '/tmp/controller/controller.json';

subtest 'No controller config' => sub {
  can_ok($config, qw(localconfig controller controller_config));
  is($config->controller, 0, "Controller config doesn't exist");
};

# Test controller api
my $pid = fork();
if (!$pid) {
  exec("t/bin/controller.pl");
}
sleep 5;

subtest 'Controller Config' => sub {
  # Create example controller config
  open(my $fh, '>', $example);
  print $fh "# config-file-type: JSON 1\n";
  print $fh '{"controller" : "http://127.0.0.1:3000"}'."\n";
  close $fh;
  
  is( -e $example, 1, "Controller Example Created");
  
  $config = Test::App::EventStreamr::ConfigAPI->new();

  # Test config from Controller
  is($config->controller, "http://127.0.0.1:3000", "Controller details found");

  is($config->nickname, 'controller_test', "Nickname: ".$config->nickname);
  is($config->room, 'control_room', "Room: ".$config->room);
  is($config->run, '1', "Run: ".$config->run);
  is($config->record_path, '/tmp/control', "Record Path: ".$config->record_path);
  is(-e $config->config_file, 1, "Config was written");
};

subtest 'Internal Config' => sub {
  # Test config from internal api
  $config = Test::App::EventStreamr::ConfigAPI->new();
  $config->get_config();
  is($config->nickname, 'internal_test', "Nickname: ".$config->nickname);
  is($config->room, 'internal_room', "Room: ".$config->room);
  is($config->run, '2', "Run: ".$config->run);
  is($config->record_path, '/tmp/internal', "Record Path: ".$config->record_path);
};

# Kill Test api
kill 9, $pid;

subtest 'Test cleanup' => sub {
  remove_tree('/tmp/controller');
  isnt( -d '/tmp/controller', 1, "Controller Example removed");
};

done_testing();
