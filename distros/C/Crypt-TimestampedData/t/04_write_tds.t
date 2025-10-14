#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;

use Crypt::TimestampedData;

print "Testing write_tds method...\n";

# Test data
my $test_data_file = File::Spec->catfile("t", 'test_data.txt');
my $test_data;
{
    open my $fh, '<:raw', $test_data_file or die "Cannot open test data file: $!";
    local $/;
    $test_data = <$fh>;
    close $fh;
}

# Create a temporary file with test data
my $temp_dir = tempdir(CLEANUP => 1);
my $input_file = File::Spec->catfile($temp_dir, 'input.txt');
{
    open my $fh, '>:raw', $input_file or die "Cannot create input file: $!";
    print $fh $test_data;
    close $fh;
}

# Use real timestamp file (extracted TimeStampToken)
my $timestamp_file = File::Spec->catfile("t", 'test_data_token.tsr');
ok(-f $timestamp_file, "Real timestamp file exists: $timestamp_file");

# Test 1: write_tds with real timestamp
my $output_file = File::Spec->catfile($temp_dir, 'output.tsd');
my $result;
lives_ok { 
    $result = Crypt::TimestampedData->write_tds($input_file, $timestamp_file, $output_file) 
} 'write_tds with real timestamp';

ok(defined $result, 'write_tds returned result');
is($result, $output_file, 'write_tds returned correct output path');
ok(-f $output_file, 'Output TSD file created');

# Test 2: Verify the created TSD file
my $tsd_data;
lives_ok { 
    $tsd_data = Crypt::TimestampedData->read_file($output_file) 
} 'Read created TSD file';

ok(defined $tsd_data, 'TSD data read successfully');
is($tsd_data->{version}, 1, 'TSD version is correct');

# Test 3: Extract and verify content
my $extracted_content = Crypt::TimestampedData->extract_content_der($tsd_data);
ok(defined $extracted_content, 'Content extracted from TSD');
is($extracted_content, $test_data, 'Extracted content matches original');

print "write_tds test completed\n";
print "Input file: $input_file\n";
print "Output file: $output_file\n";
print "Content length: " . length($extracted_content) . " bytes\n";
