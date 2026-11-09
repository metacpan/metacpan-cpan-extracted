package DBIO::PostgreSQL::Storage::Async;
# ABSTRACT: future_io async PostgreSQL transport over DBD::Pg's pg_async binding

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Async::Storage';

use Carp ();
use Scalar::Util ();
use DBI;
use DBD::Pg qw(:async);
use Future::IO;
use DBIO::Util ();
use DBIO::Exception ();
use DBIO::PostgreSQL::SQLMaker;
use DBIO::PostgreSQL::DDL ();
use DBIO::PostgreSQL::Util ();
use namespace::clean;

# The private attribute of a database handle that holds the values bound to the
# statement in flight (_submit_query ... _collect_result), for _pg_raise.
use constant BINDS_SLOT => 'private_dbio_binds';


# --- Transport capabilities -------------------------------------------------


sub transport_capabilities {
  my $self = shift;
  return ($self->next::method(@_), qw(listen notify broker_connect_options));
}

# --- SQL shaping seams ------------------------------------------------------


sub sql_maker_class { 'DBIO::PostgreSQL::SQLMaker' }


sub _sql_maker_args {
  my ($self) = @_;
  my $owner = ref $self ? $self->_owner_storage : undef;

  my @quoting = (quote_char => '"', name_sep => '.');
  if ($owner) {
    my $sync = $owner->sql_maker;
    @quoting = (
      (defined $sync->{quote_char} ? (quote_char => $sync->{quote_char}) : ()),
      name_sep => $sync->{name_sep},
    );
  }

  return (
    @quoting,
    limit_dialect => 'LimitOffset',
  );
}

# The shared DBIO::PostgreSQL::SQLMaker also feeds the sync DBI driver, which
# needs '?', so the maker keeps emitting '?'. The numbering therefore happens
# here, in the transport, once, on what reaches the query seams (core k70 /
# ADR 0032). DBD::Pg would take '?' as well as '$N'; the statement is numbered
# all the same, so that _submit_query can set pg_placeholder_dollaronly and
# DBD::Pg leaves every '?' that is no placeholder -- the jsonpath operator,
# which the maker writes '@\?' and the numbering hands on as '@?', first of
# all -- as it is.
#
# Which '?' is a placeholder is not decided here: that is one rule about
# PostgreSQL's scanner, kept in DBIO::PostgreSQL::Util::number_placeholders and
# shared with the native ev transport.


sub _transform_sql {
  my ($self, $sql) = @_;
  return DBIO::PostgreSQL::Storage::Async::_Refusal::of_util(
    sub { DBIO::PostgreSQL::Util::number_placeholders($sql) },
  );
}


sub _post_insert_sql { ' RETURNING *' }

# --- Connect-info seam ------------------------------------------------------


sub _normalize_conninfo {
  my ($self, $info) = @_;

  # DBI-form: [ 'dbi:Pg:...', $user, $pass, \%attrs, \%extra ] -> our conninfo
  # shape. Both attribute hashes, the later winning, as
  # DBIO::Storage::DBI::_normalize_connect_info merges them (karr k91).
  if (ref $info eq 'ARRAY'
      && defined $info->[0] && !ref $info->[0] && $info->[0] =~ /^dbi:/i) {
    my ($dsn, $user, $pass) = @$info;
    my %conninfo = (
      dsn      => $dsn,
      user     => $user,
      password => $pass,
      attrs    => { map { %$_ } grep { ref $_ eq 'HASH' } @{$info}[3, 4] },
    );
    $conninfo{pool_size} = delete $conninfo{attrs}{pool_size}
      if defined $conninfo{attrs}{pool_size};
    return [ \%conninfo, {} ];
  }

  # Broker arrayref [ $broker ], or an already-normalised [ \%conninfo, \%opts ]
  # pair -- leave for the inherited broker detection / normalisation.
  return $info;
}


sub _async_broker_conninfo {
  my ($self, $mode) = @_;

  # Without a broker _current_async_connect_info answers what is stored, and
  # that is no broker's answer (karr k97; as dbio-async refuses, its k43).
  _pg_refuse(sprintf '%s has no AccessBroker attached to ask for connect info',
    ref($self) || $self)
    unless $self->access_broker;

  my ($conninfo) = $self->_normalize_async_connect_info(
    $self->_pg_broker_connect_info($self->_current_async_connect_info($mode))
  );
  $conninfo->{attrs} = $self->_merge_access_broker_settings(
    $conninfo->{attrs}, $self->_access_broker_call_attributes,
  );
  return $conninfo;
}

# What the broker answered, in any shape _async_broker_conninfo lists, as the
# [ \%conninfo, \%opts ] pair core's _normalize_async_connect_info splits.
sub _pg_broker_connect_info {
  my ($self, $info) = @_;

  $info = [ $info, {} ] if ref $info eq 'HASH';

  if (ref $info eq 'ARRAY') {
    my $first = $info->[0];
    if (defined $first && !ref $first && $first =~ /^dbi:/i) {
      # Core's strip also records the storage options it pulls out; that
      # record belongs to connect_info, not to one broker answer.
      local $self->{_storage_options};
      return $self->_normalize_conninfo($self->_strip_private_connect_attrs($info));
    }
    return [ $self->_pg_broker_conninfo_hash($first), $info->[1] ]
      if ref $first eq 'HASH';
  }

  _pg_refuse(sprintf(
    'PostgreSQL future_io cannot connect from what the AccessBroker returned: %s. '
  . "It takes a DBI-form arrayref [ 'dbi:Pg:...', \$user, \$password, \\%%attrs ], "
  . 'a hashref of libpq connection parameters (dbname, host, port, user, password, ...), '
  . 'a hashref with a dsn (dsn, user, password, attrs), '
  . 'or either hashref paired with an options hashref',
    $self->_pg_describe_shape($info)),
    _pg_answer_connect_info($info));
}

# One conninfo hash from a broker: taken as it is when it has a dsn, otherwise
# its libpq connection parameters become the dsn.
sub _pg_broker_conninfo_hash {
  my ($self, $hash) = @_;
  my %conninfo = %$hash;
  return \%conninfo if defined $conninfo{dsn};

  my %transport_key = map { $_ => 1 } qw( user password attrs pool_size );
  my $known = _pg_answer_connect_info($hash);
  # An empty dbname names no database: refused, as the sync storage refuses
  # it (core karr k340), not dropped into a DSN without one.
  _pg_refuse('PostgreSQL future_io cannot connect from what the AccessBroker '
    . 'returned: its dbname is an empty dbname, which names no database. Give '
    . 'the database name, or leave dbname out to connect with host and port alone',
    $known)
    if defined $conninfo{dbname} && !ref $conninfo{dbname} && !length $conninfo{dbname};

  my %param;
  for my $key (grep { !$transport_key{$_} } keys %conninfo) {
    my $value = delete $conninfo{$key};
    $param{$key} = $value if defined $value && length $value;
  }

  # A dbname that is a whole DSN is the DSN, as core and dbio-async read it
  # (core ADR 0057) -- not a database of that name. Nothing set beside it can
  # be put into it: where it would go is the DSN's business. Core says so for
  # host and port; here every other parameter would become a part of the DSN
  # as well, so each one is refused in the same words rather than dropped.
  if (defined $param{dbname} && !ref $param{dbname} && $param{dbname} =~ /^dbi:/i) {
    $conninfo{dsn} = delete $param{dbname};
    _pg_refuse('Connection parameter(s) ' . join(', ', map { "'$_'" } sort keys %param)
        . ' given beside a dbname that is a whole DSN: they cannot be put into '
        . 'it. Give them inside the DSN, or give dbname as a database name.',
        $known)
      if %param;
    return \%conninfo;
  }

  # "dbi:Pg:" alone leaves the target to libpq's environment (PGHOST,
  # PGDATABASE, a service file); the sync storage refuses it too.
  _pg_refuse('PostgreSQL future_io cannot connect from what the AccessBroker '
    . 'returned: it names no dbname, host or port, so libpq would take the '
    . 'target from its environment (PGHOST, PGDATABASE, ...). Give at least '
    . 'one of dbname, host or port (or service, hostaddr)',
    $known)
    unless grep { exists $param{$_} } qw(dbname host port hostaddr service);

  my @params;
  for my $key (sort keys %param) {
    # A key is a libpq parameter name: it goes into the DSN as it is, so only
    # the plain form is a key.
    _pg_refuse("PostgreSQL future_io cannot connect from what the AccessBroker returned: "
      . "its connection parameter '$key' is not a libpq parameter name "
      . "(lower case letters, digits and underscores, beginning with a letter "
      . "or an underscore)", $known)
      unless $key =~ /\A[a-z_][a-z0-9_]*\z/;
    _pg_refuse("PostgreSQL future_io cannot connect from what the AccessBroker returned: "
      . "its libpq connection parameter '$key' is a reference, not a value", $known)
      if ref $param{$key};
    # The DSN is a C string from DBD::Pg on: it would end at the NUL, and
    # every parameter sorted behind this one would be gone with it.
    _pg_refuse("PostgreSQL future_io cannot connect from what the AccessBroker returned: "
      . "its libpq connection parameter '$key' contains a NUL character, which "
      . 'no connection string can carry', $known)
      if $param{$key} =~ /\0/;
    push @params, "$key=" . $self->_pg_dsn_value($param{$key});
  }
  $conninfo{dsn} = 'dbi:Pg:' . join ';', @params;
  return \%conninfo;
}

# A libpq parameter value as it goes into a DBD::Pg DSN, so that libpq reads
# back the value it was given (karr k80, k96). The rule -- what libpq and
# DBD::Pg each do to the text, and what is written against it -- is kept in
# DBIO::PostgreSQL::Util::quote_dsn_value, which the sync storage writes
# through as well (DBIO::PostgreSQL::Storage::_connect_params_dsn, karr k102):
# the two connections of one schema get the same DSN for the same parameters.
sub _pg_dsn_value {
  my ($self, $value) = @_;
  return DBIO::PostgreSQL::Util::quote_dsn_value($value);
}

# The shape of a broker's answer, for an error message: types and hash keys,
# never values -- they carry the password.
sub _pg_describe_shape {
  my ($self, $value) = @_;
  return 'nothing (undef)' unless defined $value;
  return 'a plain string' unless ref $value;
  return sprintf 'a hashref with keys (%s)', join ', ', sort keys %$value
    if ref $value eq 'HASH';
  return sprintf 'an arrayref of (%s)', join ', ',
    map { !defined $_ ? 'undef' : ref $_ ? ref($_) . ' ref' : 'string' } @$value
    if ref $value eq 'ARRAY';
  return 'a ' . ref($value) . ' ref';
}

# --- Pool connection lifecycle ----------------------------------------------


sub _create_pool_connection {
  my ($self, $conninfo) = @_;
  return $self->_pg_connect($conninfo);
}

# The one DBI->connect of this transport: a pool connection, and the dedicated
# listen connection (_listen_open). The forced attributes win over the
# caller's; AutoInactiveDestroy among them, so no connection of this transport
# can be ended by a forked child's copy of its handle (karr k79). HandleError
# is forced too, around the caller's (_pg_handle_error): this is where every
# error DBI reports for the handle, and for the connect itself, is raised.
sub _pg_connect {
  my ($self, $conninfo) = @_;

  _pg_refuse('PostgreSQL async conninfo must be a hashref with a dsn',
    _pg_answer_connect_info($conninfo))
    unless ref $conninfo eq 'HASH' && defined $conninfo->{dsn};

  # A whole DSN that names no target leaves it to libpq's environment, as the
  # connection parameters a broker answers do when they name none (karr k121).
  _pg_refuse('PostgreSQL future_io cannot connect with a DSN that names no '
    . 'dbname, host or port, so libpq would take the target from its '
    . 'environment (PGHOST, PGDATABASE, ...). Give at least one of dbname, '
    . 'host or port (or service, hostaddr) in the DSN',
    _pg_answer_connect_info($conninfo))
    if !ref $conninfo->{dsn} && $conninfo->{dsn} =~ /\Adbi:Pg\b/i
      && !DBIO::PostgreSQL::Util::dsn_names_target($conninfo->{dsn});

  my %attrs = %{ $conninfo->{attrs} || {} };
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
      HandleError         => _pg_handle_error($attrs{HandleError}),
    },
  );

  # Never the password in what a failed connect says (karr k111, core k297).
  # DBI's message quotes the DSN it was given; libpq's reason quotes what it
  # could not read -- a URI whole, and the user and password DBD::Pg puts
  # behind it. Both ways a connect fails are raised in here -- DBI's message
  # by the HandleError above, and the connect that answered false because the
  # caller's HandleError took the error -- so one mask covers them, and the
  # stack trace Carp's verbose mode adds to either.
  my ($dbh, $ok, $err);
  {
    local $@;
    $ok = eval {
      $dbh = DBI->connect(@info)
        or _pg_raise("DBD::Pg connect failed: $DBI::errstr");
      1;
    };
    $err = $@;
  }
  die DBIO::Util::mask_connect_secrets($err, \@info) unless $ok;

  return { dbh => $dbh };
}

# The HandleError of every handle this transport opens: _pg_dbi_error. When
# the connect attributes carry one of the caller's, that one is asked first
# and keeps what DBI gives a HandleError -- answering true it has taken the
# error, dying it has replaced it. Anything that is no code is left for DBI to
# refuse.
sub _pg_handle_error {
  my ($theirs) = @_;
  return \&_pg_dbi_error unless defined $theirs;
  return $theirs unless (Scalar::Util::reftype($theirs) // '') eq 'CODE';
  return sub { $theirs->(@_) ? 1 : _pg_dbi_error(@_) };
}

# DBI calls its HandleError with the message it would have died with -- the
# driver and method, "failed:" and the driver's text -- the handle, and what
# the method returned.
sub _pg_dbi_error {
  my ($message, $h) = @_;
  my $dbh = eval { ref $h && $h->{Type} && $h->{Type} eq 'st' ? $h->{Database} : $h };
  return _pg_raise($message, $dbh);
}


sub _pg_raise {
  my ($message, $dbh) = @_;
  $message =~ s/\n\z//;
  $message = _pg_mask_bound($message, $dbh);
  $message = DBIO::PostgreSQL::Util::mask_error_details($message);
  die $Carp::Verbose ? DBIO::Util::masked_longmess($message) : "$message\n";
}

# The values of the statement in flight stand at its handle (BINDS_SLOT), so
# that the HandleError, which knows the handle and nothing else, can take them
# out of the text.
sub _pg_mask_bound {
  my ($message, $dbh) = @_;
  my $binds = eval { ref $dbh ? $dbh->{+BINDS_SLOT} : undef };
  return $message unless ref $binds eq 'ARRAY' && @$binds;
  my $masked = eval {
    DBIO::Util::mask_bound_values($message, $binds, sub { $dbh->quote($_[0]) });
  };
  return defined $masked ? $masked : $message;
}

# The statement is over: the values leave the handle, and the statement handle
# that holds them as its parameters is let go. A statement without values
# leaves its handle where it is (_txn_commit_rolled_back reads a COMMIT's).
sub _pg_forget_binds {
  my ($conn) = @_;
  return unless ref $conn eq 'HASH';
  my $dbh = $conn->{dbh};
  my $held = eval { $dbh ? $dbh->{+BINDS_SLOT} : undef };
  return unless $held;
  eval { $dbh->{+BINDS_SLOT} = undef };
  delete $conn->{sth};
  return;
}


sub _pg_refuse { goto &DBIO::PostgreSQL::Storage::Async::_Refusal::raise }

# The connect info a refusal is about, in the DBI form the trace masks
# (DBIO::Util::masked_longmess): from a conninfo hash, an answer in the DBI
# form, or the hash of a [ \%conninfo, \%opts ] pair. Nothing for anything
# else.
sub _pg_answer_connect_info {
  my ($info) = @_;
  $info = $info->[0] if ref $info eq 'ARRAY' && ref $info->[0] eq 'HASH';
  return [ @{$info}{qw( dsn user password attrs )} ] if ref $info eq 'HASH';
  return [ @{$info}[0 .. 3] ] if ref $info eq 'ARRAY';
  return undef;
}

# Where a refusal is thrown from. DBIO::Exception->throw names the first frame
# that is not this package's, nor of a package the patterns of
# _skip_namespace_frames name (DBIO::Carp): DBIO's own, and here Future's and
# IO::Async's as well -- a refusal reached in a callback of the loop would
# otherwise name Future/PP.pm. %Carp::Internal keeps these frames out of the
# origin the exception names (the transport's method that refused) and out of
# the start of a stack trace.
{
  package # not a class of its own: the place a refusal is thrown from
    DBIO::PostgreSQL::Storage::Async::_Refusal;

  $Carp::Internal{ (__PACKAGE__) }++;

  sub _skip_namespace_frames { '^Future\b|^IO::Async\b' }

  sub raise {
    my ($message, $connect_info) = @_;
    DBIO::Exception->throw($message, $Carp::Verbose, $connect_info);
  }

  # A refusal of a DBIO::PostgreSQL::Util rule, raised again as this
  # transport's. The rule croaks, naming its caller -- the code ref, in this
  # file; Carp's short form is asked for, so that is what comes back, and the
  # refusal is raised again in the rule's words without that place.
  sub of_util {
    my ($code) = @_;
    my ($answer, $ok, $err);
    {
      local $@;
      $ok  = eval { local $Carp::Verbose = 0; $answer = $code->(); 1 };
      $err = $@;
    }
    return $answer if $ok;
    die $err unless !ref $err && $err =~ s/ at \Q${\ __FILE__}\E line \d+[^\n]*\n\z//;
    raise($err);
  }
}


sub _reset_pool_connection {
  my ($self, $conn) = @_;
  return $self->_query_async_pinned($conn, 'DISCARD ALL', [])->then(sub {
    $self->_setup_pool_connection($conn);
    return $self->future_class->done;
  });
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
  $dbh->{+BINDS_SLOT} = @$bind ? [ @$bind ] : undef;

  my $ok = eval {
    my $sth = $dbh->prepare($sql, {
      pg_async                  => PG_ASYNC,
      pg_placeholder_dollaronly => 1,
    });
    $sth->execute(@$bind);
    $conn->{sth} = $sth;
    1;
  };
  my $error = $@;
  unless ($ok) {
    _pg_forget_binds($conn);
    die $error;
  }

  return;
}


sub _collect_result {
  my ($self, $conn) = @_;

  my $future;
  my $ok = eval { $future = $self->_pg_collect($conn); 1 };
  my $error = $@;

  # Waiting for more of the result (the re-poll recurses here) keeps the values
  # for the HandleError; every other end of the statement takes them off.
  _pg_forget_binds($conn) unless $ok && !$future->is_ready;
  die $error unless $ok;
  return $future;
}

sub _pg_collect {
  my ($self, $conn) = @_;

  my $dbh = $conn->{dbh};

  # The result may not have fully arrived on the first readable event. pg_ready
  # consumes what is on the wire and reports whether the result is complete;
  # if not, wait for more and re-check rather than blocking in pg_result.
  unless ($dbh->pg_ready) {
    return $self->_await_readable($conn)->then(sub {
      return $self->_collect_result($conn);
    });
  }

  # Finalise; dies (RaiseError) on a query error and on a lost connection.
  my $sth = $conn->{sth};
  my $rv = $dbh->pg_result;

  # A cancelled statement is the one failure pg_result does not die on: it
  # returns 0E0 and leaves SQLSTATE 57014 as the only trace (see POD).
  _pg_raise("DBD::Pg::db pg_result failed: PostgreSQL cancelled the statement "
    . "(SQLSTATE 57014 query_canceled: statement_timeout or a cancel request; "
    . "DBD::Pg does not pass on the server's message)", $dbh)
    if ($dbh->state // '') eq '57014';

  if (($sth->{NUM_OF_FIELDS} || 0) > 0) {
    my $rows = $sth->fetchall_arrayref;
    return $self->future_class->done(@$rows);
  }

  return $self->future_class->done($rv);
}


sub _txn_commit_rolled_back {
  my ($self, $conn) = @_;
  my $sth = ref $conn eq 'HASH' ? $conn->{sth} : undef;
  return 0 unless $sth;
  return (($sth->{pg_cmd_status} // '') eq 'ROLLBACK') ? 1 : 0;
}


sub _conn_error_is_fatal {
  my ($self, $conn) = @_;
  return $self->_pg_socket_gone($conn);
}

# The one verdict on whether a connection is dead, shared by
# _conn_error_is_fatal and _idle_connection_alive: libpq has no server
# connection open (pg_socket -1, or unknown), or there is no handle at all.
sub _pg_socket_gone {
  my ($self, $conn) = @_;
  my $dbh = ref $conn eq 'HASH' ? $conn->{dbh} : undef;
  return $dbh && ($dbh->{pg_socket} // -1) >= 0 ? 0 : 1;
}


sub _idle_connection_alive {
  my ($self, $conn) = @_;
  return 0 if $self->_pg_socket_gone($conn);

  my $dbh = $conn->{dbh};
  for (1 .. 4) {
    return 1 unless $self->_pg_readable_now($conn);

    my ($ok, $err);
    {
      local $@;
      $ok  = eval { $self->_pg_nonblocking($conn, sub { $dbh->pg_notifies }); 1 };
      $err = $@;
    }
    return 0 if $self->_pg_socket_gone($conn);
    die $err unless $ok;
  }
  return 1;
}

# Is the connection's socket readable right now? A select with a zero timeout,
# on the cached dup of the socket (_conn_poll_fh). A select error counts as
# readable: the read that follows is what finds out.
sub _pg_readable_now {
  my ($self, $conn) = @_;
  my $rin = '';
  vec($rin, fileno($self->_conn_poll_fh($conn)), 1) = 1;
  return select($rin, undef, undef, 0) != 0;
}

# --- LISTEN / NOTIFY seams --------------------------------------------------
#
# Core DBIO::Storage::Async owns the contract and the machinery (ADR 0056);
# DBIO::Async::Storage owns the Future::IO watch loop, the backoff timer and the
# pooled _notify_send (dbio-async ADR 0005). What is left is PostgreSQL's:
# the dedicated DBD::Pg handle, quoted LISTEN / UNLISTEN, the pg_notifies drain,
# the probe and the pg_notify statement. Private helpers are named _pg_*, not
# _listen_*: they share an inheritance chain with core's private _listen_*
# helpers, and a same-named method appearing in core later would be shadowed.


sub _listen_open {
  my ($self) = @_;
  my $provider = $self->_conninfo_provider;
  my $conninfo = $provider ? $provider->() : $self->{_conninfo};
  return $self->future_class->done($self->_pg_connect($conninfo));
}


sub _listen_close {
  my ($self, $conn) = @_;
  my $dbh = delete $conn->{dbh} or return;
  $dbh->disconnect if $dbh->{Active};
  return;
}


sub _listen_subscribe {
  my ($self, $conn, $channel) = @_;
  return $self->_pg_listen_command($conn, LISTEN => $channel);
}


sub _listen_unsubscribe {
  my ($self, $conn, $channel) = @_;
  return $self->_pg_listen_command($conn, UNLISTEN => $channel);
}

sub _pg_listen_command {
  my ($self, $conn, $verb, $channel) = @_;
  my $sql = "$verb " . $self->_pg_quote_channel($channel);
  my $dbh = $conn->{dbh} or _pg_refuse("$verb: the listen connection is closed");
  $self->_pg_nonblocking($conn, sub { $dbh->do($sql) });
  $self->_pg_dispatch_buffered($conn);
  return $self->future_class->done;
}


sub _pg_quote_channel {
  my ($self, $channel) = @_;
  return DBIO::PostgreSQL::Storage::Async::_Refusal::of_util(
    sub { DBIO::PostgreSQL::Util::quote_channel($channel) },
  );
}


sub _listen_drain {
  my ($self, $conn) = @_;
  my $dbh = $conn->{dbh} or _pg_refuse('the listen connection is closed');

  my @drained;
  $self->_pg_nonblocking($conn, sub {
    while (my $n = $dbh->pg_notifies) {
      my ($channel, $sender_pid, $payload) = @$n;
      push @drained, [ $channel, $payload, $sender_pid ];
    }
    _pg_raise('draining the listen connection failed: ' . ($dbh->errstr // 'unknown error'))
      if $dbh->err;
  });
  return \@drained;
}


sub _listen_probe {
  my ($self, $conn) = @_;
  my $dbh = $conn->{dbh} or return 0;
  return 0 unless $self->_pg_nonblocking($conn, sub { $dbh->ping });
  $self->_pg_dispatch_buffered($conn);
  return 1;
}


sub _pg_dispatch_buffered {
  my ($self, $conn) = @_;
  for my $n (@{ $self->_listen_drain($conn) }) {
    last unless $conn->{dbh};
    $self->_listen_dispatch(@$n);
  }
  return;
}


sub _pg_nonblocking {
  my ($self, $conn, $code) = @_;
  my $fh = do { local $@; eval { $self->_conn_poll_fh($conn) } };
  my $was_blocking = $fh ? $fh->blocking(0) : 0;

  my ($r, $ok, $err);
  {
    local $@;
    $ok  = eval { $r = $code->(); 1 };
    $err = $@;
  }
  $fh->blocking(1) if $was_blocking;
  die $err unless $ok;
  return $r;
}


sub _notify_sql {
  my ($self, $channel, $payload) = @_;
  return ('SELECT pg_notify(?, ?)', [ $channel, $payload ]);
}

# --- Deploy seam ------------------------------------------------------------


sub _ddl_class { 'DBIO::PostgreSQL::DDL' }


sub deploy_async {
  my ($self, $schema, @rest) = @_;

  my @declared = DBIO::PostgreSQL::DDL::_schema_decl($schema, 'pg_extensions');
  return $self->SUPER::deploy_async($schema, @rest) unless @declared;

  return $self->_seam_future(_query_async =>
    DBIO::PostgreSQL::DDL::control_schemas_sql(@declared), [],
  )->then(sub {
    my %fixed = map { $_->[0] => $_->[1] } @_;
    DBIO::PostgreSQL::DDL::check_control_schemas($schema, \%fixed);
    return $self->_deploy_async_with_control_schemas($schema, \%fixed, @rest);
  });
}

# The schemas a control file fixes are handed to _install_ddl for the length
# of the synchronous call core's deploy_async makes to it, and no longer: a
# second deploy on the same storage reads its own.
sub _deploy_async_with_control_schemas {
  my ($self, $schema, $fixed, @rest) = @_;
  local $self->{_extension_control_schemas} = $fixed;
  return $self->SUPER::deploy_async($schema, @rest);
}


sub _install_ddl {
  my ($self, $schema) = @_;
  return $self->_ddl_class->install_ddl($schema,
    extension_control_schemas => $self->{_extension_control_schemas} // {});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Storage::Async - future_io async PostgreSQL transport over DBD::Pg's pg_async binding

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The concrete C<future_io> transport adapter for PostgreSQL (core ADR 0030 /
0031). It is resolved B<by convention> off the sync driver storage: a
connection opened with

  MyApp::Schema->connect($dsn, $user, $pass, { async => 'future_io' });

on a L<DBIO::PostgreSQL::Storage> instance derives C<ref($storage) . '::Async'>
== C<DBIO::PostgreSQL::Storage::Async>. No C<register_async_mode> call is
needed; the name itself is the registration.

=head2 Storage extensions ride on top by composition

Under the storage-layer composition model, a PostgreSQL
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

=item * L</_async_broker_conninfo> -- an AccessBroker's connect info into the
same shape, fresh for every new connection (L</AccessBroker>)

=item * L</_create_pool_connection> / L</_shutdown_pool_connection> -- DBD::Pg
handle lifecycle

=item * L</_conn_ready> / L</_conn_fileno> -- readiness + the C<pg_socket> fd
for the L<Future::IO> watcher

=item * L</_submit_query> / L</_collect_result> -- send non-blocking, then
gather once the wire is readable

=item * L</_conn_error_is_fatal> -- whether a failed statement took its
connection with it, so the pool retires it

=item * L</_idle_connection_alive> -- whether an idle pool connection's session
is still there before the pool hands it out, so one whose backend ended while
it sat idle is retired instead

=item * L</_txn_commit_rolled_back> -- whether PostgreSQL answered a
transaction's C<COMMIT> with C<ROLLBACK>

=item * L</_reset_pool_connection> -- C<DISCARD ALL> and the connect actions
again when a borrow ends, so the session of one borrow is its own

=item * L</_ddl_class> -- the DDL generator L<DBIO::Storage::Async/deploy_async>
installs from

=back

The transaction-context seams are not among them:
C<_txn_context_class> and C<_txn_conn_accessor> answer with the C<future_io>
transport's own defaults (L<DBIO::Async::Storage>) -- the
L<DBIO::Async::TransactionContext> under the key C<txn_conn>, which is exactly
what this transport wants -- so it names them nowhere and would only do so for
a different context class or constructor key.

A connection is represented as a small hashref C<< { dbh => $dbh, sth => $sth } >>:
the DBD::Pg database handle plus the statement handle of the in-flight async
query. There is at most one per connection at a time: the pool lends a
connection to one borrower, and on a pinned connection (a transaction's) the
base sends a statement only once the one before it has settled
(L<DBIO::Async::Storage/THE PINNED STATEMENT QUEUE>). Pinning alone does not
give that -- two statements issued on a transaction context without awaiting
the first would otherwise share the connection.

For LISTEN/NOTIFY this class fills the PostgreSQL half of the listen seams
(see L</LISTEN / NOTIFY>):

=over 4

=item * L</_listen_open> / L</_listen_close> -- the dedicated listen
connection

=item * L</_listen_subscribe> / L</_listen_unsubscribe> -- quoted
C<LISTEN> / C<UNLISTEN>, each followed by a drain of what libpq buffered

=item * L</_listen_drain> -- C<pg_notifies>, in contract order, never blocking

=item * L</_listen_probe> -- the liveness ping

=item * L</_notify_sql> -- C<SELECT pg_notify(?, ?)>

=back

=head2 The session of a borrow

A pool connection serves one borrow at a time -- a statement, a transaction
or a pipeline -- and the session of a borrow is its own. When a borrow ends,
L</_reset_pool_connection> runs C<DISCARD ALL> on the connection and then the
connect actions again (C<search_path> and C<LOAD> of the connection's schema
and extensions, C<on_connect_do>, C<on_connect_call>); only then is the
connection given to the next borrower. A reset that fails, or takes longer than
C<reset_timeout>, retires the connection and the next borrower gets a fresh one.

The reset covers settings of the session (C<set_config(..., false)>, C<SET>,
C<SET ROLE>, C<SET SESSION AUTHORIZATION>), temporary tables, prepared
statements, cursors, C<LISTEN> registrations and the session-level advisory
locks, which C<DISCARD ALL> releases. Inside a transaction, C<set_config(...,
true)> and C<SET LOCAL> end with it as before.

=head2 Transport capabilities

L</transport_capabilities> declares what L<DBIO::Async::Storage> declares --
C<on_connect_replay>: the pool replays the owning sync storage's
C<on_connect_do> / C<on_connect_call> on every freshly-spawned connection --
plus C<listen> and C<notify> (L</LISTEN / NOTIFY>), the names the native C<ev>
transport uses for the same contract, and C<broker_connect_options>: the
connect options given beside an AccessBroker reach every connection this
transport opens (L</AccessBroker>).

Two PostgreSQL wire features stay on the native C<ev> backend
(L<DBIO::PostgreSQL::EV::Storage>, dist C<dbio-postgresql-ev>) and are B<not>
declared here:

=over 4

=item * B<pipelining> (L<DBIO::Storage::Async/pipeline>) -- DBD::Pg's async
binding exposes no libpq pipeline mode, so the pipeline seams stay core's
croaking defaults.

=item * B<COPY> -- asynchronous C<COPY> is C<ev>-only. (C<COPY> on the sync
driver is a separate matter.)

=back

An async storage layer that declares C<required_transport_capabilities> for
either of them fails loud (core capability gate) when composed over this
C<future_io> transport, naming the missing capability -- never a silent
feature loss.

=head2 AccessBroker

Every built-in L<DBIO::AccessBroker> works on this transport:
L<DBIO::AccessBroker::Static>, L<DBIO::AccessBroker::Vault> and a
L<DBIO::AccessBroker::HostBound> view over either. The broker is asked for its
current connect info whenever a connection is opened -- each new pool
connection, and the listen connection at its first C<listen> and at every
reconnect -- so rotated credentials apply from the next connection on. What
it answers is turned into a C<< DBI->connect >> by
L</_async_broker_conninfo>, which lists the shapes it takes.

  # on the future_io backend ($schema->storage->async) directly
  $async->connect_info([ DBIO::AccessBroker::Static->new(
    host => 'db1', dbname => 'app', username => 'app', password => $pw,
  ) ]);

  # or through the schema: a Vault broker carries the mode in its DBI attributes
  my $schema = MyApp::Schema->connect(DBIO::AccessBroker::Vault->new(
    vault     => $vault,
    dsn       => 'dbi:Pg:dbname=app;host=db1',
    cred_path => 'database/creds/app',
    dbi_attrs => { async => 'future_io' },
  ));

  # or through the schema, with the connect options beside the broker
  my $schema = MyApp::Schema->connect($static_broker, {
    async             => 'future_io',
    pool_size         => 10,
    pg_server_prepare => 0,
  });

The options beside the broker (core ADR 0030 addendum) are taken
here because this transport declares C<broker_connect_options>
(L</transport_capabilities>). C<pool_size> sizes the pool -- core's
L<DBIO::Storage::Async/connect_info> does that, with
L<DBIO::Storage::Async/_access_broker_pool_size> -- and every other DBD
attribute is merged into the attributes of each connection opened from the
broker's answer, pool and listen connection alike (L</_async_broker_conninfo>).
A setting given both beside the broker and in its answer must have the same
value in both, or the connection is refused, naming the setting. What the
owning sync storage applies itself -- C<async>, C<on_connect_do>, the SQL maker
options -- never reaches C<< DBI->connect >>.

=head2 LISTEN / NOTIFY

C<listen>, C<unlisten>, C<notify>, C<listen_alive> and C<listen_reconnect> are
core async API (core ADR 0056), the same contract on every async transport
that declares C<listen> / C<notify>, and documented once in
L<DBIO::Storage::Async/"LISTEN / NOTIFY">. Core owns the channel registry, the
one dedicated listen connection, reconnect with backoff, re-subscribing every
channel and the fork guard; L<DBIO::Async::Storage> owns the L<Future::IO>
watch loop, the backoff timer and the pooled C<notify>. This class supplies
the PostgreSQL seams listed above. They are reached through the async backend
of a C<future_io> connection:

  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'future_io' });
  my $async  = $schema->storage->async;

  $async->on_listen_error(sub {
    my ($storage, $error) = @_;   # every error; without a hook it is warned
    $log->warn("listen: $error");
  });
  $async->on_listen_reconnect(sub {
    my ($storage) = @_;           # rebuilt, every channel subscribed again
    $log->info('listen connection rebuilt -- re-read what may have been missed');
  });
  $async->listen_backoff_initial(0.5);   # reconnect backoff, seconds
  $async->listen_backoff_max(30);        # (defaults 1 and 30)

  $async->listen(jobs => sub {
    my ($channel, $payload, $sender_pid) = @_;
    ...
  })->get;                               # resolves once LISTEN is in effect

  $async->notify(jobs => 'wake up')->get;   # on a pooled connection
  $async->unlisten('jobs')->get;

  # an external watchdog
  $async->listen_reconnect->get unless $async->listen_alive;

C<$sender_pid> is the PostgreSQL backend pid of the notifying session.
C<listen_alive> is true while the listen connection is set up and answers a
ping; a failed ping starts self-healing at once. C<on_listen_reconnect> fires
after a B<rebuild>, not for the first connection.

=over 4

=item * B<Delivery> is PostgreSQL's: a notification arrives when the sending
transaction commits, and it is not durable -- whatever was sent while the
listen connection was down is gone, which is what C<on_listen_reconnect> is
for. There is no NULL payload: C<< notify($channel) >> arrives as C<''>. The
listen connection's socket is watched from the event loop, and notifications
are delivered from there. libpq also buffers notifications that arrive while
the listen connection runs a synchronous statement -- its own C<LISTEN> /
C<UNLISTEN> or the ping behind C<listen_alive> -- and those are delivered
right after that statement, so a callback can run from inside C<listen>,
C<unlisten> or C<listen_alive> too.

=item * B<Channel names> are PostgreSQL identifiers, sent quoted: exact and
case-sensitive, any character but NUL, at most 63 bytes in UTF-8. A longer
name is refused, not truncated (L</_pg_quote_channel>): C<listen> fails its
Future and the channel is dropped. The server limits a payload to less than
8000 bytes; C<notify> fails its Future beyond that.

=item * B<The listen connection blocks briefly.> It is a synchronous DBD::Pg
handle, opened with a blocking C<< DBI->connect >> like every pool
connection: its connect (at the first C<listen> and on each reconnect), each
C<LISTEN> / C<UNLISTEN> and the C<listen_alive> ping hold the event loop for
one round trip. Against a host that stops answering without closing the
connection, a round trip lasts until the TCP timeout; bound it with libpq
parameters in the DSN (C<connect_timeout>, C<keepalives_idle>,
C<tcp_user_timeout>).

=item * B<Fork safety.> Every connection of this transport -- the listen
connection, and the pooled ones C<notify> runs on -- is opened with
C<< AutoInactiveDestroy => 1 >> (L</_create_pool_connection>), and core never
touches them outside the process that opened them. A child that forks off a
listening parent and exits -- global destruction and all -- leaves the
parent's LISTEN session and its pooled sessions intact. A child that wants
notifications itself calls C<listen> and gets its own connection.

=back

B<The IO::Async loop.> With L<Future::IO::Impl::IOAsync>, L<Future::IO>
watches the listen socket on the loop C<< IO::Async::Loop->new >> returns --
the process-wide magic singleton -- which the implementation fetches the first
time it needs a loop and keeps. A program that builds its loop with a
subclass constructor, C<< IO::Async::Loop::EV->new >> say, holds that same
loop only if it built it before anything asked for the singleton; otherwise
it runs a second loop while the socket is watched on the first, which nothing
runs, and notifications silently never arrive. Build the program's loop
through C<< IO::Async::Loop->new >> and choose the implementation with
C<IO_ASYNC_LOOP=EV> in the environment (or C<$IO::Async::Loop::LOOP = 'EV'>
before the first construction).

=head1 METHODS

=head2 transport_capabilities

  my @caps = DBIO::PostgreSQL::Storage::Async->transport_capabilities;
  # ('on_connect_replay', 'listen', 'notify', 'broker_connect_options')

Class method (L<DBIO::Storage::Async/transport_capabilities>): the inherited
list plus C<listen> and C<notify>, the capability names core's LISTEN/NOTIFY
gate asks for (core ADR 0056 section 2), and C<broker_connect_options>, the
promise core asks for before it hands this transport the connect options given
beside an AccessBroker (L</AccessBroker>). Not C<copy>, not
C<pipeline> -- see L</Transport capabilities>.

=head2 sql_maker_class

The L<DBIO::PostgreSQL::SQLMaker> subclass used to generate SQL.

=head2 _sql_maker_args

PostgreSQL SQLMaker construction args: the identifier quoting of the
connection, and the LIMIT/OFFSET dialect.

The quoting is not decided here. C<quote_char> and C<name_sep> are taken from
the SQL maker of the owning sync storage (L<DBIO::PostgreSQL::Storage/sql_maker>,
which is core's rule), so both paths of one connection quote alike: nothing
given quotes with C<"> and separates with C<.>, C<< quote_names => 0 >> alone
or an empty C<quote_char> alone writes identifiers unquoted, and an explicit
C<quote_char> or C<name_sep> is used as given. A backend without
an owning sync storage -- constructed on its own, not through
C<< connect(..., { async => 'future_io' }) >> -- quotes with C<"> and C<.>,
the defaults of L<DBIO::PostgreSQL::Storage>: core takes the quoting options
out of the connect info it hands a backend.

=head2 _transform_sql

  my $positional = $storage->_transform_sql($sql);

Transport-internal SQL shaping (L<DBIO::Storage::Async/_transform_sql>, ADR
0032): number every C<?> placeholder as PostgreSQL's positional
C<$N>, left to right, so they line up with the bind values. The inherited
query seams call it first (L<DBIO::Async::Storage/_query_async>,
L<DBIO::Async::Storage/_query_async_pinned>); a caller of those hands over SQL
in the C<?> dialect and never shapes it itself.

It delegates to L<DBIO::PostgreSQL::Util/number_placeholders>, where the rule
lives and is documented in full. In short: a C<?> is a placeholder where
PostgreSQL reads SQL. A C<?> inside a string or quoted identifier, an escape
string C<E'...'> with its backslashed quotes, a dollar-quoted body
(C<$$...$$>, C<$tag$...$tag$>) or a comment (C<-- ...>, C</* ... */>, nested
ones too) is text and stays as it is, so literal SQL that runs over the
schema's dbh runs over this transport with the same binds. Everywhere else a
C<?> is a placeholder, behind an operator character too (C<< <@? >>, C<@@?>,
C<@?>). This is the server's reading, which the sync driver's L<DBD::Pg> does
not match in four forms (a nested comment, a lower case C<e'...'>, a carriage
return ending a C<--> comment, a C<$> inside an identifier); a statement with
one of them can be read differently on the two ways, see
L<DBIO::PostgreSQL::Util/Where DBD::Pg reads less than the server>.
C<\?> is a literal question mark and the backslash goes: the jsonpath
operator, which the SQL maker writes C<@\?>, reaches the server as C<@?>.
C<$N> already in the statement passes through, and a C<$N> beside a C<?>
placeholder is refused, as is an undefined statement or a reference: in the
function's words, as a refusal of this transport's that names the caller's
place (L</_pg_refuse>, L</ERRORS>). A statement is shaped once: shaping it
again changes nothing as long as it holds no C<\?>, whose C<?> is a
placeholder to a second pass.

A C<?> inside C<'...'>, C<"...">, a dollar-quoted body, a comment or an
C<E'...'> string (behind its backslashed quote too) is passed over, not
numbered. Numbered, a dollar-quoted body without a bind would reach the
server changed -- C<$1> where its C<?> had been -- and with a bind L<DBD::Pg>
would refuse the statement: it looks for no placeholder in a body or a
comment, so the first one it saw would be the statement's own, numbered
C<$2> (I<"Invalid placeholders: must start at $1 and increment one at a
time">), or it would count none at all (I<"called with 1 bind variables when
0 are needed">).

B<DBD::Pg reads the numbered statement once more.> This transport does not
hand it to the server itself: L</_submit_query> prepares it with
C<pg_placeholder_dollaronly>, and DBD::Pg then looks for the C<$N> by a
scanner of its own, which in places reads less than the server does. Measured
with DBD::Pg 3.20.2 against PostgreSQL 18.6: it does not nest C</* ... */>,
takes neither a lowercase C<e'...'> nor the continuation of an C<E'...'>
string on the next line for an escape string, does not end a C<--> comment at
a carriage return, and takes a C<$> inside an identifier (C<a$b$>) for the
start of a dollar quote. The numbering holds the server's reading all the
same. Where the difference hides a C<$N> from DBD::Pg, or shows it one that is
text, DBD::Pg refuses the statement before it is sent, with one of the two
messages above; it passes a C<$N> on as it finds it, so such a statement never
runs with other binds. The schema's dbh refuses or misreads the same
statements. The native C<ev> transport hands the statement to libpq and has no
second reading.

=head2 _post_insert_sql

Returns C< RETURNING *> so an INSERT yields every populated column (autoinc PK
+ retrieve-on-insert defaults); the inherited runner folds the row onto the
supplied data to build the returned-columns hashref (ADR 0031 §3).

=head2 _normalize_conninfo

  my $info = $storage->_normalize_conninfo([ 'dbi:Pg:...', $user, $pass, \%attrs, \%extra ]);

Convert the sync storage's DBI-form connect info into the C<[ \%conninfo,
\%opts ]> pair the pool consumes, carrying the DSN / user / password / attrs
straight through for L</_create_pool_connection> to hand to C<< DBI->connect >>.
The attributes are C<\%attrs> and the optional fifth element
C<\%extra_attributes> merged, the later winning -- as the sync storage merges
them (L<DBIO::Storage::DBI/connect_info>), so an attribute given in either
reaches every pooled connection. The DBIO-private keys of both are
gone by then: core strips them before this seam
(L<DBIO::Storage::Async/connect_info>). A C<pool_size> attribute, if present,
is lifted into the conninfo hash (the inherited normaliser strips it back out
to size the pool). Broker-style or
already-normalised info is passed through untouched; what a broker answers is
read by L</_async_broker_conninfo>.

=head2 _async_broker_conninfo

  my $conninfo = $storage->_async_broker_conninfo($mode);
  # { dsn => 'dbi:Pg:dbname=app;host=db1', user => ..., password => ..., attrs => {...} }

AccessBroker seam (L<DBIO::Storage::Async/_async_broker_conninfo>), called for
every new pool connection and for every open of the listen connection
(L</_listen_open>): ask the attached broker for its current connect info --
anew each time, so rotated credentials reach the next connection -- and turn
it into the conninfo hash L</_create_pool_connection> connects from. The
broker's answer may come in any of these shapes:

=over 4

=item * B<A DBI-form arrayref> C<< [ 'dbi:Pg:...', $user, $password, \%attrs ] >>,
as L<DBIO::AccessBroker::Vault> answers, and L<DBIO::AccessBroker::HostBound>
over it. Read exactly like DBI-form connect info (L</_normalize_conninfo>),
after the DBIO-private attributes -- C<async>, C<quote_char> and the rest --
are stripped from C<\%attrs> the way core strips them from a direct connect.
That matters here: a Vault broker gets onto this transport through
C<< MyApp::Schema->connect($vault) >> with C<< dbi_attrs => { async => 'future_io' } >>,
and C<async> is no DBD::Pg attribute.

=item * B<A hashref of libpq connection parameters>, as
L<DBIO::AccessBroker::Static> answers (C<dbname>, C<host>, C<port>, C<user>,
C<password>), and L<DBIO::AccessBroker::HostBound> over it. C<user> and
C<password> become the C<< DBI->connect >> user and password; every other key
with a value becomes a C<key=value> part of a C<dbi:Pg:> DSN, which DBD::Pg
hands to libpq as it is -- so any libpq parameter works (C<sslmode>,
C<connect_timeout>, ...). Parts without a value are left out, and the parts are
sorted by name (C<dbname>, C<host>, C<port>). The keys this transport's own
shape uses (C<attrs>, C<pool_size>) keep their meaning.

A key is a libpq parameter name: lower case letters, digits and underscores,
beginning with a letter or an underscore. Any other key is refused, naming
it.

Without C<sslmode> libpq connects with C<prefer>, and a server that does not
offer TLS is then connected to in the clear. For a connection over a network
answer C<< sslmode => 'verify-full' >> with C<sslrootcert> naming the
certificate authority; C<verify-full> checks the certificate and the host
name.

At least one of C<dbname>, C<host>, C<port>, C<hostaddr> and C<service> must be
given: without one the DSN would be C<dbi:Pg:> and libpq would take the target
from its environment (C<PGHOST>, C<PGDATABASE>), so the credentials would go
where the environment says. C<service> and C<hostaddr> name a target
themselves and are enough. Anything else is refused, naming the parameters and
never a value; the sync storage, which writes only C<dbname>, C<host> and
C<port>, refuses the same.

A value is a value, whatever is in it: libpq reads back what the broker
answered. Each one is written by L<DBIO::PostgreSQL::Util/quote_dsn_value>,
where the rule is kept and explained: a value containing whitespace, C<;>,
C<'>, C<\>, C<=> or C<"> goes in single-quoted, with C<'>, C<\> and C<=>
escaped by a backslash; any other goes in as it is. So a
database name given in double quotes keeps them -- C<< dbname => '"app"' >> is
the database C<"app">, not C<app>; the DBD::Pg way of quoting a name belongs
into a DSN, not into a value. The sync storage writes C<dbname>, C<host> and
C<port> through the same function
(L<DBIO::PostgreSQL::Storage/_connect_params_dsn>), so for a
broker that answers these three both halves of a schema hold the same DSN.
One difference is core's: it refuses a C<;> in a value before the sync
storage is asked for the DSN (core ADR 0057), where this transport writes it
quoted. A value with a NUL character is refused, naming the parameter and
never the value: no connection string can carry it, and written out it would
end the DSN there, the parameters behind it lost.

A C<dbname> that starts with C<dbi:> is the DSN, taken as it is -- the way
L<DBIO::AccessBroker::Static> is given a whole DSN, and the way the sync
storage reads it (core ADR 0057), so a schema's sync storage and its
C<future_io> backend open the same database. Nothing set beside it
can be put into it: C<host> and C<port>, which core refuses there, and every
other parameter that would otherwise become a part of the DSN (C<sslmode>,
...) croak in core's words, naming the keys and never a value. A parameter
without a value is as none given, and C<user>, C<password>, C<attrs> and
C<pool_size> keep their meaning.

=item * B<A hashref in this transport's own shape> -- with a C<dsn>, plus
C<user>, C<password> and C<attrs> -- taken as it is. A broker written for this
transport answers in it.

=item * Either hashref as the first half of a C<< [ \%conninfo, \%opts ] >>
pair.

=back

The DBD attributes given beside the broker
(L<DBIO::Storage::Async/_access_broker_call_attributes>, see L</AccessBroker>)
are then merged into the connection's attributes, whichever shape the answer
came in -- the attributes of every shape are DBD attributes here -- with
C<_merge_access_broker_settings> (L<DBIO::Storage>): a setting given in both
places must have the same value, or this throws naming the setting, and
nothing is connected.

The answer is read through L<DBIO::Storage::Async/_current_async_connect_info>,
so a broker that answers nothing -- C<undef>, an empty hash or array, a false
value -- is refused there, naming the broker class and the shape:
an empty hash would otherwise become the DSN C<dbi:Pg:>, and libpq would
connect with its environment defaults. Anything else this transport cannot
connect from is refused, naming the shape it received -- never the values,
which carry the password.

Without a broker attached it is refused saying so (L</ERRORS>), as
L<DBIO::Async::Storage/_async_broker_conninfo> does. The provider
core installs outlives a broker detached through
L<DBIO::Storage/clear_access_broker> -- on the storage, where L</_listen_open>
asks it, and in a pool built with it -- and what is stored in the broker's
place then is no broker's answer: no connection is opened from it, and it is
not reported as one.

=head2 _create_pool_connection

  my $conn = $storage->_create_pool_connection(\%conninfo);

Open one DBD::Pg handle via C<< DBI->connect >> and wrap it as
C<< { dbh => $dbh } >>. C<AutoCommit> is on: the inherited orchestration drives
transactions with explicit C<BEGIN> / C<COMMIT> / C<ROLLBACK> on the pinned
connection, so DBD::Pg's own transaction tracking stays out of the way.

The handle is opened with C<< AutoInactiveDestroy => 1 >>, whatever the connect
attributes say: a forked child that drops its copy of the handle --
at its exit, say -- must not send PostgreSQL the terminate message that would
end the parent's pooled session. The pool itself never touches its connections
outside the process that opened them
(L<DBIO::Storage::PoolBase/_verify_pid>); the handle's own C<DESTROY> is this
transport's half.

A connect that fails is reported without its password: the
message goes through core's C<DBIO::Util::mask_connect_secrets> with the
connect info it is about, as core's own connect does
(L<DBIO::Storage::DBI>). Otherwise it is DBI's message --
C<< DBI connect('...','user',...) failed: >> and libpq's reason -- or, when
C<< DBI->connect >> answered false because a C<HandleError> among the connect
attributes took the error, C<DBD::Pg connect failed:> and libpq's reason. The
listen connection (L</_listen_open>) is opened the same way, so the same
holds for what its failed connect hands the C<listen> Future and
C<on_listen_error>, on every reconnect attempt again.

The handle raises its errors through L</_pg_raise>, and so does the connect
itself: what a failed connect or statement says is its text, without a file
and a line of this library (see L</ERRORS>).

=head2 _pg_raise

  _pg_raise($message);
  _pg_raise($message, $dbh);

Die with C<$message> and a newline -- the one place an error of DBI's, of
DBD::Pg's or of the server's is raised on this transport (see L</ERRORS>): a
failed statement, a failed connect, a statement the server cancelled. A
function, not a method. The transport's own refusals are raised by
L</_pg_refuse>.

With the database handle the statement failed on, the text first loses the
values bound to that statement (core's C<DBIO::Util/mask_bound_values>: each
value whole, also as C<< $dbh->quote >> writes it), then the forms of the
server's text (L<DBIO::PostgreSQL::Util/mask_error_details>) -- the order of
the sync storage's C<_mask_error_values>. The values are those
L</_submit_query> put on the handle for the statement in flight; a handle
without any (a statement without binds, a connect) leaves the text to the
forms alone.

Under L<Carp>'s verbose mode (C<$Carp::Verbose>, C<perl -MCarp=verbose>) it
dies with the message and a stack trace instead, as C<croak> does: whoever
asks for the frames gets them. The trace is core's
L<DBIO::Util/masked_longmess>, so a password among the arguments of a frame
(a DSN, the connect info) is shown as C<***>.

=head2 _pg_refuse

  _pg_refuse($message);
  _pg_refuse($message, [ $dsn, $user, $password, \%attrs ]);

Throw a refusal of this transport's own -- what it refuses to do with what
the caller gave it (see L</ERRORS>) -- as a L<DBIO::Exception>, the way core
throws its own: C<< Some::method(): $message at FILE line N >>, where the
place is the caller's (maintainer's decision 2026-10-16). A
function, not a method.

The place is found as L<DBIO::Exception/throw> finds it, through
L<DBIO::Carp>: the first frame outside DBIO -- and outside L<Future> and
L<IO::Async>, whose frames stand between the caller and a refusal reached in a
callback of the event loop. So it is the caller's line whether the caller
called into the transport itself, went through the pool, or ran the loop in
which the refusal was reached. A loop of another library names the frame of
that library that ran the callback.

Under L<Carp>'s verbose mode the exception carries a stack trace instead, the
one L<DBIO::Exception/throw> writes with core's L<DBIO::Util/masked_longmess>.
The connect info given is handed to it, so a password the refused answer
holds is masked where a frame repeats it, as a password among the arguments
of a frame always is.

=head2 _reset_pool_connection

  my $future = $storage->_reset_pool_connection($conn);

The reset of a pool connection at the end of a borrow (core's seam,
L<DBIO::Storage::Async/_reset_pool_connection>, ADR 0079): C<DISCARD ALL>,
then the connect actions again (L<DBIO::Storage::Async/_setup_pool_connection>:
the connection's C<search_path> and extension C<LOAD>, C<on_connect_do>,
C<on_connect_call>). The connection goes to the next borrower only after both,
and a failure of either retires it. There is no way to switch it off.

C<DISCARD ALL> ends everything the session of one borrow holds: settings
(C<set_config(..., false)>, C<SET>, C<SET ROLE>, C<SET SESSION AUTHORIZATION>,
the session's isolation level), temporary tables, prepared statements, cursors,
C<LISTEN> registrations, sequence state (C<currval>, C<lastval>) and the
session-level advisory locks, which it releases. The connect actions then set
the session up as a fresh connect does.

=head2 _shutdown_pool_connection

Disconnect the DBD::Pg handle held by C<$conn>.

=head2 _conn_ready

True once the connection can accept queries. C<< DBI->connect >> is a blocking
connect, so a handed-out connection is ready immediately. The check is only
that C<$conn> holds a handle DBI still counts as C<Active>, i.e. one nobody
has disconnected. It does B<not> tell whether the server connection is still
there: DBD::Pg leaves C<Active> true on a lost connection. Whether an idle
connection's session is still there is L</_idle_connection_alive>'s question,
asked before this one; a connection that died past that check is found out by
the next statement sent on it, which fails and retires it
(L</_conn_error_is_fatal>).

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
literal C<?> (the one of the JSONB C<@?> operator, written C<@\?> before the
numbering) alone.

A failure here -- DBD::Pg refusing the statement, or the send failing -- dies
with DBI's message and nothing behind it (L</ERRORS>), and the query Future
fails with it (L<DBIO::Async::Storage/_await_query_result>
runs this inside C<< Future->call >>). The base then asks
L</_conn_error_is_fatal>, so a connection that turns out to be gone is retired
rather than reused.

=head2 _collect_result

  my $future = $storage->_collect_result($conn);

Called once the socket is readable. Takes the connection and nothing else: the
SQL and the bind arrayref were consumed by L</_submit_query> at dispatch and
must not outlive it (ADR 0044), which is why
L<DBIO::Async::Storage/_collect_on_readable> forwards only C<$conn> and why the
re-poll below recurses the same way.

If the async result has not fully arrived (C<< $dbh->pg_ready >> is false) it
waits for the socket again -- through L<DBIO::Async::Storage/_await_readable>,
the one seam that touches L<Future::IO> -- and re-checks, so a large result
spanning several reads is handled correctly. The in-flight statement handle it
needs is on C<$conn>, put there by L</_submit_query>; carrying the SQL and the
binds into that re-poll callback instead would pin the caller's bind arrayref
alive for as long as the result keeps arriving. Once ready it finalises with
C<< $dbh->pg_result >> and resolves:

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

C<pg_ready> and C<pg_result> die on a failed statement, and on a lost
connection, with DBI's message and the server's text (L</ERRORS>); the die
fails the query Future, and the base then asks
L</_conn_error_is_fatal>, so a connection that is gone is retired rather than
reused.

One failure C<pg_result> does B<not> die on: a statement PostgreSQL
cancelled -- C<statement_timeout>, C<pg_cancel_backend>, a cancel request --
which fails with SQLSTATE C<57014> (C<query_canceled>). DBD::Pg answers that
one with C<0E0>, sets no C<err> and no C<errstr>, and leaves only
C<< $dbh->state >> at C<57014>; the server's message is dropped. This is
DBD::Pg's documented contract for its own C<pg_send_cancel>, and it applies to
every cancellation alike (C<pg_db_result> in F<dbdimp.c>; measured on
PostgreSQL 18.6 / DBD::Pg 3.20.2). The sync path is not affected -- a blocking
C<execute> raises. So after C<pg_result> the state is read, and C<57014> fails
the statement with an error naming the SQLSTATE; before, a cancelled
statement resolved as a success with no rows. C<pg_result> sets the state from
every result it reads, a successful one included, so it is this statement's
own and never left over from an earlier one. A cancelled statement leaves the
connection usable -- its socket stays open, so L</_conn_error_is_fatal> answers
false -- and it goes back to the pool.

=head2 _txn_commit_rolled_back

  my $rolled_back = $storage->_txn_commit_rolled_back($conn, @commit_result);

Core transport seam (L<DBIO::Storage::Async/_txn_commit_rolled_back>): true
when PostgreSQL answered the transaction's C<COMMIT> with the command tag
C<ROLLBACK>. That is its answer, not an error, when a statement in the
transaction failed and aborted it -- a statement core never saw fail, because
it was sent on the pinned connection past the transaction context. Core then
fails the transaction with I<"COMMIT was answered with ROLLBACK: ...">.

The tag is the C<pg_cmd_status> attribute of the C<COMMIT>'s statement handle,
which L</_submit_query> left on C<$conn>. C<@commit_result> cannot carry it:
it is C<pg_result>'s row count, C<0E0> for C<COMMIT> and for its C<ROLLBACK>
answer alike, and the database handle's C<pg_cmd_status> stays undef on an
async statement (both measured on PostgreSQL 18.6 / DBD::Pg 3.20.2). Core asks
from the success callback of the C<COMMIT>'s Future, and the base's statement
queue sends the next statement on the connection only after that callback has
run -- nothing is sent on the connection in between, so the handle on C<$conn>
is the C<COMMIT>'s own. A connection without
a statement handle is taken at its word, core's default.

=head2 _conn_error_is_fatal

  my $dead = $storage->_conn_error_is_fatal($conn, $error);

Driver seam of L<DBIO::Async::Storage/_conn_error_is_fatal>: did the statement
that just failed on the connection C<$conn> take the connection with it? The
base asks it for every failed query Future of
L<DBIO::Async::Storage/_query_async> and
L<DBIO::Async::Storage/_query_async_pinned> -- whether L</_submit_query>,
C<pg_ready> or C<pg_result> died, or L</_collect_result> failed a cancelled
statement -- and on a true answer reports C<$conn> to the pool
(L<DBIO::Storage::PoolBase/_mark_connection_dead>), so the release that
follows retires it instead of putting it back. The pool cannot see a
connection die by itself: without the report a dead handle goes back to the
idle list and every caller it is handed to fails the same way. A transaction's
pinned connection is covered alike, since core hands it back through the same
release once the transaction has ended.

Dead means libpq has no server connection open any more: DBD::Pg's
C<pg_socket> (libpq's C<PQsocket>) is C<-1>, or C<$conn> holds no handle at
all. libpq drops the socket on every path where it concludes the connection is
lost -- end of file (a terminated backend, a server restart), a read or write
error, lost protocol sync -- and never on a statement error the session
survives. That is the verdict of the library that owns the connection;
C<$error> is not read, and nothing is sent: no round trip, so the event loop is
never held. C<< $dbh->{Active} >> does not tell -- DBD::Pg leaves it true on a
lost connection -- and C<pg_ping> would, but costs a blocking round trip on
every ordinary statement error. Measured on PostgreSQL 18.6 / DBD::Pg 3.20.2:
C<pg_socket> is C<-1> after C<pg_terminate_backend> (idle or in flight), on a
handle that is already dead and on a disconnected one, and unchanged after a
syntax error, a division by zero, a bind error, an error inside a transaction
and a cancellation (C<statement_timeout>, C<pg_cancel_backend>: SQLSTATE
C<57014>) -- so a cancelled statement keeps its connection.

A connection whose backend died while it sat idle in the pool still shows an
open C<pg_socket>: libpq learns of the death only when it next reads from the
socket. That read is L</_idle_connection_alive>'s, before the pool hands the
connection out, so such a connection is normally retired without a statement
failing on it. What this seam still sees is a connection that died after that
check, or without the server saying so (a network partition): its statement
fails, the connection is retired with it, and the call after it gets a fresh
one.

The listen connection never reaches this seam: its statements run
synchronously (L</_listen_subscribe>, L</_listen_probe>, L</_listen_drain>),
not through the query path, and core heals it on its own.

=head2 _idle_connection_alive

  my $alive = $storage->_idle_connection_alive($conn);

Driver seam of L<DBIO::Async::Storage/_idle_connection_alive>: is the server
session behind the idle pool connection C<$conn> still there? Core's pool asks
it every time it is about to hand out an idle connection
(L<DBIO::Storage::PoolBase/acquire>); on a false answer it retires C<$conn>
and takes the next idle connection or a fresh one, so a backend that ended
while its connection sat idle -- C<pg_terminate_backend>, a server restart,
C<idle_session_timeout> -- no longer costs a caller a failed statement first.

C<pg_socket> alone cannot tell. libpq notices a lost connection only when it
reads from the socket, and nothing reads from an idle pool connection: after
C<pg_terminate_backend> on an idle backend, C<pg_socket> stays open and
C<Active> stays true until the next read. What the server does leave is on the
socket. Ending a session, it sends a C<FATAL> error message and closes, so the
socket turns readable -- and an idle connection has no statement in flight,
so nothing else is due on it. So the check is:

=over 4

=item 1. C<pg_socket> below zero, or no handle: dead (the verdict of
L</_conn_error_is_fatal>).

=item 2. The socket is not readable, by a C<select> with a zero timeout:
alive. The common case, and all it costs.

=item 3. Readable: let libpq read what arrived -- one C<pg_notifies>, which
runs C<PQconsumeInput> -- and give the verdict of step 1 again. Repeated while
the socket stays readable, at most four reads.

=back

Why read instead of taking readable as dead: a PostgreSQL server also writes
to a live idle session. A notification on a channel the session C<LISTEN>s to
arrives at once, and it leaves the socket readable exactly like a dying
session's last message; taking readable as dead would throw such a connection
away on every borrow. Reading tells the two apart. Measured on PostgreSQL 18.6
/ libpq 17 / DBD::Pg 3.20.2, idle backend terminated with
C<pg_terminate_backend> and gone from C<pg_stat_activity>: C<pg_socket>
unchanged, socket readable; the first read takes the C<FATAL> message --
libpq handles an error that arrives while idle as a notice -- and answers
nothing, the socket is still readable (the end of file behind it); the second
read dies with "server closed the connection unexpectedly", and C<pg_socket>
is C<-1>. Over TLS the same two reads, the second dying with "SSL connection
has been closed unexpectedly": the verdict is the socket's, never
the wording's. A connection that received a notification: readable, one read
consumes it, not readable any more, socket open -- alive. Two reads are what a
session the server ended takes; the bound of four only keeps a connection that
goes on receiving, which is a live one, from holding the acquire.

It never blocks and never sends. The zero-timeout C<select> does not wait;
C<PQconsumeInput> sends nothing and reads only what the socket holds, with the
socket in C<O_NONBLOCK> mode for the read (L</_pg_nonblocking>) -- the same
guarantee the listen drain relies on (L</_listen_drain>). No C<ping>, no
C<pg_ping>: both are round trips.

A read that dies because the connection is gone is the answer, not a failed
check: false, and core retires the connection quietly. A read that dies while
the socket stays open is not understood here, and is rethrown; core then
retires the connection all the same and reports the error to the pool's
C<on_error>.

Two side effects of the read, both of which the next statement's read would
have had anyway:

=over 4

=item * The dying session's C<FATAL> message reaches DBD::Pg as a notice, which
it warns (unless the handle's C<PrintWarn> is off) -- now from the acquire, as
the one trace of why the connection was retired.

=item * A notification a pool connection received is taken off libpq's queue
and dropped. A pool connection is not a listen connection: this transport runs
C<LISTEN> only on the dedicated listen connection (L</_listen_open>) and never
reads a notification from a pool connection, so one there -- possible only if
the application ran C<LISTEN> on pool connections itself, in C<on_connect_do>
say -- was never going to be delivered.

=back

It narrows the window; it does not close it. A backend can die after the
check, or without the server saying so (a network partition, a host gone);
the statement sent on it fails, and L</_conn_error_is_fatal> retires the
connection as before.

=head2 _listen_open

  my $f = $storage->_listen_open;   # done with { dbh => $dbh }

Core listen seam (L<DBIO::Storage::Async/_listen_open>): open the dedicated
listen connection -- a B<new> DBD::Pg handle, never one from the pool. Its
connect info is what a pool spawn would get at this moment: fresh credentials
through L<DBIO::Storage::Async/_conninfo_provider> when an AccessBroker is
attached (so rotated credentials apply exactly as they do to the pool),
otherwise the static conninfo. A provider whose broker has been detached
opens nothing: L</_async_broker_conninfo> throws. The connect shape is the
pool's (L</_create_pool_connection>: C<AutoCommit>, C<RaiseError>, no C<PrintError>,
C<< AutoInactiveDestroy => 1 >>). The last one, set at connect time, matters
most here: a forked child that exits, and so destroys its inherited copy of the
handle, must never send PostgreSQL the terminate message that would end the
parent's LISTEN session.

The handle is synchronous (no C<pg_async>): it only ever runs C<LISTEN>,
C<UNLISTEN> and the probe's ping, and is otherwise watched for readability.
The pool's C<on_connect_do> / C<on_connect_call> replay is B<not> run on it --
none of those statements concern listening, and a session-setup statement
with side effects should not run once more per reconnect.

Resolves with C<< { dbh => $dbh } >>, the shape of a pool connection, so the
inherited L</_conn_fileno>, L<DBIO::Async::Storage/_conn_poll_fh> and
L<DBIO::Async::Storage/_await_readable> work on it unchanged. A failed
connect throws, which core reports and heals from.

=head2 _listen_close

  $storage->_listen_close($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_close>): disconnect the listen
handle and take it off C<$conn>. A dead connection is fine -- DBD::Pg's
C<disconnect> does not fail on one -- and a connection already closed is left
alone. Core has stopped the watch (L<DBIO::Async::Storage/_listen_unwatch>)
first, and never calls this in a process other than the one that opened the
connection.

=head2 _listen_subscribe

  my $f = $storage->_listen_subscribe($conn, $channel);

Core listen seam (L<DBIO::Storage::Async/_listen_subscribe>): run
C<LISTEN "channel"> on the listen connection. The channel is validated and
quoted as an identifier (see L</_pg_quote_channel>), never interpolated raw
(ADR 0017 section 3, as restated by core ADR 0056). A channel it refuses makes
the seam throw; core then finds the connection alive, drops the channel and
fails its L<DBIO::Storage::Async/listen> Future with the reason.

Right after the statement it drains and dispatches what libpq buffered during
the round trip (see L</_pg_dispatch_buffered>): a notification that arrived
while the synchronous C<LISTEN> waited for its reply sits in libpq's buffer,
and the socket never becomes readable for it again.

=head2 _listen_unsubscribe

  my $f = $storage->_listen_unsubscribe($conn, $channel);

Core listen seam (L<DBIO::Storage::Async/_listen_unsubscribe>): C<UNLISTEN>,
with the same validation, quoting and drain as L</_listen_subscribe>. Core has
already dropped the channel from its registry, so a notification for it that
the drain turns up is discarded; the other channels' are delivered.

=head2 _pg_quote_channel

  my $sql_ident = $storage->_pg_quote_channel($channel);   # "jobs"

Validate a channel name and quote it as a PostgreSQL identifier: wrapped in
double quotes, embedded C<"> doubled. Quoting makes the name exact -- case
included -- which is also how C<pg_notify> (the L</_notify_sql> statement)
takes it, so C<listen('Jobs')> and C<notify('Jobs')> meet.

Refused, by throwing: an undefined, empty or reference channel, one
containing a NUL byte, and one longer than 63 bytes in UTF-8 (PostgreSQL's
C<NAMEDATALEN> - 1). The length limit is a refusal, not a truncation, because
a longer name can never deliver: C<LISTEN> would silently truncate it and then
report notifications under the truncated name, which matches no registered
channel, and C<pg_notify> rejects it outright ("channel name too long").

The rule itself lives in L<DBIO::PostgreSQL::Util/quote_channel>, a public
helper the native C<ev> transport can load as well; this method delegates to
it. The helper croaks, which blames its caller -- this file. A
refusal is raised again in the helper's words as a refusal of this
transport's, naming the caller's place (L</_pg_refuse>).

=head2 _listen_drain

  my $notifications = $storage->_listen_drain($conn);
  # [ [ $channel, $payload, $sender_pid ], ... ]

Driver seam of the L<DBIO::Async::Storage> watch loop
(L<DBIO::Async::Storage/_listen_drain>): every notification pending on the
listen connection, in arrival order, as C<[$channel, $payload, $sender_pid]>
-- DBD::Pg's C<pg_notifies> answers C<[$channel, $sender_pid, $payload]>, and
the tuple is reordered into the contract's order here. An empty arrayref when
nothing is pending.

Each C<pg_notifies> call runs libpq's C<PQconsumeInput>, which reads what the
socket holds without waiting for more, then C<PQnotifies>. It dies:

=over 4

=item * on a dead connection, and at end of file -- C<PQconsumeInput> fails
("server closed the connection unexpectedly", over TLS "SSL connection has
been closed unexpectedly", then "connection not open") and
DBD::Pg raises it under the handle's C<RaiseError>. A server that terminates
the backend first sends its C<FATAL> message, which one drain consumes as a
notice and answers C<[]> for; the end of file behind it keeps the socket
readable, so the next drain dies. Either way the loop never spins on a closed
socket.

=item * on an error DBD::Pg recorded without raising it (a caller-supplied
C<HandleError> that swallowed it), as a second line of defence.

=item * on a connection L</_listen_close> already closed.

=back

It never blocks. libpq's socket must be in C<O_NONBLOCK> mode for
C<PQconsumeInput> to return when the socket runs dry -- libpq reads a second
time on its own once more than 32 kB are buffered -- and C<O_NONBLOCK> lives
on the open file description that the watch loop's C<dup> of the socket shares.
L<Future::IO>'s built-in implementation clears it on that dup while its poll
callbacks run, which is exactly when a drain happens. So every libpq read on
the listen connection runs with C<O_NONBLOCK> set and the previous mode
restored afterwards (L</_pg_nonblocking>).

=head2 _listen_probe

  my $alive = $storage->_listen_probe($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_probe>), asked by
L<DBIO::Storage::Async/listen_alive> and after a failed channel operation:
DBD::Pg's C<ping>, a synchronous empty-query round trip, false on a dead
connection. Like L</_listen_subscribe> it drains and dispatches afterwards
what libpq buffered during that round trip, so a callback may run from inside
C<listen_alive>.

=head2 _pg_dispatch_buffered

  $storage->_pg_dispatch_buffered($conn);

Deliver what a synchronous statement on the listen connection left in libpq's
buffer: L</_listen_drain>, then
L<DBIO::Storage::Async/_listen_dispatch> for each notification, in order. A
channel callback that ends the connection (unlistening the last channel,
C<listen_reconnect>) stops the batch there -- nothing is dispatched for a
connection core has closed, just as the watch loop stops.

=head2 _pg_nonblocking

  my $r = $storage->_pg_nonblocking($conn, sub { $dbh->ping });

Run the code with the connection's socket in C<O_NONBLOCK> mode -- the
mode libpq assumes -- and put the previous mode back afterwards, whether the
code returned or died. Used for every libpq read on the listen connection, and
for the read L</_idle_connection_alive> makes on an idle pool connection. The
flag is set through the watch loop's cached dup of
the socket (L<DBIO::Async::Storage/_conn_poll_fh>), which shares it with
libpq's own descriptor; see L</_listen_drain> for why. A connection whose
socket is already gone (C<pg_socket> is C<-1>) is left as it is: libpq fails
on it at once instead of blocking.

=head2 _notify_sql

  my ($sql, $bind) = $storage->_notify_sql($channel, $payload);
  # ('SELECT pg_notify(?, ?)', [ $channel, $payload ])

Driver seam of L<DBIO::Async::Storage/_notify_send>, which runs the statement
on a pooled connection through L<DBIO::Async::Storage/_query_async> -- where
L</_transform_sql> turns the C<?>s into C<$1, $2>. Channel and payload travel
B<only> as bind values, never in the SQL (ADR 0017 section 3). PostgreSQL has
no NULL payload: C<pg_notify> sends an C<undef> payload as the empty string,
and a listener receives C<''>. The server refuses a channel over 63 bytes and a
payload of 8000 bytes or more; the Future of
L<DBIO::Storage::Async/notify> fails with its message.

=head2 _ddl_class

The class L<DBIO::Storage::Async/deploy_async> asks for the install DDL, via
C<< _ddl_class->install_ddl($schema) >> -- L<DBIO::PostgreSQL::DDL>, the very
class the sync L<DBIO::PostgreSQL::Deploy> and the native C<ev> backend
(L<DBIO::PostgreSQL::EV::Storage>) name. One generator for all three paths, so
C<< $storage->deploy_async($schema) >> and C<< $deploy->install >> put
byte-identical DDL on the wire; a second generator here could only drift.

Without it the inherited C<deploy_async> croaks (core leaves the seam abstract,
because a backend that cannot deploy must say so rather than deploy something
else).

=head2 deploy_async

    my $future = $storage->deploy_async($schema, \%opts);

Core's L<DBIO::Storage::Async/deploy_async>, behind one question to the
server. The schema of a C<CREATE EXTENSION> is, as in
L<DBIO::PostgreSQL::Deploy>, the declared one, else the one the control file of
the extension fixes, else C<public> -- and the control file is the server's
to tell. So before the DDL is built, a pooled connection is asked
(asynchronously, no second blocking connection) for the schemas the control
files of the extensions the schema class declares fix
(L<DBIO::PostgreSQL::DDL/control_schemas_sql>), a declared schema other than a
fixed one is refused with the Future failed, before any statement of the DDL
(L<DBIO::PostgreSQL::DDL/check_control_schemas>), and the answer reaches
L</_install_ddl> as C<extension_control_schemas>. An extension with a fixed
schema (C<age>, C<postgis_topology>, ...) is thus written without the
C<WITH SCHEMA> clause the server would refuse. A schema that declares no
extension, or no schema class with the PostgreSQL component, asks nothing.

=head2 _install_ddl

The install script (core's C<_install_ddl>, which asks the generator without
options), with the control schemas L</deploy_async> read from the server passed
to L<DBIO::PostgreSQL::DDL/install_ddl> as C<extension_control_schemas>.

=head1 ERRORS

An error of the database's is a plain string: its text and a newline. A
refusal of this transport's own is a L<DBIO::Exception> that names the
caller's place. Either reaches the caller as the failure of the Future -- of
a statement, of C<txn_do_async>, of C<listen> or C<notify> -- or as what a
direct call dies with, and as the argument of C<on_listen_error>, unchanged or
behind core's words for where it happened (C<opening the listen connection
failed: ...>; core's words make a string of the exception).

=over 4

=item * B<A statement the server refuses> fails with DBI's message: the
method that collected it, C<failed:>, and the server's text as libpq gives it,
C<DETAIL>, C<HINT>, the C<LINE> and its position marker included.

  DBD::Pg::db pg_result failed: ERROR:  duplicate key value violates unique constraint "users_pkey"
  DETAIL:  Key (id)=(1) already exists.

A statement L<DBD::Pg> refuses before it is sent reads C<DBD::Pg::st execute
failed: ...>, and so does one on a connection that is gone.

The text names no value the statement was run with. Of a statement with bound
values every value of four characters or more is replaced by C<***> whole,
also where the server reads it as a name (C<relation "***" does not exist>),
and then the forms of the server's text are masked
(L<DBIO::PostgreSQL::Util/mask_error_details>), for a statement of the pool,
of a transaction's pinned connection and of C<_query_async> alike. The values
are at the connection's database handle (C<private_dbio_binds>) from
L</_submit_query> until the statement is over; a result, an error and a failed
send take them, and the statement handle that holds them, off again (ADR 0044).

=item * B<The SQLSTATE> is not in that text and never was. It is on the
DBD::Pg handle the statement ran on (C<state>), which a caller holds only for
a pinned connection -- a transaction context's C<txn_conn>. The one failure
that names its SQLSTATE is a statement the server cancelled (C<57014>,
L</_collect_result>), because that is all DBD::Pg passes on of it.

=item * B<A connection that cannot be opened> fails with DBI's
C<< DBI connect('...','user',...) failed: >> and libpq's reason, its password
masked (L</_create_pool_connection>).

=item * B<A refusal of the transport> -- what it refuses to do with what the
caller gave it -- is a L<DBIO::Exception>, the way core throws its own: the
transport's method that refused, one sentence saying what was refused, and
the caller's file and line (L</_pg_refuse>, maintainer's decision
2026-10-16).

  DBIO::PostgreSQL::Storage::Async::_pg_quote_channel(): LISTEN channel name '...' is 64 bytes long; ... at app.pl line 12

These are: no AccessBroker attached to ask; a broker answer of a shape it
cannot connect from, with an empty C<dbname>, with parameters beside a
C<dbname> that is a whole DSN, or with a parameter that is a reference or
holds a NUL character; connect info that is no hash with a C<dsn>; a channel
name L<DBIO::PostgreSQL::Util/quote_channel> refuses; a listen connection that
is closed; and a statement L<DBIO::PostgreSQL::Util/number_placeholders>
refuses -- none at all, or C<$N> beside a C<?>. The place is the caller's
whether the caller called into the transport itself, went through the pool,
or ran the event loop in which the refusal was reached.

=back

None of the errors of the database's names a file and a line. Under
C<RaiseError> DBI raises an error itself and adds the place that called it,
and every call into DBI is made from this file, so a statement would fail with
C<< ... at <where DBIO is installed>/DBIO/PostgreSQL/Storage/Async.pm line
946. >> -- a path that says where the library lives and a line that moves with
every release, neither of them about the statement. So every handle this
transport opens carries a C<HandleError> that raises the error instead (the
one C<< DBI->connect >> in C<_pg_connect>; it covers the connect itself, the
pool connections and the listen connection), through L</_pg_raise>. A
C<HandleError> among the caller's connect attributes is not replaced: it is
asked first and keeps what DBI gives one -- answering true it has taken the
error, dying it has replaced it. This transport depends on its statements
raising, so a C<HandleError> that takes errors is the caller's risk, as it
was.

Whoever asks L<Carp> for stack traces (C<$Carp::Verbose>,
C<perl -MCarp=verbose>) gets the text followed by the trace, for every one of
these -- a refusal as a L<DBIO::Exception> still. A failed connect and the
transport's refusals always did; an error DBI raised on an open handle did
not, because DBI raises those from C. The frames are written by
C<DBIO::Util::masked_longmess>: a password in the arguments of a frame is not
shown, nor, for a refusal, the password of the connect info it refused.

Not raised here, and in the form of who raises it: what core says about a
transaction or the listen machinery (L<DBIO::Exception> objects -- I<COMMIT
was answered with ROLLBACK>, an unsupported capability), what
L<DBIO::Async::Storage> says about a statement abandoned in flight, and what
DBD::Pg croaks directly while it reads a statement (I<Invalid placeholders:
must start at $1 ...>, which names no place either).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
