package DBIO::PostgreSQL::EV::TransactionContext;
# ABSTRACT: Pinned connection context for an async PostgreSQL transaction

use strict;
use warnings;
use Future ();
use namespace::clean;

sub new {
  my ($class, %args) = @_;
  return bless {
    storage => $args{storage} // die('storage required'),
    pg      => $args{pg}      // die('pg required'),
  }, $class;
}


sub storage { $_[0]->{storage} }


sub txn_pg  { $_[0]->{pg}      }


sub pool    { $_[0]->{storage}->pool }


sub in_txn  { 1 }


sub _query_async {
  my ($self, $sql, $bind) = @_;
  return $self->{storage}->_query_async_pinned($self->{pg}, $sql, $bind);
}

# CRUD inside a transaction MUST run on the pinned connection that
# BEGIN/COMMIT ran on, not a fresh pooled one. Each method routes
# through the storage's shared CRUD builder with the pinned connection,
# so SQL generation (insert RETURNING, select_single first-row) is not
# duplicated. Forwarding to $storage->select_async etc. would acquire a
# separate pool connection and run the query OUTSIDE the transaction.
sub select_async        { my $self = shift; $self->{storage}->_run_crud_pinned('select',        $self->{pg}, @_) }
sub select_single_async { my $self = shift; $self->{storage}->_run_crud_pinned('select_single', $self->{pg}, @_) }
sub insert_async        { my $self = shift; $self->{storage}->_run_crud_pinned('insert',        $self->{pg}, @_) }
sub update_async        { my $self = shift; $self->{storage}->_run_crud_pinned('update',        $self->{pg}, @_) }
sub delete_async        { my $self = shift; $self->{storage}->_run_crud_pinned('delete',        $self->{pg}, @_) }
sub select             { my $self = shift; $self->select_async(@_)->get        }
sub select_single      { my $self = shift; $self->select_single_async(@_)->get }
sub insert             { my $self = shift; $self->insert_async(@_)->get        }
sub update             { my $self = shift; $self->update_async(@_)->get        }
sub delete             { my $self = shift; $self->delete_async(@_)->get        }

# Delegations -- mirror the generic DBIO::Storage::Async::TransactionContext
# contract so a txn coderef can reach the storage's sql_maker/debug and open a
# pipeline or nested transaction from inside the pinned context.
sub sql_maker          { my $self = shift; $self->{storage}->sql_maker(@_)          }
sub debug              { my $self = shift; $self->{storage}->debug(@_)              }
sub pipeline           { my $self = shift; $self->{storage}->pipeline(@_)           }
sub txn_do_async       { my $self = shift; $self->{storage}->txn_do_async(@_)       }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::TransactionContext - Pinned connection context for an async PostgreSQL transaction

=head1 VERSION

version 0.900001

=head1 ATTRIBUTES

=head2 storage

The parent L<DBIO::PostgreSQL::EV::Storage> instance.

=head2 pg

The pinned L<EV::Pg> connection handle for the duration of this transaction.

=head2 pool

Shortcut to C<< $self->storage->pool >>.

=head2 in_txn

Always true — indicates we are inside a transaction.

=head1 METHODS

=head2 _query_async

Executes a query on the pinned transaction connection without releasing
it back to the pool. Uses L<DBIO::PostgreSQL::EV::Storage/_query_async_pinned>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
