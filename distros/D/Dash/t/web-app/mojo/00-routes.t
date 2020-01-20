use Mojo::Base -strict;

use Test::Mojo;
use Test::More tests => 17;

my $t = Test::Mojo->new('Dash');

$t->get_ok('/')->status_is(200)->content_like(qr/Loading/);

$t->get_ok('/_dash-component-suites/dash_renderer/dash_renderer.min.js')->status_is(200);

$t->get_ok('/_dash-layout')->status_is(200)->json_is( {} );

$t->get_ok('/_dash-dependencies')->status_is(200)->json_is( [] );

$t->post_ok('/_dash-update-component')->status_is(200)->json_is( { response => "There is no registered callbacks" } );

$t->get_ok('/_favicon.ico')->status_is(200)->content_type_is('image/x-icon');

