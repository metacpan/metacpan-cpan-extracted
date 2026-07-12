package DBIO::MySQL::EV::Storage;
# ABSTRACT: Async MySQL/MariaDB storage driver using EV::MariaDB

use strict;
use warnings;
use base 'DBIO::Storage::Async';

use Carp 'croak';
use Scalar::Util ();
use Future;
use DBIO::MySQL::SQLMaker;
use DBIO::MySQL::EV::ConnectInfo ();
use DBIO::MySQL::EV::Pool;
use DBIO::MySQL::EV::QueryExecutor;
use DBIO::MySQL::EV::TransactionContext;
use namespace::clean;


# --- SQLMaker seams -----------------------------------------------------------
# The inherited DBIO::Storage::Async::sql_maker builds the maker from these.


sub sql_maker_class { 'DBIO::MySQL::SQLMaker' }


sub _sql_maker_args {
  return (
    quote_char => '`',
    name_sep   => '.',
  );
}


sub _post_insert_sql { '' }


sub future_class { 'Future' }


sub transport_capabilities { qw(on_connect_replay) }


sub connect_info {
  my ($self, $info) = @_;
  if ($info) {
    # Embedded path: the sync storage feeds its own DBI-form connect_info
    # (['dbi:MariaDB:...', $user, $pass, \%attrs]). Translate it into the async
    # [ \%conninfo, \%opts ] shape before the normal broker/normalize logic, so
    # EV::MariaDB gets named params instead of a DSN string it cannot parse.
    if (ref $info eq 'ARRAY' && defined $info->[0] && !ref $info->[0] && $info->[0] =~ /^dbi:/i) {
      $info = DBIO::MySQL::EV::ConnectInfo::dbi_to_conninfo($info);
    }
    $self->disconnect if $self->{pool};
    $self->{connect_info} = $info;

    if ($self->_is_access_broker_connect_info($info)) {
      $self->_setup_access_broker($info->[0]);
      my ($conninfo, $pool_size, $opts) = $self->_normalize_async_connect_info(
        $self->_current_async_connect_info($self->access_broker_mode)
      );
      $self->{_conninfo}  = $conninfo;
      $self->{_pool_size} = $pool_size;
      $self->{_opts}      = $opts;
    }
    else {
      $self->_clear_access_broker;
      my ($conninfo, $pool_size, $opts) = $self->_normalize_async_connect_info($info);
      $self->{_conninfo}  = $conninfo;
      $self->{_pool_size} = $pool_size;
      $self->{_opts}      = $opts;
    }
  }
  return $self->{connect_info};
}


sub _async_broker_conninfo {
  my ($self, $mode) = @_;

  my ($conninfo) = $self->_normalize_async_connect_info(
    $self->_current_async_connect_info($mode)
  );
  return $conninfo;
}


sub _normalize_async_connect_info {
  my ($self, $info) = @_;

  my $conninfo = $info->[0];
  $conninfo = ref($conninfo) eq 'HASH' ? { %$conninfo } : $conninfo;

  my $opts = $info->[1];
  $opts = ref($opts) eq 'HASH' ? { %$opts } : {};

  my $pool_size = 5;
  if (ref($conninfo) eq 'HASH') {
    $pool_size = delete $conninfo->{pool_size} // 5;
    # MySQL uses 'database', not 'dbname'
    $conninfo->{database} = delete $conninfo->{dbname} if exists $conninfo->{dbname};
  }

  return ($conninfo, $pool_size, $opts);
}


sub _conninfo_hash {
  my ($self, $ci) = @_;
  my $conninfo = defined($ci) ? $ci : $self->{_conninfo};
  return unless defined $conninfo;
  return $conninfo if ref $conninfo ne 'HASH';
  return $conninfo;
}


sub pool {
  my $self = shift;
  $self->{pool} ||= do {
    my %args = (
      storage  => $self,
      size     => $self->{_pool_size},
      on_error => sub { warn "DBIO::MySQL::EV pool error: $_[0]\n" },
    );

    if (my $provider = $self->_conninfo_provider) {
      $args{conninfo_provider} = $provider;
    }
    else {
      $args{conninfo} = $self->{_conninfo};
    }

    DBIO::MySQL::EV::Pool->new(%args);
  };
}

# Lazily-built query executor bound to the pool. The executor is the MySQL wire
# seam: it hides EV::MariaDB's query-vs-prepare/execute split (query() takes no
# binds) and the async bind-clearing contract (karr #11). Held on the storage so
# a caller that pre-wires { pool, executor } (the offline facade tests) keeps its
# own instance.
sub _executor {
  my $self = shift;
  return $self->{executor} ||= DBIO::MySQL::EV::QueryExecutor->new(
    pool  => $self->{pool},
    debug => $self->{debug},
  );
}

# --- Transaction context seams ------------------------------------------------


sub _txn_context_class { 'DBIO::MySQL::EV::TransactionContext' }


sub _txn_conn_accessor { 'mdb' }

# --- SQL shaping seam ---------------------------------------------------------


sub _transform_sql { $_[1] }

# --- Async query execution (transport seams) ----------------------------------


sub _query_async {
  my ($self, $sql, $bind) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  return $self->pool->acquire->then(sub {
    my $conn = shift;
    my $f = $self->_executor->execute($conn, $sql, $bind);
    $f->on_ready(sub { $self->pool->release($conn) });
    return $f;
  });
}


sub _query_async_pinned {
  my ($self, $conn, $sql, $bind) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);
  return $self->_executor->execute($conn, $sql, $bind);
}

# --- INSERT: LAST_INSERT_ID instead of RETURNING (MySQL value-add) ------------


sub insert_async {
  my ($self, @args) = @_;

  # INSERT + LAST_INSERT_ID() must ride the SAME session, so pin the whole
  # insert on one acquired connection and release it once the Future settles.
  return $self->pool->acquire->then(sub {
    my $conn = shift;
    my $f = $self->_run_crud_pinned('insert', $conn, @args);
    $f->on_ready(sub { $self->pool->release($conn) });
    return $f;
  });
}


sub _run_crud_pinned {
  my ($self, $op, $conn, @args) = @_;
  return $self->SUPER::_run_crud_pinned($op, $conn, @args) unless $op eq 'insert';

  # The CRUD contract is insert_async($source, \%rowdata) (ADR 0031 §3).
  # SQLMaker wants a plain table name, so unwrap a blessed source to its
  # ->name; a bare string passes through.
  my ($source, @rest) = @args;
  my $to_insert = $rest[0];
  my $table = (Scalar::Util::blessed($source) && $source->can('name'))
    ? $source->name
    : $source;

  my ($sql, @bind) = $self->sql_maker->insert($table, @rest);

  # LAST_INSERT_ID() must run on the SAME connection as the INSERT, otherwise
  # the session-scope LII is undefined / from a prior session. Both run pinned
  # on $conn, so the SELECT never hits a foreign session's LII.
  return $self->_query_async_pinned($conn, $sql, \@bind)->then(sub {
    return $self->_query_async_pinned($conn, 'SELECT LAST_INSERT_ID()', []);
  })->then(sub {
    my $lii_row = shift;
    my $lii_id  = (ref $lii_row eq 'ARRAY' && @$lii_row) ? $lii_row->[0] : undef;
    # Capture for legacy ->last_insert_id callers (e.g. scripts, tests).
    $self->{_last_insert_id} = $lii_id if defined $lii_id;
    return $self->_insert_returned_columns($source, $to_insert, $lii_row);
  });
}


sub _insert_returned_columns {
  my ($self, $source, $to_insert, $lii_row) = @_;

  my %returned = %{ $to_insert || {} };
  return \%returned unless defined $lii_row && ref $lii_row eq 'ARRAY' && @$lii_row;
  my $lii_id = $lii_row->[0];
  return \%returned unless defined $lii_id;

  my $col = $self->_auto_increment_column($source, $to_insert);
  return \%returned unless defined $col;
  $returned{$col} = $lii_id;

  return \%returned;
}

# Find the column a $storage->insert should drop the LAST_INSERT_ID() value
# into, matching the sync DBIO::Storage::DBI heuristic:
#   - the first column with is_auto_increment, OR
#   - the first PK column that wasn't supplied in $to_insert (no
#     is_auto_increment flag on the schema, MySQL still hands back an
#     LII because the PK is auto_increment server-side).
# Returns undef when neither applies (e.g. a table with no PK), in which
# case the hashref is left as the supplied insert data only.
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

# --- Pool connect-action replay seam (karr #68 / #18) -------------------------


sub _run_pool_connect_statement {
  my ($self, $conn, $sql, $attrs, @bind) = @_;
  require EV;

  # The connection was just spawned; its async connect may still be in flight.
  # Block the EV loop until it is ready (the core seam's synchronous contract)
  # -- prepare/execute are exclusive ops and need an idle, connected handle.
  EV::run(EV::RUN_ONCE()) until $conn->is_connected;

  $sql = $self->_transform_sql($sql);

  my $done = 0;
  my $err;
  my $cb = sub { (undef, $err) = @_; $done = 1 };

  if (@bind) {
    # EV::MariaDB->query() takes no bind values; a bound connect statement must
    # go through prepare + execute. (Connect actions are almost always bindless
    # SET statements, but honour binds for completeness.)
    $conn->prepare($sql, sub {
      my ($stmt, $perr) = @_;
      if ($perr) { $err = $perr; $done = 1; return }
      $conn->execute($stmt, [@bind], $cb);
    });
  }
  else {
    $conn->query($sql, $cb);
  }
  EV::run(EV::RUN_ONCE()) until $done;

  croak "pool connect statement failed: $err" if defined $err;
  return;
}

# --- Schema integration -------------------------------------------------------
# schema / debug / connected / in_txn / disconnect / DESTROY and the sync
# CRUD/txn ->get fallbacks are inherited from DBIO::Storage::Async.


sub last_insert_id {
  my ($self, $source, @cols) = @_;
  return $self->{_last_insert_id};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV::Storage - Async MySQL/MariaDB storage driver using EV::MariaDB

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

The native C<ev> async transport for MySQL/MariaDB (core ADR 0030 / 0031): a
B<thin transport> over L<EV::MariaDB>, a non-blocking client that speaks the
MariaDB C client library directly. No DBI, no DBD::MySQL, just raw MariaDB
performance.

It resolves as the C<ev> async mode of L<DBIO::MySQL::Storage> (registered
there via C<< register_async_mode( ev => ... ) >>), so a schema connected with
C<< { async => 'ev' } >> answers the six C<*_async> storage methods over
EV::MariaDB while the same schema keeps serving synchronous queries over
DBI/DBD::MySQL.

=head2 Thin transport: shared machinery is inherited

The B<Model-B orchestration> (ADR 0030 §4) is inherited unchanged from
L<DBIO::Storage::Async>: the CRUD runner (L<DBIO::Storage::Async/_run_crud>
with its pooled / pinned runners), L<DBIO::Storage::Async/txn_do_async>
bracketing, the C<sql_maker> plumbing and the sync C<< ->get >> fallbacks. This
class fills B<only> the loop-/wire-specific seams and the genuine MySQL
value-add:

=over 4

=item * L</sql_maker_class> / L</_sql_maker_args> -- the MySQL SQLMaker
(backtick quoting, C<LIMIT offset, rows> pagination)

=item * L</_transform_sql> -- B<identity>. MySQL/DBD speaks C<?> natively, so
there is no placeholder rewrite; the seam is kept only to honour the uniform
core #70 / ADR 0032 C<?>-in contract

=item * L</_query_async> / L</_query_async_pinned> -- native EV::MariaDB query
dispatch (pooled and pinned), routed through L<DBIO::MySQL::EV::QueryExecutor>

=item * L</insert_async> + L</_run_crud_pinned> + L</_insert_returned_columns>
-- MySQL has B<no RETURNING clause>, so INSERT reads C<SELECT LAST_INSERT_ID()>
on the B<same> pinned connection and folds the auto-increment id into the
returned-columns hashref (ADR 0031 §3). This is the one CRUD path core's
generic RETURNING-shaped runner cannot serve, so it is overridden here

=item * L</_run_pool_connect_statement> -- synchronous connect-action replay on
a freshly-spawned EV::MariaDB pool connection (karr #68 / karr #18 seam)

=item * L</connect_info> / L</_normalize_async_connect_info> / L</_conninfo_hash>
-- the EV::MariaDB named-parameter conninfo transport shape (incl.
C<dbname>-E<gt>C<database>)

=item * L</_txn_context_class> / L</_txn_conn_accessor> -- the pinned-connection
transaction context

=back

=head2 Transport value-add

MySQL/MariaDB has B<no> LISTEN/NOTIFY and B<no> COPY, so -- unlike the
PostgreSQL EV transport -- this transport carries no such wire value-add and
declares none. EV::MariaDB pipelines queries B<automatically> at the wire level
(consecutive C<query> calls are batched, up to 64 in flight) with B<no> explicit
pipeline-mode API to bracket; the core C<_pipeline_enter>/C<_pipeline_sync>/
C<_pipeline_exit> seam therefore does not apply and the C<pipeline> capability
is B<not> declared (see L</transport_capabilities>). The only capability this
transport provides is C<on_connect_replay>.

=head1 METHODS

=head2 sql_maker_class

The L<DBIO::MySQL::SQLMaker> subclass used to generate SQL. Shared with the sync
driver, so the maker keeps emitting C<?> placeholders -- which MySQL/DBD
understands natively (L</_transform_sql> is identity).

=head2 _sql_maker_args

MySQL SQLMaker construction args: backtick identifier quoting, C<.> name
separator. (The MySQL C<LIMIT offset, rows> pagination dialect is baked into
L<DBIO::MySQL::SQLMaker> itself.)

=head2 _post_insert_sql

Empty string -- MySQL has B<no> RETURNING clause. The INSERT path
(L</_run_crud_pinned>) reads C<SELECT LAST_INSERT_ID()> on the pinned connection
instead of appending a RETURNING suffix, so core's generic
C<_run_crud> insert branch (which consumes this seam) is never reached for this
transport; the seam is defined only to satisfy the base contract.

=head2 future_class

Returns C<'Future'> -- uses L<Future.pm|Future> from CPAN. Plain L<Future>
C<< ->then >> callbacks auto-wrap a non-Future return value into a resolved
Future (ADR 0031 §4), so ResultSet/Row C<< *_async >> callbacks that return
plain values resolve without an explicit C<< Future->done(...) >> wrap.

=head2 transport_capabilities

  my @caps = DBIO::MySQL::EV::Storage->transport_capabilities;

Class method (see L<DBIO::Storage::Async/transport_capabilities>). Declares the
wire capabilities this transport really provides, so
L<DBIO::Storage::DBI/_async_storage> lets an async extension layer that requires
any of them compose onto it (and croaks naming the gap otherwise, rather than
silently dropping a feature). This transport provides B<only>:

=over 4

=item * C<on_connect_replay> -- its pool (L<DBIO::MySQL::EV::Pool>, a
L<DBIO::Storage::PoolBase>) drives core's
L<DBIO::Storage::Async/_setup_pool_connection> on every freshly-spawned
connection, and L</_run_pool_connect_statement> replays the owning sync
storage's C<on_connect_do>/C<on_connect_call> against it (karr #68 / #18).

=back

It does B<not> declare C<listen>, C<notify> or C<copy> (MySQL has neither
LISTEN/NOTIFY nor COPY), nor C<pipeline> (EV::MariaDB pipelines automatically
at the wire level; there is no explicit pipeline-mode API for the core seam to
bracket).

=head2 connect_info

  $storage->connect_info([ \%conninfo, \%opts ]);

Set connection parameters. C<%conninfo> is passed to L<EV::MariaDB> as named
connection parameters (host, user, password, database, ...). When the embedding
sync storage feeds its own DBI-form connect info
(C<< ['dbi:MariaDB:...', $user, $pass, \%attrs] >>) it is translated into the
async C<< [ \%conninfo, \%opts ] >> shape first (EV::MariaDB cannot parse a DSN
string). AccessBroker connect info (C<< [ $broker ] >>) is detected and wired to
the per-spawn credential provider (the inherited broker seam), exactly as the
sync path does.

This override (rather than the inherited base C<connect_info>) is retained
because the EV transport folds the DBI-form DSN into EV::MariaDB named params
inline via L<DBIO::MySQL::EV::ConnectInfo/dbi_to_conninfo>.

=head2 _async_broker_conninfo

  my $conninfo = $storage->_async_broker_conninfo($mode);

AccessBroker seam (see L<DBIO::Storage::Async/ACCESSBROKER CONSUMPTION>): return
one fresh, storage-native EV::MariaDB conninfo hash for a single new pool
connection, built from the current broker credentials via the inherited
normalisation.

=head2 _normalize_async_connect_info

  my ($conninfo, $pool_size, $opts) = $storage->_normalize_async_connect_info($info);

MySQL-specific override of the base normaliser: besides stripping C<pool_size>
out of the conninfo, it maps C<dbname> to C<database> (EV::MariaDB's spelling)
so a hash-form connect that used the DBI-style C<dbname> key still reaches the
native client correctly. Works on copies so the caller's structures are never
mutated.

=head2 _conninfo_hash

  my $conninfo = $storage->_conninfo_hash;

Returns the already-normalised stored EV::MariaDB conninfo hashref (or a passed
override). Normalisation (C<dbname>-E<gt>C<database>, C<pool_size> extraction)
is done once in L</_normalize_async_connect_info>, so this returns it as-is.

=head2 pool

Returns the L<DBIO::MySQL::EV::Pool> connection pool, created lazily on first
access. The pool is wired with C<< storage => $self >> so its core-shared spawn
path (L<DBIO::Storage::PoolBase/_spawn_connection>) replays the owning sync
storage's connect actions on each new connection via
L</_run_pool_connect_statement> (karr #68 / #18). Fed the per-spawn
C<conninfo_provider> when an AccessBroker is attached, otherwise the static
conninfo hash.

=head2 _txn_context_class

The pinned-connection transaction context the inherited
L<DBIO::Storage::Async/txn_do_async> hands to its coderef:
L<DBIO::MySQL::EV::TransactionContext>.

=head2 _txn_conn_accessor

The constructor key the pinned connection is passed under -- C<mdb>, matching
L<DBIO::MySQL::EV::TransactionContext>.

=head2 _transform_sql

Transport-internal SQL shaping (core #70 / ADR 0032). B<Identity> for MySQL:
MySQL/DBD speaks the C<?> placeholder dialect natively, so the C<sql_maker>
output needs no rewrite. The seam is retained (and applied first by
L</_query_async> / L</_query_async_pinned>) purely to keep the transport seam
contract uniform across drivers -- do B<not> reintroduce a dialect rewrite here.

=head2 _query_async

Transport seam. Execute a query on a freshly-acquired pooled connection,
releasing it once the Future is ready. Returns a L<Future> of the raw result
rows (list of column arrayrefs for a result set, or the affected-row count for
plain DML -- ADR 0031 §3), exactly what the inherited C<_run_crud> expects.

Receives SQL in the C<sql_maker> C<?>-placeholder dialect and shapes it via
L</_transform_sql> (identity for MySQL) before it reaches the executor -- the
core #70 / ADR 0032 seam contract.

=head2 _query_async_pinned

Transport seam. Like L</_query_async> but runs on the supplied pinned connection
and does B<not> release it -- used for queries inside a pinned transaction and
for the INSERT + C<LAST_INSERT_ID()> pair (which must ride the same session).
Shapes the incoming C<?>-dialect SQL via L</_transform_sql> exactly as
L</_query_async> does.

=head2 insert_async

  my $future = $storage->insert_async($source, \%vals);

Resolve the returned-columns I<hashref> -- the supplied insert data overlaid
with the auto-increment PK the engine populated (ADR 0031 §3). MySQL has no
RETURNING clause, so the INSERT and a following C<SELECT LAST_INSERT_ID()> must
run on the B<same> session: this override acquires one pooled connection, runs
the whole insert pinned on it via L</_run_crud_pinned>, and releases it when the
Future settles. (The base C<insert_async> uses the pooled runner, which would
acquire a fresh connection per query and read a foreign session's LII.)

=head2 _run_crud_pinned

  my $future = $storage->_run_crud_pinned($op, $conn, @args);

Build SQL and run a CRUD op on a pinned connection (the entry point the
L<DBIO::MySQL::EV::TransactionContext> and L</insert_async> use). For every op
except C<insert> this delegates to the inherited runner. The C<insert> op is the
MySQL value-add: it runs the INSERT and then C<SELECT LAST_INSERT_ID()> on the
B<same> C<$conn> (so the session-scoped LII is the one the INSERT produced),
captures it for legacy L</last_insert_id> callers, and folds it into the
returned-columns hashref via L</_insert_returned_columns>.

=head2 _insert_returned_columns

  $hashref = $storage->_insert_returned_columns($source, \%to_insert, $lii_row);

Assemble the returned-columns hashref from a C<SELECT LAST_INSERT_ID()> row (ADR
0031 §3). MySQL has no RETURNING clause, so the INSERT path captures the LII on
the pinned connection and hands the single-column row to this method. The
hashref is C<< { %$to_insert, $col => $lii_id } >>, where C<$col> is the source's
first C<is_auto_increment> column (falling back to the first PK column whose
value was not supplied, matching the sync L<DBIO::Storage::DBI/insert>
heuristic). Overrides the inherited default that maps a positional RETURNING row
onto a column list.

=head2 _run_pool_connect_statement

  $storage->_run_pool_connect_statement($conn, $sql, $attrs, @bind);

Native-backend override of the core connect-action runner seam
(L<DBIO::Storage::Async/_run_pool_connect_statement>). The base default drives a
blocking DBI C<do> and croaks on a non-DBI connection; an EV::MariaDB handle is
neither a C<< { dbh => $dbh } >> wrapper nor a do-capable DBI handle, so this
override drives the statement B<synchronously to completion> on that connection
over the EV loop.

Called once per freshly-spawned pool connection from
L<DBIO::Storage::Async/_setup_pool_connection>, so the owning sync storage's
C<on_connect_do> / C<on_connect_call> replay on every new EV pool connection,
identical to the DBD-based pools (karr #68 / #18). The freshly-spawned
EV::MariaDB handle connects asynchronously, so we first drive the loop until it
is up, then run the statement and drive the loop until it completes. Bindless
statements (the usual C<SET ...> connect actions) go on the queueable C<query>
path; a bound statement is routed through C<prepare> + C<execute>. C<$attrs>
(the DBI attribute hashref) has no EV::MariaDB analogue and is ignored.

=head2 last_insert_id

  my $id = $storage->last_insert_id;

Returns the auto-increment value from the last INSERT performed on this storage
instance (captured from C<SELECT LAST_INSERT_ID()> by L</_run_crud_pinned>).
Valid after L<insert_async|/insert_async> or the sync C<insert> succeeds.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
