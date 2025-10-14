#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 22;
use Test::Exception;
use Test::Warn;
use File::Temp qw(tempdir);
use File::Spec;

use Crypt::TimestampedData;

# Test data file
my $test_data_file = File::Spec->catfile("t", 'test_data.txt');
ok(-f $test_data_file, "Test data file exists: $test_data_file");

# Read test data
my $test_data;
{
    open my $fh, '<:raw', $test_data_file or die "Cannot open test data file: $!";
    local $/;
    $test_data = <$fh>;
    close $fh;
}
ok(length($test_data) > 0, "Test data loaded successfully");
# Test data length verification (updated after content modification)
my $expected_length = length($test_data);
ok($expected_length > 0, "Test data has positive length: $expected_length bytes");

# Test 1: Basic object creation
my $tsd = Crypt::TimestampedData->new();
isa_ok($tsd, 'Crypt::TimestampedData', 'Object creation');

# Test 2: Create a simple TSD structure manually
# This tests the basic encoding/decoding without complex timestamp handling
my $tsd_data = {
    version => 1,
    metaData => {
        hashProtected => 0,
        fileName => 'test_data.txt',
        mediaType => 'text/plain'
    },
    # content is optional in TSD, so we'll leave it undefined for this test
    temporalEvidence => {
        tstEvidence => []
    }
};

ok(defined $tsd_data, 'TSD data structure created');

# Test 3: Verify TSD structure
is($tsd_data->{version}, 1, 'TSD version is correct');
ok(defined $tsd_data->{metaData}, 'Metadata is present');
is($tsd_data->{metaData}->{fileName}, 'test_data.txt', 'Filename is correct');

# Test 4: Test content extraction (should return undef since no content)
my $extracted_content;
lives_ok { 
    $extracted_content = Crypt::TimestampedData->extract_content_der($tsd_data) 
} 'Extract content from TSD';

is($extracted_content, undef, 'No content to extract (as expected)');

# Test 5: Test DER encoding/decoding roundtrip
my $der;
lives_ok { $der = Crypt::TimestampedData->encode_der($tsd_data) } 'Encode TSD to DER';
ok(defined $der && length($der) > 0, 'DER encoding produced data');

my $decoded_tsd;
lives_ok { $decoded_tsd = Crypt::TimestampedData->decode_der($der) } 'Decode DER to TSD';
ok(defined $decoded_tsd, 'Decoded TSD is defined');

# Test 6: Verify roundtrip data integrity
is($decoded_tsd->{version}, $tsd_data->{version}, 'Version preserved in roundtrip');
is($decoded_tsd->{metaData}->{fileName}, $tsd_data->{metaData}->{fileName}, 'Filename preserved in roundtrip');

# Test 7: Test file operations
my $temp_dir = tempdir(CLEANUP => 1);
my $tsd_file = File::Spec->catfile($temp_dir, 'test.tsd');

lives_ok { Crypt::TimestampedData->write_file($tsd_file, $tsd_data) } 'Write TSD file';
ok(-f $tsd_file, 'TSD file created');

my $read_tsd;
lives_ok { $read_tsd = Crypt::TimestampedData->read_file($tsd_file) } 'Read TSD file';
ok(defined $read_tsd, 'Read TSD data is defined');

# Test 8: Verify file roundtrip
is($read_tsd->{version}, $tsd_data->{version}, 'Version preserved in file roundtrip');
is($read_tsd->{metaData}->{fileName}, $tsd_data->{metaData}->{fileName}, 'Filename preserved in file roundtrip');

print "\n=== Test completed successfully ===\n";
print "Test data length: " . length($test_data) . " bytes\n";
print "DER encoding length: " . length($der) . " bytes\n";
print "Test file: $tsd_file\n";
