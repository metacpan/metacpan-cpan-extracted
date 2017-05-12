#!/usr/bin/perl
use strict;
use warnings;

use ApacheLog::Compressor 0.004;
use Sys::Hostname qw(hostname);

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

my ($in, $out) = @ARGV;
die "No input file provided" unless defined $in && length $in;
die "No output file provided" unless defined $out && length $out;

# Write all data to binary output file
open my $out_fh, '>', $out or die "Failed to create output file $out - $!";
binmode $out_fh;

# Provide a callback to send data through to the file
my $alc = ApacheLog::Compressor->new(
	on_write	=> sub {
		my ($self, $pkt) = @_;
		print { $out_fh } $pkt;
	},
	filter => sub {
		my ($self, $data) = @_;
		# Ignore entries with no URL or timestamp
		return 0 unless defined $data->{url} && length $data->{url};
		return 0 unless $data->{timestamp};

		# Also skip irrelevant entries, in this case regular OPTIONS * server pings from loadbalancer
		return 0 if $ApacheLog::Compressor::HTTP_METHOD_LIST[$data->{method}] eq 'OPTIONS' && $data->{url} eq '*';
		return 1;
	}
);

# Input file - normally use whichever one's just been closed + rotated
open my $in_fh, '<', $in or die "Failed to open input file $in - $!";
binmode $in_fh, ':encoding(utf8)';

# Initial packet to identify which server this came from
$alc->send_packet('server',
	hostname	=> hostname(),
);

# Read and compress all the lines in the files
while(my $line = <$in_fh>) {
        $alc->compress($line);
}
close $in_fh or die $!;
close $out_fh or die $!;

# Dump the stats in case anyone finds them useful
$alc->stats;

