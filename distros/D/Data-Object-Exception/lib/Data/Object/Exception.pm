package Data::Object::Exception;

use 5.014;

use strict;
use warnings;
use routines;

use Moo;

use overload (
  '""' => 'explain',
  '~~' => 'explain',
  fallback => 1
);

our $VERSION = '2.02'; # VERSION

has id => (
  is => 'ro'
);

has context => (
  is => 'ro'
);

has frames => (
  is => 'ro'
);

has message => (
  is => 'ro',
  default => 'Exception!'
);

# BUILD

fun BUILD($self, $args) {

  # build stack trace
  return $self->trace(2) if !$self->frames;
}

fun BUILDARGS($class, @args) {

  # constructor arguments
  return {
    @args == 1
      # ...
      ? !ref($args[0])
        # single non-ref argument
        ? (message => $args[0])
        # ...
        : 'HASH' eq ref($args[0])
        # single hash-based argument
        ? %{$args[0]}
        # non hash-based argument
        : ()
        # multiple arguments
      : @args
  };
}

# FUNCTIONS

fun throw($self, $message, $context, $offset) {
  my $id;

  my $class = ref $self || $self;

  my $args = {};

  if (ref $message eq 'ARRAY') {
    ($id, $message) = @$message;
  }

  if (ref $self) {
    for my $name (keys %$self) {
      $args->{$name} = $self->{$name};
    }
  }

  $args->{id} = $id if $id;
  $args->{message} = $message if $message;
  $args->{context} = $context if $context;

  my $exception = $self->new($args);

  die $exception->trace($offset);
}

# METHODS

method explain() {
  $self->trace(1, 1) if !$self->{frames};

  my $frames = $self->{frames};

  my $file = $frames->[0][1];
  my $line = $frames->[0][2];
  my $pack = $frames->[0][0];
  my $subr = $frames->[0][3];

  my $message = $self->{message} || 'Exception!';

  my @stacktrace = ("$message in $file at line $line");

  for (my $i = 1; $i < @$frames; $i++) {
    my $pack = $frames->[$i][0];
    my $file = $frames->[$i][1];
    my $line = $frames->[$i][2];
    my $subr = $frames->[$i][3];

    push @stacktrace, "\t$subr in $file at line $line";
  }

  return join "\n", @stacktrace, "";
}

method trace($offset, $limit) {
  $self->{frames} = my $frames = [];

  for (my $i = $offset // 1; my @caller = caller($i); $i++) {
    push @$frames, [@caller];

    last if defined $limit && $i + 1 == $offset + $limit;
  }

  return $self;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Exception

=cut

=head1 ABSTRACT

Exception Class for Perl 5

=cut

=head1 SYNOPSIS

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new;

  # $exception->throw

=cut

=head1 DESCRIPTION

This package provides functionality for creating, throwing, and introspecting
exception objects.

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 args-1

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  # $exception->throw

The package allows objects to be instantiated with a single argument.

=cut

=head2 args-kv

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new(message => 'Oops!');

  # $exception->throw

The package allows objects to be instantiated with key-value arguments.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 context

  context(Any)

This attribute is read-only, accepts C<(Any)> values, and is optional.

=cut

=head2 id

  id(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 message

  message(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 explain

  explain() : Str

The explain method returns an error message with stack trace.

=over 4

=item explain example #1

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->explain

=back

=cut

=head2 throw

  throw(Tuple[Str, Str] | Str $message, Any $context, Maybe[Number] $offset) : Any

The throw method throws an error with message (and optionally, an ID).

=over 4

=item throw example #1

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new;

  $exception->throw('Oops!')

=back

=over 4

=item throw example #2

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->throw

=back

=over 4

=item throw example #3

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new;

  $exception->throw(['E001', 'Oops!'])

=back

=cut

=head2 trace

  trace(Int $offset, $Int $limit) : Object

The trace method compiles a stack trace and returns the object. By default it
skips the first frame.

=over 4

=item trace example #1

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->trace(0)

=back

=over 4

=item trace example #2

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->trace(1)

=back

=over 4

=item trace example #3

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new('Oops!');

  $exception->trace(0,1)

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-exception/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-exception/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-exception>

L<Initiatives|https://github.com/iamalnewkirk/data-object-exception/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-exception/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-exception/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-exception/issues>

=cut
