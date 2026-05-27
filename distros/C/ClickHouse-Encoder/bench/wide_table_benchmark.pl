#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

my $ROWS = $ENV{ROWS} // 100_000;
my $ITERATIONS = $ENV{ITERS} // 3;
my $PORT = $ENV{CH_PORT} // 9000;

# Check if ClickHouse is available
my $ch_ok = system("clickhouse-client --port $PORT --query 'select 1' >/dev/null 2>&1") == 0;
die "ClickHouse not available on port $PORT\n" unless $ch_ok;

print "=" x 70, "\n";
print "ClickHouse Wide Table Benchmark (20 columns, $ROWS rows)\n";
print "=" x 70, "\n\n";

# Define 20 columns with mixed types
my @columns = (
    ['id',          'UInt64'],
    ['user_id',     'UInt32'],
    ['session_id',  'String'],
    ['event_type',  'UInt8'],
    ['timestamp',   'UInt64'],
    ['ip_hash',     'UInt64'],
    ['country',     'FixedString(2)'],
    ['region',      'String'],
    ['city',        'String'],
    ['lat',         'Float64'],
    ['lon',         'Float64'],
    ['device_type', 'UInt8'],
    ['os_version',  'String'],
    ['app_version', 'String'],
    ['screen_w',    'UInt16'],
    ['screen_h',    'UInt16'],
    ['duration_ms', 'UInt32'],
    ['is_premium',  'UInt8'],
    ['score',       'Float32'],
    ['metadata',    'String'],
);

my $col_defs = join(",\n    ", map { "$_->[0] $_->[1]" } @columns);

# Generate test data
print "Generating $ROWS rows with 20 columns...\n";
my $t0 = time();
my @data;
for my $i (1 .. $ROWS) {
    push @data, [
        $i,                                    # id
        int(rand(10_000_000)),                 # user_id
        sprintf("sess_%016x", int(rand(2**48))), # session_id
        int(rand(10)),                         # event_type
        int(time() * 1000) + $i,               # timestamp
        int(rand(2**32)),                      # ip_hash
        ('US', 'GB', 'DE', 'FR', 'JP')[int(rand(5))], # country
        "Region_" . int(rand(50)),             # region
        "City_" . int(rand(1000)),             # city
        37.0 + rand(10),                       # lat
        -122.0 + rand(50),                     # lon
        int(rand(4)),                          # device_type
        "1." . int(rand(100)) . "." . int(rand(10)), # os_version
        "2.0." . int(rand(50)),                # app_version
        (320, 375, 414, 768, 1024)[int(rand(5))], # screen_w
        (568, 667, 896, 1024, 1366)[int(rand(5))], # screen_h
        int(rand(300_000)),                    # duration_ms
        int(rand(2)),                          # is_premium
        rand(100),                             # score
        'meta_' . $i . '_' . int(rand(1000)),     # metadata
    ];
}
my $gen_time = time() - $t0;
printf "Data generation: %.2f sec\n\n", $gen_time;

# Setup encoder
my $encoder = ClickHouse::Encoder->new(columns => \@columns);

# Encode Native format
print "Encoding Native format...\n";
$t0 = time();
my $native_data = $encoder->encode(\@data);
my $native_encode_time = time() - $t0;

# Encode TabSeparated (CSV-like)
print "Encoding TabSeparated format...\n";
$t0 = time();
my $csv_data = '';
for my $row (@data) {
    my @escaped = map {
        my $v = $_;
        $v =~ s/\\/\\\\/g;
        $v =~ s/\t/\\t/g;
        $v =~ s/\n/\\n/g;
        $v;
    } @$row;
    $csv_data .= join("\t", @escaped) . "\n";
}
my $csv_encode_time = time() - $t0;

print "\n", "-" x 70, "\n";
print "Encoding Results\n";
print "-" x 70, "\n\n";

printf "Native format:\n";
printf "  Time:       %.3f sec\n", $native_encode_time;
printf "  Speed:      %.0f rows/sec\n", $ROWS / $native_encode_time;
printf "  Size:       %.2f MB\n", length($native_data) / 1024 / 1024;

printf "\nTabSeparated format:\n";
printf "  Time:       %.3f sec\n", $csv_encode_time;
printf "  Speed:      %.0f rows/sec\n", $ROWS / $csv_encode_time;
printf "  Size:       %.2f MB\n", length($csv_data) / 1024 / 1024;

printf "\nNative encoding is %.1fx faster\n", $csv_encode_time / $native_encode_time;
printf "Native data is %.0f%% smaller\n", (1 - length($native_data) / length($csv_data)) * 100;

# Create test table
print "\n", "=" x 70, "\n";
print "INSERT Benchmark\n";
print "=" x 70, "\n\n";

print "Setting up test table...\n";
system("clickhouse-client --port $PORT --query 'drop table if exists bench_wide'");
system("clickhouse-client --port $PORT --query 'create table bench_wide (\n    $col_defs\n) engine = Null'");

# Benchmark function
sub bench_insert {
    my ($format, $data, $iterations) = @_;
    my @times;

    for my $i (1 .. $iterations) {
        my $t0 = time();
        open my $fh, '|-', "clickhouse-client --port $PORT --query 'insert into bench_wide format $format' 2>/dev/null"
            or die "Cannot run clickhouse-client: $!";
        binmode $fh;
        print $fh $data;
        close $fh;
        my $elapsed = time() - $t0;
        push @times, $elapsed;
        printf "  Run %d: %.3f sec\n", $i, $elapsed;
    }

    return @times;
}

# Warmup
print "Warming up...\n";
bench_insert('Native', $native_data, 1);
bench_insert('TabSeparated', $csv_data, 1);

# Benchmark
print "\nBenchmarking Native format ($ITERATIONS iterations)...\n";
my @native_times = bench_insert('Native', $native_data, $ITERATIONS);

print "\nBenchmarking TabSeparated format ($ITERATIONS iterations)...\n";
my @csv_times = bench_insert('TabSeparated', $csv_data, $ITERATIONS);

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
my ($csv_avg, $csv_min) = stats(@csv_times);

print "\n", "=" x 70, "\n";
print "RESULTS: $ROWS rows x 20 columns\n";
print "=" x 70, "\n\n";

printf "Native format:\n";
printf "  Avg time:   %.3f sec\n", $native_avg;
printf "  Best time:  %.3f sec\n", $native_min;
printf "  Throughput: %.0f rows/sec\n", $ROWS / $native_avg;
printf "  Bandwidth:  %.1f MB/sec\n", length($native_data) / $native_avg / 1024 / 1024;

printf "\nTabSeparated format:\n";
printf "  Avg time:   %.3f sec\n", $csv_avg;
printf "  Best time:  %.3f sec\n", $csv_min;
printf "  Throughput: %.0f rows/sec\n", $ROWS / $csv_avg;
printf "  Bandwidth:  %.1f MB/sec\n", length($csv_data) / $csv_avg / 1024 / 1024;

my $speedup = $csv_avg / $native_avg;
print "\n", "=" x 70, "\n";
printf "Native INSERT is %.2fx faster than TabSeparated\n", $speedup;
print "=" x 70, "\n";

# Cleanup
system("clickhouse-client --port $PORT --query 'drop table if exists bench_wide'");

print "\nDone.\n";
