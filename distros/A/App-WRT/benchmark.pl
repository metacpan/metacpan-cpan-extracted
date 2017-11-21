#!/usr/bin/perl

use Benchmark;

$script = $ARGV[0];

# declare array
my @data;

# start timer
$start = new Benchmark;

for ($x = 0; $x <= 100; $x++) {
  $output = `perl ./$script`;
}

# end timer
$end = new Benchmark;

# calculate difference
$diff = timediff($end, $start);

# report
print "Content-type: text/plain\n\n";
print "Time taken was ", timestr($diff, 'all'), " seconds";
