package Data::Object::Opts;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Proxyable';
with 'Data::Object::Role::Stashable';

use Getopt::Long ();

our $VERSION = '2.00'; # VERSION

# ATTRIBUTES

has 'args' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1,
);

has 'spec' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1,
);

has 'named' => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1,
);

# BUILD

method build_self($args) {
  $self->{named} = {} if !$args->{named};

  $self->{args} = [] if !$args->{args};
  $self->{spec} = [] if !$args->{spec};

  $self->{args} = [@ARGV] if !@{$self->{args}};

  my $warn = [];

  local $SIG{__WARN__} = sub {
    push @$warn, [@_];

    return;
  };

  $self->stash(opts => $self->parse($args->{opts}));
  $self->stash(warn => $warn) if $warn;

  return $self;
}

method build_proxy($package, $method, $value) {
  my $has_value = exists $_[2];

  return sub {

    return $self->get($method) if !$has_value; # no val

    return $self->set($method, $value);
  };
}


# METHODS

method exists($key) {
  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return exists $self->stashed->{$pos};
}

method get($key) {
  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return $self->stashed->{$pos};
}

method name($key) {
  if (defined $self->named->{$key}) {
    return $self->named->{$key};
  }

  if (defined $self->stashed->{$key}) {
    return $key;
  }

  return undef;
}

method set($key, $val) {
  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return $self->stashed->{$pos} = $val;
}

method parse($extras) {
  my $args = $self->args;
  my $spec = $self->spec;

  my $options = {};
  my @configs = qw(default no_auto_abbrev no_ignore_case);

  $extras = [] if !$extras;

  # configure parser
  Getopt::Long::Configure(Getopt::Long::Configure(@configs, @$extras));

  # parse args using spec
  Getopt::Long::GetOptionsFromArray([@$args], $options, @$spec);

  return $options;
}

method stashed() {
  my $data = $self->stash('opts');

  return $data;
}

method warned() {
  my $data = $self->stash('warn');

  return scalar @$data;
}

method warnings() {
  my $data = $self->stash('warn');

  return $data;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Opts

=cut

=head1 ABSTRACT

Opts Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Opts;

  my $opts = Data::Object::Opts->new(
    args => ['--resource', 'users', '--help'],
    spec => ['resource|r=s', 'help|h'],
    named => { method => 'resource' } # optional
  );

  # $opts->method; # $resource
  # $opts->get('resource'); # $resource

  # $opts->help; # $help
  # $opts->get('help'); # $help

=cut

=head1 DESCRIPTION

This package provides methods for accessing command-line arguments.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

L<Data::Object::Role::Proxyable>

L<Data::Object::Role::Stashable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 args

  args(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 named

  named(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is optional.

=cut

=head2 spec

  spec(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 exists

  exists(Str $key) : Any

The exists method takes a name or index and returns truthy if an associated
value exists.

=over 4

=item exists example #1

  # given: synopsis

  $opts->exists('resource'); # truthy

=back

=over 4

=item exists example #2

  # given: synopsis

  $opts->exists('method'); # truthy

=back

=over 4

=item exists example #3

  # given: synopsis

  $opts->exists('resources'); # falsy

=back

=cut

=head2 get

  get(Str $key) : Any

The get method takes a name or index and returns the associated value.

=over 4

=item get example #1

  # given: synopsis

  $opts->get('resource'); # users

=back

=over 4

=item get example #2

  # given: synopsis

  $opts->get('method'); # users

=back

=over 4

=item get example #3

  # given: synopsis

  $opts->get('resources'); # undef

=back

=cut

=head2 name

  name(Str $key) : Any

The name method takes a name or index and returns index if the the associated
value exists.

=over 4

=item name example #1

  # given: synopsis

  $opts->name('resource'); # resource

=back

=over 4

=item name example #2

  # given: synopsis

  $opts->name('method'); # resource

=back

=over 4

=item name example #3

  # given: synopsis

  $opts->name('resources'); # undef

=back

=cut

=head2 parse

  parse(Maybe[ArrayRef] $config) : HashRef

The parse method optionally takes additional L<Getopt::Long> parser
configuration options and retuns the options found based on the object C<args>
and C<spec> values.

=over 4

=item parse example #1

  # given: synopsis

  $opts->parse;

=back

=over 4

=item parse example #2

  # given: synopsis

  $opts->parse(['bundling']);

=back

=cut

=head2 set

  set(Str $key, Maybe[Any] $value) : Any

The set method takes a name or index and sets the value provided if the
associated argument exists.

=over 4

=item set example #1

  # given: synopsis

  $opts->set('method', 'people'); # people

=back

=over 4

=item set example #2

  # given: synopsis

  $opts->set('resource', 'people'); # people

=back

=over 4

=item set example #3

  # given: synopsis

  $opts->set('resources', 'people'); # undef

  # is not set

=back

=cut

=head2 stashed

  stashed() : HashRef

The stashed method returns the stashed data associated with the object.

=over 4

=item stashed example #1

  # given: synopsis

  $opts->stashed;

=back

=cut

=head2 warned

  warned() : Num

The warned method returns the number of warnings emitted during option parsing.

=over 4

=item warned example #1

  package main;

  use Data::Object::Opts;

  my $opts = Data::Object::Opts->new(
    args => ['-vh'],
    spec => ['verbose|v', 'help|h']
  );

  $opts->warned;

=back

=cut

=head2 warnings

  warnings() : ArrayRef[ArrayRef[Str]]

The warnings method returns the set of warnings emitted during option parsing.

=over 4

=item warnings example #1

  package main;

  use Data::Object::Opts;

  my $opts = Data::Object::Opts->new(
    args => ['-vh'],
    spec => ['verbose|v', 'help|h']
  );

  $opts->warnings;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-opts/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-opts/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-opts>

L<Initiatives|https://github.com/iamalnewkirk/data-object-opts/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-opts/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-opts/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-opts/issues>

=cut
