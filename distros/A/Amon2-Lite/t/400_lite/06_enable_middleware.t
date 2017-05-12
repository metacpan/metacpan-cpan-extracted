use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Response;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

my $app = do {
    package MyApp;
    use Amon2::Lite;

    get '/' => sub {
        my $c = shift;
        return $c->create_response(200, [], ['OK']);
    };

    __PACKAGE__->enable_middleware('Plack::Middleware::XFramework', framework => 'Amon2::Lite');
    __PACKAGE__->to_app();
};
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('http://localhost/');
is($mech->response->header('X-Framework'), 'Amon2::Lite', 'header');

done_testing;

