#!/usr/bin/env perl
use strictures 1;

use Test::More;
use Test::WWW::Mechanize::PSGI;

{
    package MyApp::Controller::Root;
    use Moose;
    use Test::More;
    BEGIN { extends 'Catalyst::Controller' }
    __PACKAGE__->config->{namespace} = '';
    sub noop :Local :Args(0) {
        my ($self, $c) = @_;
        return;
    }
    sub session :Local :Args(0) {
        my ($self, $c) = @_;
        $c->session();
    }
    sub set :Local :Args(2) {
        my ($self, $c, $key, $value) = @_;
        $c->session->{$key} = $value;
    }
    sub get :Local :Args(1) {
        my ($self, $c, $key) = @_;
        $c->res->body( $c->session->{$key} );
        $c->res->content_type('text/plain');
    }
}

{
    package MyApp;
    use Catalyst qw(
        Starch
        Starch::Cookie
    );
    MyApp->config(
        'Plugin::Starch' => {
            store => {
                class  => '::Memory',
            },
            cookie_secure    => 0,
            cookie_http_only => 0,
        },
    );
    MyApp->setup();
}

my $mech = Test::WWW::Mechanize::PSGI->new(
    app => MyApp->psgi_app(),
);

$mech->get_ok('/noop');
$mech->get_ok('/session');
$mech->get_ok('/set/foo/hello');
$mech->get_ok('/get/foo');

is(
    $mech->response->content(),
    'hello',
    'retrieved value from session successfully',
);

done_testing;
