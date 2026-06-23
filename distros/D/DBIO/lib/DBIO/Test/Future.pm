package DBIO::Test::Future;
# ABSTRACT: Synchronous mock Future for DBIO test suite

use strict;
use warnings;



sub done {
  my $class = shift;
  bless { ready => 1, failed => 0, result => [@_] }, $class;
}


sub fail {
  my ($class, $error) = @_;
  bless { ready => 1, failed => 1, error => $error, result => [] }, $class;
}


sub is_ready { 1 }


sub is_failed { $_[0]->{failed} ? 1 : 0 }


sub get {
  my $self = shift;
  die $self->{error} if $self->{failed};
  return wantarray ? @{ $self->{result} } : $self->{result}[0];
}


sub then {
  my ($self, $cb) = @_;
  return $self if $self->{failed};
  my @r = eval { $cb->(@{ $self->{result} }) };
  return $@ ? ref($self)->fail($@) : ref($self)->done(@r);
}


sub catch {
  my ($self, $cb) = @_;
  return $self unless $self->{failed};
  my @r = eval { $cb->($self->{error}) };
  return $@ ? ref($self)->fail($@) : ref($self)->done(@r);
}


sub and_then {
  my ($self, $cb) = @_;
  return $self if $self->{failed};
  my $inner = eval { $cb->(@{ $self->{result} }) };
  return ref($self)->fail($@) if $@;
  return $inner if ref($inner) && $inner->isa(__PACKAGE__);
  return ref($self)->done($inner);
}


sub needs_all {
  my ($class, @futures) = @_;
  my @results;
  for my $f (@futures) {
    return $f if $f->is_failed;
    push @results, $f->get;
  }
  return $class->done(@results);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Future - Synchronous mock Future for DBIO test suite

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  use DBIO::Test::Future;

  my $f = DBIO::Test::Future->done('hello', 'world');
  ok $f->is_ready;
  is_deeply [$f->get], ['hello', 'world'];

  my $f2 = $f->then(sub { return uc $_[0] });
  is_deeply [$f2->get], ['HELLO'];

  my $err = DBIO::Test::Future->fail('something broke');
  ok $err->is_failed;

=head1 DESCRIPTION

A minimal synchronous Future implementation for testing DBIO's async
interface without requiring any event loop framework.

Just like L<DBIO::Test::Storage> provides a fake storage for testing SQL
generation without a real database, C<DBIO::Test::Future> provides a fake
Future that resolves immediately for testing async method signatures.

All methods execute synchronously -- C<then> chains run immediately,
C<get> returns instantly, and C<is_ready> is always true.

=head1 METHODS

=head2 done

  my $f = DBIO::Test::Future->done(@values);

Create an immediately-resolved successful Future.

=head2 fail

  my $f = DBIO::Test::Future->fail($error);

Create an immediately-resolved failed Future.

=head2 is_ready

Returns true (always, since test futures resolve immediately).

=head2 is_failed

Returns true if this Future was created with L</fail>.

=head2 get

Returns the resolved values. Dies if the Future failed.

=head2 then

  my $f2 = $f->then(sub { my @result = @_; return @new_result });

Executes the callback immediately with the resolved values and returns
a new Future with the callback's return value. If the callback dies,
returns a failed Future. If this Future is failed, returns itself
without calling the callback.

=head2 catch

  my $f2 = $f->catch(sub { my $error = shift; ... });

Executes the callback immediately with the error if this Future
failed. Returns itself unchanged if successful.

=head2 and_then

  my $f2 = $f->and_then(sub { return DBIO::Test::Future->done(...) });

Like L</then> but expects the callback to return a Future object.
Flattens nested Futures.

=head2 needs_all

  my $f = DBIO::Test::Future->needs_all(@futures);

Returns a Future that resolves when all input Futures have resolved.
Fails if any input Future fails. Results are collected in order.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
