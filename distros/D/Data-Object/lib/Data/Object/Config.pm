package Data::Object::Config;

use strict;
use warnings;

use Data::Object::Export qw(
  croak
  namespace
  registry
);

use Import::Into;
use Type::Tiny;

# BUILD

sub import {
  my ($class, $type, $meta) = @_;

  process(scalar(caller), prepare($class, $type), $type, $meta);

  return;
}

# METHODS

sub choose {
  my ($type) = @_;

  # * specail config pl
  if (subject($type, 'pl')) {
    return 'config_cli';
  }

  # * specail config pm
  if (subject($type, 'pm')) {
    return 'config_class';
  }

  # config cli
  if (subject($type, 'cli')) {
    return 'config_cli';
  }

  # * specail config core
  if (subject($type, 'core')) {
    return;
  }

  # config array
  if (subject($type, 'array')) {
    return 'config_array';
  }

  # config code
  if (subject($type, 'code')) {
    return 'config_code';
  }

  # config dispatch
  if (subject($type, 'dispatch')) {
    return 'config_dispatch';
  }

  # config exception
  if (subject($type, 'exception')) {
    return 'config_exception';
  }

  # config float
  if (subject($type, 'float')) {
    return 'config_float';
  }

  # config hash
  if (subject($type, 'hash')) {
    return 'config_hash';
  }

  # config integer
  if (subject($type, 'integer')) {
    return 'config_integer';
  }

  # config kind
  if (subject($type, 'kind')) {
    return 'config_kind';
  }

  # config number
  if (subject($type, 'number')) {
    return 'config_number';
  }

  # config regexp
  if (subject($type, 'regexp')) {
    return 'config_regexp';
  }

  # config replace
  if (subject($type, 'replace')) {
    return 'config_replace';
  }

  # config scalar
  if (subject($type, 'scalar')) {
    return 'config_scalar';
  }

  # config search
  if (subject($type, 'search')) {
    return 'config_search';
  }

  # config state
  if (subject($type, 'state')) {
    return 'config_state';
  }

  # config string
  if (subject($type, 'string')) {
    return 'config_string';
  }

  # config type
  if (subject($type, 'type')) {
    return 'config_type';
  }

  # config undef
  if (subject($type, 'undef')) {
    return 'config_undef';
  }

  # config class
  if (subject($type, 'class')) {
    return 'config_class';
  }

  # config role
  if (subject($type, 'role')) {
    return 'config_role';
  }

  # config rule
  if (subject($type, 'rule')) {
    return 'config_rule';
  }

  # config json
  if (subject($type, 'json')) {
    return 'config_json';
  }

  # config path
  if (subject($type, 'path')) {
    return 'config_path';
  }

  # config tmpl
  if (subject($type, 'tmpl')) {
    return 'config_tmpl';
  }

  # config try
  if (subject($type, 'try')) {
    return 'config_try';
  }

  # config yaml
  if (subject($type, 'yaml')) {
    return 'config_yaml';
  }

  return;
}

sub prepare {
  my ($class, $type) = @_;

  my $plans;
  my $config = choose($type);

  no strict 'refs';

  $plans = &$config() if $config;

  return config($plans);
}

sub process {
  my ($target, $plans, $type, $meta) = @_;

  for my $plan (@$plans) {
    if ($plan->[0] eq 'add') {
      process_add($target, $plan);
    }
    if ($plan->[0] eq 'call') {
      process_call($target, $plan);
    }
    if ($plan->[0] eq 'use') {
      process_use($target, $plan);
    }
  }

  # experimental! auto-register type
  _process_meta($target, $type, $meta) if $meta;

  return;
}

sub prepare_add {
  my ($class, $func) = @_;

  return ['add', $class, $func];
}

sub process_add {
  my ($target, $plan) = @_;

  my ($action, $package, $name) = @$plan;

  no warnings 'redefine', 'prototype';

  *{"${target}::${name}"} = $package->can($name);

  return;
}

sub prepare_call {
  my ($func, @args) = @_;

  return ['call', $func, @args];
}

sub process_call {
  my ($target, $plan) = @_;

  my ($action, $name, @args) = @$plan;

  $target->can($name)->(@args);

  return;
}

sub prepare_use {
  my ($class, @args) = @_;

  return ['use', $class, @args];
}

sub process_use {
  my ($target, $plan) = @_;

  my ($action, $package, @args) = @$plan;

  import::into($package, $target, @args);

  return;
}

sub subject {
  my ($type, $name) = @_;

  return 0 if !$type;

  $type =~ s/^\W//g;

  return 1 if lc($type) eq lc($name);

  return 0;
}

sub config {
  [
    # basics
    prepare_use('strict'),
    prepare_use('warnings'),
    prepare_use('feature', 'say'),
    prepare_use('feature', 'state'),

    # types and signatures
    prepare_use('Data::Object::Config::Library'),
    prepare_use('Data::Object::Config::Signatures'),

    # contextual
    ($_[0] ? @{$_[0]} : ()),

    # tools and functions
    prepare_use('Data::Object::Export'),

    # special function
    prepare_use('subs', 'do')
  ]
}

sub config_cli {
  [
    @{config_class()},
    prepare_call('extends', 'Data::Object::Cli')
  ]
}

sub config_array {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Array')
  ]
}

sub config_code {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Code')
  ]
}

sub config_dispatch {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Dispatch')
  ]
}

sub config_exception {
  [
    @{config_class()},
    prepare_call('extends', 'Data::Object::Exception')
  ]
}

sub config_float {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Float')
  ]
}

sub config_hash {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Hash')
  ]
}

sub config_integer {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Integer')
  ]
}

sub config_json {
  [
    prepare_use('Data::Object::Export', 'data_json')
  ]
}

sub config_kind {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Kind')
  ]
}

sub config_number {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Number')
  ]
}

sub config_path {
  [
    prepare_use('Data::Object::Export', 'data_path')
  ]
}

sub config_regexp {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Regexp')
  ]
}

sub config_replace {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Replace')
  ]
}

sub config_scalar {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Scalar')
  ]
}

sub config_search {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Search')
  ]
}

sub config_state {
  [
    prepare_use('Data::Object::State'),
    prepare_use('Data::Object::Config::Class', { replace => 1 }, 'has')
  ]
}

sub config_string {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::String')
  ]
}

sub config_tmpl {
  [
    prepare_use('Data::Object::Export', 'data_tmpl')
  ]
}

sub config_try {
  [
    prepare_use('Try::Tiny')
  ]
}

sub config_type {
  [
    @{config_class()},
    prepare_call('extends', 'Data::Object::Kind')
  ]
}

sub config_yaml {
  [
    prepare_use('Data::Object::Export', 'data_yaml')
  ]
}

sub config_undef {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Undef')
  ]
}

sub config_class {
  [
    prepare_use('Data::Object::Class'),
    prepare_use('Data::Object::Config::Class', { replace => 1 }, 'has')
  ]
}

sub config_role {
  [
    prepare_use('Data::Object::Role'),
    prepare_use('Data::Object::Config::Role', { replace => 1 }, 'has')
  ]
}

sub config_rule {
  [
    prepare_use('Data::Object::Rule'),
    prepare_use('Data::Object::Config::Role', { replace => 1 }, 'has')
  ]
}

# experimental!
sub _process_meta {
  my ($target, $type, $meta) = @_;

  my $parent;

  # get the plan name
  my $config = choose($type) || '';

  # set the parent type
  if (!$parent && $config eq 'config_role') {
    $parent = 'ConsumerOf';
  }
  if (!$parent && $config eq 'config_rule') {
    $parent = 'ConsumerOf';
  }
  if (!$parent) {
    $parent = 'InstanceOf';
  }

  # map target to typelib
  my $namespace = _process_typelib($target, $meta);

  # attempt to load the type library from disk if not already loaded
  eval "require $namespace";

  # ensure that the type library is valid and operable
  croak "$namespace is not a valid type library" unless $namespace->isa('Type::Library');

  # build type-tiny constraint for target, then add constraint to typelib
  _process_typereg($namespace, _process_typetiny(registry(), $target, $parent));

  return;
}

# experimental!
sub _process_typelib {
  my ($target, $meta) = @_;

  # register target <-> typelib so target can use typelib
  return namespace($target, ref($meta) ? join('-', @$meta) : $meta);
}

# experimental!
sub _process_typereg {
  my ($namespace, $constraint) = @_;

  # add type constraint to the user-defined type-library
  return $namespace->get_type($constraint->name) || $namespace->add_type($constraint);
}

# experimental!
sub _process_typetiny {
  my ($registry, $target, $reference) = @_;

  # core typelib has InstanceOf and ConsumerOf type objects
  my $library = $registry->def;

  # type constraint name from target package name
  my $name = ucfirst $target =~ s/\W//gr;

  # new parameterized InstanceOf or ConsumerOf for target
  my $parent = $library->get_type($reference)->of($target);

  # return new type-tiny type constraint
  return Type::Tiny->new(name => $name, parent => $parent);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Config

=cut

=head1 ABSTRACT

Data-Object Package Configuration

=cut

=head1 SYNOPSIS

  use Data::Object::Config;

=cut

=head1 DESCRIPTION

Data::Object::Config is used to configure the consuming package based on
arguments passed to the import statement.

=cut

=head1 FUNCTIONS

This package implements the following functions.

=cut

=head2 choose

  choose('class');

The choose function returns the configuration (plans) based on the argument passed.

=cut

=head2 prepare

  prepare($package, $type);

The prepare function returns configuration plans based on the arguments passed.

=cut

=head2 process

  process($caller, $plans);

The process function executes a series of plans on behalf of the caller.

=cut

=head2 prepare_add

  prepare_add($package, $function);

The prepare_add function returns an add-plan for the arguments passed.

=cut

=head2 process_add

  process_add($caller, $plan);

The process_add function executes the add-plan on behalf of the caller.

=cut

=head2 prepare_call

  prepare_call($function, @args);

The prepare_call function returns a call-plan for the arguments passed.

=cut

=head2 process_call

  process_call($caller, $plan);

The process_call function executes the call-plan on behalf of the caller.

=cut

=head2 prepare_use

  prepare_use($package, @args);

The prepare_use function returns a use-plan for the arguments passed.

=cut

=head2 process_use

  process_use($caller, $plan);

The process_use function executes the use-plan on behalf of the caller.

=cut

=head2 subject

  subject('-Role', 'Role');

The subject function returns truthy if both arguments match alphanumerically (not case-sensitive).

=cut

=head2 config

  my $plans = config;

The config function returns plans for configuring a package with the standard
L<Data::Object> setup.

=cut

=head2 config_cli

  my $plans = config_cli;

The config_cli function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Cli>.

=cut

=head2 config_array

  my $plans = config_array;

The config_array function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Array>.

=cut

=head2 config_code

  my $plans = config_code;

The config_code function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Code>.

=cut

=head2 config_dispatch

  my $plans = config_dispatch;

The config_dispatch function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Dispatch>.

=cut

=head2 config_exception

  my $plans = config_exception;

The config_exception function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Exception>.

=cut

=head2 config_float

  my $plans = config_float;

The config_float function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Float>.

=cut

=head2 config_hash

  my $plans = config_hash;

The config_hash function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Hash>.

=cut

=head2 config_integer

  my $plans = config_integer;

The config_integer function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Integer>.

=cut

=head2 config_json

  my $plans = config_json;

The config_json function returns plans for configuring the package to have a
C<json> function that loads a L<Data::Object::Json> object.

=cut

=head2 config_kind

  my $plans = config_kind;

The config_kind function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Kind>.

=cut

=head2 config_number

  my $plans = config_number;

The config_number function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Number>.

=cut

=head2 config_path

  my $plans = config_path;

The config_path function returns plans for configuring the package to have a
C<path> function that loads a L<Data::Object::Path> object.

=cut

=head2 config_regexp

  my $plans = config_regexp;

The config_regexp function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Regexp>.

=cut

=head2 config_replace

  my $plans = config_replace;

The config_replace function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Replace>.

=cut

=head2 config_scalar

  my $plans = config_scalar;

The config_scalar function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Scalar>.

=cut

=head2 config_search

  my $plans = config_search;

The config_search function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Search>.

=cut

=head2 config_state

  my $plans = config_state;

The config_state function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::State>.

=cut

=head2 config_string

  my $plans = config_string;

The config_string function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::String>.

=cut

=head2 config_tmpl

  my $plans = config_tmpl;

The config_tmpl function returns plans for configuring the package to have a
C<tmpl> function that loads a L<Data::Object::Template> object.

=cut

=head2 config_try

  my $plans = config_try;

The config_try function returns plans for configuring the package to have
C<try> and C<catch> constructs for trapping exceptions.

=cut

=head2 config_type

  my $plans = config_type;

The config_type function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Type>.

=cut

=head2 config_yaml

  my $plans = config_yaml;

The config_yaml function returns plans for configuring the package to have a
C<yaml> function that loads a L<Data::Object::Yaml> object.

=cut

=head2 config_undef

  my $plans = config_undef;

The config_undef function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Undef>.

=cut

=head2 config_class

  my $plans = config_class;

The config_class function returns plans for configuring the package to be a
L<Data::Object::Class>.

=cut

=head2 config_role

  my $plans = config_role;

The config_role function returns plans for configuring the package to be a
L<Data::Object::Role>.

=cut

=head2 config_rule

  my $plans = config_rule;

The config_rule function returns plans for configuring a package to be a
L<Data::Object::Rule>.

=cut
