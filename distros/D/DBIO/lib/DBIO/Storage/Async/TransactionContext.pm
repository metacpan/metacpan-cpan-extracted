package DBIO::Storage::Async::TransactionContext;
# ABSTRACT: Generic pinned-connection context for async transactions

use strict;
use warnings;

use namespace::clean;


sub new {
  my ($class, %args) = @_;
  die('storage required') unless $args{storage};
  die('txn_conn required') unless $args{txn_conn};
  return bless {
    storage  => $args{storage},
    txn_conn => $args{txn_conn},
  }, $class;
}


sub storage { $_[0]->{storage} }


sub txn_conn { $_[0]->{txn_conn} }


sub pool { $_[0]->{storage}->pool }


sub in_txn { 1 }


sub _query_async {
  my ($self, $sql, $bind) = @_;
  return $self->{storage}->_query_async_pinned($self->{txn_conn}, $sql, $bind);
}

# CRUD inside a transaction MUST run on the pinned connection that
# BEGIN/COMMIT ran on, not a fresh pooled one. Each method routes
# through the storage's shared CRUD builder with the pinned connection,
# so SQL generation (insert post-processing, select_single first-row)
# is not duplicated. Forwarding to $storage->select_async etc. would
# acquire a separate pool connection and run the query OUTSIDE the
# transaction.

sub select_async        { my $self = shift; $self->{storage}->_run_crud_pinned('select',        $self->{txn_conn}, @_) }
sub select_single_async { my $self = shift; $self->{storage}->_run_crud_pinned('select_single', $self->{txn_conn}, @_) }
sub insert_async        { my $self = shift; $self->{storage}->_run_crud_pinned('insert',        $self->{txn_conn}, @_) }
sub update_async        { my $self = shift; $self->{storage}->_run_crud_pinned('update',        $self->{txn_conn}, @_) }
sub delete_async        { my $self = shift; $self->{storage}->_run_crud_pinned('delete',        $self->{txn_conn}, @_) }

# Sync fallbacks -- block the event loop via ->get

sub select             { my $self = shift; $self->select_async(@_)->get        }
sub select_single      { my $self = shift; $self->select_single_async(@_)->get }
sub insert             { my $self = shift; $self->insert_async(@_)->get        }
sub update             { my $self = shift; $self->update_async(@_)->get        }
sub delete             { my $self = shift; $self->delete_async(@_)->get        }

# Delegations

sub sql_maker    { my $self = shift; $self->{storage}->sql_maker(@_)    }
sub debug        { my $self = shift; $self->{storage}->debug(@_)        }
sub pipeline     { my $self = shift; $self->{storage}->pipeline(@_)     }
sub txn_do_async { my $self = shift; $self->{storage}->txn_do_async(@_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::Async::TransactionContext - Generic pinned-connection context for async transactions

=head1 VERSION

version 0.900002

=head1 DESCRIPTION

The transaction context handed to the coderef of
L<DBIO::Storage::Async/txn_do_async>. It pins every CRUD operation to the
single connection that C<BEGIN>/C<COMMIT>/C<ROLLBACK> ran on, routing them
through the storage's shared C<_run_crud_pinned> builder so SQL generation
(INSERT post-processing, C<select_single> first-row) is never duplicated.

This is the loop-agnostic default returned by
L<DBIO::Storage::Async/_txn_context_class>; a transport backend that needs a
different pinned-connection accessor overrides
L<DBIO::Storage::Async/_txn_conn_accessor> (and, if needed, C<_txn_context_class>).

=head1 ATTRIBUTES

=head2 storage

The parent L<DBIO::Storage::Async> instance.

=head2 txn_conn

The pinned connection handle for the duration of this transaction.

=head2 pool

Shortcut to C<< $self->storage->pool >>.

=head2 in_txn

Always true -- indicates we are inside a transaction.

=head1 METHODS

=head2 new

  my $ctx = DBIO::Storage::Async::TransactionContext->new(
      storage  => $storage,
      txn_conn => $conn,
  );

Creates a new transaction context. Requires C<storage> and a connection
under the key returned by the storage's
L<DBIO::Storage::Async/_txn_conn_accessor> (default C<txn_conn>).

=head2 _query_async

Executes a query on the pinned transaction connection without releasing
it back to the pool. Uses L<DBIO::Storage::Async/_query_async_pinned>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
