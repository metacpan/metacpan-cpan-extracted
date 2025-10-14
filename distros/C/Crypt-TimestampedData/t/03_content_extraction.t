#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;

use Crypt::TimestampedData;

# Test data
my $test_data_file = File::Spec->catfile("t", 'test_data.txt');
my $test_data;
{
    open my $fh, '<:raw', $test_data_file or die "Cannot open test data file: $!";
    local $/;
    $test_data = <$fh>;
    close $fh;
}

print "Testing content extraction...\n";

# Create TSD with test data using write_tds method
my $temp_dir = tempdir(CLEANUP => 1);
my $input_file = File::Spec->catfile($temp_dir, 'input.txt');
{
    open my $fh, '>:raw', $input_file or die "Cannot create input file: $!";
    print $fh $test_data;
    close $fh;
}

# Use real timestamp file (extracted TimeStampToken)
my $timestamp_file = File::Spec->catfile("t", 'test_data_token.tsr');
my $tsd_file = File::Spec->catfile($temp_dir, 'test.tsd');

# Create TSD using write_tds
lives_ok { 
    Crypt::TimestampedData->write_tds($input_file, $timestamp_file, $tsd_file) 
} 'Create TSD with real timestamp';

# Read the TSD back
my $tsd_data;
lives_ok { 
    $tsd_data = Crypt::TimestampedData->read_file($tsd_file) 
} 'Read TSD file';

# Test 1: Extract content DER
my $extracted_content;
lives_ok { 
    $extracted_content = Crypt::TimestampedData->extract_content_der($tsd_data) 
} 'Extract content DER';

ok(defined $extracted_content, 'Content extracted successfully');
is($extracted_content, $test_data, 'Extracted content matches original');

# Test 2: Write content to file
my $extract_temp_dir = tempdir(CLEANUP => 1);
my $extracted_file = File::Spec->catfile($extract_temp_dir, 'extracted_content.txt');

lives_ok { 
    Crypt::TimestampedData->write_content_file($tsd_data, $extracted_file) 
} 'Write extracted content to file';

ok(-f $extracted_file, 'Extracted content file created');

# Test 3: Verify extracted file content
my $extracted_data;
{
    open my $fh, '<:raw', $extracted_file or die "Cannot open extracted file: $!";
    local $/;
    $extracted_data = <$fh>;
    close $fh;
}

is($extracted_data, $test_data, 'Extracted file content matches original');

# Test 4: Extract timestamp tokens
my $tokens;
lives_ok { 
    $tokens = Crypt::TimestampedData->extract_tst_tokens_der($tsd_data) 
} 'Extract timestamp tokens';

ok(ref($tokens) eq 'ARRAY', 'Timestamp tokens is array reference');
is(scalar(@$tokens), 1, 'One timestamp token found');

# Test 5: Write timestamp tokens to files
my $tokens_dir = File::Spec->catfile($temp_dir, 'tokens');
mkdir $tokens_dir;

my $token_count;
lives_ok { 
    $token_count = Crypt::TimestampedData->write_tst_files($tsd_data, $tokens_dir) 
} 'Write timestamp tokens to files';

is($token_count, 1, 'One timestamp file written');

print "Content extraction test completed\n";
print "Extracted content length: " . length($extracted_data) . " bytes\n";
print "Timestamp tokens: $token_count\n";
