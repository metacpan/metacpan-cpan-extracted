package DBIO::PostgreSQL::EV;
our $VERSION = '0.900004';
# ABSTRACT: Async PostgreSQL storage for DBIO via EV::Pg

use strict;
use warnings;

use base 'DBIO::Base';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV - Async PostgreSQL storage for DBIO via EV::Pg

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use base 'DBIO::Core';
  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');

  package MyApp::Schema;
  use DBIO 'Schema', -pg;                 # the schema declares its driver
  __PACKAGE__->register_class(Artist => 'MyApp::Schema::Result::Artist');

  package main;

  # A dbi:Pg: DSN for the PostgreSQL driver, { async => 'ev' } this
  # distribution's transport for everything async.
  my $schema = MyApp::Schema->connect(
    'dbi:Pg:dbname=myapp;host=localhost', $user, $pass,
    { async => 'ev' },
  );
  my $artists = $schema->resultset('Artist');

  # Sync calls run over DBI / DBD::Pg, as on any other connection
  my @all = $artists->all;

  # *_async calls run over EV::Pg and return Futures
  my @nina = $artists->create_async({ name => 'Nina Simone' })
    ->then(sub { $artists->search({ name => 'Nina Simone' })->all_async })
    ->get;                                # get waits by running the EV loop

  # LISTEN/NOTIFY, COPY and pipeline mode are called on the transport
  my $async = $schema->storage->async;    # the DBIO::PostgreSQL::EV::Storage

  $async->listen(artists => sub {
    my ($channel, $payload, $sender_pid) = @_;
    ...
  })->get;
  $async->notify(artists => 'changed')->get;

  $async->copy_in('artist', [qw( name )], sub {
    my ($put) = @_;
    $put->([ $_ ]) for 'Miles Davis', 'John Coltrane';  # values as they are;
  })->get;                                              # undef is NULL

  my $source = $schema->source('Artist');
  my @rows = $async->pipeline(sub {
    my ($batch) = @_;                     # a batch context, not the storage
    $batch->future_class->needs_all(
      map { $batch->insert_async($source, { name => $_ }) }
        'Billie Holiday', 'Ella Fitzgerald'
    );
  })->get;                                # one returned-columns hashref each

=head1 DESCRIPTION

This distribution is the native C<ev> async transport for PostgreSQL. It speaks
libpq's asynchronous protocol through L<EV::Pg> -- no DBI, no DBD::Pg -- and
answers every async call with a L<Future>. This page is its map: L</OVERVIEW>
says in a few lines what each part does and links to the module that documents
it.

=head2 Activating the ev mode

Async is chosen per connection (core ADR 0030): a schema that declares the
PostgreSQL driver connects with an ordinary C<dbi:Pg:> DSN and
C<< { async => 'ev' } >>, as in the L</SYNOPSIS>. The schema declares its
driver (core ADR 0067) with C<use DBIO 'Schema', -pg> or the
L<DBIO::PostgreSQL> component; both pin L<DBIO::PostgreSQL::Storage>, the sync
driver, and that driver registers the C<ev> mode with
C<< register_async_mode( ev => 'DBIO::PostgreSQL::EV::Storage' ) >>. Core
resolves the mode on the storage, so nothing else in the schema class takes
part in choosing the transport, and no component of this distribution is
loaded. A schema that declares no driver is refused at connect.

C<< $schema->storage >> stays the sync storage, with the transport embedded in
it. Sync calls run over DBI / DBD::Pg; the C<*_async> methods of the storage,
of ResultSets and of rows run over EV::Pg against the same connection info,
which the transport translates into libpq conninfo
(L<DBIO::PostgreSQL::EV::ConnectInfo>). What only this transport offers --
LISTEN/NOTIFY, COPY, pipeline mode -- is called on
C<< $schema->storage->async >>. The C<pool_size> connect attribute sizes its
connection pool (default 5), and the C<on_connect_do> / C<on_connect_call>
actions are replayed on every pooled connection.

Nothing degrades. Without the option the connection is sync and every
C<*_async> call croaks (I<< not an async connection -- connect with
{ async => ... } >>); a requested mode whose backend is not installed croaks as
well (core ADR 0030 §3). No compile-time dependency on EV is added to the sync
driver.

=head1 OVERVIEW

=head2 The transport

L<DBIO::PostgreSQL::EV::Storage> is the C<ev> async storage, a thin transport
over L<EV::Pg>: core's L<DBIO::Storage::Async> brings the CRUD, transaction,
pipeline and LISTEN/NOTIFY machinery, and this class fills its seams with
EV::Pg. The storage-level C<*_async> calls resolve in the shapes core defines
(core ADR 0031): C<select_async> with raw row arrayrefs, C<insert_async> with
the returned-columns hashref, read back with C<RETURNING *>. SQL comes from the
shared L<DBIO::PostgreSQL::SQLMaker>, whose C<?> placeholders the transport
rewrites to C<$N> itself. It declares the capabilities C<on_connect_replay>,
C<listen>, C<notify>, C<copy> and C<pipeline>, so an extension's async storage
layer that needs them composes onto it, and C<broker_connect_options>, so a
connection made from an L<DBIO::AccessBroker> takes connect options beside the
broker -- C<< connect($broker, { async => 'ev', pool_size => 3 }) >>
(L<DBIO::PostgreSQL::EV::Storage/transport_capabilities>).

=head2 Futures

Every Future the transport hands out is a L<DBIO::PostgreSQL::EV::Future>,
whose C<get> runs the L<EV> loop until the Future is ready. That is what makes
C<< ->get >> work from a plain script, and with it the transport's blocking
methods -- C<select>, C<insert>, C<txn_do>, ... -- each a C<*_async> call waited
on (ADR 0001). Inside a callback of one of the transport's own connections, a
wait that would make EV::Pg hand a result to the wrong callback is refused with
I<"Blocking wait refused">, and so is a blocking call queued for a pooled
connection while those callbacks hold every one of them -- with
C<< pool_size => 1 >>, any blocking call on the storage in a C<then> or a
C<txn_do> coderef; chain with C<then> there
(L<DBIO::PostgreSQL::EV::Future/await>). The same goes for a blocking call
made while the pool is opening the connection it would have to wait for: in
an AccessBroker's answer, or in a callback the loop runs while the broker
fetches or C<on_connect_do> is replayed.

A statement the server refused fails its Future with a
L<DBIO::Exception::Server>: C<sqlstate>, C<constraint>, C<table> and
C<detail> beside the server's text, which is what it stringifies to. A
failure that is not the server's -- connection lost, a statement refused at
dispatch -- is a plain string without a SQLSTATE
(L<DBIO::PostgreSQL::EV::Storage/What a failed statement's Future fails with>).
What the transport refuses to do with what it was given -- connect info or an
AccessBroker answer it cannot connect from, a channel name, a statement that
mixes C<$N> and C<?>, a listen connection that is closed -- is a
L<DBIO::Exception> naming the caller's file and line
(L<DBIO::PostgreSQL::EV::Storage/Refusals of the transport>).

=head2 Connection pool

L<DBIO::PostgreSQL::EV::Pool> holds the EV::Pg connections, spawned as needed
up to C<pool_size>, and replays the connect actions on each new one. It is
fork-safe: a forked child leaves the parent's sessions alone, whether it exits
or resumes the EV loop (L<DBIO::PostgreSQL::EV::Pool/Fork safety>). A
connection EV::Pg reports dead is retired instead of being handed out again;
one whose session ended while it sat idle is found when it is next borrowed,
also when nothing ran the EV loop in between
(L<DBIO::PostgreSQL::EV::Pool/_idle_connection_alive>). Every connection goes
back to the pool exactly once, also when EV::Pg
refuses a statement or a Future callback dies
(L<DBIO::PostgreSQL::EV::Storage/_dispatch_query>).

Every borrow of a pooled connection has a session of its own. When a statement,
a transaction, a pipeline or a C<copy_in> ends, the connection is reset
(C<DISCARD ALL>, then the connect actions again) before it is lent to the next
caller; a C<SET ROLE> or a C<set_config(..., false)> of one borrow is not there
in the next
(L<DBIO::PostgreSQL::EV::Storage/The session of a pooled connection>).

=head2 Transactions

C<< $schema->storage->txn_do_async >> (L<DBIO::Storage::Async/txn_do_async>)
pins one pooled connection from C<BEGIN> to C<COMMIT> or C<ROLLBACK> and hands
the coderef a L<DBIO::PostgreSQL::EV::TransactionContext>; the transaction's
statements go through that context's C<*_async> methods. The pinned connection
runs them one at a time, in the order they were issued, so a coderef that dies
while one of them is still running rolls back cleanly, and the connection goes
back to the pool idle (L<DBIO::PostgreSQL::EV::Storage/_query_async_pinned>).

=head2 Pipeline mode

C<pipeline> brackets one pooled connection with libpq's pipeline mode and hands
the block a L<DBIO::Storage::Async::PipelineContext> pinned to it; the calls
made on that context travel in one round trip (L<DBIO::Storage::Async/pipeline>,
ADR 0007). A call on the storage inside the block takes another connection and
is not batched.

=head2 LISTEN / NOTIFY

C<listen>, C<unlisten>, C<notify>, C<listen_alive>, C<listen_reconnect> and the
hooks C<on_listen_error> and C<on_listen_reconnect> are core's contract, the
same on every transport that declares it
(L<DBIO::Storage::Async/"LISTEN / NOTIFY">). This transport fills it with
EV::Pg: LISTEN runs on one dedicated connection, NOTIFY on a pooled one as
C<SELECT pg_notify($1, $2)>. The listen connection heals itself -- when the
server drops it, it is reopened after a backoff and every channel is LISTENed
again -- and it is fork-safe like a pooled one. Delivery, channel names and
liveness on PostgreSQL: L<DBIO::PostgreSQL::EV::Storage/"LISTEN / NOTIFY">.

=head2 COPY

C<copy_in> bulk-loads rows with C<COPY ... FROM STDIN> in PostgreSQL's text
format; its callback gets a writer that takes one arrayref per row
(L<DBIO::PostgreSQL::EV::Storage/copy_in>). The writer escapes each value by
the text-format rules (backslash, TAB, line feed and carriage return), so a
value arrives in the table exactly as given and C<undef> is NULL.

=head2 AccessBroker credential rotation

The transport accepts an L<DBIO::AccessBroker> as its connect info
(C<< $storage->connect_info([ $broker ]) >>): L<DBIO::AccessBroker::Static>,
L<DBIO::AccessBroker::Vault> and a L<DBIO::AccessBroker::HostBound> view over
either. It asks the broker for its current connect info for every new pooled
connection, and for the listen connection at every open, so rotated
credentials reach new connections without a pool teardown, and turns the
answer into libpq connection parameters
(L<DBIO::PostgreSQL::EV::Storage/_async_broker_conninfo>,
L<DBIO::Storage::Async/ACCESSBROKER CONSUMPTION>, ADR 0009).

A schema picks the C<ev> mode for a broker in the broker's own DBI attributes
-- C<< dbi_attrs => { async => 'ev' } >> on a Vault broker -- or, with a core
that takes the connect options beside the broker, as
C<< connect($broker, { async => 'ev' }) >>. Without either it stays sync.

  my $schema = MyApp::Schema->connect(DBIO::AccessBroker::Vault->new(
    vault     => $vault,
    dsn       => 'dbi:Pg:dbname=app;host=db1',
    cred_path => 'database/creds/app',
    dbi_attrs => { async => 'ev' },
  ));
  my $async = $schema->storage->async;   # DBIO::PostgreSQL::EV::Storage

A libpq parameter for the connections (C<sslmode>, C<connect_timeout>, ...)
belongs in the broker's answer. A hash of libpq parameters is this
transport's shape: answered to every storage, it connects the schema, and
every pooled connection and the listen connection are opened with the
parameter. The dbh of the schema's sync storage is not opened without it: of
a hash that storage applies only C<dbname>, C<host> and C<port>, so core
throws where it would connect -- at the first use of the dbh and at every
reconnect, not at C<connect>. For the parameter on the dbh too,
the broker answers the DBI form with the parameter in the DSN, which the dbh
and the pool are both opened from, or each storage its own
(L<DBIO::AccessBroker/connect_info_for_storage>). Given beside the broker,
C<< connect($broker, { async => 'ev', sslmode => ... }) >>, such a parameter
is not applied to any connection: the transport refuses to be built with it
rather than connect without it, and the sync storage refuses the same way
where it would open its dbh
(L<DBIO::PostgreSQL::EV::Storage/connect_info>,
L<DBIO::PostgreSQL::EV::Storage/_async_broker_conninfo>).

=head2 Connection security and timeouts

Set C<sslmode=verify-full> and C<sslrootcert> in the DSN
(C<dbi:Pg:dbname=app;host=db1;sslmode=verify-full;sslrootcert=/etc/ssl/db-ca.pem>)
for every connection that leaves the machine: libpq's default, C<prefer>,
falls back to plain text and checks no certificate, while C<verify-full>
encrypts, checks the server's certificate against C<sslrootcert> and checks
that the certificate names the host. The transport sets neither on its own.

Every connection this transport opens has a C<connect_timeout>. A conninfo
that sets none gets C<connect_timeout=10> (seconds); a value the connect info
gives, C<0> included, is used as it is. libpq's own default waits for ever.

=head2 Statement trace

The transport has no trace of its own. Every statement, C<BEGIN> and
C<COMMIT> included, goes through the one rule of core, shared by every async
transport: L<DBIO::Storage::Async/_debug_query>. It is on with C<DBIO_TRACE>
(or C<< $storage->debug(1) >>) and writes to the debug object of the schema's
storage; bind values, their redaction and their cut are that method's.

=head2 Test harness

L<DBIO::PostgreSQL::EV::TestHarness> is an installable live-test harness on
core's L<DBIO::Test::AsyncHarness>. It connects an C<< { async => 'ev' } >>
schema from C<DBIO_TEST_PG_DSN>, skips the test file cleanly without one,
drives the EV loop, and runs a statement on each of several pooled connections
-- the check that connect actions replay. Extension distributions such as
C<dbio-postgresql-age> build their live suites on it.

=head1 EVENT LOOP COMPATIBILITY

L<EV::Pg> uses the L<EV> event loop. This works with:

=over 4

=item * L<EV> directly

=item * L<AnyEvent> (uses EV as backend when available)

=item * L<IO::Async> via L<IO::Async::Loop::EV>

=item * L<Mojolicious> via L<Mojo::Reactor::EV>

=back

=head1 SEE ALSO

L<DBIO::PostgreSQL>, L<DBIO::Storage::Async>, L<EV::Pg>. The ADRs cited above
are in this distribution's F<docs/adr/>; the core ADRs (0030 async modes, 0031
resolution shapes, 0056 LISTEN/NOTIFY) are in L<DBIO>'s.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
