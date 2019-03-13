package Data::Object::Type;

use strict;
use warnings;

use Type::Tiny;
use Type::Coercion;
use Types::TypeTiny;

use parent 'Data::Object::Kind';

# BUILD

sub new {
  return bless {}, shift;
}

# METHODS

sub name {
  die;
}

sub aliases {
  return [];
}

sub coercions {
  return [];
}

sub parent {
  return 'Object';
}

sub library {
  return shift->namespace->meta;
}

sub namespace {
  return 'Data::Object::Config::Library';
}

sub register {
  my ($class) = @_;

  my $self = $class->new if !ref($class);

  $class->new->validator($_) for $self->name, @{$self->aliases};

  return $self;
}

sub validator {
  my ($self, $name) = @_;

  my $library = $self->library;

  if (!$name) {
    $name = $self->name;
  }
  if ($library->get_type($name)) {
    return $library->get_type($name);
  }

  my $type = Type::Tiny->new($self->options(name => $name));
  my $coercions = $self->coercions;

  for (my $i = 0; $i < @$coercions; $i+=2) {
    my $item = $coercions->[$i];

    $coercions->[$i] = $library->get_type($item) if !ref($item);
  }

  $type->coercion->add_type_coercions(@$coercions);

  return $library->add_type($type);
}

sub options {
  my ($self, %overrides) = @_;

  my %options;

  $options{name} = $overrides{name} || $self->name;
  $options{parent} = $overrides{parent} || $self->parent;

  if ($overrides{name}) {
    if ($overrides{name} ne $self->name) {
      $self->{alias} = $overrides{name};
    }
  }

  if (!ref($options{parent})) {
    $options{parent} = $self->library->get_type($options{parent});
  }

  my $constraint = sub { $self->validation(@_) };
  $options{constraint} = $overrides{constraint} || $constraint;

  if ($self->can('parameterize')) {
    my $generator = sub { $self->constraint_generator(@_) };
    $options{constraint_generator} = $generator;
  } elsif($overrides{constraint_generator}) {
    $options{constraint_generator} = $overrides{constraint_generator};
  }

  if ($self->can('parameterize_coercions')) {
    my $generator = sub { $self->coercion_generator(@_) };
    $options{coercion_generator} = $generator;
  }

  if ($self->can('explaination')) {
    my $generator = $self->explaination_generator;
    $options{deep_explanation} = $generator;
  } elsif($overrides{deep_explanation}) {
    $options{deep_explanation} = $overrides{deep_explanation};
  }

  return %options;
}

sub validation {
  die;
}

sub coercion_generator {
  my ($self, $type, $child, $data) = @_;

  if (!$data->has_coercion) {
    return $type->coercion;
  }

  my $anon = $data->coercion->_source_type_union;
  my $coercion = Type::Coercion->new(type_constraint => $child);
  my $generated = $self->parameterize_coercions($data, $type, $anon);

  for (my $i = 0; $i < @$generated; $i+=2) {
    my $item = $generated->[$i];

    $generated->[$i] = $self->library->get_type($item) if !ref($item);
  }

  $coercion->add_type_coercions(@$generated);

  return $coercion;
}

sub constraint_generator {
  my ($self, @args) = @_;

  return $self->validator if !@args;

  my $sign = "@{[$self->{alias} || $self->name]}\[`a\]";
  my $text = "Parameter to $sign expected to be a type constraint";
  my @list = map Types::TypeTiny::to_TypeTiny($_), @args;

  for my $item (@list) {
    if ($item->isa('Type::Tiny')) {
      next;
    }
    if (!Types::TypeTiny::TypeTiny->check($item)) {
      Types::Standard::_croak("$text; got $item");
    }
  }

  return sub { my ($data) = @_; $self->parameterize($data, @list) };
}

sub explaination_generator {
  my ($self, @args) = @_;

  # re-ordering arguments for consistency
  return sub { $self->explaination($_[1], $_[0], $_[2]) };
}

1;

=encoding utf8

=head1 NAME

Data::Object::Type

=cut

=head1 ABSTRACT

Data-Object Type Constraint Builder

=cut

=head1 SYNOPSIS

  package App::Type::Id;

  use parent 'Data::Object::Type';

  sub name {
    return 'Id';
  }

  sub parent {
    return 'Str';
  }

  sub namespace {
    return 'App::Type::Library';
  }

  sub validation {
    my ($self, $data) = @_;

    return 0 if !$data;

    return 0 if $data !~ /^\d+$/;

    return 1;
  }

=cut

=head1 DESCRIPTION

Data::Object::Type is an abstract base class for type constraint builder
classes.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  my $data = Data::Object::Type->new();

Construct a new object.

=cut

=head2 name

  my $name = $data->name();

The name method returns the name of the data type.

=cut

=head2 aliases

  my $aliases = $data->aliases();

The aliases method returns aliases to register in the type library.

=cut

=head2 coercions

  my $coercions = $data->coercions();

The coercions method returns coercions to configure on the type constraint.

=cut

=head2 parent

  my $parent = $data->parent();

The parent method represents the type expression (or parent type) that its type
should derive from.

=cut

=head2 library

  my $library = $data->library();

The library method returns an instance of the type library instance.

=cut

=head2 namespace

  my $namespace = $data->namespace();

The namespace method returns the name of the data type.

=cut

=head2 register

  my $register = $data->register();

The register method registers the built type constraint in the specified type
library.

=cut

=head2 validator

  my $validator = $data->validator();

The validator method returns the built type constraint object.

=cut

=head2 options

  my $options = $data->options();

The options method is used internally to create the options for building the
L<Type::Tiny> type constraint.

=cut

=head2 validation

  my $validation = $self->validation();

The validation method returns truthy if type check is valid.

=cut

=head2 coercion_generator

  my $coercion_generator = $self->coercion_generator();

coercion_generator

=cut

=head2 constraint_generator

  my $constraint_generator = $self->constraint_generator();

constraint_generator

=cut

=head2 explaination_generator

  my $explaination_generator = $self->explaination_generator();

The explaination_generator method returns the explaination for the type check failure.

=cut
