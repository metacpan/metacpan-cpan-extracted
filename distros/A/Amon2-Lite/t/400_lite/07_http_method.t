use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

my $app = do {
    package MyApp;
    use Amon2::Lite;

    get  '/g' => sub { shift->create_response(200, [], 'get_ok' ) };
    post '/p' => sub { shift->create_response(200, [], 'post_ok') };
    any  '/a' => sub { shift->create_response(200, [], 'any_ok' ) };
    any ['get'] => '/a2' => sub { shift->create_response(200, [], 'any_ok2' ) };

    __PACKAGE__->to_app();
};

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);

subtest 'normal case' => sub {
    $mech->get_ok('http://localhost/g');
    $mech->content_is('get_ok');

    $mech->post_ok('http://localhost/p');
    $mech->content_is('post_ok');
};
subtest 'error case' => sub {
    $mech->post('http://localhost/g');
    is($mech->response->code, 405);

    $mech->get('http://localhost/p');
    is($mech->response->code, 405);

};

subtest 'any' => sub {
    $mech->get_ok('http://localhost/a');
    $mech->content_is('any_ok');
    $mech->post_ok('http://localhost/a');
    $mech->content_is('any_ok');
};
subtest 'any 2' => sub {
    $mech->get_ok('http://localhost/a2');
    $mech->content_is('any_ok2');

    $mech->post('http://localhost/a2');
    is($mech->response->code, 405);
};

done_testing;

