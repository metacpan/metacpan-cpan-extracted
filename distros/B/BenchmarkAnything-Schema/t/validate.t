use strict;
use warnings;

use Test::More 0.88;

require BenchmarkAnything::Schema;
require JSON::MaybeXS;
require JSON::Schema;
require File::Slurper;

# prefix "B.A.D." == "Benchmark Anything Data"

# valid example files
my %json_files = (
                  valid => [qw(
                                      t/valid-benchmark-anything-data-01.json
                                      t/valid-benchmark-anything-data-02.json
                                      t/valid-benchmark-anything-data-03.json
                             )
                           ],
                  invalid => [qw(
                                        t/invalid-benchmark-anything-data-01.json
                                        t/invalid-benchmark-anything-data-02.json
                                        t/invalid-benchmark-anything-data-03.json
                                        t/invalid-benchmark-anything-data-04.json
                               )
                             ],
                 );

my $reference_file = 't/valid-benchmark-anything-data-01.json';
my $reference_json = File::Slurper::read_text($reference_file);
my $reference      = JSON::MaybeXS::decode_json($reference_json);

# --- basic structure validation before applying json schema ---

is (scalar(@{$reference->{BenchmarkAnythingData}}), 3,    "intro key with correct sub entries");

is ($reference->{BenchmarkAnythingData}[0]{NAME},     "benchmarkanything.test.metric", "entry 0 - NAME");
is ($reference->{BenchmarkAnythingData}[0]{VALUE},    27.34,                           "entry 0 - VALUE");
is ($reference->{BenchmarkAnythingData}[0]{keyword},  "affe",                          "entry 0 - keyword");

is ($reference->{BenchmarkAnythingData}[1]{NAME},     "benchmarkanything.test.metric", "entry 1 - NAME");
is ($reference->{BenchmarkAnythingData}[1]{VALUE},    34.56789,                        "entry 1 - VALUE");
is ($reference->{BenchmarkAnythingData}[1]{keyword},  "zomtec",                        "entry 1 - keyword");

is ($reference->{BenchmarkAnythingData}[2]{NAME},     "benchmarkanything.test.metric", "entry 2 - NAME");
is ($reference->{BenchmarkAnythingData}[2]{VALUE},    40,                              "entry 2 - VALUE");
is ($reference->{BenchmarkAnythingData}[2]{keyword},  "birne",                         "entry 2 - keyword");

# --- json schema validation ---

foreach my $mode (qw(valid invalid)) {
        diag "validate $mode files";
        foreach my $file (@{$json_files{$mode}}) {
                my $json = File::Slurper::read_text($file);
                my %input = (
                             json => $json,
                             data => JSON::MaybeXS::decode_json($json)
                            );
                foreach my $type (qw(json data)) {
                        my $result = BenchmarkAnything::Schema::valid_json_schema($input{$type});

                        # stringify overloaded magic away for the is() function
                        my $got      = "".$result;
                        my $expected = "".($mode eq "valid" ? 1 : '');

                        is($got, $expected, "validated $mode $type against json schema: $file");

                        diag " expected validation error: $_" foreach $result->errors;
                }
        }
}

done_testing;
