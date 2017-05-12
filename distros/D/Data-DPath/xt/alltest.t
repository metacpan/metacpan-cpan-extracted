#! /usr/bin/env perl

eval "use Test::Aggregate::Nested";

if ($@) {
        use Test::More;
        plan skip_all => "Test::Aggregate::Nested required for testing aggregated";
}

use Data::DPath;
use Data::Dumper;
use Benchmark ':all', ':hireswallclock';

local $Data::DPath::USE_SAFE = 0;

BEGIN {
        print "TAP Version 13\n";
}

#DB::enable_profile();

my $tests = Test::Aggregate::Nested->new
    ({
      dirs => 't/',
     });

diag "Running benchmark. Can take some time ...";
my $count = 1;
my $t = timeit ($count, sub { $tests->run });
my $n = $t->[5];
my $throughput = $n / $t->[0];
print "  ---\n";
print "  benchmark:\n";
print "    timestr:    ".timestr($t), "\n";
print "    wallclock:  $t->[0]\n";
print "    usr:        $t->[1]\n";
print "    sys:        $t->[2]\n";
print "    throughput: $throughput\n";
print "  ...\n";
