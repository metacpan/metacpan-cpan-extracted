use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

{

    package MyApp;
    use parent qw/Amon2/;

    sub load_config {
        +{ 'MAINTENANCE' =>
                +{ enable => 1, except => +{ path => ['/user'] } } };
    }

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;

    sub dispatch {
        my $c = shift;
        if ( $c->request->path_info eq '/' ) {
            return $c->create_response( 200, [], [] );
        }
        elsif ( $c->request->path_info eq '/user' ) {
            return $c->create_response( 200, [], [] );
        }
        else {
            return $c->create_response( 404, [], [] );
        }
    }

    __PACKAGE__->load_plugins('Web::Maintenance');
}

my $app  = MyApp::Web->to_app;
my $mech = Test::WWW::Mechanize::PSGI->new(
    app                   => $app,
    max_redirect          => 0,
    requests_redirectable => []
);
$mech->get('/');
is $mech->status(), 503;

$mech->get('/user');
is $mech->status(), 200;

done_testing;

