use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/token/form');

my ($form) = $mech->forms;

ok( $form, 'Found form' );

ok( $form->find_input('basic_form'), 'found input field' );

ok( my $token = $form->find_input('_token'), 'found token field' );

$token = $token->value;

like( $token, qr/^[a-z0-9]+$/, 'token value looks like a token' );

ok( my $res = $mech->submit_form( fields => { 'basic_form' => 1, '_token' => "123" } ),
    'submit with different token' );
	
unlike( $res->as_string, qr/VALID/, 'form is not valid' );

$mech->get_ok('http://localhost/token/form');

ok( $res = $mech->submit_form( fields => { '_token' => $token } ),
    'submit with token only' );

unlike( $res->as_string, qr/VALID/, 'basic_form is required' );

$mech->get_ok('http://localhost/token/form');

ok( $res = $mech->submit_form( fields => { 'basic_form' => 1, '_token' => $token } ),
    'submit with valid token' );

like( $res->as_string, qr/VALID/, 'form is valid' );

$mech->get_ok( 'http://localhost/token/count_token', 'get token count' );

is( $mech->content, 4, "4 tokens" );


$mech->get_ok(
    'http://localhost/tokenexpire/form',
    'get token with negative expiration time'
);

($form) = $mech->forms;

ok( $form, 'Found form' );

ok( $form->find_input('basic_form'), 'found input field' );

ok( $token = $form->find_input('token'), 'found token field' );

for(4..21) {
	$mech->get_ok('http://localhost/token/count_token');
	is($mech->content, $_ > 20 ? 20 : $_);
	$mech->get_ok('http://localhost/token/form', 'get form #' . $_);
}

($form) = $mech->forms;
ok( $token = $form->find_input('_token'), 'found token field' );

ok( $res = $mech->submit_form( fields => { 'basic_form' => 1, '_token' => $token->value } ),
    'submit with valid token' );

is( $mech->content, 'VALID', 'form is valid' );

done_testing;