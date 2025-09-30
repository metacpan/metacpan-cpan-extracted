#!/usr/bin/env perl

# This script gives some idea about Assert::Refute's CPU usage.
# It runs a contract consisting of like( $_, qr/.../ ) statements
#     multiple times, optionally outputting a summary of each contract
# CPU time is measured instead of wallclock time.
# See --help for more

use strict;
use warnings;
use Time::HiRes qw(clock);
use Getopt::Long;
use Assert::Refute {}, ":all";

BEGIN {
    if (Assert::Refute->VERSION < 0.05) {
        die "Assert::Refute too old, can't cope: ".Assert::Refute->VERSION;
    };
    if (Assert::Refute->VERSION < 0.10) {
        *try_refute = \&refute_these;
    };
};

my $count    = 100;
my $repeat   = 1000;
my $want_tap = 0;
my $print    = 0;
my $fail     = 0;
my $subtest  = 0;

GetOptions (
    "count=i"    => \$count,
    "repeat=i"   => \$repeat,
    "subtest=i"  => \$subtest,
    "tap!"       => \$want_tap,
    "print!"     => \$print,
    "fail!"      => \$fail,
    "help"       => \&usage,
) or die "Bad usage. See $0 --help\n";

$want_tap++ if $print;
$fail = $fail ? '-' : '';

sub usage {
    print <<"USAGE"; exit 0;
Usage: $0 [options]
Benchmark the Assert::Refute using repeated like( \$_, qr/.../ ) statements.
Time::HiRes::clock() is used to measure CPU usage as opposed to wallclock time.
Options may include:
    -c, --count   - number of refutations per contract (default 100)
    -r, --repeat  - number of contracts to execute (default 1000)
    -s, --subtest - run n bunches of <count> refutations as subtests
    -t, --tap     - format TAP report (like Test::More would)
    -p, --print   - print the report (implies -t)
    -f, --fail    - execute failing tests instead of passing ones.
    --help        - this message
USAGE
};

printf "Using Assert::Refute version %s under perl %s\n",
    Assert::Refute->VERSION, $^V;

my $contract = $subtest
    ? sub {
        subcontract "Attempt $_" => sub {
            like $_, qr/$fail\d+/ for 1 .. $count;
        } for 1 .. $subtest;
    }
    : sub {
        like $_, qr/$fail\d+/ for 1 .. $count;
    };

my $t0 = clock();
for (1 .. $repeat) {
    my $report = &try_refute( $contract ); ## no critic - avoid prototype
    my $tap = $want_tap && $report->get_tap;
    print $tap if $print;
};
my $cpu_time = clock() - $t0;

if ($subtest) {
    printf "Refuted %d*%d contracts of %d statements each in %0.3fs\n",
        $repeat, $subtest, $count, $cpu_time;
} else {
    printf "Refuted %d contracts of %d statements each in %0.3fs\n",
        $repeat, $count, $cpu_time;
};
printf "%0.0f statements per second\n",
    $repeat*$count*($subtest||1)/$cpu_time;

