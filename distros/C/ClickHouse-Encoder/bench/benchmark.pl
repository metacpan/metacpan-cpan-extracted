#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);
use Text::CSV_XS;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

my $ROWS = $ENV{ROWS} // 10_000;

print "Generating $ROWS rows of test data...\n";

my @data;
for my $i (1 .. $ROWS) {
    push @data, [
        $i,
        int(rand(1_000_000)),
        rand() * 1000,
        "string_value_$i",
        "fixed_str",
    ];
}

print "Columns: UInt32, UInt64, Float64, String, FixedString(16)\n";
print "Rows: $ROWS\n\n";

my $encoder = ClickHouse::Encoder->new(
    columns => [
        ['id',     'UInt32'],
        ['bignum', 'UInt64'],
        ['value',  'Float64'],
        ['name',   'String'],
        ['code',   'FixedString(16)'],
    ],
);

my $csv = Text::CSV_XS->new({ binary => 1, eol => "\n" });

# Verify both work
my $ch_out = $encoder->encode(\@data);
my $csv_out = '';
open my $fh, '>:raw', \$csv_out;
$csv->print($fh, $_) for @data;
close $fh;

printf "Output sizes: ClickHouse=%d bytes, CSV=%d bytes\n\n",
    length($ch_out), length($csv_out);

print "Benchmarking...\n\n";

cmpthese(-3, {
    'ClickHouse::Encoder' => sub {
        my $out = $encoder->encode(\@data);
    },
    'Text::CSV_XS' => sub {
        my $out = '';
        open my $fh, '>:raw', \$out;
        $csv->print($fh, $_) for @data;
        close $fh;
    },
});

print "\n--- With Arrays and Tuples (ClickHouse only) ---\n\n";

my @complex_data;
for my $i (1 .. $ROWS) {
    push @complex_data, [
        $i,
        ["tag_$i", "label_$i", "cat_$i"],
        [$i * 1.5, $i * 2.5],
    ];
}

my $complex_encoder = ClickHouse::Encoder->new(
    columns => [
        ['id',    'UInt32'],
        ['tags',  'Array(String)'],
        ['point', 'Tuple(Float64, Float64)'],
    ],
);

my $complex_out = $complex_encoder->encode(\@complex_data);
printf "Complex data output: %d bytes\n", length($complex_out);

my $result = timethese(-3, {
    'ClickHouse (complex)' => sub {
        my $out = $complex_encoder->encode(\@complex_data);
    },
});

print "\n";
