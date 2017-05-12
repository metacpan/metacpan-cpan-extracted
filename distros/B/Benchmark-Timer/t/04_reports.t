use strict;
use Test::More tests => 10;
use Benchmark::Timer;

# ------------------------------------------------------------------------
# Basic tests of the Benchmark::Timer library.

my $t = Benchmark::Timer->new;

my ($report, %reports);

$t->start('tag1');
$t->stop;

#1
ok(1, 'Start/stop a tag');

$report = $t->report;

#2
like($report, qr/^1 trial of tag1 \(.* total\)\n$/,
  'Single timing report');

$t->start('tag1');
$t->stop;

$report = $t->report;

#3
like($report, qr/^2 trials of tag1 \(.* total\), .*\/trial\n$/,
  'Multiple timing report');

$report = $t->reports;

#4
like($report, qr/^2 trials of tag1 \(.* total\), .*\/trial\n$/,
  'Multiple timing report--scalar');

%reports = $t->reports;

#4
is(scalar keys %reports, 1,
  'Multiple timing report--hash');

$t->start('tag2');
$t->stop;

$report = $t->report;

#6
like($report, qr/^1 trial of tag2 \(.* total\)\n$/,
  'Single timing report--last tag used');

$report = $t->reports;

#7
like($report, qr/^2 trials of tag1 \(.* total\), .*\/trial\n1 trial of tag2 \(.* total\)\n$/,
  'Multiple timing report--scalar');

%reports = $t->reports;

#8
is(scalar keys %reports, 2,
  'Multiple timing report--hash');

#9
like($reports{'tag1'}, qr/^2 trials of tag1 \(.* total\), .*\/trial\n$/,
  'Multiple timing report--hash element 1');

#10
like($reports{'tag2'}, qr/^1 trial of tag2 \(.* total\)\n$/,
  'Multiple timing report--hash element 2');

