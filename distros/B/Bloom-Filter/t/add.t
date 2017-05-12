#!/usr/bin/perl -w

use Test::More;

use Bloom::Filter;

my $bf = Bloom::Filter->new();

# default capacity should be 100;

my @salts = $bf->salts();
is( scalar @salts, 10, "Correct default number of salts" );

my @keys = qw/Hansel Gretel/;

is( $bf->key_count(), 0, "No keys" );
ok( $bf->add( $keys[0] ), "Added key" );
is( $bf->key_count(), 1, "Key count incremented" );
ok( $bf->add( $keys[0] ), "Added key" );
is( $bf->key_count(), 2, "Key count incremented" );

for (1..98) { $bf->add( $_ ) };

ok( !$bf->add( "last key" ), "Capacity exceeded" );

$bf = Bloom::Filter->new();
ok( $bf->add( @keys ), "Added multiple keys" );
is( $bf->key_count(), 2, "Correct key count" );

done_testing();
