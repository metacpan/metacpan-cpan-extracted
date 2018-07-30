#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;

use Test2::V0;

use Acme::JTM::Experiment;

pass("Successfully loaded Acme::JTM::Experiment");


# EXPERIMENT

# use integer;

sub imask {
    return ( 2**32 - ( 2**( 32 - $_[0] ) ) );
}

sub int2quad {
    return join('.', unpack('C4', pack('N', $_[0])));
}

my @imask;
my %quadmask2bits;

for (my $i=0; $i<=32; $i++) {
    $imask[$i] = imask($i);
    $quadmask2bits{ int2quad( $imask[$i] ) } = $i;
    diag "I: $i";
    diag "imask: " . $imask[$i];
    diag sprintf("imask hex: %08x", $imask[$i]);
    diag "I2Q: " . int2quad($imask[$i]);
    diag "---";
}

my $mask = '255.255.224.0';
ok(exists $quadmask2bits{$mask}, "Mask exists in hash");

my $bits = $quadmask2bits{$mask};
is($bits, 19, "Bit length is proper");


# END EXPERIMENT


done_testing;

