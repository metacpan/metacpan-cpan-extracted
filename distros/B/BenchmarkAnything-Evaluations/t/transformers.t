#! /usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::More 0.88;
use Test::Deep 'cmp_deeply';
require BenchmarkAnything::Evaluations;

my $input;
my $output;
my $expected;

$input = [
          { title   => "dpath-T-n64",
            results => [
                        {NAME => "dpath", VALUE => 1000, perlconfig_version => "2.0.13"},
                        {NAME => "dpath", VALUE => 1170, perlconfig_version => "2.0.14"},
                        {NAME => "dpath", VALUE =>  660, perlconfig_version => "2.0.15"},
                        {NAME => "dpath", VALUE => 1030, perlconfig_version => "2.0.16"},
                       ],
          },
          { title   => "Mem-nT-n64",
            results => [
                        {NAME => "Mem",   VALUE =>  400, perlconfig_version => "2.0.13"},
                        {NAME => "Mem",   VALUE =>  460, perlconfig_version => "2.0.14"},
                        {NAME => "Mem",   VALUE => 1120, perlconfig_version => "2.0.15"},
                        {NAME => "Mem",   VALUE =>  540, perlconfig_version => "2.0.16"},
                       ],
          },
          { title   => "Fib-T-64",
            results => [
                        {NAME => "Fib",   VALUE => 100, perlconfig_version => "2.0.13"},
                        {NAME => "Fib",   VALUE => 100, perlconfig_version => "2.0.14"},
                        {NAME => "Fib",   VALUE => 100, perlconfig_version => "2.0.15"},
                        {NAME => "Fib",   VALUE => 200, perlconfig_version => "2.0.16"},
                       ],
          },
         ];

$expected = [
   [
      "perlconfig_version",
      "dpath-T-n64",
      "Mem-nT-n64",
      "Fib-T-64",
   ],
   [
      "2.0.13",
      1000,
      400,
      100,
   ],
   [
      "2.0.14",
      1170,
      460,
      100,
   ],
   [
      "2.0.15",
      660,
      1120,
      100,
   ],
   [
      "2.0.16",
      1030,
      540,
      200,
   ],
]
;

my $options =  {
                x_key       => "perlconfig_version",
                x_type      => "version", # version, numeric, string, date
                y_key       => "VALUE",
                y_type      => "numeric",
                aggregation => "avg", # sub entries of {stats}: avg, stdv, ci_95_lower, ci_95_upper
                verbose     => 1,
               };
diag "\n"; # align all verbose output
$output = BenchmarkAnything::Evaluations::transform_chartlines($input, $options);
cmp_deeply($output, $expected, "data transformation - google areachart");

# Finish
ok(1, "dummy");
done_testing;
