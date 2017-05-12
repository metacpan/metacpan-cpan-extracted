#!perl

use strict;
use warnings;
use Test::More;

use AnyEvent;
use AnyEvent::Monitor::CPU;
use Proc::CPUUsage;

#
# Measure the overhead of our CPU monitor
#

## Run the test for 5 seconds
diag("Measure overhead for 5 seconds...");
my $cv    = AnyEvent->condvar;
my $timer = AnyEvent->timer(
  after => 5,
  cb    => sub {
    $cv->send;
  },
);

## Start a monitor
my $m = AnyEvent::Monitor::CPU->new(
  { cb => sub { }
  }
);

## Measure the overhead
my $cpu = Proc::CPUUsage->new;

$cpu->usage;
$cv->recv;
my $usage = $cpu->usage;

ok($usage <= .05,
  sprintf('Overhead is less than 1%% (%0.4f%%)', $usage * 100));

done_testing();
