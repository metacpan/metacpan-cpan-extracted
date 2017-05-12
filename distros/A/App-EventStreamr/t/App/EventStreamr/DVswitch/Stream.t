#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use Test::More;
use App::EventStreamr::DVswitch::Stream;
use App::EventStreamr::Status;
use App::EventStreamr::Config;
use Test::App::EventStreamr::ProcessTest;

# Added 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $status = App::EventStreamr::Status->new();

open(my $fh, '>', '/tmp/config.json');
print $fh '{"run" : "1", "control" : { "dvswitch" : { "run" : "1" } }, "mixer" : { "host" : "127.0.0.1", "port" : "1234" }, "stream" : { "host" : "127.0.0.1", "port" : "1111", "password" : "password++", "stream" : "TestStream" }}';
close $fh;

my $config = App::EventStreamr::Config->new(
  config_path => '/tmp',
);

my $proc = App::EventStreamr::DVswitch::Stream->new(
  config => $config,
  status => $status,
);

is($proc->cmd, 'dvsink-command -h 127.0.0.1 -p 1234 -- ffmpeg2theora - -f dv -F 25:2 --speedlevel 0 -v 4  --optimize -V 420 --soft-target -a 4 -c 1 -H 44100 --title TestStream -o - | oggfwd 127.0.0.1 1111 password++ /TestStream', "Stream Command built");

# TODO: Implement Process Testing
#SKIP: {
#  skip "DVswitch not installed", 5, unless ( -e "/usr/bin/dvswitch" );
#  Test::App::EventStreamr::ProcessTest->new(
#    process => $proc,
#    config => $config,
#    id => 'dvswitch',
#  )->run_tests();
#}

unlink('/tmp/config.json');

done_testing();
