package DBIO::PostgreSQL::Storage::Async;
# ABSTRACT: future_io async PostgreSQL transport over DBD::Pg's pg_async binding

use strict;
use warnings;
use base 'DBIO::Async::Storage';

use Carp 'croak';
use DBI;
use DBD::Pg qw(:async);
use Future::IO;
use DBIO::PostgreSQL::SQLMaker;
use namespace::clean;


# --- SQL shaping seams ------------------------------------------------------


sub sql_maker_class { 'DBIO::PostgreSQL::SQLMaker' }


sub _sql_maker_args {
  return (
    quote_char    => '"',
    name_sep      => '.',
    limit_dialect => 'LimitOffset',
  );
}

# Translate SQL-standard '?' placeholders into PostgreSQL positional '$N'
# placeholders, numbering left-to-right so they line up with the maker's @bind.
#
# The shared DBIO::PostgreSQL::SQLMaker is also used by the SYNC DBI driver,
# which needs '?', so the maker MUST keep emitting '?'. The translation
# therefore lives here, in the async transport, applied to maker output before
# it reaches DBD::Pg. DBD::Pg accepts both '?' and '$N', but we normalise to
# '$N' so _submit_query can set pg_placeholder_dollaronly and thereby leave the
# JSONB '@?' operator's literal '?' untouched.
#
# Subtleties this must respect (all verified against the maker's output):
#   * '@?' is the JSONB jsonpath operator, not a placeholder. A '?' that is
#     immediately preceded by '@' is part of an operator and is left alone.
#     Its actual RHS placeholder ('@? ?::jsonpath') is a separate '?' and
#     does get translated.
#   * '?::jsonb' / '?::jsonpath' casts are real placeholders -> '$N::jsonb'.
#   * 'ARRAY[?, ?]' (jsonb_exists_any/all) has one placeholder per '?'.
#   * A '?' inside a single-quoted string literal ('...', with '' escaping)
#     or a double-quoted identifier ("...", with "" escaping) is data/name,
#     not a placeholder, and is skipped. This is defensive against inlined
#     literals that happen to contain '?'.


sub _transform_sql {
  my ($self, $sql) = @_;

  my $out = '';
  my $n   = 0;
  my $len = length $sql;
  my $i   = 0;

  while ($i < $len) {
    my $c = substr($sql, $i, 1);

    if ($c eq "'" || $c eq '"') {
      # Copy a quoted run verbatim, honouring doubled-quote escaping.
      my $quote = $c;
      $out .= $c;
      $i++;
      while ($i < $len) {
        my $d = substr($sql, $i, 1);
        $out .= $d;
        $i++;
        if ($d eq $quote) {
          if ($i < $len && substr($sql, $i, 1) eq $quote) {
            $out .= $quote;   # doubled quote -> escaped, stay inside
            $i++;
          } else {
            last;             # end of quoted run
          }
        }
      }
      next;
    }

    if ($c eq '?') {
      # '@?' operator: the '?' belongs to the operator, not a placeholder.
      if ($i > 0 && substr($sql, $i - 1, 1) eq '@') {
        $out .= $c;
        $i++;
        next;
      }
      $out .= '$' . (++$n);
      $i++;
      next;
    }

    $out .= $c;
    $i++;
  }

  return $out;
}


sub _post_insert_sql { ' RETURNING *' }

# --- Connect-info seam ------------------------------------------------------


sub _normalize_conninfo {
  my ($self, $info) = @_;

  # DBI-form: [ 'dbi:Pg:...', $user, $pass, \%attrs ] -> our conninfo shape.
  if (ref $info eq 'ARRAY'
      && defined $info->[0] && !ref $info->[0] && $info->[0] =~ /^dbi:/i) {
    my ($dsn, $user, $pass, $attrs) = @$info;
    $attrs = {} unless ref $attrs eq 'HASH';
    my %conninfo = (
      dsn      => $dsn,
      user     => $user,
      password => $pass,
      attrs    => { %$attrs },
    );
    $conninfo{pool_size} = delete $conninfo{attrs}{pool_size}
      if defined $conninfo{attrs}{pool_size};
    return [ \%conninfo, {} ];
  }

  # Broker arrayref [ $broker ], or an already-normalised [ \%conninfo, \%opts ]
  # pair -- leave for the inherited broker detection / normalisation.
  return $info;
}

# --- Pool connection lifecycle ----------------------------------------------


sub _create_pool_connection {
  my ($self, $conninfo) = @_;

  croak 'PostgreSQL async conninfo must be a hashref with a dsn'
    unless ref $conninfo eq 'HASH' && defined $conninfo->{dsn};

  my $dbh = DBI->connect(
    $conninfo->{dsn},
    $conninfo->{user},
    $conninfo->{password},
    {
      %{ $conninfo->{attrs} || {} },
      AutoCommit => 1,
      RaiseError => 1,
      PrintError => 0,
    },
  ) or croak "DBD::Pg connect failed: $DBI::errstr";

  return { dbh => $dbh };
}


sub _shutdown_pool_connection {
  my ($self, $conn) = @_;
  my $dbh = $conn->{dbh} or return;
  $dbh->disconnect if $dbh->{Active};
}

# --- Readiness / socket seams -----------------------------------------------


sub _conn_ready {
  my ($self, $conn) = @_;
  return $conn->{dbh} && $conn->{dbh}{Active} ? 1 : 0;
}


sub _conn_fileno {
  my ($self, $conn) = @_;
  return $conn->{dbh}{pg_socket};
}

# --- Query submit / collect -------------------------------------------------


sub _submit_query {
  my ($self, $conn, $sql, $bind) = @_;
  $bind //= [];

  my $dbh = $conn->{dbh};

  # Release the previous (already-collected) async statement handle BEFORE
  # starting a new async query. DBD::Pg tracks async state on the DATABASE
  # handle; destroying a spent async sth *after* the new execute clobbers the
  # new query's async status back to 0, so the next _collect_result sees
  # "pg_ready: No asynchronous query is running" on the second query over a
  # reused pooled connection. Clearing it here means the new execute owns the
  # dbh async slot uncontested.
  delete $conn->{sth};

  my $sth = $dbh->prepare($sql, {
    pg_async                  => PG_ASYNC,
    pg_placeholder_dollaronly => 1,
  });
  $sth->execute(@$bind);
  $conn->{sth} = $sth;

  return;
}


sub _collect_result {
  my ($self, $conn, $sql, $bind) = @_;

  my $dbh = $conn->{dbh};

  # The result may not have fully arrived on the first readable event. pg_ready
  # consumes what is on the wire and reports whether the result is complete;
  # if not, wait for more and re-check rather than blocking in pg_result.
  unless ($dbh->pg_ready) {
    return $self->_await_readable($conn)->then(sub {
      return $self->_collect_result($conn, $sql, $bind);
    });
  }

  my $sth = $conn->{sth};
  my $rv  = $dbh->pg_result;   # finalise; dies (RaiseError) on a query error

  if (($sth->{NUM_OF_FIELDS} || 0) > 0) {
    my $rows = $sth->fetchall_arrayref;
    return $self->future_class->done(@$rows);
  }

  return $self->future_class->done($rv);
}

# --- Transaction context seams ----------------------------------------------


sub _txn_context_class { 'DBIO::Async::TransactionContext' }


sub _txn_conn_accessor { 'txn_conn' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Storage::Async - future_io async PostgreSQL transport over DBD::Pg's pg_async binding

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

The concrete C<future_io> transport adapter for PostgreSQL (core ADR 0030 /
0031). It is resolved B<by convention> off the sync driver storage: a
connection opened with

  MyApp::Schema->connect($dsn, $user, $pass, { async => 'future_io' });

on a L<DBIO::PostgreSQL::Storage> instance derives C<ref($storage) . '::Async'>
== C<DBIO::PostgreSQL::Storage::Async>. No C<register_async_mode> call is
needed; the name itself is the registration.

=head2 Storage extensions ride on top by composition

Under the storage-layer composition model (core karr #70), a PostgreSQL
extension (AGE, PostGIS, ...) is B<not> a C<storage_type> subclass and does
B<not> ship a shadow C<register_async_mode> / C<< ::Storage::Async >> of its
own. It ships a plain storage B<layer> registered with
C<< $schema->register_storage_layer('DBIO::PostgreSQL::Ext::Storage') >> and,
for async behaviour, a sibling async mirror
C<DBIO::PostgreSQL::Ext::Storage::Async> (a plain method package, B<not> a
transport). When a layered schema connects C<< { async => 'future_io' } >>,
core resolves this transport by convention off the B<composition base> (the
driver, not the layers -- see L<DBIO::Storage::DBI/_async_resolution_class>) and
then C<< DBIO::Storage::Composed->compose >>s each registered layer's async
mirror B<on top of> it. So this class stays the single per-driver future_io
transport BASE; extensions add behaviour above it via C3, exactly as their sync
layers ride the sync driver storage.

The Model-B orchestration -- the CRUD runner (L<DBIO::Storage::Async/_run_crud>
with its pooled / pinned runners), INSERT returned-columns mapping,
L<DBIO::Storage::Async/txn_do_async> bracketing, the pipeline scaffold, and the
sync C<< ->get >> fallbacks -- is inherited unchanged from
L<DBIO::Storage::Async>. The L<Future::IO> transport (query execution over the
socket-readable watcher, the L<Future> class and the L<DBIO::Async::Pool>) is
inherited from L<DBIO::Async::Storage>. This class fills B<only> the
DB-specific transport seams over L<DBD::Pg>'s own asynchronous binding
(C<< {pg_async => PG_ASYNC} >> + C<pg_ready> / C<pg_result> / C<pg_socket>):

=over 4

=item * L</sql_maker_class> / L</_sql_maker_args> -- the PostgreSQL SQLMaker

=item * L</_transform_sql> -- C<?> to positional C<$N> placeholders

=item * L</_post_insert_sql> -- C< RETURNING *> for the returned-columns hashref

=item * L</_normalize_conninfo> -- DBI-form connect info into the pool's shape

=item * L</_create_pool_connection> / L</_shutdown_pool_connection> -- DBD::Pg
handle lifecycle

=item * L</_conn_ready> / L</_conn_fileno> -- readiness + the C<pg_socket> fd
for the L<Future::IO> watcher

=item * L</_submit_query> / L</_collect_result> -- send non-blocking, then
gather once the wire is readable

=item * L</_txn_context_class> / L</_txn_conn_accessor> -- the pinned-connection
transaction context

=back

A connection is represented as a small hashref C<< { dbh => $dbh, sth => $sth } >>:
the DBD::Pg database handle plus the statement handle of the in-flight async
query (there is at most one per connection at a time, guaranteed by the pool /
transaction pinning).

=head2 Transport capabilities

This transport inherits C<transport_capabilities> from
L<DBIO::Async::Storage>, which advertises exactly C<on_connect_replay> (the
pool replays the owning sync storage's C<on_connect_do> / C<on_connect_call>
on every freshly-spawned connection). It declares B<nothing extra>: the
advanced PostgreSQL wire features are B<not> implemented on the C<future_io>
transport.

C<LISTEN>/C<NOTIFY> (L<DBIO::Storage::Async/listen>),
C<COPY>, and pipelining (L<DBIO::Storage::Async/pipeline>) are B<not> supported
here -- DBD::Pg's async binding exposes no libpq pipeline mode, and the base
seams croak if called. The native C<ev> backend
(L<DBIO::PostgreSQL::EV::Storage>, dist C<dbio-postgresql-ev>) is the transport
that carries C<LISTEN>/C<NOTIFY>, C<COPY> and pipelining. An async storage
layer that declares C<required_transport_capabilities> for any of these will
therefore fail loud (core capability gate) when composed over this C<future_io>
transport, naming the missing capability -- never a silent feature loss.

=head1 METHODS

=head2 sql_maker_class

The L<DBIO::PostgreSQL::SQLMaker> subclass used to generate SQL.

=head2 _sql_maker_args

PostgreSQL SQLMaker construction args: double-quote identifier quoting, C<.>
name separator, LIMIT/OFFSET dialect. Matches the sync driver and the C<ev>
backend.

=head2 _transform_sql

Rewrite C<?> placeholders to PostgreSQL positional C<$N>, skipping quoted
literals / identifiers and the JSONB C<@?> operator.

=head2 _post_insert_sql

Returns C< RETURNING *> so an INSERT yields every populated column (autoinc PK
+ retrieve-on-insert defaults); the inherited runner folds the row onto the
supplied data to build the returned-columns hashref (ADR 0031 §3).

=head2 _normalize_conninfo

  my $info = $storage->_normalize_conninfo([ 'dbi:Pg:...', $user, $pass, \%attrs ]);

Convert the sync storage's DBI-form connect info into the C<[ \%conninfo,
\%opts ]> pair the pool consumes, carrying the DSN / user / password / attrs
straight through for L</_create_pool_connection> to hand to C<< DBI->connect >>.
A C<pool_size> attribute, if present, is lifted into the conninfo hash (the
inherited normaliser strips it back out to size the pool). Broker-style or
already-normalised info is passed through untouched.

=head2 _create_pool_connection

  my $conn = $storage->_create_pool_connection(\%conninfo);

Open one DBD::Pg handle via C<< DBI->connect >> and wrap it as
C<< { dbh => $dbh } >>. C<AutoCommit> is on: the inherited orchestration drives
transactions with explicit C<BEGIN> / C<COMMIT> / C<ROLLBACK> on the pinned
connection, so DBD::Pg's own transaction tracking stays out of the way.

=head2 _shutdown_pool_connection

Disconnect the DBD::Pg handle held by C<$conn>.

=head2 _conn_ready

True once the connection can accept queries. C<< DBI->connect >> is a blocking
connect, so a handed-out connection is ready immediately -- we only confirm the
handle is live.

=head2 _conn_fileno

The connection socket fd for the L<Future::IO> readable watcher, exposed by
DBD::Pg as C<< $dbh->{pg_socket} >>. The transport base
(L<DBIO::Async::Storage/_await_readable>) dups this integer fd into a
filehandle for C<< Future::IO->poll >>.

=head2 _submit_query

  $storage->_submit_query($conn, $sql, $bind);

Send C<$sql> non-blocking via DBD::Pg's async binding: prepare with
C<< {pg_async => PG_ASYNC} >> and execute the bind values. C<execute> returns
immediately; the result is gathered later by L</_collect_result>. The statement
handle is stashed on C<$conn> so the collector can fetch its rows.

C<pg_placeholder_dollaronly> is set so DBD::Pg treats only the C<$N>
placeholders L</_transform_sql> produced as bind parameters, leaving any
literal C<?> (the JSONB C<@?> operator) alone.

=head2 _collect_result

  my $future = $storage->_collect_result($conn, $sql, $bind);

Called once the socket is readable. If the async result has not fully arrived
(C<< $dbh->pg_ready >> is false) it waits for the socket again and re-checks --
so a large result spanning several reads is handled correctly. Once ready it
finalises with C<< $dbh->pg_result >> and resolves:

=over 4

=item * a query that produced a result set (SELECT, or INSERT/UPDATE/DELETE
C<... RETURNING>) -> the list of raw row arrayrefs, exactly the shape the sync
cursor's C<< ->all >> yields (ADR 0031 §3);

=item * a statement with no result set (plain UPDATE/DELETE, BEGIN/COMMIT/...)
-> the affected-row count from C<pg_result>.

=back

The full list is carried in an explicit C<< future_class->done(@rows) >> so it
survives the surrounding C<< ->then >> chain (a bare list return would collapse
to its last element).

=head2 _txn_context_class

The pinned-connection transaction context handed to a C<txn_do_async> coderef:
the C<future_io> L<DBIO::Async::TransactionContext>.

=head2 _txn_conn_accessor

The constructor key the pinned connection is passed under -- C<txn_conn>,
matching L<DBIO::Storage::Async::TransactionContext>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
