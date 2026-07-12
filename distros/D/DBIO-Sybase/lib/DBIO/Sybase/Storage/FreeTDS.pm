package DBIO::Sybase::Storage::FreeTDS;
# ABSTRACT: Base class for drivers using DBD::Sybase over FreeTDS.

use strict;
use warnings;
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

sub _exec_txn_begin {
  my $self = shift;

  if ($self->{_in_do_block}) {
    $self->_dbh->do('BEGIN TRAN');
  }
  else {
    $self->dbh_do(sub { $_[1]->do('BEGIN TRAN') });
  }
}

sub _exec_txn_commit {
  my $self = shift;

  my $dbh = $self->_dbh
    or $self->throw_exception('cannot COMMIT on a disconnected handle');

  $dbh->do('COMMIT');
}

sub _exec_txn_rollback {
  my $self = shift;

  my $dbh  = $self->_dbh
    or $self->throw_exception('cannot ROLLBACK on a disconnected handle');

  $dbh->do('ROLLBACK');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage::FreeTDS - Base class for drivers using DBD::Sybase over FreeTDS.

=head1 VERSION

version 0.900001

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

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase::Storage> - Sybase storage dispatcher (mixes this in)

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
