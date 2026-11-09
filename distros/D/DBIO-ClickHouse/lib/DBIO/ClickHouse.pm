package DBIO::ClickHouse;
# ABSTRACT: ClickHouse-specific schema management for DBIO
our $VERSION = '0.900004';

use strict;
use warnings;

use base 'DBIO::Base';

use DBIO::ClickHouse::DDL;


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::ClickHouse::Storage');
  return $self->next::method(@info);
}


sub clickhouse_install_ddl {
  my ($self) = @_;
  return DBIO::ClickHouse::DDL->install_ddl($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse - ClickHouse-specific schema management for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ClickHouse');

  my $schema = MyApp::Schema->connect(
    'dbi:mysql:database=default;host=127.0.0.1;port=9004', $user, $pass,
    { mysql_enable_utf8mb4 => 1 },
  );

  # or, using the `-ch` shortcut:
  package MyApp::Schema;
  use DBIO Schema => -ch;

=head1 DESCRIPTION

L<DBIO::ClickHouse> is the ClickHouse driver component for DBIO. When loaded
into a schema class, C<connection()> sets L<DBIO::Schema/storage_type> to
C<+DBIO::ClickHouse::Storage>, which enables ClickHouse-specific storage
behavior.

=head2 Transport: the MySQL wire protocol

ClickHouse is a column-oriented OLAP database that speaks the B<MySQL wire
protocol> on server port B<9004>. There is no native C<DBD::ClickHouse> on
CPAN, so this driver rides L<DBD::mysql> or L<DBD::MariaDB> over that wire
protocol. B<L<DBD::mysql> is the standard>: it sends no SQL at all
on connect, so it works against a B<stock> ClickHouse server -- and therefore
ClickHouse Cloud -- with no server-side accommodation. The live suite runs
against 25.3.14.14 over a C<dbi:mysql:> DSN pointed at an unmodified server.
Connect with
C<< mysql_enable_utf8mb4 => 1 >> or character data comes back as bytes; the
live harness sets it for you.

L<DBD::MariaDB> is supported for servers whose config you control. It issues
C<SET character_set_server = 'utf8mb4'> on every connect, which a stock
ClickHouse refuses with C<UNKNOWN_SETTING> unless the server registers

  <custom_settings_prefixes>SQL_,character_set_,collation_,sql_</custom_settings_prefixes>

read at server start only. ClickHouse Cloud forbids custom prefixes, so
L<DBD::MariaDB> is unusable there. It decodes character data unconditionally,
so no utf8 attribute is needed.

Either way the DSN names the DBD, never the database:
C<dbi:mysql:...;port=9004> or C<dbi:MariaDB:...;port=9004>, both reaching
L<DBIO::ClickHouse::Storage>. See
C<docs/adr/0001-mysql-wire-protocol-transport.md>.

=head2 The storage must be pinned explicitly

A ClickHouse MySQL-wire DSN is C<dbi:MariaDB:...> (or C<dbi:mysql:...>), which
is B<indistinguishable> from a real MySQL DSN and would otherwise resolve to
the MySQL storage. There is therefore B<no DSN-based autodetection> for
ClickHouse. You must pin C<+DBIO::ClickHouse::Storage> either by loading this
component or by the C<-ch> shortcut -- both do so via C<connection()> /
L<DBIO/apply_driver>. The pinned storage takes both DBDs as its own access
path, so neither is reported as another driver's
(L<DBIO::ClickHouse::Storage/ACCESS PATH: DBD::MYSQL AND DBD::MARIADB>).

=head1 METHODS

=head2 connection

Overrides L<DBIO/connection> to force C<+DBIO::ClickHouse::Storage> as
C<storage_type>.

=head2 clickhouse_install_ddl

    my $sql = $schema->clickhouse_install_ddl;

Generates the ClickHouse-native install DDL for this schema through
L<DBIO::ClickHouse::DDL/install_ddl>: one C<CREATE TABLE> per source, each with
an explicit C<ENGINE> and sorting key, statements separated by a blank line.

This is the method L<DBIO::ClickHouse::Storage/deployment_statements> looks for,
so loading this component is also what makes C<deployment_statements> work.

=head1 CLICKHOUSE SEMANTICS

ClickHouse shares only the wire protocol with MySQL, not the semantics. Notably:
no transactions, no savepoints, no C<SELECT ... FOR UPDATE>, no
C<INSERT ... RETURNING>, and no auto-increment / C<last_insert_id> (the primary
key is the MergeTree C<ORDER BY> key; surrogate identity uses
C<generateUUIDv4()>). C<UPDATE> / C<DELETE> are asynchronous mutations
(C<ALTER TABLE ... UPDATE/DELETE>). See L<DBIO::ClickHouse::Storage> and
C<docs/adr/0002-standalone-dist-not-mysql-subclass.md>.

=head2 Transactions

Since there are none, the transaction API is split in two rather than faked
wholesale. Everything that only B<promises> atomicity is a no-op and warns once
per interpreter: C<txn_begin> and C<txn_commit> send nothing to the server, and
C<txn_do> runs its coderef without a C<BEGIN>/C<COMMIT> bracket (and never
retries it). If that coderef dies, its exception propagates B<unchanged>,
preceded by a loud warning -- one per failure -- that everything the block
completed is permanent.

Everything that B<claims work was undone> throws: C<txn_rollback> always throws
a L<DBIO::Exception>. Swallowing a rollback would leave your code believing the
changes are gone while they are still in the table, which is the one case where
a silent no-op corrupts your understanding of the data rather than merely
failing to help.

So ordinary schema code (including core's own C<populate>, multi-create,
C<delete_all> and cascade delete, which all use C<txn_scope_guard>) keeps
working -- minus the atomicity ClickHouse never had. See
L<DBIO::ClickHouse::Storage/TRANSACTIONS> and
C<docs/adr/0003-no-transactions-policy.md>.

Native DDL generation is implemented: L</clickhouse_install_ddl> renders the
install DDL through L<DBIO::ClickHouse::DDL>, with the per-table C<ENGINE>,
C<ORDER BY>, C<PARTITION BY> and C<SETTINGS> options declared through
L<DBIO::ClickHouse::Result>'s C<clickhouse_table>. Introspection
(L<DBIO::ClickHouse::Introspect>), diff (L<DBIO::ClickHouse::Diff>) and
desired-state deploy (L<DBIO::ClickHouse::Deploy>) are implemented as well.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
