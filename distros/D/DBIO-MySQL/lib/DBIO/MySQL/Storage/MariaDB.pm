package DBIO::MySQL::Storage::MariaDB;
# ABSTRACT: MariaDB-specific storage for DBIO

use strict;
use warnings;

use base qw/DBIO::MySQL::Storage/;

DBIO::Storage::DBI->register_driver('MariaDB' => __PACKAGE__);

__PACKAGE__->sql_maker_class('DBIO::MySQL::SQLMaker::MariaDB');


sub _dbh_last_insert_id {
  my ($self, $dbh, $source, $col) = @_;
  $dbh->{mariadb_insertid};
}

sub _run_connection_actions {
  my $self = shift;

  if (
    $self->_dbh->{mariadb_auto_reconnect}
      and
    ! exists $self->_dbio_connect_attributes->{mariadb_auto_reconnect}
  ) {
    $self->_dbh->{mariadb_auto_reconnect} = 0;
  }

  $self->DBIO::Storage::DBI::_run_connection_actions(@_);
}

sub _replication_status_row {
  my $self = shift;
  my $dbh = $self->_get_dbh;
  # MariaDB 10.5+ renamed SHOW SLAVE STATUS to SHOW REPLICA STATUS; older
  # versions only know the legacy statement. Try modern first, fall back.
  return $dbh->selectrow_hashref('SHOW REPLICA STATUS')
      // $dbh->selectrow_hashref('SHOW SLAVE STATUS');
}


sub lag_behind_master {
  my $status = shift->_replication_status_row
    or return undef;
  return $status->{Seconds_Behind_Master};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Storage::MariaDB - MariaDB-specific storage for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');

  my $schema = MyApp::Schema->connect($dsn, $user, $pass);

=head1 DESCRIPTION

MariaDB-specific storage backend for L<DBIO>. Extends L<DBIO::MySQL::Storage>
with adaptations for L<DBD::MariaDB>:

=over 4

=item *

Reads C<mariadb_insertid> instead of C<mysql_insertid> for last-insert-id
retrieval.

=item *

Disables C<mariadb_auto_reconnect> by default, consistent with the MySQL
storage behavior, to prevent silent transaction loss.

=item *

Replication status queries use C<SHOW REPLICA STATUS> (MariaDB 10.5+) with
fallback to C<SHOW SLAVE STATUS> for older servers.

=back

This class is auto-registered for the C<MariaDB> DBI driver and is activated
when L<DBIO::MySQL::MariaDB/connection> is called.

=head1 METHODS

=head2 is_replicating

Returns true if the connected MariaDB replica is currently replicating (both
IO and SQL threads running). Inherited from L<DBIO::MySQL::Storage>;
C<_replication_status_row> is overridden to prefer C<SHOW REPLICA STATUS>.

=head2 lag_behind_master

Returns the number of seconds the replica is behind the master. Queries
C<SHOW REPLICA STATUS> first, falling back to C<SHOW SLAVE STATUS> for older
servers.

=seealso

=over 4

=item * L<DBIO::MySQL::MariaDB> - Schema component that activates this storage

=item * L<DBIO::MySQL::Storage> - MySQL parent class

=item * L<DBIO::MySQL> - Main distribution entry point

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
