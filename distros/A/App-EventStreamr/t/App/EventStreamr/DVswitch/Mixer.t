#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use Test::More;
use App::EventStreamr::DVswitch::Mixer;
use App::EventStreamr::Status;
use App::EventStreamr::Config;
use Test::App::EventStreamr::ProcessTest;

# Added 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $status = App::EventStreamr::Status->new();

open(my $fh, '>', '/tmp/config.json');
print $fh '{"run" : "1", "control" : { "dvswitch" : { "run" : "1" } }, "mixer" : { "host" : "127.0.0.1", "port" : "1234" }}';
close $fh;

my $config = App::EventStreamr::Config->new(
  config_path => '/tmp',
);

my $proc = App::EventStreamr::DVswitch::Mixer->new(
  config => $config,
  status => $status,
);

SKIP: {
  skip "DVswitch not installed", 5, unless ( -e "/usr/bin/dvswitch" );
  Test::App::EventStreamr::ProcessTest->new(
    process => $proc,
    config => $config,
    id => 'dvswitch',
  )->run_tests();
}

unlink('/tmp/config.json');

done_testing();
