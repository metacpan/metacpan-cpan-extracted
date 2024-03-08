#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use AI::Image;

my $image_fai11 = AI::Image->new();

ok( $image_fai11->isa( 'AI::Image' ),  'Instantiation' );
ok( !$image_fai11->success, 'Key Error during object creation' );

my $image_fail2 = AI::Image->new(
    'key'   => '0123456789',
    'api'   => 'Not Allowed',
);

ok( $image_fail2->isa( 'AI::Image' ),  'Instantiation' );
ok( !$image_fail2->success, 'API Error during object creation' );

my $image_pass = AI::Image->new(
    'key'   => '0123456789',
    'api'   => 'OpenAI',
);

ok( $image_pass->isa( 'AI::Image' ), 'Instantiation' );
ok( $image_pass->success, 'Successful object creation' );

done_testing(6);


    
