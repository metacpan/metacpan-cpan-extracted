package DBIO::MySQL::Storage::MariaDB;
# ABSTRACT: MariaDB-specific storage for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::MySQL::Storage/;

DBIO::Storage::DBI->register_driver('MariaDB' => __PACKAGE__);

# No sql_maker_class of its own (karr #30). It used to point at
# DBIO::MySQL::SQLMaker::MariaDB for one reason -- the locking-read grammar --
# and that is a SERVER question this class cannot answer: it is the DBD::MariaDB
# binding, and DBD::MariaDB reaches MySQL servers as readily as MariaDB ones.
# DBIO::MySQL::Storage/_lock_dialect now decides it from the server, so this
# class inherits DBIO::MySQL::SQLMaker like every other MySQL connection.



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Storage::MariaDB - MariaDB-specific storage for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');

  my $schema = MyApp::Schema->connect($dsn, $user, $pass);

=head1 DESCRIPTION

MariaDB-specific storage backend for L<DBIO>: the L<DBIO::MySQL::Storage>
subclass registered for a C<dbi:MariaDB:> DSN (L<DBD::MariaDB>). It overrides
no behaviour of its own. It exists as the registration target for the
C<MariaDB> DBI driver, and as the class the C<future_io> transport is resolved
from by convention (L<DBIO::MySQL::Storage::MariaDB::Async>).

The L<DBD::MariaDB> attribute names -- C<mariadb_insertid> for the last insert
id, C<mariadb_auto_reconnect> for the auto-reconnect that is switched off on
every connect -- are not chosen here. L<DBIO::MySQL::Storage> reads them off
the DBD that owns the handle (L<DBIO::MySQL::Storage/_dbd_attribute>).
C<load_components('MySQL')> over a C<dbi:MariaDB:> DSN never reaches this class,
so a choice made here would miss it. This class used to override
C<_dbh_last_insert_id> and C<_run_connection_actions> for them. The second
override skipped the parent's C<_run_connection_actions> on purpose, and with it
anything the parent added there. Both are gone.

This class is auto-registered for the C<MariaDB> DBI driver and is activated
when L<DBIO::MySQL::MariaDB/connection> is called.

=head2 This class is the DBD, not the engine

Everything above is a L<DBD::MariaDB> fact, and that is the whole of what this
subclass is for. It is B<not> a statement about the server at the other end:
DBD::MariaDB connects to MySQL servers just as happily, and a MariaDB server
reached through a C<dbi:mysql:> DSN lands in the parent class instead.

So B<no SQL dialect decision is taken here at class level>, and none
is left: which spelling of an upsert's attempted values the server
understands, whether it has C<RETURNING>, which locking-read grammar it has, and
which spelling of the replica-status statement it answers are all properties of
the engine, and all are decided in L<DBIO::MySQL::Storage> from
L<DBIO::MySQL::Storage/_is_mariadb> plus the server version -- correct for all
four DBD/engine combinations, where a class-level answer here is right for two
of them and wrong for the other two.

Two of those are not decided here, and each would be a latent syntax error of
that exact shape:

=over 4

=item *

B<The locking-read grammar> is not set by this class's C<sql_maker_class>
(pointing at L<DBIO::MySQL::SQLMaker::MariaDB> purely to spell C<< for =>
'share' >> as C<LOCK IN SHARE MODE>). A MariaDB server reached through a
C<dbi:mysql:> DSN never gets here at all and would be handed C<FOR SHARE>,
which MariaDB has in no version; a MySQL 8 reached through L<DBD::MariaDB> --
how this dist's live suite reaches MySQL -- does get here and would be handed
C<LOCK IN SHARE MODE OF `t` NOWAIT>, which MySQL rejects, because the legacy
spelling is precisely the one that carries neither C<OF> nor a modifier. See
L<DBIO::MySQL::Storage/_lock_dialect>.

=item *

B<The replica-status statement> is not overridden here to try C<SHOW REPLICA
STATUS> first. The rename is a server fact on both products and they made it
at different releases -- and MySQL renamed the B<output columns> with it, so
against a MySQL 8.0.22+ replica through L<DBD::MariaDB> the statement would
succeed and C<is_replicating> would then read a C<Slave_IO_Running> that was
no longer there. Meanwhile the parent's plain C<SHOW SLAVE STATUS> is a syntax
error on MySQL 8.4, which removed it. See
L<DBIO::MySQL::Storage/_replication_status_statement>.

=back

=head1 SEE ALSO

=pod

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
