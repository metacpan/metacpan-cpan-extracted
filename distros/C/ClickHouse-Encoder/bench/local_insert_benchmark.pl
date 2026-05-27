#!/usr/bin/env perl
# Benchmark inserting N rows through `clickhouse-local` (no server required).
# Compares Native (binary) format produced by ClickHouse::Encoder against
# TabSeparated (TSV) produced by plain Perl. Includes the time to build the
# arrayref-of-arrayrefs and to serialize it.
#
# Usage:
#   perl bench/local_insert_benchmark.pl              # 500_000 rows
#   ROWS=2_000_000 perl bench/local_insert_benchmark.pl
#   CH_LOCAL=clickhouse-local perl bench/local_insert_benchmark.pl

use strict;
use warnings;
use Time::HiRes qw(time);
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

my $ROWS    = $ENV{ROWS} || 500_000;
my $CH      = $ENV{CH_LOCAL} // 'clickhouse-local';
my $RUNS    = $ENV{RUNS} || 3;

unless (system("$CH --query 'select 1' >/dev/null 2>&1") == 0) {
    die "clickhouse-local not found (set CH_LOCAL=...)\n";
}

print "=" x 70, "\n";
print "clickhouse-local INSERT benchmark: Native vs TabSeparated\n";
print "Rows: $ROWS, runs: $RUNS\n";
print "=" x 70, "\n\n";

# ---- 1. Generate input: arrayref-of-arrayrefs ----------------------------

print "Generating $ROWS rows...\n";
my $t0 = time();
my @rows;
for my $i (1 .. $ROWS) {
    push @rows, [
        $i,
        "user_$i",
        ['perl', 'clickhouse', "tag$i"],
        rand() * 1000,
        1700_000_000 + $i,
    ];
}
my $gen_time = time() - $t0;
printf "  data generation: %.3f s (%.0f rows/s)\n\n", $gen_time, $ROWS / $gen_time;

my $structure =
    'id UInt64, user String, tags Array(String), score Float64, occurred DateTime';

# ---- 2. Encode: Native ---------------------------------------------------

print "Encoding Native...\n";
my $enc = ClickHouse::Encoder->new(columns => [
    ['id',       'UInt64'],
    ['user',     'String'],
    ['tags',     'Array(String)'],
    ['score',    'Float64'],
    ['occurred', 'DateTime'],
]);

$t0 = time();
my $native = $enc->encode(\@rows);
my $enc_native_time = time() - $t0;
printf "  encode: %.3f s (%.0f rows/s); size=%.2f MB\n\n",
    $enc_native_time, $ROWS / $enc_native_time, length($native) / 1024 / 1024;

# ---- 3. Encode: TSV (plain Perl) -----------------------------------------

print "Encoding TabSeparated...\n";
$t0 = time();
my $tsv = '';
for my $r (@rows) {
    my @cols = ($r->[0], $r->[1], '[' . join(',', map { "'$_'" } @{$r->[2]}) . ']',
                $r->[3], $r->[4]);
    # bare-bones escape (no tabs/newlines in our generated data)
    $tsv .= join("\t", @cols) . "\n";
}
my $enc_tsv_time = time() - $t0;
printf "  encode: %.3f s (%.0f rows/s); size=%.2f MB\n\n",
    $enc_tsv_time, $ROWS / $enc_tsv_time, length($tsv) / 1024 / 1024;

# ---- 4. Run via clickhouse-local -----------------------------------------

sub bench_local {
    my ($label, $data, $input_format, $runs) = @_;
    my @times;
    for (1 .. $runs) {
        my $t0 = time();
        open my $fh, '|-', $CH,
            '--structure',    $structure,
            '--input-format', $input_format,
            '--query',        'select count() from table format Null'
            or die "clickhouse-local: $!";
        binmode $fh;
        print $fh $data;
        close $fh
            or die "$label run failed (exit ${\ ($? >> 8)})\n";
        push @times, time() - $t0;
    }
    return @times;
}

sub stats { my $sum = 0; $sum += $_ for @_; my @s = sort { $a <=> $b } @_;
            return ($sum / @_, $s[0], $s[-1]) }

print "Warming up...\n";
bench_local('warmup native', $native, 'Native', 1);
bench_local('warmup tsv',    $tsv,    'TabSeparated', 1);

print "\nRunning Native ($RUNS runs)...\n";
my @nrun = bench_local('Native', $native, 'Native', $RUNS);
printf "  run: %.3f s\n", $_ for @nrun;

print "\nRunning TabSeparated ($RUNS runs)...\n";
my @trun = bench_local('TabSeparated', $tsv, 'TabSeparated', $RUNS);
printf "  run: %.3f s\n", $_ for @trun;

# ---- 5. Report ------------------------------------------------------------

my ($n_avg, $n_min, $n_max) = stats(@nrun);
my ($t_avg, $t_min, $t_max) = stats(@trun);

print "\n", "=" x 70, "\n";
print "Results: $ROWS rows through clickhouse-local\n";
print "=" x 70, "\n\n";

printf "Native:\n";
printf "  prep (encode):     %.3f s\n", $enc_native_time;
printf "  ingest (best):     %.3f s   (%.0f rows/s, %.1f MB/s)\n",
    $n_min, $ROWS / $n_min, length($native) / $n_min / 1024 / 1024;
printf "  ingest (avg):      %.3f s   (%.0f rows/s)\n",
    $n_avg, $ROWS / $n_avg;
printf "  end-to-end (prep + best ingest): %.3f s   (%.0f rows/s)\n",
    $enc_native_time + $n_min, $ROWS / ($enc_native_time + $n_min);

printf "\nTabSeparated:\n";
printf "  prep (encode):     %.3f s\n", $enc_tsv_time;
printf "  ingest (best):     %.3f s   (%.0f rows/s, %.1f MB/s)\n",
    $t_min, $ROWS / $t_min, length($tsv) / $t_min / 1024 / 1024;
printf "  ingest (avg):      %.3f s   (%.0f rows/s)\n",
    $t_avg, $ROWS / $t_avg;
printf "  end-to-end (prep + best ingest): %.3f s   (%.0f rows/s)\n",
    $enc_tsv_time + $t_min, $ROWS / ($enc_tsv_time + $t_min);

printf "\nNative is %.2fx faster end-to-end.\n",
    ($enc_tsv_time + $t_min) / ($enc_native_time + $n_min);
printf "Native payload is %.0f%% smaller.\n",
    (1 - length($native) / length($tsv)) * 100;
