#!/usr/bin/perl
use strict;
use warnings;
use Audio::Extract::PCM;
use Getopt::Long;

# Extracts PCM data to Standard Output

GetOptions (
    'rate=s'     => \(my $rate = 44100),
    'size=s'     => \(my $samplesize = 2),
    'channels=s' => \(my $channels = 2),
) or exit 1;

my ($source) = @ARGV or die "Expected a source filename\n";

my $extractor = Audio::Extract::PCM->new($source);
my $pcm = $extractor->pcm($rate, $samplesize, $channels)
    or die $extractor->error() . "\n";

binmode STDOUT;
print $$pcm or die $!;
close STDOUT or die $!;
