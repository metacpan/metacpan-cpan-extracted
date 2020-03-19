package Data::Object::Try;

use 5.014;

use strict;
use warnings;
use routines;

use Moo;
use Try::Tiny ();

our $VERSION = '2.02'; # VERSION

# ATTRIBUTES

has 'invocant' => (
  is => 'ro'
);

has 'arguments' => (
  is => 'ro'
);

has 'on_try' => (
  is => 'rw'
);

has 'on_catch' => (
  is => 'rw'
);

has 'on_default' => (
  is => 'rw'
);

has 'on_finally' => (
  is => 'rw'
);

# BUILD

method BUILD($args) {
  $self->{'on_catch'} = [] if !$args->{'on_catch'};

  return $args;
}

# METHODS

method call($callback) {
  $self->on_try($self->callback($callback));

  return $self;
}

method callback($callback) {
  require Carp;

  unless (UNIVERSAL::isa($callback, 'CODE')) {
    my $method = $self->invocant
      ? $self->invocant->can($callback) : $self->can($callback);
      Carp::confess(sprintf(
        qq(Can't locate object method "%s" on package "%s"),
        ($callback, ref $self)
      )) if !$method;
    $callback = sub { goto $method };
  }

  return $callback;
}

method catch($class, $callback) {
  push @{$self->on_catch}, [$class, $self->callback($callback)];

  return $self;
}

method default($callback) {
  $self->on_default($self->callback($callback));

  return $self;
}

method execute($callback, @args) {
  unshift @args, @{$self->arguments}
    if $self->arguments && @{$self->arguments};
  unshift @args, $self->invocant
    if $self->invocant;

  return $callback->(@args);
}

method finally($callback) {
  $self->on_finally($self->callback($callback));

  return $self;
}

method maybe() {
  $self->on_default(sub{''});

  return $self;
}

method no_catch() {
  $self->on_catch([]);

  return $self;
}

method no_default() {
  $self->on_default(undef);

  return $self;
}

method no_finally() {
  $self->on_finally(undef);

  return $self;
}

method no_try() {
  $self->on_try(undef);

  return $self;
}

method result(@args) {
  require Carp;

  my $returned;

  Try::Tiny::try(sub {
    my $tryer = $self->on_try;

    $returned = $self->execute($tryer, @args);
  }, Try::Tiny::catch(sub {
    my $caught = $_;
    my $catchers = $self->on_catch;
    my $default = $self->on_default;

    for my $catcher (@$catchers) {
      if (UNIVERSAL::isa($caught, $catcher->[0])) {
        $returned = $catcher->[1]->($caught);
        last;
      }
    }

    if(!$returned) {
      $returned = $default->($caught) if $default;
      Carp::confess($caught) if not defined $returned;
    }
  }, Try::Tiny::finally(sub {
    my $finally = $self->on_finally;

    $self->execute($finally, @args) if $finally;
  })));

  return $returned;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Try

=cut

=head1 ABSTRACT

Try Class for Perl 5

=cut

=head1 SYNOPSIS

  use strict;
  use warnings;
  use routines;

  use Data::Object::Try;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {
    # try something

    return time;
  });

  $try->catch('Example::Exception', fun ($caught) {
    # caught an exception

    return;
  });

  $try->default(fun ($caught) {
    # catch the uncaught

    return;
  });

  $try->finally(fun (@args) {
    # always run after try/catch

    return;
  });

  my @args;

  my $result = $try->result(@args);

=cut

=head1 DESCRIPTION

This package provides an object-oriented interface for performing complex try/catch operations.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 arguments

  arguments(ArrayRef)

This attribute is read-only, accepts C<(ArrayRef)> values, and is optional.

=cut

=head2 invocant

  invocant(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 on_catch

  on_catch(ArrayRef[CodeRef])

This attribute is read-write, accepts C<(ArrayRef[CodeRef])> values, and is optional.

=cut

=head2 on_default

  on_default(CodeRef)

This attribute is read-write, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_finally

  on_finally(CodeRef)

This attribute is read-write, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_try

  on_try(CodeRef)

This attribute is read-write, accepts C<(CodeRef)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 call

  call(Str | CodeRef $arg) : Object

The call method takes a method name or coderef, registers it as the tryable
routine, and returns the object. When invoked, the callback will received an
C<invocant> if one was provided to the constructor, the default C<arguments> if
any were provided to the constructor, and whatever arguments were provided by
the invocant.

=over 4

=item call example #1

  use routines;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    return [@args];
  });

=back

=cut

=head2 callback

  callback(Str | CodeRef $arg) : CodeRef

The callback method takes a method name or coderef, and returns a coderef for
registration. If a coderef is provided this method is mostly a passthrough.

=over 4

=item callback example #1

  use routines;

  my $try = Data::Object::Try->new;

  $try->callback(fun (@args) {

    return [@args];
  });

=back

=over 4

=item callback example #2

  package Example;

  use Moo;
  use routines;

  fun test(@args) {

    return [@args];
  }

  package main;

  my $try = Data::Object::Try->new(
    invocant => Example->new
  );

  $try->callback('test');

=back

=cut

=head2 catch

  catch(Str $isa, Str | CodeRef $arg) : Any

The catch method takes a package or ref name, and when triggered checks whether
the captured exception is of the type specified and if so executes the given
callback.

=over 4

=item catch example #1

  use routines;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->catch('Data::Object::Try', fun (@args) {

    return [@args];
  });

=back

=cut

=head2 default

  default(Str | CodeRef $arg) : Object

The default method takes a method name or coderef and is triggered if no
C<catch> conditions match the exception thrown.

=over 4

=item default example #1

  use routines;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->default(fun (@args) {

    return [@args];
  });

=back

=cut

=head2 execute

  execute(CodeRef $arg, Any @args) : Any

The execute method takes a coderef and executes it with any given arguments.
When invoked, the callback will received an C<invocant> if one was provided to
the constructor, the default C<arguments> if any were provided to the
constructor, and whatever arguments were passed directly to this method.

=over 4

=item execute example #1

  use routines;

  my $try = Data::Object::Try->new(
    invocant => Example->new,
    arguments => [1,2,3]
  );

  $try->execute(fun (@args) {

    return [@args];
  });

=back

=cut

=head2 finally

  finally(Str | CodeRef $arg) : Object

The finally method takes a package or ref name and always executes the callback
after a try/catch operation. The return value is ignored. When invoked, the
callback will received an C<invocant> if one was provided to the constructor,
the default C<arguments> if any were provided to the constructor, and whatever
arguments were provided by the invocant.

=over 4

=item finally example #1

  use routines;

  my $try = Data::Object::Try->new(
    invocant => Example->new,
    arguments => [1,2,3]
  );

  $try->call(fun (@args) {

    return $try;
  });

  $try->finally(fun (@args) {

    $try->{'$finally'} = [@args];
  });

=back

=cut

=head2 maybe

  maybe() : Object

The maybe method registers a default C<catch> condition that returns falsy,
i.e. an empty string, if an exception is encountered.

=over 4

=item maybe example #1

  use routines;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->maybe;

=back

=cut

=head2 no_catch

  no_catch() : Object

The no_catch method removes any configured catch conditions and returns the
object.

=over 4

=item no_catch example #1

  use routines;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->catch('Data::Object::Try', fun (@args) {

    return [@args];
  });

  $try->no_catch;

=back

=cut

=head2 no_default

  no_default() : Object

The no_default method removes any configured default condition and returns the
object.

=over 4

=item no_default example #1

  use routines;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    die $try;
  });

  $try->default(fun (@args) {

    return [@args];
  });

  $try->no_default;

=back

=cut

=head2 no_finally

  no_finally() : Object

The no_finally method removes any configured finally condition and returns the
object.

=over 4

=item no_finally example #1

  use routines;

  my $try = Data::Object::Try->new(
    invocant => Example->new,
    arguments => [1,2,3]
  );

  $try->call(fun (@args) {

    return $try;
  });

  $try->finally(fun (@args) {

    $try->{'$finally'} = [@args];
  });

  $try->no_finally;

=back

=cut

=head2 no_try

  no_try() : Object

The no_try method removes any configured C<try> operation and returns the
object.

=over 4

=item no_try example #1

  use routines;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    return [@args];
  });

  $try->no_try;

=back

=cut

=head2 result

  result(Any @args) : Any

The result method executes the try/catch/default/finally logic and returns
either 1) the return value from the successfully tried operation 2) the return
value from the successfully matched catch condition if an exception was thrown
3) the return value from the default catch condition if an exception was thrown
and no catch condition matched. When invoked, the C<try> and C<finally>
callbacks will received an C<invocant> if one was provided to the constructor,
the default C<arguments> if any were provided to the constructor, and whatever
arguments were passed directly to this method.

=over 4

=item result example #1

  use routines;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    return [@args];
  });

  $try->result;

=back

=over 4

=item result example #2

  use routines;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {

    return [@args];
  });

  $try->result(1..5);

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-try/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-try/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-try>

L<Initiatives|https://github.com/iamalnewkirk/data-object-try/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-try/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-try/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-try/issues>

=cut
