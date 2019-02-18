#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::WWW::Mechanize::PSGI;
use Time::HiRes qw();

my $iters = 2000;

{
    package MySessionApp::Controller::Root;
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
    package MySessionApp;
    use Catalyst qw(
        Session
        Session::Store::FastMmap
        Session::State::Cookie
    );
    MySessionApp->config(
        'Plugin::Session' => {
            unlink_on_exit => 0,
            cache_size => '10m',
            storage => "/tmp/session-data-bench-$<-$$",
            cookie_secure    => 0,
            cookie_httponly => 0,
        },
    );
    MySessionApp->setup();
}

{
    package MyStarchApp::Controller::Root;
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
        $c->session->{$key};
    }
}

{
    package MyStarchApp;
    use Catalyst qw(
        Starch
        Starch::State::Cookie
    );
    MyStarchApp->config(
        'Plugin::Starch' => {
            plugins => ['::Sereal'],
            store => {
                class  => '::CHI',
                chi => {
                  driver => 'FastMmap',
                  unlink_on_exit => 0,
                  root_dir => "/tmp/starch-data-bench-$<-$$",
                  cache_size => '10m',
                },
            },
            cookie_secure    => 0,
            cookie_http_only => 0,
        },
    );
    MyStarchApp->setup();
}

my $session_mech = Test::WWW::Mechanize::PSGI->new(
    app => MySessionApp->psgi_app(),
);

my $starch_mech = Test::WWW::Mechanize::PSGI->new(
    app => MyStarchApp->psgi_app(),
);

bench_it( session_set => sub{
  $session_mech->get_ok('/set/foo/hello');
});

bench_it( session_get => sub{
  $session_mech->get_ok('/get/foo');
});

bench_it( starch_set => sub{
  $starch_mech->get_ok('/set/foo/hello');
});

bench_it( starch_get => sub{
  $starch_mech->get_ok('/get/foo');
});

sub bench_it {
  my ($name, $sub) = @_;

  subtest $name => sub{
    $sub->();

    my $start = Time::HiRes::time();
    foreach (1..$iters) {
      $sub->();
    }
    my $end = Time::HiRes::time();
    my $run_time = $end - $start;

    diag sprintf(
      "%d %s took %.02fs - %.02f/s\n",
      $iters, $name, $run_time, $iters / $run_time,
    );
  };

  return;
}

done_testing;
