#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use AI::Embedding;

my $embed_pass = AI::Embedding->new(
    'key'	=> '0123456789',
    'api'	=> 'OpenAI',
);

ok( $embed_pass->isa( 'AI::Embedding' ), 'Instantiation' );
ok( $embed_pass->success, 'Successful object creation' );

my $test_string1 = 'The cat sat on the mat';
my $test_string2 = 'Hickory dickory dock';

my $embed1 = $embed_pass->test_embedding($test_string1);

is( scalar split (/,/, $embed1), 1536, "Correct first embed length");

my $embed2 = $embed_pass->test_embedding($test_string2);

is( scalar split (/,/, $embed2), 1536, "Correct second embed length");

my $embed3 = $embed_pass->test_embedding($test_string2);

ok( $embed2 eq $embed3, "Same text - same test embedding" );
ok( $embed2 ne $embed1, "Different text - different test embedding" );

done_testing(6);

