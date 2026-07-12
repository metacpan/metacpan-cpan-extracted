package DBIO::MySQL::Storage::Async;
# ABSTRACT: future_io async MySQL transport over the DBD driver's native async binding

use strict;
use warnings;
use base 'DBIO::Async::Storage';

use Carp 'croak';
use Scalar::Util ();
use DBI;
use Future::IO;
use DBIO::MySQL::SQLMaker;
use namespace::clean;


# --- SQL shaping seams ------------------------------------------------------


sub sql_maker_class { 'DBIO::MySQL::SQLMaker' }


sub _sql_maker_args {
  return (
    quote_char => '`',
    name_sep   => '.',
  );
}


sub _transform_sql { $_[1] }


sub _post_insert_sql { '' }

# --- INSERT returned-columns (last_insert_id, no RETURNING) ------------------


sub _insert_returned_columns {
  my ($self, $source, $to_insert, $affected) = @_;

  my %returned = %{ $to_insert || {} };

  my $id = $self->{_last_insert_id};
  return \%returned unless defined $id && $id;

  my $col = $self->_auto_increment_column($source, $to_insert);
  return \%returned unless defined $col;

  $returned{$col} = $id;
  return \%returned;
}

# Find the column the auto-increment id belongs in, matching the sync
# DBIO::Storage::DBI heuristic:
#   - the first column flagged is_auto_increment, OR
#   - the first PK column that was not supplied in $to_insert (no
#     is_auto_increment flag on the schema, but MySQL still hands back an id
#     because the PK is auto_increment server-side).
# Returns undef when neither applies (e.g. a table with no PK), leaving the
# hashref as the supplied insert data only.
sub _auto_increment_column {
  my ($self, $source, $to_insert) = @_;
  return unless Scalar::Util::blessed($source) && $source->can('columns');

  my $col_infos = eval { $source->columns_info } || {};
  my @pks = $source->can('primary_columns') ? $source->primary_columns : ();
  my %is_pk = map { $_ => 1 } @pks;

  my $first_autoinc;
  my $first_pk_unsupplied;
  for my $col ($source->columns) {
    if (!defined $first_autoinc
          && ($col_infos->{$col}{is_auto_increment} // 0)) {
      $first_autoinc = $col;
    }
    if ($is_pk{$col}
          && !defined $first_pk_unsupplied
          && !exists $to_insert->{$col}) {
      $first_pk_unsupplied = $col;
    }
  }

  return $first_autoinc if defined $first_autoinc;
  return $first_pk_unsupplied;
}


sub last_insert_id { $_[0]->{_last_insert_id} }

# --- Connect-info seam ------------------------------------------------------


sub _normalize_conninfo {
  my ($self, $info) = @_;

  # DBI-form: [ 'dbi:mysql:...', $user, $pass, \%attrs ] -> our conninfo shape.
  if (ref $info eq 'ARRAY'
      && defined $info->[0] && !ref $info->[0] && $info->[0] =~ /^dbi:/i) {
    my ($dsn, $user, $pass, $attrs) = @$info;
    $attrs = {} unless ref $attrs eq 'HASH';
    my %dbd_attrs = %$attrs;
    # DBIO-private connect attributes (async, ignore_version, SQLMaker options) are
    # already stripped centrally by core DBIO::Storage::Async::connect_info before
    # this seam runs (core #66), so they never reach %dbd_attrs here.
    my %conninfo = (
      dsn      => $dsn,
      user     => $user,
      password => $pass,
      attrs    => \%dbd_attrs,
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

  croak 'MySQL async conninfo must be a hashref with a dsn'
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
  ) or croak "DBI connect failed: $DBI::errstr";

  return { dbh => $dbh };
}


sub _shutdown_pool_connection {
  my ($self, $conn) = @_;
  my $dbh = $conn->{dbh} or return;
  $dbh->disconnect if $dbh->{Active};
}

# --- DBD-specific async primitives ------------------------------------------
# These five one-liners are the ONLY places the DBD driver's async binding is
# named. This class carries the DBD::mysql binding; the convention subclass
# DBIO::MySQL::Storage::MariaDB::Async overrides them with DBD::MariaDB's
# mariadb_* equivalents. Everything else in the transport (submit / collect
# control flow, pooling, txn) is DBD-agnostic and shared.


sub _async_prepare_attrs { { async => 1 } }


sub _conn_socket_fd { $_[1]->mysql_fd }


sub _async_ready { $_[1]->mysql_async_ready }


sub _async_result { $_[1]->mysql_async_result }


sub _async_insertid { $_[1]->{mysql_insertid} }

# --- Readiness / socket seams -----------------------------------------------


sub _conn_ready {
  my ($self, $conn) = @_;
  return $conn->{dbh} && $conn->{dbh}{Active} ? 1 : 0;
}


sub _conn_fileno {
  my ($self, $conn) = @_;
  return $self->_conn_socket_fd($conn->{dbh});
}

# --- Query submit / collect -------------------------------------------------


sub _submit_query {
  my ($self, $conn, $sql, $bind) = @_;
  $bind //= [];

  my $dbh = $conn->{dbh};

  delete $conn->{sth};

  my $sth = $dbh->prepare($sql, $self->_async_prepare_attrs);
  $sth->execute(@$bind);
  $conn->{sth} = $sth;

  return;
}


sub _collect_result {
  my ($self, $conn, $sql, $bind) = @_;

  my $sth = $conn->{sth};

  # The result may not have fully arrived on the first readable event.
  # _async_ready reports whether _async_result will not block; if not, wait for
  # more and re-check rather than blocking.
  unless ($self->_async_ready($sth)) {
    return $self->_await_readable($conn)->then(sub {
      return $self->_collect_result($conn, $sql, $bind);
    });
  }

  my $rv = $self->_async_result($sth);   # finalise; dies (RaiseError) on error

  # Capture the auto-increment id for insert_async's returned-columns hashref
  # (MySQL has no RETURNING). The insertid is per-sth and 0 for non-INSERTs, so
  # guarding on truthiness keeps a following statement from clobbering it.
  if (my $iid = $self->_async_insertid($sth)) {
    $self->{_last_insert_id} = $iid;
  }

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

DBIO::MySQL::Storage::Async - future_io async MySQL transport over the DBD driver's native async binding

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

The concrete C<future_io> transport adapter for MySQL / MariaDB (core ADR 0030 /
0031), the MySQL analogue of L<DBIO::PostgreSQL::Storage::Async>. It is resolved
B<by convention> off the sync driver storage: a connection opened with

  MyApp::Schema->connect($dsn, $user, $pass, { async => 'future_io' });

on a L<DBIO::MySQL::Storage> instance derives C<ref($storage) . '::Async'> ==
C<DBIO::MySQL::Storage::Async>. No C<register_async_mode> call is needed; the
name itself is the registration.

=head2 Storage extensions ride on top by composition

Under the storage-layer composition model (core karr #70), a MySQL / MariaDB
driver extension is B<not> a C<storage_type> subclass and does B<not> ship a
shadow C<register_async_mode> / C<< ::Storage::Async >> of its own. It ships a
plain storage B<layer> registered with
C<< $schema->register_storage_layer('DBIO::MySQL::Ext::Storage') >> and, for
async behaviour, a sibling async mirror C<DBIO::MySQL::Ext::Storage::Async> (a
plain method package, B<not> a transport). When a layered schema connects
C<< { async => 'future_io' } >>, core resolves this transport by convention off
the B<composition base> (the driver, not the layers) and then
C<< DBIO::Storage::Composed->compose >>s each registered layer's async mirror
B<on top of> it. So this class stays the single per-driver future_io transport
BASE; extensions add behaviour above it via C3, exactly as their sync layers
ride the sync driver storage. MySQL ships no such extension today, but this
reference driver honours the mechanism (the offline structural proof is
F<t/56-storage-layer-composition.t>, the live one F<t/57-*-live.t>).

=head2 One dist, two DBD drivers

MySQL is served by two DBI drivers, and DBIO models them as two storage classes:
L<DBIO::MySQL::Storage> for a C<dbi:mysql:> DSN (L<DBD::mysql>) and
L<DBIO::MySQL::Storage::MariaDB> for a C<dbi:MariaDB:> DSN (L<DBD::MariaDB>). The
user picks the DBD by the DSN, so the async transport must drive I<that> DBD's
binding, not a fixed one -- the two are really two drivers that happen to ship
in one dist.

Both bindings share the same shape -- a single async query per connection plus a
socket fd for the event loop -- but differ only in the attribute / method names:

  DBD::mysql      async         mysql_fd       mysql_async_ready
                  mysql_async_result           mysql_insertid
  DBD::MariaDB    mariadb_async mariadb_sockfd mariadb_async_ready
                  mariadb_async_result         mariadb_insertid

This class carries the B<DBD::mysql> binding and all the shared transport control
flow. Its convention subclass L<DBIO::MySQL::Storage::MariaDB::Async> (resolved
for a C<dbi:MariaDB:> connection) overrides B<only> the five DBD-specific
primitives below with their C<mariadb_*> equivalents. So whichever DBD the sync
connection used, the matching async binding is driven -- mirroring the sync
split, where L<DBIO::MySQL::Storage::MariaDB> reads C<mariadb_insertid> where
L<DBIO::MySQL::Storage> reads C<mysql_insertid>. Neither DBD is loaded at compile
time here; C<< DBI->connect >> pulls the one the DSN names.

The Model-B orchestration -- the CRUD runner (L<DBIO::Storage::Async/_run_crud>
with its pooled / pinned runners), INSERT returned-columns mapping,
L<DBIO::Storage::Async/txn_do_async> bracketing, the pipeline scaffold, and the
sync C<< ->get >> fallbacks -- is inherited unchanged from
L<DBIO::Storage::Async>. The L<Future::IO> transport (query execution over the
socket-readable watcher, the L<Future> class and the L<DBIO::Async::Pool>) is
inherited from L<DBIO::Async::Storage>. This class fills B<only> the DB-specific
transport seams over the driver's asynchronous binding:

=over 4

=item * L</sql_maker_class> / L</_sql_maker_args> -- the MySQL SQLMaker

=item * L</_transform_sql> -- identity (MySQL keeps C<?> placeholders)

=item * L</_post_insert_sql> -- empty (MySQL has no C<RETURNING>)

=item * L</_insert_returned_columns> -- assemble the returned-columns hashref
from the auto-increment id (there is no C<RETURNING>), the key divergence from
PostgreSQL

=item * L</_normalize_conninfo> -- DBI-form connect info into the pool's shape

=item * L</_create_pool_connection> / L</_shutdown_pool_connection> -- DBD handle
lifecycle

=item * L</_conn_ready> / L</_conn_fileno> -- readiness + the socket fd for the
L<Future::IO> watcher

=item * L</_submit_query> / L</_collect_result> -- send non-blocking, then gather
once the wire is readable

=item * L</_async_prepare_attrs> / L</_conn_socket_fd> / L</_async_ready> /
L</_async_result> / L</_async_insertid> -- the five DBD-specific async primitives
the seams above call, overridden in the MariaDB subclass

=item * L</_txn_context_class> / L</_txn_conn_accessor> -- the pinned-connection
transaction context

=back

A connection is represented as a small hashref C<< { dbh => $dbh, sth => $sth } >>:
the driver's database handle plus the statement handle of the in-flight async
query (there is at most one per connection at a time -- MySQL allows a single
async query per connection -- guaranteed by the pool / transaction pinning).

=head2 Transport capabilities

This transport inherits C<transport_capabilities> from
L<DBIO::Async::Storage>, which advertises exactly C<on_connect_replay> (the pool
replays the owning sync storage's C<on_connect_do> / C<on_connect_call> on every
freshly-spawned connection, core karr #68). It declares B<nothing extra>.

MySQL and MariaDB have no C<LISTEN>/C<NOTIFY> and no C<COPY> (those are
PostgreSQL wire features), so unlike the PostgreSQL transport there is nothing
of that kind to carry here. Pipelining
(L<DBIO::Storage::Async/pipeline>) is B<not> implemented on this C<future_io>
transport either -- neither DBD driver's async binding exposes a batch/pipeline
mode -- so the inherited scaffold croaks if C<pipeline> is called. The native
C<ev> backend (L<DBIO::MySQL::EV::Storage>, dist C<dbio-mysql-ev>, over
C<EV::MariaDB>) is the transport that carries pipelining. An async storage layer
that declares C<required_transport_capabilities> for a feature this transport
does not advertise will therefore fail loud (core capability gate) when composed
over this C<future_io> transport, naming the missing capability -- never a silent
feature loss.

=head1 METHODS

=head2 sql_maker_class

The L<DBIO::MySQL::SQLMaker> subclass used to generate SQL.

=head2 _sql_maker_args

MySQL SQLMaker construction args: backtick identifier quoting and C<.> name
separator. The MySQL C<LIMIT offset, rows> dialect is built into
L<DBIO::MySQL::SQLMaker/apply_limit>, so no C<limit_dialect> is passed. Matches
the sync driver and the C<ev> backend.

=head2 _transform_sql

Identity: MySQL uses standard C<?> placeholders, so the maker's output is sent to
the DBD driver unchanged (unlike PostgreSQL's C<?E<gt>$N> rewrite).

=head2 _post_insert_sql

Empty string: MySQL has no C<RETURNING> clause, so nothing is appended to an
INSERT. The returned-columns hashref is assembled from the auto-increment id
instead (see L</_insert_returned_columns>).

=head2 _insert_returned_columns

  $hashref = $storage->_insert_returned_columns($source, \%to_insert, $affected);

Assemble the returned-columns hashref (ADR 0031 §3) from the auto-increment id
MySQL generated for the INSERT. MySQL has no C<RETURNING>, so the inherited
runner hands this method the INSERT's affected-row count (C<$affected>, ignored
here); the id itself was captured on C<< $self->{_last_insert_id} >> by
L</_collect_result> from the per-statement insertid (L</_async_insertid>) at the
moment the INSERT finalised. The hashref is C<< { %$to_insert, $col => $id } >>,
where C<$col> is the source's first C<is_auto_increment> column (falling back to
the first PK column whose value was not supplied, matching the sync
L<DBIO::Storage::DBI/insert> heuristic). When no id was generated (an explicit PK
was supplied, or the table has no auto-increment) the supplied data is returned
untouched. Overrides the inherited RETURNING-row default.

Genuinely-concurrent inserts on one storage instance (outside a transaction) are
not supported by this last_insert_id path -- issue them sequentially or inside a
C<txn_do_async>. This mirrors MySQL's own "one async query per connection"
limit; pipelining is not available on this backend.

=head2 last_insert_id

  my $id = $storage->last_insert_id;

The auto-increment value from the last INSERT this storage finalised, captured
from the driver's per-statement insertid (L</_async_insertid>). Valid after an
C<insert_async> / C<insert> succeeds; provided for legacy callers (scripts,
tests). The CRUD path uses L</_insert_returned_columns> instead.

=head2 _normalize_conninfo

  my $info = $storage->_normalize_conninfo([ 'dbi:mysql:...', $user, $pass, \%attrs ]);

Convert the sync storage's DBI-form connect info into the C<[ \%conninfo,
\%opts ]> pair the pool consumes, carrying the DSN / user / password / attrs
straight through for L</_create_pool_connection> to hand to C<< DBI->connect >>.
A C<pool_size> attribute, if present, is lifted into the conninfo hash (the
inherited normaliser strips it back out to size the pool). Broker-style or
already-normalised info is passed through untouched.

=head2 _create_pool_connection

  my $conn = $storage->_create_pool_connection(\%conninfo);

Open one DBD handle via C<< DBI->connect >> and wrap it as C<< { dbh => $dbh } >>.
C<AutoCommit> is on: the inherited orchestration drives transactions with
explicit C<BEGIN> / C<COMMIT> / C<ROLLBACK> on the pinned connection.

=head2 _shutdown_pool_connection

Disconnect the DBD handle held by C<$conn>.

=head2 _async_prepare_attrs

The prepare-time attributes that arm a non-blocking query: C<< { async => 1 } >>
for DBD::mysql. C<execute> then returns immediately.

=head2 _conn_socket_fd

  my $fd = $storage->_conn_socket_fd($dbh);

The connection socket file descriptor for the L<Future::IO> readable watcher --
C<< $dbh->mysql_fd >> for DBD::mysql (the MySQL analogue of DBD::Pg's
C<pg_socket>).

=head2 _async_ready

  my $bool = $storage->_async_ready($sth);

True once L</_async_result> will not block -- DBD::mysql C<mysql_async_ready>.

=head2 _async_result

  my $rv = $storage->_async_result($sth);

Finalise the in-flight async statement and return what C<execute> would have --
the affected-row count (DBD::mysql C<mysql_async_result>). Dies (RaiseError) on a
server-side error.

=head2 _async_insertid

  my $id = $storage->_async_insertid($sth);

The per-statement C<AUTO_INCREMENT> id generated by the finalised INSERT, read
from C<< $sth->{mysql_insertid} >> -- the per-sth form DBD::mysql recommends over
the shared-handle C<< $dbh->{mysql_insertid} >>. Zero / undef for non-INSERTs.

=head2 _conn_ready

True once the connection can accept queries. C<< DBI->connect >> is a blocking
connect, so a handed-out connection is ready immediately -- we only confirm the
handle is live.

=head2 _conn_fileno

The connection socket fd for the L<Future::IO> readable watcher, obtained from
the DBD-specific L</_conn_socket_fd> primitive. The transport base
(L<DBIO::Async::Storage/_await_readable>) dups this integer fd into a filehandle
for C<< Future::IO->poll >>.

=head2 _submit_query

  $storage->_submit_query($conn, $sql, $bind);

Send C<$sql> non-blocking via the DBD driver's async binding: prepare with
L</_async_prepare_attrs> and execute the bind values. C<execute> returns
immediately; the result is gathered later by L</_collect_result>. The statement
handle is stashed on C<$conn> so the collector can finalise and fetch it.

The previous (already-collected) async statement handle is released B<before>
starting the new async query. MySQL allows a single async query per connection;
clearing the spent sth first means the new execute owns the connection's async
slot uncontested (mirrors the DBD::Pg adapter's fix).

=head2 _collect_result

  my $future = $storage->_collect_result($conn, $sql, $bind);

Called once the socket is readable. If the async result has not fully arrived
(L</_async_ready> is false) it waits for the socket again and re-checks -- so a
large result spanning several reads is handled correctly. Once ready it finalises
with L</_async_result> and resolves:

=over 4

=item * a query that produced a result set (SELECT) -> the list of raw row
arrayrefs, exactly the shape the sync cursor's C<< ->all >> yields (ADR 0031 §3);

=item * a statement with no result set (INSERT / UPDATE / DELETE, BEGIN /
COMMIT / ...) -> the affected-row count from L</_async_result>.

=back

For an INSERT it also captures the per-statement insertid (L</_async_insertid>)
onto C<< $self->{_last_insert_id} >> so L</_insert_returned_columns> can fold the
auto-increment id into the returned-columns hashref (MySQL has no C<RETURNING>).
The id is captured only when non-zero, so a following non-INSERT statement does
not clobber a pending insert's id.

The full row list is carried in an explicit C<< future_class->done(@rows) >> so
it survives the surrounding C<< ->then >> chain (a bare list return would
collapse to its last element).

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
