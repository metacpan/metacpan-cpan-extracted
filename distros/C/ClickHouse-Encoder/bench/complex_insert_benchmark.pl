#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use JSON::PP;

my $ROWS = $ENV{ROWS} // 50_000;
my $ITERATIONS = $ENV{ITERS} // 3;
my $PORT = $ENV{CH_PORT} // 9000;

# Check if ClickHouse is available
my $ch_ok = system("clickhouse-client --port $PORT --query 'select 1' >/dev/null 2>&1") == 0;
die "ClickHouse not available on port $PORT\n" unless $ch_ok;

print "=" x 60, "\n";
print "ClickHouse Complex Types Insert Benchmark\n";
print "=" x 60, "\n\n";
print "Rows per batch: $ROWS\n";
print "Iterations: $ITERATIONS\n\n";

# Generate test data with arrays and tuples
print "Generating test data with Arrays and Tuples...\n";
my @data;
for my $i (1 .. $ROWS) {
    push @data, [
        $i,
        "user_$i",
        ["tag1_$i", "tag2_$i", "tag3_$i"],  # Array(String)
        [$i * 1.5, $i * 2.5],                # Tuple(Float64, Float64)
        ($i % 3 == 0 ? undef : $i * 100),    # Nullable(UInt64)
    ];
}

# Setup encoder
my $encoder = ClickHouse::Encoder->new(
    columns => [
        ['id',       'UInt32'],
        ['name',     'String'],
        ['tags',     'Array(String)'],
        ['coords',   'Tuple(Float64, Float64)'],
        ['optional', 'Nullable(UInt64)'],
    ],
);

# Pre-encode native
print "Encoding Native format...\n";
my $t0 = time();
my $native_data = $encoder->encode(\@data);
my $native_encode_time = time() - $t0;

# Pre-encode JSON (for JSONEachRow format)
print "Encoding JSON format...\n";
$t0 = time();
my $json_data = '';
my $json = JSON::PP->new->utf8;
for my $row (@data) {
    my %obj = (
        id       => $row->[0],
        name     => $row->[1],
        tags     => $row->[2],
        coords   => $row->[3],
        optional => $row->[4],
    );
    $json_data .= $json->encode(\%obj) . "\n";
}
my $json_encode_time = time() - $t0;

printf "\nEncoding times:\n";
printf "  Native: %.3f sec (%.0f rows/sec)\n", $native_encode_time, $ROWS / $native_encode_time;
printf "  JSON:   %.3f sec (%.0f rows/sec)\n", $json_encode_time, $ROWS / $json_encode_time;
printf "  Native encoding is %.1fx faster\n", $json_encode_time / $native_encode_time;

printf "\nData sizes:\n";
printf "  Native: %d bytes (%.2f MB)\n", length($native_data), length($native_data) / 1024 / 1024;
printf "  JSON:   %d bytes (%.2f MB)\n", length($json_data), length($json_data) / 1024 / 1024;
printf "  Native is %.0f%% smaller\n", (1 - length($native_data) / length($json_data)) * 100;

# Create test table
print "\nSetting up test table...\n";
system("clickhouse-client --port $PORT --query 'drop table if exists bench_complex'");
system("clickhouse-client --port $PORT --query 'create table bench_complex (
    id UInt32,
    name String,
    tags Array(String),
    coords Tuple(Float64, Float64),
    optional Nullable(UInt64)
) engine = Null'");

# Benchmark function
sub bench_insert {
    my ($format, $data, $iterations) = @_;
    my @times;

    for my $i (1 .. $iterations) {
        my $t0 = time();
        open my $fh, '|-', "clickhouse-client --port $PORT --query 'insert into bench_complex format $format' 2>/dev/null"
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
print "INSERT Benchmark (Complex Types)\n";
print "=" x 60, "\n\n";

# Warmup
print "Warming up...\n";
bench_insert('Native', $native_data, 1);
bench_insert('JSONEachRow', $json_data, 1);

# Benchmark
print "Benchmarking Native format...\n";
my @native_times = bench_insert('Native', $native_data, $ITERATIONS);

print "Benchmarking JSONEachRow format...\n";
my @json_times = bench_insert('JSONEachRow', $json_data, $ITERATIONS);

# Calculate statistics
sub stats {
    my @times = @_;
    my $sum = 0;
    $sum += $_ for @times;
    my $avg = $sum / @times;
    my $min = (sort { $a <=> $b } @times)[0];
    return ($avg, $min);
}

my ($native_avg, $native_min) = stats(@native_times);
my ($json_avg, $json_min) = stats(@json_times);

print "\n", "-" x 60, "\n";
print "Results (seconds per $ROWS rows with Arrays/Tuples/Nullable):\n";
print "-" x 60, "\n\n";

printf "Native format:\n";
printf "  avg: %.4f sec, min: %.4f sec\n", $native_avg, $native_min;
printf "  throughput: %.0f rows/sec, %.2f MB/sec\n",
    $ROWS / $native_avg,
    length($native_data) / $native_avg / 1024 / 1024;

printf "\nJSONEachRow format:\n";
printf "  avg: %.4f sec, min: %.4f sec\n", $json_avg, $json_min;
printf "  throughput: %.0f rows/sec, %.2f MB/sec\n",
    $ROWS / $json_avg,
    length($json_data) / $json_avg / 1024 / 1024;

my $speedup = $json_avg / $native_avg;
print "\n", "=" x 60, "\n";
printf "Native is %.2fx faster than JSON for complex types INSERT\n", $speedup;
print "=" x 60, "\n";

# Cleanup
system("clickhouse-client --port $PORT --query 'drop table if exists bench_complex'");

print "\nDone.\n";
