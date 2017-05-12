#!/usr/bin/env perl

# Tests for all the dictionary lookup functionality go here.
# Test::Deep means these tests will work even if the functionility
# Data::Password::Simple is expanded.

use strict;
use Test::Deep;
use Test::More;

use Data::Password::Simple 0.05;

plan('no_plan');

my @test_words = qw( 
    telephone sausage   monkey button    
    book      cabbage   glass  mouse     
    stomach   cardboard ferry  christmas 
);

my @dictionary = qw(
    telephone sausage book cabbage stomache cardboard
);

my %dict_hash = map { $_ => 1 } @dictionary;

my $dps = Data::Password::Simple->new(
    dictionary => \@dictionary,
    length     => 0, # Effectively disable length checking
);

for my $word (@test_words) {
    my ($ok, $status) = $dps->check($word);

    ok (
        $ok == $dps->check($word),
        "Scalar context behaviour is consistant"
    );
  
    ok ( 
        $ok == _expect_ok($word), 
        "Test for basic match ($word)" 
    ); 

    # Make sure the status agrees
    cmp_deeply (
        $status,
        superhashof( _expect_status($word) ),
        "Dictionary status is as expected ($word)"
    );

    # Check case insensitive matching
    ok ( 
        $dps->check(uc $word) == _expect_ok($word), 
        "Case insensitive match OK ($word)"
    );
}

sub _expect_ok {
    my $word = shift;

    return exists $dict_hash{$word} ? 0 : 1;
}

sub _expect_status {
    my $word = shift;

    if ( exists $dict_hash{$word} ) {
        return { error => { in_dictionary => 1 } };
    }
    return { acceptable => 1 };
}
