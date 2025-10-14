#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 14;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;

use Crypt::TimestampedData;

print "Testing with real timestamp from FreeTSA...\n";

# Test data
my $test_data_file = File::Spec->catfile("t", 'test_data.txt');
my $test_data;
{
    open my $fh, '<:raw', $test_data_file or die "Cannot open test data file: $!";
    local $/;
    $test_data = <$fh>;
    close $fh;
}

# Real timestamp file (extracted TimeStampToken)
my $timestamp_file = File::Spec->catfile("t", 'test_data_token.tsr');
ok(-f $timestamp_file, "Real timestamp file exists: $timestamp_file");

# Read the real timestamp
my $timestamp_data;
{
    open my $fh, '<:raw', $timestamp_file or die "Cannot open timestamp file: $!";
    local $/;
    $timestamp_data = <$fh>;
    close $fh;
}
ok(length($timestamp_data) > 0, "Real timestamp data loaded successfully");
print "Timestamp file size: " . length($timestamp_data) . " bytes\n";

# Test 1: Create TSD with real timestamp using write_tds
my $temp_dir = tempdir(CLEANUP => 1);
my $input_file = File::Spec->catfile($temp_dir, 'input.txt');
{
    open my $fh, '>:raw', $input_file or die "Cannot create input file: $!";
    print $fh $test_data;
    close $fh;
}

my $output_file = File::Spec->catfile($temp_dir, 'output.tsd');
my $result;
lives_ok { 
    $result = Crypt::TimestampedData->write_tds($input_file, $timestamp_file, $output_file) 
} 'Create TSD with real timestamp using write_tds';

ok(defined $result, 'write_tds returned result');
is($result, $output_file, 'write_tds returned correct output path');
ok(-f $output_file, 'Output TSD file created');

# Test 2: Read and verify the TSD file
my $tsd_data;
lives_ok { 
    $tsd_data = Crypt::TimestampedData->read_file($output_file) 
} 'Read TSD file with real timestamp';

ok(defined $tsd_data, 'TSD data read successfully');
is($tsd_data->{version}, 1, 'TSD version is correct');

# Test 3: Extract and verify content
my $extracted_content;
lives_ok { 
    $extracted_content = Crypt::TimestampedData->extract_content_der($tsd_data) 
} 'Extract content from TSD';

ok(defined $extracted_content, 'Content extracted successfully');
is($extracted_content, $test_data, 'Extracted content matches original');

# Test 4: Extract timestamp tokens
my $tokens = Crypt::TimestampedData->extract_tst_tokens_der($tsd_data);
ok(ref($tokens) eq 'ARRAY', 'Timestamp tokens is array reference');
is(scalar(@$tokens), 1, 'One timestamp token found');

print "Real timestamp test completed successfully\n";
print "Input file: $input_file\n";
print "Output file: $output_file\n";
print "Content length: " . length($extracted_content) . " bytes\n";
print "Timestamp tokens: " . scalar(@$tokens) . "\n";
