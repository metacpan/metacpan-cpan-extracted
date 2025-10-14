#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;

use Crypt::TimestampedData;

print "Running regression tests...\n";

# Test 1: Empty TSD structure
my $empty_tsd = {
    version => 1,
    temporalEvidence => {
        tstEvidence => []
    }
};

my $empty_der;
lives_ok { $empty_der = Crypt::TimestampedData->encode_der($empty_tsd) } 'Encode empty TSD';
ok(defined $empty_der, 'Empty TSD encoded successfully');

my $decoded_empty;
lives_ok { $decoded_empty = Crypt::TimestampedData->decode_der($empty_der) } 'Decode empty TSD';
ok(defined $decoded_empty, 'Empty TSD decoded successfully');

# Test 2: TSD with minimal required fields
my $minimal_tsd = {
    version => 1,
    temporalEvidence => {
        tstEvidence => [
            {
                timeStamp => {
                    contentType => '1.2.840.113549.1.7.1', # id-data
                    content => 'test_content'
                }
            }
        ]
    }
};

my $minimal_der;
lives_ok { $minimal_der = Crypt::TimestampedData->encode_der($minimal_tsd) } 'Encode minimal TSD';
ok(defined $minimal_der, 'Minimal TSD encoded successfully');

print "Regression tests completed\n";
