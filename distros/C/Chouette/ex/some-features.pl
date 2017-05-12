#!/usr/bin/env perl

use common::sense;
use File::Temp;
use Chouette;

use FindBin;
use lib "$FindBin::Bin";

my $chouette = Chouette->new({
    config_defaults => {
        var_dir => File::Temp::tempdir(CLEANUP => 1),
        listen => '9876',
    },

    middleware => [
        'Plack::Middleware::ContentLength',
        ['Plack::Middleware::CrossOrigin', origins => '*'],
        ['ETag', cache_control => [ 'must-revalidate', 'max-age=3600' ]],
    ],

    routes => {
        '/' => {
            GET => sub {
                my $c = shift;
                die $c->respond({ hello => 'world!' });
            },
        },
        '/asdf' => {
            GET => sub { die "403: blah" },
            POST => sub { die '200 asdf' },
        },
        '/blah/:id' => {
            GET => sub {
                my $c = shift;
                die "400: can't update ID " . $c->route_params->{id};
            },
        },
        '/math/times7' => {
            # curl http://127.0.0.1:9876/math/times7?n=8
            GET => sub {
                my $c = shift;

                $c->logger->info("Main PID is $$");

                my $n = $c->req->parameters->{n} // die "400: need an n param";

                $c->task('math', timeout => 5)->times7($n, sub {
                    my ($math, $result) = @_;

                    $c->respond({ result => $result, });
                });
            },
        },
    },

    tasks => {
        math => {
            pkg => 'MyTask',
            client => {
                timeout => 10,
            },
            server => {
                hung_worker_timeout => 30,
            },
        },
    },
});

$chouette->run;
