#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use FindBin qw($Bin);
use Test::More;
use File::Path 'remove_tree';
# Added 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

# When running during bulk testing the restart appears to fail
# works fine if given time before previous test.
sleep 5;

use App::EventStreamr::Config;
use App::EventStreamr::Status;
use App::EventStreamr::DVswitch::Mixer;
use App::EventStreamr::DVswitch::Record;
use Test::App::EventStreamr::ProcessTest;

open(my $fh, '>', '/tmp/config.json');
print $fh '{"run" : "1", "control" : { "dvsink" : { "run" : "1" } }, "mixer" : { "host" : "127.0.0.1", "port" : "1234" }, "room" : "eventstreamr", "record_path" : "/tmp/$room/$date" }';
close $fh;

my $config = App::EventStreamr::Config->new(
  config_path => '/tmp',
);

my $status = App::EventStreamr::Status->new();

my $dvswitch = App::EventStreamr::DVswitch::Mixer->new(
  config => $config,
  status => $status,
);

my $proc = App::EventStreamr::DVswitch::Record->new(
  config => $config,
  status => $status,
);


SKIP: {
  skip "DVswitch||DVsink not installed", 5, unless ( -e "/usr/bin/dvswitch" && -e "/usr/bin/dvsink-files" );
  
  $dvswitch->start();

  Test::App::EventStreamr::ProcessTest->new(
    process => $proc,
    config => $config,
    id => 'dvsink',
  )->run_tests();

  $dvswitch->stop();
  
  # Clean up after ourselves
  remove_tree( "/tmp/$config->{room}" );
}

unlink('/tmp/config.json');

done_testing();
