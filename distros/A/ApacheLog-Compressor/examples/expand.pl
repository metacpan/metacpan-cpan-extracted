#!/usr/bin/perl
use strict;
use warnings;

use ApacheLog::Compressor 0.004;
use Encode qw(decode_utf8 is_utf8);

my ($in, $out) = @ARGV;
die "No input file provided" unless defined $in && length $in;
die "No output file provided" unless defined $out && length $out;

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

# Write all data to plain text file
open my $out_fh, '>', $out or die "Failed to create output file $out - $!";
binmode $out_fh, ':encoding(utf8)';

use Data::Dumper;
# Provide a callback to send data through to the file
my $alc = ApacheLog::Compressor->new(
	on_log_line	=> sub {
		my ($self, $data) = @_;
		# Use the helper method to expand back to plain text representation
		print { $out_fh } $self->data_to_text($data) . "\n";
	},
);

# Input file - normally use whichever one's just been closed + rotated
open my $in_fh, '<', $in or die "Failed to open input file $in - $!";
binmode $in_fh;

# Read and expand all the lines in the files
my $buffer = '';
while(read($in_fh, my $data, 1024) >= 0) {
	$buffer .= $data;
        $alc->expand(\$buffer);
}
close $in_fh or die $!;
close $out_fh or die $!;

# Dump the stats in case anyone finds them useful
$alc->stats;

