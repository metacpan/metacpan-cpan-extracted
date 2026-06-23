package DBIO::MySQL::Async::TransactionContext;
# ABSTRACT: Pinned connection context for an async MySQL/MariaDB transaction

use strict;
use warnings;
use Future ();
use namespace::clean;

sub new {
  my ($class, %args) = @_;
  return bless {
    storage => $args{storage} // die('storage required'),
    mdb     => $args{mdb}     // die('mdb required'),
  }, $class;
}


sub storage { $_[0]->{storage} }


sub txn_mdb { $_[0]->{mdb} }


sub pool { $_[0]->{storage}->pool }


sub in_txn { 1 }


sub _query_async {
  my ($self, $sql, $bind) = @_;
  return $self->{storage}->_query_async_pinned($self->{mdb}, $sql, $bind);
}

# Explicit delegation of the public API. The autoloaded version was
# fragile: it silently forwarded typos, bypassing can() and method
# checks. Each method below is the contract a txn_do_async callback
# is allowed to call on the context.
#
# CRUD inside a transaction MUST run on the pinned connection that
# BEGIN/COMMIT ran on, not a fresh pooled one. Each CRUD method routes
# through the storage's shared CRUD builder with the pinned connection
# (txn_mdb), so SQL generation (insert + LAST_INSERT_ID, select_single
# first-row) is not duplicated. Forwarding to $storage->select_async etc.
# would acquire a separate pool connection and run the query OUTSIDE the
# transaction.

sub select_async        { my $s = shift; $s->{storage}->_run_crud_pinned('select',        $s->{mdb}, @_) }
sub select_single_async { my $s = shift; $s->{storage}->_run_crud_pinned('select_single', $s->{mdb}, @_) }
sub insert_async        { my $s = shift; $s->{storage}->_run_crud_pinned('insert',        $s->{mdb}, @_) }
sub update_async        { my $s = shift; $s->{storage}->_run_crud_pinned('update',        $s->{mdb}, @_) }
sub delete_async        { my $s = shift; $s->{storage}->_run_crud_pinned('delete',        $s->{mdb}, @_) }
sub select              { my $s = shift; $s->select_async(@_)->get        }
sub select_single       { my $s = shift; $s->select_single_async(@_)->get }
sub insert              { my $s = shift; $s->insert_async(@_)->get        }
sub update              { my $s = shift; $s->update_async(@_)->get        }
sub delete              { my $s = shift; $s->delete_async(@_)->get        }
sub sql_maker           { my $s = shift; $s->{storage}->sql_maker(@_)           }
sub debug               { my $s = shift; $s->{storage}->debug(@_)               }
sub pipeline            { my $s = shift; $s->{storage}->pipeline(@_)            }
sub txn_do_async        { my $s = shift; $s->{storage}->txn_do_async(@_)        }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Async::TransactionContext - Pinned connection context for an async MySQL/MariaDB transaction

=head1 VERSION

version 0.900000

=head1 ATTRIBUTES

=head2 storage

The parent L<DBIO::MySQL::Async::Storage> instance.

=head2 txn_mdb

The pinned L<EV::MariaDB> connection handle for the duration of this transaction.

=head2 pool

Shortcut to C<< $self->storage->pool >>.

=head2 in_txn

Always true — indicates we are inside a transaction.

=head1 METHODS

=head2 _query_async

Forwards query execution to the underlying storage using the pinned
transaction connection (C<txn_mdb>) via
L<DBIO::MySQL::Async::Storage/_query_async_pinned> (no release).

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
