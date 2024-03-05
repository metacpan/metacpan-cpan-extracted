#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use AI::Chat;

my $chat_fai11 = AI::Chat->new();

ok( $chat_fai11->isa( 'AI::Chat' ),  'Instantiation' );
ok( !$chat_fai11->success, 'Key Error during object creation' );

my $chat_fail2 = AI::Chat->new(
    'key'   => '0123456789',
    'api'   => 'Not Allowed',
);

ok( $chat_fail2->isa( 'AI::Chat' ),  'Instantiation' );
ok( !$chat_fail2->success, 'API Error during object creation' );

my $chat_pass = AI::Chat->new(
    'key'   => '0123456789',
    'api'   => 'OpenAI',
);

ok( $chat_pass->isa( 'AI::Chat' ), 'Instantiation' );
ok( $chat_pass->success, 'Successful object creation' );

done_testing(6);


    
