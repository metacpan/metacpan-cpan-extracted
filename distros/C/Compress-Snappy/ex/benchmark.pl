#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw(timethese);
use Getopt::Long qw(GetOptions :config no_ignore_case);
use List::Util qw(max);

use Compress::Bzip2  ();
use Compress::LZ4    ();
use Compress::LZF    ();
use Compress::Snappy ();
use Compress::Zlib   ();

my %opts = (
    iterations => -1,
    size       => 10,  # kB
);
GetOptions(\%opts, 'iterations|i=i', 'size|s=f',);

my $data = join '', ('A'..'Z', 'a'..'z', 0..9, qw(_ .)) x (16 * $opts{size});

my %compress = (
    'Compress::Bzip2::compress'  => sub { Compress::Bzip2::compress($data) },
    'Compress::LZ4::compress'    => sub { Compress::LZ4::compress($data) },
    'Compress::LZF::compress'    => sub { Compress::LZF::compress($data) },
    'Compress::Snappy::compress' => sub { Compress::Snappy::compress($data) },
    'Compress::Zlib::compress'   => sub { Compress::Zlib::compress($data) },
);

my $bzip2  = Compress::Bzip2::compress($data);
my $lz4    = Compress::LZ4::compress($data);
my $lzf    = Compress::LZF::compress($data);
my $snappy = Compress::Snappy::compress($data);
my $zlib   = Compress::Zlib::compress($data);

my %compression_ratios = (
    'Compress::Bzip2::compress'  => length($bzip2) / length($data),
    'Compress::LZ4::compress'    => length($lz4) / length($data),
    'Compress::LZF::compress'    => length($lzf) / length($data),
    'Compress::Snappy::compress' => length($snappy) / length($data),
    'Compress::Zlib::compress'   => length($zlib) / length($data),
);

my %decompress = (
    'Compress::Bzip2::decompress' =>
        sub { Compress::Bzip2::decompress($bzip2) },
    'Compress::LZ4::decompress' => sub { Compress::LZ4::decompress($lz4) },
    'Compress::LZF::decompress' => sub { Compress::LZF::decompress($lzf) },
    'Compress::Snappy::decompress' =>
        sub { Compress::Snappy::decompress($snappy) },
    'Compress::Zlib::uncompress' => sub { Compress::Zlib::uncompress($zlib) },
);

run(\%compress, 'Compressible', 'compression', \%compression_ratios);
print "\n";
run(\%decompress, 'Compressible', 'decompression');
print "\n";

# Make a string of random bytes.
$data = join '', map { chr int rand(256) } (1 .. $opts{size});
# Compress it just to make sure.
$data = Compress::Bzip2::compress($data);

$bzip2  = Compress::Bzip2::compress($data);
$lz4    = Compress::LZ4::compress($data);
$lzf    = Compress::LZF::compress($data);
$snappy = Compress::Snappy::compress($data);
$zlib   = Compress::Zlib::compress($data);

%compression_ratios = (
    'Compress::Bzip2::compress'  => length($bzip2) / length($data),
    'Compress::LZ4::compress'    => length($lz4) / length($data),
    'Compress::LZF::compress'    => length($lzf) / length($data),
    'Compress::Snappy::compress' => length($snappy) / length($data),
    'Compress::Zlib::compress'   => length($zlib) / length($data),
);

run(\%compress, 'Uncompressible', 'compression', \%compression_ratios);
print "\n";
run(\%decompress, 'Uncompressible', 'decompression');

exit;


sub run {
    my ($tests, $type, $op, $c_ratios) = @_;

    my $header = sprintf '%s data (%s KiB) - %s', $type, $opts{size}, $op;
    printf "%s\n%s\n", $header, '-' x length($header);

    my $times = timethese -1, $tests, 'none';

    my @info;
    my ($max_name_len, $max_rate_len, $max_bw_len) = (0, 0, 0);
    my ($c_format, $c_ratio_sub) = ('', sub { });
    if ($c_ratios) {
        $c_format    = '  %.3f%%';
        $c_ratio_sub = sub { 100 * $c_ratios->{$_[0]} };
    }

    while (my ($name, $info) = each %$times) {
        my ($duration, $cycles) = @{$info}[ 1, 5 ];
        my $rate = sprintf '%.0f', $cycles / $duration;
        my $bw = $rate * $opts{size} / 1024;
        $bw = sprintf int $bw ? '%.0f' : '%.2f', $bw;

        push @info, [$name, $rate, $bw];

        $max_name_len = max $max_name_len, length($name);
        $max_rate_len = max $max_rate_len, length($rate);
        $max_bw_len   = max $max_bw_len,   length($bw);
    }

    for my $rec (sort { $b->[1] <=> $a->[1] } @info) {
        my ($name, $rate, $bw) = @$rec;

        my $name_padding = $max_name_len - length($name);

        printf "%s %s %${max_rate_len}s/s  %${max_bw_len}s MiB/s$c_format\n",
            $name, ' 'x$name_padding, $rate, $bw, $c_ratio_sub->($name);
    }
}
