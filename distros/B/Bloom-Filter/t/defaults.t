#!/usr/bin/perl -w

use Test::More;

use Bloom::Filter;

my $bf = Bloom::Filter->new();

# default capacity should be 100;

is( $bf->capacity(), 100, "Default capacity ok" );
is( $bf->error_rate(), 0.001, "Default error rate ok" );
is( $bf->length(), 1438, "Length calculated properly" );

my $bf2 = Bloom::Filter->new( capacity => 1092, error_rate => .00001);

is( $bf2->capacity(), 1092, "Custom capacity ok" );
is( $bf2->error_rate(), 0.00001, "Custom error rate ok" );
is( $bf2->length(), 26172, "Length calculated properly" );

done_testing();
