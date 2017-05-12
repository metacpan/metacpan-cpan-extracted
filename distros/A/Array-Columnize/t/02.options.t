#!/usr/bin/env perl
# -*- Perl -*-
use warnings;
use Test::More;
use rlib '../lib';
use Test::More;

note( "Testing Array::Columnize::options" );
BEGIN {
    use_ok( Array::Columnize::options );
}

my %config;
Array::Columnize::merge_config \%config;
use strict;
my @test_keys; 
@test_keys = qw(arrange_array term_adjust lineprefix colsep);

foreach my $option (@test_keys) {
    ok( exists $config{$option}, "Configuration field $option is set");
}

my(@isect, %count); @isect = %count = ();
my @both = (keys(%config), @test_keys);
my @diff = ();
foreach my $elt (@both) { $count{$elt}++ }
foreach my $elt (keys %count) { 
    if ($count{$elt} == 2) { push @isect, $elt; } else { push @diff, $elt; }
}

# print join(", ", @isect), "\n";
# print join(", ", @diff), "\n";

my $config2 = {
    arrange_array => 1,
    term_adjust   => 1,
    lineprefix    => '...',
    colsep        => ', ',
};

my @a1 = sort keys(%$config2);
my @a2 = sort @test_keys;
is @a1, @a2,
    "Prereq for further tests: only values in \@test_keys are set in \$config2";
$config2->{bogus} = 'yep';

Array::Columnize::merge_config $config2;

foreach my $option (@isect) {
     isnt($config2->{$option}, $config{$option}, 
	  "Configuration field $option should change");
}

foreach my $option (@diff) {
    is($config2->{$option}, $config{$option},
       "Configuration field $option is be set to default");
}
ok($config2->{bogus}, "Set option not defaulted");

done_testing();
