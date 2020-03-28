package API::Client;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use FlightRecorder;
use Mojo::Transaction;
use Mojo::UserAgent;
use Mojo::URL;

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Stashable';
with 'Data::Object::Role::Throwable';

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has 'debug' => (
  is => 'ro',
  isa => 'Bool',
  def => 0,
);

has 'fatal' => (
  is => 'ro',
  isa => 'Bool',
  def => 0,
);

has 'logger' => (
  is => 'ro',
  isa => 'InstanceOf["FlightRecorder"]',
  new => 1,
);

fun new_logger($self) {
  FlightRecorder->new
}

has 'name' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_name($self) {
  "@{[ref($self)]} (@{[$self->version]})"
}

has 'retries' => (
  is => 'ro',
  isa => 'Int',
  def => 0,
);

has 'timeout' => (
  is => 'ro',
  isa => 'Int',
  def => 10,
);

has 'url' => (
  is => 'ro',
  isa => 'InstanceOf["Mojo::URL"]',
  opt => 1,
);

has 'user_agent' => (
  is => 'ro',
  isa => 'InstanceOf["Mojo::UserAgent"]',
  new => 1,
);

fun new_user_agent($self) {
  Mojo::UserAgent->new
}

has 'version' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_version($self) {
  $self->VERSION || 0.01
}

# BUILD

method build_args($args) {
  if (!ref $args->{url}) {
    $args->{url} = Mojo::URL->new($args->{url}) if $args->{url};
  }

  return $args;
}

method build_self($args) {
  if (!$self->{url} && $self->can('base')) {
    $self->{url} = Mojo::URL->new(join('/', @{$self->base($args)}));
  }

  return $self;
}

# METHODS

method create(Any %args) {

  return $self->dispatch(%args, method => 'post');
}

method delete(Any %args) {

  return $self->dispatch(%args, method => 'delete');
}

method dispatch(Str :$method = 'get', Any %args) {
  my $log = $self->logger->info("@{[uc($method)]} @{[$self->url->to_string]}");

  my $result = $self->execute(%args, method => $method);

  $log->end;

  return $result;
}

method fetch(Any %args) {

  return $self->dispatch(%args, method => 'get');
}

method patch(Any %args) {

  return $self->dispatch(%args, method => 'patch');
}

method update(Any %args) {

  return $self->dispatch(%args, method => 'put');
}

method prepare(Object $ua, Object $tx, Any %args) {
  $self->set_auth($ua, $tx, %args);
  $self->set_headers($ua, $tx, %args);
  $self->set_identity($ua, $tx, %args);

  return $self;
}

method process(Object $ua, Object $tx, Any %args) {

  return $self;
}

method resource(Str @segments) {
  my $url;

  if (@segments) {
    $url = $self->url->clone;

    $url->path->merge(
      join '/', '', @{$self->url->path->parts}, @segments
    );
  }

  my $object = ref($self)->new(
    %{$self->serialize}, ($url ? ('url', $url) : ())
  );

  return $object;
}

method serialize() {

  return {
    debug => $self->debug,
    fatal => $self->fatal,
    name => $self->name,
    retries => $self->retries,
    timeout => $self->timeout,
    url => $self->url->to_string,
  };
}

method set_auth($ua, $tx, %args) {
  if ($self->can('auth')) {
    $tx->req->url->userinfo(join ':', @{$self->auth});
  }

  return $self;
}

method set_headers($ua, $tx, %args) {
  if ($self->can('headers')) {
    $tx->req->headers->header(@$_) for @{$self->headers};
  } else {
    $tx->req->headers->header('Content-Type' => 'application/json');
  }

  return $self;
}

method set_identity($ua, $tx, %args) {
  $tx->req->headers->header('User-Agent' => $self->name);

  return $self;
}

method execute(Str :$method = 'get', Str :$path = '', Any %args) {
  delete $args{method};

  my $ua = $self->user_agent;
  my $url = $self->url->clone;

  my $query = $args{query} || {};
  my $headers = $args{headers} || {};

  $url->path(join '/', $url->path, $path) if $path;
  $url->query($url->query->merge(%$query)) if keys %$query;

  my @args;

  # data handlers
  for my $type (sort keys %{$ua->transactor->generators}) {
    push @args, $type, delete $args{$type} if $args{$type};
  }

  # handle raw body value
  push @args, delete $args{body} if exists $args{body};

  # transaction prepare hook
  $ua->on(prepare => fun ($ua, $tx) {
    $self->prepare($ua, $tx, %args);
  });

  # client timeouts
  $ua->max_redirects(0);
  $ua->connect_timeout($self->timeout);
  $ua->request_timeout($self->timeout);

  # transaction
  my ($ok, $tx, $req, $res);

  # times to retry failures
  my $retries = $self->retries;

  # transaction retry loop
  for (my $i = 0; $i < ($retries || 1); $i++) {
    # execute transaction
    $tx = $ua->start($ua->build_tx($method, $url, $headers, @args));
    $self->process($ua, $tx, %args);

    # transaction objects
    $req = $tx->req;
    $res = $tx->res;

    # determine success/failure
    $ok = $res->code ? $res->code !~ /(4|5)\d\d/ : 0;

    # log activity
    if ($req && $res) {
      my $log = $self->logger;
      my $msg = join " ", "attempt", ("#".($i+1)), ": $method", $url->to_string;

      $log->debug("req: $msg")->data({
        request => $req->to_string =~ s/\s*$/\n\n\n/r
      });

      $log->debug("res: $msg")->data({
        response => $res->to_string =~ s/\s*$/\n\n\n/r
      });

      # output to the console where applicable
      $log->info("res: $msg [@{[$res->code]}]");
      $log->output if $self->debug;
    }

    # no retry necessary
    last if $ok;
  }

  # throw exception if fatal is truthy
  if ($req && $res && $self->fatal && !$ok) {
    my $code = $res->code;

    $self->stash(tx => $tx);
    $self->throw([$code, uc "${code}_http_response"]);
  }

  # return transaction
  return $tx;
}

1;

=encoding utf8

=head1 NAME

API::Client

=cut

=head1 ABSTRACT

HTTP API Thin-Client Abstraction

=cut

=head1 SYNOPSIS

  package main;

  use API::Client;

  my $client = API::Client->new(url => 'https://httpbin.org');

  # $client->resource('post');

  # $client->update(json => {...});

=cut

=head1 DESCRIPTION

This package provides an abstraction and method for rapidly developing HTTP API
clients. While this module can be used to interact with APIs directly,
API::Client was designed to be consumed (subclassed) by higher-level
purpose-specific API clients.

=head1 THIN CLIENT

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

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

L<Data::Object::Role::Stashable>

L<Data::Object::Role::Throwable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 building

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

Building up an HTTP request is extremely easy, simply call the L</resource> to
create a new object instance representing the API endpoint you wish to issue a
request against.

=cut

=head2 chaining

  # given: synopsis

  # https://httpbin.org/users
  my $users = $client->resource('users');

  # https://httpbin.org/users/c09e91a
  my $user = $client->resource('users', 'c09e91a');

  # https://httpbin.org/users/c09e91a
  my $new_user = $users->resource('c09e91a');

  [$users, $user, $new_user]

Because each call to L</resource> returns a new object instance configured with
a path (resource locator) based on the supplied parameters, reuse and request
isolation are made simple, i.e., you will only need to configure the client
once in your application.

=cut

=head2 creating

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

This example illustrates how you might create a new API resource.

=cut

=head2 deleting

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

This example illustrates how you might delete a new API resource.

=cut

=head2 fetching

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

This example illustrates how you might fetch an API resource.

=cut

=head2 subclassing

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

This package was designed to be subclassed and provides hooks into the client
building and request dispatching processes. Specifically, there are three
useful hooks (i.e. methods, which if present are used to build up the client
object and requests), which are, the C<auth> hook, which should return a
C<Tuple[Str, Str]> which is used to configure the basic auth header, the
C<base> hook which should return a C<Tuple[Str]> which is used to configure the
base URL, and the C<headers> hook, which should return a
C<ArrayRef[Tuple[Str, Str]]> which are used to configure the HTTP request
headers.

=cut

=head2 transacting

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

An HTTP request is only issued when the L</dispatch> method is called, directly
or indirectly. Those calls return a L<Mojo::Transaction> object which provides
access to the C<request> and C<response> objects.

=cut

=head2 updating

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

This example illustrates how you might update a new API resource.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 debug

  debug(Bool)

This attribute is read-only, accepts C<(Bool)> values, and is optional.

=cut

=head2 fatal

  fatal(Bool)

This attribute is read-only, accepts C<(Bool)> values, and is optional.

=cut

=head2 logger

  logger(InstanceOf["FlightRecorder"])

This attribute is read-only, accepts C<(InstanceOf["FlightRecorder"])> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 retries

  retries(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

=cut

=head2 timeout

  timeout(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

=cut

=head2 url

  url(InstanceOf["Mojo::URL"])

This attribute is read-only, accepts C<(InstanceOf["Mojo::URL"])> values, and is optional.

=cut

=head2 user_agent

  user_agent(InstanceOf["Mojo::UserAgent"])

This attribute is read-only, accepts C<(InstanceOf["Mojo::UserAgent"])> values, and is optional.

=cut

=head2 version

  version(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 create

  create(Any %args) : InstanceOf["Mojo::Transaction"]

The create method issues a C<POST> request to the API resource represented by
the object.

=over 4

=item create example #1

  # given: synopsis

  $client->resource('post')->create(
    json => {active => 1}
  );

=back

=cut

=head2 delete

  delete(Any %args) : InstanceOf["Mojo::Transaction"]

The delete method issues a C<DELETE> request to the API resource represented by
the object.

=over 4

=item delete example #1

  # given: synopsis

  $client->resource('delete')->delete;

=back

=cut

=head2 dispatch

  dispatch(Str :$method = 'get', Any %args) : InstanceOf["Mojo::Transaction"]

The dispatch method issues a request to the API resource represented by the
object.

=over 4

=item dispatch example #1

  # given: synopsis

  $client->resource('get')->dispatch;

=back

=over 4

=item dispatch example #2

  # given: synopsis

  $client->resource('post')->dispatch(
    method => 'post', body => 'active=1'
  );

=back

=over 4

=item dispatch example #3

  # given: synopsis

  $client->resource('get')->dispatch(
    method => 'get', query => {active => 1}
  );

=back

=over 4

=item dispatch example #4

  # given: synopsis

  $client->resource('post')->dispatch(
    method => 'post', json => {active => 1}
  );

=back

=over 4

=item dispatch example #5

  # given: synopsis

  $client->resource('post')->dispatch(
    method => 'post', form => {active => 1}
  );

=back

=over 4

=item dispatch example #6

  # given: synopsis

  $client->resource('put')->dispatch(
    method => 'put', json => {active => 1}
  );

=back

=over 4

=item dispatch example #7

  # given: synopsis

  $client->resource('patch')->dispatch(
    method => 'patch', json => {active => 1}
  );

=back

=over 4

=item dispatch example #8

  # given: synopsis

  $client->resource('delete')->dispatch(
    method => 'delete', json => {active => 1}
  );

=back

=cut

=head2 fetch

  fetch(Any %args) : InstanceOf["Mojo::Transaction"]

The fetch method issues a C<GET> request to the API resource represented by the
object.

=over 4

=item fetch example #1

  # given: synopsis

  $client->resource('get')->fetch;

=back

=cut

=head2 patch

  patch(Any %args) : InstanceOf["Mojo::Transaction"]

The patch method issues a C<PATCH> request to the API resource represented by
the object.

=over 4

=item patch example #1

  # given: synopsis

  $client->resource('patch')->patch(
    json => {active => 1}
  );

=back

=cut

=head2 prepare

  prepare(Object $ua, Object $tx, Any %args) : Object

The prepare method acts as a C<before> hook triggered before each request where
you can modify the transactor objects.

=over 4

=item prepare example #1

  # given: synopsis

  require Mojo::UserAgent;
  require Mojo::Transaction::HTTP;

  $client->prepare(
    Mojo::UserAgent->new,
    Mojo::Transaction::HTTP->new
  );

=back

=cut

=head2 process

  process(Object $ua, Object $tx, Any %args) : Object

The process method acts as an C<after> hook triggered after each response where
you can modify the transactor objects.

=over 4

=item process example #1

  # given: synopsis

  require Mojo::UserAgent;
  require Mojo::Transaction::HTTP;

  $client->process(
    Mojo::UserAgent->new,
    Mojo::Transaction::HTTP->new
  );

=back

=cut

=head2 resource

  resource(Str @segments) : Object

The resource method returns a new instance of the object for the API resource
endpoint specified.

=over 4

=item resource example #1

  # given: synopsis

  $client->resource('status', 200);

=back

=cut

=head2 serialize

  serialize() : HashRef

The serialize method serializes and returns the object as a C<hashref>.

=over 4

=item serialize example #1

  # given: synopsis

  $client->serialize;

=back

=cut

=head2 update

  update(Any %args) : InstanceOf["Mojo::Transaction"]

The update method issues a C<PUT> request to the API resource represented by
the object.

=over 4

=item update example #1

  # given: synopsis

  $client->resource('put')->update(
    json => {active => 1}
  );

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/api-client/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/api-client/wiki>

L<Project|https://github.com/iamalnewkirk/api-client>

L<Initiatives|https://github.com/iamalnewkirk/api-client/projects>

L<Milestones|https://github.com/iamalnewkirk/api-client/milestones>

L<Contributing|https://github.com/iamalnewkirk/api-client/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/api-client/issues>

=cut
