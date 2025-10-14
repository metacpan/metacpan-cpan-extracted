#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;

# Test the alias
use Crypt::TSD;

print "Testing Crypt::TSD alias...\n";

# Test 1: Basic object creation
my $tsd = Crypt::TSD->new();
isa_ok($tsd, 'Crypt::TSD', 'Object creation with alias');
isa_ok($tsd, 'Crypt::TimestampedData', 'Object is also Crypt::TimestampedData');

# Test 2: Verify version
is($Crypt::TSD::VERSION, $Crypt::TimestampedData::VERSION, 'Version matches main module');

# Test 3: Test basic TSD operations
my $tsd_data = {
    version => 1,
    metaData => {
        hashProtected => 0,
        fileName => 'test_alias.txt',
        mediaType => 'text/plain'
    },
    temporalEvidence => {
        tstEvidence => []
    }
};

# Test 4: Encode TSD to DER
my $der;
lives_ok { $der = Crypt::TSD->encode_der($tsd_data) } 'Encode TSD to DER using alias';
ok(defined $der && length($der) > 0, 'DER encoding produced data');

# Test 5: Decode DER back to TSD
my $decoded_tsd;
lives_ok { $decoded_tsd = Crypt::TSD->decode_der($der) } 'Decode DER to TSD using alias';
ok(defined $decoded_tsd, 'Decoded TSD is defined');

# Test 6: Verify roundtrip data integrity
is($decoded_tsd->{version}, $tsd_data->{version}, 'Version preserved in roundtrip');
is($decoded_tsd->{metaData}->{fileName}, $tsd_data->{metaData}->{fileName}, 'Filename preserved in roundtrip');

print "Crypt::TSD alias test completed successfully\n";
