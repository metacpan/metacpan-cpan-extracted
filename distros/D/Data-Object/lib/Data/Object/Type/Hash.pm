package Data::Object::Type::Hash;

use strict;
use warnings;

use Data::Object::Export;

use parent 'Data::Object::Type';

# BUILD
# METHODS

sub name {
  return 'DoHash';
}

sub aliases {
  return ['HashObj', 'HashObject'];
}

sub coercions {
  return ['HashRef', sub { do('hash', $_[0]) }];
}

sub validation {
  my ($self, $data) = @_;

  return 0 if !$data->isa('Data::Object::Hash');

  return 1;
}

sub explaination {
  my ($self, $data, $type, $name) = @_;

  my $param = $type->parameters->[0];

  for my $k (sort keys %$data) {
    next if $param->check($data->{$k});

    my $indx = sprintf('%s->{%s}', $name, B::perlstring($k));
    my $desc = $param->validate_explain($data->{$k}, $indx);
    my $text = '"%s" constrains each value in the hash object with "%s"';

    return [sprintf($text, $type, $param), @{$desc}];
  }

  return;
}

sub parameterize {
  my ($self, $data, $type) = @_;

  $type->check($_) || return for values %$data;

  return !!1;
}

sub parameterize_coercions {
  my ($self, $data, $type, $anon) = @_;

  my $coercions = [];

  push @$coercions, 'HashRef', sub {
    my $value = @_ ? $_[0] : $_;
    my $items = {};

    for my $k (sort keys %$value) {
      return $value unless $anon->check($value->{$k});
      $items->{$k} = $data->coerce($value->{$k});
    }

    return $type->coerce($items);
  };

  return $coercions;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Type::Hash

=cut

=head1 ABSTRACT

Data-Object Hash Type Constraint

=cut

=head1 SYNOPSIS

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Hash;

  register Data::Object::Type::Hash;

  1;

=cut

=head1 DESCRIPTION

Type constraint for validating L<Data::Object::Hash> objects. This type
constraint is registered in the L<Data::Object::Config::Library> type library.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 name

  my $name = $self->name();

The name method returns the name of the data type.

=cut

=head2 aliases

  my $aliases = $self->aliases();

The aliases method returns aliases to register in the type library.

=cut

=head2 coercions

  my $coercions = $self->coercions();

The coercions method returns coercions to configure on the type constraint.

=cut

=head2 validation

  my $validation = $self->validation();

The validation method returns truthy if type check is valid.

=cut

=head2 explaination

  my $explaination = $self->explaination();

The explaination method returns the explaination for the type check failure.

=cut

=head2 parameterize

  my $parameterize = $self->parameterize();

The parameterize method returns truthy if parameterized type check is valid.

=cut

=head2 parameterize_coercions

  my $parameterize_coercions = $self->parameterize_coercions();

The parameterize_coercions method returns truthy if parameterized type check is valid.

=cut
