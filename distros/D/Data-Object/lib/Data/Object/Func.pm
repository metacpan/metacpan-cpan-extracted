package Data::Object::Func;

use Data::Object::Class;

extends 'Data::Object::Kind';

with 'Data::Object::Role::Codifiable';
with 'Data::Object::Role::Throwable';

# BUILD

sub BUILDARGS {
  my ($class, @args) = @_;

  return {@args} if ! ref $args[0];

  return $class->configure(@args);
}

# METHODS

sub execute {
  return;
}

sub configure {
  my ($class, @args) = @_;

  my $data = {};

  for my $expr ($class->mapping) {
    last if !@args;

    my $regx = qr/^(\W*)(\w+)$/;

    my ($type, $attr) = $expr =~ $regx;

    if (!$type) {
      $data->{$attr} = shift(@args);
    } elsif ($type eq '@') {
      $data->{$attr} = [@args];
      last;
    } elsif ($type eq '%') {
      $data->{$attr} = {@args};
      last;
    }
  }

  return $data;
}

sub mapping {
  return (); # noop
}

sub recurse {
  my ($self, @args) = @_;

  my $class = ref($self) || $self;

  return $class->new(@args)->execute;
}

sub unpack {
  my ($self) = @_;

  my @args;

  for my $expr ($self->mapping) {
    my $regx = qr/^(\W*)(\w+)$/;

    my ($type, $attr) = $expr =~ $regx;

    if (!$type) {
      push @args, $self->$attr;
    } elsif ($type eq '@') {
      push @args, @{$self->$attr} if $self->$attr;
      last;
    } elsif ($type eq '%') {
      push @args, @{$self->$attr} if $self->$attr;
      last;
    }
  }

  return @args;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func

=cut

=head1 ABSTRACT

Data-Object Function-Object Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func;

=cut

=head1 DESCRIPTION

Data::Object::Func is an abstract base class for function classes.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $func = Data::Object::Func->new();

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 configure

  my $configure = $func->configure();

Converts positional args to named args.

=cut

=head2 mapping

  my @data = $func->mapping;

Returns the ordered list of named function object arguments.

=cut

=head2 recurse

  my $recurse = $func->recurse();

Recurses into the function object.

=cut

=head2 unpack

  my $unpack = $func->unpack();

Returns a list of positional args from the named args.

=cut
