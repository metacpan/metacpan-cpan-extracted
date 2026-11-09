package DBIO::MySQL::Storage::Async;
# ABSTRACT: future_io async MySQL transport over the DBD driver's native async binding

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Async::Storage';

use Carp 'croak';
use Scalar::Util ();
use DBI;
use Future::IO;
use DBIO::Util ();
use DBIO::MySQL::SQLMaker;
use DBIO::MySQL::Storage ();
use DBIO::MySQL::Storage::Async::Binary ();
use DBIO::MySQL::MariaDBForkGuard ();
use DBIO::MySQL::DDL ();
use DBIO::MySQL::Util ();
use DBIO::MySQL::Identifier ();
use DBIO::MySQL::NotifyTable;
use namespace::clean;


# --- Transport capabilities -------------------------------------------------


sub transport_capabilities {
  my $self = shift;
  return ($self->next::method(@_), qw(listen notify broker_connect_options));
}

# --- LISTEN / NOTIFY configuration ------------------------------------------


__PACKAGE__->mk_group_accessors(inherited => qw(
  notify_table notify_poll_interval notify_lookback notify_retention
));
{
  my %defaults = DBIO::MySQL::NotifyTable->defaults;
  __PACKAGE__->notify_table($defaults{table});
  __PACKAGE__->notify_poll_interval($defaults{poll_interval});
  __PACKAGE__->notify_lookback($defaults{lookback});
  __PACKAGE__->notify_retention($defaults{retention});
}

# --- SQL shaping seams ------------------------------------------------------


sub sql_maker_class { 'DBIO::MySQL::SQLMaker' }


sub _sql_maker_args {
  return (
    quote_char => '`',
    name_sep   => '.',
  );
}


sub _run_crud {
  my ($self, $op, $runner, @args) = @_;

  my $ident = $args[0];
  my $typed = sub {
    my ($sql, $bind) = @_;
    return $runner->($sql, $self->_binary_binds($ident, $bind));
  };

  # Only while the statement is built: the continuations the builder returns
  # do not touch the maker.
  local $self->{sql_maker} = $self->{_typed_sql_maker} ||=
    $self->sql_maker_class->new($self->_sql_maker_args, bindtype => 'columns');
  return $self->SUPER::_run_crud($op, $typed, @args);
}

# [ $column => $value ] pairs of the typed maker become the value, wrapped when
# the column is binary; anything else core already took apart stays as it is.
sub _binary_binds {
  my ($self, $ident, $bind) = @_;

  my $owner = $self->can('_effective_owner_storage')
    ? $self->_effective_owner_storage
    : $self->_owner_storage;
  my $colinfos;
  my @out;
  for my $b (@$bind) {
    if (ref $b eq 'ARRAY' && @$b == 2 && defined $b->[0] && !ref $b->[0]) {
      my ($col, $value) = @$b;
      my $type;
      if (defined $value && !ref $value && $owner && ref $ident) {
        $colinfos ||= $owner->_resolve_column_info($ident);
        $type = $colinfos->{$col}{data_type};
      }
      push @out, (defined $type && DBIO::MySQL::Storage->bind_attribute_by_data_type($type))
        ? DBIO::MySQL::Storage::Async::Binary->new($value)
        : $value;
    }
    else {
      push @out, $b;
    }
  }
  return \@out;
}


sub _transform_sql { $_[1] }


sub _post_insert_sql { '' }

# --- INSERT returned-columns (last_insert_id, no RETURNING) ------------------


sub _insert_returned_columns {
  my ($self, $source, $to_insert, $affected) = @_;

  my %returned = %{ $to_insert || {} };

  my $id = $self->{_statement_insert_id};
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

  # DBI-form: [ 'dbi:mysql:...', $user, $pass, \%attrs, \%extra ] -> our
  # conninfo shape. Both attribute hashes, the later winning, as
  # DBIO::Storage::DBI::_normalize_connect_info merges them (karr k64): read
  # from slot [3] alone, what the caller put in the fifth element reached the
  # owner's connection and no pooled one.
  if (ref $info eq 'ARRAY'
      && defined $info->[0] && !ref $info->[0] && $info->[0] =~ /^dbi:/i) {
    my ($dsn, $user, $pass) = @$info;
    my %dbd_attrs = map { %$_ } grep { ref $_ eq 'HASH' } @{$info}[3, 4];
    # DBIO-private connect attributes (async, ignore_version, SQLMaker options) are
    # already stripped centrally by core DBIO::Storage::Async::connect_info before
    # this seam runs (core #66), from both hashes, so they never reach
    # %dbd_attrs here.
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

  # Single-hash form (DBIx::Class heritage): [ { dsn, user, password, <DBD
  # attributes>, pool_size } ], no second element. Every key but those is a
  # DBD attribute, as the owning sync storage reads it (karr k66). The
  # transport's own shape always has a second element ([ \%conninfo, \%opts ],
  # a broker answer is wrapped that way), so a lone hash is the caller's.
  if (ref $info eq 'ARRAY' && @$info == 1
      && ref $info->[0] eq 'HASH' && !Scalar::Util::blessed($info->[0])
      && defined $info->[0]{dsn} && !exists $info->[0]{dbh_maker}) {
    my %conninfo = %{ $info->[0] };
    my %dbd_attrs = ( %{ delete $conninfo{attrs} || {} } );
    my %flat;
    for my $key (grep { !/^(?:dsn|user|password|pool_size)$/ } keys %conninfo) {
      $flat{$key} = delete $conninfo{$key};
    }
    $conninfo{attrs} = { %flat, %dbd_attrs };
    return [ \%conninfo, {} ];
  }

  # Broker arrayref [ $broker ], or an already-normalised [ \%conninfo, \%opts ]
  # pair -- leave for the inherited broker detection / normalisation.
  return $info;
}

# --- Pool connection lifecycle ----------------------------------------------


sub _create_pool_connection {
  my ($self, $conninfo) = @_;
  return $self->_mysql_connect($conninfo);
}

# The one DBI->connect of this transport: a pool connection
# (_create_pool_connection) and the dedicated listen connection (_listen_open,
# which passes $force_no_reconnect). The forced attributes win over the
# caller's.
#
# The auto-reconnect attribute is named here and nowhere earlier, for the DBD
# of the DSN this connection is opened with (karr k60): this is the first point
# where that DSN is known -- with an AccessBroker it is the broker's answer for
# this one connection. Off unless the connect attributes set it under that
# DBD's name; off regardless when forced.
sub _mysql_connect {
  my ($self, $conninfo, $force_no_reconnect) = @_;

  croak 'MySQL async conninfo must be a hashref with a dsn'
    unless ref $conninfo eq 'HASH' && defined $conninfo->{dsn};

  my %attrs     = %{ $conninfo->{attrs} || {} };
  my $reconnect = $self->_mysql_auto_reconnect_attr($conninfo->{dsn});
  $attrs{$reconnect} = 0 if $force_no_reconnect || !exists $attrs{$reconnect};

  my @info = (
    $conninfo->{dsn},
    $conninfo->{user},
    $conninfo->{password},
    {
      %attrs,
      AutoCommit          => 1,
      RaiseError          => 1,
      PrintError          => 0,
      AutoInactiveDestroy => 1,
    },
  );

  # Never the password in what a failed connect says (karr k76, core k297).
  # Under RaiseError DBI dies itself, quoting the DSN it was given, which may
  # carry password=...; DBI's message goes on as it came, its location
  # included, hence die. The croak is left for a connect that answered false:
  # a HandleError among the attributes took the error.
  my ($dbh, $ok, $err);
  {
    local $@;
    $ok  = eval { $dbh = DBI->connect(@info); 1 };
    $err = $@;
  }
  die DBIO::Util::mask_connect_secrets($err, \@info) unless $ok;
  croak DBIO::Util::mask_connect_secrets("DBI connect failed: $DBI::errstr", \@info)
    unless $dbh;

  # The server's version string, kept once while the connection is healthy:
  # _conn_error_is_fatal needs the product for 4031 and must not ask a dead
  # connection anything. The handshake delivered it, so this is no round trip.
  # A forked child's exit must not close this process's connections
  # (karr k56, ADR 0009).
  DBIO::MySQL::MariaDBForkGuard->install if ($dbh->{Driver}{Name} // '') eq 'MariaDB';

  # The session of every connection of this transport, the listen one
  # included, is the one the synchronous storage gives its own
  # (STRICT_ALL_TABLES; karr k121). Before the pool replays on_connect_do and
  # on_connect_call, as the synchronous storage does.
  DBIO::MySQL::Storage::session_setup($dbh);

  my $conn = { dbh => $dbh };
  $self->_mysql_serverinfo($conn);

  return $conn;
}


sub _shutdown_pool_connection {
  my ($self, $conn) = @_;
  my $dbh = $conn->{dbh} or return;
  if ($self->_conn_known_dead($conn)) {
    $dbh->{Warn} = 0;
    $self->_silence_statement($conn->{sth});
  }
  $dbh->disconnect if $dbh->{Active};
}

# A statement handle of a connection known to be dead: its DESTROY could only
# report the loss once more, as "(in cleanup) ... st DESTROY failed".
sub _silence_statement {
  my ($self, $sth) = @_;
  return unless $sth;
  $sth->{RaiseError} = 0;
  $sth->{PrintError} = 0;
  return;
}

# --- DBD-specific async primitives ------------------------------------------
# These are the ONLY places the transport asks for a DBD driver's async
# binding (the five below, plus _mysql_auto_reconnect_attr for the pool and
# listen connections). None of them spells a name: each asks
# DBIO::MySQL::Storage's table for the DBD of the connection in hand -- the
# connection, not this class, is what has a DBD (karr k60). Everything else in
# the transport (submit / collect control flow, pooling, txn) is DBD-agnostic.

# The name $conn's DBD gives $what. The DBD is the handle's own, read once and
# kept on $conn. _submit_query asks first, before the connection's first
# statement, so no handle attribute is fetched with a statement in flight.
sub _mysql_binding {
  my ($self, $conn, $what) = @_;
  $conn->{_mysql_dbd} //= do {
    my $dbh = $conn->{dbh};
    $dbh && $dbh->{Driver}{Name};
  };
  return DBIO::MySQL::Storage->_dbd_attribute($conn->{_mysql_dbd}, $what);
}

# The version string the server sent in its handshake (mysql_serverinfo /
# mariadb_serverinfo), read once and kept on $conn. A client-side string: no
# statement, no round trip, safe on a dead connection too. It carries the
# product ("11.8.8-MariaDB-ubu2404" vs "8.0.30"), the same string
# SELECT VERSION() answers. undef when the handle cannot say.
sub _mysql_serverinfo {
  my ($self, $conn) = @_;
  return $conn->{_mysql_serverinfo} if exists $conn->{_mysql_serverinfo};
  my $dbh = $conn->{dbh} or return undef;
  my $info = eval { $dbh->{ $self->_mysql_binding($conn, 'serverinfo') } };
  return $conn->{_mysql_serverinfo} = $info;
}


sub _async_prepare_attrs {
  my ($self, $conn) = @_;
  return { $self->_mysql_binding($conn, 'async') => 1 };
}


sub _conn_socket_fd {
  my ($self, $conn) = @_;
  my $method = $self->_mysql_binding($conn, 'socket_fd');
  return $conn->{dbh}->$method;
}


sub _async_ready {
  my ($self, $conn) = @_;
  my $method = $self->_mysql_binding($conn, 'async_ready');
  return $conn->{sth}->$method;
}


sub _async_result {
  my ($self, $conn) = @_;
  my $method = $self->_mysql_binding($conn, 'async_result');
  return $conn->{sth}->$method;
}


sub _async_insertid {
  my ($self, $conn) = @_;
  return $conn->{sth}{ $self->_mysql_binding($conn, 'insertid') };
}


sub _mysql_auto_reconnect_attr {
  my ($self, $dsn) = @_;
  my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
  # A DSN without a driver part names no DBD: core refuses it (karr k340),
  # and DBI_DRIVER does not stand in. _dbd_attribute throws for undef.
  return DBIO::MySQL::Storage->_dbd_attribute(
    ( length $dbd ? $dbd : undef ), 'auto_reconnect',
  );
}

# --- Readiness / socket seams -----------------------------------------------


sub _conn_ready {
  my ($self, $conn) = @_;
  return $conn->{dbh} && $conn->{dbh}{Active} ? 1 : 0;
}


sub _conn_fileno {
  my ($self, $conn) = @_;
  return $self->_conn_socket_fd($conn);
}

# --- Query submit / collect -------------------------------------------------


sub _submit_query {
  my ($self, $conn, $sql, $bind) = @_;
  $bind //= [];

  my $dbh = $conn->{dbh};

  my $old = delete $conn->{sth};
  $self->_silence_statement($old) if $old && $self->_conn_known_dead($conn);
  undef $old;

  delete @$conn{qw(_error_binds _error_sql)};

  my $values = $self->_error_values($bind);
  my $sth = eval { $dbh->prepare($sql, $self->_async_prepare_attrs($conn)) };
  unless ($sth) {
    my $error = $@;
    die $self->_masked_error($error, $values, $sql);
  }
  unless (eval { $self->_bind_and_execute($dbh, $sth, $bind); 1 }) {
    my $error = $@;
    $self->_silence_statement($sth) if $self->_conn_known_dead($conn);
    die $self->_masked_error($error, $values, $sql);
  }
  $conn->{sth} = $sth;

  # What the collector needs to take the values out of an error: plain copies,
  # dropped when the result is finalised.
  @$conn{qw(_error_binds _error_sql)} = ($values, $sql);

  return;
}


sub _bind_and_execute {
  my ($self, $dbh, $sth, $bind) = @_;

  my (@attrs, @pairs);
  for my $value (@$bind) {
    my $binary = Scalar::Util::blessed($value)
      && $value->isa('DBIO::MySQL::Storage::Async::Binary');
    push @attrs, $binary ? { TYPE => DBI::SQL_BINARY() } : undef;
    push @pairs, [ {}, $binary ? $value->value : $value ];
  }
  my $adjusted = DBIO::MySQL::Storage::text_binds($dbh, \@pairs, \@attrs);

  # A type is a bind_param; without one the values go with the execute, as
  # they always did.
  return $sth->execute(map { $_->[1] } @$adjusted) unless grep { $_ } @attrs;

  $sth->bind_param($_ + 1, $adjusted->[$_][1], $attrs[$_]) for 0 .. $#pairs;
  return $sth->execute;
}


sub _collect_result {
  my ($self, $conn) = @_;

  my $sth = $conn->{sth};

  # The result may not have fully arrived on the first readable event.
  # _async_ready reports whether _async_result will not block; if not, wait for
  # more and re-check rather than blocking.
  unless ($self->_async_ready($conn)) {
    return $self->_await_readable($conn)->then(sub {
      return $self->_collect_result($conn);
    });
  }

  # The values and the statement of this one query; with them gone nothing
  # pins the caller's binds past the result.
  my ($values, $sql) = delete @$conn{qw(_error_binds _error_sql)};

  my @out;
  my $ok = eval {
    my $rv = $self->_async_result($conn);   # finalise; dies (RaiseError) on error

    # The insertid of THIS statement, for insert_async's returned-columns hashref
    # (MySQL has no RETURNING). Taken for every statement, zero included: a
    # statement that generated no id must not leave an earlier one's in place for
    # _insert_returned_columns to pick up (karr k69). last_insert_id is the other
    # value -- the last id a statement generated -- so there a zero is skipped.
    my $iid = $self->_async_insertid($conn);
    $self->{_statement_insert_id} = $iid;
    $self->{_last_insert_id}      = $iid if $iid;

    my @rows;
    my $has_rows = ($sth->{NUM_OF_FIELDS} || 0) > 0;
    @rows = @{ $sth->fetchall_arrayref } if $has_rows;

    # A statement may have produced more result sets (a CALL). The client
    # library refuses every further statement on the connection while they are
    # unread; read them out, discarded (karr k73).
    $self->_drain_more_results($conn);

    @out = $has_rows ? @rows : ($rv);
    1;
  };
  unless ($ok) {
    my $error = $@;
    die $self->_masked_error($error, $values, $sql);
  }

  return $self->future_class->done(@out);
}


sub _drain_more_results {
  my ($self, $conn) = @_;
  my $sth = $conn->{sth};
  my $ok = eval { 1 while $sth->more_results; 1 };
  return if $ok;
  my $error = $@ || 'reading the remaining result sets failed';
  $conn->{_unread_results_failed} = 1;
  die $error;
}


sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;

  return $text unless defined $text and !ref $text;

  my $masked = eval {
    DBIO::Util::mask_bound_values(
      DBIO::MySQL::Util::mask_error_details($text, $values, $statement),
      $values,
    );
  };

  return defined $masked ? $masked : $text;
}

# The values of a bind list as the hook takes them: a binary one is its value,
# undef and a reference are left out.
sub _error_values {
  my ($self, $bind) = @_;

  my @plain;
  for my $given (@{ $bind || [] }) {
    my $value = Scalar::Util::blessed($given) && $given->isa('DBIO::MySQL::Storage::Async::Binary')
      ? $given->value
      : $given;
    push @plain, "$value" if defined $value && !ref $value;
  }

  return \@plain;
}

# An error as it leaves the transport: text masked, an object as it is.
sub _masked_error {
  my ($self, $error, $values, $sql) = @_;
  return $self->_mask_error_values($error, $values, $sql);
}

# --- Dead-connection seams --------------------------------------------------


# The client library's numbers for a lost connection (errmsg.h, the same in
# MySQL's libmysqlclient and in MariaDB Connector/C). Both DBDs pass the
# library's mysql_errno() through as the handle's err -- do_error() in
# DBD::mysql 4.055, mariadb_dr_do_error() in DBD::MariaDB 1.24, from
# mysql_db_async_result() / mariadb_db_async_result() and from execute -- and
# test the first two themselves before an auto-reconnect (mysql_db_reconnect(),
# mariadb_db_reconnect()).
#
# Add a number only with a measurement, or a vendor statement, that the
# connection is unusable after it; the POD above says what was measured, and
# what is missing for 1053, 1927 and 2014. 4031 is answered by product, below.
my %CONN_LOST_ERR = map { $_ => 1 } (
  2006,   # CR_SERVER_GONE_ERROR
  2013,   # CR_SERVER_LOST
  2026,   # CR_SSL_CONNECTION_ERROR: the same loss, over TLS (measured, karr k65)
  2055,   # CR_SERVER_LOST_EXTENDED (text only in both libraries, number 2013)
);

sub _conn_error_is_fatal {
  my ($self, $conn) = @_;
  return $self->_conn_known_dead($conn);
}

# The answer of _conn_error_is_fatal, from memory. The quiet-drop paths ask it
# here, so that the seam itself is asked by the base alone (karr k74).
sub _conn_known_dead {
  my ($self, $conn) = @_;

  # No handle: nothing to send a statement on. Answered, not thrown -- the
  # base would count a throw as dead too, but report it as a broken seam.
  my $dbh = ref $conn eq 'HASH' ? $conn->{dbh} : undef;
  return 1 unless $dbh;

  # Result sets that could not be read out leave the protocol in an unknown
  # state (karr k73).
  return 1 if $conn->{_unread_results_failed};

  my $err = $dbh->err;
  return 0 unless defined $err;
  return 1 if $CONN_LOST_ERR{$err};

  # 4031 is the server closing an idle session on MySQL 8.0.24+ only.
  if ($err == 4031) {
    my $info = $self->_mysql_serverinfo($conn);
    return 0 unless defined $info && $info !~ /mariadb/i;
    my ($maj, $min, $pat) = $info =~ /^(\d+)\.(\d+)\.(\d+)/ or return 0;
    return ($maj * 1_000_000 + $min * 1_000 + $pat) >= 8_000_024 ? 1 : 0;
  }

  return 0;
}


sub _idle_connection_alive {
  my ($self, $conn) = @_;

  my $dbh = ref $conn eq 'HASH' ? $conn->{dbh} : undef;
  return 0 unless $dbh && $dbh->{Active};

  # undef once the client library has no socket (pmysql->net.fd of -1 in
  # DBD::mysql 4.055, imp_dbh->sock_fd below zero in DBD::MariaDB 1.24).
  # Guarded before vec, which warns about undef and dies on a negative offset.
  my $fd = $self->_conn_socket_fd($conn);
  return 0 unless defined $fd && $fd =~ /\A[0-9]+\z/;

  # select only reports: what the server sent stays on the socket. A zero
  # timeout cannot wait, but it can be interrupted -- the kernel answers EINTR
  # for a pending signal when nothing is readable -- which says nothing about
  # the socket, so ask again.
  my $rin = '';
  vec($rin, $fd, 1) = 1;
  my $found;
  do { $found = select(my $rout = $rin, undef, undef, 0) }
    while $found < 0 && $!{EINTR};

  # Readable (> 0) is dead; so is a select that failed (< 0, the fd is not
  # open). Only "nothing to read" is alive.
  return $found == 0 ? 1 : 0;
}

# --- LISTEN / NOTIFY seams (emulated) ---------------------------------------
#
# Core DBIO::Storage::Async owns the contract and the machinery (ADR 0056);
# DBIO::Async::Storage owns the Future::IO watch loop, the timer and the pooled
# _notify_send (dbio-async ADR 0005). What is left is MySQL's: the dedicated
# handle and the notify-table emulation, whose SQL and state are
# DBIO::MySQL::NotifyTable's. Private helpers are named _mysql_*, never
# _listen_* or _watch_*: they share an inheritance chain with core's and
# dbio-async's privates, and a same-named method appearing there later would be
# shadowed.
#
# One async statement per MySQL connection: a second one, or a ping, while one
# is in flight dies in both DBDs ("Calling a synchronous function on an
# asynchronous handle"). Every statement on the listen connection therefore
# goes through _mysql_listen_start, which records the one in flight in
# {_mysql_busy}: a drain skips its tick while a subscribe's statement runs, a
# subscribe waits for the drain in flight, and the probe does not ping over a
# statement in flight.


sub _listen_open {
  my ($self) = @_;
  my $notify   = $self->_mysql_notify_table;
  my $provider = $self->_conninfo_provider;
  my $conninfo = $provider ? $provider->() : $self->{_conninfo};
  my $conn     = $self->_mysql_connect($conninfo, 1);   # auto-reconnect forced off
  $conn->{_mysql_notify} = $notify;
  return $self->future_class->done($conn);
}


sub _listen_close {
  my ($self, $conn) = @_;
  my $dbh = delete $conn->{dbh} or return;
  $dbh->{Warn} = 0;   # an abandoned poll is an active statement handle
  $dbh->disconnect if $dbh->{Active};
  # The last statement handle goes only now, and quietly: on a dead
  # connection its DESTROY would report the loss once more, as a warning.
  if (my $sth = delete $conn->{sth}) {
    $sth->{RaiseError} = 0;
    $sth->{PrintError} = 0;
  }
  return;
}


sub _listen_subscribe {
  my ($self, $conn, $channel) = @_;
  my $notify = $conn->{_mysql_notify}
    or croak "LISTEN on channel '$channel': the listen connection is closed";
  my ($sql, $bind) = $notify->subscribe_sql($channel);
  return $self->_mysql_listen_statement($conn, $sql, $bind)->then(
    _mysql_subscribed_cb($self->future_class, $notify, $channel),
    _mysql_subscribe_failed_cb($self->future_class, $notify),
  );
}

sub _mysql_subscribed_cb {
  my ($fc, $notify, $channel) = @_;
  return sub {
    $notify->subscribed($channel, [@_]);
    return $fc->done;
  };
}

sub _mysql_subscribe_failed_cb {
  my ($fc, $notify) = @_;
  return sub {
    my ($err) = @_;
    $err = sprintf(
      'the notify table %s does not exist -- MySQL has no LISTEN/NOTIFY, and '
    . 'its emulation needs that table: deploy it once with deploy_notify_table, '
    . 'or run DBIO::MySQL::NotifyTable->create_table_sql from a migration (%s)',
      $notify->quoted_table, $err,
    ) if defined $err && $err =~ /doesn't exist/;
    return $fc->fail($err);
  };
}


sub _listen_unsubscribe {
  my ($self, $conn, $channel) = @_;
  my $notify = $conn->{_mysql_notify};
  $notify->unsubscribe($channel) if $notify;
  return $self->future_class->done;
}


sub _listen_poll_interval { $_[0]->notify_poll_interval }


sub _listen_drain {
  my ($self, $conn) = @_;
  my $notify = $conn->{_mysql_notify};
  croak 'the listen connection is closed' unless $notify && $conn->{dbh};
  croak 'the listen connection was abandoned with a statement in flight'
    if $conn->{_mysql_abandoned};
  return [] if $conn->{_mysql_busy};

  my ($sql, $bind, $token) = $notify->poll_sql or return [];
  return $self->_mysql_listen_start($conn, $sql, $bind)
    ->then($self->_mysql_polled_cb($conn, $notify, $token));
}

sub _mysql_polled_cb {
  my ($self, $conn, $notify, $token) = @_;
  my $fc = $self->future_class;
  Scalar::Util::weaken(my $weak_self = $self);
  Scalar::Util::weaken(my $weak_conn = $conn);
  return sub {
    my $notifications = $notify->polled($token, [@_]);
    my ($self, $conn) = ($weak_self, $weak_conn);
    my ($sql, $bind)  = $notify->cleanup_sql;
    return $fc->done($notifications)
      unless defined $sql && $self && $conn && $conn->{dbh};
    return $self->_mysql_listen_start($conn, $sql, $bind)->then(
      $self->_mysql_cleaned_cb($notify, $notifications, 1),
      $self->_mysql_cleaned_cb($notify, $notifications, 0),
    );
  };
}

sub _mysql_cleaned_cb {
  my ($self, $notify, $notifications, $ok) = @_;
  my $fc = $self->future_class;
  Scalar::Util::weaken(my $weak_self = $self);
  return sub {
    my ($result) = @_;
    $notify->cleaned($ok ? $result : undef);
    $weak_self->_listen_error(
      'cleaning up the notify table ' . $notify->quoted_table . ' failed: '
    . ($result // 'unknown error')
    ) if !$ok && $weak_self;
    return $fc->done($notifications);
  };
}


sub _listen_probe {
  my ($self, $conn) = @_;
  my $dbh = $conn->{dbh} or return 0;
  return 0 if $conn->{_mysql_abandoned};
  return 1 if $conn->{_mysql_busy};
  return $dbh->ping ? 1 : 0;
}


sub _notify_sql {
  my ($self, $channel, $payload) = @_;
  return $self->_mysql_notify_table->notify_sql($channel, $payload);
}


sub deploy_notify_table {
  my ($self) = @_;
  return $self->future_class->call(sub {
    $self->_query_async($self->_mysql_notify_table->create_table_sql, []);
  });
}

# The notify table of the current settings; croaks on invalid ones.
sub _mysql_notify_table {
  my ($self) = @_;
  return DBIO::MySQL::NotifyTable->new(
    table         => $self->notify_table,
    poll_interval => $self->notify_poll_interval,
    lookback      => $self->notify_lookback,
    retention     => $self->notify_retention,
  );
}

# Run a statement on the listen connection once the one in flight is done,
# whether that succeeded or not. Re-checks after the wait: the drain it waited
# for may have started its cleanup.
sub _mysql_listen_statement {
  my ($self, $conn, $sql, $bind) = @_;
  my $busy = $conn->{_mysql_busy}
    or return $self->_mysql_listen_start($conn, $sql, $bind);
  return $busy->followed_by($self->_mysql_listen_retry_cb($conn, $sql, $bind));
}

sub _mysql_listen_retry_cb {
  my ($self, $conn, $sql, $bind) = @_;
  my $fc = $self->future_class;
  Scalar::Util::weaken(my $weak_self = $self);
  Scalar::Util::weaken(my $weak_conn = $conn);
  return sub {
    my ($self, $conn) = ($weak_self, $weak_conn);
    return $fc->fail('the listen connection is gone') unless $self && $conn;
    return $fc->call(sub { $self->_mysql_listen_statement($conn, $sql, $bind) });
  };
}

# Start a statement on the listen connection and record it as the one in
# flight until it settles. A cancelled one -- the watch was stopped mid-poll --
# leaves the handle with an unread result, so the connection is marked
# abandoned: nothing runs on it again, and core closes it next.
sub _mysql_listen_start {
  my ($self, $conn, $sql, $bind) = @_;
  croak 'the listen connection is closed' unless $conn->{dbh};
  croak 'the listen connection was abandoned with a statement in flight'
    if $conn->{_mysql_abandoned};

  my $f = $self->_query_async_pinned($conn, $sql, $bind);
  $conn->{_mysql_busy} = $f;
  $f->on_ready(_mysql_listen_idle_cb($conn, $f));
  return $f;
}

sub _mysql_listen_idle_cb {
  my ($conn, $f) = @_;
  Scalar::Util::weaken(my $weak_conn = $conn);
  my $id = Scalar::Util::refaddr($f);
  return sub {
    my $conn = $weak_conn or return;
    $conn->{_mysql_abandoned} = 1 if $_[0]->is_cancelled;
    delete $conn->{_mysql_busy}
      if $conn->{_mysql_busy} && Scalar::Util::refaddr($conn->{_mysql_busy}) == $id;
    return;
  };
}

# --- Async deploy seam ------------------------------------------------------



sub _ddl_quote_ident {
  my ($self, $name) = @_;
  return DBIO::MySQL::Identifier::quote_ident($name);
}

sub _ddl_class { 'DBIO::MySQL::DDL' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Storage::Async - future_io async MySQL transport over the DBD driver's native async binding

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The concrete C<future_io> transport adapter for MySQL / MariaDB (core ADR 0030 /
0031), the MySQL analogue of L<DBIO::PostgreSQL::Storage::Async>. It is resolved
B<by convention> off the sync driver storage: a connection opened with

  MyApp::Schema->connect($dsn, $user, $pass, { async => 'future_io' });

on a L<DBIO::MySQL::Storage> instance derives C<ref($storage) . '::Async'> ==
C<DBIO::MySQL::Storage::Async>. No C<register_async_mode> call is needed; the
name itself is the registration.

=head2 Storage extensions ride on top by composition

Under the storage-layer composition model, a MySQL / MariaDB
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

Which of the two a connection gets is decided B<per connection, by its DBD>
(this dist's ADR 0007 with its 2026-10-04 addendum), never by the
class of this transport:

=over 4

=item * Before the connect there is no handle, so the DBD is the one the
connection's DSN names (L</_mysql_auto_reconnect_attr>). That DSN is the one
this very connection is opened with: with an AccessBroker it is the broker's
answer for this connection, which may differ from the last one's.

=item * From then on it is the handle's own C<< $dbh->{Driver}{Name} >>, read
once and kept on the connection.

=back

The class cannot decide it. The class is found by convention off the sync
storage class, and that is pinned by the schema component for B<every> DSN:
C<load_components('MySQL')> over a C<dbi:MariaDB:> DSN runs
L<DBIO::MySQL::Storage> and so this class, on L<DBD::MariaDB> handles; the
MariaDB component pins its classes for a C<dbi:mysql:> DSN the same way. The
names themselves come from the one table the sync storage reads too
(L<DBIO::MySQL::Storage/_dbd_attribute>), which asks the handle for the same
reason. A DBD the table does not know is refused, before the
connect, naming it.

So this class carries all of the transport, both bindings included, and its
convention subclass L<DBIO::MySQL::Storage::MariaDB::Async> adds nothing: it
exists as the name the convention resolves for the MariaDB storage class.
Neither DBD is loaded at compile time here; C<< DBI->connect >> pulls the one
the DSN names.

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

=item * L</_conn_error_is_fatal> -- whether a failed statement took its
connection with it, so the pool retires it

=item * L</_idle_connection_alive> -- whether an idle pool connection's session
is still there, asked before the pool hands it out

=item * L</_async_prepare_attrs> / L</_conn_socket_fd> / L</_async_ready> /
L</_async_result> / L</_async_insertid> -- the five DBD-specific async primitives
the seams above call, each answering for the DBD of the connection it is handed

=item * L</_ddl_class> -- the install-DDL generator (L<DBIO::MySQL::DDL>) core's
generic C<deploy_async> resolves, so C<< $storage->deploy_async($schema) >> runs
the same DDL the sync deploy pipeline emits

=back

The transaction-context seams are B<not> among them: L<DBIO::Async::Storage>
answers C<_txn_context_class> / C<_txn_conn_accessor> with the future_io
defaults this transport wants anyway (L<DBIO::Async::TransactionContext> under
the C<txn_conn> constructor key), so repeating them here would only
be a second place for the two to drift.

A connection is represented as a small hashref C<< { dbh => $dbh, sth => $sth } >>:
the driver's database handle plus the statement handle of the in-flight async
query (there is at most one per connection at a time -- MySQL allows a single
async query per connection -- guaranteed by the pool / transaction pinning).

For LISTEN/NOTIFY this class fills the listen seams with an B<emulation> over a
notify table (see L</"LISTEN / NOTIFY (emulated)">):

=over 4

=item * L</_listen_open> / L</_listen_close> -- the dedicated listen
connection, carrying its L<DBIO::MySQL::NotifyTable> state

=item * L</_listen_subscribe> / L</_listen_unsubscribe> -- take a channel's
mark on the listen connection / forget the channel

=item * L</_listen_poll_interval> -- the timer mode of the dbio-async watch
loop

=item * L</_listen_drain> -- one poll of the notify table, never blocking

=item * L</_listen_probe> -- the liveness ping

=item * L</_notify_sql> -- the notify C<INSERT>

=item * L</_mysql_auto_reconnect_attr> -- a sixth DBD-specific primitive, the
auto-reconnect attribute the pool and the listen connection switch off, named
for the DBD of the DSN being connected

=back

=head2 Transport capabilities

L</transport_capabilities> declares what L<DBIO::Async::Storage> declares --
C<on_connect_replay>: the pool replays the owning sync storage's
C<on_connect_do> / C<on_connect_call> on every freshly-spawned connection --
plus C<listen> and C<notify>, which MySQL and MariaDB get B<emulated>
(L</"LISTEN / NOTIFY (emulated)">), under the capability names every transport
uses for the same contract, and C<broker_connect_options>: the connect options
given beside an AccessBroker reach every connection this transport opens (ADR
0030 addendum II).

  my $schema = MyApp::Schema->connect($broker, {
    async                 => 'future_io',
    pool_size             => 3,
    mysql_enable_utf8mb4  => 1,          # mariadb_* names on a dbi:MariaDB: DSN
    on_connect_do         => [ q{SET time_zone = '+00:00'} ],
  });

Of that hash the owning sync storage applies its own part -- the mode, the
storage and SQL maker options, the connection actions it replays on every
pooled connection. The rest is the transport's, and without the declaration
core refuses the connect at the first async use rather than let the pooled
connections run without settings the owner's connection has:

=over 4

=item * C<pool_size> sizes the pool (L<DBIO::Storage::Async/connect_info>);
it never reaches C<< DBI->connect >>.

=item * The DBD attributes are merged into the attributes of B<every> broker
answer -- each pool spawn and each open of the listen connection -- by
L<DBIO::Async::Storage/_async_broker_conninfo>, which this transport inherits,
and handed to C<< DBI->connect >> by L</_create_pool_connection> and
L</_listen_open>. A setting given both beside the broker and in its answer must
have the same value; a different one is refused, naming the setting -- by the
owning storage at C<connect>, and again for each of these connections, since
the broker answers anew for every one. The DBD's auto-reconnect given there is
the caller's choice on pool connections as it is in any other connect
attributes (L</_create_pool_connection>), and forced off on the listen
connection.

=item * A broker that answers this transport's own shape -- a hashref with a
C<dsn>, or a C<< [ \%conninfo, \%opts ] >> pair -- cannot take DBD attributes
from beside it: that connection throws, naming them, instead of being opened
without them. Give the attributes in the answer's C<attrs> then.

=back

MySQL and MariaDB have no C<COPY> (a PostgreSQL wire feature), so there is
nothing of that kind to carry here. Pipelining
(L<DBIO::Storage::Async/pipeline>) is B<not> implemented on this C<future_io>
transport either -- neither DBD driver's async binding exposes a batch/pipeline
mode -- so C<pipeline> returns a failed Future naming this class
(L<DBIO::Storage::Async/_pipeline_refusal>), before it touches the pool. The
native C<ev> backend (L<DBIO::MySQL::EV::Storage>, dist C<dbio-mysql-ev>, over
C<EV::MariaDB>) declines pipelining too: C<EV::MariaDB> batches consecutive
queries on its own and has no mode to bracket. An async storage layer
that declares C<required_transport_capabilities> for a feature this transport
does not advertise will therefore fail loud (core capability gate) when composed
over this C<future_io> transport, naming the missing capability -- never a silent
feature loss.

=head2 LISTEN / NOTIFY (emulated)

C<listen>, C<unlisten>, C<notify>, C<listen_alive> and C<listen_reconnect> are
core async API (core ADR 0056), the same contract on every async transport that
declares C<listen> / C<notify>, documented once in
L<DBIO::Storage::Async/"LISTEN / NOTIFY">. Core owns the channel registry, the
one dedicated listen connection, reconnect with backoff, subscribing every
channel again and the fork guard; L<DBIO::Async::Storage> owns the L<Future::IO>
watch loop, the timer and the pooled C<notify> (dbio-async ADR 0005).

B<MySQL and MariaDB have no LISTEN/NOTIFY, so this transport emulates it> with a
notify table and polling, through L<DBIO::MySQL::NotifyTable> -- the part it
shares with the C<ev> transport of C<dbio-mysql-ev>. C<notify> inserts a row;
the listen connection polls the table on a timer for rows new to it. The design
and its reasons are this dist's ADR 0008.

  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'future_io' });
  my $async  = $schema->storage->async;

  $async->deploy_notify_table->get;      # once -- never created implicitly

  $async->on_listen_error(sub {
    my ($storage, $error) = @_;          # every error; without a hook it is warned
    $log->warn("listen: $error");
  });
  $async->on_listen_reconnect(sub {
    my ($storage) = @_;                  # rebuilt, every channel subscribed again
    $log->info('listen connection rebuilt -- re-read what may have been missed');
  });

  $async->listen(jobs => sub {
    my ($channel, $payload, $sender_pid) = @_;   # $sender_pid: CONNECTION_ID()
    ...
  })->get;                               # resolves once the mark is taken

  $async->notify(jobs => 'wake up')->get;   # an INSERT on a pooled connection
  $async->unlisten('jobs')->get;

What the emulation delivers, and where it differs from a server push:

=over 4

=item * B<Latency is the poll interval> (L</notify_poll_interval>, default 1
second): a notification arrives with the first poll after it became visible.

=item * B<Delivery on commit.> A notification becomes visible when the
transaction that inserted it commits -- PostgreSQL's moment too. C<notify> runs
its C<INSERT> on a pooled connection in autocommit, so it is visible at once;
to notify transactionally, run L<DBIO::MySQL::NotifyTable/notify_sql> inside
your own transaction.

=item * B<No history, no replay.> C<listen> takes a mark before its Future
resolves, so C<< listen(...)->get; notify(...)->get >> delivers and nothing
committed earlier does. A notification whose transaction was still open at
that moment is delivered when it commits. Each listen connection takes new
marks, so a reconnect -- like PostgreSQL's -- loses what was committed while
the connection was down; C<on_listen_reconnect> is where to re-read state.

=item * B<Out-of-order commits are caught, within the lookback.> AUTO_INCREMENT
ids are handed out at insert, not at commit; each poll re-reads a window of
L</notify_lookback> seconds (default 60) and delivers what it had not seen, each
notification once. The limit: a notification is lost when its transaction
commits more than the lookback after its C<INSERT> I<and> a later notification
on the same channel was delivered meanwhile (details in
L<DBIO::MySQL::NotifyTable/How the out-of-order commit is caught>).

=item * B<Retention.> The listen connection deletes rows older than
L</notify_retention> seconds (default 3600) -- one bounded C<DELETE ... LIMIT>
at most once a minute, back to back only while it clears a backlog. The
listening account needs C<SELECT> and C<DELETE> on the table, a notifying one
C<INSERT>. A cleanup that fails is reported through C<on_listen_error> and
tried again a minute later; it does not end listening. C<notify_retention(0)>
turns it off for a deployment that prunes the table itself.

=item * B<The table> is L<DBIO::MySQL::NotifyTable/THE TABLE>, named by
L</notify_table> (default C<dbio_notify>, a plain identifier). It is B<never
created implicitly>: deploy it with L</deploy_notify_table>, or run
L<DBIO::MySQL::NotifyTable/create_table_sql> from a migration. Until it exists,
C<listen> fails with a message saying so, and C<notify> with the server's.

=item * B<Channels and payloads.> A channel is matched exactly and
case-sensitively, at most 255 characters -- a longer one is refused, never
truncated, whatever the C<sql_mode>; the payload is C<TEXT>, at most 65535
bytes in UTF-8, refused beyond. An C<undef> payload arrives as C<''>. Both only
ever travel as bind values. Non-ASCII channel names need a Unicode-aware
connection (DBD::MariaDB always; DBD::mysql with C<mysql_enable_utf8mb4>).

=item * B<The listen connection.> A dedicated DBD handle outside the pool,
opened from the connect info a pool spawn would get (fresh AccessBroker
credentials included), with C<< AutoInactiveDestroy => 1 >> and the driver's
auto-reconnect forced off, since a silently rebuilt session would hide the
death core must see. It is not given the pool's C<on_connect_do> /
C<on_connect_call> replay. Its polls are non-blocking; its connect, at the
first C<listen> and at every reconnect, is a blocking C<< DBI->connect >> like
every pool connection's, as is the ping behind C<listen_alive>. One statement
runs on it at a time: a C<listen> arriving while a poll is in flight waits for
that poll, and C<listen_alive> reports a poll in flight as alive without
touching the connection -- the poll itself reports a dead one.

=item * B<Fork.> Core never touches the listen connection or the pool
outside the process that opened them, and every connection of this transport,
pooled or listening, is opened with C<< AutoInactiveDestroy => 1 >>
(L</_create_pool_connection>). So a forked child that drops its copies -- by
disconnecting the storage it inherited -- leaves the parent's sessions intact,
and with L<DBD::mysql> so does a child that simply exits. L<DBD::MariaDB>
(1.24) would not: DBI's C<END> in the exiting child calls C<disconnect_all>,
which DBD::MariaDB carries out on every connection the child inherited,
C<AutoInactiveDestroy> notwithstanding, or dies in a DBI C<active kids> panic
(exit status 22). So the first connect over L<DBD::MariaDB> installs
L<DBIO::MySQL::MariaDBForkGuard>, which makes that call a no-op in every process
but the installing one: the parent's listen and pool connections survive the
child's exit, with no rebuild (this dist's ADR 0009). It covers every
L<DBD::MariaDB> connection of the process, not only this transport's, and it
must come before the fork. A child that ends with C<POSIX::_exit> runs no
C<END> either way.

=back

The same C<IO::Async::Loop> advice as for the PostgreSQL transport applies:
with L<Future::IO::Impl::IOAsync>, build the program's loop through
C<< IO::Async::Loop->new >> (choosing an implementation with C<IO_ASYNC_LOOP>),
so the listen timer runs on the loop the program runs.

=head1 ATTRIBUTES

=head2 notify_table

The notify table's name, a plain identifier (validated by
L<DBIO::MySQL::NotifyTable/new>). Default C<dbio_notify>.

=head2 notify_poll_interval

Seconds between two polls of the listen connection: the latency of a
notification. Default 1.

=head2 notify_lookback

Seconds a notification's transaction may stay open between its C<INSERT> and
its C<COMMIT> and still be delivered after a later notification on the same
channel (L</"LISTEN / NOTIFY (emulated)">). Default 60.

=head2 notify_retention

Seconds a row is kept before the listen connection's cleanup deletes it; C<0>
turns the cleanup off. Must exceed L</notify_lookback> plus
L</notify_poll_interval>. Default 3600.

All four are C<inherited> class data seeded from
L<DBIO::MySQL::NotifyTable/defaults>: set them on the class for every
connection, or on the async backend for one. They are read when the listen
connection is opened and whenever a statement is built, so a change applies from
the next listen connection (L<DBIO::Storage::Async/listen_reconnect> makes one).

=head1 METHODS

=head2 transport_capabilities

  my @caps = DBIO::MySQL::Storage::Async->transport_capabilities;
  # ('on_connect_replay', 'listen', 'notify', 'broker_connect_options')

Class method (L<DBIO::Storage::Async/transport_capabilities>): the inherited
list plus C<listen> and C<notify>, the capability names core's LISTEN/NOTIFY
gate asks for (core ADR 0056 section 2) -- declared for an emulation, which core
ADR 0056 section 6 allows when the POD states latency and on-commit delivery, as
L</"LISTEN / NOTIFY (emulated)"> does -- and C<broker_connect_options>, which
core reads before it hands this transport the connect options given beside an
AccessBroker (L</"Transport capabilities">). Inherited unchanged by
L<DBIO::MySQL::Storage::MariaDB::Async>.

=head2 sql_maker_class

The L<DBIO::MySQL::SQLMaker> subclass used to generate SQL.

=head2 _sql_maker_args

MySQL SQLMaker construction args: backtick identifier quoting and C<.> name
separator. The MySQL C<LIMIT offset, rows> dialect is built into
L<DBIO::MySQL::SQLMaker/apply_limit>, so no C<limit_dialect> is passed. Matches
the sync driver and the C<ev> backend.

=head2 _run_crud

  my $future = $storage->_run_crud($op, $runner, @args);

Core's CRUD builder (L<DBIO::Storage::Async/_run_crud>) with the type of each
bind kept. Core hands the runner bare values, so the column a value is bound
for is gone by the time the statement is sent -- and a value of a C<BLOB> or
C<BINARY> column must be bound as C<SQL_BINARY>, which the synchronous storage
knows from the column (L<DBIO::MySQL::Storage/bind_attribute_by_data_type>).
This builds the statement with a maker that names the column of each bind,
resolves its type from C<$args[0]> (the result source) the way the synchronous
storage does, and hands the runner the values: bare, except those of a binary
column, which are L<DBIO::MySQL::Storage::Async::Binary> objects that stringify
as the value. A bind whose column cannot be resolved (a literal, an expression)
stays a bare value.

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
here); the id itself is the statement's own insertid (L</_async_insertid>), which
L</_collect_result> left on C<< $self->{_statement_insert_id} >> at the moment
the INSERT finalised. The hashref is C<< { %$to_insert, $col => $id } >>,
where C<$col> is the source's first C<is_auto_increment> column (falling back to
the first PK column whose value was not supplied, matching the sync
L<DBIO::Storage::DBI/insert> heuristic). When the statement generated no id (the
table has no auto-increment column, say) the supplied data is returned
untouched -- whatever an earlier insert on this storage generated. Both DBDs
report 0 for such a statement; for one that supplies the AUTO_INCREMENT column
itself they report the supplied value, so the hashref carries the key the
caller gave (both measured, see below). Overrides the inherited RETURNING-row
default.

The id is not read from the slot behind L</last_insert_id>, which keeps the
last id a statement generated. An insert that generated none would take the
previous insert's: into the key it had not supplied, or -- on a column flagged
C<is_auto_increment> -- over the key it had. The Row built from that hashref
would name another row, and its next C<update_async> or C<delete_async> would
go there.

The id reaches this method through the storage object, not through its
arguments: core hands over the first value the statement resolved with and
nothing of the connection it ran on. That holds because nothing is collected in
between. This method runs in the callback chain of the INSERT's own result
Future, which L</_collect_result> settles right after it stored the id; a
statement that was waiting for the connection may be B<sent> in between, but no
other statement's result is read before this method has run -- as long as
waiting for a socket (L<DBIO::Async::Storage/_await_readable>) hands back a
pending Future, which it does under L<Future::IO>'s built-in poll and under
L<Future::IO::Impl::IOAsync>, the two implementations this was run under. So
inserts that overlap on a pool of several connections each resolve with their
own id, in whatever order their results arrive, and so do the inserts of a
C<txn_do_async>, which run one after the other on its connection.

Exercised offline over a fake DBD, on the built-in poll
(F<t/70-future-io-insert-id-per-statement.t>), and B<measured against servers>
on L<Future::IO::Impl::IOAsync> (2026-10-05,
F<t/78-future-io-insert-id-live.t>; MySQL 8.0.30 and MariaDB 11.8.8,
L<DBD::mysql> 4.055 and L<DBD::MariaDB> 1.24). Six inserts started at once on
a pool of two finished in another order than they were sent, with the server
handing out the ids in another order too, and two of them generating none;
each resolved with what its own statement had generated, checked by reading
every row back under the id its insert resolved with. The same held for the
unchained inserts of a transaction while pooled inserts ran beside it on the
other connection. A pool of more than two connections, and another
L<Future::IO> implementation, were not run.

=head2 last_insert_id

  my $id = $storage->last_insert_id;

The last auto-increment value a statement on this storage generated, captured
from the driver's per-statement insertid (L</_async_insertid>). Valid after an
C<insert_async> / C<insert> succeeds; provided for legacy callers (scripts,
tests). A statement that generated no id leaves it as it was, so it is B<not>
"the id of the last insert": after an insert that generated none it still names
an earlier one, and with inserts overlapping on several pool connections it
names whichever finalised last. "Generated" is the DBD's word for it: an
insert that supplies the AUTO_INCREMENT column itself reports the supplied
value, and that is then what this returns (measured, both DBDs). The CRUD path
does not read it -- it takes the id of its own statement
(L</_insert_returned_columns>).

=head2 _normalize_conninfo

  my $info = $storage->_normalize_conninfo(
    [ 'dbi:mysql:...', $user, $pass, \%attrs, \%extra_attrs ],
  );

Convert the sync storage's DBI-form connect info into the C<[ \%conninfo,
\%opts ]> pair the pool consumes, carrying the DSN / user / password / attrs
straight through for L</_create_pool_connection> to hand to C<< DBI->connect >>.

The attributes are both hashes of the DBI form -- the fourth element and the
fifth, C<\%extra_attrs> -- merged with the fifth winning, exactly as the
owning sync storage merges them (L<DBIO::Storage::DBI/connect_info>), so a
pooled connection is opened with the values the owner's own connection has.
Either may be missing. The DBIO-private keys (C<async>, the storage and SQL
maker options) are gone from both before this seam runs: core strips them
(L<DBIO::Storage::Async/connect_info>).

The single-hash form C<< [ { dsn =E<gt> ..., user =E<gt> ..., password =E<gt> ...,
mysql_connect_timeout =E<gt> 7 } ] >> is read as the owning sync storage reads
it: every key but C<dsn>, C<user>, C<password> and C<pool_size> is a DBD
attribute, so the pooled and listen connections are opened with the flat
attributes the owner has. A nested C<attrs> hash is read too and
wins over a flat key of the same name. A hash with a C<dbh_maker>, or the
transport's own C<< [ \%conninfo, \%opts ] >> pair (it has a second element),
is not reshaped.

A C<pool_size> among the merged attributes is lifted into the conninfo hash
(the inherited normaliser strips it back out to size the pool), so it never
reaches the DBD. Broker-style or already-normalised info is passed through
untouched.

=head2 _create_pool_connection

  my $conn = $storage->_create_pool_connection(\%conninfo);

Open one DBD handle via C<< DBI->connect >> and wrap it as C<< { dbh => $dbh } >>.
C<AutoCommit> is on: the inherited orchestration drives transactions with
explicit C<BEGIN> / C<COMMIT> / C<ROLLBACK> on the pinned connection.

Two attributes make the handle safe to hold:

=over 4

=item * C<< AutoInactiveDestroy => 1 >>, always: a forked child that drops its
copy of the handle -- by disconnecting the storage it inherited, or at its exit
-- does not end the parent's session. The pool itself never tears connections
down outside the process that opened them
(L<DBIO::Storage::PoolBase/shutdown>); the handle's own C<DESTROY> is this
transport's half. With L<DBD::MariaDB> a child that runs DBI's C<END> still
closes them (the B<Fork> caveat under L</"LISTEN / NOTIFY (emulated)">).

=item * The DBD's auto-reconnect (L</_mysql_auto_reconnect_attr>) off, unless
the connect attributes set it: a session silently rebuilt under a pinned
transaction loses that transaction without an error, and DBD::mysql switches
C<mysql_auto_reconnect> on by itself under C<MOD_PERL> or C<GATEWAY_INTERFACE>.
The same default as the sync storage, and like there an explicit value is the
caller's informed choice (this dist's ADR 0005). The listen connection forces
it off even then (L</_listen_open>).

=back

A connect that fails is reported without its password: the message
goes through core's C<DBIO::Util::mask_connect_secrets> with the connect info it
is about, as core's own connect does (L<DBIO::Storage::DBI>). Otherwise it is
DBI's message -- C<< DBI connect('...','user',...) failed: >> and the DBD's
reason, the DSN as given, a C<password=> in it included -- or, when
C<< DBI->connect >> answered false because a C<HandleError> among the connect
attributes took the error, C<DBI connect failed:> and the DBD's reason. The
listen connection (L</_listen_open>) is opened the same way, so the same holds
for what its failed connect hands the C<listen> Future and C<on_listen_error>,
on every reconnect attempt again.

=head2 _shutdown_pool_connection

Disconnect the DBD handle held by C<$conn>.

A connection known to be dead (L</_conn_error_is_fatal>, read from memory, no
round trip) is disconnected quietly, as L</_listen_close> does the listen
connection: the handle's C<Warn> is switched off, since DBD::mysql reports
the statement handle a lost connection leaves active ("disconnect invalidates
1 active statement handle"), and the last statement handle is silenced
(C<RaiseError> and C<PrintError> off), since its C<DESTROY> would only report
the loss again. A healthy connection is disconnected as it was, warnings
untouched.

=head2 _async_prepare_attrs

  my $attrs = $storage->_async_prepare_attrs($conn);

The prepare-time attributes that arm a non-blocking query on C<$conn>:
C<< { async => 1 } >> for DBD::mysql, C<< { mariadb_async => 1 } >> for
DBD::MariaDB. C<execute> then returns immediately.

=head2 _conn_socket_fd

  my $fd = $storage->_conn_socket_fd($conn);

The connection socket file descriptor for the L<Future::IO> readable watcher --
C<< $dbh->mysql_fd >> for DBD::mysql, C<< $dbh->mariadb_sockfd >> for
DBD::MariaDB (the MySQL analogue of DBD::Pg's C<pg_socket>).

=head2 _async_ready

  my $bool = $storage->_async_ready($conn);

True once L</_async_result> will not block: C<mysql_async_ready> or
C<mariadb_async_ready> on the connection's statement in flight.

=head2 _async_result

  my $rv = $storage->_async_result($conn);

Finalise the connection's statement in flight and return what C<execute> would
have -- the affected-row count (C<mysql_async_result> or
C<mariadb_async_result>). Dies (RaiseError) on a server-side error.

=head2 _async_insertid

  my $id = $storage->_async_insertid($conn);

The per-statement C<AUTO_INCREMENT> id generated by the finalised INSERT, read
from C<< $sth->{mysql_insertid} >> or C<< $sth->{mariadb_insertid} >> -- the
per-sth form DBD::mysql recommends over the shared-handle
C<< $dbh->{mysql_insertid} >>. Zero / undef for non-INSERTs.

=head2 _mysql_auto_reconnect_attr

  my $attr = $storage->_mysql_auto_reconnect_attr($dsn);
  # 'mysql_auto_reconnect' for dbi:mysql:..., 'mariadb_auto_reconnect' for
  # dbi:MariaDB:...

The name of the auto-reconnect attribute of the DBD that C<$dsn> names. Pool
connections are opened with it switched off unless the connect attributes set
it (L</_create_pool_connection>), the listen connection always
(L</_listen_open>). DBD::mysql turns C<mysql_auto_reconnect> B<on> by itself
when C<GATEWAY_INTERFACE> or C<MOD_PERL> is set; DBD::MariaDB leaves
C<mariadb_auto_reconnect> off, and the transport says so explicitly.

The sixth DBD-specific primitive, and the one that is needed before a handle
exists: it goes into the connect attributes. So it reads the DBD off the DSN,
the way DBI and L<DBIO::Storage::DBI> do -- the driver part of C<dbi:DRIVER:>. A DSN that names none is refused
(core refuses it; C<DBI_DRIVER> does not stand in). The name is not
spelled here: it comes from the table the sync storage reads too
(L<DBIO::MySQL::Storage/_dbd_attribute>), which throws for a DBD it has no
names for.

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

On a connection already known to be dead (L</_conn_error_is_fatal>, from
memory -- the ROLLBACK core sends after a lost connection) the spent statement
handle is silenced before it is dropped, and so is the new one when its
C<execute> fails on a connection that turns out dead: their C<DESTROY> could
only report the loss as C<(in cleanup) ... st DESTROY failed>. A live
connection is never touched; the healthy path pays nothing for this.

=head2 _bind_and_execute

  $storage->_bind_and_execute($dbh, $sth, \@bind);

Bind the values of C<\@bind> and execute: the way a value reaches the server is
the synchronous storage's. A value that is a
L<DBIO::MySQL::Storage::Async::Binary> (a value of a binary column, see
L</_run_crud>) is bound as C<SQL_BINARY>, every other value goes through
L<DBIO::MySQL::Storage/text_binds> -- under L<DBD::mysql> with the utf8
attribute a string in Perl's 8-bit form is bound as characters.

=head2 _collect_result

  my $future = $storage->_collect_result($conn);

Called once the socket is readable. The seam takes the connection and B<nothing
else> (ADR 0044): the bind values were serialised onto the wire by
L</_submit_query> at dispatch, so the re-poll recursion below carries C<$conn>
alone and not the caller's bind arrayref. What it needs to take the values out
of an error text is on C<$conn>: plain copies of the values and the statement,
which L</_submit_query> leaves there and this method removes when the result is
finalised, whether that succeeded or not. An error the DBD raises while the
result is read passes through L</_mask_error_values> before it is rethrown.

If the async result has not fully arrived (L</_async_ready> is false) it waits
for the socket again (L<DBIO::Async::Storage/_await_readable>) and re-checks --
so a large result spanning several reads is handled correctly. Once ready it
finalises with L</_async_result> and resolves:

=over 4

=item * a query that produced a result set (SELECT) -> the list of raw row
arrayrefs, exactly the shape the sync cursor's C<< ->all >> yields (ADR 0031 §3);

=item * a statement with no result set (INSERT / UPDATE / DELETE, BEGIN /
COMMIT / ...) -> the affected-row count from L</_async_result>.

=back

It also takes the statement's insertid (L</_async_insertid>) off the handle, to
two places. C<< $self->{_statement_insert_id} >> gets it for B<every> statement,
zero included, so that L</_insert_returned_columns> folds into the
returned-columns hashref the id of the INSERT that just finalised and never an
earlier one's (MySQL has no C<RETURNING>). The slot behind
L</last_insert_id>, C<< $self->{_last_insert_id} >>, gets it only when
non-zero, so a statement that generated no id does not clear the last one that
was.

The full row list is carried in an explicit C<< future_class->done(@rows) >> so
it survives the surrounding C<< ->then >> chain (a bare list return would
collapse to its last element).

=head2 _drain_more_results

  $storage->_drain_more_results($conn);

Reads and discards the result sets that follow the first one of the statement
on C<< $conn->{sth} >> (C<more_results>), so the pool connection stays usable:
with L<DBD::MariaDB> 1.24 a statement that left one unread made the library
refuse every statement after it on that connection (2000, I<Calling a
synchronous function on an asynchronous handle>). A statement with a
single result set asks C<more_results> once, which answers from what the
client already knows and sends nothing, so it cannot block.

When reading them fails the connection's state is unknown. The connection is
flagged on C<$conn>, the error is rethrown, and the failed Future makes the
base ask L</_conn_error_is_fatal>, which answers true for a flagged connection:
the pool retires it.

=head2 _mask_error_values

  my $text = $storage->_mask_error_values($text, \@values, $statement);

The seam of the synchronous storage (L<DBIO::MySQL::Storage/_mask_error_values>)
for the transport: the text an engine writes into an error with the offending
value taken out, C<***> in its place, and the type, the column and the key left.
C<\@values> are the values bound to the statement as plain values, C<$statement>
the statement in placeholder form or C<undef>. It never throws; a text it cannot
treat is answered unchanged, and anything that is no text (an exception object)
as it is.

  Duplicate entry 'geheim42' for key 'users.PRIMARY'
  # becomes
  Duplicate entry '***' for key 'users.PRIMARY'

Every error the DBD raises while a statement is sent (L</_submit_query>) or
collected (L</_collect_result>, with the reading of further result sets) passes
through it before it reaches the failed Future. The statements of the listen
emulation travel the same two ways.

=head2 _conn_error_is_fatal

  my $dead = $storage->_conn_error_is_fatal($conn, $error);

Driver seam of L<DBIO::Async::Storage/_conn_error_is_fatal>: did the statement
that just failed on C<$conn> take the connection with it? The base asks for
every failed query Future of L<DBIO::Async::Storage/_query_async> and
L<DBIO::Async::Storage/_query_async_pinned> -- whether L</_submit_query> died
sending the statement or L</_collect_result> died reading its result -- and on
a true answer reports C<$conn> to the pool
(L<DBIO::Storage::PoolBase/_mark_connection_dead>) before the connection is
handed back, so the release retires it instead of putting it back. The pool
cannot see a connection die by itself: without the report a dead handle goes
back on the idle list, and every caller it is handed to fails the same way. A
transaction's pinned connection is covered alike, since core hands it back
through the same release once the transaction has ended.

Dead means the client library has lost the server: the error number on the
handle, C<< $conn->{dbh}->err >>, is one of

=over 4

=item * C<2006> C<CR_SERVER_GONE_ERROR> -- I<server has gone away>: the
client library found the connection closed as it sent the statement.

=item * C<2013> C<CR_SERVER_LOST> -- I<lost connection during query>: it closed
while the result was awaited. Also what a connection that died while it sat
idle in the pool answers its next statement with: that statement is sent
without an error and fails as its result is read (measured; see below).

=item * C<2026> C<CR_SSL_CONNECTION_ERROR> -- I<TLS/SSL error: unexpected eof
while reading>: the same loss on an encrypted connection, where it is this
number the handle holds and not 2013 (measured; see below). A TLS
error on a statement means the encrypted channel is broken, whatever broke it.

=item * C<2055> C<CR_SERVER_LOST_EXTENDED> -- I<lost connection at ..., system
error ...>. Listed for what it says; MySQL's client library and MariaDB
Connector/C both report that text under number 2013.

=back

or C<$conn> holds no handle at all. These are numbers of the B<client> library
(C<errmsg.h>), the same in MySQL's and in MariaDB Connector/C, and both DBDs
hand the library's number through as C<err> unchanged -- two of them (2006,
2013) are also what each DBD's own auto-reconnect takes for "the server has
disconnected". So one implementation serves both DBDs and
L<DBIO::MySQL::Storage::MariaDB::Async> adds nothing.

B<It is a list, not "any error">, because a statement error leaves the session
where it was: after a duplicate key (1062), a syntax error (1064), a deadlock
(1213), a lock wait timeout (1205) or an interrupted query (1317) the
connection runs the next statement, and retiring it would cost a reconnect per
failed statement -- and inside a transaction it would have the base refuse
every statement queued behind the failed one. Any number not listed answers
false, as does a failure the DBD did not report at all (no number on the
handle). A statement the server timed out is among them, and it is not 1317:
MySQL reports C<3024> for C<MAX_EXECUTION_TIME>, MariaDB C<1969> for
C<max_statement_time>. After either, as after 1317 from C<KILL QUERY>, the
session is there and a transaction it had open is still open (measured inside
C<txn_do_async>, F<t/79-future-io-txn-kill-query-live.t>).

The answer is also what the quiet drop of a dead connection's handles asks
(L</_shutdown_pool_connection>, L</_submit_query>), through an
internal sibling, so the seam itself is still asked by the base alone.

B<No ping, no round trip.> The seam runs in the failure path of a query, from
inside the event loop, so it must not block or send anything; a ping is a
synchronous round trip, and would be paid on every ordinary statement error.
The number is already there. It is read from the database handle rather than
the statement handle, since a statement that fails as it is sent leaves no
statement handle on C<$conn>; DBI keeps one error for a statement handle and
its database handle. DBI clears it only on the next method call on the handle,
and the base asks from the failed Future's own callbacks, before the release.
It is not always the number the statement died with, though: a statement that
fails as it is B<sent> dies with 2006, its statement handle is dropped as
L</_submit_query> unwinds, and that handle's C<DESTROY>, failing on the dead
connection, leaves 2013 behind -- which is what this seam then reads, on both
DBDs (measured). Both are on the list. C<$error> is not read: the exception
text carries no number, and its wording is the client library's and, for a
server error, the server's C<lc_messages>.

B<What was measured> (2026-10-05, F<t/77-future-io-conn-error-is-fatal-live.t>;
MySQL 8.0.30 and MariaDB 11.8.8, L<DBD::mysql> 4.055 and L<DBD::MariaDB> 1.24,
each plain and over TLS 1.3). On that host both DBDs were built on MariaDB
Connector/C 3.4.9, so MySQL's own client library is B<not> among the
measurements. The number is what the handle held when this seam was asked;
"dead" means a C<ping> on it right afterwards failed.

  what happened                              plain   TLS    connection
  KILL CONNECTION while a statement runs     2013    2026   dead
    the ROLLBACK core then sends, when
    that was in a transaction                2013    2013   dead
  statement on a connection killed
    while it sat idle                        2013    2026   dead
  statement after wait_timeout, MariaDB      2013    2026   dead
  statement after wait_timeout, MySQL        4031    4031   dead
  KILL QUERY while a statement runs          1317    1317   alive
  duplicate key, syntax error                1062, 1064     alive

Every row was the same on both DBDs. C<KILL CONNECTION> never arrived as a
server error: what the client library reported was the loss of the
connection.

B<Not listed (or listed by product):>

=over 4

=item * C<4031> is two errors, and is listed for one product. On MySQL 8.0.24
and later it is C<ER_CLIENT_INTERACTION_TIMEOUT>, I<the client was
disconnected by the server because of inactivity>: MySQL 8.0.30 sends it as an
error packet ahead of the close at C<wait_timeout>, the client library hands
it out as the answer to the next statement, and the connection is dead
(measured, table above). On MariaDB the same number is
C<ER_REFERENCED_TRG_DOES_NOT_EXIST>, a statement error on a healthy session.
The number alone cannot tell, so the seam answers 4031 from the server
product (maintainer's decision): fatal on MySQL 8.0.24 and later,
not on MariaDB, and not when the product is unknown. The product is the
version string of the server's handshake (C<mysql_serverinfo> /
C<mariadb_serverinfo>, named by the handle's DBD), read once when the pool
connection is opened and kept on it: no statement, no round trip, nothing sent
on a connection that may be dead. It is the same string C<SELECT VERSION()>
answers, which L<DBIO::MySQL::Storage/_is_mariadb> reads on the sync side.

=item * C<1053> C<ER_SERVER_SHUTDOWN> and MariaDB's C<1927>
C<ER_CONNECTION_KILLED> are what the servers set for a statement on a session
being killed. A C<KILL> did not deliver either of them (table above). Whether
a server that shuts down does, and in which state the connection then is, has
not been measured -- it needs a server that may be stopped.

=item * C<2014> C<CR_COMMANDS_OUT_OF_SYNC> is the client library refusing a
statement while a result is unread. It was looked for with a C<CALL> that
returns two result sets, and did not arrive: with L<DBD::mysql> the next
statement simply runs, and L<DBD::MariaDB> 1.24 refuses it -- and every one
after it on that connection -- with its own C<2000>, I<Calling a synchronous
function on an asynchronous handle>, a number that says nothing about the
server. That cannot happen any more: L</_collect_result>
reads the remaining result sets out (L</_drain_more_results>), so
the connection stays usable. When that reading fails, the connection is
flagged, and this seam answers true for it whatever the handle's error: the
pool retires it. 2000 itself stays a kept error -- it is the DBD's number for
a misuse.

=back

A connection that dies while it sits idle is L</_idle_connection_alive>'s to
catch, before the pool hands it out. What that check cannot see --
a session that ended without the server saying so, or after the check -- is
handed out, its statement fails as a lost connection, and this seam retires
it: the call after that gets a fresh one.

The listen connection is asked about too: its statements run through
L<DBIO::Async::Storage/_query_async_pinned> (L</_listen_drain>). The pool does
not hold it, so a true answer changes nothing there; core's listen machinery
sees the failed poll and rebuilds the connection itself.

=head2 _idle_connection_alive

  my $alive = $storage->_idle_connection_alive($conn);

Driver seam of L<DBIO::Async::Storage/_idle_connection_alive>: is the server
session behind the idle pool connection C<$conn> still there? Core's pool asks
it every time it is about to hand out an idle connection
(L<DBIO::Storage::PoolBase/acquire>); on a false answer it retires C<$conn>
and takes the next idle connection or a fresh one. So a session the server
ended while its connection sat idle -- C<KILL>, a server restart,
C<wait_timeout> -- no longer costs a caller a failed statement first.

Three things are read, in this order, and nothing else:

=over 4

=item 1. No handle, or one whose C<Active> is false: dead. C<Active> is DBI's
own flag on the handle, read from memory; both DBDs clear it only when the
handle is disconnected on this side. It does not notice the server going away
-- that is what step 3 is for -- but it keeps the next step from asking a
closed handle for its socket.

=item 2. No socket fd (L</_conn_socket_fd>): dead. Both DBDs answer C<undef>
once the client library holds no socket; C<mysql_fd> and C<mariadb_sockfd>
each return a number the library or the DBD keeps in memory.

=item 3. The socket is readable, by one C<select> with a zero timeout on that
fd: dead. Not readable: alive -- the common case, and all a borrow costs.

=back

B<Why readable means dead.> MySQL's client/server protocol is request and
response: the server sends a packet only to answer a command, on MySQL and on
MariaDB alike. An idle connection has no command outstanding -- the pool takes
a connection back only once its statement's result was collected or the
statement failed, and one cancelled in flight is retired, not idled
(L<DBIO::Async::Storage/_query_async>). So nothing is due on it, and whatever
makes its socket readable is not an answer to anything:

=over 4

=item * B<The server closed it.> End of file leaves a socket readable for
good. This is what C<KILL>, a shutdown or an idle timeout come to. A C<KILL>
sends nothing ahead of the close, on MySQL 8.0.30 and on MariaDB 11.8.8, and
neither does MariaDB at C<wait_timeout> (measured).

=item * B<The server said why, then closed it.> MySQL 8.0.24 and later send an
error packet (4031, I<the client was disconnected by the server because of
inactivity>) ahead of the close at C<wait_timeout> -- seen on the socket of an
idle connection on 8.0.30 -- and a server shutting down may send one too. The
packet can arrive before the close does; either way the session is over.

=item * B<A previous statement left something unread> -- a further result set
of a statement that returned more than one. L</_collect_result> reads those
out, so none reaches the idle list. A C<CALL> with two result sets
never made this check see anything, though: the socket was quiet, on both
DBDs (measured), which is why the unread result was a defect of the
collector and not something this check could have caught.

=item * B<A TLS record that carries no MySQL data> -- a session ticket or a key
update of TLS 1.3. This is the one case where a healthy connection would be
taken for dead. A server's session tickets follow the handshake at once and
are read with the answer to the authentication, so none is expected on a
connection that has gone idle; if one arrives anyway the cost is one
reconnect, never an error. Over TLS 1.3 to both servers none did: the idle
socket was quiet at every borrow, from the first after the connect (measured).

=back

B<It only looks.> The C<select> reports; it does not read, so what the server
sent stays on the socket, and no C<recv>, not even a peeking one, is needed to
tell the cases apart: all of them are dead. It never waits (the timeout is
zero; a C<select> interrupted by a signal is repeated) and never sends: no
C<ping>, no statement -- both are round trips, and this runs on every borrow.
A C<select> that fails for any other reason -- the fd is not open -- is dead:
the transport waits for every result on this same fd
(L<DBIO::Async::Storage/_await_readable>) and could not run a statement on it
either. Perl's C<select> takes a bit vector of any length, so an fd above 1023
is checked like any other.

One implementation serves both DBDs: the fd comes from the connection's own
DBD (L</_conn_socket_fd>), the rest is DBI's and the kernel's, and
L<DBIO::MySQL::Storage::MariaDB::Async> adds nothing.

B<Read from the protocol and the DBD sources> (DBD::mysql 4.055, DBD::MariaDB
1.24), exercised offline against real sockets, and B<measured against servers>
(2026-10-05, F<t/76-future-io-idle-connection-alive-live.t>; MySQL 8.0.30 and
MariaDB 11.8.8, both DBDs -- on that host both built on MariaDB Connector/C
3.4.9 -- each plain and over TLS 1.3): a healthy idle connection's socket
stays quiet and the connection is handed out again; after a C<KILL> and after
C<wait_timeout> it is readable, and the next call runs on a new session
without an error. What a server that shuts down leaves on the socket has not
been measured.

It narrows the window; it does not close it. A session can end after the
check, or without the server saying so -- a network partition, a host gone, a
firewall that dropped the idle flow: the socket stays quiet, the connection is
handed out, and its statement fails as a lost connection.
L</_conn_error_is_fatal> then retires it, as before. The two are siblings:
that one reports a connection dead B<after> a statement failed on it, this one
B<before> one is sent. Together a connection the server ended while it sat
idle costs no caller a call.

The listen connection is not asked about here: the pool does not hold it, and
core's listen machinery probes it through L</_listen_probe>.

=head2 _listen_open

  my $f = $storage->_listen_open;   # done with { dbh => $dbh, ... }

Core listen seam (L<DBIO::Storage::Async/_listen_open>): open the dedicated
listen connection -- a B<new> DBD handle, never one from the pool. Its connect
info is what a pool spawn would get at this moment: fresh credentials through
L<DBIO::Storage::Async/_conninfo_provider> when an AccessBroker is attached,
otherwise the static conninfo. A provider whose broker has been detached
(L<DBIO::Storage/clear_access_broker>) opens nothing:
L<DBIO::Async::Storage/_async_broker_conninfo>, which this transport inherits,
throws saying that no broker is attached, and core reports that like any other
failed open. The connect shape is the pool's
(L</_create_pool_connection>): C<< AutoInactiveDestroy => 1 >>, so a forked
child's copy of the handle does not end the parent's session when it is
destroyed (DBD::MariaDB closes it anyway at the child's exit -- the B<Fork>
caveat under L</"LISTEN / NOTIFY (emulated)">), and the DBD's auto-reconnect
(L</_mysql_auto_reconnect_attr>) off -- here forced off even against the
connect attributes, so a dead session is reported instead of silently replaced.

The connection carries a fresh L<DBIO::MySQL::NotifyTable> built from the
L</notify_table> settings: the marks of this connection, which a reconnect
therefore takes anew. Invalid settings throw here, before anything connects;
core reports that and keeps retrying with backoff. Resolves with the pool's
connection shape, so the pinned query path of L<DBIO::Async::Storage> runs on
it unchanged.

=head2 _listen_close

  $storage->_listen_close($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_close>): disconnect the listen
handle and take it off C<$conn>. A dead connection is fine, and so is one with
a poll still in flight -- core has stopped the watch first, which cancelled the
poll. The handle is disconnected B<before> the last statement handle is
released: releasing an in-flight asynchronous statement handle waits for its
result, disconnecting first does not. That statement handle is released with
its errors silenced, since on a dead connection its C<DESTROY> would only
report the loss core has already reported.

=head2 _listen_subscribe

  my $f = $storage->_listen_subscribe($conn, $channel);

Core listen seam (L<DBIO::Storage::Async/_listen_subscribe>): take the channel's
mark (L<DBIO::MySQL::NotifyTable/subscribe_sql>) on the listen connection and
resolve once it is in effect -- so a C<notify> after C<< listen(...)->get >> is
delivered. A poll in flight is waited for first. The channel is validated at
this seam and travels as a bind value; a channel it refuses makes the seam
throw, and a missing notify table fails it with a message naming the table and
how to deploy it. Either way core finds the connection alive, drops the channel
and fails its C<listen> Future with the reason.

=head2 _listen_unsubscribe

  my $f = $storage->_listen_unsubscribe($conn, $channel);

Core listen seam (L<DBIO::Storage::Async/_listen_unsubscribe>): stop polling
the channel. Local bookkeeping only (L<DBIO::MySQL::NotifyTable/unsubscribe>);
rows for it that a poll already in flight brings back are dropped.

=head2 _listen_poll_interval

Seam of the L<DBIO::Async::Storage> watch loop
(L<DBIO::Async::Storage/_listen_poll_interval>): L</notify_poll_interval>
seconds, which selects its B<timer> mode -- it polls on that interval and never
watches the socket.

=head2 _listen_drain

  my $f = $storage->_listen_drain($conn);
  # Future of [ [ $channel, $payload, $sender_pid ], ... ]

Driver seam of the L<DBIO::Async::Storage> watch loop
(L<DBIO::Async::Storage/_listen_drain>), called on every tick: one poll of the
notify table (L<DBIO::MySQL::NotifyTable/poll_sql>) as a non-blocking query on
the listen connection, resolving with what is new in the contract order. When
a cleanup is due (L</notify_retention>) it runs right after, on the same
connection, before the Future resolves; its failure goes to core's
L<DBIO::Storage::Async/_listen_error>, which reports it through
C<on_listen_error>, and does not fail the drain.

The Future fails when the poll fails -- a dead connection, for the loop's
C<_listen_lost>. An empty arrayref, without a statement, when no channel is
subscribed or a subscribe's statement is running on the connection (the next
tick polls). Dies on a connection L</_listen_close> closed or whose statement a
cancelled watch abandoned.

=head2 _listen_probe

  my $alive = $storage->_listen_probe($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_probe>), asked by
L<DBIO::Storage::Async/listen_alive> and after a failed subscribe: the DBD's
C<ping>, a synchronous round trip, false on a dead connection. While a
statement is in flight on the connection it answers true B<without> pinging --
a ping then would die in the DBD and be taken for a death -- because that
statement reports a dead connection itself.

=head2 _notify_sql

  my ($sql, $bind) = $storage->_notify_sql($channel, $payload);

Driver seam of L<DBIO::Async::Storage/_notify_send>, which runs the statement
on a pooled connection: L<DBIO::MySQL::NotifyTable/notify_sql>, an C<INSERT>
with channel and payload as bind values, C<CONNECTION_ID()> as the sender.
Throws on an invalid channel, payload or L</notify_table>, which fails the
Future of L<DBIO::Storage::Async/notify>.

=head2 deploy_notify_table

  $storage->deploy_notify_table->get;

Create the notify table (L<DBIO::MySQL::NotifyTable/create_table_sql>,
C<CREATE TABLE IF NOT EXISTS>) on a pooled connection; a Future that resolves
once it exists. Nothing creates it implicitly: it is DDL, which MySQL commits
implicitly, and a schema change is the deployer's call. Fails for an invalid
L</notify_table>.

=head2 _ddl_class

The install-DDL generator the inherited L<DBIO::Storage::Async/deploy_async>
resolves through L<DBIO::Storage::Async/_install_ddl>: L<DBIO::MySQL::DDL> --
the very class the B<sync> MySQL deploy pipeline uses
(L<DBIO::MySQL::Deploy/_ddl_class>), so async and sync deploy emit byte-identical
MySQL DDL. Filling this seam is all the transport needs: core's generic
C<deploy_async> then runs every generated statement over the
L<DBIO::Async::Storage/_query_async_pinned> path this class already serves for
CRUD, through L</_submit_query> / L</_collect_result>. Inherited unchanged by
L<DBIO::MySQL::Storage::MariaDB::Async> -- which DDL the server speaks is a
property of the product, not of the DBD a connection runs on (this
dist's ADR 0001).

The DDL batch is deliberately B<not> wrapped in a transaction. MySQL implicitly
COMMITs each DDL statement -- L<DBIO::MySQL::Storage> declares
C<< _use_transactional_ddl(0) >> for both products -- so the inherited
C<deploy_async> takes its non-transactional branch (ADR 0026): statement at a
time on one pooled connection, with a one-shot warning naming this class. A
deploy that fails half way therefore leaves the already-executed statements
behind; re-run with C<< add_drop_table => 1 >> to get back to a known state.

=head2 _ddl_quote_ident

  my $quoted = $storage->_ddl_quote_ident($name);

The identifier of every statement in the L<DBIO::Storage::Async/deploy_async>
C<< add_drop_table => 1 >> pre-pass (C<DROP VIEW IF EXISTS> for the declared
views, C<DROP TABLE IF EXISTS ... CASCADE> for the tables), quoted the way the
install DDL quotes it: L<DBIO::MySQL::Identifier/quote_ident>, always
backticks. The seam of core quotes ANSI (a plain name bare, any other in double
quotes), which on MySQL and MariaDB is a syntax error (1064) for a table named
C<order> or C<my-tab>, and a string literal for the second. Which objects are
dropped, in which order, and the shape of the result are the seam's
(L<DBIO::Storage::Async/_drop_statements_for>); this hook is the only
part that differs here.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
