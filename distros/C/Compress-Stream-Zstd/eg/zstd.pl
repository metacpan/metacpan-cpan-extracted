#!/usr/bin/env perl
use strict;
use warnings;

use Compress::Stream::Zstd qw(ZSTD_MAX_CLEVEL);
use Compress::Stream::Zstd::Compressor qw(ZSTD_CSTREAM_IN_SIZE);
use Compress::Stream::Zstd::Decompressor qw(ZSTD_DSTREAM_IN_SIZE);

my ($decompress) = grep { $_ eq '-d' } @ARGV;
my ($level) = map { s/^-//; $_ } grep { /^-[0-9]+$/ } @ARGV;
$level = 3 if !$level || $level < 1 || $level > ZSTD_MAX_CLEVEL;

binmode $_ for (*STDIN, *STDOUT);

if ($decompress) {
    my $decompressor = Compress::Stream::Zstd::Decompressor->new;
    while (read(*STDIN, my $buffer, ZSTD_DSTREAM_IN_SIZE)) {
        print STDOUT $decompressor->decompress($buffer);
    }
} else {
    my $compressor = Compress::Stream::Zstd::Compressor->new($level);
    while (read(*STDIN, my $buffer, ZSTD_CSTREAM_IN_SIZE)) {
        print STDOUT $compressor->compress($buffer);
    }
    print STDOUT $compressor->end;
}

__END__
