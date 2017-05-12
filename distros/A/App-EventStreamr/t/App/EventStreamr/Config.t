#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use Test::More;
use Sys::Hostname;
use App::EventStreamr::Config;
use File::Path qw(remove_tree);

# Added 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $path = "/tmp/.eventstreamr";

my $config = App::EventStreamr::Config->new(
  config_path => $path,
);

# TODO: cleanup these tests
subtest 'Initial config' => sub {
  is($config->nickname, hostname, "Nickname generated: $config->{nickname}");
  is($config->room, "test_room", "Room generated: $config->{room}");
  is($config->record_path, '/tmp/$room/$date', "Record Path generated: $config->{record_path}");
  is($config->run, 0, "Run generated: $config->{run}");
  is($config->backend, "DVswitch", "Backend generated: $config->{backend}");
};

$config = App::EventStreamr::Config->new(
  config_path => $path,
);

# TODO: cleanup these tests
subtest 'Reloaded config' => sub {
  is($config->nickname, hostname, "Nickname generated: $config->{nickname}");
  is($config->room, "test_room", "Room generated: $config->{room}");
  is($config->record_path, '/tmp/$room/$date', "Record Path generated: $config->{record_path}");
  is($config->run, 0, "Run generated: $config->{run}");
  is($config->backend, "DVswitch", "Backend generated: $config->{backend}");
};

$config->{room} = 'changed_room';
$config->{nickname} = 'changed';
$config->{record_path} = '/tmp/new';
$config->{run} = 1;
$config->{backend} = "GSTswitch";

$config->write_config;

$config = App::EventStreamr::Config->new(
  config_path => $path,
);

# TODO: cleanup these tests
subtest 'Altered + Reloaded config' => sub {
  is($config->nickname, 'changed', "Nickname generated: $config->{nickname}");
  is($config->room, "changed_room", "Room generated: $config->{room}");
  is($config->record_path, '/tmp/new', "Record Path generated: $config->{record_path}");
  is($config->run, 1, "Run generated: $config->{run}");
  is($config->backend, "GSTswitch", "Backend generated: $config->{backend}");
};

remove_tree( "$path" );
isnt( ( -d "$path" ),1 ,"Temp Config Path Removed" );

done_testing();
