#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::More 0.88;
use Test::Deep 'cmp_set';
use File::Slurper;
use JSON;
use DBI;

my $program   = "$^X -Ilib bin/benchmarkanything-storage";

# my $cfgfile   = "t/benchmarkanything-mysql.cfg";
# my $dsn       = 'DBI:mysql:database=benchmarkanythingtest';
my $cfgfile   = "t/benchmarkanything.cfg";
my $dsn       = 'dbi:SQLite:t/benchmarkanything.sqlite';

$ENV{BENCHMARKANYTHING_CONFIGFILE} = $cfgfile;

my $infile;
my $input_json;
my $input;
my $inquery_file;
my $output_json;
my $output;
my $expected_json;
my $expected;
my $output_flat;

sub command {
        my ($cmd) = @_;
        # diag "\nexecute: $cmd";
        my $output = `$cmd`;
        return $output;
}

sub verify {
        my ($input_json, $output_json, $fields, $query_file) = @_;

        require File::Basename;
        my $basename = File::Basename::basename($query_file, ".json");

        my $input  = JSON::decode_json($input_json);
        my $output = JSON::decode_json($output_json);

        for (my $i=0; $i < @$input; $i++) {
                my $got      = $output->[$i];
                my $expected = $input->[$i];
                foreach my $field (@$fields) {
                        is($got->{$field},  $expected->{$field},  "$basename - re-found [$i].$field = $expected->{$field}");
                        # diag "got = ".Dumper($got);
                }
        }
}

# Search for benchmarks, verify against expectation
sub query_and_verify {
        my ($query_file, $expectation_file, $fields) = @_;

        my $output_json   = command "$program search $query_file";
        my $expected_json = File::Slurper::read_text($expectation_file);
        verify($expected_json, $output_json, $fields, $query_file);
}

diag "\nUsing DSN: '$dsn'";

diag "\n========== Test typical queries ==========";

# Create and fill test DB
command "$program createdb --really $dsn";
command "$program add      t/valid-benchmark-anything-data-01.json";

# Search for benchmarks, verify against expectation
query_and_verify("t/query-benchmark-anything-01.json",
                 "t/query-benchmark-anything-01-expectedresult.json",
                 [qw(NAME VALUE)]
                );
query_and_verify("t/query-benchmark-anything-02.json",
                 "t/query-benchmark-anything-02-expectedresult.json",
                 [qw(NAME VALUE comment compiler keyword)]
                );
query_and_verify("t/query-benchmark-anything-03.json",
                 "t/query-benchmark-anything-03-expectedresult.json",
                 [qw(NAME VALUE comment compiler keyword)]
                );


diag "\n========== Test duplicate handling ==========";

# Create and fill test DB
command "$program createdb --really $dsn";
# Create duplicates
command "$program add      t/valid-benchmark-anything-data-01.json";
command "$program add      t/valid-benchmark-anything-data-01.json";

query_and_verify("t/query-benchmark-anything-04.json",
                 "t/query-benchmark-anything-04-expectedresult.json",
                 [qw(NAME VALUE comment compiler keyword)]
                );


diag "\n========== Metric names ==========";

command "$program createdb --really $dsn";
command "$program add      t/valid-benchmark-anything-data-02.json";

# simple list

$output_json = command "$program listnames";
$output      = JSON::decode_json($output_json);
is(scalar @$output, 5, "expected count of metrics");
cmp_set($output,
        [qw(benchmarkanything.test.metric.1
            benchmarkanything.test.metric.2
            benchmarkanything.test.metric.3
            another.benchmarkanything.test.metric.1
            another.benchmarkanything.test.metric.2
          )],
        "re-found metric names");

# list with search pattern
$output_json = command "$program listnames --pattern 'another%'";
$output      = JSON::decode_json($output_json);
is(scalar @$output, 2, "expected count of other metrics");
cmp_set($output,
        [qw(another.benchmarkanything.test.metric.1
            another.benchmarkanything.test.metric.2
          )],
        "re-found other metric names");

# list with search pattern
$output_json = command "$program listnames --pattern 'benchmarkanything%'";
$output      = JSON::decode_json($output_json);
is(scalar @$output, 3, "expected count of yet another metrics");
cmp_set($output,
        [qw(benchmarkanything.test.metric.1
            benchmarkanything.test.metric.2
            benchmarkanything.test.metric.3
          )],
        "re-found yet another metric names");


diag "\n========== Additional key names ==========";

command "$program createdb --really $dsn";
command "$program add      t/valid-benchmark-anything-data-02.json";

# simple list
$output_json = command "$program listkeys";
$output      = JSON::decode_json($output_json);
is(scalar @$output, 3, "expected count of additional key names");
cmp_set($output, [qw(comment compiler keyword )], "re-found additional key names");

# list with search pattern
$output_json = command "$program listkeys --pattern 'com%'";
$output      = JSON::decode_json($output_json);
is(scalar @$output, 2, "expected count of other additional key names");
cmp_set($output, [qw(comment compiler)], "re-found other additional key names");

# list with search pattern
$output_json = command "$program listkeys --pattern '%wor%'";
$output      = JSON::decode_json($output_json);
is(scalar @$output, 1, "expected count of yet another additional key names");
cmp_set($output, [qw( keyword)], "re-found yet another additional key names");


diag "\n========== Complete single data points ==========";

# Create and fill test DB
command "$program createdb --really $dsn";
command "$program add      t/valid-benchmark-anything-data-02.json";

# full data point
$output_json = command "$program search --id 2";
$output      = JSON::decode_json($output_json);
cmp_set([keys %$output], [qw(NAME VALUE VALUE_ID CREATED comment compiler keyword)], "search ID - expected key/value pairs");

$expected    = JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-02.json'));
eq_hash($output, $expected->{BenchmarkAnythingData}[1], "search ID - expected key/value");


diag "\n========== Output formats ==========";

# Create and fill test DB
command "$program createdb --really $dsn";
command "$program add      t/valid-benchmark-anything-data-01.json";

# flat - single result
$output_flat = command "$program search --id 2 -o flat --fb --fi";
like($output_flat, qr/^0:\[/ms,                              "expected line - line start");
like($output_flat, qr/\]$/ms,                                "expected line - line end");
like($output_flat, qr/keyword=zomtec/ms,                     "expected line - key/value 1");
like($output_flat, qr/NAME=benchmarkanything.test.metric/ms, "expected line - key/value 2");
like($output_flat, qr/VALUE=34.56789/ms,                     "expected line - key/value 3");
like($output_flat, qr/comment=another float value/ms,        "expected line - key/value 5");
like($output_flat, qr/compiler=icc/ms,                       "expected line - key/value 6");
# diag "\n";
# diag $output_flat;

# flat - multi result
$output_flat = command "$program search -o flat --fb --fi t/query-benchmark-anything-03.json";
like($output_flat, qr/^0:\[.*^1:\[.*^2:\[.*^3:\[/ms,         "expected multi line - 4 entries");
unlike($output_flat, qr/^4/ms,                               "expected multi line - not 5 entries");
# diag "\n";
# diag $output_flat;

diag "\n========== Stats ==========";

# Create and fill test DB
command "$program createdb --really $dsn";
command "$program add      t/valid-benchmark-anything-data-02.json";

# full data point
$output_json = command "$program stats -v";
$output      = JSON::decode_json($output_json);
is($output->{count_datapoints}, 8, "stats - count data points");
# is($output->{count_metrics},    5, "stats - count metrics");
# is($output->{count_keys},       3, "stats - count keys");

# Finish
done_testing;
