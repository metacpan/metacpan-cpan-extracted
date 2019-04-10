package Data::Object::Func::Hash::Unfold;

use Data::Object 'Class';

extends 'Data::Object::Func::Hash';

our $VERSION = '0.96'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data) = $self->unpack;

  my $store = {};

  for my $key (sort(keys(%$data))) {
    my $node  = $store;
    my @steps = split(/\./, $key);

    for (my $i = 0; $i < @steps; $i++) {
      my $last = $i == $#steps;
      my $step = $steps[$i];

      if (my @parts = $step =~ /^(\w*):(0|[1-9]\d*)$/) {
        $node = $node->{$parts[0]}[$parts[1]]
          = $last ? $data->{$key}
          : exists $node->{$parts[0]}[$parts[1]] ? $node->{$parts[0]}[$parts[1]]
          : {};
      } else {
        $node = $node->{$step}
          = $last ? $data->{$key} : exists $node->{$step} ? $node->{$step} : {};
      }
    }
  }

  return $store;
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Unfold

=cut

=head1 ABSTRACT

Data-Object Hash Function (Unfold) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Unfold;

  my $func = Data::Object::Func::Hash::Unfold->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Unfold is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Hash->new({1..4});

  my $func = Data::Object::Func::Hash::Unfold->new(
    arg1 => $data
  );

  my $result = $func->execute;

=back

=cut

=head2 mapping

  mapping() : (Str)

Returns the ordered list of named function object arguments.

=over 4

=item mapping example

  my @data = $self->mapping;

=back

=cut
