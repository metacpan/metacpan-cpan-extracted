package DBIO::PostgreSQL::EV::Storage;
# ABSTRACT: Async PostgreSQL storage driver using EV::Pg

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::Async';

use Carp 'croak';
use EV ();
use Scalar::Util ();
use DBIO::Storage::DBI ();
use Sub::Util ();
use DBIO::Util ();
use DBIO::Exception ();
use DBIO::Exception::Server ();
use DBIO::PostgreSQL::SQLMaker;
use DBIO::PostgreSQL::DDL ();
use DBIO::PostgreSQL::Util ();
use DBIO::PostgreSQL::EV::ConnectInfo qw( conninfo_string is_libpq_parameter );
use DBIO::PostgreSQL::EV::Future;
use DBIO::PostgreSQL::EV::Pool;
use DBIO::PostgreSQL::EV::TransactionContext;
use namespace::clean;


# --- SQLMaker seams -----------------------------------------------------------
# The inherited DBIO::Storage::Async::sql_maker builds the maker from these.


sub sql_maker_class { 'DBIO::PostgreSQL::SQLMaker' }


sub _sql_maker_args {
  my ($self) = @_;
  # _owner_storage, not _effective_owner_storage: the private sync sibling of
  # a backend without an owner shares this backend's maker, so asking it here
  # would build this maker from itself.
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


sub _post_insert_sql { ' RETURNING *' }


sub future_class { 'DBIO::PostgreSQL::EV::Future' }


sub transport_capabilities {
  qw(on_connect_replay listen notify copy pipeline broker_connect_options)
}


sub connect_info {
  my ($self, $info) = @_;
  if ($info) {
    # A connect_info setter always opens a new ownership generation (core k196 /
    # this repo k38). When a pool or listen state exists, disconnect performs
    # the rotation (it rotates before teardown) and ends listening (core ADR
    # 0056); with neither materialised we still rotate here, so no context of
    # the outgoing generation survives a reconfigure. Matches
    # DBIO::Storage::Async::connect_info.
    if ($self->{pool} || $self->{_listen}) {
      $self->disconnect;
    }
    else {
      $self->_rotate_context_owner_token;
    }
    # Nothing the connect_info before this one stored outlives this call --
    # dropped here, before anything is read, because reading can throw: the
    # broker itself, core's refusal of an answer of nothing, this transport's
    # refusal of what it cannot connect from, two pool sizes that disagree.
    # The conninfo must not be left for a connection opened later (core k252
    # and k265, karr k63 and k67), and the pool size must not size a pool
    # built after the refusal (karr k66).
    @{$self}{qw( connect_info _conninfo _pool_size _opts )} = ();
    $self->{_access_broker_call_attributes} = {};

    # [ $broker, \%options ]: the connect options the owning sync storage was
    # given beside the broker, handed on because this transport declares
    # broker_connect_options (core k243, karr k60). Read as core's connect_info
    # reads them: what the owner applies itself (async, the storage and SQL
    # maker options) is stripped, the rest is split into pool_size and the DBD
    # attributes. Undef for every other form.
    my $stripped = $self->_strip_private_connect_attrs($info);
    my $beside   = $self->_access_broker_call_options($stripped);
    $info = $stripped if $beside;

    if ($beside || $self->_is_access_broker_connect_info($info)) {
      $self->{connect_info} = $info;
      # No conninfo is kept with a broker attached, as in core's connect_info
      # (core k252, karr k63): every connection asks the broker anew
      # (_conninfo_provider), so a stored copy could only ever be an earlier
      # answer -- password included -- which nothing may use.
      $self->_setup_access_broker($info->[0]);
      # What stands beside the broker, kept where core's accessor answers for
      # it and never applied: this transport drops DBD attributes, as
      # dbi_to_conninfo does for a DSN. A connection parameter among them is
      # not dropped but refused (karr k76) -- here, before the broker is asked,
      # and for every connection after (_async_broker_conninfo), which is why
      # they are kept before anything can throw: a storage whose connect_info
      # was refused opens no connection without the parameter.
      $self->{_access_broker_call_attributes} = $beside->{attributes} if $beside;
      $self->_pg_refuse_parameters_beside_broker;
      my $read = $self->_pg_read_connect_info(
        $self->_current_async_connect_info($self->access_broker_mode), broker => 1,
      );
      my (undef, $pool_size, $opts) = $self->_normalize_async_connect_info($read);
      # One rule for the pool size wherever it is given -- the answer's hash,
      # an attribute of a DBI-form answer, beside the broker; the answer and
      # the options beside the broker must agree, or this throws (core k245).
      # Core's rule, asked of the answer as it was read: the reader has every
      # place an answer gives a pool size in, the attributes in front of a
      # DSN among them.
      my $given_pool_size = $self->_access_broker_pool_size($read, $beside);
      $pool_size = $given_pool_size if defined $given_pool_size;
      $self->{_pool_size} = $pool_size;
      $self->{_opts}      = $opts;
    }
    else {
      # Static connect info, in whichever form the owning sync storage reads
      # one: the DBI form it hands on is translated, a form nobody can connect
      # from is refused here and not by the first pool (karr k64, k66).
      $self->_clear_access_broker;
      my $read = $self->_pg_read_connect_info($info);
      my ($conninfo, $pool_size, $opts) = $self->_normalize_async_connect_info($read);
      # Nothing at all is the empty conninfo, left to libpq (karr k66).
      $conninfo //= '';
      $self->{connect_info} = $read;
      $self->{_conninfo}    = $conninfo;
      $self->{_pool_size}   = $pool_size;
      $self->{_opts}        = $opts;
    }
  }
  return $self->{connect_info};
}


sub _async_broker_conninfo {
  my ($self, $mode) = @_;
  # Without a broker core's seam answers what connect_info stored, and that is
  # no broker's answer: nothing since karr k63, before it the earlier answer of
  # the broker that was detached, its password included.
  _pg_refuse('PostgreSQL ev has no AccessBroker attached to ask for connect info')
    unless $self->access_broker;
  $self->_pg_refuse_parameters_beside_broker;
  my ($conninfo) = $self->_normalize_async_connect_info(
    $self->_pg_read_connect_info($self->_current_async_connect_info($mode), broker => 1)
  );
  return $conninfo;
}

# True for the name of a DBI attribute, by core's measure for a key of a hash
# (core k298, DBIO::Storage::DBI::AccessBroker::_access_broker_unapplied_parameters):
# it starts with an uppercase letter, with private_, dbi_ or dbd_, or with the
# prefix of the DBD -- pg_ here, the one DBD this transport stands beside. No
# libpq parameter has such a name.
sub _pg_is_dbi_attribute {
  my ($self, $name) = @_;
  return $name =~ /^(?:[A-Z]|private_|dbi_|dbd_|pg_)/;
}

# Croaks when a connection parameter stands beside the broker (karr k76): a
# key of what connect_info kept from [ $broker, \%options ] that is set to a
# value and is, by its name, no DBI attribute (_pg_is_dbi_attribute, the
# measure of core's _assert_access_broker_parameters_apply for a broker's hash
# answer); undef and the empty string name no parameter. What the owner applies
# itself and pool_size are gone from the hash by now. No list of libpq
# parameters is used for a lowercase name: one that is no DBI attribute cannot
# be told from one. A name spelled with a capital is told by the list of
# ConnectInfo::is_libpq_parameter (karr k80). Names only, sorted -- a value may be a secret (sslpassword), and
# nothing is said of the broker's answer, which has not been asked for.
sub _pg_refuse_parameters_beside_broker {
  my ($self) = @_;
  my $beside = $self->_access_broker_call_attributes;
  # A name that is a DBI attribute's by its case -- Sslmode -- and a libpq
  # parameter's lower-cased is refused as well (karr k80): the owner's DBI
  # takes it for an attribute, and the pool would connect without it.
  my @unapplied = sort grep {
    defined $beside->{$_} && length $beside->{$_}
      && (!$self->_pg_is_dbi_attribute($_) || is_libpq_parameter($_))
  } keys %$beside;
  return unless @unapplied;

  _pg_refuse(sprintf
    'PostgreSQL ev does not apply connection parameter(s) given beside an '
  . 'AccessBroker (%s): its pooled connections and the listen connection are '
  . "opened from the broker's answer alone, and would be opened without %s. "
  . "Give %s in the broker's answer: the DBI form "
  . "[ 'dbi:Pg:...;<parameter>=...', \$user, \$password ] with the parameter in "
  . 'the DSN, or a hash of libpq connection parameters answered to this '
  . 'transport (connect_info_for_storage). A libpq parameter spelled with a '
  . 'capital (Sslmode) is refused as well: DBI takes it for an attribute. '
  . 'Beside the broker it takes '
  . 'pool_size, and DBI attributes, which are for the DBI connection of the '
  . 'owning storage and dropped here',
    join(', ', @unapplied), (@unapplied > 1 ? 'them' : 'it') x 2);
}

# Connect info, in any form connect_info's POD lists, as the
# [ $conninfo, \%opts ] pair core's _normalize_async_connect_info splits. The
# one place this transport reads connect info, whatever it comes from (karr
# k61, k64): what connect_info is given, and what a broker answers -- at
# attach and for every connection -- when called with broker => 1. So a form
# is read the same from both, and what is refused here never reaches EV::Pg.
#
# The measure is the owning sync storage, which opens its dbh from the same
# connect info (karr k58): a form it reads as one connection
# (DBIO::Storage::DBI::_normalize_connect_info) is read as that connection
# here, and what it connects from in a way this transport cannot follow -- a
# code reference -- is refused. Croaks naming the form, never a value.
#
# Two rules hang on where the connect info comes from. A hash that stands in
# no array is a broker's answer only. And connect info that renders to the
# empty conninfo is refused from a broker (karr k61) and taken as static
# connect info, where what becomes of it is open (karr k66).
sub _pg_read_connect_info {
  my ($self, $info, %from) = @_;
  my ($pair, $shape);

  $info = [ $info, {} ] if $from{broker} && ref $info eq 'HASH';

  if (ref $info eq 'ARRAY') {
    # What the owning storage applies itself -- async, its storage and SQL
    # maker options -- is no part of a connection: taken out by core, of the
    # attribute hashes of whichever form (a broker's answer comes unstripped).
    # Core keeps what it took out for the storage; that is connect_info's to
    # set, not every reading's.
    my $stripped = do {
      local $self->{_storage_options};
      $self->_strip_private_connect_attrs($info);
    };
    my ($first, $opts) = @$stripped;
    my $paired = @$info <= 2 && (!defined $opts || ref $opts eq 'HASH');

    if (defined $first && !ref $first && $first =~ /^dbi:/i) {
      ($pair, $shape) = $self->_pg_read_dbi_form($stripped, 'a DBI-form arrayref', $from{broker});
    }
    elsif (ref $first eq 'CODE') {
      $shape = $self->_pg_code_shape(undef, $from{broker});
    }
    elsif (!$paired) {
      # a libpq conninfo string followed by a user and password, which would
      # be dropped; anything else nobody reads: named by its elements below
    }
    elsif (ref $first eq 'HASH') {
      # The single hash, as the owner reads it.
      my %hash   = %$first;
      my $is_dsn = exists $hash{dsn} ? 'dsn'
                 : defined $hash{dbname} && !ref $hash{dbname} && $hash{dbname} =~ /^dbi:/i ? 'dbname'
                 : undef;

      if (delete $hash{dbh_maker}) {
        $shape = $self->_pg_code_shape('dbh_maker', $from{broker});
      }
      elsif (defined $is_dsn) {
        # { dsn => $dsn, user => ..., password => ..., %attributes } is
        # [ $dsn, $user, $password, \%attributes ]. A dbname that is a whole
        # DSN is the dsn where there is none; host and port cannot go into
        # it, which the owner refuses too, and empty ones are none.
        my @beside = $is_dsn eq 'dbname'
          ? grep { defined $hash{$_} && length $hash{$_} } qw( host port ) : ();
        if (@beside) {
          $shape = 'a hashref whose dbname is a whole DSN, with ' . join(' and ', @beside) . ' beside it';
        }
        else {
          ($pair, $shape) = $self->_pg_read_dbi_form(
            [ delete $hash{$is_dsn}, delete @hash{qw( user password )}, \%hash ],
            $is_dsn eq 'dsn' ? 'a hashref with a dsn key' : 'a hashref with a DSN for its dbname',
            $from{broker},
          );
          $pair->[1] = $opts if $pair && $opts;
        }
      }
      else {
        # A hash of libpq connection parameters, this transport's own form.
        # A key that is a DBI attribute's by its name is the owner's, for its
        # dbh, and dropped as the attributes of the DBI form are.
        my @attributes = grep { $self->_pg_is_dbi_attribute($_) } keys %hash;
        # ... unless it is a libpq parameter by another case (karr k80,
        # Sslmode): dropped as an attribute it would leave the connection
        # without it, silently. Refused naming the key, never a value.
        my @cased = sort grep {
          is_libpq_parameter($_) && defined $hash{$_} && length $hash{$_}
        } @attributes;
        delete @hash{@attributes};
        my ($ref_key) = grep { ref $hash{$_} } sort keys %hash;
        if (@cased) {
          $shape = sprintf 'a hashref of libpq connection parameters whose '
            . 'key(s) (%s) are libpq parameters spelled with a capital: DBI '
            . 'takes that for an attribute, which this transport drops, and '
            . 'the connection would be opened without the parameter -- '
            . 'libpq parameters are lower case', join(', ', @cased);
        }
        elsif (defined $ref_key) {
          $shape = "its libpq connection parameter '$ref_key' is a reference, not a value";
        }
        else {
          $pair = [ \%hash, $opts ];
        }
      }
    }
    elsif (!ref $first && ($from{broker} ? defined $first && length $first : 1)) {
      # A libpq conninfo string. Static connect info may give none at all.
      $pair = [ $first, $opts ];
    }
  }

  if ($pair) {
    return $pair unless $from{broker};
    # Whatever its shape, an answer that renders to the empty conninfo is
    # refused (karr k61): libpq fills an empty conninfo from its environment
    # and defaults (PGHOST, PGUSER, ...), so the connection would go where the
    # process environment points instead of where the broker said. Rendered as
    # the pool and the listen connection render it, so the two cannot differ.
    my ($conninfo) = $self->_normalize_async_connect_info($pair);
    return $pair if conninfo_string($conninfo) =~ /\S/;
    $shape = sprintf
      'no libpq connection parameter with a value in %s -- '
    . 'libpq would fill an empty conninfo from its environment and defaults',
      $self->_pg_describe_shape(ref $info->[0] eq 'HASH' ? $info->[0] : $info);
  }

  _pg_refuse(sprintf(
    'PostgreSQL ev cannot connect from %s: %s. '
  . "It takes a DBI-form arrayref [ 'dbi:Pg:...', \$user, \$password, \\%%attrs ], "
  . "a hashref with that DSN for its dsn ({ dsn => 'dbi:Pg:...', user => ..., password => ... }), "
  . 'a hashref of libpq connection parameters (dbname, host, port, user, password, ...), '
  . 'or an arrayref of such a hashref or a libpq conninfo string, optionally '
  . 'followed by an options hashref',
    ($from{broker} ? 'what the AccessBroker returned' : 'this connect info'),
    $shape // $self->_pg_describe_shape($info)),
    _pg_answer_connect_info($info));
}

# The DBI form [ $dsn, $user, $password, \%attrs, \%extra_attributes ], read
# for _pg_read_connect_info: the pair dbi_to_conninfo makes of it, or else
# (undef, $shape) -- what is wrong with it, for a message. $form names what
# the DSN came in.
sub _pg_read_dbi_form {
  my ($self, $dbi, $form, $from_broker) = @_;
  my $dsn = $dbi->[0];
  # DBI_USER and DBI_PASS are read for static connect info only (karr k66).
  my $env = $from_broker ? 0 : 1;

  # dbi_to_conninfo's own test, made here: it dies quoting the DSN -- its
  # passwords masked since karr k78, the rest as it came -- and this message
  # names the form of connect info and nothing that was in it.
  my ($driver) = DBIO::PostgreSQL::EV::ConnectInfo::dbi_dsn_parts($dsn);
  if (defined $driver && $driver =~ /\APg\z/i) {
    my $pair = eval { DBIO::PostgreSQL::EV::ConnectInfo::dbi_to_conninfo($dbi, env => $env) };
    if ($pair) {
      # A DSN that names no target would have libpq take it from PGHOST,
      # PGDATABASE, ... -- refused with the words of the sync storage and of
      # future_io (karr k95; DBIO::PostgreSQL::Util::dsn_names_target).
      _pg_refuse(
        'Cannot connect with a DBD::Pg DSN that names no dbname, host or port, '
      . 'so libpq would take the target from its environment (PGHOST, '
      . 'PGDATABASE, ...). Give at least one of dbname, host or port (or '
      . 'service, hostaddr) in the DSN.',
        $dbi,
      ) unless DBIO::PostgreSQL::Util::dsn_names_target($dsn);
      return $pair;
    }
    # What is left for it to die of is a DSN libpq cannot read (karr k58),
    # and that complaint holds no word of the DSN.
    return (undef, "$form -- " . $@ =~ s/\s+\z//r);
  }

  # The driver's name alone. What stands between 'dbi:' and the next colon is
  # more than that: DBI takes attributes there, Password among them
  # ('dbi:Pg(Password=>...):'), and a DSN gone wrong may have its parameters
  # there (karr k78).
  my ($named) = defined $dsn && !ref $dsn ? $dsn =~ /^dbi:(\w*)/i : ();
  return (undef, "$form whose DSN is not dbi:Pg:<parameters>"
    . (defined $named ? " (DBI driver '$named')" : ''));
}

# What a code reference in connect info is, for an error message: the owner's
# way to a dbh -- a connection coderef, or a hash's dbh_maker -- and nothing
# this transport can open an EV::Pg connection from.
sub _pg_code_shape {
  my ($self, $key, $from_broker) = @_;
  # Beside a broker answering code, core refuses every key it does not
  # consume itself, a DBI attribute as much as a client parameter (core
  # k310; karr k80): named here too, never a value.
  my %consumed = map { $_ => 1 }
    qw( dsn user password dbh_maker dbname host port pool_size ignore_version );
  my $given    = $from_broker ? $self->_access_broker_call_attributes : {};
  my @beside   = sort grep {
    !$consumed{$_} && defined $given->{$_} && length $given->{$_}
  } keys %$given;
  return 'a code reference that makes a DBI handle' . (defined $key ? " ($key)" : '')
    . ' -- this transport opens its own connections, from libpq parameters'
    . (@beside ? sprintf ', and %s beside the broker would be dropped with it: %s',
        join(', ', @beside), 'the code opens the connection and nothing beside the broker goes to it'
      : '');
}

# The shape of connect info, for an error message: types and hash keys, never
# values -- they carry the password.
sub _pg_describe_shape {
  my ($self, $value) = @_;
  return 'a plain string' unless ref $value;
  return 'an empty hashref' if ref $value eq 'HASH' && !%$value;
  return sprintf 'a hashref with keys (%s)', join ', ', sort keys %$value
    if ref $value eq 'HASH';
  return sprintf 'an arrayref of (%s)', join ', ',
    map { !defined $_ ? 'undef' : ref $_ ? ref($_) . ' ref' : 'string' } @$value
    if ref $value eq 'ARRAY';
  return 'a ' . ref($value) . ' ref';
}


sub pool {
  my $self = shift;
  $self->{pool} ||= do {
    my %args = (
      storage      => $self,
      size         => $self->{_pool_size},
      future_class => $self->future_class,
      on_error     => sub { warn "DBIO::PostgreSQL::EV pool error: $_[0]\n" },
    );

    if (my $provider = $self->_conninfo_provider) {
      $args{conninfo_provider} = $provider;
    }
    else {
      $args{conninfo} = $self->_conninfo_string;
    }

    DBIO::PostgreSQL::EV::Pool->new(%args);
  };
}


sub _conninfo_string {
  my ($self, $ci) = @_;
  if (! defined $ci) {
    my $provider = $self->_conninfo_provider;
    $ci = $provider ? $provider->() : $self->{_conninfo};
  }
  my $string = conninfo_string($ci);
  # An empty conninfo is libpq's own environment and defaults (karr k66); a
  # blank, where the pool takes none that is false.
  return defined $string && !length $string ? ' ' : $string;
}

# --- Transaction context seams ------------------------------------------------


sub _txn_context_class { 'DBIO::PostgreSQL::EV::TransactionContext' }


sub _txn_conn_accessor { 'txn_conn' }


sub _txn_commit_rolled_back {
  my ($self, $pg) = @_;
  return 0 unless $pg->can('result_meta');
  my $meta = $pg->result_meta;
  return $meta && ($meta->{cmd_status} // '') eq 'ROLLBACK' ? 1 : 0;
}


sub _txn_inner_future {
  my ($self, $txn_ctx, $conn, $inner) = @_;
  $inner->_refuse_queued
    if Scalar::Util::blessed($inner) && $inner->can('_refuse_queued');
  return $self->next::method($txn_ctx, $conn, $inner);
}

# --- SQL shaping seam ---------------------------------------------------------


sub _transform_sql {
  my ($self, $sql) = @_;
  return DBIO::PostgreSQL::EV::Storage::_Refusal::of_util(
    sub { DBIO::PostgreSQL::Util::number_placeholders($sql) },
  );
}

# --- Async query execution (transport seams) ----------------------------------


sub _query_async {
  my ($self, $sql, $bind, $bind_attrs) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  my $trace_end = $self->_debug_query($sql, $bind, $bind_attrs);

  # The pool this statement begins on is the one it ends on: its completion
  # releases to $pool, never to $self->pool asked again (karr k88).
  my $pool = $self->pool;
  my $f = $pool->acquire->then(sub {
    my $pg = shift;
    return $self->_dispatch_query($pg, $sql, $bind, $pool, $pool->_lease($pg));
  });
  # Future.pm holds a then-sequence only weakly from the Future it waits on: a
  # caller that drops $f while the pool is full takes the chain with it, the
  # body never runs and the connection it would borrow never comes back (core
  # k407, as in DBIO::Async::Storage, karr k46).
  $f->retain if $f->can('retain');
  $f->on_ready($trace_end) if $trace_end;
  return $f;
}


sub _dispatch_query {
  my ($self, $pg, $sql, $bind, $pool, $lease) = @_;
  croak '_dispatch_query needs the pool the connection was acquired from' unless $pool;
  my $f   = $self->future_class->new;
  my $pid = $$;
  my $guard = $self->_pg_cancel_guard($f, $pg, $pool);
  # The values for the text of an error: copies of the plain values, so the
  # callback holds them for the statement's flight and never $bind itself.
  my $values = _pg_error_values(@$bind);
  my $on_result = sub {
    my ($rows, $err) = @_;
    return if $$ != $pid;   # a forked child's copy (karr k45)
    # Global destruction: EV::Pg cancels the statements still waiting and calls
    # back after the captured connection and Future are gone; nothing to deliver.
    return unless defined $self && defined $pg && defined $f && defined $pool;
    my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);
    $guard->{answered} = 1;
    # Here, before anything is deferred: error_fields is this statement's only now (karr k74).
    $err = $self->_pg_server_error($pg, $err, $values);
    my $settle = sub {
      $self->_pg_settle_and_release($pool, $pg, $lease, $f, $err, ref $rows eq 'ARRAY' ? @$rows : $rows);
    };
    # A cancel request is out: the connection goes back when it is answered (karr k75).
    if ($guard->{cancelling} && $pg->is_connected) {
      $guard->{then} = sub {
        my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);
        $settle->();
      };
      return;
    }
    $settle->();
  };
  # EV::Pg croaks before it queues $on_result, so that never runs: release
  # here, once (karr k46).
  unless (eval { $pg->query_params($sql, $bind, $on_result); 1 }) {
    my $err = $self->_pg_dispatch_error($@);
    $self->_pg_report_if_dead($pool, $pg);
    $pool->release($pg, $lease);
    $f->fail($err);
  }
  return $f;
}

# EV::Pg's own croak -- "not connected" -- is raised from XS and carries the
# place of the perl statement that called it: a line of this file. That says
# where the library is installed and a line that moves with every release,
# neither about the statement (karr k88; as dbio-postgresql karr k120 did for
# the future_io transport). The text and its newline are what a caller gets.
# libpq's own messages end in a newline and carry no place; they pass as they
# are, and so does anything that is not a plain string.
sub _pg_dispatch_error {
  my ($self, $err) = @_;
  return $err if ref $err or not defined $err;
  $err =~ s/ at (?:(?! at )[^\n])* line \d+\.\n\z/\n/;
  return $err;
}


sub _pg_refuse { goto &DBIO::PostgreSQL::EV::Storage::_Refusal::raise }

# The connect info a refusal is about, in the DBI form the trace masks
# (DBIO::Util::masked_longmess): from a hash of connection parameters or with a
# dsn, a DBI-form arrayref, or the hash of a [ \%hash, \%opts ] pair. Nothing
# for anything else.
sub _pg_answer_connect_info {
  my ($info) = @_;
  $info = $info->[0] if ref $info eq 'ARRAY' && ref $info->[0] eq 'HASH';
  return [ @{$info}{qw( dsn user password )}, { Password => $info->{Password} } ]
    if ref $info eq 'HASH';
  return [ @{$info}[0 .. 3] ] if ref $info eq 'ARRAY';
  return undef;
}

# Where a refusal is thrown from. DBIO::Exception->throw names the first frame
# that is not this package's, nor of a package the patterns of
# _skip_namespace_frames name (DBIO::Carp): DBIO's own, and here Future's and
# EV's as well -- a refusal reached in a callback of the loop would otherwise
# name Future's code. %Carp::Internal keeps these frames out of the origin the
# exception names (the transport's method that refused) and out of the start
# of a stack trace.
{
  package # not a class of its own: the place a refusal is thrown from
    DBIO::PostgreSQL::EV::Storage::_Refusal;

  $Carp::Internal{ (__PACKAGE__) }++;

  sub _skip_namespace_frames { '^Future\b|^EV\b' }

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


sub _pg_server_error {
  my ($self, $pg, $err, $values) = @_;
  return $err if ref $err or not defined $err;
  my $text = $self->_pg_mask_error_text($err, $values);
  return $text unless Scalar::Util::blessed($pg) && $pg->can('error_fields');
  my $fields = $pg->error_fields;
  return $text unless ref $fields eq 'HASH';
  my ($severity, $primary, $sqlstate) = @$fields{qw( severity primary sqlstate )};
  return $text unless defined $severity && length $severity
                   && defined $primary  && length $primary;
  my $verbose = defined $sqlstate && length $sqlstate ? qr/(?:\Q$sqlstate\E: )?/ : qr//;
  return $text unless $err =~ /\A\Q$severity\E:  $verbose\Q$primary\E/;
  return DBIO::Exception::Server->new(
    message    => $text,
    sqlstate   => $sqlstate,
    constraint => $fields->{constraint},
    table      => $fields->{table},
    detail     => $self->_pg_mask_error_detail($fields->{detail}, $values),
  );
}


sub _pg_mask_error_text {
  my ($self, $text, $values) = @_;
  return $text if not defined $text or ref $text;
  my $masked = eval {
    DBIO::PostgreSQL::Util::mask_error_details(
      DBIO::Util::mask_bound_values($text, $values)
    );
  };
  return defined $masked ? $masked : $text;
}

# The detail field of the server with the values taken out: the bound values,
# then the values of its forms (Key (name)=(***), Failing row contains (***)).
sub _pg_mask_error_detail {
  my ($self, $detail, $values) = @_;
  return $detail if not defined $detail or ref $detail;
  my $masked = eval {
    DBIO::PostgreSQL::Util::mask_detail_values(
      DBIO::Util::mask_bound_values($detail, $values)
    );
  };
  return defined $masked ? $masked : $detail;
}

# The values of a statement's binds as the net takes them, read the way core's
# DBIO::Storage::DBI::_plain_error_values reads a bind list: undef and a
# reference that is no plain value fall away, an object with a stringification
# is its string. A new list of copies -- what a callback keeps for the flight
# of its statement in place of the bind array (t/05).
sub _pg_error_values {
  my @plain;
  for my $v (@_) {
    next unless defined $v;
    if (length ref $v) {
      my $p = DBIO::Util::is_plain_value($v) or next;
      push @plain, "$$p" if defined $$p;
    }
    else {
      push @plain, $v;
    }
  }
  return \@plain;
}

# How a callback this class hands to EV::Pg ends a pooled statement --
# _dispatch_query, _dispatch_notify, copy_in: settle $f -- fail it with $err if
# there is one, else done with @result -- and only then hand $pg back to
# $pool, the pool it was acquired from, with $lease, the lease of the borrow
# (a stale release then takes nothing, karr k89). Settle first: the Future's then callbacks run with $pg still checked
# out (karr k44, k51), and the release runs inside the caller's delivery frame.
# An on_done / on_ready / on_fail that dies escapes done / fail, so the release
# must not depend on it returning; the die goes on to EV::Pg after the release,
# which warns it (karr k50).
#
# "There is one" is a defined $err, here and in every callback of this class:
# EV::Pg calls a statement's callback with ($result) when it went through and
# with (undef, $message) when it did not, the message a string that is never
# empty -- libpq's, or a text of its own where libpq has none ("connection
# lost", "pipeline aborted", ...; Pg.xs, 0.02 and 0.07 alike).
#
# $pool is handed in by whoever acquired $pg, and is the only pool this talks
# to -- never $self->pool (karr k88, this transport's half of karr dbio-async
# k46). The settling runs the caller's callbacks, and one of them may
# disconnect the storage: the slot pool() fills is empty then, and asked here
# it built a new pool on the disconnected storage, to release into it a
# connection that pool had never held -- or died, where the storage had
# nothing left to connect from. $pool is shut down by then, and takes the
# report and the release as no-ops.
sub _pg_settle_and_release {
  my ($self, $pool, $pg, $lease, $f, $err, @result) = @_;
  my $settled = eval {
    if (defined $err) {
      $f->fail($err);
    } else {
      $f->done(@result);
    }
    1;
  };
  my $settle_err = $@;
  $self->_pg_report_if_dead($pool, $pg) if defined $err;   # before the release (karr k49)
  $pool->release($pg, $lease);
  die $settle_err unless $settled;
  return;
}


sub _pg_report_if_dead {
  my ($self, $pool, $pg) = @_;
  $pool->_mark_connection_dead($pg) unless $pg->is_connected;
  return;
}


sub _reset_pool_connection {
  my ($self, $pg) = @_;
  my $f   = $self->future_class->new;
  my $pid = $$;

  my $on_result = sub {
    my (undef, $err) = @_;
    return if $$ != $pid;   # a forked child's copy (karr k45)
    # Global destruction: EV::Pg cancels the statements still waiting and calls
    # back after the captured connection and Future are gone; nothing to deliver.
    return unless defined $self && defined $pg && defined $f;
    my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);
    return if $f->is_ready; # cancelled by the pool: it retired the connection
    if (defined $err) {
      $f->fail("the session of a pool connection could not be reset: DISCARD ALL failed: "
             . $self->_pg_mask_error_text($err));
      return;
    }
    # The connect actions run the EV loop to the end of each statement
    # (_run_pool_connect_statement), which EV::Pg does not take inside a
    # callback of the very connection they run on: it would hand the answer of
    # the first statement to this callback, still running. So they run from a
    # timer, after this callback has returned.
    my $timer;
    $timer = EV::timer(0, 0, sub {
      undef $timer;
      return if $$ != $pid || !defined $f || !defined $pg || $f->is_ready;
      unless ($pg->is_connected && eval { $self->_setup_pool_connection($pg); 1 }) {
        $f->fail("the session of a pool connection could not be reset: "
               . "its connect actions could not be run again\n");
        return;
      }
      $f->done;
    });
    return;
  };

  # EV::Pg croaks before it queues $on_result ("not connected"): the Future
  # fails and the pool retires the connection.
  unless (eval { $pg->query('DISCARD ALL', $on_result); 1 }) {
    $f->fail($self->_pg_dispatch_error($@));
  }
  return $f;
}

# --- The pinned path's one-statement-at-a-time queue (karr k48) ---------------
# See _query_async_pinned. The state is kept per connection, by refaddr, in
# records of { pid, conn } -- the process that made the record (karr k45) and
# the connection, weakly. A record of another process, or whose connection has
# gone, is stale and counts as absent, so it can neither outlive its connection
# nor land on a later one at the same address (as Pool.pm's %PG_OPENED).
#
#   %PG_PINNED    a record exists while a statement of the pinned path is in
#                 flight on the connection outside pipeline mode, plus
#                   queue   the statements waiting behind it, [ $sql, $bind, $f ]
#                   ending  'COMMIT' / 'ROLLBACK' once one of those is queued
#                           or in flight; a statement issued then is refused.
#                           Core ends the transaction context at that moment
#                           too (core k237), so what still meets this refusal
#                           is a caller past the context, on txn_conn
#   %PG_PIPELINE  a record exists between _pipeline_enter and _pipeline_exit
my %PG_PINNED;
my %PG_PIPELINE;

# A statement in flight whose Future is cancelled asks the server to stop it
# (karr k75): EV::Pg cancel_async, libpq 17+, never the blocking cancel. Returns
# the statement's guard, which the statement's completion callback keeps:
#   answered    the statement's result is in
#   cancelling  a cancel request is out and not answered
#   then        what the result's callback left undone while it was
# The callback hands the rest of its work to `then` when it finds a request
# out, and the request's answer runs it: the connection goes on -- released,
# its next statement sent -- only when result and answer are both in, else the
# request reaches the next statement of the connection. A request that ends
# with an error marks the connection dead for its pool ($pool, else the
# storage's, never built here: karr k88). The guard stays empty, and the cancel
# a no-op, without the capability, for a Future that is not pending, and in
# pipeline mode.
sub _pg_cancel_guard {
  my ($self, $f, $pg, $pool) = @_;
  my $guard = {};
  return $guard if $f->is_ready or !$pg->can('cancel_async');
  my $pid = $$;
  Scalar::Util::weaken(my $weak_pg = $pg);
  $f->on_cancel(sub {
    return if $$ != $pid or $guard->{answered} or $guard->{cancelling};
    my $pg = $weak_pg or return;
    return if _pg_conn_record(\%PG_PIPELINE, $pg) or !$pg->is_connected;
    # A retirement has sent the request already (Pool::_shutdown_connection).
    return if DBIO::PostgreSQL::EV::Pool::_pg_cancel_is_out($pg);
    $guard->{cancelling} = 1;
    DBIO::PostgreSQL::EV::Pool::_pg_cancel_begin($pg);
    my $sent = eval {
      $pg->cancel_async(sub {
        my ($ok, $err) = @_;
        return if $$ != $pid;
        $guard->{cancelling} = 0;
        if (!$ok and my $conn = $weak_pg) {
          my $owner = $pool || $self->{pool};
          $owner->_mark_connection_dead($conn) if $owner;
        }
        my $then = delete $guard->{then};
        my $ran = eval { $then->() if $then; 1 };
        my $died = $@;
        # A retirement that waited for this answer closes the connection now.
        DBIO::PostgreSQL::EV::Pool::_pg_cancel_end($weak_pg, $ok, $err);
        die $died unless $ran;
      });
      1;
    };
    unless ($sent) {
      $guard->{cancelling} = 0;
      DBIO::PostgreSQL::EV::Pool::_pg_cancel_end($pg);
    }
  });
  return $guard;
}


sub _query_async_pinned {
  my ($self, $pg, $sql, $bind, $bind_attrs) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  my $trace_end = $self->_debug_query($sql, $bind, $bind_attrs);

  my $f = $self->future_class->new;
  $f->on_ready($trace_end) if $trace_end;

  # Pipeline mode: libpq takes the statement at once (no callbacks on $f yet).
  if (my $pipeline = _pg_conn_record(\%PG_PIPELINE, $pg)) {
    # Behind the sync point the server does not answer a statement until the
    # next sync (karr k88): it waits here for pipeline mode to be left.
    if ($pipeline->{synced}) {
      push @{ $pipeline->{queue} }, [ $sql, $bind, $f ];
      return $f;
    }
    my $err = $self->_pg_send_pinned($pg, $sql, $bind, $f, 0);
    $f->fail($err) if defined $err;
    return $f;
  }

  my $st = _pg_conn_record(\%PG_PINNED, $pg);
  if ($st && $st->{ending}) {
    $f->fail(
      "Statement refused: this transaction's $st->{ending} has already been "
    . 'issued on its connection, and the statement would run after it, '
    . 'outside the transaction. Chain every statement of a txn_do coderef '
    . "into the Future the coderef returns.\n"
    );
    return $f;
  }

  my $in_flight = $st ? 1 : 0;
  $st ||= _pg_conn_record(\%PG_PINNED, $pg, 1);
  $st->{ending} = $sql if $sql =~ /\A(?:COMMIT|ROLLBACK)\z/;
  push @{ $st->{queue} }, [ $sql, $bind, $f ];
  $self->_pg_pinned_next($pg) unless $in_flight;
  return $f;
}

sub _pg_conn_record {
  my ($table, $pg, $create) = @_;
  my $addr = Scalar::Util::refaddr($pg);
  my $rec  = $table->{$addr};
  return $rec if $rec && $rec->{pid} == $$ && defined $rec->{conn};
  delete $table->{$addr};
  return unless $create;
  $rec = $table->{$addr} = { pid => $$, conn => $pg, queue => [] };
  Scalar::Util::weaken($rec->{conn});
  return $rec;
}

# Nothing of the pinned path is in flight on $pg: send what waits in its queue,
# up to the first statement EV::Pg takes -- one cancelled in the queue is
# skipped, bar COMMIT and ROLLBACK (karr k75). When none is left, the record goes --
# the connection is idle. A statement EV::Pg refuses fails only once that is
# decided, so a callback on it finds the queue consistent; a die out of such a
# callback is returned, for the caller to rethrow once it has settled what it
# owes (the karr k50 order).
sub _pg_pinned_next {
  my ($self, $pg) = @_;
  my $st = _pg_conn_record(\%PG_PINNED, $pg) or return;
  my ($sent, @refused);
  while (my $next = shift @{ $st->{queue} }) {
    my ($sql, $bind, $f) = @$next;
    # Cancelled while it waited: not sent (karr k75). Core's COMMIT and
    # ROLLBACK are not skipped -- the queue knows them as the end ('ending'),
    # and the transaction would stay open, with its locks.
    next if $f->is_cancelled && $sql !~ /\A(?:COMMIT|ROLLBACK)\z/;
    my $err = $self->_pg_send_pinned($pg, $sql, $bind, $f, 1);
    if (!defined $err) { $sent = 1; last }
    push @refused, [ $f, $err ];
  }
  delete $PG_PINNED{ Scalar::Util::refaddr($pg) } unless $sent;

  my $died;
  for my $refused (@refused) {
    my ($f, $err) = @$refused;
    eval { $f->fail($err); 1 } or $died //= $@;
  }
  return $died;
}

# Send one statement of the pinned path; undef once EV::Pg has taken it, else
# EV::Pg's error -- it croaks before it queues the callback (karr k48, the k46
# pattern). Named sub, like _dispatch_query (karr k29): the completion callback
# is created here and does not hold $bind. The callback of a $queued statement
# sends the next one waiting before it settles $f.
sub _pg_send_pinned {
  my ($self, $pg, $sql, $bind, $f, $queued) = @_;
  my $pid = $$;
  # Pipeline mode (not $queued) sends no cancel request (karr k75).
  my $guard = $queued ? $self->_pg_cancel_guard($f, $pg) : {};
  my $values = _pg_error_values(@$bind);   # as in _dispatch_query: copies, not $bind
  my $on_result = sub {
    my ($rows, $err) = @_;
    return if $$ != $pid;   # a forked child's copy (karr k45)
    # Global destruction: EV::Pg cancels the statements still waiting and calls
    # back after the captured connection and Future are gone; nothing to deliver.
    return unless defined $self && defined $pg && defined $f;
    my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);
    $guard->{answered} = 1;
    $err = $self->_pg_server_error($pg, $err, $values);   # karr k74
    my $settle = sub {
      # libpq is idle again -- EV::Pg delivers after the statement's last result
      # -- so the next statement goes out before $f's callbacks can issue more.
      my $next_died = $queued ? $self->_pg_pinned_next($pg) : undef;
      if (defined $err) { $f->fail($err) } else { $f->done(ref $rows eq 'ARRAY' ? @$rows : $rows) }
      die $next_died if defined $next_died;
      # Do NOT release -- the connection is pinned for the duration of the txn
    };
    # A cancel request is out: the next statement goes when it is answered (karr k75).
    if ($guard->{cancelling} && $pg->is_connected) {
      $guard->{then} = sub {
        my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);
        $settle->();
      };
      return;
    }
    $settle->();
  };
  my $sent = eval { $pg->query_params($sql, $bind, $on_result); 1 };
  return $sent ? undef : $self->_pg_dispatch_error($@);
}

# --- Pool connect-action replay seam (core k68) -------------------------------


sub _run_pool_connect_statement {
  my ($self, $conn, $sql, $attrs, @bind) = @_;
  require EV;

  # The statement's result is always waited for on the EV loop: refuse before
  # anything is sent (karr k52).
  $self->_pg_refuse_connect_wait;

  # Whatever the loop runs from here on runs above the spawn that opens $conn:
  # the pool counts the connection and hands it out only after this has
  # returned (karr k88).
  my $replaying = DBIO::PostgreSQL::EV::Future->_replaying($conn);

  # The connection was just spawned; its async connect may still be in flight.
  # Block the EV loop until it is ready (the core seam's synchronous contract).
  # Prefer the pool's per-connection readiness Future
  # (DBIO::Storage::PoolBase::_connection_ready_future, core k75), which is
  # FAILED on a connect error -- so a bad connect surfaces as a thrown error
  # here rather than busy-spinning on is_connected forever. Fall back to
  # is_connected for a pool that does not expose the readiness seam (e.g. a
  # bare test double that is not a PoolBase subclass at all).
  my $pool = $self->pool;
  if ($pool->can('_connection_ready_future')) {
    my $ready = $pool->_connection_ready_future($conn);
    $self->_pg_connect_wait(sub { $ready->is_ready });
    $ready->get;   # rethrows a connect error
  }
  else {
    $self->_pg_connect_wait(sub { $conn->is_connected });
  }

  my $done = 0;
  my ($res, $err);
  my $cb = sub { ($res, $err) = @_; $done = 1 };
  if (@bind) {
    $conn->query_params($self->_transform_sql($sql), [@bind], $cb);
  }
  else {
    $conn->query($sql, $cb);
  }
  $self->_pg_connect_wait(sub { $done });

  croak 'pool connect statement failed: '
      . $self->_pg_mask_error_text($err, _pg_error_values(@bind))
    if defined $err;

  # dbio_rows (core k358): hand back the rows, as selectall_arrayref does. A
  # statement that answers no rows (SET) has a command tag, not an array.
  if (ref $attrs eq 'HASH' and $attrs->{dbio_rows}) {
    return ref $res eq 'ARRAY' ? $res : [];
  }
  return;
}

# Run the EV loop until $ready->() is true, refused before every iteration.
sub _pg_connect_wait {
  my ($self, $ready) = @_;
  until ($ready->()) {
    $self->_pg_refuse_connect_wait;
    EV::run(EV::RUN_ONCE());
  }
  return;
}

# Die while one of this transport's callbacks runs for a connection with more
# results due: a loop run now would read them (karr k52; the await refusal of
# karr k44).
sub _pg_refuse_connect_wait {
  my ($self) = @_;
  my $pg = DBIO::PostgreSQL::EV::Future::_delivering_with_more_due() or return;
  croak 'Blocking wait refused: the pool is opening a new connection and '
    . 'replaying on_connect_do / on_connect_call on it, which runs the EV '
    . 'loop, inside a callback of an EV::Pg connection that has '
    . ($pg->pending_count - 1) . ' more result(s) due; EV::Pg would hand '
    . 'the next of them to the callback that is still running, then spin. '
    . 'Chain this call with ->then onto the statement in flight, or run it '
    . 'on the transaction context ($ctx->select_async, ...)';
}

# --- Pipeline mode seams ------------------------------------------------------
# The inherited DBIO::Storage::Async::pipeline scaffold acquires a connection,
# brackets the batch with these three seams and releases the connection. EV::Pg
# expresses pipelining natively, so the base scaffold fits exactly -- no
# parallel pipeline() is needed (WP4 decision).


sub _pipeline_enter {
  my ($self, $pg) = @_;
  # EV::Pg's croak names the line here that called it (karr k88)
  eval { $pg->enter_pipeline; 1 } or die $self->_pg_dispatch_error($@);
  _pg_conn_record(\%PG_PIPELINE, $pg, 1);
  return;
}


sub _pipeline_sync {
  my ($self, $pg) = @_;
  my $f   = $self->future_class->new;
  my $pid = $$;
  my $pipeline = _pg_conn_record(\%PG_PIPELINE, $pg);
  $pg->pipeline_sync(sub {
    my (undef, $err) = @_;
    return if $$ != $pid;   # a forked child's copy (karr k45)
    return unless defined $self && defined $pg && defined $f;   # global destruction
    return if $f->is_ready; # EV::Pg's second call after an error (karr k47)
    my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);
    if (defined $err) { $f->fail($self->_pg_server_error($pg, $err)) } else { $f->done }
  });
  $pipeline->{synced} = 1 if $pipeline;
  return $f;
}


sub _pipeline_exit {
  my ($self, $pg) = @_;
  my $pipeline = _pg_conn_record(\%PG_PIPELINE, $pg);
  my $exited   = eval { $pg->exit_pipeline; 1 };
  my $error    = $self->_pg_dispatch_error($@);   # without the place (karr k88)
  my @waiting  = $pipeline ? splice @{ $pipeline->{queue} } : ();

  if (!$exited) {
    # Still in pipeline mode: what waited for the exit never goes out.
    for my $waiting (@waiting) {
      eval { $waiting->[2]->fail($error); 1 };
    }
    die $error;
  }

  delete $PG_PIPELINE{ Scalar::Util::refaddr($pg) };
  return unless @waiting;

  # The statements a transaction issued behind the sync, its ROLLBACK among
  # them, go out now, one at a time, as on any pinned connection.
  my $st = _pg_conn_record(\%PG_PINNED, $pg, 1);
  for my $waiting (@waiting) {
    $st->{ending} = $waiting->[0] if $waiting->[0] =~ /\A(?:COMMIT|ROLLBACK)\z/;
    push @{ $st->{queue} }, $waiting;
  }
  my $died = $self->_pg_pinned_next($pg);
  die $died if defined $died;
  return;
}

# --- LISTEN/NOTIFY seams (core ADR 0056) --------------------------------------
#
# Core DBIO::Storage::Async owns the public listen / unlisten / notify /
# listen_alive / listen_reconnect, the hooks, the backoff and the machinery
# behind them -- including the queue that runs one LISTEN / UNLISTEN at a time
# on the listen connection, which replaced this class's own serialiser (karr
# k15, k43). What is left is EV::Pg's. Private helpers are named _pg_*, never
# _listen_*: they share an inheritance chain with core's private _listen_*
# helpers, and a same-named method appearing there later would be shadowed.
#
# The listen connection is a hashref, opaque to core:
#
#   pg     the EV::Pg handle, a DBIO::PostgreSQL::EV::Pool::_Connection; gone
#          once closed
#   state  what the handle's handlers do with what EV::Pg reports:
#            opening   connecting; an error fails the open
#            open      connected, not watched yet; notifications are held
#            watching  notifications go to core, an error is a lost connection
#            quiet     unwatched or closed; nothing reaches core any more
#   held   the notifications held while 'open', in arrival order


sub _listen_open {
  my ($self) = @_;
  my $provider = $self->_conninfo_provider;
  my $conninfo = $provider ? conninfo_string($provider->()) : $self->_conninfo_string;
  _pg_refuse('the listen connection has no connect info -- call connect_info first')
    unless defined $conninfo && length $conninfo;

  my $f    = $self->future_class->new;
  my $conn = { state => 'opening', held => [] };

  # Nothing else holds the connection before core receives it: the open's
  # Future does, until it is ready.
  my $hold = $conn;
  $f->on_ready(sub { undef $hold });

  $conn->{pg} = DBIO::PostgreSQL::EV::Pool->_new_connection(
    conninfo   => $conninfo,
    keep_alive => 1,
    $self->_pg_listen_handlers($f, $conn),
  );
  return $f;
}

# The handle's on_connect / on_error / on_notify. Built in a named sub, so they
# close over nothing but these arguments: the storage and the connection weakly
# -- the handle keeps its handlers for its lifetime, and the connection holds
# the handle -- and the open's Future only until the connect settles. Every one
# returns at once in a process other than the opener (karr k45).
sub _pg_listen_handlers {
  my ($self, $f, $conn) = @_;
  Scalar::Util::weaken(my $weak_self = $self);
  Scalar::Util::weaken(my $weak_conn = $conn);
  my $opening = $f;
  my $pid     = $$;

  my $on_connect = sub {
    return if $$ != $pid;
    my ($f, $conn) = ($opening, $weak_conn);
    undef $opening;
    return unless $f && $conn && !$f->is_ready;
    $conn->{state} = 'open';
    $f->done($conn);
    return;
  };

  my $on_error = sub {
    my ($err) = @_;
    return if $$ != $pid;
    chomp($err = defined $err ? "$err" : 'unknown error');
    if (my $f = $opening) {
      undef $opening;
      $f->fail("connecting the listen connection failed: $err") unless $f->is_ready;
      return;
    }
    my ($self, $conn) = ($weak_self, $weak_conn);
    return unless $self && $conn && $conn->{state} ne 'quiet';
    $self->_listen_lost($conn, "the listen connection was lost: $err");
    return;
  };

  my $on_notify = sub {
    my ($channel, $payload, $sender_pid) = @_;
    return if $$ != $pid;
    my ($self, $conn) = ($weak_self, $weak_conn);
    return unless $self && $conn;
    if ($conn->{state} eq 'watching') {
      $self->_listen_dispatch($channel, $payload, $sender_pid);
    }
    elsif ($conn->{state} eq 'open') {
      push @{ $conn->{held} }, [ $channel, $payload, $sender_pid ];
    }
    return;
  };

  return (
    on_connect => $on_connect,
    on_error   => $on_error,
    on_notify  => $on_notify,
  );
}


sub _listen_close {
  my ($self, $conn) = @_;
  $self->_pg_listen_quiet($conn);
  my $pg = delete $conn->{pg} or return;
  $pg->finish;
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

# One LISTEN / UNLISTEN on the listen connection. Named sub, like
# _dispatch_query (karr k29): the completion callback is created here.
sub _pg_listen_command {
  my ($self, $conn, $verb, $channel) = @_;
  my $sql = "$verb " . $self->_pg_quote_channel($channel);
  my $pg  = $conn->{pg}
    or _pg_refuse("$verb on channel '$channel': the listen connection is closed");

  my $f   = $self->future_class->new;
  my $pid = $$;
  my $on_result = sub {
    my (undef, $err) = @_;
    return if $$ != $pid;    # a forked child's copy (karr k45)
    # Closing the connection from inside this callback -- the last channel
    # unlistened by a callback on this Future -- makes EV::Pg call it again
    # with "connection finished" while it runs (see _pipeline_sync).
    return unless defined $self && defined $pg && defined $f;   # global destruction
    return if $f->is_ready;
    my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);
    if (defined $err) { $f->fail($self->_pg_server_error($pg, $err)) } else { $f->done }
  };

  # EV::Pg croaks before it queues $on_result, so that never runs: fail here
  # (karr k46).
  unless (eval { $pg->query($sql, $on_result); 1 }) {
    $f->fail($self->_pg_dispatch_error($@));
  }
  return $f;
}


sub _pg_quote_channel {
  my ($self, $channel) = @_;
  return DBIO::PostgreSQL::EV::Storage::_Refusal::of_util(
    sub { DBIO::PostgreSQL::Util::quote_channel($channel) },
  );
}


sub _listen_watch {
  my ($self, $conn) = @_;
  my $pg = $conn->{pg} or _pg_refuse('the listen connection is closed');
  _pg_refuse('the listen connection is not connected') unless $pg->is_connected;

  $conn->{state} = 'watching';
  while (my $n = shift @{ $conn->{held} }) {
    $self->_listen_dispatch(@$n);
    last unless $conn->{state} eq 'watching';   # a callback ended it
  }
  return;
}


sub _listen_unwatch {
  my ($self, $conn) = @_;
  $self->_pg_listen_quiet($conn);
  return;
}

# Nothing the handle reports reaches core any more. Safe from inside one of
# the handlers: EV::Pg holds a reference to the handler it is running.
sub _pg_listen_quiet {
  my ($self, $conn) = @_;
  $conn->{state} = 'quiet';
  @{ $conn->{held} } = ();
  my $pg = $conn->{pg} or return;
  $pg->$_(undef) for qw(on_connect on_error on_notify);
  return;
}


sub _listen_probe {
  my ($self, $conn) = @_;
  my $pg = $conn->{pg} or return 0;
  return 0 unless $pg->is_connected;
  return DBIO::PostgreSQL::EV::Pool->_pg_peer_closed($pg) ? 0 : 1;
}


sub _listen_delay {
  my ($self, $seconds) = @_;
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
  # Released to the pool it was acquired from (karr k88, as in _query_async).
  my $pool = $self->pool;
  my $f = $pool->acquire->then(sub {
    my $pg = shift;
    return $self->_dispatch_notify($pg, $channel, $payload, $pool, $pool->_lease($pg));
  });
  $f->retain if $f->can('retain');   # held until ready, as in _query_async (core k407)
  return $f;
}


sub _dispatch_notify {
  my ($self, $pg, $channel, $payload, $pool, $lease) = @_;
  croak '_dispatch_notify needs the pool the connection was acquired from' unless $pool;
  my $f   = $self->future_class->new;
  my $pid = $$;
  my $values = _pg_error_values($channel, $payload);

  my $on_result = sub {
    my ($res, $err) = @_;
    return if $$ != $pid;   # a forked child's copy (karr k45)
    # Global destruction: EV::Pg cancels the statements still waiting and calls
    # back after the captured connection and Future are gone; nothing to deliver.
    return unless defined $self && defined $pg && defined $f && defined $pool;
    my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);
    $err = $self->_pg_server_error($pg, $err, $values);   # karr k74
    $self->_pg_settle_and_release($pool, $pg, $lease, $f, $err);   # done void
  };

  # pg_notify() with bind params -- NOTIFY itself takes no placeholders,
  # and inlining the payload as a string literal invites quoting bugs.
  # EV::Pg croaks before it queues $on_result: release here (karr k46).
  my $sent = eval {
    $pg->query_params('SELECT pg_notify($1, $2)', [ $channel, $payload // '' ], $on_result);
    1;
  };
  unless ($sent) {
    my $err = $self->_pg_dispatch_error($@);
    $self->_pg_report_if_dead($pool, $pg);
    $pool->release($pg, $lease);
    $f->fail($err);
  }

  return $f;
}

# --- COPY ---------------------------------------------------------------------

# One value in PostgreSQL's COPY text format: the backslash is the escape
# character; TAB and LF delimit fields and rows, CR is a line terminator the
# server knows too. One pass, so an escape is never escaped again (karr k98).
my %COPY_TEXT_ESCAPE = ( "\\" => '\\\\', "\t" => '\\t', "\n" => '\\n', "\r" => '\\r' );
sub _copy_text_escape {
  my ($value) = @_;
  $value =~ s/([\\\t\n\r])/$COPY_TEXT_ESCAPE{$1}/g;
  return $value;
}


sub copy_in {
  my ($self, $table, $columns, $coderef) = @_;

  my $col_list = join(', ', map { DBIO::PostgreSQL::Util::quote_ident($_) } @$columns);
  my $quoted_table = DBIO::PostgreSQL::Util::quote_qualified(split /\./, $table);
  my $sql = "COPY $quoted_table ($col_list) FROM STDIN";

  # The pool this COPY begins on is the one it ends on: the release, the report
  # of a dead connection and the retirement of an open stream all go to $pool,
  # never to $self->pool asked again (karr k88, as in _query_async). The
  # coderef runs inside the COPY's delivery, as the callbacks on its Future do.
  my $pool = $self->pool;
  my $seq = $pool->acquire->then(sub {
    my $pg = shift;
    my $lease = $pool->_lease($pg);   # every release below passes it (karr k89)
    my $f = $self->future_class->new;

    # EV::Pg fires the COPY query callback TWICE (see EV::Pg::Pg POD,
    # "A COPY command runs in two phases"): first with the string tag
    # "COPY_IN" when libpq has accepted the COPY command and the stream
    # is ready, then a second time with the final cmd_tuples result when
    # libpq has consumed the EOF marker, applied every row, and sent
    # CommandComplete + ReadyForQuery. The connection is NOT safe to
    # hand back to the pool until that second firing -- releasing after
    # the first lets the next acquire race libpq's still-pending reply
    # and fail with "another command is already in progress" (karr k13).
    #
    # $phase is where the COPY stands:
    #   sent     the COPY command is out, the server has not answered it
    #   open     the stream is open: the coderef runs, then put_copy_end
    #   closing  libpq has taken the end of the stream, the server's answer
    #            to it is due -- the second firing
    #   ended    over, however it ended
    my $phase = 'sent';
    my $pid   = $$;
    my $coderef_err;   # die from the user's coderef, captured to forward
                       # into the Future failure verbatim -- libpq wraps
                       # whatever we pass to put_copy_end into its own
                       # "ERROR: COPY from stdin failed: ..." envelope, so
                       # callers would see the wrapped string instead of
                       # their original die message unless we keep the
                       # raw $@. See t/18 "dying coderef" assertion.
    my $write_err;     # why the writer could not put a row, from the first
                       # one on: the COPY fails with it (karr k65)

    # How the COPY ends: here, once, however it ends -- settled before
    # released, through _pg_settle_and_release (karr k51), and with the
    # coderef's error before any other. Ended is the COPY's own state, not
    # $f->is_ready: a Future the caller cancelled is ready, and its
    # connection still has to go back.
    #
    # A COPY that ends while its stream is open -- no put_copy_end libpq and
    # EV::Pg both took -- leaves a connection the pool cannot use again:
    # gone, or open with libpq still in the COPY, where every statement is
    # refused. It is reported dead before it is released, so the pool retires
    # it instead of idling it (karr k65). The server's answer leaves the
    # connection ready, or gone, which _pg_settle_and_release sees (karr k49).
    my $end = sub {
      my ($err, @result) = @_;
      my $stream_open = $phase eq 'open';
      $phase = 'ended';
      $pool->_mark_connection_dead($pg) if $stream_open;
      $self->_pg_settle_and_release($pool, $pg, $lease, $f, $coderef_err // $err, @result);
    };
    my $on_copy = sub {
      my ($status, $err) = @_;
      return if $$ != $pid;          # a forked child's copy (karr k45)
      # A call after the COPY ended touches neither the Future nor the pool,
      # as in _pipeline_sync. EV::Pg keeps this callback queued when
      # put_copy_end answers -1 (Pg.xs put_copy_end, 0.02 and 0.07 alike) and
      # calls it again -- with "COPY_IN" on a read while libpq has the COPY
      # open, with "connection lost" or "connection finished" when the
      # connection goes. By then the connection is not this COPY's: released
      # again, it would have two holders (karr k57).
      return if $phase eq 'ended';
      return unless defined $self && defined $pg && defined $f && defined $pool;   # global destruction
      my $delivering = DBIO::PostgreSQL::EV::Future->_delivering($pg);

      # Second firing: the server's answer to the end of the stream. The
      # connection is back at ReadyForQuery and safe to reuse.
      if ($phase eq 'closing') {
        $end->($self->_pg_server_error($pg, $err), $status);
        return;
      }

      # First firing. With an error the server refused the COPY, or the
      # connection went before it answered: no stream was opened.
      if (defined $err) {
        $end->($self->_pg_server_error($pg, $err));
        return;
      }
      $phase = 'open';

      # The writer. A row it cannot put is the end of the COPY (karr k65):
      # put_copy_data answers 0 when libpq cannot grow its output buffer for
      # the row -- there is no waiting for room in here, the EV loop does not
      # run inside this callback -- and -1 on an error. Its croak, "not
      # connected" once EV::Pg has lost the connection, goes through
      # without its place (_pg_dispatch_error): put_copy_end croaks the same
      # then. Good only while the coderef
      # runs: after that $pg is the pool's, or in another caller's COPY, and
      # a call is refused (_pg_refuse). The writer has a name: core's
      # exception finds the caller's place past named frames only, and an
      # anonymous one would leave it the whole stack (karr k88).
      my $put = Sub::Util::set_subname 'DBIO::PostgreSQL::EV::Storage::copy_in_writer' => sub {
        my $row = shift;
        _pg_refuse('copy_in: the writer was called outside its COPY') unless $phase eq 'open';
        croak $write_err if defined $write_err;
        my $line = join("\t", map { defined $_ ? _copy_text_escape($_) : '\N' } @$row) . "\n";
        my $rc = eval { $pg->put_copy_data($line) };
        die $self->_pg_dispatch_error($@) unless defined $rc;
        return $rc if $rc == 1;
        croak $write_err = $self->_pg_copy_failure($pg, 'put_copy_data');
      };

      my $ran = eval { $coderef->($put); 1 };
      $coderef_err = $ran ? $write_err : ($@ || 'copy_in: the callback died');

      # End the stream. An error goes to libpq, so the server throws the
      # COPY away; the Future fails with the raw $coderef_err, not with
      # libpq's wrapped "ERROR: COPY from stdin failed: ..." envelope.
      my $rc = eval {
        defined $coderef_err ? $pg->put_copy_end($coderef_err) : $pg->put_copy_end;
      };
      if (!defined $rc) {
        # put_copy_end croaked "not connected": EV::Pg lost the connection
        # during the COPY and dropped this callback on the way, so no second
        # firing will come (karr k46).
        $end->($self->_pg_dispatch_error($@));
      }
      elsif ($rc < 0) {
        # PQputCopyEnd failed, and EV::Pg leaves it at that: this callback
        # stays queued, and libpq is still in the COPY if it could not queue
        # the end of the stream. No answer of the server's is due.
        $end->($self->_pg_copy_failure($pg, 'put_copy_end'));
      }
      elsif (!$pg->is_connected) {
        # libpq took the end of the stream, and EV::Pg lost the connection
        # in the flush behind it: libpq had dropped it in an earlier write
        # (PQflush answers -1 on such a connection). EV::Pg drops the
        # callback it is delivering to without a second firing, so this is
        # the only place to end; "connection lost" is what it tells a
        # callback it does call.
        $end->('connection lost');
      }
      else {
        # The second firing completes $f and releases the connection.
        $phase = 'closing';
      }
      return;
    };

    # EV::Pg croaks before it queues $on_copy ("not connected", "another
    # command is already in progress"), so neither firing will come:
    # release here, once (karr k46).
    unless (eval { $pg->query($sql, $on_copy); 1 }) {
      my $err = $self->_pg_dispatch_error($@);
      $self->_pg_report_if_dead($pool, $pg);
      $pool->release($pg, $lease);
      $f->fail($err);
    }

    return $f;
  });
  $seq->retain if $seq->can('retain');   # held until ready, as in _query_async (core k407)
  return $seq;
}

# What a failed put_copy_data / put_copy_end of copy_in says: the call, and
# libpq's reason for it when it has one -- "cannot allocate memory for output
# buffer", "server closed the connection unexpectedly" -- which is the
# connection's error message at that moment. That is libpq's text: masked,
# like every text of libpq's that is passed on here (karr k78), and without
# its trailing newline -- the writer croaks with it.
sub _pg_copy_failure {
  my ($self, $pg, $call) = @_;
  my $why = $pg->error_message;
  return "$call failed" unless defined $why && $why =~ /\S/;
  $why =~ s/\s+\z//;
  return "$call failed: " . DBIO::Util::mask_connect_secrets($why);
}

# --- Async Deploy -------------------------------------------------------------
# deploy_async / _execute_ddl_async / _drop_statements_for / the sync deploy
# fallback are all INHERITED from DBIO::Storage::Async (core karr k73): the
# generic implementation already does exactly what this transport needs --
# generate DDL, probe _use_transactional_ddl, run it through the
# _query_async_pinned seam this class implements for CRUD. Filling _ddl_class
# is the only seam a Model-B backend has to provide (karr k25; precedent
# dbio-mysql-ev k21, commit d86446e).


sub _ddl_class { 'DBIO::PostgreSQL::DDL' }


sub deploy_async {
  my ($self, $schema, @rest) = @_;

  my @declared = DBIO::PostgreSQL::DDL::_schema_decl($schema, 'pg_extensions');
  return $self->SUPER::deploy_async($schema, @rest) unless @declared;

  my $f = $self->_seam_future(_query_async =>
    DBIO::PostgreSQL::DDL::control_schemas_sql(@declared), [],
  )->then(sub {
    my %fixed = map { $_->[0] => $_->[1] } @_;
    DBIO::PostgreSQL::DDL::check_control_schemas($schema, \%fixed);
    return $self->_deploy_async_with_control_schemas($schema, \%fixed, @rest);
  });
  $f->retain if $f->can('retain');   # held until ready, as in _query_async (core k407)
  return $f;
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

# --- Schema Integration -------------------------------------------------------
# schema / debug / connected / disconnect / DESTROY and the sync
# CRUD/txn/deploy ->get fallbacks are inherited from DBIO::Storage::Async.
# disconnect was overridden here until karr k43, only to finish the dedicated
# LISTEN connection this class kept itself; core's disconnect rotates the
# context-owner token, ends listening (core ADR 0056) and shuts the pool down.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::Storage - Async PostgreSQL storage driver using EV::Pg

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The native C<ev> async transport for PostgreSQL (core ADR 0030 / 0031): a
B<thin transport> over L<EV::Pg>, a non-blocking libpq client that speaks the
async wire protocol directly. No DBI, no DBD::Pg, just raw libpq performance.

It resolves as the C<ev> async mode of L<DBIO::PostgreSQL::Storage> (registered
there via C<< register_async_mode( ev => ... ) >>), so a schema connected with
C<< { async => 'ev' } >> answers the six C<*_async> storage methods over EV::Pg
while the same schema keeps serving synchronous queries over DBI/DBD::Pg.

=head2 Thin transport: shared machinery is inherited

The B<Model-B orchestration> (ADR 0030 §4) is inherited unchanged from
L<DBIO::Storage::Async>: the CRUD runner (L<DBIO::Storage::Async/_run_crud>
with its pooled / pinned runners), the INSERT returned-columns mapping,
L<DBIO::Storage::Async/txn_do_async> bracketing, the L<DBIO::Storage::Async/pipeline>
scaffold, the C<sql_maker> plumbing and the sync C<< ->get >> fallbacks. This
class fills B<only> the loop-/wire-specific seams:

=over 4

=item * L</sql_maker_class> / L</_sql_maker_args> / L</_post_insert_sql> --
the PostgreSQL SQLMaker and its C< RETURNING *> insert suffix

=item * L</_transform_sql> -- C<?> to positional C<$N> placeholders, applied
B<internally> by the query seams (the ADR 0032 C<?>-in contract)

=item * L</_query_async> / L</_query_async_pinned> -- native EV::Pg query
dispatch (pooled and pinned)

=item * L</_run_pool_connect_statement> -- synchronous connect-action replay on
a freshly-spawned EV::Pg pool connection

=item * L</_pipeline_enter> / L</_pipeline_sync> / L</_pipeline_exit> -- libpq
pipeline mode

=item * L</connect_info> / L</_conninfo_string> -- the libpq conninfo transport
shape

=item * L</_async_broker_conninfo> -- an AccessBroker's answer into that shape,
fresh for every new connection

=item * L</_txn_context_class> / L</_txn_conn_accessor> -- the pinned-connection
transaction context

=item * L</_txn_commit_rolled_back> -- whether PostgreSQL answered a
transaction's C<COMMIT> with C<ROLLBACK>

=item * L</_reset_pool_connection> -- the session reset at the end of every
borrow of a pooled connection

=item * L</_listen_open>, L</_listen_close>, L</_listen_subscribe>,
L</_listen_unsubscribe>, L</_listen_watch>, L</_listen_unwatch>,
L</_listen_probe>, L</_listen_delay> and L</_notify_send> -- the listen seams
of core's LISTEN/NOTIFY contract, over a dedicated EV::Pg connection (see
L</LISTEN / NOTIFY>)

=back

Because the extension-composition point is the core resolver, an async storage
layer composed onto this transport inherits every CRUD/txn path for
free; the transport only has to advertise the wire capabilities it really
provides (see L</transport_capabilities>).

=head2 Transport value-add

Beyond the CRUD/txn contract this transport carries two PostgreSQL wire
features the abstract C<future_io> transport cannot: COPY (L</copy_in>) and
libpq pipelining. These override the base's croaking defaults and are declared
in L</transport_capabilities> so a layer that requires them composes cleanly
(and core croaks loudly, never silently dropping the feature, when it cannot).
LISTEN/NOTIFY is declared too, but it is no longer this transport's own API:
it is core's, and this class fills its seams (L</LISTEN / NOTIFY>).

=head2 The session of a pooled connection

Every borrow of a pooled connection has a session of its own. A borrow is a
statement, a transaction up to its C<COMMIT> or C<ROLLBACK>, a pipeline or a
C<copy_in>. When it ends the connection is reset before anyone else gets it:
C<DISCARD ALL> goes out, and then the connect actions run again -- the
connection's C<search_path>, extension C<LOAD>, C<on_connect_do>,
C<on_connect_call>. Whatever a borrower set on the session -- C<SET>,
C<SET ROLE>, C<set_config(..., false)>, a temporary table, a prepared
statement, a session-level advisory lock, a C<LISTEN> -- ends with its borrow,
and the next borrower finds the session a fresh connect gives. The reset is
answered before the connection is lent again, also to a caller that is already
queued for it (L</_reset_pool_connection>). A connection whose reset fails or
does not answer within C<reset_timeout> seconds (default 10) is closed, and the
next borrower gets a new one.

Within one transaction the settings stay: they belong to that borrow, and a
C<SET LOCAL> or C<set_config(..., true)> ends with the transaction as usual.
Statements of different calls on the storage are different borrows. The
connection of C<listen> is a connection of its own outside the pool.

=head2 Cancelling a statement

Cancelling the Future of a statement in flight -- C<< $f->cancel >>, or losing
it in C<needs_all> or C<wait_any> against a timeout -- asks the server to stop
it, when the stack can: EV::Pg's C<cancel_async> (libpq 17 and later,
C<LIBPQ_HAS_ASYNC_CANCEL>, found with C<can>) is called, once, on the
connection the statement runs on. The blocking C<cancel> is never called: it
holds the event loop for a network round trip, with no upper bound when the
network is the trouble. No request goes out for a statement that is not in
flight on a connection of its own: one that waits behind another statement of
a transaction's pinned connection, one sent in pipeline mode, and a
L</copy_in>.

The connection is held until both are in: the statement's result -- the
server's C<57014> I<canceling statement due to user request>, or its normal
result when it finished first; the Future is cancelled and discards it -- and
the answer to the cancel request. Only then does a pooled connection go back
to the pool, and the next statement of a transaction's pinned connection go
out. Released earlier, the request would reach the next statement that
connection runs, and fail a caller who cancelled nothing (measured: 151 of
185 requests through the pool). The next call on a pool of one waits for that,
about ten milliseconds, and not for the end of a statement nobody waits for any
more. A request that itself ends with an error retires the connection.

Cancelling the Future of C<txn_do_async>, C<pipeline> or C<deploy_async> --
or only the Future a transaction's coderef returned -- retires the connection
in core (ADR 0055 addendum): C<ROLLBACK> best-effort, the
connection out of the pool at once, its slot to a fresh connection. A retired
connection with a statement in flight is not closed at that moment: closing
drops a cancel request that is not through yet, unsent, and the statement
would run to its end on the server. The pool
(L<DBIO::PostgreSQL::EV::Pool/_shutdown_connection>) asks the server to stop
it and closes the connection when the request is answered, or lost with the
connection.

Without C<cancel_async> -- EV::Pg built against libpq 16 or earlier -- nothing
changes: no request is sent, the server runs the statement to its end, and the
connection is held, as before, until its result is in. C<needs_all> and
C<wait_any> cancel the losers, so with the capability their statements are
aborted on the server instead of running to the end.

A statement cancelled while it still waits in the queue of a transaction's
pinned connection is skipped: it is not sent, and the server never runs it.
The order of the statements behind it is kept; nothing overtakes. The
exception is the C<COMMIT> or C<ROLLBACK> of core: a cancelled one is sent all
the same -- the queue knows it as the end of the transaction, and skipping it
would leave the backend idle in transaction, with its locks. The transaction
fails as before with I<cancelled before it was answered>.

=head2 What a failed statement's Future fails with

A statement the B<server> refused -- a unique violation, a deadlock, a
serialization failure, a statement cancelled by C<statement_timeout> -- fails
its Future with one L<DBIO::Exception::Server> (ADR 0062 in core).
It answers C<sqlstate>, and C<constraint>, C<table> and C<detail> where the
server sent them, and it stringifies to the very text the Future failed with
before it was an object -- the server's own words, in its C<lc_messages>:

  $storage->insert_async($source, \%row)->catch(sub {
    my ($error) = @_;
    if (Scalar::Util::blessed($error)
        && $error->isa('DBIO::Exception::Server')
        && ($error->sqlstate // '') eq '23505') {
      ... # $error->constraint, $error->table
    }
  });

C<eq>, C<=~> and C<< on_fail(sub { my ($message) = @_ }) >> see the text they
saw. It is one object on every path -- pooled, pinned, inside C<txn_do_async>,
in a pipeline, a C<notify>, a L</copy_in>, a C<LISTEN> -- and C<get> dies with
it.

What is B<not> the server's stays the plain string it was, with no SQLSTATE:

=over 4

=item * the connection is gone: I<"connection lost">, I<"connection
finished">, I<"pipeline aborted">, I<"empty query">, libpq's I<"server closed
the connection unexpectedly"> and every other text of EV::Pg's or libpq's own

=item * a statement EV::Pg refused to send, I<"not connected"> and I<"another
command is already in progress">, and EV::Pg's refusal to enter or leave
pipeline mode -- its text and a newline, without the line of this library
that called EV::Pg

=item * a statement after the C<COMMIT> of its transaction, a blocking wait on
the loop, I<"connecting the listen connection failed: ...">, I<"pool connect
statement failed: ...">

=item * the error of a C<copy_in> coderef that died, which the Future fails
with as the coderef died

=item * a cancelled Future, which is cancelled and has no failure at all

=back

The line is drawn by the text, not by the connection. EV::Pg keeps
C<error_fields> of the I<last> server error on the connection and sets it only
for an error result of a server: after a lost connection it still holds the
previous error's SQLSTATE. A failure is the server's only when its text begins
with the severity and the primary message C<error_fields> holds -- libpq's
C<SEVERITY:  primary>, the SQLSTATE between them in verbose mode -- which is
true in the callback of the very statement that was refused and of nothing
else (L</_pg_server_error>).

Where core puts its own words in front -- C<BEGIN failed: ...>, C<COMMIT
failed: ...>, C<Transaction aborted: ... Rollback failed: ...> -- the caller
gets a derived copy of the same class and fields with C<context> set
(C<BEGIN>, C<COMMIT> or C<ROLLBACK>), stringifying with that prefix (core ADR
0062). Only a failure that is not the server's stays a prefixed string.

=head2 Refusals of the transport

What this transport refuses to do with what the caller gave it is a
L<DBIO::Exception>, the way core throws its own: the transport's method that
refused, one sentence saying what was refused, and the caller's file and line
(L</_pg_refuse>; the C<future_io> transport refuses the same way):

  DBIO::PostgreSQL::EV::Storage::_pg_quote_channel(): LISTEN channel name '...' is 64 bytes long; ... at app.pl line 12

These are: no AccessBroker attached to ask; connect info, or a broker's
answer, of a form it cannot connect from (L</connect_info>); a connection
parameter given beside the broker; a listen connection that is closed, not
connected or has no connect info; a channel name
L<DBIO::PostgreSQL::Util/quote_channel> refuses; a statement
L<DBIO::PostgreSQL::Util/number_placeholders> refuses -- C<$N> beside a C<?>;
and the writer of a L</copy_in> called outside its COPY. The words are what
they were. The place is the caller's whether the caller called into the
transport itself, went through the pool, or ran the EV loop in which the
refusal was reached. A refusal reached through the pool fails the statement's
Future with the exception; inside core's words -- I<"LISTEN on channel '...'
failed: ...">, C<on_listen_error> -- it is a string, as core makes it one.

A refusal of a blocking wait (L<DBIO::PostgreSQL::EV::Future/await>) and of a
statement after its transaction's C<COMMIT> are not among them: they stay as
they were.

=head2 LISTEN / NOTIFY

C<listen>, C<unlisten>, C<notify>, C<listen_alive> and C<listen_reconnect>,
the hooks C<on_listen_error> and C<on_listen_reconnect>, and the backoff
settings C<listen_backoff_initial> / C<listen_backoff_max> are core async API
(core ADR 0056) -- one contract on every async transport that declares
C<listen> / C<notify>, the PostgreSQL C<future_io> transport included, and
documented once in L<DBIO::Storage::Async/"LISTEN / NOTIFY">. Core owns the
channel registry, the one dedicated listen connection, the queue that runs one
C<LISTEN> / C<UNLISTEN> at a time on it, reconnect with backoff, C<LISTEN>ing
every channel again on the new connection, and the fork guard. This class
fills the listen seams with EV::Pg. They are reached through the async backend
of an C<ev> connection:

  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'ev' });
  my $async  = $schema->storage->async;

  $async->on_listen_error(sub {
    my ($storage, $error) = @_;   # every error; without a hook it is warned
    $log->warn("listen: $error");
  });
  $async->on_listen_reconnect(sub {
    my ($storage) = @_;           # rebuilt, every channel LISTENed again
    $log->info('listen connection rebuilt -- re-read what may have been missed');
  });
  $async->listen_backoff_initial(0.5);   # reconnect backoff, seconds
  $async->listen_backoff_max(30);        # (defaults 1 and 30)

  $async->listen(jobs => sub {
    my ($channel, $payload, $sender_pid) = @_;
    ...
  })->get;                               # runs the EV loop until LISTEN is in effect

  $async->notify(jobs => 'wake up')->get;   # on a pooled connection
  $async->unlisten('jobs')->get;

  # an external watchdog, from an EV::timer say
  $async->listen_reconnect unless $async->listen_alive;

What is particular to this transport:

=over 4

=item * B<Delivery> is PostgreSQL's: a notification arrives when the sending
transaction commits, and it is not durable -- whatever was sent while the
listen connection was down is gone, which is what C<on_listen_reconnect> is
for. C<$sender_pid> is the backend pid of the notifying session. There is no
NULL payload: C<< notify($channel) >> arrives as C<''>. Notifications are
delivered from the EV loop, by EV::Pg's C<on_notify>, in arrival order. Those
that arrive while a connection is still being set up -- after its first
C<LISTEN>, while core subscribes the other channels one by one -- are held and
delivered when watching starts (L</_listen_watch>), before the C<listen>
Future resolves; none is dropped.

=item * B<Channel names> are PostgreSQL identifiers, sent quoted: exact and
case-sensitive, any character but NUL, at most 63 bytes in UTF-8. A C<.> is
part of the name -- C<app.events> is one channel, not a schema-qualified one. A
longer name is refused, not truncated (L</_pg_quote_channel>): C<listen> fails
its Future and the channel is dropped. The server limits a payload to less
than 8000 bytes; C<notify> fails its Future beyond that.

=item * B<Liveness.> The EV loop watches the listen connection's socket the
whole time, so a server that ends the session (C<pg_terminate_backend>, a
restart) is noticed as soon as the loop reads the end of the connection: EV::Pg
reports it through C<on_error>, and core closes the connection, reports the
error through C<on_listen_error> and reconnects with backoff. C<listen_alive>
asks EV::Pg's own view of the connection (L</_listen_probe>) and never blocks;
unlike the C<future_io> transport it sends no ping, so it cannot know more than
the loop has read. A peer that vanished without closing the connection is
found only by TCP: bound that with libpq parameters in the DSN
(C<keepalives_idle>, C<tcp_user_timeout>).

=item * B<Nothing blocks the loop.> The connect, each C<LISTEN> / C<UNLISTEN>
and the backoff timer are EV watchers. The Futures are L</future_class>, so
C<get> on one runs the EV loop until it is ready.

=item * B<The loop stays up while something is listened to.> The listen
connection is opened with EV::Pg's C<keep_alive>, so C<EV::run> keeps running
for as long as the connection is open -- what a daemon waiting for
notifications needs. It closes when the last channel is unlistened.

=item * B<Fork safety.> The listen connection is built like a pooled one
(L<DBIO::PostgreSQL::EV::Pool/Fork safety>): a forked child that exits, or
drops its copy of the connection, leaves the parent's LISTEN session alone,
and a child that resumes the EV loop closes its copy before it can read a
notification meant for the parent. Core never touches the connection outside
the process that opened it; a child that wants notifications itself calls
C<listen> and gets its own connection.

=back

=head1 METHODS

=head2 sql_maker_class

The L<DBIO::PostgreSQL::SQLMaker> subclass used to generate SQL. Shared with
the sync driver and the C<future_io> transport, so the maker keeps emitting
C<?> placeholders (translated to C<$N> internally by L</_transform_sql>).

=head2 _sql_maker_args

PostgreSQL SQLMaker construction args: the identifier quoting of the
connection, and the LIMIT/OFFSET dialect.

The quoting is not decided here. C<quote_char> and C<name_sep> are taken from
the SQL maker of the owning sync storage
(L<DBIO::PostgreSQL::Storage/sql_maker>, which is core's rule), so both paths
of one connection quote alike, as the C<future_io> transport does: nothing
given quotes with C<"> and separates with C<.>, an explicit C<quote_char> or
C<name_sep> is used as given, and where the sync maker writes identifiers
unquoted (C<< quote_names => 0 >>, an empty C<quote_char>) so does this one. A
backend without an owning sync storage -- constructed on its own, as
C<< DBIO::PostgreSQL::EV::Storage->new(undef) >> plus L</connect_info>, not
through C<< connect(..., { async => 'ev' }) >> -- quotes with C<"> and C<.>,
the defaults of L<DBIO::PostgreSQL::Storage>: core takes the quoting options
out of the connect info it hands a backend.

=head2 _post_insert_sql

Returns C< RETURNING *> so an INSERT yields every populated column (autoinc PK
+ retrieve-on-insert defaults); the inherited runner folds the row onto the
supplied data to build the returned-columns hashref (ADR 0031 §3).

=head2 future_class

Returns C<'DBIO::PostgreSQL::EV::Future'>: a L<Future> subclass whose C<get>
on a pending Future runs the EV loop until it is ready
(L<DBIO::PostgreSQL::EV::Future>). That is what makes the inherited blocking
methods -- C<select>, C<insert>, C<txn_do>, C<deploy>, ... -- work: each is
C<< ->get >> on its C<*_async> sibling, and a plain L<Future> dies there
instead of waiting (ADR 0001). The class reaches every Future such a
method waits on: L</pool> hands it to the pool, every Future this class settles
from an L<EV::Pg> callback is built from it, and L<Future>'s combinators keep
it. A blocking call works from a script and from inside an EV callback. Inside
a callback of one of this transport's own connections -- a C<then> on its
Futures, a C<txn_do> coderef -- one that would make L<EV::Pg> deliver the next
result on that connection to the wrong callback is refused: it dies with
I<"Blocking wait refused: ..."> instead of spinning. So is one that is queued
for a pooled connection while the callbacks it runs inside hold every
connection of the pool -- C<< $storage->select >> in a C<then> or a C<txn_do>
coderef with C<< pool_size => 1 >>: it dies instead of hanging, and does not
run later. A blocking call that is queued for a connection and whose
wait is given up on any other way -- refused for a result due on the callback's
connection, or the loop running dry -- leaves the queue and does not run later
either. Use the C<*_async> methods there
(L<DBIO::PostgreSQL::EV::Future/await>).

Everything else is L<Future>'s own. C<< ->then >> callbacks auto-wrap a
non-Future return value into a resolved Future (ADR 0031 §4), so ResultSet/Row
C<< *_async >> callbacks that return plain values resolve without an explicit
C<< Future->done(...) >> wrap.

=head2 transport_capabilities

  my @caps = DBIO::PostgreSQL::EV::Storage->transport_capabilities;

Class method (see L<DBIO::Storage::Async/transport_capabilities>). Declares the
wire capabilities this transport really provides, so
L<DBIO::Storage::DBI/_async_storage> lets an async extension layer that requires
any of them compose onto it (and croaks naming the gap otherwise, rather than
silently dropping a feature). This transport provides:

=over 4

=item * C<on_connect_replay> -- its pool (L<DBIO::PostgreSQL::EV::Pool>, a
L<DBIO::Storage::PoolBase>) drives core's
L<DBIO::Storage::Async/_setup_pool_connection> on every freshly-spawned
connection, and L</_run_pool_connect_statement> replays the owning sync
storage's C<on_connect_do>/C<on_connect_call> against it.

=item * C<listen> / C<notify> -- the capability names core's LISTEN/NOTIFY
gate asks for (core ADR 0056 §2): core's C<listen>, C<unlisten>,
C<listen_alive> and C<listen_reconnect> need C<listen>, its C<notify> needs
C<notify>. This class fills the listen seams behind them
(L</LISTEN / NOTIFY>).

=item * C<copy> -- COPY FROM STDIN bulk load (L</copy_in>).

=item * C<pipeline> -- libpq pipeline mode (L</_pipeline_enter> /
L</_pipeline_sync> / L</_pipeline_exit> under the inherited scaffold).

=item * C<broker_connect_options> -- read by core, not by layers: the connect
options given beside an L<DBIO::AccessBroker>,
C<< MyApp::Schema->connect($broker, { async => 'ev', pool_size => 3, ... }) >>,
are handed on as C<< [ $broker, \%options ] >> and applied to every connection
this transport opens. C<pool_size> sizes the pool. The
DBD attributes are treated as the same keys are in DBI-form connect info: this
transport has no DBD, so they are dropped and never reach libpq
(L</connect_info>). A connection parameter there (C<sslmode>, ...) is neither
applied nor dropped: the connect info is refused, and so is a
capitalised one (C<Sslmode>). Without the
declaration core refuses such a connection at first async use.

=back

=head2 connect_info

  $storage->connect_info([ \%conninfo, \%opts ]);
  $storage->connect_info([ 'dbi:Pg:dbname=app;host=db1', $user, $password, \%attrs ]);
  $storage->connect_info([ { dsn => 'dbi:Pg:dbname=app;host=db1', user => $user, password => $password } ]);
  $storage->connect_info([ $broker ]);

Set what connections are opened from. The owning sync storage hands this
transport the connect info it was given itself, and opens its dbh from the
same one -- so every form the owner reads as a connection is read here as
that connection, and a pooled connection ends up where the dbh does, as the
same user. The forms:

=over 4

=item * B<The DBI form> C<< [ 'dbi:Pg:...', $user, $password, \%attrs, \%extra_attributes ] >>,
read as DBI and DBD::Pg read it
(L<DBIO::PostgreSQL::EV::ConnectInfo/dbi_to_conninfo>): the DSN's parameters,
the user and the password become libpq parameters. DBI attributes may stand
in front of the DSN (C<< dbi:Pg(RaiseError=>1):... >>), and DBI's C<Username>
and C<Password> attributes are the user and password where they are given. The
parameters may be a C<postgresql://> URI (C<< dbi:Pg:postgresql://app@db1/appdb >>),
read as libpq reads it; a user and password beside it win over its
own. Of the attributes otherwise only C<pool_size> is read, and a libpq
parameter among them (C<sslmode>, C<host>, ...), spelled in any case, is
refused, naming the key and never a value: DBI would take it for an
attribute, and the pool would connect without it. C<pool_size>
among the DSN's parameters (C<dbi:Pg:dbname=app;pool_size=3>) is refused,
naming it: libpq refuses it, so the dbh of the same connect info does not
open, and it belongs among the attributes. C<DBI_USER> and C<DBI_PASS> stand
for an undefined user and password, as for DBI. C<dbi:Pg:> with nothing behind
it is read, as the dbh reads it: libpq fills the rest from its environment.

=item * B<A hash with a C<dsn> key>,
C<< { dsn => 'dbi:Pg:...', user => $user, password => $password, %attrs } >>:
the DBI form written as a hash, every other key an attribute. A connection
parameter beside the C<dsn> (C<host>, C<sslmode>, ...) is such an attribute
too, to DBI, and is refused here naming the key (before it, dropped
without a word, and both halves connected from the DSN alone). It belongs in
the DSN. A C<dbname> that is a whole DSN is the C<dsn> where there is none, as for the
owner; a C<host> or C<port> beside it is refused, as the owner refuses it.

=item * B<A hash of libpq connection parameters>,
C<< { dbname => 'app', host => 'db1', user => $user, password => $password, ... } >>,
this transport's own form: every key is handed to libpq, so any libpq
parameter works, except C<pool_size>, which sizes the pool, and what is the
owner's by its name -- its own options (C<async>, C<on_connect_do>,
C<quote_names>, ...) and DBI attributes, told by their names as below for
what stands beside a broker. Those are dropped, as the attributes of the DBI
form are; no libpq parameter has such a name -- except in another case:
C<Sslmode> is an attribute to DBI and C<sslmode> to libpq, so a key that
lower-cased is a libpq parameter (L<DBIO::PostgreSQL::EV::ConnectInfo/is_libpq_parameter>)
is refused, naming it, not dropped. An undefined parameter is
left out; a reference for one is refused.

=item * B<A libpq conninfo string> (C<'host=db1 dbname=app'>, a
C<postgresql://> URI) in the place of that hash.

=item * B<An AccessBroker>, C<< [ $broker ] >> or C<< [ $broker, \%options ] >>,
wired to the per-spawn credential provider (the base broker seam). What the
broker answers is read as connect info in the forms above, at attach and for
every connection (L</_async_broker_conninfo>).

=back

A hash or a conninfo string may be followed by an options hashref,
C<< [ \%conninfo, \%opts ] >>.

Anything else is refused (L</Refusals of the transport>), here and not at
the first connection, naming the form
it was given -- for an array what kind of thing each element is, for a hash
its keys, for a DSN the DBI driver -- and never a value. That
includes what the owner connects from and this transport cannot: a connection
coderef and a hash with a C<dbh_maker>, which make a DBI handle. Through a
schema the refusal comes at the first C<< $schema->storage->async >>. One
reader reads static connect info and a broker's answer
(C<_pg_read_connect_info>), so a form is read, or refused, the same from
both. Static connect info that names nothing to connect to -- an empty hash,
an empty or blank conninfo string, an empty array -- is taken, and handed to
libpq as it is, to fill from its environment; a broker's answer that renders
to the empty conninfo is refused (L</_async_broker_conninfo>). A DBI-form
C<dbi:Pg:> DSN is the exception: one that names no C<dbname>, C<host>,
C<port>, C<service> or C<hostaddr> (C<dbi:Pg:>, C<dbi:Pg:sslmode=require>) is
refused, static and as a broker's answer, with the words of the sync storage
and of C<future_io> -- libpq would take the target from C<PGHOST> and
C<PGDATABASE> (L<DBIO::PostgreSQL::Util/dsn_names_target>).

A call that throws leaves nothing of the C<connect_info> before it: the pool
and the listen connection are closed first, as for every call, and the
conninfo, pool size and options the earlier call stored are dropped before
anything is read. A storage whose static connect
info was refused has nothing to connect from; one whose broker could not be
attached keeps that broker, with what stood beside it, and nothing of the
call before.

No conninfo is kept from a broker's answer, as in core's
L<DBIO::Storage::Async/connect_info>. The answer is read
once here -- to refuse one the transport cannot connect from, and for its
C<pool_size> -- and every connection asks the broker again, so a stored copy
could only be that first answer, password included. A storage whose broker is
detached afterwards has nothing to connect from until C<connect_info> is called
again: it does not fall back to what the broker once answered. Static connect
info is stored, being all a static connection is opened from.

A broker may come with the connect options the owning sync storage was given
beside it, C<< [ $broker, \%options ] >> -- the form core hands a transport
declaring C<broker_connect_options> (L</transport_capabilities>). They are read
through core's L<DBIO::Storage::Async/_access_broker_call_options>, after what
the owner applies itself (C<async>, the storage and SQL maker options) is
stripped:

=over 4

=item * C<pool_size> sizes the pool. So does a C<pool_size> in the broker's
answer -- a key of its hash, or among the attributes of a DBI-form answer, in
its fourth or fifth element, the later one winning. Given both in the answer
and beside the broker, the two must be the same value, or this throws naming
C<pool_size> (L<DBIO::Storage::Async/_access_broker_pool_size>). Given nowhere,
the pool keeps its default of 5.

=item * B<DBD attributes> (C<pg_enable_utf8>, C<AutoCommit>, C<RaiseError>,
...) are dropped, exactly as
L<DBIO::PostgreSQL::EV::ConnectInfo/dbi_to_conninfo> drops them from DBI-form
connect info: there is no DBD on this transport to apply them, and libpq
refuses a connection parameter it does not know. They change what the owner's
DBI connection does and nothing about a pooled one.
L<DBIO::Storage::Async/_access_broker_call_attributes> answers what was
dropped. What counts as one is told by its name, the way core tells it in a
broker's hash answer: a first letter in uppercase, or a start of
C<private_>, C<dbi_>, C<dbd_> or DBD::Pg's C<pg_> -- unless the name
lower-cased is a libpq parameter, C<Sslmode>: that is refused as the next
item says. An attribute beside a broker whose answer is a code
reference (C<dbh_maker>) is named in the refusal of the answer: the code opens
the connection, and nothing beside the broker goes to it.

=item * B<A connection parameter> -- any other key set to a value: C<sslmode>,
C<connect_timeout>, C<application_name>, ... -- is refused. This throws,
naming the parameters and never a value, and says where they belong. Every
connection of this transport is opened from the broker's answer alone, so the
parameter would not reach one, and C<< sslmode => 'require' >> beside a broker
would leave the pool connecting without TLS and without a word. A lowercase
name that is no DBI attribute is refused whether libpq knows it or not; a name
with a capital is refused when it is a libpq parameter lower-cased, as told by
L<DBIO::PostgreSQL::EV::ConnectInfo/is_libpq_parameter>. A key set to C<undef>
or the empty string names no parameter. Such a parameter is given in the
broker's answer (L</_async_broker_conninfo>).

=back

The options beside the broker are judged first (the order core
uses): where a connection parameter stands beside the broker and the answer
is also unusable, or its C<pool_size> differs from the one beside the broker,
the refusal above is what is said, before the broker is asked, and the
answer's problem only once the parameter is gone.

After that refusal nothing is opened through this storage without the
parameter. The broker stays attached, no conninfo is stored -- not the one of
a static C<connect_info> before it either -- and every pool connection and
every open of the listen connection is refused again, naming the parameters,
until C<connect_info> is given connect info without them. With the broker
detached there is nothing to connect from. This half-configured state is the
intended one: it is the only one in which nothing opens without the
parameter, and the same holds after a C<pool_size> that disagrees with the
broker's answer -- the broker stays attached, the pool has its default of 5
until the call is made again, and every connection is refused again with the
same message.

Through a schema, C<< MyApp::Schema->connect($broker, { async => 'ev',
sslmode => ... }) >>, the refusal comes when core builds this transport: at
the first C<< $schema->storage->async >> or C<*_async> call, and at every
later one. C<connect> itself goes through: this transport is not there yet to
refuse anything. The owning sync storage does not open its dbh without the
parameter either: core throws where that storage opens a connection of its
own -- at the first use of the dbh and at every reconnect, not at C<connect>
-- naming the parameters and that they stand beside the broker.
So a caller who never uses the async API is told as well, at the first use of
the dbh (F<t/69-access-broker-parameters-beside-live.t> holds both, against a
server).

This override (rather than the inherited base C<connect_info>) is retained
because the EV transport reads connect info itself: it translates the forms
above into libpq conninfo, refuses what it cannot connect from, and applies
its own rules to what stands beside a broker.
Like the base, it reconfigures through the inherited C<disconnect> when a pool
or listen state exists, which shuts the pool down and ends listening -- the
listen connection was opened with the outgoing connect info.

=head2 _async_broker_conninfo

  my $conninfo = $storage->_async_broker_conninfo($mode);
  # { dbname => 'app', host => 'db1', port => 5432, user => ..., password => ... }

AccessBroker seam (see L<DBIO::Storage::Async/ACCESSBROKER CONSUMPTION>): ask
the attached broker for its current connect info -- anew each time, so rotated
credentials reach the next connection -- and return it as the libpq conninfo
the connection is opened from. Called for every new pool connection (through
L<DBIO::Storage::Async/_conninfo_provider>) and for every open of the listen
connection (L</_listen_open>), its first and every reconnect. L</connect_info>
reads the broker's answer the same way when the broker is attached, where a
C<pool_size> in it sizes the pool. All three ask core's
L<DBIO::Storage::Async/_current_async_connect_info> and read what it returns in
one place, so an answer refused at attach is refused for every connection
after it, and the other way round (before it the pool spawn and the
listen open asked L<DBIO::Storage/current_access_broker_connect_info>
themselves). Connect options given beside the broker change nothing in the
conninfo: the DBD attributes among them never reach libpq. A connection
parameter among them stops the connection instead -- this refuses it before the
broker is asked, as L</connect_info> did when it was given them.
The answer may come in any of these shapes:

=over 4

=item * B<A DBI-form arrayref> C<< [ 'dbi:Pg:...', $user, $password, \%attrs ] >>,
as L<DBIO::AccessBroker::Vault> answers, and L<DBIO::AccessBroker::HostBound>
over it. Read exactly like DBI-form connect info
(L<DBIO::PostgreSQL::EV::ConnectInfo/dbi_to_conninfo>): the DSN's parameters,
the user and the password become libpq parameters, and of the attributes --
C<\%attrs>, a fifth element C<\%extra_attributes>, and DBI attributes in front
of the DSN -- only C<pool_size> and DBI's C<Username> and C<Password> are
read. The rest -- DBD::Pg attributes, and DBIO's own such as C<async>, which a
Vault broker selects this transport with -- never reaches libpq; a libpq
parameter among them (C<sslmode>, ...) is refused, naming the key, as it is in
static connect info.

=item * B<A hashref with a C<dsn> key>, C<< { dsn => 'dbi:Pg:...', user =>
$user, password => $password, %attrs } >>: that DBI form written as a hash, as
the sync storage reads it, and the answer core names for carrying a libpq
parameter to both halves of a schema. Read as the DBI form -- the parameter
goes inside the DSN; a key beside the C<dsn> is an attribute. So is a hash
whose C<dbname> is a whole DSN.

=item * B<A hashref of libpq connection parameters>, as
L<DBIO::AccessBroker::Static> answers (C<dbname>, C<host>, C<port>, C<user>,
C<password>), and L<DBIO::AccessBroker::HostBound> over it. This transport's
own shape: every key is handed to libpq, so any libpq parameter works
(C<sslmode>, C<connect_timeout>, ...), except C<pool_size> and the keys that
are the sync storage's by their names -- its own options and DBI attributes
(L</connect_info>). A key that lower-cased is a libpq parameter
(C<Sslmode>) is refused, naming it. Undefined ones are left out. A
value that is a reference is refused, naming the key. A schema's sync storage opens no dbh from a hash
carrying a libpq parameter -- see below.

=item * An arrayref holding such a hashref, or a libpq conninfo string
(C<'host=db1 dbname=app ...'>, a C<postgresql://> URI), optionally followed by
an options hashref -- the C<< [ $conninfo, \%opts ] >> shape of
L</connect_info>. A conninfo string is an answer for this transport alone:
through a schema it takes a broker that answers by the storage that asks --
see below.

=back

These are the forms of L</connect_info>, read by the same reader. Anything
else is refused (L</Refusals of the transport>), naming the shape it
received -- never the values, which carry
the password. That includes a DSN for another driver, a C<dbi:Pg:> DSN libpq
could not read the parameters of
(L<DBIO::PostgreSQL::EV::ConnectInfo/dbi_to_conninfo>), a libpq
conninfo string followed by a user and password, which would be dropped, and
an answer that makes a DBI handle -- a code reference, a hash with a
C<dbh_maker>.

So does an answer in one of these shapes that renders to an B<empty conninfo>:
a hash that is empty, or holds nothing but C<pool_size>, or only undefined
parameters; a blank conninfo string; a C<dbi:Pg:> DSN that names no parameter,
with no user and no password beside it. libpq fills an empty conninfo from its
environment and defaults (C<PGHOST>, C<PGUSER>, ...), so the connection would
be opened wherever the process environment points, as whoever it names --
not where the broker said. One parameter with a value is enough:
which ones a connection needs is libpq's to say. A broker that answers nothing
at all -- C<undef>, an empty hash or array -- is refused by core before this
method reads the answer, naming the broker class
(L<DBIO::Storage/current_access_broker_connect_info>).

Refuses (L</Refusals of the transport>) when no AccessBroker is attached --
one detached with
L<DBIO::Storage/clear_access_broker> while the per-spawn provider is still in
place: core's seam answers what L</connect_info> stored then, and that is never
what a broker connection is opened from. Nothing is stored from
a broker's answer, so there is no earlier answer to fall back to; the refusal
says that the broker is gone, where reading the seam's answer would report an
unusable answer no broker gave.

B<A libpq parameter in the answer, through a schema.> A schema's broker is
asked by two storages: this transport, and the owning sync storage for its
dbh. The hash of libpq parameters is this transport's shape only: the sync
storage builds C<dbname>, C<host> and C<port> into a DSN and applies no other
key of it. Answered to every storage alike, a hash carrying another parameter
(C<sslmode>, C<connect_timeout>, C<application_name>, ...) connects the
schema, and every connection of this transport -- pooled and listen -- is
opened with the parameter. The dbh is not opened without it: core throws where
the sync storage opens a connection of its own, at the first use of the dbh
and at every reconnect, naming the broker class and the parameters. C<<
MyApp::Schema->connect >> does not throw, and a caller who uses only the async
API never meets the refusal: this transport opens its own connections, and the
sync storage does not connect for them. With two answers the dbh is opened as
well:

=over 4

=item * B<The DBI form with the parameter in the DSN>,
C<< [ 'dbi:Pg:dbname=app;host=db1;sslmode=verify-full', $user, $password ] >>,
or the same written as a hash,
C<< { dsn => 'dbi:Pg:...;sslmode=verify-full', user => $user, password => $password } >>,
one answer for every storage: the dbh and every connection of this transport
are opened with it.

=item * B<An answer by the storage that asks>
(L<DBIO::AccessBroker/connect_info_for_storage>): the hash with the parameter
for a L<DBIO::PostgreSQL::EV::Storage>, an answer the sync storage takes for
every other. The parameter then reaches this transport's connections, and the
dbh only if the other answer carries it too.

=back

B<A libpq conninfo string through a schema> has the second way only. The sync
storage reads an arrayref as the DBI form, its first element as the DSN, and
a conninfo string -- C<'host=db1 dbname=app ...'>, a C<postgresql://> URI --
names no C<dbi:Driver:>. Answered to every storage alike it connects the
schema and every connection of this transport, and the dbh fails where it is
first used, with DBI's own error (I<can't work out what driver to use>). So a
broker answers a conninfo string to a L<DBIO::PostgreSQL::EV::Storage> only,
and the DBI form to every other storage
(L<DBIO::AccessBroker/connect_info_for_storage>).

The transport given the broker directly,
C<< $storage->connect_info([ $broker ]) >>, takes the hash with any libpq
parameter as before: no sync storage reads the answer then.

=head2 pool

Returns the L<DBIO::PostgreSQL::EV::Pool> connection pool, created lazily on
first access. The pool is wired with C<< storage => $self >> so its
core-shared spawn path (L<DBIO::Storage::PoolBase/_spawn_connection>) replays
the owning sync storage's connect actions on each new connection via
L</_run_pool_connect_statement>. Fed the per-spawn
C<conninfo_provider> when an AccessBroker is attached, otherwise the static
conninfo string. It gets this storage's L</future_class> too, so its acquire,
waiter and readiness Futures -- the first link of every query chain -- can be
waited on with C<get>.

The pool is built in the slot L<DBIO::Storage::Async/disconnect> empties, so
calling this is for what B<begins> work: L</_query_async>, L</_notify_send>
and L</copy_in> ask once, as they acquire, and keep what they got. What
B<ends> their work -- the release, the report of a dead connection, the
retirement of a COPY's connection -- talks to that pool, the one the
connection came from, and never calls this again (core's rule,
L<DBIO::Storage::Async/pool>). See L</_dispatch_query>
for when work ends on a storage without a pool.

A forked child leaves the pool's sessions to the parent: its copies of the
pooled connections close without touching the parent's sessions, when the
child exits as when it resumes the EV loop, and no callback of a statement in
flight at fork time runs in the child (L<DBIO::PostgreSQL::EV::Pool/Fork
safety>).

=head2 _conninfo_string

  my $str = $storage->_conninfo_string;          # what a new connection gets now
  my $str = $storage->_conninfo_string(\%conninfo);

The libpq conninfo string of C<\%conninfo>, or else of what a new connection
would be opened from at this moment: the broker's current answer, read by
L</_async_broker_conninfo>, when an AccessBroker is attached, the static
conninfo otherwise. C<undef> when there is neither -- no connect info was
given yet, or a broker and its provider are gone
(L<DBIO::Storage::Async/_clear_access_broker>): L</connect_info> keeps none of
a broker's answer.

=head2 _txn_context_class

The pinned-connection transaction context the inherited
L<DBIO::Storage::Async/txn_do_async> hands to its coderef:
L<DBIO::PostgreSQL::EV::TransactionContext>.

=head2 _txn_conn_accessor

The constructor key the pinned connection is passed under -- C<txn_conn>, the
key core's own L<DBIO::Storage::Async::TransactionContext> constructor requires.
Since L<DBIO::PostgreSQL::EV::TransactionContext> became a thin subclass of that
class the constructor is core's, so this seam names core's key; the
driver-native C<txn_pg> survives as a read accessor, not as a constructor key.

=head2 _txn_commit_rolled_back

  my $rolled_back = $storage->_txn_commit_rolled_back($pg, @commit_result);

Core transport seam (L<DBIO::Storage::Async/_txn_commit_rolled_back>): true
when PostgreSQL answered the transaction's C<COMMIT> with the command tag
C<ROLLBACK>. That is its answer, not an error, when a statement in the
transaction failed and the transaction was aborted -- a statement core never
saw fail: one in a pipeline batch whose coderef dropped its error, or one sent
on the pinned connection past the transaction context. Core then fails the
transaction with I<"COMMIT was answered with ROLLBACK: ...">.

The tag is C<< $pg->result_meta->{cmd_status} >>. The C<COMMIT>'s Future
cannot carry it: it resolves with L<EV::Pg>'s row count, which is C<''> for
C<COMMIT> and for its C<ROLLBACK> answer alike. Reading it here gets the
C<COMMIT>'s own. Core asks from the success callback of the C<COMMIT>'s Future,
and L</_query_async_pinned> settles that Future inside EV::Pg's callback for
the C<COMMIT>'s result. EV::Pg points C<result_meta> at a result before it
calls that result's callback (0.02 builds the hash right away, 0.07 when asked)
and changes it only when the next result is delivered or the connection is torn
down -- neither happens between the start of that callback and core's question.
Nothing goes out on the connection behind the C<COMMIT> either: a statement
issued after it is refused (L</_query_async_pinned>), and sending one would not
touch C<result_meta> anyway.

EV::Pg has had C<result_meta> since 0.02, the oldest version this distribution
accepts. A connection without it -- the stand-in of an offline test -- is taken
at its word, core's default.

=head2 _txn_inner_future

  my $future = $storage->_txn_inner_future($txn_ctx, $conn, $inner_future);

Core transport seam (L<DBIO::Storage::Async/_txn_inner_future>),
asked once the coderef of a C<txn_do> / C<txn_do_async> has returned and
before the transaction chains C<COMMIT> onto its Future. The case it exists
for: the coderef returned the Future of a call on the STORAGE --
C<< txn_do(sub { $storage->select_async(...) }) >> instead of one on C<$ctx>.
With a pool of one that call is queued for the connection the transaction
holds, and the transaction waits for it: nothing is blocking, so
L<DBIO::PostgreSQL::EV::Future/await> never sees it, and the transaction
stayed open with the pool stuck.

Here the Future is asked L<DBIO::PostgreSQL::EV::Future/_refuse_queued>: when
it waits for a caller queued for a connection of a pool whose every connection
is held by a callback on the call stack -- the C<BEGIN>'s callback that runs
the coderef is one -- the caller is taken out of the pool's queue and failed
with the refusal. The Future then takes core's error path:
C<ROLLBACK>, C<txn_do> dies with I<"Blocking wait refused: ...">, the
connection goes back to the pool, and the refused call never runs. Then core's
default runs (C<next::method>): it refuses every other Future the
coderef returned that waits in the queue of the transaction's own pool, also one
that a busy connection of a larger pool could still serve -- the transaction is
not held for it. A Future that is not queued for the pool is answered unchanged:
a call on C<$ctx>, a plain value, a Future of another class, a call that has a
connection. The rest of the transaction -- C<txn_timeout>, the retirement of a
connection whose C<ROLLBACK> failed, the session reset when the connection goes
back -- is core's C<txn_do_async> and not this seam.

=head2 _transform_sql

  my $positional = $storage->_transform_sql($sql);

Transport-internal SQL shaping (ADR 0032): number every C<?>
placeholder as PostgreSQL's positional C<$N>, left to right, so they line up
with the bind values. Called first by L</_query_async> and
L</_query_async_pinned>, and by L</_run_pool_connect_statement> for a connect
action that carries binds.

The reading is L<DBIO::PostgreSQL::Util/number_placeholders> and nothing else:
a C<?> is a placeholder where PostgreSQL reads SQL, not inside a string, a
quoted identifier, a dollar-quoted body or a comment, nor behind the
backslashed quote of an C<E''> string. Everywhere else it is one, behind an
operator character as well, for no operator is known here: the C<?> of
C<E<lt>@?>, C<@@?> and C<~@?> is a placeholder, and C<@? ?> is two, sent as
C<@$1 $2> -- as L<DBD::Pg> reads the same statement at the dbh. C<$N> already
there passes through. C<\?> outside such text is a literal question mark: the
backslash goes and a bare C<?> stays in the statement, the way to write the
operators C<?>, C<?|>, C<?&> and C<@?> in SQL sent through here (and over the
dbh, with DBD::Pg 3.7.1 or later). The SQL maker writes the jsonpath operator
that way: its C<@\? ?::jsonpath> is sent as C<@? $1::jsonpath>. A statement
that mixes C<$N> and C<?> placeholders is refused, as DBD::Pg refuses it, in
the function's words, which name the mix and not the statement -- a refusal of
this transport's that names the caller's place (L</Refusals of the
transport>); a C<$N> in text and a C<\?> are no placeholder of either style, a
C<?> behind an C<@> is one. Because the backslash goes, a statement is shaped
once: the C<?> a C<\?> left is a placeholder to a second pass. The rule is
kept once, in that function, which the C<future_io> transport answers through
as well.

=head2 _query_async

Transport seam. Execute a query on a freshly-acquired pooled connection,
releasing it once the Future is ready -- to the pool it was acquired from,
which L</pool> is asked for once, here (L</_dispatch_query>). Returns a
L<Future> of the raw result rows (list of column arrayrefs for a result set,
or the affected-row count for plain DML -- ADR 0031 §3), exactly what the
inherited C<_run_crud> expects.

Receives SQL in the C<sql_maker> C<?>-placeholder dialect and shapes it into
PostgreSQL's positional C<$N> B<internally> (via L</_transform_sql>) before it
reaches libpq -- the ADR 0032 seam contract.

C<$bind_attrs> is optional (bind attribute hashes parallel to C<$bind>, none
for a raw statement) and goes to the statement trace only; the binds stay bare
values on the wire. The trace is core's L<DBIO::Storage::Async/_debug_query>;
the transport has none of its own.

The Future returned holds itself until it is ready: Future.pm holds a C<then>
sequence only weakly from the Future waiting on a full pool, so a caller that
drops it would take the chain, and the connection it borrows, with it. The
same goes for L</_notify_send>, L</copy_in> and L</deploy_async>.

=head2 _dispatch_query

  my $future = $storage->_dispatch_query($pg, $sql, $bind, $pool, $lease);

Dispatch a C<$N>-dialect query on the given connection and return a L<Future>
completed by libpq's completion callback. Releases the connection back to
C<$pool>, the pool it was acquired from, once the Future is ready (the pooled
L</_query_async> path). Croaks without C<$pool>, before anything is sent.

C<$lease> is the lease of the borrow, C<< $pool->_lease($pg) >> taken right
after the C<acquire> (L<DBIO::Storage::PoolBase/_lease>), and every
release of C<$pg> here -- the completion's and the refused dispatch's --
passes it. A completion that fires a second time, when C<$pg> has been handed
on or borrowed again, then releases nothing instead of taking the connection
from its new holder. Without it, the release is what it always
was.

B<The connection goes back to the pool it came from>, not to L</pool> asked
again when the statement ends. The Future is settled before the connection is
released, so the caller's callbacks run first, and one of them may disconnect
the storage -- a C<then>, C<on_done> or failure handler that calls
C<disconnect>, or a C<connect_info> that reconfigures it. L<EV::Pg> does not
call the callback it is delivering to again when the connection is finished
under it, so the release that follows finds the storage without a pool, and
does not ask L</pool> to build one: C<$pool> is shut down by then and takes
the release, and the report of a dead connection before it, as no-ops; the
storage stays without a pool until the next call builds one. The same holds
for L</_dispatch_notify> and L</copy_in>. A C<disconnect> from outside, with
the statement on the server, never showed this: EV::Pg calls the statement's
callback from inside C<finish>, while the pool being shut down is still the
storage's (measured against PostgreSQL 18 with EV::Pg 0.07,
F<t/76-completion-same-pool-live.t>).

Named sub, deliberately B<not> a closure inside the C<< ->then(sub {...}) >>
acquire chain: the completion callback is created HERE, in a sub
whose pad dies when this sub returns, so the bind arrayref lives only until
dispatch, not for the whole flight of the query. The C<< ->then >> closure
only calls this and is freed once C<acquire> resolves -- a callback created
inside it would be retained by libpq for the flight and would pin that
closure's pad (and C<$bind>) alive.

The Future is of L</future_class>, and the callback marks C<$pg> as delivering
for as long as it runs -- the C<then> callbacks on the Future run inside it --
so L<DBIO::PostgreSQL::EV::Future/await> can refuse a blocking wait there that
would make L<EV::Pg> deliver the next result on C<$pg> to the wrong callback.
Every callback this class hands to L<EV::Pg> to settle one of its Futures does
the same: L</_query_async_pinned>, L</_pipeline_sync>, L</_dispatch_notify>,
L</copy_in>, and the C<LISTEN> / C<UNLISTEN> of L</_listen_subscribe> /
L</_listen_unsubscribe>.

The callback settles the Future B<before> it releases the connection, so the
C<then> callbacks run while C<$pg> is still checked out -- a call they make
gets another connection, never the one whose result is being delivered
(L<DBIO::PostgreSQL::EV::Future/await>) -- and the release runs inside the
delivery frame. A blocking call there for which the pool has no other
connection, and none that can come back while the callback runs, is refused
rather than left to wait for C<$pg>; a blocking call that is
queued for it and given up on for another reason does not run when C<$pg> is
released either. It runs however the settling ends: an C<on_done>, C<on_ready>
or C<on_fail> callback on the Future that dies escapes C<done> / C<fail> --
L<Future> catches a die only in C<then> and its siblings -- so the settling
runs in C<eval>, the connection is released, and the die is rethrown to
L<EV::Pg>, which warns it. The Future keeps its own result or error.

A query L<EV::Pg> refuses at dispatch fails the Future with EV::Pg's own error,
and the connection goes back to the pool right there. EV::Pg croaks before it
queues the callback -- I<"not connected"> on a connection it has lost,
I<"PQsendQueryParams failed: another command is already in progress"> on a busy
one -- so the callback never runs and this is the connection's only release.

A connection that failed because it is B<gone> is not reused: it is retired
when it is handed back, and the next call gets a freshly spawned connection.
Gone means L<EV::Pg> no longer reports it connected after the failure -- see
L</_pg_report_if_dead> for why that, rather than the error message, is what
tells the two apart. A statement error the session survives (a syntax error, a
constraint violation, a busy connection's refusal) leaves the connection in
the pool. Usually the pool already knows by then: EV::Pg reports a lost
connection through its C<on_error> before it fails the statements queued on it
(L<DBIO::PostgreSQL::EV::Pool/_new_connection>); this covers the connection
that went without it -- one a caller closed with C<finish>, or whose
C<on_error> a caller replaced.

Every callback this class hands to L<EV::Pg> returns at once in a process
other than the one that issued its statement. A forked child that resumes the
EV loop closes its copies of the pooled connections
(L<DBIO::PostgreSQL::EV::Pool/Fork safety>), and EV::Pg calls back every
statement in flight with a I<"connection finished"> error; the child must not
answer that with a release into the pool, a settled Future or the caller's
callbacks -- they all belong to the parent. The Future stays pending in the
child.

=head2 _pg_refuse

  _pg_refuse($message);
  _pg_refuse($message, [ $dsn, $user, $password, \%attrs ]);

Throw a refusal of this transport's own -- what it refuses to do with what
the caller gave it (see L</Refusals of the transport>) -- as a
L<DBIO::Exception>, the way core throws its own:
C<< Some::method(): $message at FILE line N >>, where the place is the
caller's. A function, not a
method.

The place is found as L<DBIO::Exception/throw> finds it, through
L<DBIO::Carp>: the first frame outside DBIO -- and outside L<Future> and
L<EV>, whose frames stand between the caller and a refusal reached in a
callback of the event loop. So it is the caller's line whether the caller
called into the transport itself, went through the pool, or ran the loop in
which the refusal was reached: a callback of the caller's names the line in
it that called into the transport; a callback of the transport's own (a
C<LISTEN> once the listen connection is up) names where the caller ran the
loop -- the C<< ->get >> of a Future of L</future_class>, or the caller's
C<EV::run>.

Under L<Carp>'s verbose mode the exception carries a stack trace instead, the
one L<DBIO::Exception/throw> writes with core's L<DBIO::Util/masked_longmess>.
The connect info given is handed to it, so a password the refused connect
info holds is masked where a frame repeats it, as a password among the
arguments of a frame always is.

=head2 _pg_server_error

  my $error = $storage->_pg_server_error($pg, $text);
  my $error = $storage->_pg_server_error($pg, $text, \@values);

What a statement's callback fails its Future with: the
L<DBIO::Exception::Server> for C<$text> when the server refused the statement,
else C<$text> as it came, masked (below). Called inside the callback of the
statement -- B<only there>, where EV::Pg has just set C<error_fields> for an
error result and for nothing else. C<\@values> are the plain values bound to
the statement (C<_pg_error_values>); the callbacks of L</_dispatch_query>,
L</_query_async_pinned> (also in a pipeline) and L</_dispatch_notify> hold a
copy of them for the statement's flight, no more.

C<$text> is the server's when C<< $pg->error_fields >> has a C<severity> and a
C<primary> and the text begins with them, as libpq renders an error:
C<SEVERITY:  primary>, with C<sqlstate: > between the two in verbose mode. The
text of a lost connection, an aborted pipeline, a finished connection, an empty
query or EV::Pg's own croak begins with none of that, and stays a string,
although C<error_fields> still holds the last server error.

An error message names keys and columns, never values, whether or not it is
the server's and whether or not the connection can answer C<error_fields>: the
text passes L</_pg_mask_error_text> -- the bound values wherever they stand,
then the values the server quotes in the forms of its messages
(L<DBIO::PostgreSQL::Util/mask_error_details>) -- and the object's C<message>
is that text. C<detail> is the server's detail field with the same net and
the values of its forms masked
(L<DBIO::PostgreSQL::Util/mask_detail_values>), so a unique violation reads
C<Key (name)=(***) already exists.>, as on the synchronous storage and on
C<future_io>. A text of no known form is not changed.

Only a plain string is looked at: an object and C<undef> pass unchanged.

=head2 _pg_mask_error_text

  my $text = $storage->_pg_mask_error_text($text, \@values);

The text of an error with the values taken out, for every text of the
server's or libpq's that reaches an exception or a failed Future: the values
bound to the statement (each of four characters or more, wherever it stands --
L<DBIO::Util/mask_bound_values>, the net of core's
L<DBIO::Storage::DBI/_mask_error_values>), then the values the server quotes in
the forms of its messages (L<DBIO::PostgreSQL::Util/mask_error_details>).
C<\@values> is optional. A text of no known form, C<undef> and a reference
come back as they are, a text already masked comes back unchanged, and it
never dies. The text of a statement without binds -- the C<DISCARD ALL> of the
session reset, a C<LISTEN> -- passes it too.

=head2 _pg_report_if_dead

  $storage->_pg_report_if_dead($pool, $pg);

Called after a statement on the pooled connection C<$pg> failed, or L<EV::Pg>
refused to dispatch it, and before C<$pg> goes back to the pool: when EV::Pg
no longer reports C<$pg> connected, tell the pool it is dead
(L<DBIO::Storage::PoolBase/_mark_connection_dead>), so the release
retires it instead of idling it. C<$pool> is the pool C<$pg> was
acquired from, the one its release goes to -- not L</pool> asked at this
moment (see L</_dispatch_query>).

The error message does not decide, EV::Pg's own view of the connection does.
EV::Pg tears a connection down on every connection-level error -- the server
ended the session, the socket broke, the protocol went out of step -- before
it fails the statements queued on it (I<"connection lost">); from then on
C<is_connected> is false and a dispatch croaks I<"not connected">. A statement
error the session survives, and the refusal of a busy connection (I<"another
command is already in progress">), leave it true. C<finish> is the one call
that fails the queued statements (I<"connection finished">) B<before> it
closes the connection, so a statement in flight on a connection someone
finishes is not reported, and the connection goes back to the pool. EV::Pg
0.02 and 0.07 behave alike here. Harmless when the pool already knows: the
report may be made any number of times.

A connection that sits idle and is not connected any more does not get as far
as a dispatch: the pool asks EV::Pg, and looks at the socket, before it hands
an idle connection out (L<DBIO::PostgreSQL::EV::Pool/_idle_connection_alive>).
The dispatch's croak is the only report left where the pool asks nothing: a
connection handed straight from a release to a queued caller, and one that is
lost after the pool has looked.

=head2 _reset_pool_connection

  my $future = $storage->_reset_pool_connection($pg);

Core's session-reset seam (L<DBIO::Storage::Async/_reset_pool_connection>, ADR
0079), asked by L<DBIO::Storage::PoolBase/release> when a borrow ends. Every
borrow of a pooled connection has a session of its own: C<DISCARD ALL> goes
out on C<$pg> and, once the server has answered it, the connect actions run
again (L<DBIO::Storage::Async/_setup_pool_connection>: the connection's
C<search_path> and extension C<LOAD>, C<on_connect_do>, C<on_connect_call>).
The pool hands the connection to the next borrower when the returned Future is
done, and retires it when the Future fails.

C<DISCARD ALL> ends what the session of one borrow holds: settings
(C<set_config(..., false)>, C<SET>, C<SET ROLE>, C<SET SESSION AUTHORIZATION>,
the session's isolation level), temporary tables, prepared statements, cursors,
C<LISTEN> registrations, sequence state (C<currval>, C<lastval>) and the
session-level advisory locks, which it releases. There is no way to switch the
reset off, and nothing else in this class resets: a statement, a transaction
after its C<COMMIT> or C<ROLLBACK>, a pipeline and a C<copy_in> all end in
C<release>, and the reset is the pool's.

The statement is sent bare (Simple Query protocol, no binds) on exactly this
connection, outside the transaction queue of the pinned path. It runs in no
transaction block, which C<DISCARD ALL> requires: a transaction has ended with
its C<COMMIT> or C<ROLLBACK> before the borrow does. The connect actions run
from an EV timer once the answer has been delivered, not inside that callback:
they drive the EV loop, which EV::Pg does not take inside a callback of the
connection they run on. The Future fails with a message that names the step --
the reset or the connect actions -- and carries no statement text, bind or
connection parameter.

=head2 _query_async_pinned

Transport seam. Like L</_query_async> but runs on the supplied pinned
connection and does B<not> release it -- used for queries inside a pinned
transaction, and by core's DDL runner and pipeline context. Shapes the incoming
C<?>-dialect SQL internally via L</_transform_sql> exactly as L</_query_async>
does. It takes the optional C<$bind_attrs> of L</_query_async> and hands it to
the trace (L<DBIO::Storage::Async/_debug_query>) alone.

B<One statement at a time.> Outside pipeline mode libpq runs one statement at a
time on a connection, and L<EV::Pg> refuses a second while the first is in
flight -- it croaks I<"PQsendQueryParams failed: another command is already in
progress">. A statement issued on a connection while one of this method's
statements is in flight there therefore waits in that connection's queue, and
is sent once the one before it has its result, in the order they were issued.
The next one is sent from the completion callback B<before> that callback
settles its Future, so a statement a C<then> callback issues queues behind the
ones already waiting.

That is what makes a C<txn_do> coderef roll back cleanly when it dies while one
of its statements is in flight -- after C<< $ctx->insert_async(...) >>, or when
a blocking C<$ctx> method is refused (L<DBIO::PostgreSQL::EV::Future/await>):
core's C<ROLLBACK> waits for that statement's result, then runs, the
transaction fails with the coderef's own error, and the connection goes back to
the pool IDLE. Two C<*_async> calls on the context that are not chained both
run, in order (core waits for both before C<COMMIT>, see
L<DBIO::PostgreSQL::EV::TransactionContext>).

B<Nothing after the end.> Once core's C<COMMIT> or C<ROLLBACK> has been issued
on the connection, a further statement issued on it before that has run is
refused: its Future fails at once and it is never sent. Queued behind the
C<COMMIT> or C<ROLLBACK> it would be sent from that statement's completion
callback, so it would run after the transaction, outside of it -- a write
committed on its own after a rollback -- and still be in flight when core
hands the connection back to the pool, where the next caller's statement would
be refused. Only a statement the coderef did not chain into the Future it
returns can get there, from a C<then> on a statement still in flight.

A statement issued on the transaction context does not get this
far: core ends the context as it sends C<COMMIT> or C<ROLLBACK>, and the
context refuses the statement itself, synchronously (I<"transaction context is
no longer active">). This refusal is left for the connection reached past the
context -- C<< $ctx->txn_conn >> handed to this method directly, the way core's
C<deploy_async> runs its DDL -- which core does not see.

B<Pipeline mode> is left alone: between L</_pipeline_enter> and
L</_pipeline_exit> libpq takes any number of statements, and each is sent at
once, to be batched. Behind the pipeline's sync point it is not: the server
answers a statement sent in pipeline mode only once a sync point follows it,
so one sent there would never be answered. That is what a transaction's
C<ROLLBACK> is when its coderef ended with C<< $ctx->pipeline >> still waiting
for its sync. Such a statement waits, in order, until
L</_pipeline_exit> has left pipeline mode, and is sent then like any pinned
statement; when the exit is refused it fails with the exit's error.

A statement L<EV::Pg> refuses at dispatch -- I<"not connected"> on a connection
it has lost, say -- fails its Future with EV::Pg's own error, whether it was
sent at once or from the queue, and the statements queued behind it are still
sent. The statement's
callback returns at once in a process other than the one that issued it, as
every callback of this class does.

=head2 _run_pool_connect_statement

  $storage->_run_pool_connect_statement($conn, $sql, $attrs, @bind);

Native-backend override of the core connect-action runner seam
(L<DBIO::Storage::Async/_run_pool_connect_statement>). The base default drives a
blocking DBI C<do> and croaks on a non-DBI connection; an EV::Pg handle is
neither a C<< { dbh => $dbh } >> wrapper nor a do-capable DBI handle, so this
override drives the statement B<synchronously to completion> on that very
connection over the EV loop.

Called once per freshly-spawned pool connection from
L<DBIO::Storage::Async/_setup_pool_connection>, so the owning sync storage's
C<on_connect_do> / C<on_connect_call> (including C<connect_call_*> methods such
as an extension's C<connect_call_load_age>) replay on every new EV pool
connection, identical to the C<future_io> pool. The freshly-spawned EV::Pg
handle may still be mid-connect, so we first drive the loop until it is up, then
run the statement and drive the loop until it completes. C<$attrs> (the DBI
attribute hashref) has no EV::Pg analogue and is ignored, except for the
reserved key C<dbio_rows>: when it is true the method returns the rows of the
statement as an array reference of row array references (values as EV::Pg
delivers them, SQL NULL as C<undef>; an empty array reference for a statement
that answers no rows), as the core default does with C<selectall_arrayref>.
Without it the method returns nothing.

B<Refused inside a delivery.> Core spawns a pool connection synchronously,
from C<acquire>, whenever the pool has room and no idle connection, so a
C<*_async> call made inside a C<then> callback or a C<txn_do> coderef can
bring a connection up right there -- and this replay then runs the EV loop
inside that callback. Inside a callback of one of this transport's own
connections that has more results due -- a C<txn_do> coderef that has already
sent a C<$ctx> statement, a C<then> on a statement of a pipeline batch --
L<EV::Pg> would hand the next of those results to the callback that is still
running and then spin, exactly the wait L<DBIO::PostgreSQL::EV::Future/await>
refuses. Measured against PostgreSQL 18.6 with a coderef that sent
C<< $ctx->_query_async >> and then a pool call that spawned: EV::Pg reported
I<"exception in callback: ... is already done and cannot be -E<gt>done"> and the
process spun at 100% CPU until it was killed. So the replay refuses
the same wait, on entry and before every iteration, and dies with I<"Blocking
wait refused: ...">. The pool retires the half-opened connection, and the call
that asked for it fails its Future with an error carrying the refusal
(L<DBIO::Storage::PoolBase> turns a spawn that dies into a failed C<acquire>);
measured the same way, it fails at once and the pool is left idle. Chain that
call with C<then> onto the statement in flight, or run it on the transaction
context. An C<on_disconnect_do> / C<on_disconnect_call> run at pool shutdown
goes through here too; core runs those best-effort, so a refused one is
skipped.

B<The connection is marked as being opened> while this runs
(L<DBIO::PostgreSQL::EV::Future/_replaying>). The pool counts it by
now, it is not idle, and no callback of this transport is being delivered for
it -- yet it is handed out only once the spawn has returned, and whatever the
loop runs meanwhile runs above the spawn on the call stack. A blocking call on
the storage made there, by a timer of the application, say, is queued for that
connection in a pool of one and could never be served; the mark is how
L<DBIO::PostgreSQL::EV::Pool/_pg_held_by_callbacks> knows, and
L<DBIO::PostgreSQL::EV::Future/await> refuses the wait. Without it the wait
hung, or died of a loop that had run dry (measured against PostgreSQL 18.6,
F<t/78-blocking-behind-spawn-live.t>).

=head2 _pipeline_enter

Open libpq pipeline mode on the connection, and note it: until
L</_pipeline_exit>, L</_query_async_pinned> sends every statement on it at once
instead of queueing it behind the one in flight.

=head2 _pipeline_sync

Flush the batched queries and resolve once the pipeline sync point has been
acknowledged. EV::Pg's C<pipeline_sync> takes a completion callback; we adapt it
to the Future the inherited scaffold expects.

L<EV::Pg> calls that callback with C<(1)> when the server acknowledged the sync
point, and with C<(undef, $error)> when the batch never got there. The Future
is done in the first case only; in the second it fails with EV::Pg's own
message, and the scaffold fails the whole pipeline with it. The error comes two
ways (EV::Pg 0.07 and 0.02 alike):

=over 4

=item * The connection goes with the sync still pending: I<"connection lost">
when EV::Pg loses it, I<"connection finished"> when it is closed. Losing it is
what happens when the backend dies during the batch -- its statements fail
first, then the sync (measured against PostgreSQL 18.6).

=item * An error result arrives while the sync is the next thing EV::Pg waits
for, as the server's I<"FATAL:  terminating connection due to administrator
command"> does on a batch without statements. EV::Pg keeps the sync callback at
the head of its queue after that and calls it B<again> with I<"connection
lost"> once the connection goes. The Future settles on the first call, and
later ones return without touching it.

=back

=head2 _pipeline_exit

Close libpq pipeline mode on the connection. When EV::Pg refuses, the
connection stays in pipeline mode, and noted as such for L</_query_async_pinned>
(core retires it).

=head2 _listen_open

  my $f = $storage->_listen_open;   # done with the listen connection

Core listen seam (L<DBIO::Storage::Async/_listen_open>): open the dedicated
listen connection -- a B<new> L<EV::Pg> handle, never one from the pool -- and
resolve once it is connected; a connect that fails fails the Future with
EV::Pg's message. Its conninfo is what a pool spawn would get at this moment:
fresh credentials through L<DBIO::Storage::Async/_conninfo_provider> when an
AccessBroker is attached, so rotated credentials apply to every reconnect
exactly as they do to the pool (ADR 0009), otherwise C<_conninfo_string>.
The pool's connect-action replay (L</_run_pool_connect_statement>) does not
run on it: none of those statements concern listening, and a session-setup
statement with side effects should not run once more per reconnect.

The handle is built by L<DBIO::PostgreSQL::EV::Pool/_new_connection>, the
constructor of every pooled connection, so it closes B<fork-safe> like them
(L<DBIO::PostgreSQL::EV::Pool/Fork safety>): a forked child that
exits or drops its copy leaves the parent's LISTEN session alone, and a child
that resumes the EV loop closes its copy before it can read the parent's
notifications.

It is opened with C<keep_alive>, so C<EV::run> keeps running while the
connection is open, and its C<on_connect>, C<on_error> and C<on_notify> are
set at once: a notification that arrives before watching starts is held for
L</_listen_watch>, and a connection-level error after the connect goes to
L<DBIO::Storage::Async/_listen_lost>. Refuses (L</Refusals of the
transport>) when the storage has no connect info.

=head2 _listen_close

  $storage->_listen_close($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_close>): clear the handle's
handlers, so nothing it reports reaches core any more, and C<finish> it. A
dead connection is fine -- EV::Pg's C<finish> does not fail on one -- and a
connection already closed is left alone. A C<LISTEN> or C<UNLISTEN> still in
flight fails its Future with EV::Pg's I<"connection finished">. Core has
stopped the watch first whenever it started it (L</_listen_unwatch>), and
never calls this in a process other than the opener.

=head2 _listen_subscribe

  my $f = $storage->_listen_subscribe($conn, $channel);

Core listen seam (L<DBIO::Storage::Async/_listen_subscribe>): send
C<LISTEN "channel"> on the listen connection and resolve once the server has
answered; fail with the server's error otherwise. The channel is validated and
quoted as one identifier (L</_pg_quote_channel>), never interpolated raw
(ADR 0017 §3, as restated by core ADR 0056). A channel it refuses makes the
seam throw; core then finds the connection alive, drops the channel and fails
its C<listen> Future with the reason.

A C<LISTEN> L<EV::Pg> refuses at dispatch -- it croaks before it queues the
callback, I<"not connected"> on a connection it has lost, I<"another command
is already in progress"> on a busy one -- fails the Future with EV::Pg's own
error. Core then probes the connection and heals or reports.
Core's
queue never has two channel operations in flight on the connection, so the
second case does not arise from here.

=head2 _listen_unsubscribe

  my $f = $storage->_listen_unsubscribe($conn, $channel);

Core listen seam (L<DBIO::Storage::Async/_listen_unsubscribe>): C<UNLISTEN>,
with the same validation, quoting and failure handling as
L</_listen_subscribe>. Core has already dropped the channel from its registry,
so a notification for it that is still on its way is not dispatched.

=head2 _pg_quote_channel

  my $sql_ident = $storage->_pg_quote_channel($channel);   # "jobs"

Validate a channel name and quote it as B<one> PostgreSQL identifier: wrapped
in double quotes, embedded C<"> doubled. Quoting makes the name exact -- case
included -- which is also how C<pg_notify> (L</_notify_send>) takes it, so
C<listen('Jobs')> and C<notify('Jobs')> meet. A C<.> stays part of the name:
C<app.events> becomes C<"app.events">, not C<"app"."events">.

Refused, by throwing: an undefined, empty or reference channel, one containing
a NUL byte, and one longer than 63 bytes in UTF-8 (PostgreSQL's
C<NAMEDATALEN> - 1). The length limit is a refusal, not a truncation, because
a longer name can never deliver: C<LISTEN> would silently truncate it and then
report notifications under the truncated name, which matches no registered
channel, and C<pg_notify> rejects it outright (I<"channel name too long">).

The rule itself lives in L<DBIO::PostgreSQL::Util/quote_channel>, the one
implementation the C<future_io> transport shares;
this method delegates to it. The helper croaks, which blames its caller --
this file; a refusal is raised again in the helper's words as a refusal of
this transport's, naming the caller's place (L</_pg_refuse>).

=head2 _listen_watch

  $storage->_listen_watch($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_watch>), B<socket-driven>:
the EV loop already watches the connection's socket -- EV::Pg's read watcher
-- so starting to watch switches what its handlers do. From now on every
notification EV::Pg's C<on_notify> reports goes to
L<DBIO::Storage::Async/_listen_dispatch>, in arrival order, and a
connection-level error its C<on_error> reports (the server closed the
connection, a protocol error) goes to L<DBIO::Storage::Async/_listen_lost>.

First it delivers the notifications that arrived after the connect and before
this call -- while core subscribed the channels one by one -- in the order they
arrived. EV::Pg 0.07 discards a notification when no C<on_notify> is set, and
0.02 leaves it in libpq's buffer until the next read, so C<on_notify> is set
from the open on and holds them until here. A channel callback that ends the
connection (unlistening the last channel, C<listen_reconnect>) stops that
delivery there.

Throws, which core counts as a dead connection, when the handle is gone or
EV::Pg does not report it connected.

=head2 _listen_unwatch

  $storage->_listen_unwatch($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_unwatch>): clear the handle's
C<on_notify>, C<on_error> and C<on_connect> and drop what is held, so no
L<DBIO::Storage::Async/_listen_dispatch> or
L<DBIO::Storage::Async/_listen_lost> for C<$conn> follows. Core closes the
connection right after (L</_listen_close>).

=head2 _listen_probe

  my $alive = $storage->_listen_probe($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_probe>), asked by
L<DBIO::Storage::Async/listen_alive> and after a failed C<LISTEN> /
C<UNLISTEN>: EV::Pg's C<is_connected> -- the handle exists, its connect has
completed and libpq reports C<CONNECTION_OK> (the same in EV::Pg 0.02 and
0.07) -- and the look the pool takes at an idle connection
(L<DBIO::PostgreSQL::EV::Pool/_pg_peer_closed>): the server's end of the socket
is not closed. Synchronous, without a round trip, nothing sent, nothing read,
no loop run. EV::Pg keeps reporting the handle connected until the loop has
read the close, so without the second look a program that only blocks was told
a session was alive that C<pg_terminate_backend> had ended; the
loop reports it through C<on_error> as soon as it runs, as before. Not seen: a
peer that vanished without closing, and the milliseconds between a backend's
last message and its exit. The C<future_io> transport pings instead; a
synchronous ping here would have to run the EV loop from inside
C<listen_alive>.

=head2 _listen_delay

  my $f = $storage->_listen_delay($seconds);

Core listen seam (L<DBIO::Storage::Async/_listen_delay>): the reconnect
backoff, an L<EV/timer> settling a L</future_class> Future from the EV loop.
The timer lives until it fires or the Future is cancelled, which core does
when a wait is cut short (C<listen_reconnect>, C<disconnect>), and which stops
it.

=head2 _notify_send

  my $f = $storage->_notify_send($channel, $payload);

Core listen seam (L<DBIO::Storage::Async/_notify_send>), behind core's
C<notify>: acquire a B<pooled> connection -- sending needs no listen
connection (ADR 0003) -- and run C<SELECT pg_notify($1, $2)> on it through
L</_dispatch_notify>, channel and payload bound, never interpolated. An
C<undef> payload is sent as C<''>; PostgreSQL has no NULL payload. Resolves
void once the server has answered. Core has already refused a missing channel;
a channel over 63 bytes or a payload of 8000 bytes or more fails the Future
with the server's error.

=head2 _dispatch_notify

  my $future = $storage->_dispatch_notify($pg, $channel, $payload, $pool, $lease);

Dispatch a pg_notify on the given connection and return a L<Future> completed
by libpq's completion callback. Releases the connection back to C<$pool>, the
pool it was acquired from, once the Future is ready (the pooled
L</_notify_send> path behind core's C<notify>) -- never to L</pool> asked
again, so a C<then> on a C<notify> that disconnects the storage leaves it
without a pool (see L</_dispatch_query>). Croaks without C<$pool>,
before anything is sent. C<$lease> is the lease of the borrow, passed to every
release as in L</_dispatch_query>.

Named sub, deliberately B<not> a closure inside the C<< ->then(sub {...}) >>
acquire chain: the completion callback is created HERE, in a sub
whose pad dies when this sub returns, so the freshly-built bind arrayref
lives only until dispatch, not for the whole flight of the query -- the same
ADR 0044 dispatch pattern as L</_dispatch_query>. The C<< ->then >>
closure only calls this and is freed once C<acquire> resolves.

Resolves B<void> -- C<< $f->done >> with no arguments, a pure completion
signal. Unlike L</_dispatch_query> it deliberately does B<not> pass the
pg_notify result row through; the caller of C<notify> only waits for the
NOTIFY to be dispatched.

The completion callback settles the Future B<before> it releases the
connection, as in L</_dispatch_query>: a C<then> callback on the Future runs
while the connection is still checked out, so a call it makes gets another
connection, never the one whose result L<EV::Pg> is still delivering; and an
C<on_done>, C<on_ready> or C<on_fail> on it that dies does not keep the
connection from going back. A blocking
call in such a C<then> never gets that very connection
(L<DBIO::PostgreSQL::EV::Future/await>).

A NOTIFY L<EV::Pg> refuses at dispatch fails the Future with EV::Pg's own error
and releases the connection at once, as in L</_dispatch_query>.
Either way, a connection that failed because it is gone is retired rather than
reused, as in L</_dispatch_query>.

=head2 copy_in

  $storage->copy_in($table, \@columns, sub {
      my ($put) = @_;
      $put->(['Miles Davis', 'Jazz']);
      $put->(['John Coltrane', 'Jazz']);
  });

Bulk load data via PostgreSQL COPY FROM STDIN. The callback receives a writer
function that accepts arrayrefs of column values. Transport value-add:
overrides the base's croaking default (declared as the C<copy> capability).

B<Values> are given as they are and arrive as they are. The writer writes each
by PostgreSQL's COPY text-format rules: a backslash as C<\\>, a TAB as C<\t>,
a line feed as C<\n> and a carriage return as C<\r>, so a value never ends its
field or its row, and the two characters C<\N> in a value stay those two
characters. C<undef> is SQL NULL; the empty string is the empty string. There
is no CSV mode, and a value needs no escaping on the caller's side.

B<Names>: C<$table> is a table name, C<schema.table> for a qualified one, and each entry of C<\@columns> one column
name, written as identifiers by the server's rule
(L<DBIO::PostgreSQL::Util/quote_ident>): bare when plain lower case and no key
word, double-quoted otherwise, whatever the schema's C<quote_names> says. A
dot in C<$table> separates schema and table, each part its own identifier.

The returned Future settles, and the pooled connection is handed back to the
pool exactly once, however the COPY ends -- also when L<EV::Pg> refuses the
COPY command at dispatch (it croaks before it queues the callback, with I<"not
connected"> or I<"another command is already in progress">), and when it loses
the connection during the COPY (it then drops the callback without its second
firing, and the writer and C<put_copy_end> croak I<"not connected">). The
Future fails with the callback's own error if the callback died, whatever
became of the stream after that; else with what ended the COPY -- the server's
error, EV::Pg's (I<"not connected">, I<"connection lost">), or I<"put_copy_end
failed: "> and libpq's reason.

B<The writer> dies when it cannot put its row. L<EV::Pg> croaks I<"not
connected"> once it has lost the connection, and the COPY fails whatever the
callback does about that. A C<put_copy_data> that answers 0 -- libpq could not
make room for the row in its output buffer -- or -1 is the end of the COPY as
well, whether the callback lets the writer's die through or catches it: the
writer dies for every further row, the COPY is aborted, and the Future fails
with the writer's error, I<"put_copy_data failed: "> and libpq's reason,
unless the callback goes on to die of something else. A COPY does not complete
without a row it was given. The writer is good while the callback
runs: called after that it is refused (L</Refusals of the transport>), its
connection being the pool's again, or in the middle of another caller's COPY.

The callback runs to its end before the L<EV> loop does anything else. What
the server has not read by then waits in libpq's output buffer, in this
process -- with a server that reads more slowly than the callback writes, most
of the stream. libpq lets that buffer grow as long as it can get the memory,
and C<put_copy_data> answers 0 once it cannot.

B<How the COPY ends decides what becomes of its connection.> A COPY the server
has answered -- done, failed or refused -- leaves the connection ready for the
next statement, and it goes back to the pool; one that failed because the
connection is gone is retired on the way, as in L</_dispatch_query>. A COPY
that ends with its stream still open is retired in any case
(L<DBIO::Storage::PoolBase/_mark_connection_dead>), and the next call gets a
fresh connection. That is a C<put_copy_end> that

=over 4

=item * answered -1. L<EV::Pg> does no more about it than hand libpq's -1 on
(0.02 and 0.07 alike). Where libpq could not queue the end of the stream it
is still in the COPY, on an open connection, and refuses every statement with
I<"another command is already in progress">; nothing is left to end the COPY
with. Where libpq met the end of the connection, EV::Pg has not heard of it.

=item * croaked I<"not connected">: EV::Pg lost the connection during the
COPY.

=item * answered 1 on a connection that is gone. libpq had dropped it in an
earlier write, and EV::Pg learns of that in the flush behind C<put_copy_end>,
where it drops the callback it is delivering to without calling it again. So
C<is_connected> is asked right after C<put_copy_end>, and the COPY ends there
with I<"connection lost"> rather than wait for an answer that cannot come.

=back

Wherever the COPY ends inside L<EV::Pg>'s callback, the Future is settled
B<before> the connection goes back, as in L</_dispatch_query>: a C<then>
callback on the returned Future runs while the connection is still checked
out, so a call it makes gets another connection, never the one whose result
EV::Pg is still delivering; and an C<on_done>, C<on_ready> or C<on_fail> on it
that dies does not keep the connection from going back. A COPY
EV::Pg refuses at dispatch -- no callback, so nothing is being delivered on
the connection -- goes back before its Future fails, as in
L</_dispatch_query>.

A call of the callback that comes after the COPY has ended returns without
touching the Future or the pool, as a late call does in L</_pipeline_sync>.
EV::Pg keeps the callback queued after a C<put_copy_end> that answered -1, to
call it again whenever it reads from the connection while libpq has the COPY
open, and when the connection goes. Retiring the connection closes it inside
the callback's own delivery, and there EV::Pg 0.02 and 0.07 drop the callback
instead.

B<The connection goes back to the pool it was acquired from>, however the COPY
ends -- released, reported dead or retired there, never at L</pool> asked
again (see L</_dispatch_query>). The callback runs inside the COPY's
delivery, and so do the callbacks on the returned Future: when one of them
disconnects the storage, the COPY ends on a storage without a pool, and that
pool is shut down, where all three are no-ops. A callback that disconnects the
storage ends its own COPY: the connection is finished under the stream, the
writer and C<put_copy_end> croak I<"not connected">, the Future fails with
that, and the server loads nothing. The COPY's end builds no new pool on the
disconnected storage.

The connection's lease is taken right after the C<acquire>
(L<DBIO::Storage::PoolBase/_lease>) and every release of it passes
the lease, so a release that arrives once the connection has been handed on
takes nothing (see L</_dispatch_query>).

=head2 _ddl_class

The install-DDL generator the inherited L<DBIO::Storage::Async/deploy_async>
resolves through L<DBIO::Storage::Async/_install_ddl>: L<DBIO::PostgreSQL::DDL>
-- the same class the B<sync> C<< $schema->pg_install_ddl >> path uses
(L<DBIO::PostgreSQL/pg_install_ddl>), so async and sync deploy emit
byte-identical DDL.

The DDL batch runs inside a single async transaction, not statement-at-a-time:
the sync L<DBIO::PostgreSQL::Storage> declares C<< _use_transactional_ddl(1) >>
(PostgreSQL's DDL is transactional), so the inherited C<deploy_async> probes
that capability on the owning sync storage (L<DBIO::Storage::Async/_owner_storage>)
and takes its C<txn_do_async> branch -- a failure on statement N of M rolls back
the preceding N-1, matching today's behaviour. That branch calls
C<< $ctx->txn_conn >>, which L<DBIO::PostgreSQL::EV::TransactionContext> answers
because it inherits it from core's generic context; the native
C<txn_pg> is the alias on top of it, not the other way round.

=head2 deploy_async

    my $future = $storage->deploy_async($schema, \%opts);

Core's L<DBIO::Storage::Async/deploy_async>, behind one question to the
server (as for C<future_io>). The
schema of a C<CREATE EXTENSION> is, as in L<DBIO::PostgreSQL::Deploy>, the
declared one, else the one the control file of the extension fixes, else
C<public> -- and the control file is the server's to tell. So before the DDL
is built, a pooled connection is asked (asynchronously, no second blocking
connection) for the schemas the control files of the extensions the schema
class declares fix (L<DBIO::PostgreSQL::DDL/control_schemas_sql>), a declared
schema other than a fixed one is refused with the Future failed, before any
statement of the DDL (L<DBIO::PostgreSQL::DDL/check_control_schemas>), and
the answer reaches L</_install_ddl> as C<extension_control_schemas>. An
extension with a fixed schema (C<age>, C<postgis_topology>, ...) is thus
written without the C<WITH SCHEMA> clause the server would refuse. A schema
that declares no extension, or no schema class with the PostgreSQL component,
asks nothing.

=head2 _install_ddl

The install script (core's C<_install_ddl>, which asks the generator without
options), with the control schemas L</deploy_async> read from the server
passed to L<DBIO::PostgreSQL::DDL/install_ddl> as
C<extension_control_schemas>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
