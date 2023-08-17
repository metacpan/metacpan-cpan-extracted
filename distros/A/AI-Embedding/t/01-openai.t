#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use AI::Embedding;

my $embed_fail1 = AI::Embedding->new();

ok( $embed_fail1->isa( 'AI::Embedding' ),  'Instantiation' );
ok( !$embed_fail1->success, 'Key Error during object creation' );

my $embed_fail2 = AI::Embedding->new(
    'key'	=> '0123456789',
    'api'	=> 'Not Allowed',
);

ok( $embed_fail2->isa( 'AI::Embedding' ),  'Instantiation' );
ok( !$embed_fail2->success, 'API Error during object creation' );

my $embed_pass = AI::Embedding->new(
    'key'	=> '0123456789',
    'api'	=> 'OpenAI',
);

ok( $embed_pass->isa( 'AI::Embedding' ), 'Instantiation' );
ok( $embed_pass->success, 'Successful object creation' );

my $comp_fail = $embed_pass->compare('-0.6,-0.5,-0.4,-0.3,-0.2,0.0,0.2,0.3,0.4,0.5', '-0.6,-0.5,-0.4,-0.3,-0.2');

ok( !$embed_pass->success, 'Compare mismatch' );
ok( $embed_pass->error eq 'Embeds are unequal length', 'Correct error message');

my $comp_pass1 = $embed_pass->compare('-0.6,-0.5,-0.4,-0.3,-0.2,0.0,0.2,0.3,0.4,0.5', '-0.6,-0.5,-0.4,-0.3,-0.2,0.0,0.2,0.3,0.4,0.5');

is( $comp_pass1, 1, "Compare got $comp_pass1");

my $cmp = $embed_pass->comparator('-0.6,-0.5,-0.4,-0.3,-0.2,0.0,0.2,0.3,0.4,0.5');

ok( $embed_pass->success, "Comparator created" );
ok( defined $cmp, "Comparator exists" );

my $comp_pass2 = $cmp->('-0.6,-0.5,-0.4,-0.3,-0.2,0.0,0.2,0.3,0.4,0.5');

is( $comp_pass2, 1, "Compare to comparator got $comp_pass2");

done_testing(12);


    
