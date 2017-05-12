use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

subtest 'basic' => sub {
    my $app = do {
        package MyApp;
        use Amon2::Lite;
        get '/' => sub { shift->create_response(200, [], 'ok') };
        __PACKAGE__->to_app();
    };
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
    $mech->get_ok('http://localhost/');
    is($mech->response->header('X-Content-Type-Options'), 'nosniff');
    is($mech->response->header('X-Frame-Options'), 'DENY');
    note $mech->response->as_string;
};
subtest 'disabled' => sub {
    my $app = do {
        package MyApp2;
        use Amon2::Lite;
        get '/' => sub { shift->create_response(200, [], 'ok') };
        __PACKAGE__->to_app(
            no_x_content_type_options => 1,
            no_x_frame_options        => 1,
        );
    };
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
    $mech->get_ok('http://localhost/');
    ok(!$mech->response->header('X-Content-Type-Options'));
    ok(!$mech->response->header('X-Frame-Options'));
    note $mech->response->as_string;
};

done_testing;

