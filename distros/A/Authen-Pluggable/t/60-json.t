package Skel;
use Mojo::Base 'Mojolicious';

package main;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Mojo;
use Mojo::IOLoop;

use Authen::Pluggable;
use Mojo::Log;

my $t = Test::Mojo->new( 'Skel', { secrets => ['I love Mojolicious'] } );
$t->app->routes->get(
    '/auth' => sub ($c) {
        if ( $c->param('user') eq 'foo' && $c->param('pass') eq 'foo' ) {
            $c->render( json => { user => 'foo', cn => 'Test User' } );
        } else {
            $c->render( json => {} );
        }
    }
);

my $provider = 'JSON';

my $user = 'foo';
my $pass = 'foo';

my $log  = $ENV{DEBUG} ? Mojo::Log->new( color => 1 ) : undef;
my $auth = new Authen::Pluggable( log => $log );

subtest 'authentication' => sub {
    isa_ok( $auth->provider($provider), 'Authen::Pluggable::' . $provider );
    $auth->provider($provider)->_cfg->{url}->path('/auth')
        ->port( $t->ua->server->url->port );
    my $loop = Mojo::IOLoop->singleton;
    $loop->timer( 20 => sub { fail('Timeout'); $loop->stop } );
    $loop->subprocess->run(
        sub {
            my $uinfo = $auth->authen( $user, '' );
            is( $uinfo, undef, 'User no authenticated (missing pass)' );
            $uinfo = $auth->authen( $user, $pass . $pass );
            is( $uinfo, undef, 'User no authenticated (wrong pass)' );

            $uinfo = $auth->authen( $user, $pass );

            isnt( $uinfo->{user}, undef, 'User authenticated' );
            is( $uinfo->{user},     $user,     'User authenticated' );
            is( $uinfo->{provider}, $provider, 'Correct provider response' );
            is( $uinfo->{cn},       'Test User', 'Common name available' );
        },
        sub ( $subprocess, $err, @results ) {
            fail($err) if $err;
            $loop->stop;
        }
    );
    $loop->start;
};

done_testing();
