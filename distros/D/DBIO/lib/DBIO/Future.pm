package DBIO::Future;
# ABSTRACT: Future interface contract for async DBIO operations

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp 'croak';
use namespace::clean;


sub validate {
  my ($class, $obj) = @_;
  for (qw(then catch get is_ready is_failed done fail needs_all)) {
    croak "$obj does not implement $_" unless $obj->can($_);
  }
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Future - Future interface contract for async DBIO operations

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Defines the interface contract that all DBIO-compatible Future objects
must implement. This is B<not> a base class -- async distributions bring
their own Future implementation (L<Future> and its subclasses, such as
L<IO::Async::Future>).

The interface is intentionally minimal to maximize compatibility across
event loop ecosystems.

=head1 METHODS

=head2 validate

  DBIO::Future->validate($obj);

Verifies that C<$obj> -- a Future instance or a Future class name --
implements the required Future interface: the five instance methods C<then>,
C<catch>, C<get>, C<is_ready> and C<is_failed>, and the class methods C<done>,
C<fail> and C<needs_all> that core calls on a C<future_class>. C<new> is not
required. Croaks, naming the method, if any required one is missing.

It asks for methods only. What a Future is failed with is a value, known when
it fails, not a capability of the class -- there is nothing on the class for
C<can> to probe, and a transport that fails with plain strings is conforming.
The failure shape is therefore a documented contract (L</WHAT A TRANSPORT
FAILS WITH>), pinned by F<t/test/59_async_failure_object.t>, not a validate
check.

=head1 REQUIRED METHODS

Any object returned by DBIO async methods must support these methods:

=over 4

=item then

  $future->then(sub { my @result = @_; ... });

Success callback. Called with the resolved values when the Future completes
successfully. May return either a new Future (which is chained and flattened) or
a plain value, which is wrapped into an immediately-resolved Future. A conforming
Future B<must> auto-wrap a plain return -- the storage and ResultSet C<*_async>
C<then> callbacks rely on it (ADR 0031).

=item catch

  $future->catch(sub { my $error = shift; ... });

Error callback. Called with the error when the Future fails. Like L</then>, may
return a new Future or a plain value, which is wrapped into a resolved Future.

=item get

  my @result = $future->get;

Block until the Future is resolved and return the result.
Dies if the Future failed.

=item is_ready

  if ($future->is_ready) { ... }

Returns true if the Future has been resolved (either success or failure).

=item is_failed

  if ($future->is_failed) { ... }

Returns true if the Future was resolved with an error.

=back

=head1 WHAT CORE CALLS ON A FUTURE CLASS

The five methods above are what a caller of a C<*_async> method can rely on.
The class a storage names as its C<future_class> is asked for more, because
core makes Futures of that class itself. L</validate> checks the five methods
and C<done>, C<fail> and C<needs_all>; it does not ask for C<new>:

=over 4

=item done, fail

  $future_class->done(@values);
  $future_class->fail($error);

Class methods: an already resolved and an already failed Future. Every async
path uses them, the C<immediate> mode included.

=item needs_all

  $future_class->needs_all(@futures);

Class method: a Future that resolves once all of C<@futures> have.
L<DBIO::Storage::Async/txn_do_async> waits with it for the statements of a
transaction before it sends C<COMMIT>.

=item new

  my $pending = $future_class->new;
  $pending->done(@values);      # or ->fail($error)

A pending Future, settled later through C<done> or C<fail> called on the
instance. L<DBIO::Storage::PoolBase> queues a caller on one and builds a
connection's readiness Future this way, and core's LISTEN/NOTIFY machinery
makes the Futures it hands to callers with it -- on the class, or on a pending
Future the transport returned. A real backend needs it;
L<DBIO::Future::Immediate>, which is never pending, has none.

=back

L<DBIO::Storage::Async> and L<DBIO::Storage::PoolBase> also call L</then> with
two callbacks, C<< $future->then($on_done, $on_fail) >>, as L<Future> takes
them: on a Future that failed the second one runs, with the error, and what
it returns -- a value, a Future, or what it dies with -- is the outcome; where
the callback for the outcome is not given, the outcome passes through. Core's
second callback is where a transaction sends its C<ROLLBACK> and where a
connection goes back to the pool: with a class that drops it, a failed
transaction sends neither and keeps its connection. L<DBIO::Future::Immediate>
did; it, L<DBIO::Test::Future> and L<Future> answer the same
table in F<t/test/52_async_future_then_two_callbacks.t>.

Anything further -- C<retain>, C<cancel>, C<on_cancel>, C<is_cancelled> -- is
asked for with C<can> first and used only where the class has it.

=head1 WHAT A TRANSPORT FAILS WITH

A statement the B<server> refused fails its Future with a
L<DBIO::Exception::Server>, not with a string (ADR 0062):

  $future_class->fail(
    DBIO::Exception::Server->new(
      message    => $text,         # what the string used to be, untouched
      sqlstate   => '23505',
      constraint => 'artist_name_key',
      table      => 'artist',
      detail     => 'Key (name)=(Duplicate) already exists.',
    )
  );

The transport hands over what the server reported and nothing it has to
guess: C<message> is required, the other four fields are C<undef> where the
server named none. A caller reads C<sqlstate> instead of parsing a text that
depends on the server's locale; a caller that matches the text keeps working,
the object stringifies to C<message> and compares as that string.

Core passes the object on B<as it came>, the same object (C<refaddr> equal),
through C<txn_do_async>, the context a transaction hands its coderef and
C<pipeline>, whether the statement's Future was returned, awaited or left to
the transaction. Core wraps the error in text in the places it says
(L<DBIO::Storage::Async/txn_do_async>: a failed C<BEGIN> or C<COMMIT>, a
failed C<ROLLBACK>); there the object stays an object, as a derived copy of
the same class and fields with L<DBIO::Exception::Server/context> set
(C<BEGIN>, C<COMMIT>, C<ROLLBACK>) that stringifies with the text -- not the
same object (C<refaddr> differs) -- and an error that is no such object stays
the string it was. The
failure of a Future is one value: a transport fails it with the object as the
first and only error, details after it are for the Future class.

An error that did not come from the server -- a connection that dropped, a
timeout the client enforced, a transport that died -- stays a string or a
L<DBIO::Exception>; it has no SQLSTATE to report. A transport that does not
build the object keeps working, unchanged: nothing in core requires it.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
