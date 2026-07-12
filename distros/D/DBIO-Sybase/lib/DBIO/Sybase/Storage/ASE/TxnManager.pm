package DBIO::Sybase::Storage::ASE::TxnManager;
# ABSTRACT: Transaction and savepoint management for Sybase ASE

use strict;
use warnings;
use namespace::clean;

# No requires - these methods expect the consuming class to have:
# _dbh, _is_bulk_storage, _began_bulk_work, next::method

sub _exec_txn_begin {
  my $self = shift;

# bulkLogin=1 connections are always in a transaction, and can only call BEGIN
# TRAN once. However, we need to make sure there's a $dbh.
  return if $self->_is_bulk_storage && $self->_dbh && $self->_began_bulk_work;

  $self->next::method(@_);

  $self->_began_bulk_work(1) if $self->_is_bulk_storage;
}

# savepoint support using ASE syntax

sub _exec_svp_begin {
  my ($self, $name) = @_;

  $self->_dbh->do("SAVE TRANSACTION $name");
}

# A new SAVE TRANSACTION with the same name releases the previous one.
sub _exec_svp_release { 1 }

sub _exec_svp_rollback {
  my ($self, $name) = @_;

  $self->_dbh->do("ROLLBACK TRANSACTION $name");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage::ASE::TxnManager - Transaction and savepoint management for Sybase ASE

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
