#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use Data::HexConverter;

my $dataFile = 'testdata.txt';

open(my $fh, '<', $dataFile) or die "Could not open file '$dataFile' $!";

my $testData = <$fh>;
chomp $testData;
close($fh);

my $start_time = [gettimeofday];

my $binaryData;

for (1..1000) {
	 $binaryData = Data::HexConverter::hex_to_binary(\$testData);
}

my $elapsed_time = tv_interval $start_time;

printf "Method: %s\n", hex_to_binary_impl();
printf "Elapsed time: %.4f seconds\n", $elapsed_time;
printf "Average time per conversion: %.6f seconds\n", $elapsed_time / 1000;
printf "Size of binary data: %d bytes\n", length($binaryData);

