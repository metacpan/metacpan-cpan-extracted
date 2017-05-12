#!/usr/bin/env perl

# Tests for the length requirements go here.
# Test::Deep means these tests will work even if the functionility
# Data::Password::Simple is expanded.

use strict;
use Test::Deep;
use Test::More;

use Data::Password::Simple 0.05;

plan('no_plan');

my @test_words = qw(
    on key boot mouse monkey sausage stomache
);

my $dps = Data::Password::Simple->new();

# Test default accessor
ok ($dps->required_length() == $dps->{_default_length},
    "Default length set successfully");

my $rqlength = $dps->required_length(); 

# Test default length
for my $word (@test_words) { 
    
    my ($ok, $status) = $dps->check($word);

    ok (
        $ok == $dps->check($word),
        "Scalar context behaviour is consistant"
    );
   
    ok (
        $ok == _expect_ok($word),
        "Basic length test ($word)"
    );

    cmp_deeply (
        $status,
        superhashof( _expect_status($word) ),
        "Length status is as expected ($word)"
    );
}

sub _expect_ok {
    my $word = shift;
    
    return (length $word < $rqlength) ? 0 : 1; 
}

sub _expect_status {
    my $word = shift;

    if (length $word < $rqlength) {
        return { error => { too_short => 1 } };
    }
    return { acceptable => 1 };
}
