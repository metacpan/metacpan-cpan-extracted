#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

my $ROWS = $ENV{ROWS} // 100_000;
my $ITERATIONS = $ENV{ITERS} // 5;
my $PORT = $ENV{CH_PORT} // 9000;

# Check if ClickHouse is available
my $ch_ok = system("clickhouse-client --port $PORT --query 'select 1' >/dev/null 2>&1") == 0;
die "ClickHouse not available on port $PORT\n" unless $ch_ok;

print "=" x 60, "\n";
print "ClickHouse Insert Benchmark: Native vs CSV\n";
print "=" x 60, "\n\n";
print "Rows per batch: $ROWS\n";
print "Iterations: $ITERATIONS\n";
print "ClickHouse port: $PORT\n\n";

# Generate test data
print "Generating test data...\n";
my @data;
for my $i (1 .. $ROWS) {
    push @data, [
        $i,
        int(rand(1_000_000_000)),
        rand() * 1000,
        "string_value_$i" . ("x" x 20),
    ];
}

# Setup encoder
my $encoder = ClickHouse::Encoder->new(
    columns => [
        ['id',     'UInt32'],
        ['bignum', 'UInt64'],
        ['value',  'Float64'],
        ['name',   'String'],
    ],
);

# Pre-encode data
print "Pre-encoding data...\n";

my $t0 = time();
my $native_data = $encoder->encode(\@data);
my $native_encode_time = time() - $t0;

$t0 = time();
my $csv_data = '';
for my $row (@data) {
    $csv_data .= join("\t", @$row) . "\n";
}
my $csv_encode_time = time() - $t0;

printf "\nEncoding times:\n";
printf "  Native: %.3f sec (%.0f rows/sec)\n", $native_encode_time, $ROWS / $native_encode_time;
printf "  CSV:    %.3f sec (%.0f rows/sec)\n", $csv_encode_time, $ROWS / $csv_encode_time;
printf "\nData sizes:\n";
printf "  Native: %d bytes (%.2f MB)\n", length($native_data), length($native_data) / 1024 / 1024;
printf "  CSV:    %d bytes (%.2f MB)\n", length($csv_data), length($csv_data) / 1024 / 1024;

# Create test table
print "\nSetting up test table...\n";
system("clickhouse-client --port $PORT --query 'drop table if exists bench_native'");
system("clickhouse-client --port $PORT --query 'drop table if exists bench_csv'");
system("clickhouse-client --port $PORT --query 'create table bench_native (id UInt32, bignum UInt64, value Float64, name String) engine = Null'");
system("clickhouse-client --port $PORT --query 'create table bench_csv (id UInt32, bignum UInt64, value Float64, name String) engine = Null'");

# Benchmark function
sub bench_insert {
    my ($table, $format, $data, $iterations) = @_;
    my @times;

    for my $i (1 .. $iterations) {
        my $t0 = time();
        open my $fh, '|-', "clickhouse-client --port $PORT --query 'insert into $table format $format' 2>/dev/null"
            or die "Cannot run clickhouse-client: $!";
        binmode $fh;
        print $fh $data;
        close $fh;
        my $elapsed = time() - $t0;
        push @times, $elapsed;
    }

    return @times;
}

print "\n", "=" x 60, "\n";
print "INSERT Benchmark (into Null engine - measures parsing speed)\n";
print "=" x 60, "\n\n";

# Warmup
print "Warming up...\n";
bench_insert('bench_native', 'Native', $native_data, 1);
bench_insert('bench_csv', 'TabSeparated', $csv_data, 1);

# Benchmark Native
print "Benchmarking Native format...\n";
my @native_times = bench_insert('bench_native', 'Native', $native_data, $ITERATIONS);

# Benchmark CSV
print "Benchmarking TabSeparated (CSV) format...\n";
my @csv_times = bench_insert('bench_csv', 'TabSeparated', $csv_data, $ITERATIONS);

# Calculate statistics
sub stats {
    my @times = @_;
    my $sum = 0;
    $sum += $_ for @times;
    my $avg = $sum / @times;
    my $min = (sort { $a <=> $b } @times)[0];
    my $max = (sort { $a <=> $b } @times)[-1];
    return ($avg, $min, $max);
}

my ($native_avg, $native_min, $native_max) = stats(@native_times);
my ($csv_avg, $csv_min, $csv_max) = stats(@csv_times);

print "\n", "-" x 60, "\n";
print "Results (seconds per $ROWS rows):\n";
print "-" x 60, "\n\n";

printf "Native format:\n";
printf "  avg: %.4f sec  min: %.4f  max: %.4f\n", $native_avg, $native_min, $native_max;
printf "  throughput: %.0f rows/sec, %.2f MB/sec\n",
    $ROWS / $native_avg,
    length($native_data) / $native_avg / 1024 / 1024;

printf "\nTabSeparated (CSV) format:\n";
printf "  avg: %.4f sec  min: %.4f  max: %.4f\n", $csv_avg, $csv_min, $csv_max;
printf "  throughput: %.0f rows/sec, %.2f MB/sec\n",
    $ROWS / $csv_avg,
    length($csv_data) / $csv_avg / 1024 / 1024;

my $speedup = $csv_avg / $native_avg;
printf "\n", "=" x 60, "\n";
printf "Native is %.2fx faster than CSV for ClickHouse INSERT\n", $speedup;
print "=" x 60, "\n";

# Now test with real table (MergeTree) to include write overhead
print "\n\nBonus: Testing with MergeTree engine (includes disk I/O)...\n";

system("clickhouse-client --port $PORT --query 'drop table if exists bench_real'");
system("clickhouse-client --port $PORT --query 'create table bench_real (id UInt32, bignum UInt64, value Float64, name String) engine = MergeTree order by id'");

my @real_native = bench_insert('bench_real', 'Native', $native_data, 3);
system("clickhouse-client --port $PORT --query 'truncate table bench_real'");
my @real_csv = bench_insert('bench_real', 'TabSeparated', $csv_data, 3);

my ($real_native_avg) = stats(@real_native);
my ($real_csv_avg) = stats(@real_csv);

printf "\nMergeTree results:\n";
printf "  Native: %.4f sec (%.0f rows/sec)\n", $real_native_avg, $ROWS / $real_native_avg;
printf "  CSV:    %.4f sec (%.0f rows/sec)\n", $real_csv_avg, $ROWS / $real_csv_avg;
printf "  Speedup: %.2fx\n", $real_csv_avg / $real_native_avg;

# Cleanup
system("clickhouse-client --port $PORT --query 'drop table if exists bench_native'");
system("clickhouse-client --port $PORT --query 'drop table if exists bench_csv'");
system("clickhouse-client --port $PORT --query 'drop table if exists bench_real'");

print "\nDone.\n";
