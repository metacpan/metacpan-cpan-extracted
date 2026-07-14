package DBIO::Future;
# ABSTRACT: Future interface contract for async DBIO operations

use strict;
use warnings;

use Carp 'croak';
use namespace::clean;


sub validate {
  my ($class, $obj) = @_;
  for (qw(then catch get is_ready is_failed)) {
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

version 0.900002

=head1 DESCRIPTION

Defines the interface contract that all DBIO-compatible Future objects
must implement. This is B<not> a base class -- async distributions bring
their own Future implementation (L<Future>, L<Mojo::Promise>, etc.).

The interface is intentionally minimal to maximize compatibility across
event loop ecosystems.

=head1 METHODS

=head2 validate

  DBIO::Future->validate($obj);

Verifies that C<$obj> implements the required Future interface.
Croaks if any required method is missing.

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

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
