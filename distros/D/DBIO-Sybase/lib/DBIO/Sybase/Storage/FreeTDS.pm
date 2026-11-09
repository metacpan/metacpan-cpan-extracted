package DBIO::Sybase::Storage::FreeTDS;
# ABSTRACT: Base class for drivers using DBD::Sybase over FreeTDS.

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Sybase::Storage/;
use mro 'c3';
use Try::Tiny;
use namespace::clean;


# The subclass storage driver defines _set_autocommit_stmt
# for MsSQL it is SET IMPLICIT_TRANSACTIONS ON/OFF
# for proper Sybase it's SET CHAINED ON/OFF
sub _set_autocommit {
  my $self = shift;

  if ($self->_dbh_autocommit) {
    $self->_dbh->do($self->_set_autocommit_stmt(1));
  } else {
    $self->_dbh->do($self->_set_autocommit_stmt(0));
  }
}

# Handle AutoCommit and SET TEXTSIZE because LongReadLen doesn't work.
#
sub _run_connection_actions {
  my $self = shift;

  # based on LongReadLen in connect_info
  $self->set_textsize;

  $self->_set_autocommit;

  $self->next::method(@_);
}


sub set_textsize {
  my $self = shift;
  my $text_size =
    shift
      ||
    try { $self->_dbio_connect_attributes->{LongReadLen} }
      ||
    32768; # the DBD::Sybase default

  $self->_dbh->do("SET TEXTSIZE $text_size");
}

# The statement handles of $dbh that are still active. DBD::Sybase sends a
# statement on a database handle with an active statement handle over a
# connection of its own, so BEGIN TRAN, COMMIT and ROLLBACK sent with
# $dbh->do would land on a session that is not the transaction's (karr k65).
sub _active_statement_handles {
  my ($self, $dbh) = @_;

  return () unless $dbh->{ActiveKids};

  return grep { $_ && $_->{Active} } @{ $dbh->{ChildHandles} || [] };
}

sub _refuse_with_open_cursor {
  my ($self, $what, $dbh) = @_;

  $self->throw_exception(
    "Cannot $what while a statement handle of the connection is still "
  . 'active (an open cursor): DBD::Sybase over FreeTDS would send it on a '
  . 'second connection, outside the transaction. Read the cursor to its end '
  . 'or finish it first'
  ) if $self->_active_statement_handles($dbh);
}

sub _exec_txn_begin {
  my $self = shift;

  if ($self->{_in_do_block}) {
    my $dbh = $self->_dbh;
    $self->_refuse_with_open_cursor('BEGIN TRAN', $dbh);
    $dbh->do('BEGIN TRAN');
  }
  else {
    $self->dbh_do(sub {
      $_[0]->_refuse_with_open_cursor('BEGIN TRAN', $_[1]);
      $_[1]->do('BEGIN TRAN');
    });
  }
}

sub _exec_txn_commit {
  my $self = shift;

  my $dbh = $self->_dbh
    or $self->throw_exception('cannot COMMIT on a disconnected handle');

  $self->_refuse_with_open_cursor('COMMIT', $dbh);

  $dbh->do('COMMIT');
}

sub _exec_txn_rollback {
  my $self = shift;

  my $dbh  = $self->_dbh
    or $self->throw_exception('cannot ROLLBACK on a disconnected handle');

  # an open cursor is ended, so that the ROLLBACK goes out on the session of
  # the transaction
  $_->finish for $self->_active_statement_handles($dbh);

  $dbh->do('ROLLBACK');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage::FreeTDS - Base class for drivers using DBD::Sybase over FreeTDS.

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Base storage class for L<DBD::Sybase> connections using the FreeTDS library.
It is a subclass of L<DBIO::Sybase::Storage> and is mixed in automatically
by L<DBIO::Sybase::Storage> when FreeTDS is detected.

Provides FreeTDS-specific transaction management (explicit C<BEGIN TRAN>,
C<COMMIT>, C<ROLLBACK>) and text size handling via C<SET TEXTSIZE>, since
C<< $dbh->{LongReadLen} >> is not available under FreeTDS.

=head1 METHODS

=head2 set_textsize

When using DBD::Sybase with FreeTDS, C<< $dbh->{LongReadLen} >> is not available,
use this function instead. It does:

  $dbh->do("SET TEXTSIZE $bytes");

Takes the number of bytes, or uses the C<LongReadLen> value from your
L<connect_info|DBIO::Storage::DBI/connect_info> if omitted, lastly falls
back to the C<32768> which is the L<DBD::Sybase> default.

=head1 TRANSACTIONS AND OPEN CURSORS

L<DBD::Sybase> runs a statement on a database handle that has an active
statement handle (an open cursor, or a statement the server refused at
prepare) over a second connection. C<BEGIN TRAN>, C<COMMIT> and C<ROLLBACK>
would then miss the session of the transaction while the storage counted on as
if they had not. So, when the connection has an active statement handle:

=over

=item * C<ROLLBACK> -- also that of a C<txn_scope_guard> and of C<txn_do> --
finishes every active statement handle of the connection first and rolls back
on the same connection. A cursor read across the rollback is ended by it; that
is the price.

=item * C<BEGIN TRAN> throws an exception that names the open cursor, before
anything is sent. The storage is as it was, C<transaction_depth> included.
Read the cursor to its end, or finish it, first.

=item * C<COMMIT> throws the same exception before anything is sent. The core
treats it like any failed commit of the outermost transaction: the
transaction is over. The storage finishes the cursor and sends C<ROLLBACK> on
the same connection, C<transaction_depth> is 0, and the caller gets the error
of the C<COMMIT>. Nothing of the transaction is kept; read the cursor to its end,
or finish it, before the commit.

=back

Nothing is ever sent on a second connection silently. Without an active
statement handle nothing changes.

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase::Storage> - Sybase base storage (mixes this in)

=item * L<DBIO::Sybase::Storage::ASE> - Sybase ASE storage

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

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
