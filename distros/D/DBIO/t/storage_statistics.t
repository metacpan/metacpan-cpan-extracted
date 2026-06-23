use strict;
use warnings;
use Test::More;

use lib 't/lib';
use DBIO::Test;

my $schema = DBIO::Test->init_schema;

# --- Statistics object exists ---
my $stats = $schema->storage->debugobj;
isa_ok($stats, 'DBIO::Storage::Statistics', 'debugobj is Statistics');

# --- Initial state ---
is($stats->query_count, 0, 'query_count starts at 0');
is($stats->total_elapsed, 0, 'total_elapsed starts at 0');
is($stats->last_query_elapsed, undef, 'last_query_elapsed starts undef');

# --- Timing works without debug enabled ---
ok(!$schema->storage->debug, 'debug is off by default');

# search alone doesn't execute — need to force execution
my @rows = $schema->resultset('Artist')->search({})->all;

cmp_ok($stats->query_count, '>=', 1, 'query_count incremented after query');
cmp_ok($stats->total_elapsed, '>', 0, 'total_elapsed > 0 after query');
ok(defined $stats->last_query_elapsed, 'last_query_elapsed defined');
cmp_ok($stats->last_query_elapsed, '>', 0, 'last_query_elapsed > 0');
cmp_ok($stats->last_query_elapsed, '<=', $stats->total_elapsed,
  'last_query_elapsed <= total_elapsed');

# --- Multiple queries accumulate ---
my $count_before = $stats->query_count;
my $total_before = $stats->total_elapsed;

my @cds = $schema->resultset('CD')->search({})->all;

cmp_ok($stats->query_count, '>', $count_before, 'query_count increments');
cmp_ok($stats->total_elapsed, '>=', $total_before, 'total_elapsed accumulates');

# --- reset_stats ---
$stats->reset_stats;
is($stats->query_count, 0, 'query_count reset to 0');
is($stats->total_elapsed, 0, 'total_elapsed reset to 0');
is($stats->last_query_elapsed, undef, 'last_query_elapsed reset to undef');

# --- Elapsed output in trace ---
{
  my $trace_output = '';
  open my $fh, '>', \$trace_output;

  my $test_stats = DBIO::Storage::Statistics->new;
  $test_stats->debugfh($fh);

  $test_stats->query_start('SELECT 1', "'val'");
  # simulate a tiny delay
  $test_stats->query_end('SELECT 1', "'val'");

  like($trace_output, qr/SELECT 1/, 'trace output contains SQL');
  like($trace_output, qr/Elapsed: \d+\.\d+s/, 'trace output contains elapsed time');
  is($test_stats->query_count, 1, 'query_count incremented via direct call');
  ok(defined $test_stats->last_query_elapsed, 'last_query_elapsed set');
}

# --- No output when no bind args (debug off path) ---
{
  my $trace_output = '';
  open my $fh, '>', \$trace_output;

  my $test_stats = DBIO::Storage::Statistics->new;
  $test_stats->debugfh($fh);

  # no @bind = debug is off, timing only
  $test_stats->query_start('SELECT 1');
  $test_stats->query_end('SELECT 1');

  is($trace_output, '', 'no trace output without bind args');
  is($test_stats->query_count, 1, 'query_count still incremented');
  ok(defined $test_stats->last_query_elapsed, 'elapsed still tracked');
}

done_testing;
