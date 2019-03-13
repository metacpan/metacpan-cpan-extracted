package Data::Object::Func::Hash::Iterator;

use Data::Object Class;

extends 'Data::Object::Func::Hash';

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

  my @keys = sort keys %{$data};

  my $i = 0;
  return sub {
    return undef if $i > $#keys;
    return $data->{$keys[$i++]};
  }
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Iterator

=cut

=head1 ABSTRACT

Data-Object Hash Function (Iterator) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Iterator;

  my $func = Data::Object::Func::Hash::Iterator->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Iterator is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Hash->new({1..4});

  my $func = Data::Object::Func::Hash::Iterator->new(
    arg1 => $data
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
