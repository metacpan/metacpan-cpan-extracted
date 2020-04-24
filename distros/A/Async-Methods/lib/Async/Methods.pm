package Async::Methods;

our $VERSION = '0.000003'; # v0.0.3

$VERSION = eval $VERSION;

use strict;
use warnings;
use Carp ();
use Hash::Util qw(fieldhash);

fieldhash my %start;
fieldhash my %then;
fieldhash my %else;

package start;

sub start::_ {
  my ($self, $method, @args) = @_;
  my $f = $self->$method(@args);
  $start{$f} = $self;
  return $f;
}

sub AUTOLOAD {
  my ($self, @args) = @_;
  my ($method) = our $AUTOLOAD =~ /^start::(.+)$/;
  $self->start::_($method => @args);
}

package then;

sub then::_ {
  my ($self, $method, @args) = @_;
  my $f_type = ref($self);
  my $f; $f = $self->then(
    sub { my $obj = shift; $obj->$method(@args, @_) },
    sub {
      if (my $else = $else{$f}) {
        $else->(@_)
      } else {
        $f_type->AWAIT_FAIL(@_)
      }
    },
  );
  if (my $start_obj = $start{$self}) {
    $then{$f} = $start{$f} = $start_obj;
  }
  return $f;
}

sub AUTOLOAD {
  my ($self, @args) = @_;
  my ($method) = our $AUTOLOAD =~ /^then::(.+)$/;
  $self->then::_($method => @args);
}

package else;

sub else::_ {
  my ($self, $method, @args) = @_;
  Carp::croak "Can only call else on result of start:: -> then::"
    unless my $start_obj = $then{$self};
  $else{$self} = sub { $start_obj->$method(@args, @_) };
  return $self;
}

sub AUTOLOAD {
  my ($self, @args) = @_;
  my ($method) = our $AUTOLOAD =~ /^else::(.+)$/;
  $self->else::_($method => @args);
}

package catch;

sub catch::_ {
  my ($self, $method, @args) = @_;
  Carp::croak "Can only call catch on start:: or start:: -> then:: object"
    unless my $start_obj = $start{$self};
  $self->catch(sub { $start_obj->$method(@args, @_) });
}

sub AUTOLOAD {
  my ($self, @args) = @_;
  my ($method) = our $AUTOLOAD =~ /^catch::(.+)$/;
  $self->catch::_($method => @args);
}

package await;

sub this {
  my ($self) = @_;
  return $self->get if $self->can('get');
  if ($self->isa('Mojo::Promise')) {
    # This logic stolen from Mojo::Promis::Role::Get v0.1.2
    Carp::croak "'get' cannot be called when the event loop is running"
      if $self->ioloop->is_running;
    my (@result, $rejected);
    $self->then(sub { @result = @_ }, sub { $rejected = 1; @result = @_ })
         ->wait;
    if ($rejected) {
      my $reason = $result[0] // 'Promise was rejected';
      die $reason if ref $reason or $reason =~ m/\n\z/;
      Carp::croak $reason;
    }
    return wantarray ? @result : $result[0];
  }
  die "Don't know how to await for $self";
}

sub await::_ {
  my ($self, $method, @args) = @_;
  my $f = ($self->can('then')
    ? $self->then::_($method, @args)
    : $self->$method(@args)
  );
  $f->await::this;
}

sub AUTOLOAD {
  my ($self, @args) = @_;
  my ($method) = our $AUTOLOAD =~ /^await::(.+)$/;
  $self->await::_($method => @args);
}

1;

=head1 NAME

Async::Methods - Namespaced sugar methods for async/await and future/promise based code

=head1 SYNOPSIS

  use Mojo::UserAgent;
  
  my $ua = Mojo::UserAgent->new;
  
  # Normal synchronous code
  
  print $ua->get('http://trout.me.uk/')->result->body;
  
  # Equivalent code running synchronously atop promises
  
  print $ua->get_p('http://trout.me.uk')->then::result->await::body;
  
  # Equivalent code within an async subroutine
  
  use Mojo::Base -async_await, -signatures;
  
  async sub fetch ($url) {
    await $ua->get_p($url)->then::result->then::body;
  }
  
  print fetch($url)->await::this;

=head1 DESCRIPTION

L<Async::Methods> provides a set of helper methods operating via namespace
that make chaining together asynchronous methods easier. This is not at all
meant to be a replacement for the C<async> and C<await> keywords available
via L<Future::AsyncAwait> or the C<-async_await> flag to L<Mojo::Base> and
in fact is largely meant to be used I<with> such facilities.

Note that in the following code I use C<$p> for example variables but they
can be L<Future> or L<Mojo::Promise> objects or (hopefully) objects of any
other class that provides a similar interface.

Note that methods of each type provided can be called three ways:

  $obj->the_type::some_method(@args);

will call C<some_method> on a relevant object, and is effectively simply
sugar for the second type,

  $obj->the_type::_(some_method => @args);

which calls the method name given in its first argument (yes, this means that
you can't use the first syntax to call a method called C<_> but the author of
this module strongly suspects that won't be an inconvience in most cases).

Thirdly, to match perl's capacity to allow <$obj->$cb(@args)> as a syntax, you
can also call:

  $obj->the_type::_(sub { ... } => @args);
  $obj->the_type::_($cb => @args);

to call that code reference as a method.

=head1 METHODS

=head2 start::

  my $p = $obj->start::some_method(@args);
  my $p = $obj->start::_(some_method => @args);
  my $p = $obj->start::_(sub { ... } => @args);

L</start::> methods don't do anything special in and of themselves but
register the C<$obj> with L<Async::Methods> to allow L</catch::> and
L</else::> to work correctly (see their documentation below for why you
might find that useful). Other than the registration part, this is
entirely equivalent to

  my $p = $obj->some_method(@args);

=head2 then::

  my $then_p = $p->then::some_method(@args);
  my $then_p = $p->then::_(some_method => @args);
  my $then_p = $p->then::_(sub { ... } => @args);

L</then::> allows for chaining an additional method call from the return
value of the previous promise (assuming it's successful). As such, on its own
this is equivalent to

  my $then_p = $p->then(
    sub ($obj, @rest) { $obj->some_method(@args, @rest)) }
  );

Note that L</then::> does not require anything special of the promise upon
which it's called to provide the base functionality, but I<does> need to be
called on the result of something rooted in L</start::> if you want to be
able to chain L</else::> or L</catch::> from the return value.

=head2 else::

  my $else_p = $p->else::some_method(@args);
  my $else_p = $p->else::_(some_method => @args);
  my $else_p = $p->else::_(sub { ... } => @args);


L</else::> must be called on the result of a L</start::> chained to a
L</then::>, and provides a callback if the L<start::>ed method fails,
invoked on the I<original> invocant. This makes it the "other half" of
L<Async::Methods>' support for two-arg C<<->then>>, so:

  my $else_p = $obj->start::one(@args1)
                   ->then::two(@args2)
                   ->else::three(@args3);

is functionally equivalent to:

  my $else_p = $obj->one(@args1)
                   ->then(
                       sub ($then_obj, @then_rest) {
                         $then_obj->two(@args2, @then_rest)
                       },
                       sub (@error) {
                         $obj->three(@args3, @error)
                       },
                     );

which the author hopes explains why you might, on the whole, not really
mind being forced to type L<start::>.

Note that because L</else::> always resolves to the second argument to a
two-arg C<then> call, it can't be used in isolation. Fortunately, we already
provide L</catch::> for that, which is documented next.

=head2 catch::

  my $catch_p = $p->catch::some_method(@args);
  my $catch_p = $p->catch::_(some_method => @args);
  my $catch_p = $p->catch::_(sub { ... } => @args);

L</catch::> can be called on the result of either a L</start::> call or 
a L</start::> -> L</then::> chain, and will catch any/all errors produced
up to this point, as opposed to L</else::> which catches errors I<before>
the preceding L</then::> call.

As such, morally equivalent to:

  my $catch_p = $obj->start::whatever(...)
                    ->catch(sub ($obj, @error) {
                        $obj->some_method(@args, @error)
                      });

=head2 await::

  my $ret = $p->await::this;

C<await::this> is simple generic sugar for (at top level of your code outside
of an already-running event loop) spinning the event loop until the promise
completes and then either returning the result on success or C<die()>ing with
the error on failure. For a future, it's equivalent to

  my $ret = $f->get;

but if called on a L<Mojo::Promise> loads L<Mojo::Promise::Role::Get> and uses
that to complete the operation, so C<await::this> can be called on either and
still provides a uniform interface. Assuming you install
L<Mojo::Promise::Role::Get> if you need it of course - otherwise you'll get
an exception from the relevant C<require> call.

  my $ret = $p->await::some_method(@args);
  my $ret = $p->await::_(some_method => @args);
  my $ret = $p->await::_(sub { ... } => @args);

L</await::> requires absolutely nothing of the promise upon which it's called,
and other than the special case of C<this> is equivalent to

  my $ret = $p->then::some_method(@args)->await::this;

Hopefully obvious caveat: If you want to await a method called C<this> you'll
need to call one of

  my $ret = $p->then::this(@args)->await::this;
  my $ret = $p->await::_(this => @args);

but C<this> did not strike the author as a sufficiently common method name
to be a deal-breaker in practice.

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

 Grinnz - Dan Book (cpan:DBOOK) <dbook@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2020 the Async::Methods L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
