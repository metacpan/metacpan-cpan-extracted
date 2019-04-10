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

our $VERSION = '0.96'; # VERSION

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

  # config base
  if (subject($type, 'base')) {
    return 'config_base';
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

  # config try
  if (subject($type, 'try')) {
    return 'config_try';
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

    # say, state, switch, unicode_strings, array_base
    prepare_use('feature', ':5.14'),

    # types and signatures
    prepare_use('Data::Object::Library'),
    prepare_use('Data::Object::Signatures'),

    # contextual
    ($_[0] ? @{$_[0]} : ()),

    # tools and functions, and "do" function
    prepare_use('Data::Object::Export'),

    # make special "do" function work
    prepare_use('subs', 'do')
  ]
}

sub config_array {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Array')
  ]
}

sub config_class {
  [
    prepare_use('Data::Object::Class'),
    prepare_use('Data::Object::ClassHas')
  ]
}

sub config_cli {
  [
    @{config_class()},
    prepare_call('extends', 'Data::Object::Cli')
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

sub config_base {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Base')
  ]
}

sub config_number {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Number')
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

sub config_role {
  [
    prepare_use('Data::Object::Role'),
    prepare_use('Data::Object::RoleHas')
  ]
}

sub config_rule {
  [
    prepare_use('Data::Object::Rule'),
    prepare_use('Data::Object::RoleHas')
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
    prepare_use('Data::Object::ClassHas')
  ]
}

sub config_string {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::String')
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
    prepare_call('extends', 'Data::Object::Base')
  ]
}

sub config_undef {
  [
    prepare_use('Role::Tiny::With'),
    prepare_use('parent', 'Data::Object::Undef')
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

  choose(Str $arg1) : ArrayRef

The choose function returns the configuration (plans) based on the argument passed.

=over 4

=item choose example

  choose('class');

=back

=cut

=head2 config

  config(ArrayRef $arg1) : ArrayRef

The config function returns plans for configuring a package with the standard
L<Data::Object> setup.

=over 4

=item config example

  my $plans = config;

=back

=cut

=head2 config_array

  config_array() : ArrayRef

The config_array function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Array>.

=over 4

=item config_array example

  my $plans = config_array;

=back

=cut

=head2 config_base

  config_base() : ArrayRef

The config_base function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Base>.

=over 4

=item config_base example

  my $plans = config_base;

=back

=cut

=head2 config_class

  config_class() : ArrayRef

The config_class function returns plans for configuring the package to be a
L<Data::Object::Class>.

=over 4

=item config_class example

  my $plans = config_class;

=back

=cut

=head2 config_cli

  config_cli() : ArrayRef

The config_cli function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Cli>.

=over 4

=item config_cli example

  my $plans = config_cli;

=back

=cut

=head2 config_code

  config_code() : ArrayRef

The config_code function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Code>.

=over 4

=item config_code example

  my $plans = config_code;

=back

=cut

=head2 config_dispatch

  config_dispatch() : ArrayRef

The config_dispatch function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Dispatch>.

=over 4

=item config_dispatch example

  my $plans = config_dispatch;

=back

=cut

=head2 config_exception

  config_exception() : ArrayRef

The config_exception function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Exception>.

=over 4

=item config_exception example

  my $plans = config_exception;

=back

=cut

=head2 config_float

  config_float() : ArrayRef

The config_float function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Float>.

=over 4

=item config_float example

  my $plans = config_float;

=back

=cut

=head2 config_hash

  config_hash() : ArrayRef

The config_hash function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Hash>.

=over 4

=item config_hash example

  my $plans = config_hash;

=back

=cut

=head2 config_integer

  config_integer() : ArrayRef

The config_integer function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Integer>.

=over 4

=item config_integer example

  my $plans = config_integer;

=back

=cut

=head2 config_number

  config_number() : ArrayRef

The config_number function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Number>.

=over 4

=item config_number example

  my $plans = config_number;

=back

=cut

=head2 config_regexp

  config_regexp() : ArrayRef

The config_regexp function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Regexp>.

=over 4

=item config_regexp example

  my $plans = config_regexp;

=back

=cut

=head2 config_replace

  config_replace() : ArrayRef

The config_replace function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Replace>.

=over 4

=item config_replace example

  my $plans = config_replace;

=back

=cut

=head2 config_role

  config_role() : ArrayRef

The config_role function returns plans for configuring the package to be a
L<Data::Object::Role>.

=over 4

=item config_role example

  my $plans = config_role;

=back

=cut

=head2 config_rule

  config_rule() : ArrayRef

The config_rule function returns plans for configuring a package to be a
L<Data::Object::Rule>.

=over 4

=item config_rule example

  my $plans = config_rule;

=back

=cut

=head2 config_scalar

  config_scalar() : ArrayRef

The config_scalar function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Scalar>.

=over 4

=item config_scalar example

  my $plans = config_scalar;

=back

=cut

=head2 config_search

  config_search() : ArrayRef

The config_search function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Search>.

=over 4

=item config_search example

  my $plans = config_search;

=back

=cut

=head2 config_state

  config_state() : ArrayRef

The config_state function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::State>.

=over 4

=item config_state example

  my $plans = config_state;

=back

=cut

=head2 config_string

  config_string() : ArrayRef

The config_string function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::String>.

=over 4

=item config_string example

  my $plans = config_string;

=back

=cut

=head2 config_try

  config_try() : ArrayRef

The config_try function returns plans for configuring the package to have
C<try> and C<catch> constructs for trapping exceptions.

=over 4

=item config_try example

  my $plans = config_try;

=back

=cut

=head2 config_type

  config_type() : ArrayRef

The config_type function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Type>.

=over 4

=item config_type example

  my $plans = config_type;

=back

=cut

=head2 config_undef

  config_undef() : ArrayRef

The config_undef function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Undef>.

=over 4

=item config_undef example

  my $plans = config_undef;

=back

=cut

=head2 prepare

  prepare(Str $arg1, Str $arg2) : ArrayRef

The prepare function returns configuration plans based on the arguments passed.

=over 4

=item prepare example

  prepare($package, $type);

=back

=cut

=head2 prepare_add

  prepare_add(Str $arg1, Str $arg2) : ArrayRef

The prepare_add function returns an add-plan for the arguments passed.

=over 4

=item prepare_add example

  prepare_add($package, $function);

=back

=cut

=head2 prepare_call

  prepare_call(Str $arg1, Any @args) : ArrayRef

The prepare_call function returns a call-plan for the arguments passed.

=over 4

=item prepare_call example

  prepare_call($function, @args);

=back

=cut

=head2 prepare_use

  prepare_use(Str $arg1, Any @args) : ArrayRef

The prepare_use function returns a use-plan for the arguments passed.

=over 4

=item prepare_use example

  prepare_use($package, @args);

=back

=cut

=head2 process

  process(Str $arg1, ArrayRef $arg2) : Any

The process function executes a series of plans on behalf of the caller.

=over 4

=item process example

  process($caller, $plans);

=back

=cut

=head2 process_add

  process_add(Str $arg1, ArrayRef $arg2) : Any

The process_add function executes the add-plan on behalf of the caller.

=over 4

=item process_add example

  process_add($caller, $plan);

=back

=cut

=head2 process_call

  process_call(Str $arg1, ArrayRef $arg2) : Any

The process_call function executes the call-plan on behalf of the caller.

=over 4

=item process_call example

  process_call($caller, $plan);

=back

=cut

=head2 process_use

  process_use(Str $arg1, ArrayRef $arg2) : Any

The process_use function executes the use-plan on behalf of the caller.

=over 4

=item process_use example

  process_use($caller, $plan);

=back

=cut

=head2 subject

  subject(Str $arg1, Str $arg2) : Int

The subject function returns truthy if both arguments match alphanumerically (not case-sensitive).

=over 4

=item subject example

  subject('-Role', 'Role');

=back

=cut
