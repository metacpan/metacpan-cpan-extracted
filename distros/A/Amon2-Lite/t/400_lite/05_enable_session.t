use strict;
use warnings;
use utf8;
use Test::More;

use Test::Requires 'Test::WWW::Mechanize::PSGI';

my $app = do {
    package MyApp;
    use Amon2::Lite;

    get '/' => sub {
        my $c = shift;
        my $cnt = $c->session->get('cnt') || 0;
        $cnt++;
        $c->session->set(cnt => $cnt);
        return $c->create_response(200, [], [$cnt]);
    };

    __PACKAGE__->enable_session();
    __PACKAGE__->to_app();
};

{
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
    $mech->get_ok('http://localhost/');
    $mech->content_is('1');
    is($mech->response->header('Cache-Control'), 'private');
    $mech->get_ok('http://localhost/');
    $mech->content_is('2');
}

done_testing;

