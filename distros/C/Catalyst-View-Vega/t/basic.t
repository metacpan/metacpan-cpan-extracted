use strict;
use warnings;
use utf8;
use open qw< :std :encoding(UTF-8) >;

# Catch any compile-time errors early
use Catalyst::View::Vega;

use Path::Tiny;
my $SPECS = path(__FILE__)->parent->child('specs');

{
  package TestApp::View::Vega;

  use Moose;
  extends 'Catalyst::View::Vega';

  $INC{'TestApp/View/Vega.pm'} = __FILE__;

  package TestApp::Controller::Root;
  use base 'Catalyst::Controller';

  sub single_action :Path('/single/action') Args(0) {
    my ($self, $c) = @_;
    my $vega = $c->view;
    $vega->specfile('basic.json');
    $vega->bind_data({
        foo => [{ bar => 42 }],
        baz => "http://example.com",
    });
    $c->detach($vega);
  }

  sub root :Chained('/') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->view->specfile('basic.json');
  }

  sub root_chained :Chained('root') PathPart('chained') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->view->bind_data( foo => [{ bar => 42 }] );
  }

  sub root_chained_action :Chained('root_chained') PathPart('action') Args(0) {
    my ($self, $c) = @_;
    $c->view->bind_data( baz => "http://example.com" );
    $c->detach($c->view);
  }

  sub root_chained_unbound :Chained('root_chained') PathPart('unbound') Args(0) {
    my ($self, $c) = @_;
    $c->view->unbind_data('foo');
    $c->detach($c->view);
  }

  sub error_bad_name :Chained('root') PathPart('error/bad-name') Args(0) {
    my ($self, $c) = @_;
    $c->view->bind_data( DNE => [] );
    $c->detach($c->view);
  }

  sub error_bad_values :Chained('root') PathPart('error/bad-values') Args(0) {
    my ($self, $c) = @_;
    $c->view->bind_data('odd');
    $c->detach($c->view);
  }

  $INC{'TestApp/Controller/Root.pm'} = __FILE__;

  package TestApp;
  use Catalyst;

  TestApp->config(
    'Controller::Root' => { namespace => '' },
    'default_view'     => 'Vega',
    'View::Vega'       => {
      path => "$SPECS",
    },
  );

  TestApp->setup;
}

use Test::More;
use Test::Deep;
use Catalyst::Test 'TestApp';
use JSON::MaybeXS;

for my $action (qw[ /single/action /chained/action /chained/unbound ]) {
    ok(my $res = request($action), $action);
    is($res->code, 200, "status is 200");

    my $got      = decode_json( $res->content );
    my $expected = decode_json( $SPECS->child('basic.json')->slurp_raw );

    unless ($action =~ /unbound/) {
        $expected->{data}[0]{values} = [{ bar => 42 }];
        $expected->{data}[1]{url}    = "http://example.com";
    }
    cmp_deeply($got, $expected, "data inlined into spec");
}

{
    my ($res, $c) = ctx_request('/error/bad-name');
    ok($res, '/error/bad-name');
    is($res->code, 500, "status is 500")
        or die $res->decoded_content;
    like($c->error->[-1], qr/cannot find a dataset named «DNE»/, "error message matches");
}

done_testing;
