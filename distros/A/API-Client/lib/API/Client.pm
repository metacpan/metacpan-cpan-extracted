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

our $VERSION = '0.10'; # VERSION

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
  req => 1,
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
  if (!$args->{url}) {
    $args->{url} = join('/', @{$self->base(%$args)}) if $self->can('base');
  }
  if (!ref $args->{url}) {
    $args->{url} = Mojo::URL->new($args->{url}) if $args->{url};
  }

  return $args;
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
  my $object = ref($self)->new($self->serialize);

  $object->url->path(join '/', @segments) if @segments;

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
clients.

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
