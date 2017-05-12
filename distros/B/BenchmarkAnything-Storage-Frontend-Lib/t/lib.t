#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::More 0.88;
use Test::Deep 'cmp_set';
use File::Slurper;
use JSON;

require BenchmarkAnything::Storage::Frontend::Lib;

# my $cfgfile   = "t/benchmarkanything-mysql.cfg";
# my $dsn       = 'DBI:mysql:database=benchmarkanythingtest';
my $cfgfile   = "t/benchmarkanything.cfg";
my $dsn       = 'dbi:SQLite:t/benchmarkanything.sqlite';

$ENV{BENCHMARKANYTHING_CONFIGFILE} = $cfgfile;

my $output_json;
my $output;
my $expected;

sub verify {
        my ($input, $output, $fields) = @_;

        for (my $i=0; $i < @$input; $i++) {
                my $got      = $output->[$i];
                my $expected = $input->[$i];
                foreach my $field (@$fields) {
                        is($got->{$field},  $expected->{$field},  "re-found [$i].$field = $expected->{$field}");
                        # diag "got = ".Dumper($got);
                }
        }
}

# Search for benchmarks, verify against expectation
sub query_and_verify {
        my ($balib, $query_file, $expectation_file, $fields) = @_;

        my $query    = JSON::decode_json(File::Slurper::read_text($query_file));
        my $expected = JSON::decode_json(File::Slurper::read_text($expectation_file));
        my $output   = $balib->search($query);
        verify($expected, $output, $fields);
}


diag "\nUsing DSN: '$dsn'";

diag "\n========== Test lib config ==========";

my $balib = BenchmarkAnything::Storage::Frontend::Lib
 ->new(really  => $dsn,
       verbose => 0,
       debug   => 0,
      )
 ->connect;
is ($balib->{config}{benchmarkanything}{storage}{backend}{sql}{dsn}, $dsn, "config - dsn");

diag "\n========== Test typical queries ==========";

# Create and fill test DB
$balib->createdb;
$balib->add (JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-01.json')));

# Search for benchmarks, verify against expectation
query_and_verify($balib,
                 "t/query-benchmark-anything-01.json",
                 "t/query-benchmark-anything-01-expectedresult.json",
                 [qw(NAME VALUE)]
                );
query_and_verify($balib,
                 "t/query-benchmark-anything-02.json",
                 "t/query-benchmark-anything-02-expectedresult.json",
                 [qw(NAME VALUE comment compiler keyword)]
                );
query_and_verify($balib,
                 "t/query-benchmark-anything-03.json",
                 "t/query-benchmark-anything-03-expectedresult.json",
                 [qw(NAME VALUE comment compiler keyword)]
                );

# diag "\n========== Test duplicate handling ==========";

# Create and fill test DB
$balib->createdb;

# Create duplicates
$balib->add (JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-01.json')));
$balib->add (JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-01.json')));

# verify
query_and_verify($balib,
                 "t/query-benchmark-anything-04.json",
                 "t/query-benchmark-anything-04-expectedresult.json",
                 [qw(NAME VALUE comment compiler keyword)]
                );


diag "\n========== Metric names ==========";

$balib->createdb;
$balib->add (JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-02.json')));

# simple list
$output = $balib->listnames;
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
$output = $balib->listnames('another%');
is(scalar @$output, 2, "expected count of other metrics");
cmp_set($output,
        [qw(another.benchmarkanything.test.metric.1
            another.benchmarkanything.test.metric.2
          )],
        "re-found other metric names");

# list with search pattern
$output = $balib->listnames ('benchmarkanything%');
is(scalar @$output, 3, "expected count of yet another metrics");
cmp_set($output,
        [qw(benchmarkanything.test.metric.1
            benchmarkanything.test.metric.2
            benchmarkanything.test.metric.3
          )],
        "re-found yet another metric names");


diag "\n========== Complete single data points ==========";

# Create and fill test DB
$balib->createdb;
$balib->add (JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-02.json')));

# full data point
$output = $balib->getpoint (2);
cmp_set([keys %$output], [qw(NAME VALUE VALUE_ID CREATED comment compiler keyword)], "getpoint - expected key/value pairs");

$expected    = JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-02.json'));
eq_hash($output, $expected->{BenchmarkAnythingData}[1], "getpoint - expected key/value");


diag "\n========== Internals: additional keys ==========";

$balib->createdb;
$balib->add (JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-02.json')));
my $id1 = $balib->_get_additional_key_id ('keyword');
my $id2 = $balib->_get_additional_key_id ('comment');
my $id3 = $balib->_get_additional_key_id ('compiler');
# We don't know their storage order
ok(($id1 >= 1), "got meaningful id ($id1) for additional key1");
ok(($id2 >= 1), "got meaningful id ($id2) for additional key2");
ok(($id3 >= 1), "got meaningful id ($id3) for additional key3");
ok(($id1 != $id2), "id_key1 != id_key2");
ok(($id1 != $id3), "id_key1 != id_key3");
ok(($id2 != $id3), "id_key2 != id_key3");

my $keys = $balib->_default_additional_keys;
cmp_set([keys %$keys], [qw(NAME VALUE UNIT VALUE_ID CREATED)], "default additional keys");


diag "\n========== Internals: operators ==========";

$balib->createdb;
$balib->add (JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-02.json')));
my $operators = $balib->_get_benchmark_operators;
cmp_set($operators, [ '=', '!=', 'like', 'not like', '<', '>', '<=', '>=' ], "get benchmark operators");

diag "\n========== Stats ==========";

$balib->createdb;
$balib->add (JSON::decode_json(File::Slurper::read_text('t/valid-benchmark-anything-data-02.json')));

# simple counts
$output = $balib->stats;
is($output->{count_datapointkeys},  18, "stats - count data point keys");
is($output->{count_datapoints},      8, "stats - count data points");
is($output->{count_metrics},         5, "stats - count metrics");
is($output->{count_keys},            3, "stats - count keys");

# Finish
done_testing;
