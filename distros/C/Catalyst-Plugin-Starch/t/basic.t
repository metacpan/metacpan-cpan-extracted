#!/usr/bin/env perl
use 5.010001;
use strictures 2;

use Test2::V0;
use Test::WWW::Mechanize::PSGI;

{
    package MyApp::Controller::Root;
    use Moose;
    use Test2::V0 qw( !meta );
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
    sub fatal_method :Local :Args(0) {
        my ($self, $c) = @_;
        my $ok = eval { $c->check_session_plugin_requirements(); 1 } || 0;
        $c->res->body( "$ok:$@" );
        $c->res->content_type('text/plain');
    }
    sub tests :Local :Args(0) {
        my ($self, $c) = @_;

        foreach my $method (qw(
            cookie_is_rejecting
            check_session_plugin_requirements
        )) {
            like(
                dies { $c->$method() },
                qr{method is not implemented},
                "unimplemented, $method, method threw exception",
            );
        }

        cmp_ok(
            $c->session_expires(), '>', time(),
            'session_expires is in the future',
        );

        $c->session( foo => 32 );
        is( $c->session->{foo}, 32, 'setting list via the session method' );

        $c->session({ bar => 23 });
        is( $c->session->{bar}, 23, 'setting hash ref via the session method' );

        my $old_id = $c->sessionid();
        $c->change_session_id();
        isnt( $c->sessionid(), $old_id, 'session id changed' );
        is( $c->session->{bar}, 23, 'session appears to have same data after id change' );

        $c->change_session_expires( $c->starch->expires() + 100 );
        is( $c->starch_state->expires(), $c->starch->expires() + 100, 'changing session expires worked' );

        ok( $c->session_is_valid(), 'session is valid' );

        like(
            dies { $c->delete_expired_sessions() },
            qr{does not support expired state reaping},
            'reaping expired sessions died',
        );

        $c->delete_session('foobar');
        ok( $c->starch_state->is_deleted(), 'state was deleted' );
        is( $c->session_delete_reason(), 'foobar', 'delete reason was stored' );
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

$mech->get_ok('/tests');

done_testing;
