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
clients. While this module can be used to interact with APIs directly,
API::Client was designed to be consumed (subclassed) by higher-level
purpose-specific API clients.

+=head1 THIN CLIENT

The thin API client library is advantageous as it has complete API coverage and
can easily adapt to changes in the API with minimal effort. As a thin-client
superclass, this module does not map specific HTTP requests to specific
routines, nor does it provide parameter validation, pagination, or other
conventions found in typical API client implementations; Instead, it simply
provides a simple and consistent mechanism for dynamically generating HTTP
requests.  Additionally, this module has support for debugging and retrying API
calls as well as throwing exceptions when 4xx and 5xx server response codes are
returned.

=cut

=scenario building

Building up an HTTP request is extremely easy, simply call the L</resource> to
create a new object instance representing the API endpoint you wish to issue a
request against.

=example building

  # given: synopsis

  my $resource = $client->resource('get');

  # GET /get
  my $get = $client->resource('get')->dispatch;

  # HEAD /head
  my $head = $client->resource('head')->dispatch(
    method => 'head'
  );

  # PATCH /patch
  my $patch = $client->resource('patch')->dispatch(
    method => 'patch'
  );

  [$get, $head, $patch]

=cut

=scenario chaining

Because each call to L</resource> returns a new object instance configured with
a path (resource locator) based on the supplied parameters, reuse and request
isolation are made simple, i.e., you will only need to configure the client
once in your application.

=example chaining

  # given: synopsis

  # https://httpbin.org/users
  my $users = $client->resource('users');

  # https://httpbin.org/users/c09e91a
  my $user = $client->resource('users', 'c09e91a');

  # https://httpbin.org/users/c09e91a
  my $new_user = $users->resource('c09e91a');

  [$users, $user, $new_user]

=cut

=scenario fetching

This example illustrates how you might fetch an API resource.

=example fetching

  # given: synopsis

  my $tx1 = $client->resource('get')->fetch(
    query => {active => 1}
  );

  # is equivalent to

  my $tx2 = $client->resource('get')->dispatch(
    method => 'get',
    query => {active => 1}
  );

  [$tx1, $tx2]

=cut

=scenario creating

This example illustrates how you might create a new API resource.

=example creating

  # given: synopsis

  my $tx1 = $client->resource('post')->create(
    json => {active => 1}
  );

  # is equivalent to

  my $tx2 = $client->resource('post')->dispatch(
    method => 'post',
    json => {active => 1}
  );

  [$tx1, $tx2]

=cut

=scenario updating

This example illustrates how you might update a new API resource.

=example updating

  # given: synopsis

  my $tx1 = $client->resource('put')->update(
    json => {active => 1}
  );

  # is equivalent to

  my $tx2 = $client->resource('put')->dispatch(
    method => 'put',
    json => {active => 1}
  );

  [$tx1, $tx2]

=cut

=scenario deleting

This example illustrates how you might delete a new API resource.

=example deleting

  # given: synopsis

  my $tx1 = $client->resource('delete')->delete(
    json => {active => 1}
  );

  # is equivalent to

  my $tx2 = $client->resource('delete')->dispatch(
    method => 'delete',
    json => {active => 1}
  );

  [$tx1, $tx2]

=cut

=scenario transacting

An HTTP request is only issued when the L</dispatch> method is called, directly
or indirectly. Those calls return a L<Mojo::Transaction> object which provides
access to the C<request> and C<response> objects.

=example transacting

  # given: synopsis

  my $tx1 = $client->resource('patch')->patch(
    json => {active => 1}
  );

  # is equivalent to

  my $tx2 = $client->resource('patch')->dispatch(
    method => 'patch',
    json => {active => 1}
  );

  [$tx1, $tx2]

=cut

=scenario subclassing

This package was designed to be subclassed and provides hooks into the client
building and request dispatching processes. Specifically, there are three
useful hooks (i.e. methods, which if present are used to build up the client
object and requests), which are, the C<auth> hook, which should return a
C<Tuple[Str, Str]> which is used to configure the basic auth header, the
C<base> hook which should return a C<Tuple[Str]> which is used to configure the
base URL, and the C<headers> hook, which should return a
C<ArrayRef[Tuple[Str, Str]]> which are used to configure the HTTP request
headers.

=example subclassing

  package Hookbin;

  use Data::Object::Class;

  extends 'API::Client';

  sub auth {
    ['admin', 'secret']
  }

  sub headers {
    [['Accept', '*/*']]
  }

  sub base {
    ['https://httpbin.org/get']
  }

  package main;

  my $hookbin = Hookbin->new;

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

    $subs->scenario('building', fun($tryable) {
      require Scalar::Util;
      ok my $result = $tryable->result;

      my $get = $result->[0];
      my $head = $result->[1];
      my $patch = $result->[2];

      isnt Scalar::Util::refaddr($get), Scalar::Util::refaddr($head);
      isnt Scalar::Util::refaddr($get), Scalar::Util::refaddr($patch);
      isnt Scalar::Util::refaddr($head), Scalar::Util::refaddr($patch);

      is $get->req->method, 'get';
      is $head->req->method, 'head';
      is $patch->req->method, 'patch';
    });

    $subs->scenario('chaining', fun($tryable) {
      require Scalar::Util;
      ok my $result = $tryable->result;

      my $users = $result->[0];
      my $user = $result->[1];
      my $new_user = $result->[2];

      isnt Scalar::Util::refaddr($users), Scalar::Util::refaddr($user);
      isnt Scalar::Util::refaddr($users), Scalar::Util::refaddr($new_user);
      isnt Scalar::Util::refaddr($user), Scalar::Util::refaddr($new_user);

      is $users->url->to_string, 'https://httpbin.org/users';
      is $user->url->to_string, 'https://httpbin.org/users/c09e91a';
      is $new_user->url->to_string, 'https://httpbin.org/users/c09e91a';
    });

    $subs->scenario('fetching', fun($tryable) {
      ok my $result = $tryable->result;

      ;
    });

    $subs->scenario('creating', fun($tryable) {
      ok my $result = $tryable->result;

      ;
    });

    $subs->scenario('updating', fun($tryable) {
      ok my $result = $tryable->result;

      ;
    });

    $subs->scenario('deleting', fun($tryable) {
      ok my $result = $tryable->result;

      ;
    });

    $subs->scenario('transacting', fun($tryable) {
      ok my $result = $tryable->result;

      ;
    });

    $subs->scenario('subclassing', fun($tryable) {
      ok my $result = $tryable->result;
      ok $result->isa('Hookbin');
      ok $result->isa('API::Client');

      is_deeply $result->auth, ['admin', 'secret'];
      is_deeply $result->headers, [['Accept', '*/*']];
      is_deeply $result->base, ['https://httpbin.org/get'];
      is $result->url->to_string, 'https://httpbin.org/get';
      is $result->name, 'Hookbin (0.01)';
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
