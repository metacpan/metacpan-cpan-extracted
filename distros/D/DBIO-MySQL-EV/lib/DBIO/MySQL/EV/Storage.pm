package DBIO::MySQL::EV::Storage;
# ABSTRACT: Async MySQL/MariaDB storage driver using EV::MariaDB

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::Async';

use Carp 'croak';
use Scalar::Util ();
use DBIO::Util ();
use DBIO::Carp;
use DBIO::MySQL::SQLMaker;
use DBIO::MySQL::DDL ();
use DBIO::MySQL::Identifier ();
use DBIO::MySQL::NotifyTable;
use DBIO::MySQL::Util ();
use DBIO::MySQL::EV::ConnectInfo ();
use DBIO::MySQL::EV::Future;
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


sub future_class { 'DBIO::MySQL::EV::Future' }


sub transport_capabilities {
  qw(on_connect_replay listen notify broker_connect_options)
}

# --- LISTEN / NOTIFY configuration --------------------------------------------



__PACKAGE__->mk_group_accessors(inherited => qw(
  notify_table notify_poll_interval notify_lookback notify_retention
  rollback_wait_timeout
));
__PACKAGE__->rollback_wait_timeout(30);
{
  my %defaults = DBIO::MySQL::NotifyTable->defaults;
  __PACKAGE__->notify_table($defaults{table});
  __PACKAGE__->notify_poll_interval($defaults{poll_interval});
  __PACKAGE__->notify_lookback($defaults{lookback});
  __PACKAGE__->notify_retention($defaults{retention});
}


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
    # The single-hash form { dsn, user, password, pool_size, <attributes> }
    # (karr k79), read as the owning sync storage reads it: every key but those
    # and a nested attrs hash is a connect attribute. dsn and async never reach
    # EV::MariaDB->new. A blessed hash is a broker; a hash with a dbh_maker is
    # not a DSN's.
    elsif (ref $info eq 'ARRAY' && @$info == 1 && ref $info->[0] eq 'HASH'
        && !Scalar::Util::blessed($info->[0]) && defined $info->[0]{dsn}
        && !exists $info->[0]{dbh_maker}) {
      my %h = %{ $info->[0] };
      my ($dsn, $user, $pass) = delete @h{qw( dsn user password )};
      my $nested = delete $h{attrs};
      $info = DBIO::MySQL::EV::ConnectInfo::dbi_to_conninfo([
        $dsn, $user, $pass, { %h, ref $nested eq 'HASH' ? %$nested : () },
      ]);
    }
    # A truthy connect_info setter always opens a new ownership generation
    # (ADR 0045 section 4). disconnect performs the token rotation when a pool
    # or a listen connection exists; without either we still rotate here,
    # exactly as the inherited base connect_info does, so a context from the
    # old generation cannot survive reconfiguration. The listen connection goes
    # through disconnect too: it was opened with the old connect info and would
    # go on running with it (karr k65, core k90).
    if ($self->{pool} || $self->{_listen}) {
      $self->disconnect;
    }
    else {
      $self->_rotate_context_owner_token;
    }
    # [ $broker, \%options ]: the connect options the owning sync storage was
    # given beside the broker, handed on because this transport declares
    # broker_connect_options (core k243, karr k59). Read as core's connect_info
    # reads them: what the owner applies itself (async, the storage and SQL
    # maker options) is stripped, the rest is split into pool_size and the DBD
    # attributes. Undef for every other form, which is left as it came.
    my $stripped = $self->_strip_private_connect_attrs($info);
    my $beside   = $self->_access_broker_call_options($stripped);
    $info = $stripped if $beside;

    $self->{connect_info} = $info;

    if ($beside || $self->_is_access_broker_connect_info($info)) {
      $self->_setup_access_broker($info->[0]);
      # No conninfo is kept with a broker attached, as in core's connect_info
      # (core k252): every connection asks the broker anew (_conninfo_provider),
      # so a stored copy could only ever be this earlier answer -- password
      # included -- which nothing may use. Dropped before the answer is read:
      # a refused answer must not leave the connect info of before in place.
      $self->{_conninfo} = undef;
      # What stands beside the broker, kept where core's accessor answers for
      # it and never applied: this transport drops DBD attributes, as
      # dbi_to_conninfo does for a DSN. A connection parameter among them is
      # not dropped but refused (karr k78) -- here, before the broker is asked,
      # and for every connection after (_async_broker_conninfo), which is why
      # they are kept before anything can throw: a storage whose connect_info
      # was refused opens no connection without the parameter.
      $self->{_access_broker_call_attributes} = $beside ? $beside->{attributes} : {};
      $self->_mysql_refuse_parameters_beside_broker;
      my $answer = $self->_current_async_connect_info($self->access_broker_mode);
      my (undef, $pool_size, $opts) = $self->_normalize_async_connect_info(
        $self->_mysql_broker_connect_info($answer)
      );
      # One rule for the pool size wherever it is given -- the answer's hash,
      # slot [3] or [4] of a DBI-form answer, beside the broker; the answer and
      # the options beside the broker must agree, or this throws (core k245).
      my $given_pool_size = $self->_access_broker_pool_size($answer, $beside);
      $pool_size = $given_pool_size if defined $given_pool_size;
      $self->{_pool_size} = $pool_size;
      $self->{_opts}      = $opts;
    }
    else {
      $self->_clear_access_broker;
      my ($conninfo, $pool_size, $opts) = $self->_normalize_async_connect_info($info);
      # A whole DSN as the database name of a hash (karr k80): no DSN is read
      # out of a hash, so it would be the name of the database and the host it
      # names would not be given. The refusal of the broker's answer, for the
      # connect info given directly; nothing of the DSN is said, it may carry
      # a password.
      croak 'MySQL ev cannot connect from the connect info: '
          . $self->_mysql_describe_shape(ref $info->[0] eq 'HASH' ? $info->[0] : $info)
          . ' whose database name is a whole DBI DSN -- a hash is read as '
          . 'EV::MariaDB parameters and no DSN is read out of one. Give the DSN '
          . 'as the connect info itself ([ $dsn, $user, $password ] or '
          . '{ dsn => $dsn, user => ..., password => ... }), or the database '
          . 'name as dbname with host and port beside it'
        if ref $conninfo eq 'HASH'
          && grep { defined($_) && !ref($_) && /^dbi:/i } map { $conninfo->{$_} } qw( database db );
      $self->{_conninfo}  = $conninfo;
      $self->{_pool_size} = $pool_size;
      $self->{_opts}      = $opts;
      $self->{_access_broker_call_attributes} = {};
    }
  }
  return $self->{connect_info};
}


sub _async_broker_conninfo {
  my ($self, $mode) = @_;

  # Without a broker core's seam answers what connect_info stored. That is no
  # broker's answer, so it is not read as one.
  croak 'MySQL ev has no AccessBroker attached to ask for connect info'
    unless $self->access_broker;
  $self->_mysql_refuse_parameters_beside_broker;

  my ($conninfo) = $self->_normalize_async_connect_info(
    $self->_mysql_broker_connect_info($self->_current_async_connect_info($mode))
  );
  return $conninfo;
}

# Croaks when a connection parameter stands beside the broker (karr k78): a
# key of what connect_info kept from [ $broker, \%options ] that is set to a
# value and is, by its name, no DBI attribute. The measure is core's for a
# broker's hash answer and for the options beside one (core k298 / k307,
# DBIO::Storage::DBI::AccessBroker::_access_broker_unapplied_parameters): a
# DBI attribute starts with an uppercase letter, with private_, dbi_ or dbd_,
# or with the prefix of the DBD -- mysql_ or mariadb_ here: this transport
# stands beside either DBD and is not told which, so both count; undef and the
# empty string name no parameter. What the owner applies itself and pool_size
# are gone from the hash by now. No list of EV::MariaDB parameters is kept: a
# lowercase name that is no DBI attribute cannot be told from one, and the
# ones EV::MariaDB does not know would make its constructor croak if they were
# handed on. Names only, sorted -- a value may be a secret (password), and
# nothing is said of the broker's answer, which has not been asked for.
sub _mysql_refuse_parameters_beside_broker {
  my ($self) = @_;
  my $beside = $self->_access_broker_call_attributes;
  my @unapplied = sort grep {
    defined $beside->{$_} && length $beside->{$_}
      && !/^(?:[A-Z]|private_|dbi_|dbd_|mysql_|mariadb_)/
  } keys %$beside;
  return unless @unapplied;

  croak sprintf
    'MySQL ev does not apply connection parameter(s) given beside an '
  . 'AccessBroker (%s): its pooled connections and the listen connection are '
  . "opened from the broker's answer alone, and would be opened without %s. "
  . "Give %s in the broker's answer: the DBI form "
  . "[ 'dbi:mysql:...;<parameter>=...' or 'dbi:MariaDB:...;<parameter>=...', "
  . '$user, $password ] with the parameter in the DSN, or a hash of EV::MariaDB '
  . 'connection parameters answered to this transport '
  . '(connect_info_for_storage). Beside the broker it takes pool_size, and DBI '
  . 'attributes, which are for the DBI connection of the owning storage and '
  . 'dropped here',
    join(', ', @unapplied), (@unapplied > 1 ? 'them' : 'it') x 2;
}

# What the broker answered, in any shape _async_broker_conninfo lists, as the
# [ \%conninfo, \%opts ] pair _normalize_async_connect_info splits. A bare
# hashref has already been made that pair by _current_async_connect_info. The
# one place this transport reads a broker's answer: at attach and for every
# connection, so what is refused here never reaches EV::MariaDB.
sub _mysql_broker_connect_info {
  my ($self, $info) = @_;
  my ($pair, $shape);

  if (ref $info eq 'ARRAY') {
    my ($first, $opts) = @$info;
    if (defined $first && !ref $first && $first =~ /^dbi:([^:]*):/i) {
      # The driver's name alone, as DBI reads it. What stands before the
      # second colon is more than that: DBI takes attributes there, Password
      # among them ('dbi:mysql(Password=>...):'), and a DSN gone wrong may
      # have its parameters there (karr k76).
      my ($driver) = $1 =~ /^(\w*)/;
      # dbi_to_conninfo dies quoting the DSN -- its passwords masked since
      # karr k76, the rest as it came -- and this message names the shape of
      # an answer and nothing that was in it.
      my $refused;
      $pair = do {
        local $@;
        my $got = eval { DBIO::MySQL::EV::ConnectInfo::dbi_to_conninfo($info) };
        # A refusal of the connect info (karr k64, k80) names keys, never
        # values, and says what is wrong better than the shape would.
        $refused = $1 if !$got && $@ =~ /^MySQL ev refuses the connect info: (.*?)\n?\z/s;
        $got;
      };
      $shape = defined $refused ? "a DBI-form arrayref: $refused"
             : 'a DBI-form arrayref whose DSN is not dbi:mysql:<parameters> or '
             . "dbi:MariaDB:<parameters> (DBI driver '$driver')"
        unless $pair;
    }
    elsif (ref $first eq 'HASH' && @$info <= 2 && (!defined $opts || ref $opts eq 'HASH')) {
      $pair = $info;
    }
  }

  if ($pair) {
    # Read from the parameters as the pool and the listen connection hand them
    # over, so the two cannot differ.
    my ($conninfo) = $self->_normalize_async_connect_info($pair);
    my $described  = $self->_mysql_describe_shape(ref $info->[0] eq 'HASH' ? $info->[0] : $info);

    # A whole DSN where the name of the database belongs (karr k63):
    # DBIO::AccessBroker::Static->new(dbname => 'dbi:mysql:...'), the form
    # core's sync storage takes as the DSN. The answer is still a hash, read
    # here as EV::MariaDB parameters -- the DSN would be the database's name
    # and the host it names would not be given, so EV::MariaDB would connect
    # to the client library's default, the local server, with the broker's
    # user and password. Refused whatever stands beside it: a host bound in by
    # a HostBound view is not the one the DSN names either. Told by the form,
    # 'dbi:' in front; nothing of the DSN is said, it may carry a password.
    if (grep { defined($_) && !ref($_) && /^dbi:/i } @{$conninfo}{qw( database db )}) {
      $shape = "$described whose database name is a whole DBI DSN -- a hash is "
             . 'read as EV::MariaDB parameters and no DSN is read out of one, so '
             . 'the connection would be opened without the host the DSN names. '
             . 'Have the broker answer the DSN in the DBI form '
             . '[ $dsn, $user, $password ], or the database name as dbname with '
             . 'host and port beside it';
    }
    # EV::MariaDB->new starts a connect only when given a host or a user.
    # Given neither, its handle stays unconnected and calls back neither
    # on_connect nor on_error, so the acquire waiting for it would never
    # resolve. The test is the pool's, shared with static connect info
    # (karr k66).
    elsif (DBIO::MySQL::EV::Pool->_mysql_connectable($conninfo)) {
      return $pair;
    }
    else {
      $shape = "$described, which names neither a host nor a user -- "
             . 'EV::MariaDB opens no connection without one of them';
    }
  }

  croak sprintf
    'MySQL ev cannot connect from what the AccessBroker returned: %s. '
  . "It takes a DBI-form arrayref [ 'dbi:mysql:...' or 'dbi:MariaDB:...', "
  . '$user, $password, \\%%attrs ], a hashref of EV::MariaDB connection '
  . 'parameters (host, port, database, user, password, ...), or an arrayref '
  . 'of such a hashref, optionally followed by an options hashref',
    $shape // $self->_mysql_describe_shape($info);
}

# The shape of a broker's answer, for an error message: types and hash keys,
# never values -- they carry the password.
sub _mysql_describe_shape {
  my ($self, $value) = @_;
  return 'nothing (undef)' unless defined $value;
  return 'a plain string' unless ref $value;
  return 'an empty hashref' if ref $value eq 'HASH' && !%$value;
  return sprintf 'a hashref with keys (%s)', join ', ', sort keys %$value
    if ref $value eq 'HASH';
  return sprintf 'an arrayref of (%s)', join ', ',
    map { !defined $_ ? 'undef' : ref $_ ? ref($_) . ' ref' : 'string' } @$value
    if ref $value eq 'ARRAY';
  return 'a ' . ref($value) . ' ref';
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
  return $conninfo;
}


sub pool {
  my $self = shift;
  $self->{pool} ||= do {
    my %args = (
      storage      => $self,
      size         => $self->{_pool_size},
      future_class => $self->future_class,
      # No password in the warning (karr k76). What a connection reports is
      # masked where its handle is made; this is for whatever else the pool
      # reports here.
      on_error     => sub { warn DBIO::Util::mask_connect_secrets("DBIO::MySQL::EV pool error: $_[0]\n") },
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

# Lazily-built query executor. The executor is the MySQL wire seam: it hides
# EV::MariaDB's query-vs-prepare/execute split (query() takes no binds), closes
# every statement it prepares (karr k45) and keeps the async bind-clearing
# contract (karr k11). It is deliberately NOT bound to the
# pool -- every execute() is handed the connection to run on (pooled or pinned),
# so the executor holds no connection state and building it never forces the
# lazy pool into existence. Held on the storage so a caller that pre-wires
# { pool, executor } (the offline facade tests) keeps its own instance.
sub _executor {
  my $self = shift;
  return $self->{executor} ||= DBIO::MySQL::EV::QueryExecutor->new(
    future_class => $self->future_class,
    error_masker => \&_mysql_mask_error,
  );
}


sub _mysql_mask_error {
  my ($text, $values, $sql) = @_;
  return $text unless defined $text && !ref $text;

  my $masked = eval {
    DBIO::Util::mask_bound_values(
      DBIO::MySQL::Util::mask_error_details($text, $values, $sql),
      $values,
    );
  };
  return defined $masked ? $masked : $text;
}

# --- Transaction context seams ------------------------------------------------


sub _txn_context_class { 'DBIO::MySQL::EV::TransactionContext' }


sub _txn_conn_accessor { 'txn_conn' }

# --- Async deploy seam --------------------------------------------------------


sub _ddl_class { 'DBIO::MySQL::DDL' }


sub _ddl_quote_ident { DBIO::MySQL::Identifier::quote_ident($_[1]) }

# --- SQL shaping seam ---------------------------------------------------------


sub _transform_sql { $_[1] }

# --- Async query execution (transport seams) ----------------------------------


sub _query_async {
  my ($self, $sql, $bind, $bind_attrs) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  # The pool this statement begins on is the one it ends on (karr k90).
  my $pool = $self->pool;
  # The wait for the pool is held until it is done (core k407): Future.pm
  # holds a then-sequence only weakly from the Future it waits on, so a caller
  # that drops it while the pool is full would lose the chain.
  return $self->_hold_derived($pool->acquire->then(sub {
    my $conn = shift;
    # A dispatch without a Future must still release $conn (karr k50, k61): as
    # a failed Future it takes the same on_ready release as any other outcome.
    my $f = $self->_seam_future(_await_query_result => $conn, $sql, $bind, $bind_attrs);
    $f->on_ready($self->_release_on_ready($conn, $pool, $pool->_lease($conn)));
    return $self->_mysql_caller_future($f);
  }));
}


sub _mysql_caller_future {
  my ($self, $dispatch) = @_;
  return $dispatch unless $dispatch->can('without_cancel');
  return $dispatch->retain->without_cancel;
}


sub _await_query_result {
  my ($self, $conn, $sql, $bind, $bind_attrs) = @_;
  return $self->_mysql_execute($conn, $sql, $bind, undef, $bind_attrs);
}


sub _mysql_execute {
  my ($self, $conn, $sql, $bind, $dispatch, $bind_attrs) = @_;
  $dispatch //= 'execute';

  my $end = $self->_debug_query($sql, $bind, $bind_attrs);
  my $f;
  unless (eval { $f = $self->_dispatch_to_executor($dispatch, $conn, $sql, $bind); 1 }) {
    my $err = $@;
    $end->() if $end;
    $self->_mysql_report_if_gone($conn);
    die $err;
  }
  # An executor that answers no Future is _seam_future's to name (karr k61).
  $f->on_fail($self->_mysql_report_gone_cb($conn))
    if Scalar::Util::blessed($f) && $f->can('on_fail');
  _mysql_trace_end($end, $f);
  return $f;
}

# query_end of the core trace (_debug_query), once the statement's Future is
# ready, done or failed. $end is undef when nothing is traced. A named sub
# holding the coderef alone, never the bind values (ADR 0044).
sub _mysql_trace_end {
  my ($end, $f) = @_;
  return unless $end;
  return $f->on_ready($end)
    if Scalar::Util::blessed($f) && $f->can('on_ready');
  $end->();
  return;
}

# $dispatch: an executor method name, or a coderef called with the executor
# and the arguments. An executor that does not offer the queueing method
# (a replaced one, a test double) gets a plain execute.
sub _dispatch_to_executor {
  my ($self, $dispatch, @args) = @_;
  my $executor = $self->_executor;
  return $executor->$dispatch(@args) if ref $dispatch;
  $dispatch = 'execute' unless $executor->can($dispatch);
  return $executor->$dispatch(@args);
}

sub _mysql_report_gone_cb {
  my ($self, $conn) = @_;
  return sub { $self->_mysql_report_if_gone($conn) };
}

# Without a pool there is nobody to report to, and none is built for it: a
# connection the pool does not hold is not the pool's to retire.
sub _mysql_report_if_gone {
  my ($self, $conn) = @_;
  my $pool = $self->{pool} or return;
  $pool->_mysql_report_if_gone($conn);
  return;
}


sub _release_on_ready {
  my ($self, $conn, $pool, $lease) = @_;
  croak '_release_on_ready needs the pool the connection was acquired from' unless $pool;
  return sub { $pool->release($conn, $lease) };
}


sub _query_async_pinned {
  my ($self, $conn, $sql, $bind, $bind_attrs) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);
  return $self->_mysql_rollback($conn, $sql, $bind)
    if $sql =~ /\A\s*ROLLBACK\s*;?\s*\z/i;
  return $self->_mysql_commit($conn, $sql, $bind)
    if $sql =~ /\A\s*COMMIT\s*;?\s*\z/i;
  return $self->_mysql_execute($conn, $sql, $bind, 'execute_after_exclusive', $bind_attrs);
}


sub _mysql_rollback {
  my ($self, $conn, $sql, $bind) = @_;
  my $timeout = $self->rollback_wait_timeout;
  return $self->_mysql_end_transaction(
    sub { $_[0]->execute_when_idle($_[1], $_[2], $_[3], $timeout) }, $conn, $sql, $bind);
}


sub _mysql_commit {
  my ($self, $conn, $sql, $bind) = @_;
  return $self->_mysql_end_transaction(execute_after_exclusive => $conn, $sql, $bind);
}

# The statement that ends a transaction on $conn, handed to the executor's
# $dispatch (execute, or execute_when_idle). When it does not succeed -- the
# dispatch died, or its Future failed -- the connection is retired at its
# release: the transaction may still be open on it (karr k74). A dispatch that
# died is rethrown unchanged, as _mysql_execute does.
sub _mysql_end_transaction {
  my ($self, $dispatch, $conn, $sql, $bind) = @_;

  my $end = $self->_debug_query($sql, $bind);
  my $f;
  unless (eval { $f = $self->_dispatch_to_executor($dispatch, $conn, $sql, $bind); 1 }) {
    my $err = $@;
    $end->() if $end;
    $self->_mysql_retire_open_transaction($conn);
    $self->_mysql_report_if_gone($conn);
    die $err;
  }
  if (Scalar::Util::blessed($f) && $f->can('on_fail')) {
    $f->on_fail($self->_mysql_report_gone_cb($conn));
    $f->on_fail($self->_mysql_retire_open_transaction_cb($conn));
  }
  _mysql_trace_end($end, $f);
  return $f;
}

sub _mysql_retire_open_transaction_cb {
  my ($self, $conn) = @_;
  return sub { $self->_mysql_retire_open_transaction($conn) };
}

sub _mysql_retire_open_transaction {
  my ($self, $conn) = @_;
  my $pool = $self->{pool} or return;
  $pool->_mark_connection_dead($conn);
  return;
}


sub _reset_pool_connection {
  my ($self, $conn) = @_;

  my $executor = $self->_executor;
  my $end = $self->_debug_query('COM_RESET_CONNECTION', []);
  my $f;
  unless (eval { $f = $executor->reset_connection($conn); 1 }) {
    my $err = $@;
    $end->() if $end;
    $self->_mysql_report_if_gone($conn);
    return $self->future_class->fail($err);
  }
  $f->on_fail($self->_mysql_report_gone_cb($conn));
  _mysql_trace_end($end, $f);

  return $f->then(sub {
    my $names = $self->{_mysql_session_names}{ Scalar::Util::refaddr($conn) };
    return $self->future_class->done unless $names;

    my $set;
    unless (eval { $set = $self->_mysql_execute($conn, _mysql_set_names_sql(@$names), []); 1 }) {
      return $self->future_class->fail($@);
    }
    return $set;
  })->then(sub {
    $self->SUPER::_setup_pool_connection($conn);
    return $self->future_class->done;
  });
}


sub _setup_pool_connection {
  my ($self, $conn) = @_;

  $self->SUPER::_setup_pool_connection($conn);

  # Without an owning sync storage there are no connect actions and the pool
  # waits for no connect here (the core seam is a no-op there as well).
  return unless $self->_owner_storage;

  $self->_mysql_remember_session_names($conn);
  return;
}

# Reads character_set_client and collation_connection of a new connection
# (blocking, like the connect actions) and keeps them for the reset.
sub _mysql_remember_session_names {
  my ($self, $conn) = @_;

  my $rows = $self->_run_pool_connect_statement(
    $conn,
    'SELECT @@character_set_client, @@collation_connection',
    { dbio_rows => 1 },
  );
  my $row = $rows && $rows->[0] or return;

  my @names = @$row[0, 1];
  croak 'the server answered a character set or collation name that is not a plain name'
    if grep { !defined $_ || $_ !~ /\A[A-Za-z0-9_]+\z/ } @names;
  $self->{_mysql_session_names}{ Scalar::Util::refaddr($conn) } = \@names;

  return;
}

sub _mysql_set_names_sql {
  my ($charset, $collation) = @_;
  return "SET NAMES $charset COLLATE $collation";
}

# --- INSERT: LAST_INSERT_ID instead of RETURNING (MySQL value-add) ------------


sub insert_async {
  my ($self, @args) = @_;

  # INSERT + LAST_INSERT_ID() must ride the SAME session, so pin the whole
  # insert on one acquired connection and release it once the Future settles --
  # also when there never is one (karr k50, k61, see _query_async).
  my $pool = $self->pool;   # the pool the insert ends on, too (karr k90)
  return $self->_hold_derived($pool->acquire->then(sub {
    my $conn = shift;
    my $f = $self->_seam_future(_run_crud_pinned => 'insert', $conn, @args);
    $f->on_ready($self->_release_on_ready($conn, $pool, $pool->_lease($conn)));
    return $self->_mysql_caller_future($f);
  }));
}


sub _run_crud_pinned {
  my ($self, $op, $conn, @args) = @_;
  return $self->SUPER::_run_crud_pinned($op, $conn, @args) unless $op eq 'insert';

  # The CRUD contract is insert_async($source, \%rowdata) (ADR 0031 §3).
  # SQLMaker wants a plain table name, so unwrap a blessed source to its
  # ->name; a bare string passes through.
  my ($source, @rest) = @args;
  my $to_insert = $rest[0];
  # ADR 0044: the caller's row-data hashref must not be retained for the
  # flight. The returned-columns assembly only needs the values, so take a
  # shallow copy at dispatch; the flight closures reference the copy, never
  # the caller's hashref.
  my $insert_data = defined $to_insert ? { %$to_insert } : $to_insert;
  # The deferred part below (it waits for the sql_mode of a 0) references
  # these copies only, never the caller's hashref.
  my @rest_c = ( defined $to_insert ? { %$to_insert } : $to_insert, @rest[ 1 .. $#rest ] );

  # An auto-increment value of 0 is "generate" to the server, unless the
  # session's sql_mode has NO_AUTO_VALUE_ON_ZERO (karr k68): for the plan and
  # for the returned columns it counts as not supplied. The statement itself
  # still sends the 0. The sql_mode is read, on the pinned connection, only
  # for a 0.
  my $zero_col = $self->_zero_auto_increment_column($source, $insert_data);
  my $generates = ! defined $zero_col
    ? Future->done(0)
    : $self->_query_async_pinned($conn, 'SELECT @@SESSION.sql_mode', [])->then(sub {
        my $mode = ref $_[0] eq 'ARRAY' ? $_[0][0] : undef;
        return Future->done(( $mode // '' ) =~ /\bNO_AUTO_VALUE_ON_ZERO\b/ ? 0 : 1);
      });
  return $generates->then(sub {
    my ($generate) = @_;
    my $plan_data = $rest_c[0];
    if ($generate) {
      $insert_data = { %$insert_data };
      delete $insert_data->{$zero_col};
      $plan_data = { %{ $rest_c[0] } };
      delete $plan_data->{$zero_col};
    }

  # ADR 0036 section 4: the identity_column decision belongs to the storage,
  # never to the SQLMaker. Core's upsert_async hands this backend an
  # on_conflict structure WITHOUT identity_column -- the sync driver's
  # _mysql_upsert_plan adds that key before a sync statement runs, and this
  # path renders the SQLMaker directly, so the plan never ran here either.
  # Fold its private keys in exactly like DBIO::MySQL::Storage::insert does,
  # resolved against the OWNING sync storage via the back-ref core wired in
  # _async_storage (DBIO::Storage::Async/_owner_storage). Without it the ODKU
  # UPDATE branch carries no `pk` = LAST_INSERT_ID(`pk`) and reports a freshly
  # sent session's LII (0) instead of the id of the row the server actually
  # touched. The plan also enforces the sync path's conflict-target rule, so
  # the two halves of this driver cannot drift.
  my $opts = $rest_c[1];

  # The plan's decision must survive until sql_maker->insert runs, so the
  # local fold of its private keys lives at SUB scope (an if-block would end
  # the localisation before the maker ever saw it -- and the maker's consume
  # of on_conflict is a delete, which would then bite into the caller's
  # structure instead of the localised copy).
  my $plan;
  if ($opts && ref $opts eq 'HASH' && $opts->{on_conflict}
      && Scalar::Util::blessed($source)) {
    my $owner = $self->_owner_storage;
    if ($owner && $owner->can('_mysql_upsert_plan')) {
      # This transport reads SELECT LAST_INSERT_ID(), never RETURNING: say so
      # to the plan (karr k47), on a copy -- the hint is for the plan alone,
      # neither the maker nor the caller's structure gets to see it.
      $plan = $owner->_mysql_upsert_plan(
        $source, $plan_data, { %$opts, returning => 0 },
      );
    }
  }
  local $opts->{on_conflict} = { %{ $opts->{on_conflict} }, %{ $plan->{extra} } }
    if $plan;

  my $table = (Scalar::Util::blessed($source) && $source->can('name'))
    ? $source->name
    : $source;

  my ($sql, @bind) = $self->sql_maker->insert($table, @rest_c);

  # LAST_INSERT_ID() must run on the SAME connection as the INSERT, otherwise
  # the session-scope LII is undefined / from a prior session. Both run pinned
  # on $conn, so the SELECT never hits a foreign session's LII.
  my $bind_attrs = $self->_crud_bind_attrs(insert => $source, \@bind, $table, @rest_c);
  return $self->_query_async_pinned($conn, $sql, \@bind, $bind_attrs)->then(sub {
    return $self->_query_async_pinned($conn, 'SELECT LAST_INSERT_ID()', []);
  })->then(sub {
    my $lii_row = shift;
    my $lii_id  = (ref $lii_row eq 'ARRAY' && @$lii_row) ? $lii_row->[0] : undef;
    # Capture for legacy ->last_insert_id callers (e.g. scripts, tests).
    $self->{_last_insert_id} = $lii_id if defined $lii_id;
    my $returned = $self->_insert_returned_columns($source, $insert_data, $lii_row);

    # The whole plan counts, as in DBIO::MySQL::Storage::insert (karr k68):
    # where it cannot name the row, whatever primary key value is in hand
    # belongs to the row we tried to insert -- withholding it is the
    # difference between undef and a confidently wrong row. wants_identity is
    # false for result => 'void'/'count', where nothing is withheld.
    if ($plan && ! $plan->{nameable} && $plan->{wants_identity}) {
      delete @{$returned}{ @{ $plan->{primary_columns} } };
      carp_once($plan->{reason}) if defined $plan->{reason};
    }

    return $returned;
  });
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

  # A value the caller gave is the row's value; LAST_INSERT_ID() does not
  # know it (karr k68). A literal (\'DEFAULT', \'UUID()') is computed by the
  # server and is as unknown here as an absent or undef one.
  return \%returned
    if defined $to_insert->{$col}
      && ! DBIO::Util::is_literal_value($to_insert->{$col});

  $returned{$col} = $lii_id;

  return \%returned;
}

# The auto-increment column the caller gave the value 0 (not a literal), or
# undef. The server reads that 0 as "generate" unless the session's sql_mode
# has NO_AUTO_VALUE_ON_ZERO (karr k68).
sub _zero_auto_increment_column {
  my ($self, $source, $to_insert) = @_;
  return unless ref $to_insert eq 'HASH'
    && Scalar::Util::blessed($source) && $source->can('columns_info');
  my $col_infos = eval { $source->columns_info } || {};
  for my $col ($source->columns) {
    next unless $col_infos->{$col}{is_auto_increment};
    my $v = $to_insert->{$col};
    return $col if defined $v && ! ref $v && $v =~ /\A\s*[+-]?0+(?:\.0*)?\s*\z/;
    return;
  }
  return;
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

# --- Pool connect-action replay seam (karr k68 / k18) -------------------------


sub _run_pool_connect_statement {
  my ($self, $conn, $sql, $attrs, @bind) = @_;
  require EV;

  # The connection was just spawned; its async connect may still be in flight.
  # Block the EV loop until it is ready (the core seam's synchronous contract)
  # -- prepare/execute are exclusive ops and need an idle, connected handle.
  # Wait on the pool's per-connection readiness Future
  # (DBIO::Storage::PoolBase::_connection_ready_future -- core's default since
  # karr k33, which DBIO::MySQL::EV::Pool opts into): it is FAILED when the
  # spawn's connect fails, so a connection that never comes up throws here
  # instead of busy-spinning on an is_connected that will never turn true
  # (k29). Fall back to is_connected for a pool that does not expose the
  # readiness seam (e.g. a bare test double that is not a PoolBase subclass at
  # all).
  my $pool = $self->pool;
  if ($pool->can('_connection_ready_future')) {
    my $ready = $pool->_connection_ready_future($conn);
    EV::run(EV::RUN_ONCE()) until $ready->is_ready;
    $ready->get;   # rethrows the connect error
  }
  else {
    EV::run(EV::RUN_ONCE()) until $conn->is_connected;
  }

  $sql = $self->_transform_sql($sql);

  # Through the executor, like every other statement of this transport: a
  # bound connect statement is prepared, executed AND closed (karr k45 -- this
  # runner used to carry its own prepare + execute and leaked the statement).
  # Connect actions are almost always bindless SET statements, which stay on
  # the plain query path.
  my $f = $self->_executor->execute($conn, $sql, [@bind]);
  EV::run(EV::RUN_ONCE()) until $f->is_ready;

  croak 'pool connect statement failed: ' . ($f->failure // 'cancelled')
    unless $f->is_done;
  return [ $f->get ] if $attrs && $attrs->{dbio_rows};
  return;
}

# --- LISTEN / NOTIFY seams (emulated over a notify table) ---------------------
#
# Core DBIO::Storage::Async owns the contract and the machinery (core ADR 0056);
# DBIO::MySQL::NotifyTable owns the emulation's SQL and its per-channel state
# (dbio-mysql ADR 0008). What is left is the EV::MariaDB wiring (ADR 0010).
# Private helpers are named _mysql_*, as in dbio-mysql's future_io transport,
# never _listen_* or _watch_*: they share an inheritance chain with core's
# privates, and a same-named method appearing there later would be shadowed.
#
# The listen connection is a hashref, opaque to core:
#
#   mdb     the EV::MariaDB handle; gone once closed
#   notify  its DBIO::MySQL::NotifyTable -- the marks of this connection
#   pid     the process that opened it
#   busy    true while a statement runs on the handle
#   queue   statements waiting for it: [ $sql, \@bind, $future ]
#   watch   the poll loop's state { pid, timer }; gone once unwatched
#   fork    the EV::fork watcher that disarms the handle in a child
#
# prepare, execute, close_stmt and ping are EXCLUSIVE in EV::MariaDB: each dies
# while any other operation is pending on the handle. So every statement of
# the emulation -- a mark, a poll, a cleanup -- goes through one FIFO runner
# (_mysql_listen_statement), and nothing else is ever sent on the handle.


sub _listen_open {
  my ($self) = @_;
  require EV;
  require EV::MariaDB;

  my $notify   = $self->_mysql_notify_table;
  my $provider = $self->_conninfo_provider;
  my $conninfo = $provider ? $provider->() : $self->{_conninfo};
  croak 'the listen connection has no connect info -- call connect_info first'
    unless defined $conninfo;
  # Neither a host nor a user: EV::MariaDB would start no connect and call back
  # nothing, and the Future below would never settle (karr k66).
  DBIO::MySQL::EV::Pool->_mysql_refuse_unconnectable($conninfo);

  my $f   = $self->future_class->new;
  my $conn = { notify => $notify, pid => $$, busy => 0, queue => [] };

  # Held until the connect settles: nothing else references the connection
  # before core receives it. The cycle this makes through the handle's
  # callbacks ends when the Future is ready, which drops its callbacks.
  my $hold = $conn;
  $f->on_ready(sub { undef $hold });

  my ($on_connect, $on_error) = $self->_mysql_listen_handlers($f, $conn);
  # Made where the pool's handles are made: no password in what the handle
  # says, the croak of its constructor and its on_error alike (karr k76).
  $conn->{mdb} = DBIO::MySQL::EV::Pool->_mysql_new_handle(
    %$conninfo,
    on_connect => $on_connect,
    on_error   => $on_error,
  );
  # keepalive(0): the watcher is a guard, never a reason for the loop to go on
  # running -- in a child, after it fired, it would otherwise keep EV::run from
  # ever returning (karr k46).
  $conn->{fork} = EV::fork(_mysql_listen_fork_cb($conn));
  $conn->{fork}->keepalive(0);
  return $f;
}

# The handle's on_connect / on_error. They share the open's Future only until
# the connect settles: the handle keeps its handlers for its lifetime, and the
# Future holds the connection it resolved with.
sub _mysql_listen_handlers {
  my ($self, $f, $conn) = @_;
  Scalar::Util::weaken(my $weak_self = $self);
  Scalar::Util::weaken(my $weak_conn = $conn);
  my $pending = $f;

  my $on_connect = sub {
    my $conn = $weak_conn or return;
    return unless $conn->{pid} == $$;
    my $f = $pending or return;
    undef $pending;
    $f->done($conn);
    return;
  };
  my $on_error = sub {
    my ($msg) = @_;
    my ($self, $conn) = ($weak_self, $weak_conn);
    return unless $conn && $conn->{pid} == $$;
    $msg //= 'unknown error';
    chomp $msg;
    if (my $f = $pending) {
      undef $pending;
      $f->fail("connecting the listen connection failed: $msg");
      return;
    }
    $self->_listen_lost($conn, "the listen connection reported an error: $msg")
      if $self;
    return;
  };
  return ($on_connect, $on_error);
}

sub _mysql_listen_fork_cb {
  my ($conn) = @_;
  Scalar::Util::weaken(my $weak_conn = $conn);
  return sub {
    my $conn = $weak_conn or return;
    return if $conn->{pid} == $$;
    # A child resumed the event loop. Its copy of the handle must not read
    # the parent's socket: stop the poll loop and finish the handle, which in
    # a forked process drops the watchers and the client state without
    # sending COM_QUIT or shutting the shared socket down.
    delete $conn->{watch};
    my $mdb = delete $conn->{mdb} or return;
    local $@;
    eval { $mdb->finish; 1 };
    return;
  };
}


sub _listen_close {
  my ($self, $conn) = @_;
  delete $conn->{watch};
  delete $conn->{fork};
  my @waiting = splice @{ $conn->{queue} || [] };
  if (my $mdb = delete $conn->{mdb}) {
    local $@;
    eval { $mdb->finish; 1 };
  }
  for my $item (@waiting) {
    $item->[2]->fail('the listen connection was closed') unless $item->[2]->is_ready;
  }
  return;
}


sub _listen_subscribe {
  my ($self, $conn, $channel) = @_;
  my $notify = $conn->{notify};
  croak "LISTEN on channel '$channel': the listen connection is closed"
    unless $notify && $conn->{mdb};
  my ($sql, $bind) = $notify->subscribe_sql($channel);
  my $fc = $self->future_class;
  return $self->_mysql_listen_statement($conn, $sql, $bind)->then(
    _mysql_subscribed_cb($fc, $notify, $channel),
    _mysql_subscribe_failed_cb($fc, $notify),
  );
}

sub _mysql_subscribed_cb {
  my ($fc, $notify, $channel) = @_;
  return sub {
    my ($rows) = @_;
    $notify->subscribed($channel, $rows);
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
  my $notify = $conn->{notify};
  $notify->unsubscribe($channel) if $notify;
  return $self->future_class->done;
}


sub _listen_watch {
  my ($self, $conn) = @_;
  require EV;
  croak 'the listen connection is closed' unless $conn->{mdb} && $conn->{notify};
  my $watch = $conn->{watch} = { pid => $$ };
  $self->_mysql_listen_arm($conn, $watch);
  return;
}


sub _listen_unwatch {
  my ($self, $conn) = @_;
  delete $conn->{watch} if ref $conn;
  return;
}


sub _listen_probe {
  my ($self, $conn) = @_;
  my $mdb = $conn->{mdb} or return 0;
  return 1 if $conn->{busy};
  return DBIO::MySQL::EV::Pool->_mysql_connection_gone($mdb) ? 0 : 1;
}


sub _listen_delay {
  my ($self, $seconds) = @_;
  require EV;
  my $f = $self->future_class->new;
  my $timer;
  $timer = EV::timer($seconds, 0, sub {
    undef $timer;
    $f->done unless $f->is_ready;
  });
  $f->on_cancel(sub { undef $timer });
  return $f;
}


sub _notify_send {
  my ($self, $channel, $payload) = @_;
  my ($sql, $bind) = $self->_mysql_notify_table->notify_sql($channel, $payload);
  return $self->_query_async($sql, $bind);
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

# --- the listen connection's statement runner ---
#
# One statement at a time, in the order asked for. A statement with binds is
# prepare -> execute -> close_stmt: the close frees the server-side statement
# (a poll a second would otherwise leave 3600 of them behind an hour) and is
# exclusive itself, so the handle only counts as idle once it is done. One
# without binds is a plain query. Resolves with the rows (a SELECT) or the
# affected-row count; fails with the server's error.

sub _mysql_listen_statement {
  my ($self, $conn, $sql, $bind) = @_;
  my $f = $self->future_class->new;
  push @{ $conn->{queue} }, [ $sql, $bind // [], $f ];
  $self->_mysql_listen_next($conn);
  return $f;
}

sub _mysql_listen_next {
  my ($self, $conn) = @_;
  return if $conn->{busy} || $conn->{pid} != $$;
  my $item = shift @{ $conn->{queue} } or return;
  my ($sql, $bind, $f) = @$item;
  my $done = $self->_mysql_listen_done_cb($conn, $f, $sql, $bind);
  my $mdb  = $conn->{mdb}
    or return $done->(undef, 'the listen connection is closed');

  $conn->{busy} = 1;
  my $ok;
  {
    local $@;
    $ok = eval {
      if (@$bind) {
        $mdb->prepare($sql, _mysql_listen_prepared_cb($conn, $bind, $done));
      }
      else {
        $mdb->query($sql, $done);
      }
      1;
    };
    $done->(undef, $@ || 'starting a statement on the listen connection failed')
      unless $ok;
  }
  return;
}

sub _mysql_listen_prepared_cb {
  my ($conn, $bind, $done) = @_;
  Scalar::Util::weaken(my $weak_conn = $conn);
  return sub {
    my ($stmt, $err) = @_;
    my $conn = $weak_conn;
    return if $conn && $conn->{pid} != $$;
    return $done->(undef, $err // 'prepare failed') if defined $err || !defined $stmt;
    my $mdb = $conn && $conn->{mdb}
      or return $done->(undef, 'the listen connection was closed');
    local $@;
    eval { $mdb->execute($stmt, $bind, _mysql_listen_executed_cb($conn, $stmt, $done)); 1 }
      or $done->(undef, $@ || 'execute failed');
    return;
  };
}

sub _mysql_listen_executed_cb {
  my ($conn, $stmt, $done) = @_;
  Scalar::Util::weaken(my $weak_conn = $conn);
  return sub {
    my ($result, $err) = @_;
    my $conn = $weak_conn;
    return if $conn && $conn->{pid} != $$;
    my $mdb = $conn && $conn->{mdb};
    my $closing;
    if ($mdb) {
      local $@;
      $closing = eval { $mdb->close_stmt($stmt, sub { $done->($result, $err) }); 1 };
    }
    $done->($result, $err) unless $closing;
    return;
  };
}

# Settles the statement's Future once the handle is idle again, then starts
# the next one. Runs at most once: a close_stmt that croaked after calling
# back must not settle twice.
sub _mysql_listen_done_cb {
  my ($self, $conn, $f, $sql, $bind) = @_;
  Scalar::Util::weaken(my $weak_self = $self);
  Scalar::Util::weaken(my $weak_conn = $conn);
  my $settled;
  return sub {
    my ($result, $err) = @_;
    return if $settled++;
    my ($self, $conn) = ($weak_self, $weak_conn);
    return if $conn && $conn->{pid} != $$;
    $conn->{busy} = 0 if $conn;
    unless ($f->is_ready) {
      if (defined $err) {
        # The notify statements bind a channel and a payload: the server's
        # text for them is masked like any statement's (ADR 0075 of the core).
        chomp(my $msg = _mysql_mask_error("$err", $bind, $sql));
        $f->fail($msg);
      }
      else {
        $f->done($result);
      }
    }
    $self->_mysql_listen_next($conn) if $self && $conn;
    return;
  };
}

# --- the poll loop ---
#
# Named subs, not nested closures: a callback built here closes over exactly
# what it is handed, the storage, connection and watch only weakly. The watch
# state is the loop's identity -- every step first checks it is still the one
# on the connection and belongs to this process.

sub _mysql_listen_live {
  my ($conn, $watch) = @_;
  my $current = $conn->{watch};
  return $current
      && Scalar::Util::refaddr($current) == Scalar::Util::refaddr($watch)
      && $watch->{pid} == $$;
}

sub _mysql_listen_arm {
  my ($self, $conn, $watch) = @_;
  $watch->{timer} = EV::timer(
    $conn->{notify}->poll_interval, 0,
    $self->_mysql_listen_cb($conn, $watch, '_mysql_listen_poll'),
  );
  return;
}

# A callback that runs $step($conn, $watch, @args, @callback_args) while the
# watch is live, and treats anything it throws as a dead connection.
sub _mysql_listen_cb {
  my ($self, $conn, $watch, $step, @args) = @_;
  Scalar::Util::weaken(my $weak_self  = $self);
  Scalar::Util::weaken(my $weak_conn  = $conn);
  Scalar::Util::weaken(my $weak_watch = $watch);
  return sub {
    my @cb_args = @_;
    my ($self, $conn, $watch) = ($weak_self, $weak_conn, $weak_watch);
    return unless $self && $conn && $watch && _mysql_listen_live($conn, $watch);
    my $err;
    {
      local $@;
      eval { $self->$step($conn, $watch, @args, @cb_args); 1 }
        or $err = $@ || 'the listen poll died without a message';
    }
    return unless defined $err && _mysql_listen_live($conn, $watch);
    delete $conn->{watch};
    $self->_listen_lost($conn, $err);
    return;
  };
}

sub _mysql_listen_poll {
  my ($self, $conn, $watch) = @_;
  # A mark is being taken (or waits): this tick yields to it.
  return $self->_mysql_listen_arm($conn, $watch)
    if $conn->{busy} || @{ $conn->{queue} };

  my ($sql, $bind, $token) = $conn->{notify}->poll_sql
    or return $self->_mysql_listen_arm($conn, $watch);
  $self->_mysql_listen_statement($conn, $sql, $bind)->on_ready(
    $self->_mysql_listen_cb($conn, $watch, '_mysql_listen_polled', $token),
  );
  return;
}

sub _mysql_listen_polled {
  my ($self, $conn, $watch, $token, $f) = @_;
  my $notify = $conn->{notify};
  die 'polling the notify table ' . $notify->quoted_table . ' failed: '
    . ($f->failure // 'cancelled') . "\n"
    unless $f->is_done;

  my ($rows) = $f->get;
  for my $n (@{ $notify->polled($token, $rows) }) {
    return unless _mysql_listen_live($conn, $watch);
    $self->_listen_dispatch(@$n);
  }
  return unless _mysql_listen_live($conn, $watch);

  my ($sql, $bind) = $notify->cleanup_sql
    or return $self->_mysql_listen_arm($conn, $watch);
  $self->_mysql_listen_statement($conn, $sql, $bind)->on_ready(
    $self->_mysql_listen_cb($conn, $watch, '_mysql_listen_cleaned'),
  );
  return;
}

sub _mysql_listen_cleaned {
  my ($self, $conn, $watch, $f) = @_;
  my $notify = $conn->{notify};
  if ($f->is_done) {
    $notify->cleaned(($f->get)[0]);
    return $self->_mysql_listen_arm($conn, $watch);
  }

  my $err = 'cleaning up the notify table ' . $notify->quoted_table
          . ' failed: ' . ($f->failure // 'cancelled');
  $notify->cleaned(undef);
  # A dead connection ends the tick like a failed poll; on a live one the
  # cleanup was refused (no DELETE, a lock wait timeout) and polling goes on.
  die "$err\n" unless $self->_listen_probe($conn);
  $self->_listen_error($err);
  return unless _mysql_listen_live($conn, $watch);   # the hook may act
  return $self->_mysql_listen_arm($conn, $watch);
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

version 0.900004

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
ADR 0032 C<?>-in contract

=item * L</_query_async> / L</_query_async_pinned> -- native EV::MariaDB query
dispatch (pooled and pinned), routed through L<DBIO::MySQL::EV::QueryExecutor>.
A statement that fails on a connection that is gone reports it to the pool,
which retires it instead of handing it out again (L</_mysql_execute>)

=item * L</insert_async> + L</_run_crud_pinned> + L</_insert_returned_columns>
-- MySQL has B<no RETURNING clause>, so INSERT reads C<SELECT LAST_INSERT_ID()>
on the B<same> pinned connection and folds the auto-increment id into the
returned-columns hashref (ADR 0031 §3). This is the one CRUD path core's
generic RETURNING-shaped runner cannot serve, so it is overridden here

=item * L</_run_pool_connect_statement> -- synchronous connect-action replay on
a freshly-spawned EV::MariaDB pool connection

=item * L</_reset_pool_connection> -- core's session-reset seam (ADR 0079): when
a borrow ends, C<COM_RESET_CONNECTION>, C<SET NAMES> with the character set
and collation the connection started with, and the connect actions again; the
connection goes on only after all three answered

=item * L</connect_info> / L</_normalize_async_connect_info> / L</_conninfo_hash>
-- the EV::MariaDB named-parameter conninfo transport shape (incl.
C<dbname>-E<gt>C<database>)

=item * L</_txn_context_class> / L</_txn_conn_accessor> -- the pinned-connection
transaction context

=item * L</_ddl_class> -- the install-DDL generator (L<DBIO::MySQL::DDL>) core's
generic C<deploy_async> resolves, so C<< $storage->deploy_async($schema) >> runs
the same DDL the sync deploy pipeline emits

=item * the listen seams L</_listen_open>, L</_listen_close>,
L</_listen_subscribe>, L</_listen_unsubscribe>, L</_listen_watch>,
L</_listen_unwatch>, L</_listen_probe>, L</_listen_delay> and
L</_notify_send> -- LISTEN/NOTIFY B<emulated> over a notify table, see
L</"LISTEN / NOTIFY (emulated)">

=back

=head2 Transport value-add

MySQL/MariaDB has B<no> COPY, so -- unlike the PostgreSQL EV transport -- this
transport carries no such wire value-add. EV::MariaDB pipelines queries
B<automatically> at the wire level (consecutive C<query> calls are batched, up
to 64 in flight) with B<no> explicit pipeline-mode API to bracket; the core
C<_pipeline_enter>/C<_pipeline_sync>/C<_pipeline_exit> seam therefore does not
apply and the C<pipeline> capability is B<not> declared (see
L</transport_capabilities>). The inherited C<< $storage->pipeline >> is refused
here: it returns a failed Future saying that this class does not support
C<pipeline()>, without taking a connection from the pool and without running
the batch (L<DBIO::Storage::Async/pipeline>, ADR 0009).
MySQL/MariaDB has no native LISTEN/NOTIFY either;
this transport B<emulates> it and declares C<listen> and C<notify> for the
emulation (L</"LISTEN / NOTIFY (emulated)">), next to C<on_connect_replay>.

=head2 TLS and the event loop

Over TLS (C<ssl_cipher>, C<ssl_ca>, C<ssl_key>, C<ssl_cert> or C<ssl_capath> in
the DSN) statements run concurrently, like over plain TCP, because of a
work-around in this transport. Without it they did not: libmariadb
(3.4.9) leaves the socket of a TLS connection blocking, and its asynchronous
TLS read and write then block in the kernel instead of suspending, so every
C<query> and C<prepare> / C<execute> held the whole event loop until the server
had answered (docs/upstream/ev-mariadb-tls-blocks-the-loop.md, a draft, not
sent). L<DBIO::MySQL::EV::Pool/_mysql_new_handle>, where every handle of this
distribution is made, now sets C<O_NONBLOCK> on the socket in the handle's
C<on_connect>, and again after every reconnect, on every handle: the
connect info does not tell whether TLS was negotiated, and over plain TCP the
flag was measured to change nothing.

Limits, as measured on MySQL 8.0 and MariaDB 11: the connect and the TLS
handshake itself still block the loop (the flag is set after them). C<close_async>,
C<finish> and the TLS shutdown end at once, without an error, and the server's
session is gone afterwards; a 6 MB result and a 5 MB bound parameter go through
the non-blocking socket whole. Only the ssl parameters of the connect info are
looked at: a session that ends up on TLS without one is not covered. Pinned by
t/60-tls-nonblocking-socket-mock.t (the decision) and t/52-tls-concurrent-live.t
(the effect, both servers).

=head2 LISTEN / NOTIFY (emulated)

C<listen>, C<unlisten>, C<notify>, C<listen_alive> and C<listen_reconnect> are
core async API (core ADR 0056), one contract on every async transport that
declares C<listen> / C<notify>, documented once in
L<DBIO::Storage::Async/"LISTEN / NOTIFY">. Core owns the channel registry, the
one dedicated listen connection, reconnect with backoff, subscribing every
channel again, and the fork guard. This class fills the seams.

B<MySQL and MariaDB have no LISTEN/NOTIFY, so this transport emulates it> with a
notify table and polling, through L<DBIO::MySQL::NotifyTable> -- the part it
shares with the C<future_io> transport of the L<DBIO::MySQL> distribution. The
design and its reasons are B<dbio-mysql ADR 0008> (in that distribution's
C<docs/adr/>); how it is wired onto EV::MariaDB is this distribution's ADR
0010. C<notify> inserts a row; the listen connection polls the table on an EV
timer for rows new to it.

  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'ev' });
  my $async  = $schema->storage->async;

  $async->on_listen_error(sub {
    my ($storage, $error) = @_;          # every error; without a hook it is warned
    $log->warn("listen: $error");
  });
  $async->on_listen_reconnect(sub {
    my ($storage) = @_;                  # rebuilt, every channel subscribed again
    $log->info('listen connection rebuilt -- re-read what may have been missed');
  });

  $async->deploy_notify_table            # once -- never created implicitly
    ->then(sub {
      $async->listen(jobs => sub {
        my ($channel, $payload, $sender_pid) = @_;   # $sender_pid: CONNECTION_ID()
        ...
      });                                # resolves once the mark is taken
    })
    ->then(sub {
      $async->notify(jobs => 'wake up'); # an INSERT on a pooled connection
    })
    ->retain;

  EV::run;

The Futures are L<DBIO::MySQL::EV::Future>s settled from the EV loop, like
every other Future this transport returns: chain on them and run the loop, or
call C<get>, which runs the loop until the Future is ready (L</future_class>).

What the emulation delivers, and where it differs from a server push:

=over 4

=item * B<Latency is the poll interval> (L</notify_poll_interval>, default 1
second): a notification arrives with the first poll after it became visible.

=item * B<Delivery on commit.> A notification becomes visible when the
transaction that inserted it commits -- PostgreSQL's moment too. C<notify> runs
its C<INSERT> on a pooled connection in autocommit, so it is visible at once;
to notify transactionally, run L<DBIO::MySQL::NotifyTable/notify_sql> inside
your own transaction (C<txn_do_async>).

=item * B<No history, no replay.> C<listen> takes a mark before its Future
resolves: a notification committed after that is delivered, nothing committed
earlier is. A notification whose transaction was still open at that moment is
delivered when it commits. Each listen connection takes new marks, so a
reconnect loses what was committed while no connection listened;
C<on_listen_reconnect> is where to re-read state.

=item * B<The lookback limit.> Out-of-order commits are caught within
L</notify_lookback> seconds (default 60), each notification exactly once. A
notification is lost when its transaction commits more than the lookback after
its C<INSERT> I<and> a later notification on the same channel was delivered
meanwhile (L<DBIO::MySQL::NotifyTable/How the out-of-order commit is caught>).

=item * B<Retention.> The listen connection deletes rows older than
L</notify_retention> seconds (default 3600): one bounded C<DELETE ... LIMIT>
at most once a minute, back to back only while it clears a backlog
(L<DBIO::MySQL::NotifyTable/Retention>). A cleanup that fails on a live
connection is reported through C<on_listen_error> and tried again a period
later; it does not end listening. C<notify_retention(0)> turns it off for a
deployment that prunes the table itself.

=item * B<The table> is L<DBIO::MySQL::NotifyTable/THE TABLE>, named by
L</notify_table> (default C<dbio_notify>). It is B<never created implicitly>:
deploy it with L</deploy_notify_table>, or run
L<DBIO::MySQL::NotifyTable/create_table_sql> from a migration. Until it exists,
C<listen> fails with a message naming the table and L</deploy_notify_table>,
and C<notify> with the server's error.

=item * B<Privileges.> The listening account needs C<SELECT> and C<DELETE> on
the table (C<DELETE> for the retention cleanup), a notifying one C<INSERT>,
and whoever deploys it C<CREATE>.

=item * B<Channels and payloads> only ever travel as bind values. A channel is
matched exactly and case-sensitively, at most 255 characters; a payload is at
most 65535 bytes in UTF-8; both are refused beyond that, never truncated. An
C<undef> payload arrives as C<''>. They travel as EV::MariaDB sends and
returns every string on this transport: bytes as given, results as bytes
unless the connection info sets C<< utf8 => 1 >> (with
C<< charset => 'utf8mb4' >>, see L<EV::MariaDB/UNICODE>) -- non-ASCII channel
names need that setting to match.

=item * B<The listen connection> is a dedicated EV::MariaDB handle outside the
pool, opened from the connect info a pool spawn would get at that moment
(fresh AccessBroker credentials included). The pool's C<on_connect_do> /
C<on_connect_call> replay does not run on it. It runs one statement at a time:
a C<listen> arriving while a poll is in flight waits for it, a poll tick that
finds a statement running is skipped, and C<listen_alive> reports a statement
in flight as alive -- that statement reports a dead connection itself.
Otherwise C<listen_alive> checks the idle connection's socket without a round
trip: an idle MySQL connection has nothing to read, so a readable socket means
the server has hung up (C<KILL>, a restart, C<wait_timeout>). A peer that
vanished without closing the connection is found by the next poll instead.

=item * B<Fork.> Core never touches the listen connection outside the process
that opened it, and EV::MariaDB closes nothing when a forked child exits or
drops its copy of the handle, so the parent's listen session survives. A child
that B<resumes the EV loop> would still share the parent's socket, and could
read the reply to a poll that was in flight when it forked; the first thing
such a child's loop does is disarm its copy of the handle, without touching
the parent's session (ADR 0010). The pooled connections C<notify> runs on
carry the same guard (L</pool>).

=back

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
connection is opened and whenever a C<notify> or L</deploy_notify_table>
builds its statement, so a change reaches listening from the next listen
connection (L<DBIO::Storage::Async/listen_reconnect> makes one). Invalid
settings make the open throw before anything connects; core reports that and
retries with backoff.

=head2 rollback_wait_timeout

Seconds a pinned C<ROLLBACK> waits for the statements in flight on its
connection before it gives up. Default 30; C<0> or C<undef> waits
without limit. A statement in flight whose answer never comes would keep the
ROLLBACK -- and with it the transaction and its connection -- waiting for
ever. When the time is up the ROLLBACK is not sent, the connection is retired
(it may still hold the transaction, see L</_mysql_rollback>) and the Future of
the transaction fails with a L<DBIO::Exception> naming the wait. C<inherited>
class data: set it on the class for every connection, or on the async backend
for one.

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

Returns C<'DBIO::MySQL::EV::Future'>: a L<Future> subclass whose C<get> on a
pending Future runs the EV loop until it is ready
(L<DBIO::MySQL::EV::Future>). That is what makes the inherited blocking
methods -- C<select>, C<insert>, C<txn_do>, C<deploy>, ... -- work: each is
C<< ->get >> on its C<*_async> sibling, and a plain L<Future> dies there
instead of waiting (ADR 0001). The class reaches every Future such a method
waits on: L</pool> hands it to the pool, L<DBIO::MySQL::EV::QueryExecutor>
builds its query Futures from it, and L<Future>'s combinators keep it. A
blocking call works from a script and from inside an EV callback, also inside
a C<then> on this transport's Futures and a C<txn_do> coderef: those run from
the idle watcher that settles the Futures, outside the callbacks of the
EV::MariaDB handle, so a statement they send goes out at once (ADR 0001
addendum, L<DBIO::MySQL::EV::Future/await>).

What is still refused is a blocking call that is queued for a pooled connection while the
callbacks it runs inside hold every connection of the pool. In a
C<txn_do> coderef, C<< $storage->select >> and its siblings run on a pooled
connection, not on the transaction's -- that is what the context the coderef
is handed is for -- and the transaction gives its connection back only after
the coderef has returned. With a pool of one, or with every connection held by
a transaction the call is nested in, the call would wait for a connection that
cannot come back; it dies with I<"Blocking wait refused: ..."> and does not
run, and the transaction is rolled back. With a connection to spare, or one
that a statement in flight will give back, it waits and returns.

Everything else is L<Future>'s own. C<< ->then >> callbacks auto-wrap a
non-Future return value into a resolved Future (ADR 0031 §4), so ResultSet/Row
C<< *_async >> callbacks that return plain values resolve without an explicit
C<< Future->done(...) >> wrap.

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
storage's C<on_connect_do>/C<on_connect_call> against it.

=item * C<listen> and C<notify> -- the capability names core's LISTEN/NOTIFY
gate asks for (core ADR 0056 section 2), declared for an B<emulation>, which
core ADR 0056 section 6 allows when the POD states latency and on-commit
delivery, as L</"LISTEN / NOTIFY (emulated)"> does.

=item * C<broker_connect_options> -- read by core, not by layers: the connect
options given beside an L<DBIO::AccessBroker>,
C<< MyApp::Schema->connect($broker, { async => 'ev', pool_size => 3, ... }) >>,
are handed on as C<< [ $broker, \%options ] >> and applied to every connection
this transport opens. C<pool_size> sizes the pool. The
DBD attributes are treated as the same keys are in DBI-form connect info: this
transport has no DBD, so they are dropped and never reach EV::MariaDB
(L</connect_info>). A connection parameter there (C<charset>, C<host>, ...) is
neither applied nor dropped: the connect info is refused. Without
the declaration core refuses such a connection at first async use.

=back

It does B<not> declare C<copy> (MySQL has no COPY), nor C<pipeline>
(EV::MariaDB pipelines automatically at the wire level; there is no explicit
pipeline-mode API for the core seam to bracket, ADR 0009).

=head2 connect_info

  $storage->connect_info([ \%conninfo, \%opts ]);

Set connection parameters. C<%conninfo> is passed to L<EV::MariaDB> as named
connection parameters (host, user, password, database, ...). When the
embedding sync storage feeds its own DBI-form connect info (C<<
['dbi:MariaDB:...', $user, $pass, \%attrs, \%extra_attributes] >>) it is
translated into the async C<< [ \%conninfo, \%opts ] >> shape first
(EV::MariaDB cannot parse a DSN string). So is the single-hash form C<< [ {
dsn =E<gt> ..., user =E<gt> ..., password =E<gt> ..., pool_size =E<gt> 3,
<attributes> } ] >>: every key but C<dsn>, C<user>, C<password> and a nested
C<attrs> hash is an attribute, and neither C<dsn> nor C<async> is handed to
EV::MariaDB. What the translation reads, and refuses -- an unknown DSN key, a
connection parameter given as an attribute -- is told by
L<DBIO::MySQL::EV::ConnectInfo/dbi_to_conninfo>. A hash that is given directly
(C<< [ \%conninfo ] >>, C<< [ \%conninfo, \%opts ] >>) is EV::MariaDB's own
parameters; a C<dbi:...> DSN as its database name is refused, not read as a
name. AccessBroker connect info (C<< [ $broker ] >>) is detected and wired to
the per-spawn credential provider (the inherited broker seam), exactly as the
sync path does; what the broker answers is read by L</_async_broker_conninfo>,
which croaks on an answer it cannot connect from.

A broker may come with the connect options the owning sync storage was given
beside it, C<< [ $broker, \%options ] >> -- the form core hands a transport
declaring C<broker_connect_options> (L</transport_capabilities>). They are read
through core's L<DBIO::Storage::Async/_access_broker_call_options>, after what
the owner applies itself (C<async>, the storage options such as
C<on_connect_do>, the SQL maker options such as C<quote_names>) is stripped:

=over 4

=item * C<pool_size> sizes the pool. So does a C<pool_size> in the broker's
answer -- a key of its hash, or among the attributes of a DBI-form answer, in
its fourth or fifth element, the later one winning. Given both in the answer
and beside the broker, the two must be the same value, or this throws naming
C<pool_size> (L<DBIO::Storage::Async/_access_broker_pool_size>). Given nowhere,
the pool keeps its default of 5.

=item * B<DBD attributes> (C<mysql_enable_utf8mb4>, C<mariadb_auto_reconnect>,
C<AutoCommit>, C<RaiseError>, ...) are dropped: there is no DBD on this
transport to apply them, and L<EV::MariaDB> croaks on an argument it does not
know. In DBI-form connect info the DBD attributes are not dropped
(L<DBIO::MySQL::EV::ConnectInfo/dbi_to_conninfo>): the ones
EV::MariaDB has a parameter for (C<mysql_enable_utf8mb4>, ...) are translated,
any other is refused. Beside a broker they are only kept apart, below. They change what the
owner's DBI connection does and nothing about a pooled one.
L<DBIO::Storage::Async/_access_broker_call_attributes> answers what was
dropped. What counts as one is told by its name, the way core tells it for the
owning storage: a first letter in uppercase, or a start of
C<private_>, C<dbi_>, C<dbd_>, DBD::mysql's C<mysql_> or DBD::MariaDB's
C<mariadb_> -- both DBD prefixes, since this transport is not told which of
the two DBDs the owner connects with.

=item * B<A connection parameter> -- any other key set to a value: C<charset>,
C<utf8>, C<connect_timeout>, C<host>, C<database>, ... -- is refused. This
throws, naming the parameters and never a value, and says where they belong.
Every connection of this transport is opened from the broker's answer alone,
so the parameter would not reach one; it is not dropped with the DBD
attributes, which would leave the pool connecting without a
C<< ssl_verify_server_cert => 1 >> or C<< host => ... >> beside a broker, and
without a word. No list of EV::MariaDB parameters is kept: a lowercase name
that is no DBI attribute is refused whether EV::MariaDB knows it or not. A key
set to C<undef> or the empty string names no parameter. Such a parameter is
given in the broker's answer (L</_async_broker_conninfo>).

=back

After that refusal nothing is opened through this storage without the
parameter. The broker stays attached, no conninfo is stored -- not the one of
a static C<connect_info> before it either -- and every pool connection and
every open of the listen connection is refused again, naming the parameters,
until C<connect_info> is given connect info without them. With the broker
detached there is nothing to connect from.

Through a schema, C<< MyApp::Schema->connect($broker, { async => 'ev',
charset => ... }) >>, the refusal comes when core builds this transport: at
the first C<< $schema->storage->async >> or C<*_async> call, and at every
later one. C<connect> itself goes through: this transport is not there yet to
refuse anything. The owning sync storage refuses the same options on its own
account, when it opens its dbh, and the parts of the connection
itself -- C<host>, C<port>, C<dbname>, C<user>, C<password>, C<dsn> -- already
at C<connect> (L<DBIO::Storage::DBI::AccessBroker/_access_broker_call_info>).

No conninfo is kept from a broker's answer, as in core's
L<DBIO::Storage::Async/connect_info>. The answer is read once here -- to refuse
one the transport cannot connect from, and for its C<pool_size>, which sizes
the pool -- and every connection asks the broker again, so a stored copy could
only be that first answer, password included. A storage whose broker is
detached afterwards has nothing to connect from until C<connect_info> is called
again: it does not fall back to what the broker once answered, nor to static
connect info given before the broker. Static connect info is stored, being all
a static connection is opened from.

This override (rather than the inherited base C<connect_info>) is retained
because the EV transport folds the DBI-form DSN into EV::MariaDB named params
inline via L<DBIO::MySQL::EV::ConnectInfo/dbi_to_conninfo>. It matches the base
in every ownership-relevant respect: a truthy setter opens a new ownership
generation (ADR 0045 section 4), rotating the context owner token via
C<disconnect> when a pool or a listen connection exists (the listen
connection is closed, being opened with the old connect info) and via
C<_rotate_context_owner_token> otherwise, so a context from the previous generation cannot survive a
reconfiguration even before a pool has been materialised.

=head2 _async_broker_conninfo

  my $conninfo = $storage->_async_broker_conninfo($mode);
  # { database => 'app', host => 'db1', port => 3306, user => ..., password => ... }

AccessBroker seam (see L<DBIO::Storage::Async/ACCESSBROKER CONSUMPTION>): ask
the attached broker for its current connect info -- anew each time, so rotated
credentials reach the next connection -- and return it as the hash of
L<EV::MariaDB> named parameters the connection is opened from. Called for
every new pool connection (through L<DBIO::Storage::Async/_conninfo_provider>)
and for every open of the listen connection (L</_listen_open>), its first and
every reconnect. L</connect_info> reads the broker's answer the same way when
the broker is attached, where a C<pool_size> in it sizes the pool. Connect
options given beside the broker change nothing in the conninfo: the DBD
attributes among them never reach EV::MariaDB. A connection parameter among
them stops the connection instead -- this croaks before the broker is asked,
as L</connect_info> did when it was given them. The answer may come
in any of these shapes:

=over 4

=item * B<A DBI-form arrayref>
C<< [ 'dbi:mysql:...', $user, $password, \%attrs ] >> (or C<dbi:MariaDB:>), as
L<DBIO::AccessBroker::Vault> answers, and L<DBIO::AccessBroker::HostBound>
over it. Read exactly like DBI-form connect info
(L<DBIO::MySQL::EV::ConnectInfo/dbi_to_conninfo>): the DSN's parameters,
C<$user> and C<$password> become named parameters, and of C<\%attrs> -- and of
a fifth element C<\%extra_attributes> -- only C<pool_size> is read. The rest
-- DBD attributes, and DBIO's own such as
C<async>, which a Vault broker selects this transport with -- never reaches
EV::MariaDB.

=item * B<A hashref of EV::MariaDB named parameters>, as
L<DBIO::AccessBroker::Static> answers (C<host>, C<port>, C<dbname>, C<user>,
C<password>), and L<DBIO::AccessBroker::HostBound> over it. C<dbname> is read
as C<database> (L</_normalize_async_connect_info>).

=item * An arrayref holding such a hashref, optionally followed by an options
hashref -- the C<< [ \%conninfo, \%opts ] >> shape of L</connect_info>.

=back

Anything else croaks, naming the shape it received -- never the values, which
carry the password. That includes a DSN for another driver and any other
string: EV::MariaDB takes named parameters only and parses no connection
string.

So does an answer in one of these shapes that names B<neither a host nor a
user>: a hash holding only C<pool_size>, or a database and a password, or
undefined values for both; a DSN with a database only and no user beside it.
L<EV::MariaDB> starts a connect only when it is given one of the two; without
either its handle stays unconnected and calls back neither C<on_connect> nor
C<on_error>, so the pool's C<acquire> would never resolve. One of the two is
enough: what a connection needs beyond that is the server's to say. A broker
that answers nothing at all -- C<undef>, an empty hash or array -- is refused
by core before this method reads the answer, naming the broker class
(L<DBIO::Storage/current_access_broker_connect_info>).

And so does a hash whose database name is B<a whole DSN>:
C<< DBIO::AccessBroker::Static->new(dbname => 'dbi:mysql:database=app;host=db1', ...) >>,
the form core's sync storage takes as the DSN
(L<DBIO::AccessBroker::Static>). The broker still answers a hash, and this
transport reads no DSN out of one: the DSN would be the name of the database
and the host it names would not be given, so L<EV::MariaDB> would connect to
the client library's default -- the local server -- with the broker's user and
password. The answer is refused at attach and for every
connection after it, under a L<DBIO::AccessBroker::HostBound> view too, whose
host is not the one the DSN names; it is told by C<dbi:> at the start of
C<dbname>, C<database> or C<db>, and the croak says nothing of the DSN. Have
the broker answer the DSN in the DBI form, or the database name as C<dbname>
with C<host> and C<port> beside it. A schema connected from such a broker
without C<< { async => 'ev' } >> is not affected, and one connected with it
gets the refusal at its first C<< ->async >> or C<*_async> call.

Croaks when no AccessBroker is attached -- one detached with
L<DBIO::Storage/clear_access_broker> while the per-spawn provider is still in
place, on the storage or in a pool built with it. Core's seam
L<DBIO::Storage::Async/_current_async_connect_info> answers what
L</connect_info> stored then, and that is no broker's answer: the croak says
that the broker is gone.

B<A hash answer, through a schema.> A schema's broker is asked by two
storages: this transport, and the owning sync storage for its dbh. The hash of
EV::MariaDB parameters is this transport's shape only, and the sync storage
takes less of it:

=over 4

=item * it needs a C<dbname> (or a C<dsn>): of a hash it builds C<dbname>,
C<host> and C<port> into its DSN, and an answer naming neither is refused when
the schema is connected -- C<< MyApp::Schema->connect >> throws.
C<database>, EV::MariaDB's own spelling, is not read there; C<dbname> is read
as C<database> here;

=item * it refuses a hash carrying any other parameter of the database client
(C<charset>, C<utf8>, C<connect_timeout>, C<ssl_ca>, ...) when it is about to
open its dbh, naming the broker class and the parameters: a DBD would keep
such a key without a word and connect without it. C<connect> and C<< ->async
>> go through, and the pool opens its connections with the parameter; what
throws is the first call that needs the owner's dbh -- every sync call, and
with the core this was written against (0.900004) C<select_async> and the
ResultSet reads on the schema as well.

=back

So a schema's connections get such a parameter from an answer B<by the storage
that asks> (L<DBIO::AccessBroker/connect_info_for_storage>): the hash with the
parameter for a L<DBIO::MySQL::EV::Storage>, an answer the sync storage takes
for every other. One DSN for both halves carries it only under DBD::mysql,
which ignores a DSN parameter it does not know (and so does not apply it to
the dbh); DBD::MariaDB refuses one (C<Unknown attribute charset>, measured
with DBD::MariaDB 1.24 and DBD::mysql 4.055). The transport given the broker
directly, C<< $storage->connect_info([ $broker ]) >>, takes the hash with any
EV::MariaDB parameter as before: no sync storage reads the answer then.

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

Only static connect info is stored. C<undef> when there is none: no connect
info was given yet, or an AccessBroker is attached -- L</connect_info> keeps
nothing of its answer, and what a connection is opened from is
L</_async_broker_conninfo>'s to say, anew each time.

=head2 pool

Returns the L<DBIO::MySQL::EV::Pool> connection pool, created lazily on first
access. The pool is wired with C<< storage => $self >> so its core-shared spawn
path (L<DBIO::Storage::PoolBase/_spawn_connection>) replays the owning sync
storage's connect actions on each new connection via
L</_run_pool_connect_statement>. Fed the per-spawn
C<conninfo_provider> when an AccessBroker is attached, otherwise the static
conninfo hash. With neither -- no connect info was given yet, or a broker and
its provider are gone (L<DBIO::Storage::Async/_clear_access_broker>) -- there
is nothing to build a pool from, and this croaks
(L<DBIO::Storage::PoolBase/new>).

A forked child that resumes the EV loop leaves the pool's sessions to the
parent: the pool C<finish>es the child's copies of its connections -- checked
out and pinned ones included -- before the child's loop reads anything, and no
callback of a statement that was in flight at fork time runs in the child
(L<DBIO::MySQL::EV::Pool/_create_connection>, ADR 0010).

=head2 _mysql_mask_error

  my $text = DBIO::MySQL::EV::Storage::_mysql_mask_error($text, \@values, $sql);

The error masker of this transport's executor (ADR 0075 of the core: a message
names keys, columns and options, never a value). MySQL and MariaDB write the
offending value into their text -- C<Duplicate entry 'x' for key 'k'>,
C<Incorrect integer value: 'x' for column 'i'>, the C<near '...'> of a syntax
error -- bound or not. It answers the text with the value replaced by C<***> and
the type, the column, the key and the position left, by
L<DBIO::MySQL::Util/mask_error_details> (the sentences of the engine, the
quoted literals of a syntax excerpt, the bound values found elsewhere) and then
L<DBIO::Util/mask_bound_values>. It is the one mask for every way a statement's
error reaches a Future or an exception here: the executor (C<_query_async>,
C<insert_async> and its C<LAST_INSERT_ID()>, the pinned statements of a
transaction and its C<ROLLBACK>/C<COMMIT>, the session reset, the connect
actions of L</_run_pool_connect_statement>, C<deploy_async>, the notify
C<INSERT>) and the statement runner of the listen connection
(C<_mysql_listen_done_cb>). C<\@values> are plain values (the executor hands
over the bound ones of four characters or more); the SQLSTATE of the exception
is not a part of the text and stays.

It is a function and not a method on purpose: it asks no storage and so never
connects a dbh of the owning sync storage. It never throws -- a text it cannot
treat is answered as it is, and so is anything that is no text (an exception
object).

=head2 _txn_context_class

The pinned-connection transaction context the inherited
L<DBIO::Storage::Async/txn_do_async> hands to its coderef:
L<DBIO::MySQL::EV::TransactionContext> -- a B<thin subclass> of core's generic
L<DBIO::Storage::Async::TransactionContext> that inherits the whole context
surface and adds only the C<txn_mdb> alias for C<txn_conn>.

=head2 _txn_conn_accessor

The constructor key the pinned connection is passed under -- C<txn_conn>, the
core key L<DBIO::MySQL::EV::TransactionContext> now inherits from
L<DBIO::Storage::Async::TransactionContext>. The handle goes under that key,
not under a private one such as C<mdb>, which core's own callers do not know:
the transactional branch of L<DBIO::Storage::Async/deploy_async> reads C<<
$ctx->txn_conn >>. MySQL COMMITs DDL implicitly, so L</_ddl_class>'s deploy
never takes that branch (ADR 0026).

=head2 _ddl_class

The install-DDL generator the inherited L<DBIO::Storage::Async/deploy_async>
resolves through L<DBIO::Storage::Async/_install_ddl>: L<DBIO::MySQL::DDL> --
the very class the B<sync> MySQL deploy pipeline uses
(L<DBIO::MySQL::Deploy/_ddl_class>), so async and sync deploy emit byte-identical
MySQL DDL. Filling this seam is all the transport needs: core's generic
C<deploy_async> then runs every generated statement over the
L</_query_async_pinned> seam this class already implements for CRUD.

The DDL batch is deliberately B<not> wrapped in a transaction. MySQL implicitly
COMMITs each DDL statement, so the inherited C<deploy_async> takes its
non-transactional branch (ADR 0026) -- statement-at-a-time on one pooled
connection, with a one-shot warning naming this class. A deploy that fails
half-way therefore leaves the already-executed statements behind; re-run with
C<< add_drop_table => 1 >> to get back to a known state.

=head2 _ddl_quote_ident

  my $quoted = $storage->_ddl_quote_ident($name);

The identifier C<$name> as the MySQL DDL writes it: between backticks, through
L<DBIO::MySQL::Identifier/quote_ident>, so a reserved word (C<order>) or a
name that is no plain word (C<my-table>) is valid. Core's
L<DBIO::Storage::Async/_drop_statements_for>, the C<add_drop_table> pre-pass
of L<DBIO::Storage::Async/deploy_async>, writes every view and table name
through it.

=head2 _transform_sql

Transport-internal SQL shaping (ADR 0032). B<Identity> for MySQL:
MySQL/DBD speaks the C<?> placeholder dialect natively, so the C<sql_maker>
output needs no rewrite. The seam is retained (and applied first by
L</_query_async> / L</_query_async_pinned>) purely to keep the transport seam
contract uniform across drivers -- do B<not> reintroduce a dialect rewrite here.

=head2 _query_async

Transport seam. Execute a query on a freshly-acquired pooled connection,
releasing it once the Future is ready. Returns a L<Future> of the raw result
rows (list of column arrayrefs for a result set, or the affected-row count for
plain DML -- ADR 0031 §3), exactly what the inherited C<_run_crud> expects.

The dispatch, L</_await_query_result>, goes through core's
L<DBIO::Storage::Async/_seam_future>: the release hangs off the Future the
dispatch returns, so there has to be one. A dispatch that dies
before it returns a Future -- L<EV::MariaDB> croaks from C<prepare> and
C<query>, with I<"another operation is in progress">, I<"not connected"> and
the like -- fails the returned Future with that error. One that returns no
Future at all -- C<undef>, a plain value -- fails it with an error naming the
backend class and C<_await_query_result>. Either way the connection is
released at once; kept checked out instead, a pool of N would be wedged for
good after N such calls.

A connection that failed because it is B<gone> is not reused: the pool is told
before the release, retires it instead of idling it, and the next call -- or a
caller already queued for the slot -- gets a newly opened connection (see
L</_mysql_execute>). A statement error the session survives -- a syntax error,
a duplicate key, EV::MariaDB refusing a busy handle -- leaves the connection
in the pool.

A caller that B<cancels> the returned Future -- or loses it in a C<wait_any>
against a timeout -- stops waiting, and nothing else: L<EV::MariaDB> is not
told, the statement is answered all the same, and a statement with bind values
still has its C<execute> and C<close_stmt> to go. The connection stays checked
out until the dispatch has settled, and is released then, once. Released at the
cancel, it would be idle with an operation in flight, and L<EV::MariaDB> would
refuse the next caller's C<prepare> (I<"another operation is in progress">).
So the cancel stops at the Future the caller holds and never reaches the
dispatch (L</_mysql_caller_future>).

Receives SQL in the C<sql_maker> C<?>-placeholder dialect and shapes it via
L</_transform_sql> (identity for MySQL) before it reaches the executor -- the
ADR 0032 seam contract.

=head2 _mysql_caller_future

  my $future = $storage->_mysql_caller_future($dispatch);

The Future a pooled call hands its caller for C<$dispatch>, the Future of what
runs on the pooled connection, whose settling releases that connection
(L</_query_async>, L</insert_async>). It settles as C<$dispatch> does, but a
cancel of it stops there (L<Future/without_cancel>): Future.pm carries a cancel
down a C<then> chain, and a cancelled C<$dispatch> is ready at once -- its
connection would be released with an operation still in flight.

C<$dispatch> is retained until it settles. With the caller gone nothing else
may hold it -- L</insert_async>'s is the end of a C<then> chain, which Future.pm
holds weakly -- and a dispatch that is freed never releases its connection.

A Future that is not a Future.pm one cannot be cancelled either, and is
returned as it is.

The other half of the rule: the C<< $pool->acquire->then(...) >> sequence a
pooled call returns is held (C<_hold_derived>) until it is done, because
Future.pm holds it only weakly from the acquire Future still waiting for the
pool, and a caller that lets go of it there would lose the chain and the
connection.

=head2 _await_query_result

  my $future = $storage->_await_query_result($conn, $sql, $bind, $bind_attrs);

The pooled dispatch of L</_query_async>: hand the already shaped statement to
the executor on C<$conn> (L</_mysql_execute>) and return its L<Future> of the
result. It shapes nothing and releases nothing. A method of its own, not a
line inside L</_query_async>, because L<DBIO::Storage::Async/_seam_future>
takes the dispatch by name -- and names it in the error when it returns no
Future.

=head2 _mysql_execute

  my $future = $storage->_mysql_execute($conn, $sql, $bind, $dispatch, $bind_attrs);

Hand one shaped statement to the executor
(L<DBIO::MySQL::EV::QueryExecutor/execute>) on C<$conn> and return its
L<Future> -- the one place both dispatches, pooled (L</_await_query_result>)
and pinned (L</_query_async_pinned>), reach the wire through.

A statement that B<fails> has the pool told when its connection is gone
(L<DBIO::MySQL::EV::Pool/_mysql_report_if_gone>): whether it failed
through its callback, or L<EV::MariaDB> refused to dispatch it and the
executor died (that error is rethrown unchanged). The report is the first
thing the failed Future runs, so it is made before anything hands the
connection back -- the pooled release of L</_query_async> and L</insert_async>,
or core's at the end of a transaction and of C<deploy_async>, whose connection
is released by core and can be reported from here only. The pool then retires
the connection at that release instead of putting it back, where it would be
handed out again and fail every caller the same way.

What tells a gone connection from a statement error is the handle, not the
message: L<DBIO::MySQL::EV::Pool/_mysql_connection_gone>. A session the server
ended while the connection sat idle is not handed out in the first place
(L<DBIO::MySQL::EV::Pool/_idle_connection_alive>); one that ends after the
pool looked, or without the server saying so, is found by the first statement
sent on it: that statement fails, and this retires the connection. A statement
that succeeds is never asked about.

The callback is built by a named sub, as L</_release_on_ready> is and for the
same reason (ADR 0044): it holds the connection for the flight, never the bind
values.

The text of a statement that fails has its values taken out
(L</_mysql_mask_error>) by the executor before the exception exists, also the
text of a dispatch EV::MariaDB refuses, which is rethrown masked.

The statement is traced here, once, by the core's
L<DBIO::Storage::Async/_debug_query> (core ADR 0025) with the
optional C<$bind_attrs> of L</_query_async>; its C<query_end> runs when the
Future is ready, failed or done. The pinned C<ROLLBACK>/C<COMMIT> and the
C<COM_RESET_CONNECTION> of a reset are traced the same way, as raw statements.
The executor traces nothing, the connect actions of a new connection and the
listen connection's statements are not traced.

=head2 _release_on_ready

  my $cb = $storage->_release_on_ready($conn, $pool, $lease);

Build the pool-release callback for a query Future. It releases C<$conn> to
C<$pool>, the pool it was acquired from -- never to L</pool> asked again,
which builds a new pool on a storage disconnected while the statement was in
flight -- and passes C<$lease>, C<< $pool->_lease($conn) >> taken right after
the C<acquire>: a callback that runs a second time, once the connection went
on to another caller, releases nothing.

A named sub, deliberately B<not> a closure inside the C<< ->then(sub {...}) >>
acquire chain (ADR 0044): the callback is created HERE, in a sub whose pad
dies when this sub returns, so the bind arrayref lives only until dispatch,
not for the whole flight of the query. A callback created inside the C<<
->then >> closure would be retained by the executor's Future for the flight
and would pin that closure's pad -- and C<$bind> -- alive via CvOUTSIDE.

=head2 _query_async_pinned

Transport seam. Like L</_query_async> but runs on the supplied pinned connection
and does B<not> release it -- used for queries inside a pinned transaction and
for the INSERT + C<LAST_INSERT_ID()> pair (which must ride the same session).
Shapes the incoming C<?>-dialect SQL via L</_transform_sql> exactly as
L</_query_async> does.

A statement that fails on a connection that is gone reports it to the pool
(L</_mysql_execute>), so a transaction whose connection died in the
middle has it retired when core hands it back, not returned to the idle list.

The two statements that end a transaction do not go through L</_mysql_execute>
directly. C<ROLLBACK> goes through L</_mysql_rollback>: it waits for
the statements in flight on the connection. C<COMMIT> goes through
L</_mysql_commit>. Every other statement is queued behind a C<prepare> or an
C<execute> in flight on the connection, where EV::MariaDB would
refuse it: see L<DBIO::MySQL::EV::QueryExecutor/execute_after_exclusive>.
Either end of a transaction that does not succeed retires the connection:
one that may still hold a transaction never goes back to the pool.

=head2 _mysql_rollback

  my $future = $storage->_mysql_rollback($conn, 'ROLLBACK', []);

The ROLLBACK of a pinned connection, what
L</_query_async_pinned> sends for it instead of L</_mysql_execute>. Two
things differ.

B<It waits for the statements in flight on the connection.> EV::MariaDB takes
no query while a C<prepare> or an C<execute> is in flight, and a transaction
ends that way whenever its coderef dies, its Future fails or one of its
statements was cancelled while a statement with bind values was still on the
wire. The ROLLBACK is handed over only after the last of them has settled and
its statement is closed
(L<DBIO::MySQL::EV::QueryExecutor/execute_when_idle>): one order per pinned
connection, so the transaction ends later than it would have. A connection
with nothing in flight gets it at once, as before.

B<The wait has a limit>: L</rollback_wait_timeout> seconds, default
30. A statement whose answer never comes must not keep the transaction and its
connection for ever. When the time is up the ROLLBACK is not sent, the Future
fails with a L<DBIO::Exception> naming the wait, and the connection is retired
like one whose ROLLBACK failed (below).

B<A ROLLBACK that does not succeed retires the connection.> Whether refused
at dispatch or failed by the server or the client library, the session may
still hold the transaction, and a connection with an open transaction must
never go back to the pool: the next C<BEGIN> there would commit it. The
connection is reported to the pool as dead
(L<DBIO::Storage::PoolBase/_mark_connection_dead>), which retires it when core
hands it back, and a caller queued for the slot gets a newly opened one.

=head2 _mysql_commit

  my $future = $storage->_mysql_commit($conn, 'COMMIT', []);

The COMMIT of a pinned connection, what L</_query_async_pinned>
sends for it instead of L</_mysql_execute>. Core sends it only after every
statement the transaction's context handed out has settled, so there is
nothing of the transaction to wait for; like every other statement it is
queued behind a C<prepare> or C<execute> that a statement sent past the
context left in flight.

B<A COMMIT that does not succeed retires the connection>, as a ROLLBACK that
does not succeed does (L</_mysql_rollback>) and for the same reason: whether
the server failed it or EV::MariaDB refused to take it (an operation sent on
the connection past the context is in flight), nobody knows whether the
transaction is still open, and a connection with an open transaction must
never go back to the pool. The error the caller gets is unchanged -- core's
C<COMMIT failed: ...>, or the refusal -- and the next call runs on a newly
opened connection.

=head2 _reset_pool_connection

  my $future = $storage->_reset_pool_connection($conn);

Core's session-reset seam (L<DBIO::Storage::Async/_reset_pool_connection>, core
ADR 0079), asked by the pool when a borrow, a transaction or a pipeline ends.
It makes C<$conn> a connection like a freshly spawned one, in three steps that
follow each other:

=over 4

=item 1.

C<COM_RESET_CONNECTION> (L<EV::MariaDB/reset_connection>,
L<DBIO::MySQL::EV::QueryExecutor/reset_connection>). The server drops what the
session of the borrower held: user variables (C<@x>), session variables
(C<SET SESSION ...>, C<sql_mode> included, which fall back to the server's
global values), temporary tables, prepared statements, locks taken
with C<GET_LOCK>, and an open transaction.

=item 2.

C<SET NAMES E<lt>character setE<gt> COLLATE E<lt>collationE<gt>> with the two
names the connection had when it was new (L</_setup_pool_connection>): the
session starts again with the character set and the collation of the new
connection, on MySQL and on MariaDB.

=item 3.

The connect actions again -- the connection's schema, C<on_connect_call>,
C<on_connect_do> -- through L<DBIO::Storage::Async/_setup_pool_connection>,
which puts back the session settings every connection of this storage starts
with.

=back

The Future resolves after all three have answered; the pool hands the connection
on only then. A reset the server refuses, a connect action that fails, or no
answer within the pool's C<reset_timeout> fails it, and the pool retires the
connection: the next borrower gets a newly opened one. There is no way to turn
the reset off. The statements of the connect actions run as they do on a new
connection, one after the other, and block the EV loop while they do
(L</_run_pool_connect_statement>); a storage without connect actions sends the
reset and the C<SET NAMES>, one without an owning sync storage only the reset.

Every borrow therefore has the session of the new connection, character set and
collation included: the transport reads C<character_set_client> and
C<collation_connection> once per connection, in one statement after the connect
actions of its spawn, and sets both again after every reset. A name the server
answers that is not made of letters, digits and underscores is refused (the
connection is not used; the error names no value).

A reset that fails because the connection is gone reports it to the pool
(L</_mysql_execute>), as a failed statement does. The error is the client
library's or the server's; it names no statement, bind value or credential.

=head2 _setup_pool_connection

  $storage->_setup_pool_connection($conn);

Core's per-spawn seam (L<DBIO::Storage::Async/_setup_pool_connection>): the
connect actions of the owning sync storage run on the new connection, then one
statement reads its C<character_set_client> and C<collation_connection>. Both
names are kept per connection for L</_reset_pool_connection>, which sets them
again after every reset. A no-op without an owning sync storage, as the core
seam is. A name that is not made of letters, digits and
underscores makes the call die, without quoting it.

=head2 insert_async

  my $future = $storage->insert_async($source, \%vals);

Resolve the returned-columns I<hashref> -- the supplied insert data overlaid
with the auto-increment PK the engine populated (ADR 0031 §3). MySQL has no
RETURNING clause, so the INSERT and a following C<SELECT LAST_INSERT_ID()> must
run on the B<same> session: this override acquires one pooled connection, runs
the whole insert pinned on it via L</_run_crud_pinned>, and releases it when the
Future settles. (The base C<insert_async> uses the pooled runner, which would
acquire a fresh connection per query and read a foreign session's LII.)

L</_run_crud_pinned> is called through core's
L<DBIO::Storage::Async/_seam_future>, as the dispatch of L</_query_async> is.
An insert that dies before it has a Future -- SQL generation throwing, a
conflict target MySQL cannot honour say, or a croaking C<prepare> -- fails the
Future with that error. A C<_run_crud_pinned> that returns no Future at all --
an override in a subclass or a composed layer answering C<undef> or a plain
value -- fails it with an error naming the backend class and
C<_run_crud_pinned>. Either way the connection is released at once.

An insert that finds its connection gone -- at the INSERT or at
C<LAST_INSERT_ID()> -- has it retired at that release, and the next call gets
a newly opened one (L</_mysql_execute>).

A B<cancel> of the returned Future does not reach the insert
(L</_mysql_caller_future>): the INSERT is answered, its statement
closed and C<LAST_INSERT_ID()> read as if nobody had cancelled, and the
connection is released after the last of them, once. A cancelled insert is not
undone, and it may well have inserted its row.

=head2 _run_crud_pinned

  my $future = $storage->_run_crud_pinned($op, $conn, @args);

Build SQL and run a CRUD op on a pinned connection (the entry point the
L<DBIO::MySQL::EV::TransactionContext> and L</insert_async> use). For every op
except C<insert> this delegates to the inherited runner. The C<insert> op is the
MySQL value-add: it runs the INSERT and then C<SELECT LAST_INSERT_ID()> on the
B<same> C<$conn> (so the session-scoped LII is the one the INSERT produced),
captures it for legacy L</last_insert_id> callers, and folds it into the
returned-columns hashref via L</_insert_returned_columns>.

An upsert (C<on_conflict> in the options) is planned by the owning sync
storage's C<_mysql_upsert_plan>, handed the hint C<< returning => 0 >> -- this
transport reads C<LAST_INSERT_ID()>, never C<RETURNING> -- on a copy of the
options. The whole plan counts, as in the sync insert:
where the row cannot be named and the caller asked for it, the primary key
columns are taken out of the returned hashref and the plan's reason is
reported once with C<carp_once>, so the upsert resolves C<undef>; with
C<no_retrieve> (C<< result => 'void' >> or C<'count'>) nothing is withheld.

An auto-increment value of C<0> in the row data is C<generate> to the server,
so it counts as not supplied -- for the plan and for the returned columns, where
C<LAST_INSERT_ID()> is then the id -- unless the session's C<sql_mode> has
C<NO_AUTO_VALUE_ON_ZERO>, where the C<0> is a value and is kept. The
C<sql_mode> is read with C<SELECT @@SESSION.sql_mode> on the pinned connection
before the INSERT, and only for a C<0>. The sync insert of
L<DBIO::MySQL::Storage> keeps a supplied C<0> as core does.

=head2 _insert_returned_columns

  $hashref = $storage->_insert_returned_columns($source, \%to_insert, $lii_row);

Assemble the returned-columns hashref from a C<SELECT LAST_INSERT_ID()> row
(ADR 0031 §3). MySQL has no RETURNING clause, so the INSERT path captures the
LII on the pinned connection and hands the single-column row to this method.
The hashref is C<< { %$to_insert, $col => $lii_id } >>, where C<$col> is the
source's first C<is_auto_increment> column (falling back to the first PK
column whose value was not supplied, matching the sync
L<DBIO::Storage::DBI/insert> heuristic). A value the caller supplied for that
column (defined, not a literal) is kept as it is: C<LAST_INSERT_ID()> says
nothing about it. Overrides the inherited default that maps a positional
RETURNING row onto a column list.

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
identical to the DBD-based pools. The freshly-spawned
EV::MariaDB handle connects asynchronously, so we first drive the loop until
the pool's readiness Future for that connection settles -- a connect that fails
rethrows here rather than leaving the runner spinning -- then run the
statement and drive the loop until it completes. The statement runs through
L<DBIO::MySQL::EV::QueryExecutor>, as every other statement of this transport:
bindless statements (the usual C<SET ...> connect actions) go on the queueable
C<query> path, a bound one is prepared, executed and closed again.
C<$attrs> (the DBI attribute hashref) has no EV::MariaDB analogue and is
ignored, with one key: C<< dbio_rows => 1 >> (core's contract for reading a
query at connect time, e.g. in a C<connect_call_*>) makes the runner return
the rows of the statement as an array reference of row array references
(empty for an empty result). Without it nothing is returned.

=head2 _listen_open

  my $f = $storage->_listen_open;   # done with the listen connection

Core listen seam (L<DBIO::Storage::Async/_listen_open>): open the dedicated
listen connection -- a B<new> L<EV::MariaDB> handle, never one from the pool --
and resolve once it is connected. Its connect info is what a pool spawn would
get at this moment: fresh credentials through
L<DBIO::Storage::Async/_conninfo_provider> when an AccessBroker is attached,
otherwise the stored static conninfo; with neither, it croaks. So it does for
connect info that names neither a C<host> nor a C<user>: EV::MariaDB
starts no connect then and would call back nothing. The pool's
connect-action replay does not run on it.

The connection carries a fresh L<DBIO::MySQL::NotifyTable> built from the
L</notify_table> settings: the marks of this connection, which a reconnect
therefore takes anew. Invalid settings throw here, before anything connects.
A connect that fails fails the Future; a connection-level error the handle
reports later goes to L<DBIO::Storage::Async/_listen_lost>. The handle is made
where the pool's are (L<DBIO::MySQL::EV::Pool/_mysql_new_handle>), so neither
message quotes a password.

B<Fork safety.> EV::MariaDB records the process that connected and closes
nothing when a forked child exits or drops its copy, so the parent's session
survives the child. A child that resumes the EV loop, though, would still have
the handle's watchers armed on the shared socket and could read the reply to
a statement that was in flight when it forked. An L<EV/fork> watcher kept with
the connection therefore C<finish>es the child's copy before the child's loop
runs anything else -- EV::MariaDB's fork-aware close, which leaves the
parent's session alone (ADR 0010). The watcher never keeps the loop running
(C<keepalive(0)>): after it fired in a child it would otherwise keep
the child's C<EV::run> from ever returning.

=head2 _listen_close

  $storage->_listen_close($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_close>): close the listen
handle with EV::MariaDB's synchronous C<finish>, which also tolerates a dead
connection and one with a statement still in flight (core has stopped the
watch first, so its result is not delivered). Statements still waiting for
the handle fail. Also drops the fork watcher: a connection that is closed has
nothing left to disarm.

=head2 _listen_subscribe

  my $f = $storage->_listen_subscribe($conn, $channel);

Core listen seam (L<DBIO::Storage::Async/_listen_subscribe>): take the
channel's mark (L<DBIO::MySQL::NotifyTable/subscribe_sql>) B<on the listen
connection> and resolve once it is in effect -- so a C<notify> after C<listen>
resolved is delivered. A statement in flight is waited for first. The channel
is validated here and travels as a bind value; a channel it refuses makes the
seam throw, and a missing notify table fails it with a message naming the table
and L</deploy_notify_table>. Either way core finds the connection alive, drops
the channel and fails its C<listen> Future with the reason. The mark is taken
on the listen connection, not a pooled one, so that a failure means B<this>
connection's failure when core probes it (dbio-mysql ADR 0008 section 6).

=head2 _listen_unsubscribe

  my $f = $storage->_listen_unsubscribe($conn, $channel);

Core listen seam (L<DBIO::Storage::Async/_listen_unsubscribe>): stop polling
the channel. Local bookkeeping only (L<DBIO::MySQL::NotifyTable/unsubscribe>);
rows for it that a poll already in flight brings back are dropped.

=head2 _listen_watch

  $storage->_listen_watch($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_watch>), B<timer-driven>: an
EV timer fires after the connection's poll interval (L</notify_poll_interval>
as it stood when the connection opened); the tick runs one poll of the notify
table (L<DBIO::MySQL::NotifyTable/poll_sql>) on the listen connection, hands
what is new to L<DBIO::Storage::Async/_listen_dispatch> in order, runs the
retention cleanup when one is due, and only then arms the timer again -- so
polls never overlap and never queue up behind a slow one. A tick that finds a
statement running or waiting on the connection (a subscribe's mark) skips its
poll and arms again.

A failed poll is a dead connection and goes to
L<DBIO::Storage::Async/_listen_lost>, as does any other error in a tick. A
failed cleanup goes there too when L</_listen_probe> finds the connection dead;
on a live connection it is reported through
L<DBIO::Storage::Async/_listen_error> and polling goes on (a listener without
C<DELETE>, say). The first poll runs one interval after the watch starts, never
from inside this call.

=head2 _listen_unwatch

  $storage->_listen_unwatch($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_unwatch>): stop the poll loop.
The watch state is taken off the connection, which drops its timer; a poll or
cleanup still in flight completes on the handle, finds the watch gone and
delivers and reports nothing.

=head2 _listen_probe

  my $alive = $storage->_listen_probe($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_probe>), asked by
L<DBIO::Storage::Async/listen_alive> and after a failed subscribe. Synchronous
and without a round trip:

=over 4

=item * a statement in flight: alive, without touching the handle -- a C<ping>
then would die in EV::MariaDB (it is exclusive), and the statement reports a
dead connection itself;

=item * no socket (EV::MariaDB gives it up when an operation finds the
connection gone): dead;

=item * otherwise the idle socket must have nothing to read. A MySQL server
never speaks unasked, so a readable idle socket is the server hanging up -- a
C<KILL>, a restart, C<wait_timeout> -- and means dead.
The check is the pool's, L<DBIO::MySQL::EV::Pool/_mysql_connection_gone>, so
the two cannot disagree (an interrupted C<select> is asked again there).

=back

EV::MariaDB's C<is_connected> is not consulted: it stays true after the server
killed the session and even after an operation failed on it. Its C<ping> is
not used either: it is asynchronous, so a synchronous probe would have to run
the event loop from inside C<listen_alive> (ADR 0010).

=head2 _listen_delay

  my $f = $storage->_listen_delay($seconds);

Core listen seam (L<DBIO::Storage::Async/_listen_delay>): the reconnect
backoff, an L<EV/timer> wrapped in a Future. It resolves from the EV loop, and
C<cancel> stops the timer.

=head2 _notify_send

  my $f = $storage->_notify_send($channel, $payload);

Core listen seam (L<DBIO::Storage::Async/_notify_send>): run
L<DBIO::MySQL::NotifyTable/notify_sql> -- an C<INSERT> with channel and payload
as bind values, C<CONNECTION_ID()> as the sender -- on a pooled connection
through L</_query_async>, in autocommit. Throws on an invalid channel, payload
or L</notify_table>, which fails the Future of
L<DBIO::Storage::Async/notify>.

=head2 deploy_notify_table

  $storage->deploy_notify_table->then(sub { ... });

Create the notify table (L<DBIO::MySQL::NotifyTable/create_table_sql>,
C<CREATE TABLE IF NOT EXISTS>) on a pooled connection; a Future that resolves
once it exists. Nothing creates it implicitly: it is DDL, which MySQL commits
implicitly, and a schema change is the deployer's call. Fails for an invalid
L</notify_table>.

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
