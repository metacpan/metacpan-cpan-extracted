use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

API::Client

=cut

=abstract

HTTP API Thin-Client Abstraction

=cut

=includes

method: create
method: delete
method: dispatch
method: fetch
method: patch
method: prepare
method: process
method: resource
method: serialize
method: update

=cut

=synopsis

  package main;

  use API::Client;

  my $client = API::Client->new(url => 'https://httpbin.org');

  # $client->resource('post');

  # $client->update(json => {...});

=cut

=libraries

Types::Standard

=cut

=integrates

Data::Object::Role::Buildable
Data::Object::Role::Stashable
Data::Object::Role::Throwable

=cut

=attributes

debug: ro, opt, Bool
fatal: ro, opt, Bool
logger: ro, opt, InstanceOf["FlightRecorder"]
name: ro, opt, Str
retries: ro, opt, Int
timeout: ro, opt, Int
url: ro, opt, InstanceOf["Mojo::URL"]
user_agent: ro, opt, InstanceOf["Mojo::UserAgent"]
version: ro, opt, Str

=cut

=description

This package provides an abstraction and method for rapidly developing HTTP API
clients.

=cut

=method dispatch

The dispatch method issues a request to the API resource represented by the
object.

=signature dispatch

dispatch(Str :$method = 'get', Any %args) : InstanceOf["Mojo::Transaction"]

=example-1 dispatch

  # given: synopsis

  $client->resource('get')->dispatch;

=example-2 dispatch

  # given: synopsis

  $client->resource('post')->dispatch(
    method => 'post', body => 'active=1'
  );

=example-3 dispatch

  # given: synopsis

  $client->resource('get')->dispatch(
    method => 'get', query => {active => 1}
  );

=example-4 dispatch

  # given: synopsis

  $client->resource('post')->dispatch(
    method => 'post', json => {active => 1}
  );

=example-5 dispatch

  # given: synopsis

  $client->resource('post')->dispatch(
    method => 'post', form => {active => 1}
  );

=example-6 dispatch

  # given: synopsis

  $client->resource('put')->dispatch(
    method => 'put', json => {active => 1}
  );

=example-7 dispatch

  # given: synopsis

  $client->resource('patch')->dispatch(
    method => 'patch', json => {active => 1}
  );

=example-8 dispatch

  # given: synopsis

  $client->resource('delete')->dispatch(
    method => 'delete', json => {active => 1}
  );

=cut

=method create

The create method issues a C<POST> request to the API resource represented by
the object.

=signature create

create(Any %args) : InstanceOf["Mojo::Transaction"]

=example-1 create

  # given: synopsis

  $client->resource('post')->create(
    json => {active => 1}
  );

=cut

=method delete

The delete method issues a C<DELETE> request to the API resource represented by
the object.

=signature delete

delete(Any %args) : InstanceOf["Mojo::Transaction"]

=example-1 delete

  # given: synopsis

  $client->resource('delete')->delete;

=cut

=method fetch

The fetch method issues a C<GET> request to the API resource represented by the
object.

=signature fetch

fetch(Any %args) : InstanceOf["Mojo::Transaction"]

=example-1 fetch

  # given: synopsis

  $client->resource('get')->fetch;

=cut

=method patch

The patch method issues a C<PATCH> request to the API resource represented by
the object.

=signature patch

patch(Any %args) : InstanceOf["Mojo::Transaction"]

=example-1 patch

  # given: synopsis

  $client->resource('patch')->patch(
    json => {active => 1}
  );

=cut

=method prepare

The prepare method acts as a C<before> hook triggered before each request where
you can modify the transactor objects.

=signature prepare

prepare(Object $ua, Object $tx, Any %args) : Object

=example-1 prepare

  # given: synopsis

  require Mojo::UserAgent;
  require Mojo::Transaction::HTTP;

  $client->prepare(
    Mojo::UserAgent->new,
    Mojo::Transaction::HTTP->new
  );

=cut

=method process

The process method acts as an C<after> hook triggered after each response where
you can modify the transactor objects.

=signature process

process(Object $ua, Object $tx, Any %args) : Object

=example-1 process

  # given: synopsis

  require Mojo::UserAgent;
  require Mojo::Transaction::HTTP;

  $client->process(
    Mojo::UserAgent->new,
    Mojo::Transaction::HTTP->new
  );

=cut

=method resource

The resource method returns a new instance of the object for the API resource
endpoint specified.

=signature resource

resource(Str @segments) : Object

=example-1 resource

  # given: synopsis

  $client->resource('status', 200);

=cut

=method serialize

The serialize method serializes and returns the object as a C<hashref>.

=signature serialize

serialize() : HashRef

=example-1 serialize

  # given: synopsis

  $client->serialize;

=cut

=method update

The update method issues a C<PUT> request to the API resource represented by
the object.

=signature update

update(Any %args) : InstanceOf["Mojo::Transaction"]

=example-1 update

  # given: synopsis

  $client->resource('put')->update(
    json => {active => 1}
  );

=cut

package main;

use Mojo::UserAgent;

SKIP: {
  my $skip_tests = do {
    my $tx = Mojo::UserAgent->new->get('https://httpbin.org/anything');

    !eval{$tx->result->is_success};
  };

  unless ($skip_tests) {
    my $test = testauto(__FILE__);

    my $subs = $test->standard;

    $subs->synopsis(fun($tryable) {
      ok my $result = $tryable->result;

      $result
    });

    $subs->example(-1, 'create', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'post';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{json}, {active => 1};

      $result
    });

    $subs->example(-1, 'delete', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'delete';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{json}, undef;
      is_deeply $json->{form}, {};
      is $json->{data}, '';

      $result
    });

    $subs->example(-1, 'dispatch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'get';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{args}, {};

      $result
    });

    $subs->example(-2, 'dispatch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'post';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is $json->{data}, "active=1";

      $result
    });

    $subs->example(-3, 'dispatch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'get';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{args}, {active => 1};

      $result
    });

    $subs->example(-4, 'dispatch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'post';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{json}, {active => 1};

      $result
    });

    $subs->example(-5, 'dispatch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'post';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is $json->{data}, "active=1";

      $result
    });

    $subs->example(-6, 'dispatch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'put';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{json}, {active => 1};

      $result
    });

    $subs->example(-7, 'dispatch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'patch';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{json}, {active => 1};

      $result
    });

    $subs->example(-8, 'dispatch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'delete';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{json}, {active => 1};

      $result
    });

    $subs->example(-1, 'fetch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'get';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{json}, undef;
      is_deeply $json->{form}, undef;
      is $json->{data}, undef;

      $result
    });

    $subs->example(-1, 'patch', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'patch';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{json}, {active => 1};

      $result
    });

    $subs->example(-1, 'prepare', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      $result
    });

    $subs->example(-1, 'process', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      $result
    });

    $subs->example(-1, 'resource', 'method', fun($tryable) {
      ok my $result = $tryable->result;
      is $result->debug, 0;
      is $result->fatal, 0;
      like $result->name, qr/API::Client \(\d.\d\d\)/;
      is $result->retries, 0;
      is $result->timeout, 10;
      is $result->url->to_string, 'https://httpbin.org/status/200';

      $result
    });

    $subs->example(-1, 'serialize', 'method', fun($tryable) {
      ok my $result = $tryable->result;
      is $result->{debug}, 0;
      is $result->{fatal}, 0;
      like $result->{name}, qr/API::Client \(\d.\d\d\)/;
      is $result->{retries}, 0;
      is $result->{timeout}, 10;
      is $result->{url}, 'https://httpbin.org';

      $result
    });

    $subs->example(-1, 'update', 'method', fun($tryable) {
      ok my $result = $tryable->result;

      my $req = $result->req;
      is lc($req->method), 'put';

      my $res = $result->res;
      is $res->code, 200;

      my $json = $res->json;
      is $json->{headers}{'Host'}, 'httpbin.org';
      is $json->{headers}{'Content-Type'}, 'application/json';
      is_deeply $json->{json}, {active => 1};

      $result
    });
  }

  skip 'Unable to connect to HTTPBin' if $skip_tests;
}

ok 1 and done_testing;
