package DBIO::Firebird::Storage::ODBC;
# ABSTRACT: Driver for the Firebird RDBMS via L<DBD::ODBC>

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/
  DBIO::Storage::DBI::ODBC
  DBIO::Firebird::Storage::Common
/;
use mro 'c3';

__PACKAGE__->datetime_parser_type('DBIO::Firebird::DateTime::Format');

use Try::Tiny;
use namespace::clean;


# karr k50 (core k276) -- a HostBound view cannot be bound into an ODBC DSN
# here. The Firebird ODBC driver takes the server inside the database name
# (DBNAME=host/port:path) and knows no host= or port= key, which core's
# default would write into the connect string for the driver to ignore --
# the replicant connecting to whatever the database name says. Declined,
# naming the form; the view's refusal never quotes the DSN.
sub _bind_host_into_dsn {
  return (undef, 'an ODBC DSN: the Firebird ODBC driver takes the server '
    . 'inside DBNAME=host/port:path, which is not translated');
}

# Upstream DBIx::Class finding, kept: batch operations in DBD::ODBC 1.35 do not
# work with the official Firebird ODBC driver, which identifies itself as
# OdbcFb. _disable_odbc_array_ops comes from core's ODBC storage and picks the
# attribute spelling that matches the installed DBD::ODBC.
sub _run_connection_actions {
  my $self = shift;

  if (($self->_dbh_get_info('SQL_DRIVER_NAME') || '') eq 'OdbcFb') {
    $self->_disable_odbc_array_ops;
  }

  return $self->next::method(@_);
}

# Upstream DBIx::Class finding, kept: RELEASE SAVEPOINT does not work through
# this driver. Not releasing is safe -- the savepoint stays on the transaction
# until it commits or rolls back -- whereas issuing it fails the surrounding
# txn_do for a statement whose only effect would have been to free a name.
sub _exec_svp_release { 1 }

# ... and the other half of the same bug: the ROLLBACK TO SAVEPOINT works, but
# the driver reports an error it cannot describe afterwards. Anything else is
# rethrown.
sub _exec_svp_rollback {
  my ($self, $name) = @_;

  try {
    $self->_dbh->do("ROLLBACK TO SAVEPOINT $name");
  }
  catch {
    $self->throw_exception($_)
      unless /Unable to fetch information about the error/;
  };
}


sub connect_call_datetime_setup { 1 }

# ADR 0040 -- the whole operation of obtaining a query plan, which on this
# transport is: none. See the DESCRIPTION for why neither core's EXPLAIN nor
# the InterBase driver's func('ib_plan') is reachable from a DBD::ODBC handle.
# Refusing here is the ADR 0039 trade: a caller who asked for something this
# transport cannot do learns that from the method they called, instead of from
# a parse error several layers below it.
sub _explain_query {
  my $self = shift;

  $self->throw_exception(
    'Firebird cannot produce a query plan over ODBC. The engine has no EXPLAIN '
  . 'statement at all -- the token is not in the Firebird 5.0 Language '
  . 'Reference, Appendix C, which lists every keyword reserved and '
  . 'non-reserved -- and its plan is an attribute of the PREPARED statement '
  . '(isc_dsql_sql_info / isc_info_sql_get_plan), which DBD::Firebird and '
  . 'DBD::InterBase reach through the private $sth->func(\'ib_plan\') and '
  . 'DBD::ODBC does not expose in any form. Connect through DBD::Firebird or '
  . 'DBD::InterBase to explain a query on this engine.'
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Storage::ODBC - Driver for the Firebird RDBMS via L<DBD::ODBC>

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Firebird reached through L<DBD::ODBC> rather than through L<DBD::Firebird> or
L<DBD::InterBase>. The engine semantics come from
L<DBIO::Firebird::Storage::Common> and the ODBC transport helpers from
L<DBIO::Storage::DBI::ODBC>; this class holds only what is true of B<this
transport> and of no other (ADR 0010).

The nested-statement-handles-across-commits problem of the two native drivers
is a fact of their DBDs
(L<connect_call_use_softcommit|DBIO::Firebird::Storage::InterBase/connect_call_use_softcommit>,
L<disable_sth_caching|DBIO::Storage::DBI/disable_sth_caching>); this class
has not been checked against it (see L</CAVEATS>).

=head2 Why this class is not a subclass of the InterBase driver

L<DBIO::Firebird::Storage::InterBase> speaks the C<ib_*> API of
L<DBD::InterBase> -- C<ib_dialect> in the DSN, C<ib_softcommit>, C<ib_time_all>,
and C<< $sth->func('ib_plan') >> for a query plan. B<None of it exists on
L<DBD::ODBC>>, so inheriting from that class would put four connection-time
attribute writes and one private XSUB call into a handle that has never heard of
any of them. The split is the one ADR 0001 already draws and this class extends
sideways: what is a fact about the SQL both engines speak lives on
C<Storage::Common> and is inherited here (the C<FIRST>/C<SKIP> limit dialect,
C<RAND()>, C<GEN_ID> sequences, C<RDB$DATABASE> in the C<EXISTS> query, the
refusal of the four set operations Firebird has no operator for, C<INSERT ...
RETURNING>, the C<"> quote char, C<sqlt_type>); what hangs off a DBD's own API
stays with that DBD.

The same cut decides what an L<DBIO::AccessBroker> may hand this transport: an
C<odbc_> attribute in its hash answer or beside it goes to
C<< DBI->connect >>, an C<ib_> one is refused, since L<DBD::ODBC> would keep
it without applying it
(L<DBIO::Firebird::Storage::InterBase/ib_ attributes through an AccessBroker>).

=head2 Query plans are not reachable over ODBC

Firebird has no C<EXPLAIN> statement of any kind, and its plan is an attribute
of the B<prepared> statement, read with C<isc_dsql_sql_info(isc_info_sql_get_plan)>.
The two native DBDs expose that call as C<< $sth->func('ib_plan') >>; L<DBD::ODBC>
exposes nothing equivalent, and the ODBC API has no vendor-neutral spelling for
it either. C<_explain_query> therefore B<throws> here rather than inheriting
either half of a wrong answer: core's C<EXPLAIN E<lt>queryE<gt>> would be a
C<Token unknown> parse error from the server, and the C<ib_plan> override of
L<DBIO::Firebird::Storage::InterBase> would be a call into a function this
handle does not have. Connect through L<DBD::Firebird> or L<DBD::InterBase> when
you need a plan.

=head2 Which storage class an ODBC DSN lands in

The one this schema declares. An ODBC DSN does not say which engine is behind
it -- every engine reached through L<DBD::ODBC> shares the DBD name C<ODBC> --
so nothing picks this class from the DSN: it is reached by declaring it, on
the schema class or on a clone of it before connecting:

  package MyApp::DB;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Firebird::Storage::ODBC');

  # or, for a schema class shared between transports
  my $schema = MyApp::DB->clone(storage_type => '+DBIO::Firebird::Storage::ODBC')
    ->connect('dbi:ODBC:Driver=Firebird;Dbname=/path/app.fdb', $user, $pass);

The declared storage class stands (DBIO core ADR 0059): the storage stays in
this class, and driver resolution adds nothing to the connect string.

The Firebird component and the C<-fb> shortcut declare
L<DBIO::Firebird::Storage>, the L<DBD::Firebird> class. An ODBC DSN under that
declaration does B<not> reach this class: the storage stays
L<DBIO::Firebird::Storage>, core warns about the driver mismatch, and that
class appends C<ib_dialect=3> to the ODBC connect string. A schema that loads
the component with C<load_components('Firebird')> cannot declare this class on
a clone either, since the component sets its storage class on every
C<connection>. Letting the Firebird driver adapt itself to an ODBC DSN
(C<_adapt_to_access_path>, ADR 0059) is open.

DBIO core ADR 0067: a schema always declares its driver; nothing detects it
from the connected handle.

=head1 METHODS

=head2 connect_call_datetime_setup

Used as:

  on_connect_call => 'datetime_setup'

A B<noop> on this transport, so that the same C<connect_info> works for all
three Firebird DBDs. The native drivers need
L<DBIO::Firebird::Storage::InterBase/connect_call_datetime_setup> to put
L<DBD::InterBase> into ISO date and timestamp formats (C<ib_time_all>); the
ODBC driver already answers in the ODBC canonical form, which is the same
C<%Y-%m-%d %H:%M:%S> shape L<DBIO::Firebird::DateTime::Format> parses.

Without this method the connect-call would die looking for it -- C<datetime_setup>
is resolved by name against the storage class.

The native storages put every connection into the ISO formats by default; this
transport needs nothing analogous, because the ODBC driver already answers in
the canonical form. That is the reading of the existing claim above, not
something measured here: no Firebird ODBC driver was available to test
against, so the transport is unchanged.

=head1 CAVEATS

=over 4

=item *

B<Unverified.> No Firebird server was reached over ODBC for any of this. The
two savepoint workarounds and the C<OdbcFb> array-operations one are upstream
L<DBIx::Class> findings carried over with their reasons; the datetime claim
above is the ODBC canonical format rather than something observed. The ODBC leg
of F<t/10-firebird.t>, F<t/20-firebird-core.t> and F<t/30-datetime-firebird.t>
(C<DBIO_TEST_FIREBIRD_ODBC_DSN>) is where a server checks them.

=item *

Query plans are unavailable, see L</Query plans are not reachable over ODBC>.

=back

=head1 SEE ALSO

=over

=item * L<DBIO::Firebird> - Firebird schema component

=item * L<DBIO::Firebird::Storage::Common> - Shared Firebird/InterBase logic

=item * L<DBIO::Firebird::Storage> - Firebird driver via L<DBD::Firebird>

=item * L<DBIO::Firebird::Storage::InterBase> - InterBase driver via L<DBD::InterBase>

=item * L<DBIO::Storage::DBI::ODBC> - Base class for ODBC drivers

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
