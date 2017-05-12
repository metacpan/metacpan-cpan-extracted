#!/usr/bin/perl -w

use Test::More;

use Bloom::Filter;

my $bf = Bloom::Filter->new();

# default capacity should be 100;

my @salts = $bf->salts();
is( scalar @salts, 10, "Correct default number of salts" );

my @keys = qw/Hansel Gretel/;

ok( $bf->add( @keys ), "Added key" );
ok( $bf->check( "Hansel" ), "Found key 'Hansel' in filter" );
ok( !$bf->check( "Herman" ), "Did not find key 'Herman'" );
ok( $bf->check( "Gretel" ), "Found key 'Gretel' in filter" );

done_testing();
