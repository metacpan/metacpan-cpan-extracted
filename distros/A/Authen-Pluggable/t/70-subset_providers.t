package Skel;
use Mojo::Base 'Mojolicious';

package main;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Mojo;
use Mojo::IOLoop;

use Authen::Pluggable;
use Mojo::Log;

use Mojo::File 'path';

my %users = (
    users1 => [ 'foo',  'foo' ],
    users2 => [ 'bar',  'bar' ],
    json   => [ 'json', 'json' ]
);

my $t = Test::Mojo->new( 'Skel', { secrets => ['I love Mojolicious'] } );
$t->app->routes->get(
    '/auth' => sub ($c) {
        if ( $c->param('user') eq 'json' && $c->param('pass') eq 'json' ) {
            $c->render( json => { user => 'foo', cn => 'Test User' } );
        } else {
            $c->render( json => {} );
        }
    }
);

my $log  = $ENV{DEBUG} ? Mojo::Log->new( color => 1 ) : undef;
my $auth = new Authen::Pluggable( log => $log );

subtest 'ISA' => sub {
    isa_ok(
        $auth->providers(
            {   users1 => {
                    provider => 'Passwd',
                    'file'   => path(__FILE__)->sibling('users1')->to_string
                },
                users2 => {
                    provider => 'Passwd',
                    'file'   => path(__FILE__)->sibling('users2')->to_string
                },
                json => {
                    provider => 'JSON',
                    url      => $t->ua->server->url->path('/auth'),
                }
            }
        ),
        'Authen::Pluggable'
    );
};

subtest 'not authenticated' => sub {
    my $loop = Mojo::IOLoop->singleton;
    foreach my $p (qw/users1 users2 json/) {
        my $timer
            = $loop->timer( 20 => sub { fail('Timeout'); $loop->stop } );
        my @providers = grep !/^$p/, keys %users;
        $loop->subprocess->run_p(
            sub {
                my $uinfo = $auth->authen( $users{$p}->[0], $users{$p}->[1],
                    \@providers );
                return $uinfo;
            }
        )->then(
            sub {
                is( shift, undef,
                    "$p: user not authenticated for providers: "
                        . join( ',', @providers ) );
                $loop->stop;
            }
        )->catch( sub { fail(shift); $loop->stop } );
        $loop->start;
        $loop->remove($timer);
    }
};

subtest 'authenticated single provider' => sub {
    my $loop = Mojo::IOLoop->singleton;
    foreach my $p (qw/users1 users2 json/) {
        my $timer
            = $loop->timer( 20 => sub { fail('Timeout'); $loop->stop } );
        my @providers = ($p);
        $loop->subprocess->run_p(
            sub {
                return $auth->authen( $users{$p}->[0], $users{$p}->[1],
                    \@providers );
            }
        )->then(
            sub {
                my $uinfo = shift;
                ok( $uinfo,
                    "$p: user authenticated for providers: "
                        . join( ',', @providers ) );
                is( $uinfo->{provider}, $p, "$p: correct provider" );
                $loop->stop;
            }
        )->catch( sub { fail(shift); $loop->stop } );
        $loop->start;
        $loop->remove($timer);
    }
};

subtest 'authenticated multiple provider' => sub {
    my $loop = Mojo::IOLoop->singleton;
    foreach my $p (qw/users1 users2 json/) {
        my $timer
            = $loop->timer( 20 => sub { fail('Timeout'); $loop->stop } );
        my @providers = keys %users;
        $loop->subprocess->run_p(
            sub {
                return $auth->authen( $users{$p}->[0], $users{$p}->[1],
                    \@providers );
            }
        )->then(
            sub {
                my $uinfo = shift;
                ok( $uinfo,
                    "$p: user authenticated for providers: "
                        . join( ',', @providers ) );
                is( $uinfo->{provider}, $p, "$p: correct provider" );
                $loop->stop;
            }
        )->catch( sub { fail(shift); $loop->stop } );
        $loop->start;
        $loop->remove($timer);
    }
};

done_testing();
