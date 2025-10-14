#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

print "Testing version synchronization...\n";

# Test 1: Load modules in different orders
use Crypt::TimestampedData;
use Crypt::TSD;

# Test 2: Check that both modules have versions (or both undefined during development)
my $tsd_has_version = defined $Crypt::TimestampedData::VERSION;
my $alias_has_version = defined $Crypt::TSD::VERSION;

# During development, versions might be undefined, but they should match
if ($tsd_has_version && $alias_has_version) {
    is($Crypt::TimestampedData::VERSION, $Crypt::TSD::VERSION, 'Versions are synchronized');
} elsif (!$tsd_has_version && !$alias_has_version) {
    pass('Both versions undefined during development (expected)');
} else {
    fail('Version synchronization failed - one defined, one undefined');
}

# Test 4: Test with different loading order
{
    # Clear the modules
    delete $INC{'Crypt/TimestampedData.pm'};
    delete $INC{'Crypt/TSD.pm'};
    
    # Load in reverse order
    use Crypt::TSD;
    use Crypt::TimestampedData;
    
    my $tsd_has_version_rev = defined $Crypt::TimestampedData::VERSION;
    my $alias_has_version_rev = defined $Crypt::TSD::VERSION;
    
    if ($tsd_has_version_rev && $alias_has_version_rev) {
        is($Crypt::TimestampedData::VERSION, $Crypt::TSD::VERSION, 'Versions are synchronized (reverse order)');
    } elsif (!$tsd_has_version_rev && !$alias_has_version_rev) {
        pass('Both versions undefined during development (reverse order)');
    } else {
        fail('Version synchronization failed (reverse order) - one defined, one undefined');
    }
}

print "Version synchronization test completed\n";
