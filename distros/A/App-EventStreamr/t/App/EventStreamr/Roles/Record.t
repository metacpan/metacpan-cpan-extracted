#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use Test::More tests => 5;

# Add 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

use Test::App::EventStreamr::Record;
use App::EventStreamr::Status;
use App::EventStreamr::Config;
use File::Path qw(remove_tree make_path);
use Time::Local;
use POSIX 'strftime';

my $command = 'ping 127.0.0.1';
my $id = 'ping';
my $date = strftime "%Y%m%d", localtime();

my $status = App::EventStreamr::Status->new();

make_path('/tmp/eventstreamr');

open(my $fh, '>', '/tmp/config.json');

print $fh '{"run":"1","control":{"ping":{"run":"1"}},"record_path":"/tmp/$room/$date","room":"eventstreamr"}';
close $fh;

my $config = App::EventStreamr::Config->new(
  config_path => '/tmp',
);

my $proc = Test::App::EventStreamr::Record->new(
  cmd => $command,
  id => $id,
  config => $config,
  status => $status,
);

$proc->run_stop();
is( (-d "/tmp/$config->{room}/$date" ),1 ,"Record path created when not defined" );
remove_tree( "/tmp/$config->{room}" );
isnt( ( -d "/tmp/$config->{room}" ),1 ,"Temp Record Path Removed" );

# TODO: need to think accessors/setters/getters;
$status->{$id}{date} = strftime "%Y%m%d", localtime(time-86400);
$proc->run_stop();
is( (-d "/tmp/$config->{room}/$date" ),1 ,"Record path created on date change" );

$proc->stop();

remove_tree( "/tmp/$config->{room}" );
isnt( ( -d "/tmp/$config->{room}" ),1 ,"Temp Record Path Removed" );
unlink('/tmp/config.json');
isnt( ( -e "/tmp/config.json" ),1 ,"Temp Config Removed" );
