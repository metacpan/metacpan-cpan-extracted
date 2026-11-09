package DBIO::Storage::DBI;
# ABSTRACT: DBI storage handler
# -*- mode: cperl; cperl-indent-level: 2 -*-

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Storage::QueryRewrite DBIO::Storage::DBI::Capabilities DBIO::Storage::DBI::DataTypeClassifier DBIO::Storage::DBI::AccessBroker DBIO::Storage/;
use mro 'c3';

use DBIO::Carp;
use Scalar::Util qw/refaddr weaken reftype blessed/;
use Context::Preserve 'preserve_context';
use Try::Tiny;
use Devel::GlobalDestruction;
use DBIO::Util qw(is_plain_value is_literal_value scope_guard mask_connect_secrets mask_statement_secrets mask_statement_fingerprint mask_bound_values);
use DBIO::Util qw(quote_sub perlstring serialize dump_value sigwarn_silencer is_windows is_dev_release old_mro help_url);
use DBIO::Skills;
use DBIO::Deploy::Base ();
use DBIO::Storage::Composed;
use DBIO::Exception::Server ();
use namespace::clean;

# default cursor class, overridable in connect_info attributes
__PACKAGE__->cursor_class('DBIO::Storage::DBI::Cursor');

__PACKAGE__->mk_group_accessors('inherited' => qw/
  sql_quote_char sql_name_sep
/);

# Class-level hook to redact bind values before they are interpolated into
# the trace output. The default shows every value as it is, except the bind
# of a column with encode_column: its bind attributes carry redact => 1 and
# the value shows as '***'.
# Install a custom coderef on the storage class:
#
#   __PACKAGE__->redact_bind_value(sub {
#     my ($colname, $value, $bindattrs) = @_;
#     return defined $colname && $colname eq 'password' ? '***' : $value;
#   });
#
# The coderef receives the column name (or undef if no column metadata is
# attached to the bind slot), the raw bind value and the bind attribute hash
# (or undef), and must return the value to interpolate into the trace. The
# original bind value passed to the database is *not* modified - only the
# trace string is.
__PACKAGE__->mk_classdata('redact_bind_value' => sub {
  return ( ref $_[2] eq 'HASH' && $_[2]{redact} ) ? '***' : $_[1];
});

__PACKAGE__->mk_group_accessors('component_class' => qw/sql_maker_class datetime_parser_type/);

__PACKAGE__->sql_maker_class('DBIO::SQLMaker');
__PACKAGE__->datetime_parser_type('DateTime::Format::MySQL'); # historic default

# Identifier quoting is ON by default (security hardening). Concrete drivers
# override sql_quote_char with their RDBMS-native quote; the bare base storage
# falls back to the ANSI SQL standard double quote so the default-on path never
# has to warn about a missing quote_char.
__PACKAGE__->sql_quote_char('"');
__PACKAGE__->sql_name_sep('.');

__PACKAGE__->mk_group_accessors('simple' => qw/
  _connect_info _dbio_connect_attributes _driver_determined
  _declared_storage_class
  _dbh _dbh_details _conn_pid _sql_maker _sql_maker_opts _dbh_autocommit
  _perform_autoinc_retrieval _autoinc_supplied_for_op _async_mode
  _async_context_owner_token _server_messages _parent_storage
/);

# Async mode registry (ADR 0030): maps a connect-time mode name to the embedded
# backend class that answers the six *_async methods for an instance connected
# with { async => $mode }. Generic modes (e.g. 'forked', 'future_io') register
# on a base class and are inherited by every driver; native modes (e.g. 'ev')
# are registered by the concrete driver storage class, so the same logical mode
# name resolves to a DB-specific backend. Lookup walks the instance's MRO, so a
# driver registration shadows/extends the generic ones. 'immediate' is the
# in-process degrade mode (no event loop, no embedded backend): it maps to the
# immediate Future class. It is the sole permitted non-DBIO::Storage::Async
# target; every other lazy-loaded target must satisfy that backend contract.
# Core registers only 'immediate' -- 'forked'/'future_io'/'ev' come from their
# add-on/driver dists, never auto-wired here.
my %_async_mode_registry;
__PACKAGE__->register_async_mode( immediate => 'DBIO::Future::Immediate' );

# the values for these accessors are picked out (and deleted) from
# the attribute hashref passed to connect_info. The names live once
# on DBIO::Storage and are consumed by both this sync path and the async strip
# (DBIO::Storage::Async), so the two lists can never drift.
#
# Only the *base* set can be registered here -- this runs at compile
# time, on this class. A driver that adds a storage option overrides
# _dbio_storage_option_names and registers the accessor for its own name in its
# own class body; _normalize_connect_info asks the live storage for the list,
# so the added name is routed to that accessor instead of leaking to DBI.
__PACKAGE__->mk_group_accessors('simple' =>
  map { __PACKAGE__->_dbio_storage_option_accessor($_) }
    __PACKAGE__->_dbio_storage_option_names
);


# Capability detection lives in DBIO::Storage::DBI::Capabilities (mixin).

# Each of these methods need _determine_driver called before itself
# in order to function reliably. We also need to separate accessors
# from plain old method calls, since an accessor called as a setter
# does *not* need the driver determination loop fired (and in fact
# can produce hard to find bugs, like e.g. losing on_connect_*
# semantics on fresh connections)
#
# The construct below is simply a parameterized around()
my $storage_accessor_idx = { map { $_ => 1 } qw(
  sqlt_type
  datetime_parser_type

  sql_maker
  cursor_class
)};
for my $meth (keys %$storage_accessor_idx, qw(
  deployment_statements

  build_datetime_parser

  txn_begin

  insert
  update
  delete
  select
  select_single

  _insert_bulk

  with_deferred_fk_checks

  get_use_dbms_capability
  get_dbms_capability

  _exists_value_sql
  _set_operation_keyword

  _random_function
  _explain_query

  _server_info
  _get_server_version
)) {

  my $orig = __PACKAGE__->can ($meth)
    or die "$meth is not a ::Storage::DBI method!";

  my $is_getter = $storage_accessor_idx->{$meth} ? 0 : 1;

  quote_sub
    __PACKAGE__ ."::$meth", sprintf( <<'EOC', $is_getter, perlstring($meth), perlstring(__PACKAGE__) ), { '$orig' => \$orig };

    if (
      # only fire when invoked on an instance, a valid class-based invocation
      # would e.g. be setting a default for an inherited accessor
      ref $_[0]
        and
      ! $_[0]->{_driver_determined}
        and
      ! $_[0]->{_in_determine_driver}
        and
      # if this is a known *setter* - just set it, no need to connect
      # and determine the driver
      ( %1$s or @_ <= 1 )
        and
      # Only try to determine stuff if we have *something* that either is or can
      # provide a DSN: a storage that never got connect info has neither
      $_[0]->_dbi_connect_info->[0]
    ) {
      # Reached directly -- no override sits above this method in the class
      # of the storage -- the determination may move the storage to a class
      # that has one, and that class answers the call. Reached through an
      # override's next::method (a declared driver storage, ADR 0059), the
      # override is already running: re-dispatching would run it a second
      # time and hand its result to the first run (karr k345). The call goes
      # on to the base method instead.
      my $direct = $_[0]->can(%2$s) == %3$s->can(%2$s);

      $_[0]->_determine_driver;

      goto $_[0]->can(%2$s) if $direct;
    }

    goto $orig;
EOC
}


sub new {
  my $new = shift->next::method(@_);

  $new->_sql_maker_opts({});
  $new->_dbh_details({});
  $new->{_in_do_block} = 0;

  # read below to see what this does
  $new->_arm_global_destructor;

  $new;
}

# This is hack to work around perl shooting stuff in random
# order on exit(). If we do not walk the remaining storage
# objects in an END block, there is a *small but real* chance
# of a fork()ed child to kill the parent's shared DBI handle,
# *before perl reaches the DESTROY in this package*
# Yes, it is ugly and effective.
# Additionally this registry is used by the CLONE method to
# make sure no handles are shared between threads
{
  my %seek_and_destroy;

  sub _arm_global_destructor {

    # quick "garbage collection" pass - prevents the registry
    # from slowly growing with a bunch of undef-valued keys
    defined $seek_and_destroy{$_} or delete $seek_and_destroy{$_}
      for keys %seek_and_destroy;

    weaken (
      $seek_and_destroy{ refaddr($_[0]) } = $_[0]
    );
  }

  END {
    local $?; # just in case the DBI destructor changes it somehow

    # destroy just the object if not native to this process
    $_->_verify_pid for (grep
      { defined $_ }
      values %seek_and_destroy
    );
  }

  sub CLONE {
    # As per DBI's recommendation, DBIO disconnects all handles as
    # soon as possible (DBIO will reconnect only on demand from within
    # the thread)
    my @instances = grep { defined $_ } values %seek_and_destroy;
    %seek_and_destroy = ();

    for (@instances) {
      $_->_dbh(undef);

      $_->transaction_depth(0);
      $_->savepoints([]);

      # properly renumber existing refs
      $_->_arm_global_destructor
    }
  }
}

sub DESTROY {
  my $self = $_[0];

  # A freed schema closes the connections of its embedded async storage. Only
  # the process that owns them does, and not in global destruction, where the
  # pool follows its own rules (karr k254, k234). The storage is torn down
  # only if one was built; DESTROY never builds it.
  if ( $self->{_async_storage_obj}
       and !in_global_destruction
       and ( !defined $self->_conn_pid or $self->_conn_pid == $$ ) ) {
    local ($@, $?);
    try {
      $self->_reset_async_context_owner_token;
      my $async = delete $self->{_async_storage_obj};
      $async->disconnect;
    }
    catch {
      warn "Async storage teardown failed in DESTROY: $_";
    };
  }

  $_[0]->_verify_pid unless is_windows();
  # some databases spew warnings on implicit disconnect
  local $SIG{__WARN__} = sub {};
  $_[0]->_dbh(undef);

  # this op is necessary, since the very last perl runtime statement
  # triggers a global destruction shootout, and the $SIG localization
  # may very well be destroyed before perl actually gets to do the
  # $dbh undef
  1;
}

# handle pid changes correctly - do not destroy parent's connection
sub _verify_pid {

  my $pid = $_[0]->_conn_pid;

  if( defined $pid and $pid != $$ and my $dbh = $_[0]->_dbh ) {
    $dbh->{InactiveDestroy} = 1;
    $_[0]->_dbh(undef);
    $_[0]->transaction_depth(0);
    $_[0]->savepoints([]);
  }

  return;
}


sub connect_info {
  my ($self, $info) = @_;

  return $self->_connect_info if !$info;

  $self->_connect_info($info); # copy for _connect_info
  delete $self->{_connect_info_before_broker};

  # The embedded async backend was built from the connect info before. It is
  # let go of here, before anything of the new connect info is read, and
  # every context tied to its generation is invalidated with it: reading can
  # throw -- a broker, its answer -- and a call that throws must not leave a
  # backend that goes on connecting as before, through the broker this call
  # replaced (karr k293). The next use resolves a backend anew.
  $self->_reset_async_context_owner_token;
  delete $self->{_async_storage_obj};

  if ($self->_is_access_broker_connect_info($info)) {
    my $beside = $self->_access_broker_call_info($info);
    $self->set_access_broker($info->[0], 'write');
    $info = $self->_normalized_access_broker_connect_info($self->access_broker_mode);

    # ADR 0030 addendum (karr k240, k243): the connect call's own settings
    # beside the broker join its answer; one given in both has to agree.
    $info = $self->_merge_access_broker_call_info($info, $beside) if $beside;
  }
  else {
    $self->clear_access_broker;
    if (ref $info eq 'ARRAY') {
      my $given = $info;
      $info = $self->_normalize_connect_info($given);
      $self->_assert_static_connect_info_has_dsn($info, $given);
      $self->_assert_static_connect_attributes_known($info);
    }
  }

  my ($args, $attrs) = $self->_dbi_args_from_info($info);
  my %attrs = %$attrs;

  if (keys %attrs and ref $args->[0] ne 'CODE') {
    carp_unique (
        'You provided explicit AutoCommit => 0 in your connection_info. '
      . 'This is almost universally a bad idea (see the footnotes of '
      . 'DBIO::Storage::DBI for more info). If you still want to '
      . 'do this you can set $ENV{DBIO_UNSAFE_AUTOCOMMIT_OK} to disable '
      . 'this warning.'
    ) if ! $attrs{AutoCommit} and ! $ENV{DBIO_UNSAFE_AUTOCOMMIT_OK};
  }

  # this is the authoritative "always an arrayref" thing fed to DBI->connect
  # OR a single-element coderef-based $dbh factory. With a broker attached
  # nothing of its answer is kept (karr k266): every connection asks the
  # broker again, and _dbi_connect_info derives the answer when it is read.
  $self->_dbi_connect_info($self->access_broker ? undef : $args);

  # ADR 0050: connect_info() is a full reconfiguration, not a merge -- reset
  # every storage option to its default BEFORE applying this call's options,
  # so an option not named here does not go on leaking a prior value (the
  # DBIx::Class fossil: a truthiness-picker that only ever set options that
  # were present, never cleared ones that were absent). Symmetric with the
  # _sql_maker/_sql_maker_opts wipe below. cursor_class is the one exception:
  # it resets to its class default, not undef, since a component_class
  # accessor with no value breaks cursor creation.
  for my $storage_opt ($self->_dbio_storage_option_names) {
    my $accessor = $self->_dbio_storage_option_accessor($storage_opt);
    $self->$accessor(undef);
  }
  $self->cursor_class(ref($self)->cursor_class);

  # extract the individual storage options
  for my $storage_opt (keys %{ $info->{storage_options} }) {
    my $value = $info->{storage_options}{$storage_opt};

    $self->_assert_connection_schema_name($value) if $storage_opt eq 'schema';

    my $accessor = $self->_dbio_storage_option_accessor($storage_opt);
    $self->$accessor($value);
  }

  # ADR 0030: the async execution mode is chosen per connection via
  # { async => 'MODE' } in the connect attributes. Absent => sync (the
  # *_async methods croak). The resolved-backend cache was reset on the way
  # in, so a fresh connect_info re-resolves the mode.
  $self->_async_mode($info->{async_mode});

  # Extract the individual sqlmaker options
  #
  # Kill sql_maker/_sql_maker_opts, so we get a fresh one with only
  #  the new set of options
  $self->_sql_maker(undef);
  $self->_sql_maker_opts({});

  for my $sql_maker_opt (keys %{ $info->{sql_maker_options} }) {
    my $value = $info->{sql_maker_options}{$sql_maker_opt};

    $self->_sql_maker_opts->{$sql_maker_opt} = $value;
  }

  # FIXME - dirty:
  # save attributes in a separate accessor so they are always
  # introspectable, even in case of a CODE $dbhmaker
  $self->_dbio_connect_attributes (\%attrs);

  return $self->_connect_info;
}

# The detach of a DBI storage is DBIO::Storage::DBI::AccessBroker's: it takes
# the embedded async backend along (karr k293); the storage itself holds
# nothing of the broker's answer (karr k266). It is named here as well because
# that mixin stands BEHIND DBIO::Storage in the method resolution order of a
# driver storage class that does not declare c3 -- the first base,
# DBIO::Storage::QueryRewrite, inherits DBIO::Storage, and depth-first that
# comes before the other bases. Such a class (DBIO::PostgreSQL::Storage,
# DBIO::MySQL::Storage) found the bare DBIO::Storage::clear_access_broker
# first, and the mixin's never ran: the backend stayed attached. This class
# comes first in either order.
sub clear_access_broker {
  my $self = shift;
  return $self->DBIO::Storage::DBI::AccessBroker::clear_access_broker(@_);
}

# Same shadowing, same reason: the attach reaches the embedded async backend
# built before it (karr k331).
sub set_access_broker {
  my $self = shift;
  return $self->DBIO::Storage::DBI::AccessBroker::set_access_broker(@_);
}

# Static connect info (no broker) carries its DSN (karr k306): the DSN names
# the driver.
# $info is the normalised form, so a DSN built from a dbname key counts;
# $given is what the caller passed, for the shape the message names -- never a
# value of it. The code reference forms open the connection themselves and
# need no DSN. A broker's answer has its own refusal
# (_normalized_access_broker_connect_info).
sub _assert_static_connect_info_has_dsn {
  my ($self, $info, $given) = @_;

  my $dsn = $info->{arguments}[0];
  return if ref $dsn eq 'CODE';
  return if defined $dsn && length $dsn;

  my $hash  = ref $given->[0] eq 'HASH' ? $given->[0] : undef;
  my $shape = !@$given ? 'no arguments'
            : $hash && !exists $hash->{dsn} && !exists $hash->{dbname}
              ? 'a hash with neither a dsn nor a dbname key'
            : ($hash ? 'a hash' : 'the DBI form') . ' with '
              . (defined $dsn ? 'an empty' : 'an undefined') . ' DSN';

  $self->throw_exception(
    "Connect info without a DSN ($shape). A DBI storage connects to the DSN "
  . 'it is given, never to the one in $ENV{DBI_DSN}: the DSN names the '
  . 'driver. Supply a dsn, or a dbname in the hash form; a code reference '
  . '(dbh_maker) or an AccessBroker needs none.'
  );
}

# Static connect info (no broker) is fully known here, so an attribute that is
# neither a DBIO option (already pulled out by _normalize_connect_info) nor a
# DBI attribute by its name is refused rather than handed to DBI->connect to be
# dropped silently (karr k327). sslmode is let through by name (karr k306).
# Without a DSN to judge by (a dbh_maker / coderef) nothing is checked: the
# code opens the connection and no attribute is applied either way.
sub _assert_static_connect_attributes_known {
  my ($self, $info) = @_;

  my $dsn = $info->{arguments}[0];
  return if ref $dsn eq 'CODE';

  # Judged by the async mode of THIS connect info -- which names are async
  # options depends on it (karr core k397) -- not by the mode the storage held
  # before; connect_info sets the new one only after this check.
  local $self->{_async_mode} = $info->{async_mode};

  my @unknown = grep { $_ ne 'sslmode' }
    $self->_access_broker_unapplied_parameters($info->{attributes}, $dsn);
  return unless @unknown;

  $self->throw_exception(
    'Unknown connect attribute(s) ' . join(', ', map { "'$_'" } @unknown)
  . ' in connect info: neither a DBIO connection option nor a DBI attribute '
  . '(uppercase first letter, private_, dbi_, dbd_, or the prefix of the DBD '
  . 'the DSN names), so DBI->connect would silently ignore '
  . (@unknown > 1 ? 'them' : 'it') . '. A parameter of the database client '
  . 'belongs in the DSN.'
  . $self->_driver_switch_hint(@unknown)
  );
}

# The sentence a refusal gets when driver_strict or driver_warnings stand among
# the refused keys: they are accessors of the schema, never connect attributes.
# Empty otherwise; no value goes into it.
sub _driver_switch_hint {
  my ($self, @names) = @_;

  my @switches = grep { $_ eq 'driver_strict' or $_ eq 'driver_warnings' } @names
    or return '';

  return ' ' . join(' and ', @switches)
    . (@switches > 1
        ? ' are schema accessors, not connect attributes: set them on the '
        : ' is a schema accessor, not a connect attribute: set it on the ')
    . 'schema class or a connected schema, e.g. '
    . join(' and ', map { '$schema->' . $_ . ($_ eq 'driver_strict' ? '(1)' : '(0)') } @switches)
    . '.';
}

# The connect info the storage holds, for the stack trace of an exception to
# mask (karr k311): what connect_info stored, and nothing else. It never asks
# a broker -- a storage with one attached holds no answer of it (karr k266), so
# there is none -- and never connects.
sub _held_connect_info {
  my $self = shift;

  return undef if $self->access_broker;

  my $info = $self->{_dbi_connect_info};
  return ref $info eq 'ARRAY' ? $info : undef;
}

sub _dbi_connect_info {
  my $self = shift;

  return $self->{_dbi_connect_info} = $_[0]
    if @_;

  # With a broker attached the storage holds nothing of its answer (karr
  # k266): what is read is the answer of this moment, derived, not kept.
  return ($self->_access_broker_dbi_args($self->access_broker_mode))[0]
    if $self->access_broker;

  # What connect_info stored, and nothing in its place: a storage without a
  # DSN has nothing to connect from, whatever $ENV{DBI_DSN} names (karr k306)
  return $self->{_dbi_connect_info} || [];
}

# A normalised connect info as the arguments of DBI->connect and the full
# attribute set (_dbio_connect_attributes): the one place both are built, for
# connect_info, for every connection and for the read of _dbi_connect_info of
# a storage with a broker.
sub _dbi_args_from_info {
  my ($self, $info) = @_;

  my %attrs = (
    %{ $self->_default_dbi_connect_attributes || {} },
    %{ $info->{attributes} || {} },
  );

  my @args = @{ $info->{arguments} };

  # _dbio_connect_attributes keeps the full set (including DBIO-private
  # keys like ignore_version) for introspection by upper layers. The
  # arguments must only contain attrs that DBI/DBD understands: ignore_version
  # is consumed by the DeploymentHandler version-storage component
  # (DBIO::DeploymentHandler::VersionStorage::Standard::Component), not by
  # the DBD.
  my %dbi_attrs = %attrs;
  delete @dbi_attrs{qw( ignore_version )};

  # An error text carries no bind value (ADR 0075): DBI appends the values
  # itself when ShowErrorStatement is on, so it is off whatever connect_info
  # says; _dbi_handle_error writes the statement and the number of binds.
  $attrs{ShowErrorStatement} = $dbi_attrs{ShowErrorStatement} = 0;

  push @args, \%dbi_attrs if keys %dbi_attrs and ref $args[0] ne 'CODE';

  return (\@args, \%attrs);
}


sub _normalize_connect_info {
  my ($self, $info_arg) = @_;
  my %info;

  my @args = @$info_arg;  # take a shallow copy for further mutilation

  # combine/pre-parse arguments depending on invocation style

  my %attrs;
  if (ref $args[0] eq 'CODE') {     # coderef with optional \%extra_attributes
    %attrs = %{ $args[1] || {} };
    @args = $args[0];
  }
  elsif (ref $args[0] eq 'HASH') { # single hashref (i.e. Catalyst config)
    %attrs = %{$args[0]};
    @args = ();
    if (my $code = delete $attrs{dbh_maker}) {
      @args = $code;

      my @ignored = grep { delete $attrs{$_} } (qw/dsn user password/);
      if (@ignored) {
        carp sprintf (
            'Attribute(s) %s in connect_info were ignored, as they can not be applied '
          . "to the result of 'dbh_maker'",

          join (', ', map { "'$_'" } (@ignored) ),
        );
      }
    }
    else {
      # A hash of connection parameters without a dsn (e.g. from a
      # hashref-shaped AccessBroker such as DBIO::AccessBroker::Static):
      # build the dsn for this storage's driver, unless dbname already is one.
      if (!exists $attrs{dsn} && exists $attrs{dbname}) {
        $attrs{dsn} = $self->_dsn_from_connect_params(\%attrs);
      }
      # host and port without either name a server and no database: there is
      # no DSN to build them into, and they are no DBI attributes (karr k267)
      elsif (!exists $attrs{dsn}
        and my @parts = grep { exists $attrs{$_} } qw(host port)
      ) {
        $self->throw_exception(
          'Connect info gives ' . join(' and ', map { "'$_'" } @parts)
        . ' but neither a dsn nor a dbname: there is no DSN to connect to, '
        . 'and without one a host or port is not passed on as a DBI '
        . 'attribute. Supply a dsn, or a dbname.'
        );
      }
      @args = delete @attrs{qw/dsn user password/};
    }
  }
  else {                # otherwise assume dsn/user/password + \%attrs + \%extra_attrs
    %attrs = (
      % { $args[3] || {} },
      % { $args[4] || {} },
    );
    @args = @args[0,1,2];
  }

  # A user or password not given is the empty string: DBI reads $ENV{DBI_USER}
  # and $ENV{DBI_PASS} for an undef, and no environment variable stands in for
  # a credential (karr k392, like the DSN: k306, k340).
  if (ref $args[0] ne 'CODE' and @args) {
    $args[$_] //= '' for 1, 2;
  }

  $info{arguments} = \@args;

  # Ask the live storage, not a compile-time snapshot of the base
  # class, so a driver that declares its own storage option gets it routed to
  # the storage instead of leaking into DBI->connect. Symmetric to the
  # sql_maker split below and to DBIO::Storage::Async::connect_info, which both
  # already read their name list off $self.
  # cursor_class is appended instead of living in the list because the list
  # doubles as the 'simple' accessor registration above, and cursor_class
  # carries a component_class accessor of its own (DBIO::Storage).
  my @storage_opts = grep exists $attrs{$_},
    $self->_dbio_storage_option_names, 'cursor_class';

  @{ $info{storage_options} }{@storage_opts} =
    delete @attrs{@storage_opts} if @storage_opts;

  # ADR 0030: the async mode is a DBIO-private connect attribute, not a DBI one.
  # Pull it out of %attrs (so it never reaches DBI->connect) and surface it
  # separately for connect_info to set on the instance.
  $info{async_mode} = delete $attrs{async}
    if exists $attrs{async};

  # The async options (pool_size, acquire_timeout, max_waiters, txn_timeout,
  # and what the mode's backend declares) are the embedded async backend's: it
  # reads them off the raw _connect_info. They mean nothing to a DBD and a
  # strict one (DBD::MariaDB) rejects them, so on an async connection they stay
  # out of THIS owner's own DBI->connect (karr k211, k397). A sync connection
  # has no backend to consume them, so there they stay DBI attributes and the
  # DBD's verdict stands.
  delete @attrs{ $self->_async_option_names($info{async_mode}) }
    if defined $info{async_mode};

  my @sql_maker_opts = grep exists $attrs{$_},
    $self->_dbio_sql_maker_option_names;

  @{ $info{sql_maker_options} }{@sql_maker_opts} =
    delete @attrs{@sql_maker_opts} if @sql_maker_opts;

  $info{attributes} = \%attrs if %attrs;

  return \%info;
}

# The dsn for a hash of connection parameters that has none -- dbname, host
# and port, as DBIO::AccessBroker::Static (or a HostBound view over it)
# answers them. Everything around the DSN's form is core's and happens here,
# once, whatever the driver (ADR 0057): the three keys are removed from the
# hash, so they cannot reach DBI->connect as attributes; empty ones are
# dropped; a dbname that is a whole DSN is the DSN; the driver is the one the
# storage class is registered for, which the driver component pins before any
# connect -- a storage that is not a driver's (the generic class has none)
# refuses rather than guess; a value that would split a
# DSN refuses. Only the form itself is the driver's: _connect_params_dsn.
sub _dsn_from_connect_params {
  my ($self, $params) = @_;

  my @keys = qw(dbname host port);
  my %part;
  @part{@keys} = delete @{$params}{@keys};

  # An empty dbname names no database (karr k340); one not given is undef.
  $self->throw_exception(
    'Cannot build a DSN from an empty dbname: it names no database. Give the '
  . 'database name, or leave dbname out (undef) to build the DSN from host '
  . 'and port alone.'
  ) if defined $part{dbname} && !length $part{dbname};

  delete @part{ grep { !defined $part{$_} || !length $part{$_} } @keys };

  # A dbname that is a whole DSN is taken as the DSN. Host and port cannot go
  # into it -- where they would go is the DSN form's business -- and as DBI
  # attributes they would be lost, a HostBound view's host among them.
  if (defined $part{dbname} && $part{dbname} =~ /^dbi:/i) {
    my @beside = grep { exists $part{$_} } qw(host port);
    $self->throw_exception(
      'Connection parameter(s) ' . join(', ', map { "'$_'" } @beside)
    . ' given beside a dbname that is a whole DSN: they cannot be put into '
    . 'it. Give them inside the DSN, or give dbname as a database name.'
    ) if @beside;
    return $part{dbname};
  }

  my @drivers = $self->_registered_dbd_drivers;
  $self->throw_exception(
    'Cannot build a DSN from the connection parameters (dbname, host, port) '
  . 'in this connect info: they name no DBI driver, and storage class '
  . ref($self) . ' is ' . (@drivers ? 'registered for ' . join(', ', @drivers)
                                    : 'not registered for any')
  . ' DBD driver. Load the driver component in the schema class (e.g. '
  . "__PACKAGE__->load_components('PostgreSQL')) so the storage is the "
  . "driver's own, or supply a dsn instead."
  ) unless @drivers == 1;

  for my $key (grep { exists $part{$_} } @keys) {
    $self->throw_exception(
      "Cannot build a DSN from the connection parameter '$key': its value "
    . "contains ';', which separates DSN parts. Supply a dsn instead."
    ) if $part{$key} =~ /;/;
  }

  return $self->_connect_params_dsn($drivers[0], \%part);
}


sub _connect_params_dsn {
  my ($self, $driver, $params) = @_;
  return "dbi:$driver:" . join ';',
    map { "$_=$params->{$_}" } grep { exists $params->{$_} } qw(dbname host port);
}


my %_SERVER_NAMING_KEY = map { $_ => 1 }
  qw(hostaddr hostname server servername address addr dsn);

sub _bind_host_into_dsn {
  my ($self, $driver, $dsn, $host, $port) = @_;

  return (undef, 'a DSN without a dbi:Driver: prefix')
    unless defined $dsn and $dsn =~ /^dbi:[^:]*:(.*)\z/is;
  my $rest = $1;

  for my $token (grep { length } split /;/, $rest) {
    return (undef, 'a part without key=value form (Easy Connect, TNS '
      . 'descriptor, data source name or positional DSN)')
      unless $token =~ /^(\w+)=(.*)\z/s;
    my ($key, $value) = ($1, $2);
    my $lkey = lc $key;

    return (undef, "the key '$key' naming the server")
      if $_SERVER_NAMING_KEY{$lkey};

    return (undef, "the key '$key' with a host: prefix in its value")
      if ($lkey eq 'db' or $lkey eq 'dbname' or $lkey eq 'database')
        and $value =~ m{^[^:/\\]+(?:/\d+)?:}
        and $value !~ m{^[A-Za-z]:[\\/]};
  }

  $dsn = _dsn_set_token($dsn, host => $host);
  $dsn = _dsn_set_token($dsn, port => $port) if defined $port;
  return $dsn;
}

# Replace an existing "key=..." token in place, else splice one in front of
# the attribute section after "dbi:Driver:".
sub _dsn_set_token {
  my ($dsn, $key, $val) = @_;

  return $dsn if $dsn =~ s/(^|[:;])\Q$key\E=[^;]*/$1$key=$val/i;

  if ($dsn =~ /^(dbi:[^:]*:)(.*)$/is) {
    my ($prefix, $rest) = ($1, $2);
    return $prefix . (length $rest ? "$key=$val;$rest" : "$key=$val");
  }

  return $dsn;
}


sub _dbd_attribute_prefixes {
  my ($self, $driver) = @_;
  return unless defined $driver;

  # not before a broker's answer needs it: DBI.pm is otherwise loaded at the
  # first connect (see _extract_driver_from_connect_info)
  require DBI;
  return DBI->driver_prefix("DBD::$driver");
}

sub _default_dbi_connect_attributes () {
  +{
    AutoCommit => 1,
    PrintError => 0,
    RaiseError => 1,
    ShowErrorStatement => 0,
  };
}



sub _parse_connect_do {
  my ($self, $type) = @_;

  my $val = $self->$type;
  return () if not defined $val;

  my @res;

  if (not ref($val)) {
    push @res, [ 'do_sql', $val ];
  } elsif (ref($val) eq 'CODE') {
    push @res, $val;
  } elsif (ref($val) eq 'ARRAY') {
    push @res, map { [ 'do_sql', $_ ] } @$val;
  } else {
    $self->throw_exception("Invalid type for $type: ".ref($val));
  }

  return \@res;
}


sub dbh_do {
  my $self = shift;
  my $run_target = shift; # either a coderef or a method name

  # short circuit when we know there is no need for a runner
  #
  # FIXME - assumption may be wrong
  # the rationale for the txn_depth check is that if this block is a part
  # of a larger transaction, everything up to that point is screwed anyway
  return $self->$run_target($self->_get_dbh, @_)
    if $self->{_in_do_block} or $self->transaction_depth;

  # take a ref instead of a copy, to preserve @_ aliasing
  # semantics within the coderef, but only if needed
  # (pseudoforking doesn't like this trick much)
  my $args = @_ ? \@_ : [];

  DBIO::Storage::BlockRunner->new(
    storage => $self,
    wrap_txn => 0,
    retry_handler => sub {
      $_[0]->failed_attempt_count == 1
        and
      ! $_[0]->storage->connected
    },
  )->run(sub {
    $self->$run_target ($self->_get_dbh, @$args )
  });
}

sub txn_do {
  $_[0]->_get_dbh; # connects or reconnects on pid change, necessary to grab correct txn_depth
  shift->next::method(@_);
}


sub register_async_mode {
  my ($class, $mode, $backend_class) = @_;
  $_async_mode_registry{$class}{$mode} = $backend_class;
}

# Ownership of a pinned async context is scoped to one backend/pool generation.
# The owner mirrors the current backend's opaque token; no class, DSN or schema
# identity participates in the comparison.
sub _reset_async_context_owner_token {
  my ($self) = @_;
  $self->_async_context_owner_token(undef);
  return;
}

# A detached old backend may rotate while shutting down. Adopt its token only
# while it is still the backend cached by this concrete sync storage object.
sub _adopt_async_context_owner_token {
  my ($self, $backend, $token) = @_;
  my $current = $self->{_async_storage_obj} or return;
  return unless refaddr($current) == refaddr($backend);
  $self->_async_context_owner_token($token);
  return;
}

# The one ownership comparison used by with_context, ORM dispatch and direct
# Core context entry points. Context-shaped external objects without Core's
# token evidence fail closed.
#
# One context carries no token and is still this storage's own: in the
# 'immediate' mode txn_do_async hands its coderef the storage itself (ADR
# 0055), so there the proof is identity -- the very object asked, and only
# while its mode is literally 'immediate' (karr k282). Another storage, a
# storage with no async mode and a storage with a real backend (whose context
# is a TransactionContext carrying the token) all fall through to the token
# comparison below and are refused there as before.
sub _assert_async_context_owner {
  my ($self, $ctx) = @_;

  return $ctx
    if blessed($ctx)
    and refaddr($ctx) == refaddr($self)
    and ( $self->_async_mode // '' ) eq 'immediate';

  # The pooled backend itself carries the owner token by construction and
  # answers the six *_async methods, but it is no pinned context: a statement
  # sent through it takes whatever pool connection is free. A context comes
  # out of txn_do_async or a pipeline coderef (karr k331).
  $self->throw_exception(
    'the pooled async backend is not a pinned context: with_context takes '
  . 'the context handed to a txn_do_async or pipeline coderef'
  ) if blessed($ctx)
    and ( $ctx->isa('DBIO::Storage::Async')
          or ( ($self->{_async_storage_obj} // 0)
               and refaddr($ctx) == refaddr($self->{_async_storage_obj}) ) );

  $self->throw_exception('async context ownership cannot be proven')
    unless blessed($ctx) && $ctx->can('_context_owner_token');

  my $ours   = $self->_async_context_owner_token;
  my $theirs = $ctx->_context_owner_token;
  $self->throw_exception(
    'async context does not belong to this storage generation'
  ) unless $ours && $theirs && refaddr($ours) == refaddr($theirs);
  return $ctx;
}

# The storage as the 'immediate' mode's transaction context (ADR 0055) answers
# the two things a ResultSet, Row or ResultSetColumn bound to it asks beyond
# the six *_async methods (ADR 0045, karr k282).
#
# _context_active: true while an 'immediate' txn_do_async is running on this
# storage -- from before its coderef is called until it has returned, which is
# when the COMMIT or ROLLBACK goes out. A bound object used outside of that is
# refused ('no longer active') like one held past a real backend's
# transaction. There is one connection and no pool here, so "a transaction of
# this kind is open" is all there is to know: an object bound in one such
# transaction and used inside a later one runs in the later one.
sub _context_active { $_[0]->{_immediate_txn_failures} ? 1 : 0 }

# _query_async: the raw-SQL member of the surface (results_exist_async uses
# it). With a real backend it is the backend's own pooled seam; in the
# 'immediate' mode the rendered statement runs in-process and resolves with
# its rows, the form the seam resolves a SELECT with.
sub _query_async { shift->_run_async( _query => @_ ) }

# The class whose linearised ISA the async transport/mode resolution walks.
# Async transport (mode) resolution is a property of the DRIVER, never of the
# storage LAYERS composed on top of it (ADR 0032): a composed instance's class
# (DBIO::Storage::Composed::<layer>__<driver>) has the sync layer packages
# more-specific than the driver in its MRO, and a sync layer's plain ::Async
# mixin (the WP2 async-mirror target -- NOT a DBIO::Storage::Async transport)
# would otherwise be probed before the driver's real transport adapter. So we
# resolve the walk against the composition BASE (the concrete driver storage),
# not ref($self). A non-composed instance has no registry entry -> base is just
# ref($self), i.e. behaviour identical to before composition existed. Class-
# method callers (e.g. DBIO::Storage::DBI->_resolve_async_mode_class) keep the
# ref($self) || $self fallback.
sub _async_resolution_class {
  my $self  = shift;
  my $class = ref($self) || $self;
  my $comp  = DBIO::Storage::Composed->composition_of($class);
  return $comp ? $comp->{base} : $class;
}

# Walk the instance's MRO and return the backend class registered for $mode
# (driver registrations shadow/extend generic ones), or undef if no class in
# the linearised ISA registered that mode. With exclude => $pkg, that one class
# is skipped in the walk -- used by future_io to honour an explicit
# per-driver registration while ignoring any GENERIC base-class one. The walk
# is over the composition BASE (see _async_resolution_class), so storage layers
# never shadow the driver's transport registrations.
sub _resolve_async_mode_class {
  my ($self, $mode, %opt) = @_;
  my $exclude = $opt{exclude};
  for my $pkg (@{ mro::get_linear_isa($self->_async_resolution_class) }) {
    next if defined $exclude and $pkg eq $exclude;
    return $_async_mode_registry{$pkg}{$mode}
      if exists $_async_mode_registry{$pkg}
      && exists $_async_mode_registry{$pkg}{$mode};
  }
  return undef;
}

# Resolve an OPTIONAL async class candidate to the three-way outcome that
# load_optional_class alone cannot express: LOADED / genuinely-ABSENT /
# PRESENT-but-UNLOADABLE. load_optional_class returns 0 only when the
# candidate's OWN .pm is missing from @INC; when the file EXISTS but its
# compilation fails -- e.g. its own dependency is not installed (the driver
# ships <pkg>::Async, but the separate async dist providing its base class,
# such as DBIO::Async, is absent), or a genuine bug in the adapter -- it
# instead THROWS the raw compile error. We reproduce the distinction and, on
# the unloadable case, fail loud with a clear, correctly-attributed message
# (ADR 0030 §3: a broken adapter fails loud, never silently degrading to a
# parent's). Naming the missing MODULE is only claimed when Perl actually
# reports one -- a syntax error in an installed adapter is surfaced honestly,
# never misreported as a missing dependency.
# Returns 1 if loaded, 0 if genuinely absent; throws otherwise.
sub _try_load_async_class {
  my ($self, $candidate, $what) = @_;
  $what //= 'async class';

  my $loaded = eval { $self->load_optional_class($candidate) };
  return $loaded if defined $loaded;   # 1 = loaded, 0 = genuinely absent

  my $err = $@;   # load_optional_class threw: file exists, compilation failed

  # A not-installed dependency shows up in one of two shapes: the require's
  # own "Can't locate X.pm in @INC", or use base/parent's "Base class
  # package "X" is empty" (base.pm suppresses the inner Can't-locate and
  # reports the empty base instead).
  my $missing;
  if ($err =~ /\bCan't locate (\S+?)\.pm in \@INC/) {
    ($missing = $1) =~ s{/}{::}g;
  }
  elsif ($err =~ /\bBase class package "([\w:]+)" is empty/) {
    $missing = $1;
  }

  $self->throw_exception(
    (defined $missing && $missing ne $candidate)
      ? "$what '$candidate' is present but cannot be loaded -- it requires "
      . "'$missing', which is not installed. Install the distribution that "
      . "provides '$missing' and retry.\n\nUnderlying error: $err"
      : "$what '$candidate' is present but failed to load.\n\n"
      . "Underlying error: $err"
  );
}

# Resolve (and cache) the embedded async backend for this instance's chosen
# mode, or undef. undef means one of two very different things, disambiguated
# by _async_mode: no mode chosen (sync -- *_async croaks) vs. the 'immediate'
# in-process mode (no event loop, no backend -- *_async degrades). A bad/absent
# mode, or a loaded wrong-type target for any mode other than literal
# 'immediate', croaks loudly here (ADR 0030: explicit or it croaks). The
# resolved value is cached in {_async_storage_obj}; disconnect/connect_info
# delete the slot.
sub _async_storage {
  my $self = shift;

  return $self->{_async_storage_obj}
    if exists $self->{_async_storage_obj};

  my $mode = $self->_async_mode;

  # No async mode chosen -> sync instance, no backend. The *_async dispatch
  # turns this into a loud croak; we never touch the driver/registry here.
  return $self->{_async_storage_obj} = undef
    if !defined $mode;

  # The native 'ev' mapping is declared on the concrete driver storage class,
  # and future_io's adapter is derived by convention FROM that class (below);
  # both only work once the storage is reblessed into its driver storage. Force
  # driver determination so the registry walk sees the driver's registrations
  # and ref($self) is the concrete driver storage class.
  $self->_determine_driver;

  my $backend_class = $self->_resolve_async_backend_class($mode);
  return $self->_embed_async_backend($mode, $backend_class);
}

# The backend class an async mode resolves to, or a throw that names why the
# mode is not available. Split from _async_storage so that the class can be
# asked for on its own: the connect options a backend declares are known from
# it (_async_option_names, karr core k397).
sub _resolve_async_backend_class {
  my ($self, $mode) = @_;

  my $backend_class;

  if ($mode eq 'future_io') {
    # --- ADR 0030 refinement: future_io class-by-CONVENTION ----------------
    # future_io's transport adapter is discovered off the concrete,
    # driver-determined storage class: <pkg> . '::Async' -- parallel to the
    # sync driver storage (DBIO::X::Storage -> DBIO::X::Storage::Async). Because
    # a storage is always driver-specific, every driver's adapter is thus
    # deterministic with no registry entry at all. Precedence:
    #   1. An EXPLICIT register_async_mode(future_io => ...) on a concrete
    #      driver storage class still wins, as a backward-compatible override.
    #      A GENERIC base-class (DBIO::Storage::DBI) registration is deliberately
    #      NOT honoured -- so merely loading an async dist can no longer globally
    #      "claim" future_io for every driver and then die deep in an abstract
    #      base's _submit_query seam. That is exactly what this replaces.
    #   2. Otherwise WALK the linearised ISA (ADR 0030 second refinement),
    #      most-specific first, probing <pkg>::Async at each rung and
    #      STOPPING strictly BEFORE the generic DBIO::Storage::DBI base (a
    #      generic ::Async claiming every driver is the hole rule 1 closes; the
    #      walk must not reopen it). The first candidate that LOADS wins; one
    #      that loads but is NOT a DBIO::Storage::Async croaks AT ONCE naming
    #      it -- a broken extension adapter fails loud, never silently degrading
    #      to a parent's adapter. This mirrors the registry walk
    #      (_resolve_async_mode_class) so extension storage_type subclasses
    #      (AGE/PostGIS) inherit the nearest parent adapter, just like sync
    #      storage inheritance.
    # The MODE stays explicit (ADR 0030: the caller still writes
    # { async => 'future_io' }); only the CLASS is resolved by convention. This
    # is NOT the banned ADR 0029 mode auto-fallback.
    $backend_class = $self->_resolve_async_mode_class($mode, exclude => __PACKAGE__);

    if (defined $backend_class) {
      $self->throw_exception(
        "async mode '$mode' is not available -- install $backend_class"
      ) unless $self->load_optional_class($backend_class);
    }
    else {
      # Walk the composition BASE, not ref($self): the transport adapter is a
      # property of the concrete DRIVER, and a composed instance's storage
      # layers (with their plain ::Async mixins) sit more-specific than the
      # driver in ref($self)'s MRO -- probing those would find a layer's async
      # mixin (not a DBIO::Storage::Async) before the driver's real adapter and
      # croak. For a non-composed instance the base IS ref($self).
      my $class = $self->_async_resolution_class;
      my @tried;
      for my $pkg (@{ mro::get_linear_isa($class) }) {
        last if $pkg eq __PACKAGE__;   # stop strictly BEFORE the generic base
        my $adapter = $pkg . '::Async';
        push @tried, $adapter;
        # Genuinely absent -> keep walking; present-but-unloadable (its own
        # async dependency missing, or broken) -> fail loud with the cause.
        next unless $self->_try_load_async_class($adapter, 'future_io adapter');

        # Loaded -- it MUST be a proper backend or we fail loud, naming it;
        # never silently skip past it to a parent's adapter (ADR 0030 §3).
        $self->throw_exception(
          "driver $class does not support future_io -- "
          . "$adapter loaded but is not a DBIO::Storage::Async"
        ) unless $adapter->isa('DBIO::Storage::Async');

        $backend_class = $adapter;
        last;
      }

      $self->throw_exception(
        "driver $class does not support future_io -- no ${class}::Async adapter "
        . "found on it or any parent (tried: @{[ join ', ', @tried ]})"
      ) unless defined $backend_class;
    }
  }
  else {
    $backend_class = $self->_resolve_async_mode_class($mode);

    $self->throw_exception(
      "async mode '$mode' is not available -- no driver or add-on registers it"
    ) if !defined $backend_class;

    $self->throw_exception(
      "async mode '$mode' is not available -- install $backend_class"
    ) unless $self->load_optional_class($backend_class);
  }

  return $backend_class;
}

# The names of the async options a connection with async mode $mode takes: the
# core's (DBIO::Storage::_core_async_option_names) and those the mode's backend
# class declares (DBIO::Storage::Async->async_option_names). The backend class
# is asked without connecting and without a driver determination; a mode whose
# backend cannot be resolved or loaded contributes the core names alone -- the
# mode's own error is thrown at its first use, as before (karr core k397).
sub _async_option_names {
  my ($self, $mode) = @_;

  my @names = $self->_core_async_option_names;
  return @names unless defined $mode;

  my $backend_class;
  { local $@; $backend_class = eval { $self->_resolve_async_backend_class($mode) }; }
  push @names, $backend_class->async_option_names
    if defined $backend_class && !ref $backend_class
    && $backend_class->can('async_option_names');

  my %seen;
  return grep { !$seen{$_}++ } @names;
}

# The embedded backend for $mode, built from the class it resolved to and this
# storage's connect info, cached in {_async_storage_obj}.
sub _embed_async_backend {
  my ($self, $mode, $backend_class) = @_;

  # Only the literal 'immediate' mode may resolve to its Future class rather
  # than a DBIO::Storage::Async backend. A wrong-type registry target is a
  # configuration error, never a silent synchronous fallback.
  unless ($backend_class->isa('DBIO::Storage::Async')) {
    return $self->{_async_storage_obj} = undef
      if $mode eq 'immediate';
    $self->throw_exception(
      "async mode '$mode' resolved to $backend_class, which is not a "
      . 'DBIO::Storage::Async backend'
    );
  }

  # The transport itself, before any async layer is composed over it.
  my $transport_class = $backend_class;

  # --- Async mirror composition (ADR 0032). The transport class is now
  # resolved; mirror each registered SYNC storage layer onto its ASYNC
  # counterpart and compose them over the transport, so an extension's async
  # behaviour rides every transport just as its sync behaviour rides every
  # driver (one behaviour, one transport). Per sync layer L, in registration
  # order:
  #   * L->async_layer_class($mode) if L defines it -- a package (must load, or
  #     croak) or undef, which is the STATED opt-out: L is deliberately
  #     sync-only for $mode and is skipped without any load attempt (ADR 0032
  #     amendment 2026-09-25, karr k159);
  #   * otherwise (method NOT defined -- silent) the convention sibling
  #     "${L}::Async" via load_optional_class;
  #   * silent and absent -> REFUSAL (karr k159 step 3, ADR 0032 amendment
  #     2026-09-25): a layer that neither states an answer nor ships the
  #     convention sibling croaks, naming the layer and both ways out. There
  #     is no silent path left in the mirror step.
  # This does NOT touch the transport resolution above (ADR 0030: the mode
  # stays explicit; only the layer CLASSES are added by composition).
  # A storage with no live schema (weakened ref already gone) can carry no
  # registered layers, so there is nothing to mirror.
  my $schema = $self->schema;
  my @async_layers;
  for my $sync_layer ($schema ? @{ $schema->storage_layers } : ()) {
    my $async_layer;

    if ($sync_layer->can('async_layer_class')) {
      # Defining the method IS the statement (stated vs. silent, as for
      # required_transport_capabilities below). Its undef return therefore
      # means "deliberately no async layer for this mode" -- NOT "use the
      # convention": undef here is not a forgotten return. The convention
      # sibling is neither probed nor loaded, even if one exists; the
      # layer's own declaration wins. Note can() sees an inherited
      # declaration, so a subclass of a declaring layer inherits its answer.
      $async_layer = $sync_layer->async_layer_class($mode);
      next unless defined $async_layer;

      # An explicitly declared class MUST load: genuinely absent -> the
      # "could not be loaded" croak; present-but-unloadable -> _try_load's
      # cause-naming croak (never a raw compile stack).
      $self->throw_exception(
        "async layer class '$async_layer' for storage layer '$sync_layer' "
      . "(async mode '$mode') could not be loaded"
      ) unless $self->_try_load_async_class(
        $async_layer, "async layer class for storage layer '$sync_layer'"
      );
    }
    else {
      my $candidate = "${sync_layer}::Async";
      # Silent layer -> convention sibling. Present-but-unloadable -> fail
      # loud naming the cause, never a silent feature loss nor a raw compile
      # stack. Genuinely absent -> REFUSAL (karr k159 step 3, ADR 0032
      # amendment 2026-09-25): a typo in a mirror's package name and a
      # deliberately sync-only extension used to end in the same silent
      # skip. Now the layer must say which it is.
      $self->throw_exception(
        "storage layer '$sync_layer' has no async counterpart for async mode "
      . "'$mode': it does not define async_layer_class and no convention "
      . "sibling '$candidate' could be found. Either declare the layer "
      . "deliberately sync-only -- sub async_layer_class { undef } in "
      . "$sync_layer -- or ship the async mirror as '$candidate'. "
      . "(ADR 0032)"
      ) unless $self->_try_load_async_class($candidate, 'async layer');
      $async_layer = $candidate;
    }

    push @async_layers, $async_layer if defined $async_layer;
  }

  if (@async_layers) {
    # Capability gate: an async layer may only compose over a transport that
    # provides every capability it declares as required. A shortfall croaks
    # naming the layer, the missing capabilities and the transport -- a
    # transport gap becomes that transport's ticket, never a silent feature loss.
    #
    # The gate used to protect by DECLARATION, not by SEAM. A layer
    # that declared a requirement and did not find it was stopped, but a layer
    # that declared NOTHING composed onto any transport without a word --
    # including one that offers no query seam to wrap, where the layer would
    # load, compose and then quietly do nothing (the very silent feature loss
    # ADR 0032 section 5 exists to prevent). So a missing declaration is now
    # read as "needs the DEFAULT SEAM": the layer is taken to require
    # _query_async, and a transport that does not own the query path refuses
    # it. "Says nothing" is thus the safe case, not the unchecked one, and the
    # hole closes for every transport rather than only for the forked one.
    #
    # A transport OFFERS the seam iff it actually overrides the abstract
    # _query_async stub on DBIO::Storage::Async. Model A backends (DBIO::Forked)
    # override the six *_async entry points directly and run the driver's
    # ordinary sync CRUD elsewhere, so they inherit the stub and have no seam.
    my %have = map { $_ => 1 } $backend_class->transport_capabilities;
    my $abstract_seam = DBIO::Storage::Async->can('_query_async');
    my $backend_seam  = $backend_class->can('_query_async');
    my $has_seam      = $backend_seam
      && (!$abstract_seam || $backend_seam != $abstract_seam);

    for my $async_layer (@async_layers) {
      if (!$async_layer->can('required_transport_capabilities')) {
        next if $has_seam;
        $self->throw_exception(
          "async layer '$async_layer' declares no "
        . "required_transport_capabilities, so it is taken to require the "
        . "default async query seam '_query_async' -- and transport "
        . "'$backend_class' does not provide that seam (it does not override "
        . "DBIO::Storage::Async::_query_async, so it does not own the query "
        . "path a layer wraps; the layer would compose and then do nothing). "
        . "Give '$async_layer' a required_transport_capabilities method "
        . "declaring what it actually needs from a transport -- an explicit "
        . "empty list if it genuinely needs nothing beyond what any transport "
        . "gives -- or choose another async mode whose transport owns the "
        . "query path"
        );
      }

      # Names core reads itself never count as a layer capability, whatever
      # the transport declares (karr k268).
      my %core_read = map { $_ => 1 } DBIO::Storage::Async->_core_read_capabilities;
      my @required  = $async_layer->required_transport_capabilities;
      my @core_asked = grep { $core_read{$_} } @required;
      if (@core_asked) {
        $self->throw_exception(
          "async layer '$async_layer' requires transport "
        . (@core_asked == 1 ? 'capability' : 'capabilities') . " '"
        . join("', '", @core_asked) . "' of transport '$backend_class', "
        . "which is read by core, not by layers: it describes how the "
        . "transport takes connect options, not a feature a layer can build "
        . "on -- drop it from required_transport_capabilities"
        );
      }
      my @missing = grep { !$have{$_} } @required;
      next unless @missing;
      $self->throw_exception(
        "async layer '$async_layer' requires transport "
      . (@missing == 1 ? 'capability' : 'capabilities') . " '"
      . join("', '", @missing) . "' which transport '$backend_class' does not "
      . "provide -- upgrade the transport '$backend_class' (or its "
      . "distribution) or choose another async mode"
      );
    }

    $backend_class =
      DBIO::Storage::Composed->compose($backend_class, \@async_layers);
  }

  # The backend is handed this storage's connect info as given, as with a DSN
  # -- except beside a broker (ADR 0030 addenda, karr k240/k243). Most of what
  # may stand there is this owner's to apply (the mode, storage options,
  # SQL maker options); pooled connections get the connection actions from
  # the owner (ADR 0049). So the backend gets the broker alone -- the form
  # every backend takes a broker in -- unless the hash holds settings a
  # backend applies itself (DBD attributes, pool_size). Those go only to a
  # transport that declares it takes them; any other would open every pooled
  # connection without them while this one has them, so that throws.
  my $connect_info = $self->_connect_info;
  if ($self->_is_access_broker_connect_info($connect_info)) {
    # A broker detached from this storage (clear_access_broker) opens nothing
    # any more (karr k266) -- not through a backend built only now either,
    # which would attach it again and ask it (karr k293).
    $self->throw_exception(
      "async mode '$mode': the AccessBroker this storage was connected "
    . 'through has been detached, so there is nothing to connect an async '
    . 'backend from. Give the storage connect info again.'
    ) unless $self->access_broker;

    if (my @for_backend = $self->_access_broker_backend_settings($connect_info)) {
      $self->throw_exception(
        "async mode '$mode': transport $transport_class does not take "
      . 'connection settings beside an AccessBroker (it does not declare '
      . "'broker_connect_options' among its transport_capabilities), so "
      . join(', ', @for_backend) . ' would reach this connection but none of '
      . 'its pooled ones. Leave them out for this mode, or use a transport '
      . 'that declares it.'
      ) unless $transport_class->_takes_broker_connect_options;
    }
    else {
      # The async options beside the broker (acquire_timeout, ...) are the
      # backend's own, with no transport capability to declare (karr k397).
      my $async_options = $self->_access_broker_async_options($connect_info);
      $connect_info = %$async_options
        ? [ $connect_info->[0], $async_options ]
        : [ $connect_info->[0] ];
    }
  }

  # Build the embedded backend -- the mechanism introduced by the withdrawn
  # ADR 0028 and kept by ADR 0030, which moved only the CHOICE of backend from
  # a per-class default to the connect call: ->new($schema) fed this storage's
  # DBI-form connect_info.
  my $async = $backend_class->new($self->schema);
  $async->connect_info($connect_info);

  # Give the async backend a weak back-reference to THIS owning sync
  # storage, so its pool can resolve on_connect_call/on_connect_do (and their
  # connect_call_* methods) on the class that actually defines them, and replay
  # them against each freshly-spawned pool connection. Mirror this backend's
  # current generation token onto that concrete owner; composed storage classes
  # do not alter the owning object.
  $async->_owner_storage($self) if $async->can('_owner_storage');
  $self->_async_context_owner_token($async->_context_owner_token);

  return $self->{_async_storage_obj} = $async;
}


sub async {
  my $self = shift;
  return $self->_async_storage;
}


sub disconnect {

  if( my $dbh = $_[0]->_dbh ) {

    $_[0]->_do_connection_actions(disconnect_call_ => $_) for (
      ( $_[0]->on_disconnect_call || () ),
      $_[0]->_parse_connect_do ('on_disconnect_do')
    );

    # stops the "implicit rollback on disconnect" warning
    $_[0]->_exec_txn_rollback unless $_[0]->_dbh_autocommit;

    %{ $dbh->{CachedKids} } = ();
    $dbh->disconnect;
    $_[0]->_dbh(undef);
    $_[0]->deferred_rollback(undef);
  }

  # Tear down the embedded async backend, if one was built. Outside the _dbh
  # guard so it runs even when no sync dbh was ever opened. Reset ownership
  # before deleting the cache; the old backend's disconnect rotates its own
  # token, but may not re-adopt it after this storage has detached that backend.
  $_[0]->_reset_async_context_owner_token;
  if (my $async = delete $_[0]->{_async_storage_obj}) {
    $async->disconnect;
  }
}


# Storage subclasses should override this
sub with_deferred_fk_checks {
  #my ($self, $sub) = @_;
  $_[1]->();
}


sub connected {
  return 0 unless $_[0]->_seems_connected;

  #be on the safe side
  local $_[0]->_dbh->{RaiseError} = 1;

  return $_[0]->_ping;
}

sub _seems_connected {
  $_[0]->_verify_pid unless is_windows();

  ($_[0]->_dbh || return 0)->FETCH('Active');
}

sub _ping {
  ($_[0]->_dbh || return 0)->ping;
}

sub ensure_connected {
  $_[0]->connected || ( $_[0]->_populate_dbh && 1 );
}


sub dbh {
  # maybe save a ping call
  $_[0]->_dbh
    ? ( $_[0]->ensure_connected and $_[0]->_dbh )
    : $_[0]->_populate_dbh
  ;
}

# this is the internal "get dbh or connect (don't check)" method
sub _get_dbh {
  $_[0]->_verify_pid unless is_windows();
  $_[0]->_dbh || $_[0]->_populate_dbh;
}

# *DELIBERATELY* not a setter (for the time being)
# Too intertwined with everything else for any kind of sanity
sub sql_maker {
  my $self = shift;

  $self->throw_exception('sql_maker() is not a setter method') if @_;

  unless ($self->_sql_maker) {
    my $sql_maker_class = $self->sql_maker_class;

    my %opts = %{$self->_sql_maker_opts||{}};

    my ($quote_char, $name_sep);

    # Identifier quoting defaults to ON (security hardening, Codeberg
    # dbio/dbio#2). Quote unless the user explicitly passed a false
    # quote_names in their connect_info.
    if (!exists $opts{quote_names} || $opts{quote_names}) {
      # An explicitly supplied quote_char is always respected, including an
      # empty string (which means "no quoting" and must win over the class
      # default) -- hence exists(), not truthiness.
      $quote_char = exists $opts{quote_char}
        ? delete $opts{quote_char}
        : $self->sql_quote_char || do {
          my $s_class = (ref $self) || $self;
          carp_unique (<<"__EOW__");
You requested 'quote_names' but your storage class ($s_class) does
not explicitly define a default sql_quote_char and you have not
supplied a quote_char as part of your connection_info. DBIO will
default to the ANSI SQL standard quote '"', which works most of
the time. Please file a Codeberg issue against '$s_class' at
https://codeberg.org/dbio/dbio/issues
__EOW__

          '"'; # RV
        };

      $name_sep = (delete $opts{name_sep}) || $self->sql_name_sep;
    }

    $self->_sql_maker($sql_maker_class->new(
      bindtype=>'columns',
      array_datatypes => 1,
      ($quote_char ? (quote_char => $quote_char) : ()),
      name_sep => ($name_sep || '.'),
      %opts,
    ));
  }
  return $self->_sql_maker;
}

# nothing to do by default
sub _init {}

sub _populate_dbh {

  $_[0]->_dbh(undef); # in case ->connected failed we might get sent here

  $_[0]->_dbh_details({}); # reset everything we know

  # FIXME - this needs reenabling with the proper "no reset on same DSN" check
  #$_[0]->_sql_maker(undef); # this may also end up being different

  $_[0]->_dbh($_[0]->_connect);

  $_[0]->_conn_pid($$) unless is_windows(); # on win32 these are in fact threads

  # A driver determination that throws takes the handle with it: no connection
  # action has run on it, and connected() would take the storage for usable.
  # The rule of _do_connection_actions, without its exception for a pool
  # connection -- this handle is the one opened above. Only the handle goes:
  # the transaction depth is not set yet, _conn_pid means nothing without a
  # handle, and the next connect resets _dbh_details. A guard and not a catch,
  # so that the error passes as it was thrown (karr k312).
  {
    my ($self, $determined) = $_[0];
    my $guard = scope_guard { $self->_dbh(undef) unless $determined };
    $self->_determine_driver;
    $determined = 1;
  }

  # Always set the transaction depth on connect, since
  #  there is no transaction in progress by definition
  $_[0]->{transaction_depth} = $_[0]->_dbh_autocommit ? 0 : 1;
  $_[0]->deferred_rollback(undef);

  $_[0]->_run_connection_actions unless $_[0]->{_in_determine_driver};

  $_[0]->_dbh;
}

# The connect key 'schema' (ADR 0065): the namespace this connection works in.
# Core owns the word, the plain-name contract and the refusal; the meaning is
# the driver's, given by overriding _set_connection_schema.
sub _assert_connection_schema_name {
  my ($self, $value) = @_;

  DBIO::Exception->throw(
    "The connect key 'schema' takes a single non-empty name (the namespace "
  . 'this connection works in), not '
  . (!defined $value ? 'undef' : ref $value ? 'a ' . ref($value) . ' reference' : 'an empty string')
  ) unless defined $value and !ref $value and length $value;

  # an identifier (ADR 0077): ';', a line break and NUL would end the driver's
  # statement; the rest (quote, blank, backslash) the driver quotes or refuses
  DBIO::Util::assert_identifier_text("The connect key 'schema'", $value);

  return $value;
}

# Driver seam: make $name the namespace of the connection being set up. Runs
# on every new connection, sync (_run_connection_actions) and async pool
# (_run_pool_connect_actions), before the user's on_connect_call/on_connect_do,
# only when the connect info gave 'schema'. Issue the statement(s) through
# _do_query, which lands on the right connection in both places. A storage
# whose driver has no namespaces keeps this default and refuses.
# $name is an identifier (ADR 0077): write it only through the driver's
# identifier quoting (or a bind), or refuse it with a DBIO::Exception.
sub _set_connection_schema {
  my ($self, $name) = @_;

  DBIO::Exception->throw(
    ref($self) . " has no namespaces: the connect key 'schema' (given '$name') "
  . 'has no meaning for this driver. Remove it from the connect info, or use a '
  . 'driver that gives it one.'
  );
}

# Driver seam (ADR 0066): what the declared database extensions want of a new
# connection, as data -- { load => [ ... ], search_path => [ ... ] } -- or
# undef for none (the default). Asked with the connection's namespace, which
# may be undef. The driver resolves its extension list here.
sub _extension_activation { undef }

# Driver seam (ADR 0066): write the activation the driver got from
# _extension_activation as the dialect's statements (PostgreSQL: LOAD, and,
# when $name is undef, appending to the search_path; with a namespace the
# search_path is _set_connection_schema's). Only called with an activation.
# Issue statements through _do_query. The default does nothing.
sub _activate_extensions { $_[0] }

sub _apply_connection_schema {
  my $self = shift;
  my $name = $self->connection_schema;

  my $activation = $self->_extension_activation($name);
  $self->_activate_extensions($activation, $name) if $activation;
  $self->_set_connection_schema($name, $activation) if defined $name;

  return $self;
}

sub _run_connection_actions {
  # there are pathological cases in the CI where this can loop
  # did not investigae in depth, but in either case this makes
  # sense to guard like this
  return if $_[0]->{_running_connections_actions};

  local $_[0]->{_running_connections_actions} = 1;

  $_[0]->_apply_connection_schema;

  $_[0]->_do_connection_actions(connect_call_ => $_) for (
    ( $_[0]->on_connect_call || () ),
    $_[0]->_parse_connect_do ('on_connect_do'),
  );

  my $sqlac_like;
  if(
    is_dev_release
      and
    ($ENV{DBIODEVREL_SWAPOUT_SQLAC_WITH} || $ENV{DBICDEVREL_SWAPOUT_SQLAC_WITH})
      and
    ( $sqlac_like ) = ($ENV{DBIODEVREL_SWAPOUT_SQLAC_WITH} || $ENV{DBICDEVREL_SWAPOUT_SQLAC_WITH}) =~ /(.+)/
      and
    # delay calling ->sql_maker as long as we can
    # ensure_class_loaded returns undef or throws
    ( DBIO::Componentised->ensure_class_loaded( $sqlac_like ), 1 )
      and
    ( ref $_[0]->sql_maker ) !~ /__REBASED__/
  ) {

    require DBIO::SQLMaker::ClassicExtensions;
    require SQL::Abstract;

    Class::C3::Componentised->inject_base(
      'DBICDevRel::SQLAC::SwapOut',
      'DBIO::SQLMaker::ClassicExtensions',
      $sqlac_like,
      'SQL::Abstract',
    );

    $_[0]->_do_connection_actions(connect_call_ => [[ rebase_sqlmaker => 'DBICDevRel::SQLAC::SwapOut' ]]);
  }
}

# Replay THIS storage's configured on_connect actions against a freshly
# spawned async pool connection. Called from the embedded async backend's
# _setup_pool_connection with $runner, a coderef that runs one statement on the
# pool connection. We reuse the exact sync dispatch (_do_connection_actions +
# _parse_connect_do, in the same order _run_connection_actions uses) so that
# connect_call_* resolve on this (owning) storage identically to sync -- but the
# statements they emit via _do_query are redirected onto the pool connection by
# localising _pool_connect_runner (honoured in _do_query). This is the
# convention-friendly dispatch: resolve on the sync storage, execute against
# the pool handle.
sub _run_pool_connect_actions {
  my ($self, $runner) = @_;

  local $self->{_pool_connect_runner} = $runner;

  $self->_apply_connection_schema;

  $self->_do_connection_actions(connect_call_ => $_) for (
    ( $self->on_connect_call || () ),
    $self->_parse_connect_do('on_connect_do'),
  );

  return $self;
}

# The rows of a query for a connect_call_*: inside the pool replay
# (_pool_connect_runner set) the runner reads them from the pool connection,
# else they come from this storage's own handle, so one connect_call_* asks the
# same question on both paths. Returns an arrayref of row arrayrefs.
sub _pool_connect_rows {
  my ($self, $sql, @bind) = @_;

  local $self->{_statement_in_flight} = $sql;
  local $self->{_values_in_flight} = \@bind;

  my $rows = try {
    if (my $runner = $self->{_pool_connect_runner}) {
      $runner->($sql, { dbio_rows => 1 }, @bind);
    }
    else {
      $self->dbh_do(sub { $_[1]->selectall_arrayref($sql, undef, @bind) });
    }
  }
  catch {
    my $err = $_;
    my $values = _plain_error_values(@bind);
    if (!ref $err) {
      $err = $self->_mask_error_values(mask_statement_secrets($err, $sql), $values, $sql);
    }
    elsif (blessed $err and $err->isa('DBIO::Exception') and defined $err->{msg} and !ref $err->{msg}) {
      $err->{msg} = $self->_mask_error_values(mask_statement_secrets($err->{msg}, $sql), $values, $sql);
    }
    die $err;
  };

  return $rows;
}

# Symmetric counterpart for disconnect: same dispatch machinery, run against the
# pool connection while it is still live (from the pool's shutdown path).
sub _run_pool_disconnect_actions {
  my ($self, $runner) = @_;

  local $self->{_pool_connect_runner} = $runner;

  $self->_do_connection_actions(disconnect_call_ => $_) for (
    ( $self->on_disconnect_call || () ),
    $self->_parse_connect_do('on_disconnect_do'),
  );

  return $self;
}



sub _server_info {
  my $self = shift;

  my $info;
  unless ($info = $self->_dbh_details->{info}) {

    $info = {};
    # this guarantees that problematic conninfo won't be hidden
    # by the try{} below
    $self->ensure_connected;

    my $server_version = try {
      $self->_get_server_version
    } catch {
      # driver determination *may* use this codepath
      # in which case we must rethrow
      $self->throw_exception($_) if $self->{_in_determine_driver};

      # $server_version on failure
      undef;
    };

    if (defined $server_version) {
      $info->{dbms_version} = $server_version;

      my ($numeric_version) = $server_version =~ /^([\d\.]+)/;
      my @verparts = split (/\./, $numeric_version);
      if (
        @verparts
          &&
        $verparts[0] <= 999
      ) {
        # consider only up to 3 version parts, iff not more than 3 digits
        my @use_parts;
        while (@verparts && @use_parts < 3) {
          my $p = shift @verparts;
          last if $p > 999;
          push @use_parts, $p;
        }
        push @use_parts, 0 while @use_parts < 3;

        $info->{normalized_dbms_version} = sprintf "%d.%03d%03d", @use_parts;
      }
    }

    $self->_dbh_details->{info} = $info;
  }

  return $info;
}

sub _get_server_version {
  shift->_dbh_get_info('SQL_DBMS_VER');
}

sub _dbh_get_info {
  my ($self, $info) = @_;

  if ($info =~ /[^0-9]/) {
    require DBI::Const::GetInfoType;
    $info = $DBI::Const::GetInfoType::GetInfoType{$info};
    $self->throw_exception("Info type '$_[1]' not provided by DBI::Const::GetInfoType")
      unless defined $info;
  }

  $self->_get_dbh->get_info($info);
}

sub _describe_connection {
  require DBI::Const::GetInfoReturn;

  my $self = shift;

  my $drv;
  try {
    $drv = $self->_extract_driver_from_connect_info;
    $self->ensure_connected;
  };

  $drv = "DBD::$drv" if $drv;

  my $info = $self->_dbi_connect_info;

  my $res = do {
    local $SIG{__WARN__} = sigwarn_silencer(qr/Argument .+? isn't numeric in subroutine entry/);
    {
      # never the password in it: this goes into a warning (karr k297)
      DBIO_DSN => mask_connect_secrets($info->[0], $info),
      DBI_VER => DBI->VERSION,
      DBIO_VER => DBIO->VERSION,
      DBIO_DRIVER => ref $self,
      $drv ? (
        DBD => $drv,
        DBD_VER => try { $drv->VERSION },
      ) : (),
    }
  };

  # try to grab data even if we never managed to connect
  # will cover us in cases of an oddly broken half-connect
  for my $inf (
    #keys %DBI::Const::GetInfoType::GetInfoType,
    qw/
      SQL_CURSOR_COMMIT_BEHAVIOR
      SQL_CURSOR_ROLLBACK_BEHAVIOR
      SQL_CURSOR_SENSITIVITY
      SQL_DATA_SOURCE_NAME
      SQL_DBMS_NAME
      SQL_DBMS_VER
      SQL_DEFAULT_TXN_ISOLATION
      SQL_DM_VER
      SQL_DRIVER_NAME
      SQL_DRIVER_ODBC_VER
      SQL_DRIVER_VER
      SQL_EXPRESSIONS_IN_ORDERBY
      SQL_GROUP_BY
      SQL_IDENTIFIER_CASE
      SQL_IDENTIFIER_QUOTE_CHAR
      SQL_MAX_CATALOG_NAME_LEN
      SQL_MAX_COLUMN_NAME_LEN
      SQL_MAX_IDENTIFIER_LEN
      SQL_MAX_TABLE_NAME_LEN
      SQL_MULTIPLE_ACTIVE_TXN
      SQL_MULT_RESULT_SETS
      SQL_NEED_LONG_DATA_LEN
      SQL_NON_NULLABLE_COLUMNS
      SQL_ODBC_VER
      SQL_QUALIFIER_NAME_SEPARATOR
      SQL_QUOTED_IDENTIFIER_CASE
      SQL_TXN_CAPABLE
      SQL_TXN_ISOLATION_OPTION
    /
  ) {
    # some drivers barf on things they do not know about instead
    # of returning undef
    my $v = try { $self->_dbh_get_info($inf) };
    next unless defined $v;

    #my $key = sprintf( '%s(%s)', $inf, $DBI::Const::GetInfoType::GetInfoType{$inf} );
    my $expl = DBI::Const::GetInfoReturn::Explain($inf, $v);
    $res->{$inf} = DBI::Const::GetInfoReturn::Format($inf, $v) . ( $expl ? " ($expl)" : '' );
  }

  # what a DBD answers here may be its DSN again
  $res->{SQL_DATA_SOURCE_NAME} = mask_connect_secrets($res->{SQL_DATA_SOURCE_NAME}, $info)
    if defined $res->{SQL_DATA_SOURCE_NAME};

  $res;
}

# Driver registry: maps DBD driver names to DBIO Storage classes.
# External DBIO::* distributions register themselves here via
# register_driver(), or are discovered via the default mapping below.
my %_driver_registry = (
  Pg        => 'DBIO::PostgreSQL::Storage',
  mysql     => 'DBIO::MySQL::Storage',
  MariaDB   => 'DBIO::MySQL::Storage::MariaDB',
  SQLite    => 'DBIO::SQLite::Storage',
  Oracle    => 'DBIO::Oracle::Storage',
  Sybase    => 'DBIO::Sybase::Storage',
  Firebird  => 'DBIO::Firebird::Storage',
  InterBase => 'DBIO::Firebird::Storage::InterBase',
  Informix  => 'DBIO::Informix::Storage',
  DB2       => 'DBIO::DB2::Storage',
  ODBC      => 'DBIO::Storage::DBI::ODBC',
);


sub register_driver {
  my ($class, $driver_name, $storage_class) = @_;
  $_driver_registry{$driver_name} = $storage_class;
}

sub driver_storage_class {
  my ($class, $driver_name) = @_;
  return $_driver_registry{$driver_name};
}

# The registry read backwards: the DBD driver names the nearest registered
# class in this storage's MRO is registered for. Most specific first, so a
# storage layer composed over a driver storage answers that driver, and a
# driver subclass with an entry of its own (DBIO::MySQL::Storage::MariaDB)
# answers its own. Empty for a storage no class of which is registered.
sub _registered_dbd_drivers {
  my $self = shift;
  for my $class (@{ mro::get_linear_isa(ref $self || $self) }) {
    my @drivers = sort grep { $_driver_registry{$_} eq $class }
      keys %_driver_registry;
    return @drivers if @drivers;
  }
  return;
}


my %_access_path_dbds;

sub register_access_path_dbd {
  my ($class, @dbds) = @_;
  $class = ref $class || $class;
  $_access_path_dbds{$class}{$_} = 1 for @dbds;
  return;
}

# Does a class in this storage's MRO -- the adapted class, and with it the
# declared one -- declare $dbd as its access path? Class or instance.
sub _access_path_dbd_declared {
  my ($self, $dbd) = @_;
  return 0 unless defined $dbd;
  for my $class (@{ mro::get_linear_isa(ref $self || $self) }) {
    return 1 if $_access_path_dbds{$class} and $_access_path_dbds{$class}{$dbd};
  }
  return 0;
}


sub register_connector_driver {
  my $class = shift;
  $class->throw_exception(
    'register_connector_driver is retired (ADR 0067): a storage is never '
  . 'moved into a driver by the engine an ODBC connection reports. Declare '
  . "the driver on the schema (use DBIO 'Schema', -<driver>); a driver that "
  . 'runs over ODBC adapts itself to it in _adapt_to_access_path.'
  );
}

# Standard SQL type registrations for DBIO::Cake.
# Driver subclasses add or override entries for their own types.
__PACKAGE__->register_type('json', {
  cake_options => [qw(inflate_json)],
  components   => ['InflateColumn::Serializer'],
  col_attrs    => { serializer_class => 'JSON' },
});

for my $dt (qw(date datetime timestamp time timetz timestamptz interval)) {
  __PACKAGE__->register_type($dt, {
    cake_options => ['inflate_datetime'],
    components   => ['InflateColumn::DateTime'],
  });
}

sub _determine_driver {
  my ($self) = @_;

  if ((not $self->_driver_determined) && (not $self->{_in_determine_driver})) {
    # Connected on entry means _populate_dbh is the caller and runs the
    # connection actions itself once we return. Running them is ours only when
    # the determination opens the connection, since _populate_dbh holds them
    # back while _in_determine_driver is set. That holds for a declared class
    # as for the generic one (karr k309).
    my $started_connected = $self->_dbh ? 1 : 0;
    local $self->{_in_determine_driver} = 1;

    # A determination that throws leaves the storage as it came in: in the
    # class it had, undetermined, and without a handle the determination
    # opened itself -- no connection action has run on that one (a handle the
    # storage came in with is _populate_dbh's to drop). The next use starts
    # over, through the same branch. ADR 0059 says so for the hook of a
    # declared class, and _adapt_declared_storage does it for the hook; this
    # covers what else can throw: _init (karr k312, k313).
    # Whatever the failed step set on the instance stays, as it does there.
    # A guard and not a catch, so that the error passes as it was thrown.
    my $entry_class = ref $self;
    my $determined;
    my $guard = scope_guard {
      return if $determined;
      bless $self, $entry_class;
      $self->_driver_determined(0);
      $self->_dbh(undef) unless $started_connected;
    };

    # A composed storage class (DBIO::Storage::Composed) is judged by its
    # base: layers over the generic __PACKAGE__ are as driverless as the bare
    # generic storage, layers over a driver class are declared. A non-composed
    # instance has no registry entry and is judged by its own class.
    my $composition = DBIO::Storage::Composed->composition_of(ref $self);
    my $is_generic = ref($self) eq __PACKAGE__
      || ($composition && $composition->{base} eq __PACKAGE__);

    if ($is_generic) {
      # The generic storage has no driver, and none is guessed from the DSN
      # (ADR 0067). A schema refuses it at connect; a storage built by hand
      # that gets this far is refused here, and a connection opened for it is
      # dropped by the guard above.
      $self->throw_exception(
        'The generic storage DBIO::Storage::DBI has no driver, and a storage '
      . 'always has one (ADR 0067). Use the storage class of a driver -- '
      . "declared on the schema with use DBIO 'Schema', -<driver>, the "
      . "driver's component or storage_type. DBIO->driver_for(\$dsn) names "
      . 'the driver of a DSN.'
      );
    }
    else {
      # A declared storage class -- pinned by a driver component or a driver
      # shortcut through the schema's storage_type -- never leaves its driver.
      # It gets to adapt itself to the access path (ADR 0059, karr k301).
      $self->_adapt_declared_storage($composition);
    }

    $self->_driver_determined(1);

    Class::C3->reinitialize() if old_mro();

    $self->_init; # run driver-specific initializations

    # A connection action that fails below is no failed determination: it
    # gives up the connection (_do_connection_actions) and not the driver.
    $determined = 1;

    $self->_run_connection_actions
        if !$started_connected && defined $self->_dbh;
  }
}

sub _extract_driver_from_connect_info {
  my $self = shift;

  my $drv;

  # if connect_info is a CODEREF, we have no choice but to connect
  if (
    ref $self->_dbi_connect_info->[0]
      and
    reftype $self->_dbi_connect_info->[0] eq 'CODE'
  ) {
    $self->_populate_dbh;
    $drv = $self->_dbh->{Driver}{Name};
  }
  else {
    # try to use dsn to not require being connected
    # (dsn may not be supplied at all if all we do is make a mock-schema)
    #
    # Use the same regex as the one used by DBI itself (even if the use of
    # \w is odd given unicode):
    # https://metacpan.org/source/TIMB/DBI-1.634/DBI.pm#L621
    #
    # DO NOT use https://metacpan.org/source/TIMB/DBI-1.634/DBI.pm#L559-566
    # as there is a long-standing precedent of not loading DBI.pm until the
    # very moment we are actually connecting
    #
    $drv = $self->_dsn_driver_part($self->_dbi_connect_info->[0]);
  }

  return $drv;
}


sub _adapt_to_access_path {}


sub _driver_mismatch {
  my ($self, $message) = @_;

  my $schema = $self->_driver_switch_schema;
  my $strict = $schema ? $schema->driver_strict   : 0;
  my $warn   = $schema ? $schema->driver_warnings : 1;

  return unless $strict or $warn;

  $message = sprintf 'Driver mismatch for declared storage class %s: %s',
    ( $self->_declared_storage_class || ref $self ), $message;

  $self->throw_exception(
    "$message (an error because driver_strict is set on the schema)"
  ) if $strict;

  carp "$message -- set driver_strict(1) on the schema to make this an "
     . 'error, or driver_warnings(0) to silence it';

  return;
}

# The schema whose driver_strict / driver_warnings apply to this storage: its
# own, else that of the nearest parent storage along _parent_storage (a writer
# or bulk storage a driver builds without a schema). Bounded and cycle-safe.
sub _driver_switch_schema {
  my $self = shift;

  my %seen;
  my $storage = $self;
  for (1 .. 16) {
    last if !$storage or $seen{ refaddr($storage) }++;
    my $schema = $storage->schema;
    return $schema if $schema;
    $storage = $storage->_parent_storage;
  }

  return undef;
}

# The declared half of driver determination (ADR 0059): the hook, the check
# of its one rule, the layers, and the DBD of another driver. $composition is
# the DBIO::Storage::Composed entry of the instance's class, if it is layered.
sub _adapt_declared_storage {
  my ($self, $composition) = @_;

  my $entry_class = ref $self;
  my $declared    = $composition ? $composition->{base} : $entry_class;

  $self->_declared_storage_class($declared);

  try {
    $self->_adapt_to_access_path($self->_access_path_dbd);

    my $adapted = ref $self;

    # The rule is checked here and not left to the hook: a storage in the
    # class of another driver is what this path exists to rule out. Back into
    # the class it came in first -- the foreign one may not even be a storage.
    if (! $self->isa($declared)) {
      bless $self, $entry_class;
      $self->throw_exception(
        "The _adapt_to_access_path hook of declared storage class $declared "
      . "reblessed the storage into $adapted, which is not a subclass of it. "
      . 'A declared driver adapts to the access path within its own classes '
      . 'only; a server that is something else is reported through '
      . '_driver_mismatch.'
      );
    }

    # The hook reblesses into a plain class of its driver; the layers of the
    # schema go back over it.
    bless $self, DBIO::Storage::Composed->recompose($entry_class, $adapted)
      if $composition
        and ! DBIO::Storage::Composed->composition_of($adapted);

    $self->_check_access_path_dbd($declared);
  }
  catch {
    bless $self, $entry_class;
    $self->throw_exception($_);
  };

  return;
}

# The DBD the connect info leads through, as far as it is known WITHOUT
# connecting: the live handle's when there is one, else the one the DSN names,
# else none (a DSN with an empty driver part is refused, karr k340). Undef for
# a connection coderef that has not been run and for connect info without a
# DSN. The driver part is read as _extract_driver_from_connect_info reads it;
# that method is not shared because it connects for a coderef, which
# _describe_connection may and this may not.
sub _access_path_dbd {
  my $self = shift;

  if (my $dbh = $self->_dbh) {
    return $dbh->{Driver}{Name};
  }

  my $dsn = $self->_dbi_connect_info->[0];
  return undef if ref $dsn;

  return $self->_dsn_driver_part($dsn);
}

# The driver part of a DSN, undef for no DSN. The DSN decides the driver
# (karr k340): a DSN whose driver part is empty (dbi::dbname=x) is refused,
# and $ENV{DBI_DRIVER} does not stand in for it. The message names the shape,
# never the DSN. The regex is the one DBI itself uses.
sub _dsn_driver_part {
  my ($self, $dsn) = @_;

  return undef unless defined $dsn && length $dsn;

  my ($dbd) = $dsn =~ /^dbi:(\w*)/i;
  return undef unless defined $dbd;

  $self->throw_exception(
    'Connect info with a DSN without a driver part (dbi::...). The DSN names '
  . 'the driver, never $ENV{DBI_DRIVER}: give the DBD name in the DSN '
  . '(dbi:<driver>:...).'
  ) unless length $dbd;

  return $dbd;
}

# The DBD of another driver: the registry maps it to a class that is neither
# an ancestor of the (adapted) storage nor a subclass of the declared class.
# A DBD nothing is registered for (Proxy, Gofer, a mock) is not a finding.
# A registered class that cannot be loaded is no relative.
sub _check_access_path_dbd {
  my ($self, $declared) = @_;

  my $dbd = $self->_access_path_dbd;
  return unless defined $dbd;

  # A DBD the driver declared as its own access path is no finding
  # (register_access_path_dbd, karr k321).
  return if $self->_access_path_dbd_declared($dbd);

  # Only a class of registered origin is judged: a private subclass of the
  # generic storage, set by hand, has no driver to compare the DBD with
  # (karr k301).
  return unless $declared->_registered_dbd_drivers;

  my $registered = $_driver_registry{$dbd}
    or return;

  return if $self->isa($registered);

  return if (
    ( try { $self->load_optional_class($registered) } )
      and
    $registered->isa($declared)
  );

  $self->_driver_mismatch(
    "the connect info leads through DBD::$dbd, which is registered for $registered"
  );

  return;
}

sub _do_connection_actions {
  my ($self, $method_prefix, $call, @args) = @_;

  try {
    if (not ref($call)) {
      my $method = $method_prefix . $call;
      $self->$method(@args);
    }
    elsif (ref($call) eq 'CODE') {
      $self->$call(@args);
    }
    elsif (ref($call) eq 'ARRAY') {
      if (ref($call->[0]) ne 'ARRAY') {
        $self->_do_connection_actions($method_prefix, $_) for @$call;
      }
      else {
        $self->_do_connection_actions($method_prefix, @$_) for @$call;
      }
    }
    else {
      $self->throw_exception (sprintf ("Don't know how to process conection actions of type '%s'", ref($call)) );
    }
  }
  catch {
    if ( $method_prefix =~ /^connect/ ) {
      # this is an on_connect cycle - we can't just throw while leaving
      # a handle in an undefined state in our storage object
      # kill it with fire and rethrow
      #
      # Unless the actions were replayed on an async pool connection
      # (_run_pool_connect_actions): then the half-configured handle is the
      # pool's, which retires it (ADR 0047). Ours is another connection the
      # failure never touched, possibly in the middle of a transaction
      # (karr k251).
      $self->_dbh(undef) unless $self->{_pool_connect_runner};
      $self->throw_exception( $_[0] );
    }
    else {
      carp "Disconnect action failed: $_[0]";
    }
  };

  return $self;
}

sub connect_call_do_sql {
  my $self = shift;
  $self->_do_query(@_);
}

sub disconnect_call_do_sql {
  my $self = shift;
  $self->_do_query(@_);
}


sub connect_call_datetime_setup { 1 }

sub _do_query {
  my ($self, $action) = @_;

  if (ref $action eq 'CODE') {
    my $answer = $action->($self);

    # nothing, one statement as a plain string, or a list of statements
    return $self unless defined $answer and (ref $answer or length $answer);

    $answer = [ $answer ] unless ref $answer;

    $self->throw_exception(
      'A code reference given to on_connect_do / on_disconnect_do / do_sql '
    . 'must return a SQL string, an array reference of statements, or '
    . 'nothing, not ' . (blessed($answer)
        ? 'an object of class ' . ref $answer
        : 'a ' . ref($answer) . ' reference')
    ) unless ref $answer eq 'ARRAY';

    $self->_do_query($_) foreach @$answer;
  }
  else {
    # Most debuggers expect ($sql, @bind), so we need to exclude
    # the attribute hash which is the second argument to $dbh->do
    # furthermore the bind values are usually to be presented
    # as named arrayref pairs, so wrap those here too
    my @do_args = (ref $action eq 'ARRAY') ? (@$action) : ($action);
    my $sql = shift @do_args;
    my $attrs = shift @do_args;
    my @bind = map { [ undef, $_ ] } @do_args;

    # An error about this statement never quotes what it carries as a secret
    # (karr k343): _dbi_handle_error masks the text of the database before
    # the exception_action sees it, a die of the pool runner is masked here.
    local $self->{_statement_in_flight} = $sql;
    local $self->{_values_in_flight} = \@do_args;

    try {
      # When replaying this storage's connection actions against a
      # freshly-spawned async pool connection (_run_pool_connect_actions), the
      # statement must execute on THAT pool connection, not on this sync
      # storage's own dbh. The runner (installed by the async backend's
      # _setup_pool_connection) does the blocking do on the pool handle. Only
      # ever set inside that dynamic scope, so the normal sync path is
      # untouched.
      if (my $runner = $self->{_pool_connect_runner}) {
        $runner->($sql, $attrs, @do_args);
      }
      else {
        $self->dbh_do(sub {
          $_[0]->_query_start($sql, \@bind);
          $_[1]->do($sql, $attrs, @do_args);
          $_[0]->_query_end($sql, \@bind);
        });
      }
    }
    catch {
      my $err = $_;
      my $values = _plain_error_values(@do_args);
      if (!ref $err) {
        $err = $self->_mask_error_values(mask_statement_secrets($err, $sql), $values, $sql);
      }
      elsif (blessed $err and $err->isa('DBIO::Exception') and defined $err->{msg} and !ref $err->{msg}) {
        $err->{msg} = $self->_mask_error_values(mask_statement_secrets($err->{msg}, $sql), $values, $sql);
      }
      die $err;
    };
  }

  return $self;
}


sub connect_call_rebase_sqlmaker {
  my( $self, $requested_base_class ) = @_;

  $self->throw_exception(
    "The on_connect callee 'rebase_sqlmaker' expects a single plain string argument: the name of the target base class"
  ) if (
    @_ != 2
      or
    ! length( $requested_base_class )
  );

  my $old_class = ref( $self->sql_maker );

  # nothing to do!
  return if $old_class->isa( $requested_base_class );

  my $synthetic_class = "${old_class}__REBASED_ON__${requested_base_class}";

  {
    no strict 'refs';

    # skip if we already made that class
    unless( @{"${synthetic_class}::ISA"} ) {

      $self->ensure_class_loaded( $requested_base_class );

      $self->throw_exception(
        "The 'rebase_sqlmaker' target class '$requested_base_class' is not inheriting from 'DBIO::SQLMaker::ClassicExtensions', this can not work"
      ) unless $requested_base_class->isa( 'DBIO::SQLMaker::ClassicExtensions' );

      $self->throw_exception(
        "The 'rebase_sqlmaker' target class '$requested_base_class' must inherit from SQL::Abstract or SQL::Abstract::Classic"
      ) unless $requested_base_class->isa( 'SQL::Abstract' )
            or $requested_base_class->isa( 'SQL::Abstract::Classic' );

      $self->inject_base( $synthetic_class, $old_class, $requested_base_class );

      Class::C3->reinitialize
        if old_mro();
    }
  }

  # force re-build on next access for this particular $storage instance
  $self->sql_maker_class( $synthetic_class );
  $self->_sql_maker( undef );
}


sub _finish_connect_dsn { $_[1] }

sub _connect {
  my $self = shift;

  my $info;
  if ($self->access_broker) {
    # nothing of the answer is stored: it is formed for this connection alone
    my ($args, $attrs) = $self->_access_broker_dbi_args(
      $self->access_broker_mode, connecting => 1,
    );
    $info = $args;
    $self->_dbio_connect_attributes($attrs);
  }
  else {
    $info = $self->_dbi_connect_info;
  }

  $self->throw_exception("You did not provide any connection_info")
    unless defined $info->[0];

  # before DBI->connect, which would take the driver from $ENV{DBI_DRIVER}
  # for a DSN without a driver part (karr k340)
  $self->_dsn_driver_part($info->[0]) unless ref $info->[0];

  # the driver's last word on the DSN, for broker and static connect info
  # alike; on a copy, the stored connect info stays as it is
  unless (ref $info->[0]) {
    $info = [ @$info ];
    $info->[0] = $self->_finish_connect_dsn($info->[0]);
  }

  my ($old_connect_via, $dbh);

  local $DBI::connect_via = 'connect' if $INC{'Apache/DBI.pm'} && $ENV{MOD_PERL};

  # this odd anonymous coderef dereference is in fact really
  # necessary to avoid the unwanted effect described in perl5
  # RT#75792
  #
  # in addition the coderef itself can't reside inside the try{} block below
  # as it somehow triggers a leak under perl -d
  my $dbh_error_handler_installer = sub {
    weaken (my $weak_self = $_[0]);

    # the coderef is blessed so we can distinguish it from externally
    # supplied handles (which must be preserved)
    $_[1]->{HandleError} = bless sub {
      if ($weak_self) {
        $weak_self->_dbi_handle_error(@_[0, 1]);
      }
      else {
        # the handler may be invoked by something totally out of
        # the scope of DBIO
        my $err;
        eval {
          DBIO::Exception->throw("DBI Exception (unhandled by DBIO, ::Schema GCed): $_[0]");
          1;
        } or $err = $@;
        die _exception_as_server($err, __PACKAGE__->_dbi_error_fields($_[1]));
      }
    }, '__DBIO__DBH__ERROR__HANDLER__';
  };

  try {
    if(ref $info->[0] eq 'CODE') {
      $dbh = $info->[0]->();
    }
    else {
      require DBI;
      $dbh = DBI->connect(@$info);
    }

    die $DBI::errstr unless $dbh;

    die sprintf ("%s fresh DBI handle with a *false* 'Active' attribute. "
      . 'This handle is disconnected as far as DBIO is concerned, and we can '
      . 'not continue',
      ref $info->[0] eq 'CODE'
        ? "Connection coderef $info->[0] returned a"
        : 'DBI->connect($schema->storage->connect_info) resulted in a'
    ) unless $dbh->FETCH('Active');

    # sanity checks unless asked otherwise
    unless ($self->unsafe) {

      $self->throw_exception(
        'Refusing clobbering of {HandleError} installed on externally supplied '
       ."DBI handle $dbh. Either remove the handler or use the 'unsafe' attribute."
      ) if $dbh->{HandleError} and ref $dbh->{HandleError} ne '__DBIO__DBH__ERROR__HANDLER__';

      # Default via _default_dbi_connect_attributes is 1, hence it was an explicit
      # request, or an external handle. Complain and set anyway
      unless ($dbh->{RaiseError}) {
        carp( ref $info->[0] eq 'CODE'

          ? "The 'RaiseError' of the externally supplied DBI handle is set to false. "
           ."DBIO will toggle it back to true, unless the 'unsafe' connect "
           .'attribute has been supplied'

          : 'RaiseError => 0 supplied in your connection_info, without an explicit '
           .'unsafe => 1. Toggling RaiseError back to true'
        );

        $dbh->{RaiseError} = 1;
      }

      $dbh->{ShowErrorStatement} = 0;

      $dbh_error_handler_installer->($self, $dbh);
    }
  }
  catch {
    # DBI dies quoting the data source it was given, and a DBD or a connection
    # coderef may repeat any of it: never the password (karr k297)
    $self->throw_exception(mask_connect_secrets("DBI Connection failed: $_", $info))
  };

  $self->_dbh_autocommit($dbh->{AutoCommit});
  return $dbh;
}

# What the HandleError handler of every handle this storage opens does with
# a refused statement (ADR 0062, decision 2026-10-12): throws it as a
# DBIO::Exception::Server -- a DBIO::Exception, so existing catch blocks keep
# working -- whose text is the "DBI Exception: ..." (caller included) it always
# was, and whose sqlstate and further fields come from _dbi_error_fields. The
# exception still goes through throw_exception first, so an exception_action
# of the schema sees the same text it always did and an object of its own that
# it throws is left alone.
sub _dbi_handle_error {
  my ($self, $msg, $h) = @_;

  # the statement being run: the one of _dbh_execute, else the one of a
  # connect action (_do_query), else the one the handle knows
  # _exec_in_flight holds the statement (in placeholder form) and the values
  # bound to it; _values_in_flight the values of a statement _do_query runs
  my ($exec_sql, $exec_values) = @{ $self->{_exec_in_flight} || [] };
  my $mask_values = $exec_values // $self->{_values_in_flight};
  my $statement = $exec_sql // $self->{_statement_in_flight}
    // eval { $h->{Statement} };
  # a handle that knows no bind count answers with a DBI warning; the error
  # handler stays silent
  my $binds = ref $exec_values eq 'ARRAY' ? scalar @$exec_values : do {
    local $SIG{__WARN__} = sub { };
    eval { $h->{NUM_OF_PARAMS} } // 0;
  };

  # the statement being run through _do_query (karr k343)
  $msg = mask_statement_secrets($msg, $self->{_statement_in_flight})
    if defined $self->{_statement_in_flight};

  # the values bound to the statement stay out of the text of the engine
  # (ADR 0075)
  $msg = $self->_mask_error_values(
    $msg,
    _plain_error_values(ref $mask_values eq 'ARRAY' ? @$mask_values : ()),
    (defined $statement and !ref $statement and length $statement) ? $statement : undef,
  );

  # What DBI appends on its own for a handle with ShowErrorStatement on (a
  # handle supplied by a coderef, 'unsafe') is replaced by the statement and
  # the number of its binds below. It is cut off after the values are masked:
  # a value that holds the marker is masked whole first.
  $msg =~ s/\s*\[for Statement ".*\z//s;

  if (defined $statement and !ref $statement and length $statement) {
    $statement = mask_statement_secrets($statement, $self->{_statement_in_flight})
      if defined $self->{_statement_in_flight};
    $msg .= sprintf ' [for Statement "%s" with %d bind value%s]',
      $statement, $binds, $binds == 1 ? '' : 's';
  }

  my $err;
  eval { $self->throw_exception("DBI Exception: $msg"); 1 } or $err = $@;

  die _exception_as_server($err, $self->_dbi_error_fields($h));
}


sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;

  return $text unless defined $text and !ref $text;

  my $masked = eval {
    my $dbh = $self->_dbh;
    my $quote = (blessed $dbh and $dbh->can('quote'))
      ? sub { $dbh->quote($_[0]) }
      : undef;
    mask_bound_values($text, $values, $quote);
  };

  return defined $masked ? $masked : $text;
}

# The values of a list of binds as the hook _mask_error_values takes them:
# undef and a reference that is no plain value fall away, an object with a
# stringification is its string.
sub _plain_error_values {
  my @plain;
  for my $v (@_) {
    next unless defined $v;
    if (length ref $v) {
      my $p = is_plain_value($v) or next;
      push @plain, "$$p" if defined $$p;
    }
    else {
      push @plain, $v;
    }
  }
  return \@plain;
}

# The statement and values of a bind list for the text of an error: the
# statement in placeholder form, the values raw. NoBindVars overrides this,
# its statement carries the values.
sub _error_form_of_bind {
  my ($self, $sql, $bind) = @_;
  return ($sql, [ map { $_->[1] } @{ $bind || [] } ]);
}

# A plain DBIO::Exception becomes the Server object with the same text; what
# is any other class (an exception_action's own object, an object of a driver)
# is left exactly as it is.
sub _exception_as_server {
  my ($err, $fields) = @_;

  return $err unless ref $err eq 'DBIO::Exception';

  my %own = map { $_ => $fields->{$_} }
    grep { defined $fields->{$_} } qw(sqlstate constraint table detail);

  return bless { %$err, %own }, 'DBIO::Exception::Server';
}


sub _dbi_error_fields {
  my ($self, $h) = @_;

  my $state = blessed($h) && $h->can('state')
    ? eval { $h->state }
    : undef;

  return {} unless defined $state && length $state
    && $state ne '00000' && $state ne 'S1000';
  return { sqlstate => $state };
}

sub txn_begin {
  $_[0]->_assert_transaction_safe_access_broker;
  local $_[0]->{_access_broker_txn_safety_checked} = 1;

  # this means we have not yet connected and do not know the AC status
  # (e.g. coderef $dbh), need a full-fledged connection check
  if (! defined $_[0]->_dbh_autocommit) {
    $_[0]->ensure_connected;
  }
  # Otherwise simply connect or re-connect on pid changes
  else {
    $_[0]->_get_dbh;
  }

  shift->next::method(@_);
}

sub _exec_txn_begin {
  my $self = shift;

  # if the user is utilizing txn_do - good for him, otherwise we need to
  # ensure that the $dbh is healthy on BEGIN.
  # We do this via ->dbh_do instead of ->dbh, so that the ->dbh "ping"
  # will be replaced by a failure of begin_work itself (which will be
  # then retried on reconnect)
  if ($self->{_in_do_block}) {
    $self->_dbh->begin_work;
  } else {
    $self->dbh_do(sub { $_[1]->begin_work });
  }
}

sub txn_commit {
  my $self = shift;

  $self->throw_exception("Unable to txn_commit() on a disconnected storage")
    unless $self->_seems_connected;

  # esoteric case for folks using external $dbh handles
  if (! $self->transaction_depth and ! $self->_dbh->FETCH('AutoCommit') ) {
    carp "Storage transaction_depth 0 does not match "
        ."false AutoCommit of $self->{_dbh}, attempting COMMIT anyway";
    $self->transaction_depth(1);
  }

  $self->next::method(@_);

  # if AutoCommit is disabled txn_depth never goes to 0
  # as a new txn is started immediately on commit
  $self->transaction_depth(1) if (
    !$self->transaction_depth
      and
    defined $self->_dbh_autocommit
      and
    ! $self->_dbh_autocommit
  );
}

sub _exec_txn_commit {
  shift->_dbh->commit;
}

sub txn_rollback {
  my $self = shift;

  $self->throw_exception("Unable to txn_rollback() on a disconnected storage")
    unless $self->_seems_connected;

  # esoteric case for folks using external $dbh handles
  if (! $self->transaction_depth and ! $self->_dbh->FETCH('AutoCommit') ) {
    carp "Storage transaction_depth 0 does not match "
        ."false AutoCommit of $self->{_dbh}, attempting ROLLBACK anyway";
    $self->transaction_depth(1);
  }

  $self->next::method(@_);

  # if AutoCommit is disabled txn_depth never goes to 0
  # as a new txn is started immediately on commit
  $self->transaction_depth(1) if (
    !$self->transaction_depth
      and
    defined $self->_dbh_autocommit
      and
    ! $self->_dbh_autocommit
  );
}

sub _exec_txn_rollback {
  shift->_dbh->rollback;
}

# The one routine that drops a handle without rolling back first: used for a
# handle whose rollback just failed and for the old handle a retry replaces.
# Not disconnect(): that would ask the handle for a rollback again.
sub _discard_dbh {
  my $self = shift;

  if (my $dbh = $self->_dbh) {
    eval {
      local $dbh->{Warn} = 0;
      %{ $dbh->{CachedKids} } = ();
      $dbh->disconnect;
      1;
    };
    $self->_dbh(undef);
  }

  $self->{transaction_depth} = 0;
  $self->savepoints([]);
  $self->deferred_rollback(undef);
}

sub _abandon_after_failed_rollback {
  shift->_discard_dbh;
}

# After a failed COMMIT DBI has AutoCommit on again, so the ROLLBACK the base
# tries (karr k372) would warn "rollback ineffective with AutoCommit enabled"
# although it is exactly what the server needs. The attempt is silenced; the
# handle's own Warn attribute is put back afterwards.
sub _abandon_after_failed_commit {
  my $self = shift;

  my $dbh = $self->_dbh;
  return $self->next::method(@_) unless $dbh;

  local $dbh->{Warn} = 0;
  return $self->next::method(@_);
}

sub _abandon_handle_before_reconnect {
  my $self = shift;

  return unless $self->_dbh;

  carp 'Retrying on a new connection: the old handle is disconnected, so that '
     . 'the block does not run a second time next to the transaction the old '
     . 'handle still holds open';

  $self->_discard_dbh;
}

# generate the DBI-specific stubs, which then fallback to ::Storage proper
quote_sub __PACKAGE__ . "::$_" => sprintf (<<'EOS', $_) for qw(svp_begin svp_release svp_rollback);
  $_[0]->throw_exception('Unable to %s() on a disconnected storage')
    unless $_[0]->_seems_connected;
  shift->next::method(@_);
EOS

# This used to be the top-half of _execute.  It was split out to make it
#  easier to override in NoBindVars without duping the rest.  It takes up
#  all of _execute's args, and emits $sql, @bind.
sub _prep_for_execute {
  #my ($self, $op, $ident, $args) = @_;
  return shift->_gen_sql_bind(@_)
}

sub _gen_sql_bind {
  my ($self, $op, $ident, $args) = @_;

  my ($colinfos, $from);
  if ( blessed($ident) ) {
    $from = $ident->from;
    $colinfos = $ident->columns_info;
  }

  my ($sql, $bind);
  ($sql, @$bind) = $self->sql_maker->$op( ($from || $ident), @$args );

  $bind = $self->_resolve_bindattrs(
    $ident, [ @{$args->[2]{bind}||[]}, @$bind ], $colinfos
  );

  if (
    ! $ENV{DBIO_DT_SEARCH_OK}
      and
    $op eq 'select'
      and
    grep {
      length ref $_->[1]
        and
      blessed($_->[1])
        and
      $_->[1]->isa('DateTime')
    } @$bind
  ) {
    carp_unique 'DateTime objects passed to search() are not supported '
      . 'properly (InflateColumn::DateTime formats and settings are not '
      . 'respected.) See ".. format a DateTime object for searching?" in '
      . 'DBIO::Manual::FAQ. To disable this warning for good '
      . 'set $ENV{DBIO_DT_SEARCH_OK} to true'
  }

  return( $sql, $bind );
}

sub _resolve_bindattrs {
  my ($self, $ident, $bind, $colinfos) = @_;

  my $resolve_bindinfo = sub {
    #my $infohash = shift;

    $colinfos ||= { %{ $self->_resolve_column_info($ident) } };

    my $ret;
    if (my $col = $_[0]->{dbic_colname}) {
      $ret = { %{$_[0]} };

      $ret->{sqlt_datatype} ||= $colinfos->{$col}{data_type}
        if $colinfos->{$col}{data_type};

      $ret->{sqlt_size} ||= $colinfos->{$col}{size}
        if $colinfos->{$col}{size};

      # the trace shows the bind of an encoded column masked
      $ret->{redact} = 1
        if $colinfos->{$col}{encode_column};
    }

    $ret || $_[0];
  };

  return [ map {
      ( ref $_ ne 'ARRAY' or @$_ != 2 ) ? [ {}, $_ ]
    : ( ! defined $_->[0] )             ? [ {}, $_->[1] ]
    : (ref $_->[0] eq 'HASH')           ? [(
                                            ! keys %{$_->[0]}
                                              or
                                            exists $_->[0]{dbd_attrs}
                                              or
                                            $_->[0]{sqlt_datatype}
                                           ) ? $_->[0]
                                             : $resolve_bindinfo->($_->[0])
                                           , $_->[1]
                                          ]
    : (ref $_->[0] eq 'SCALAR')         ? [ { sqlt_datatype => ${$_->[0]} }, $_->[1] ]
    :                                     [ $resolve_bindinfo->(
                                              { dbic_colname => $_->[0] }
                                            ), $_->[1] ]
  } @$bind ];
}

sub _format_for_trace {
  my $self = $_[0];

  ### Turn @bind from something like this:
  ###   ( [ "artist", 1 ], [ \%attrs, 3 ] )
  ### to this:
  ###   ( "'1'", "'3'" )
  ###
  ### Bind values are traced from level 2 on (DBIO_TRACE=2, debug(2)); level 1
  ### traces the statement alone. Each value is run through the
  ### L</redact_bind_value> hook before interpolation so that credential / PII
  ### columns do not leak into the trace sink, then cut to 32 characters with
  ### '...' marking the cut. The hook receives the column name (or undef if no
  ### column metadata is attached to the bind slot), the raw value and the
  ### bind attribute hash, and must return the value to interpolate.

  return () unless ($self->debug || 0) >= 2;

  my $redact = $self->redact_bind_value;

  map {
    my $val = $_ && $_->[1];
    if (defined $val) {
      my $colname = ( ref( $_->[0] ) eq 'HASH' )
        ? $_->[0]{dbic_colname}
        : undef;
      my $shown = $redact->( $colname, $val, $_->[0] );
      $shown = substr($shown, 0, 32) . '...' if length($shown) > 32;
      qq{'$shown'};
    }
    else {
      q{NULL};
    }
  } @{$_[1] || []};
}


# The statement of a connect action is traced as its fingerprint form: a secret
# it carries shows as ***[sha256:<8 hex>] (karr k343 (3), k392).
sub _trace_statement {
  my ($self, $sql) = @_;
  return defined $self->{_statement_in_flight}
    ? mask_statement_fingerprint($sql)
    : $sql;
}

sub _query_start {
  my ( $self, $sql, $bind ) = @_;
  $sql = $self->_trace_statement($sql);

  if ($self->debug) {
    my @trace = $self->_format_for_trace($bind);
    # Always pass at least one element when debug is on so that
    # Statistics::query_start produces output even for no-bind queries
    $self->debugobj->query_start($sql, @trace ? @trace : '');
  } else {
    $self->debugobj->query_start($sql);
  }
}

sub _query_end {
  my ( $self, $sql, $bind ) = @_;
  $sql = $self->_trace_statement($sql);

  $self->debugobj->query_end(
    $sql,
    $self->_format_for_trace($bind),
  );
}

sub _dbi_attrs_for_bind {
  my ($self, $ident, $bind) = @_;

  my @attrs;

  for (map { $_->[0] } @$bind) {
    push @attrs, do {
      if (exists $_->{dbd_attrs}) {
        $_->{dbd_attrs}
      }
      elsif($_->{sqlt_datatype}) {
        # cache the result in the dbh_details hash, as it can not change unless
        # we connect to something else
        my $cache = $self->_dbh_details->{_datatype_map_cache} ||= {};
        if (not exists $cache->{$_->{sqlt_datatype}}) {
          $cache->{$_->{sqlt_datatype}} = $self->bind_attribute_by_data_type($_->{sqlt_datatype}) || undef;
        }
        $cache->{$_->{sqlt_datatype}};
      }
      else {
        undef;  # always push something at this position
      }
    }
  }

  return \@attrs;
}

sub _execute {
  my ($self, $op, $ident, @args) = @_;

  my ($sql, $bind) = $self->_prep_for_execute($op, $ident, \@args);

  # not even a PID check - we do not care about the state of the _dbh.
  # All we need is to get the appropriate drivers loaded if they aren't
  # already so that the assumption in ad7c50fc26e holds
  $self->_populate_dbh unless $self->_dbh;

  $self->dbh_do( _dbh_execute =>     # retry over disconnects
    $sql,
    $bind,
    $self->_dbi_attrs_for_bind($ident, $bind),
  );
}

sub _dbh_execute {
  my ($self, $dbh, $sql, $bind, $bind_attrs) = @_;

  # for the error text of _dbi_handle_error: the statement in placeholder
  # form and the values bound to it (their number, and the values the hook
  # _mask_error_values takes out of the text of the engine)
  my ($shown_sql, $values) = $self->_error_form_of_bind($sql, $bind);
  local $self->{_exec_in_flight} = [ $shown_sql, $values ];

  $self->_query_start( $sql, $bind );

  my $sth = $self->_bind_sth_params(
    $self->_prepare_sth($dbh, $sql),
    $bind,
    $bind_attrs,
  );

  # Can this fail without throwing an exception anyways???
  my ($rv, $messages) = $self->_execute_sth($dbh, $sth);
  $self->throw_exception($self->_mask_error_values(
    $sth->errstr || $sth->err || 'Unknown error: execute() returned false, but error flags were not set...',
    _plain_error_values(@$values),
    $shown_sql,
  )) if !$rv;

  $self->_server_messages($messages);
  $self->_query_end( $sql, $bind );

  return (wantarray ? ($rv, $sth, @$bind) : $rv);
}


sub _execute_sth {
  my ($self, $dbh, $sth) = @_;
  my $rv = $sth->execute;
  return ($rv, undef);
}

# ADR 0040 section 6: the prepare-only half of _dbh_execute, for
# L</_prepare_rendered> -- everything that method does except the one verb in
# the middle.
#
# Deliberately NOT factored out of _dbh_execute. Calling this from there would
# put _query_end *before* $sth->execute, and the start/end pair is what the
# trace sink measures a statement's runtime with (DBIO::Storage::Debug::PrettyPrint
# and every profiler built on DBIO::Storage::Statistics). Three shared lines are
# cheaper than changing what a timing number on the hot path means.
sub _dbh_prepare {
  my ($self, $dbh, $sql, $bind, $bind_attrs) = @_;

  my ($shown_sql, $values) = $self->_error_form_of_bind($sql, $bind);
  local $self->{_exec_in_flight} = [ $shown_sql, $values ];

  $self->_query_start( $sql, $bind );

  my $sth = $self->_bind_sth_params(
    $self->_prepare_sth($dbh, $sql),
    $bind,
    $bind_attrs,
  );

  $self->_query_end( $sql, $bind );

  return $sth;
}

sub _prepare_sth {
  my ($self, $dbh, $sql) = @_;

  # 3 is the if_active parameter which avoids active sth re-use
  my $sth = $self->disable_sth_caching
    ? $dbh->prepare($sql)
    : $dbh->prepare_cached($sql, {}, 3);

  # XXX You would think RaiseError would make this impossible,
  #  but apparently that's not true :(
  $self->throw_exception(
    $dbh->errstr
      ||
    sprintf( "\$dbh->prepare() of '%s' through %s failed *silently* without "
            .'an exception and/or setting $dbh->errstr',
      length ($sql) > 20
        ? substr($sql, 0, 20) . '...'
        : $sql
      ,
      'DBD::' . $dbh->{Driver}{Name},
    )
  ) if !$sth;

  $sth;
}


sub _adjust_bind_values { $_[2] }

sub _bind_sth_params {
  my ($self, $sth, $bind, $bind_attrs) = @_;

  $bind = $self->_adjust_bind_values($sth, $bind, $bind_attrs);

  for my $i (0 .. $#$bind) {
    if (ref $bind->[$i][1] eq 'SCALAR') {  # any scalarrefs are assumed to be bind_inouts
      $sth->bind_param_inout(
        $i + 1, # bind params counts are 1-based
        $bind->[$i][1],
        $bind->[$i][0]{dbd_size} || $self->_max_column_bytesize($bind->[$i][0]), # size
        $bind_attrs->[$i],
      );
    }
    else {
      # FIXME SUBOPTIMAL - DBI needs fixing to always stringify regardless of DBD
      my $v = ( length ref $bind->[$i][1] and is_plain_value $bind->[$i][1] )
        ? "$bind->[$i][1]"
        : $bind->[$i][1]
      ;

      $sth->bind_param(
        $i + 1,
        # The temp-var is CRUCIAL - DO NOT REMOVE IT, breaks older DBD::SQLite RT#79576
        $v,
        $bind_attrs->[$i],
      );
    }
  }

  $sth;
}

sub _prefetch_autovalues {
  my ($self, $source, $colinfo, $to_insert) = @_;

  my %values;
  for my $col (keys %$colinfo) {
    if (
      $colinfo->{$col}{auto_nextval}
        and
      (
        ! exists $to_insert->{$col}
          or
        is_literal_value($to_insert->{$col})
      )
    ) {
      # Both methods are a driver's: one whose engine has no sequences brings
      # neither, and this class has none to fall back on. Whether they are
      # there is a fact about the class -- insert() has run the driver
      # determination by now -- so it is asked before _get_dbh below, and a
      # storage without sequences refuses without connecting (karr k302).
      if (my @missing = grep { ! $self->can($_) } (
        '_sequence_fetch',
        ( $colinfo->{$col}{sequence} ? () : '_dbh_get_autoinc_seq' ),
      )) {
        my $table = $source->name;

        $self->throw_exception( sprintf(
          "Unable to fetch a value for column '%s' of %s (table %s): it is "
        . 'marked auto_nextval, but the storage %s has no sequence support '
        . '(no %s). %s, or remove auto_nextval from its column info; for a '
        . 'GUID column see DBIO::Storage::DBI::UniqueIdentifier',
          $col,
          $source->source_name,
          ( ref $table eq 'SCALAR' ? $$table : $table ),
          ref $self,
          join(' and ', @missing),
          ( exists $to_insert->{$col}
            ? 'Literal SQL for the column does not stand in for the sequence: '
            . 'give it a plain value'
            : 'Give the column a value on insert'
          ),
        ));
      }

      $values{$col} = $self->_sequence_fetch(
        'NEXTVAL',
        ( $colinfo->{$col}{sequence} ||=
            $self->_dbh_get_autoinc_seq($self->_get_dbh, $source, $col)
        ),
      );
    }
  }

  \%values;
}

# ADR 0036: the optional $opts hashref is the atomic-upsert transport. It is
# read (and written back to) by DBIO::ResultSet::upsert only -- a plain insert
# passes nothing and behaves exactly as before.
#
#   on_conflict   => \%normalized   the structure handed on to
#                                   sql_maker->insert as $options->{on_conflict};
#                                   only a driver SQLMaker understands it, so
#                                   the storage refuses to emit it unless the
#                                   driver declares the supports_upsert
#                                   capability -- and its optional 'where' key
#                                   (the conditional DO UPDATE) unless the
#                                   driver declares supports_upsert_where too
#   no_retrieve   => 1              skip all identity retrieval (RETURNING tail,
#                                   last_insert_id, follow-up SELECT) -- one
#                                   round-trip, for result => 'void' / 'count'
#
# and on return:
#
#   affected_rows => $rv            the statement's return value
sub insert {
  my ($self, $source, $to_insert, $opts) = @_;

  my $col_infos = $source->columns_info;

  my $prefetched_values = $self->_prefetch_autovalues($source, $col_infos, $to_insert);

  # fuse the values, but keep a separate list of prefetched_values so that
  # they can be fused once again with the final return
  $to_insert = { %$to_insert, %$prefetched_values };

  my %pcols = map { $_ => 1 } $source->primary_columns;

  my (%retrieve_cols, $autoinc_supplied, $retrieve_autoinc_col, $pk_supplied);

  for my $col ($source->columns) {

    # first autoinc wins - this is why ->columns() in-order iteration is important
    #
    # FIXME - there ought to be a sanity-check for multiple is_auto_increment settings
    # or something...
    #
    if ($col_infos->{$col}{is_auto_increment}) {

      # FIXME - we seem to assume undef values as non-supplied.
      # This is wrong.
      # Investigate what does it take to s/defined/exists/
      # ( fails t/cdbi/copy.t amoong other things )
      $autoinc_supplied ||= 1 if defined $to_insert->{$col};

      $retrieve_autoinc_col ||= $col unless $autoinc_supplied;
    }

    # Track if any primary key column has a supplied value (including scalar references)
    if ($pcols{$col}) {
      $pk_supplied ||= 1 if (
        defined $to_insert->{$col}
          and
        (
          # not a ref - cheaper to check before a call to is_literal_value()
          ! length ref $to_insert->{$col}
            or
          # is a literal value (like scalar references for database functions)
          is_literal_value( $to_insert->{$col} )
        )
      );
    }

    # nothing to retrieve when explicit values are supplied
    next if (
      # FIXME - we seem to assume undef values as non-supplied.
      # This is wrong.
      # Investigate what does it take to s/defined/exists/
      # ( fails t/cdbi/copy.t amoong other things )
      defined $to_insert->{$col}
        and
      (
        # not a ref - cheaper to check before a call to is_literal_value()
        ! length ref $to_insert->{$col}
          or
        # not a literal we *MAY* need to pull out ( see check below )
        ! is_literal_value( $to_insert->{$col} )
      )
    );

    # the 'scalar keys' is a trick to preserve the ->columns declaration order
    $retrieve_cols{$col} = scalar keys %retrieve_cols if (
      $pcols{$col}
        or
      $col_infos->{$col}{retrieve_on_insert}
    );
  };

  # An upsert asking for result => 'void' / 'count' wants exactly one
  # round-trip and no identity work (ADR 0036 section 4).
  if ($opts and $opts->{no_retrieve}) {
    %retrieve_cols = ();
    undef $retrieve_autoinc_col;
  }

  # corner case of a non-supplied PK which is *not* declared as autoinc
  if (
    ! $autoinc_supplied
      and
    ! defined $retrieve_autoinc_col
      and
    ! $pk_supplied
      and
    # FIXME - first come-first serve, suboptimal...
    ($retrieve_autoinc_col) = ( grep
      {
        $pcols{$_}
          and
        ! $col_infos->{$_}{retrieve_on_insert}
          and
        ! defined $col_infos->{$_}{is_auto_increment}
      }
      sort
        { $retrieve_cols{$a} <=> $retrieve_cols{$b} }
        keys %retrieve_cols
    )
  ) {
    carp_unique(
      "Missing value for primary key column '$retrieve_autoinc_col' on "
    . "@{[ $source->source_name ]} - perhaps you forgot to set its "
    . "'is_auto_increment' attribute during add_columns()? Treating "
    . "'$retrieve_autoinc_col' implicitly as an autoinc, and attempting "
    . 'value retrieval'
    );
  }

  local $self->{_autoinc_supplied_for_op} = $autoinc_supplied;
  local $self->{_perform_autoinc_retrieval} = $retrieve_autoinc_col;

  my ($sqla_opts, @ir_container);
  if (%retrieve_cols and $self->_use_insert_returning) {
    $sqla_opts->{returning_container} = \@ir_container
      if $self->_use_insert_returning_bound;

    $sqla_opts->{returning} = [
      sort { $retrieve_cols{$a} <=> $retrieve_cols{$b} } keys %retrieve_cols
    ];
  }

  # ADR 0036: the conflict clause rides the same options transport as
  # RETURNING. The base SQLMaker does not understand it, so a driver that has
  # not declared the capability must never be handed the structure.
  if (my $on_conflict = $opts ? $opts->{on_conflict} : undef) {
    $self->throw_exception(
      sprintf(
        "%s does not declare the supports_upsert capability -- refusing to "
      . "emit an ON CONFLICT clause its SQL generator cannot render",
        ref $self,
      )
    ) unless $self->_use_supports_upsert;

    # The conditional conflict branch is the one part of the structure a
    # driver can drop without any symptom: the statement stays valid and
    # writes unconditionally, i.e. it does the overwrite the condition was
    # written to prevent. Hence its own capability (ADR 0036 section 3).
    $self->throw_exception(
      sprintf(
        "%s does not declare the supports_upsert_where capability -- refusing "
      . "to emit a conditional DO UPDATE its SQL generator would silently "
      . "drop, leaving an unconditional overwrite",
        ref $self,
      )
    ) if defined $on_conflict->{where} and ! $self->_use_supports_upsert_where;

    $sqla_opts->{on_conflict} = $on_conflict;
  }

  my ($rv, $sth) = $self->_execute('insert', $source, $to_insert, $sqla_opts);

  $opts->{affected_rows} = $rv if $opts;

  my %returned_cols = %$to_insert;
  if (my $retlist = $sqla_opts->{returning}) {  # if IR is supported - we will get everything in one set

    unless( @ir_container ) {
      try {

        # FIXME - need to investigate why Caelum silenced this in 4d4dc518
        local $SIG{__WARN__} = sub {};

        @ir_container = $sth->fetchrow_array;
        $sth->finish;

      } catch {
        # Evict the $sth from the cache in case we got here, since the finish()
        # is crucial, at least on older Firebirds, possibly on other engines too
        #
        # It would be too complex to make this a proper subclass override,
        # and besides we already take the try{} penalty, adding a catch that
        # triggers infrequently is a no-brainer
        #
        if( my $kids = $self->_dbh->{CachedKids} ) {
          $kids->{$_} == $sth and delete $kids->{$_}
            for keys %$kids
        }
      };
    }

    @returned_cols{@$retlist} = @ir_container if @ir_container;
  }
  else {
    # pull in PK if needed and then everything else
    if (my @missing_pri = grep { $pcols{$_} } keys %retrieve_cols) {

      $self->throw_exception( "Missing primary key but Storage doesn't support last_insert_id" )
        unless $self->can('last_insert_id');

      my @pri_values = $self->last_insert_id($source, @missing_pri);

      $self->throw_exception( "Can't get last insert id" )
        unless (@pri_values == @missing_pri);

      @returned_cols{@missing_pri} = @pri_values;
      delete @retrieve_cols{@missing_pri};
    }

    # if there is more left to pull
    if (%retrieve_cols) {
      $self->throw_exception(
        'Unable to retrieve additional columns without a Primary Key on ' . $source->source_name
      ) unless %pcols;

      my @left_to_fetch = sort { $retrieve_cols{$a} <=> $retrieve_cols{$b} } keys %retrieve_cols;

      my $cur = DBIO::ResultSet->new($source, {
        where => { map { $_ => $returned_cols{$_} } (keys %pcols) },
        select => \@left_to_fetch,
      })->cursor;

      @returned_cols{@left_to_fetch} = $cur->next;

      $self->throw_exception('Duplicate row returned for PK-search after fresh insert')
        if scalar $cur->next;
    }
  }

  return { %$prefetched_values, %returned_cols };
}

sub insert_bulk {
  carp_unique(
    'insert_bulk() should have never been exposed as a public method and '
  . 'calling it is depecated as of Aug 2014. If you believe having a genuine '
  . 'use for this method please contact the development team via '
  . help_url()
  );

  return '0E0' unless @{$_[3]||[]};

  shift->_insert_bulk(@_);
}

sub _insert_bulk {
  my ($self, $source, $cols, $data) = @_;

  $self->throw_exception('Calling _insert_bulk without a dataset to process makes no sense')
    unless @{$data||[]};

  my $colinfos = $source->columns_info($cols);

  local $self->{_autoinc_supplied_for_op} =
    (grep { $_->{is_auto_increment} } values %$colinfos)
      ? 1
      : 0
  ;

  # get a slice type index based on first row of data
  # a "column" in this context may refer to more than one bind value
  # e.g. \[ '?, ?', [...], [...] ]
  #
  # construct the value type index - a description of values types for every
  # per-column slice of $data:
  #
  # nonexistent - nonbind literal
  # 0 - regular value
  # [] of bindattrs - resolved attribute(s) of bind(s) passed via literal+bind \[] combo
  #
  # also construct the column hash to pass to the SQL generator. For plain
  # (non literal) values - convert the members of the first row into a
  # literal+bind combo, with extra positional info in the bind attr hashref.
  # This will allow us to match the order properly, and is so contrived
  # because a user-supplied literal/bind (or something else specific to a
  # resultsource and/or storage driver) can inject extra binds along the
  # way, so one can't rely on "shift positions" ordering at all. Also we
  # can't just hand SQLMaker a set of some known "values" (e.g. hashrefs that
  # can be later matched up by address), because we want to supply a real
  # value on which perhaps e.g. datatype checks will be performed
  my ($proto_data, $serialized_bind_type_by_col_idx);
  for my $col_idx (0..$#$cols) {
    my $colname = $cols->[$col_idx];
    if (ref $data->[0][$col_idx] eq 'SCALAR') {
      # no bind value at all - no type

      $proto_data->{$colname} = $data->[0][$col_idx];
    }
    elsif (ref $data->[0][$col_idx] eq 'REF' and ref ${$data->[0][$col_idx]} eq 'ARRAY' ) {
      # repack, so we don't end up mangling the original \[]
      my ($sql, @bind) = @${$data->[0][$col_idx]};

      # normalization of user supplied stuff
      my $resolved_bind = $self->_resolve_bindattrs(
        $source, \@bind, $colinfos,
      );

      # store value-less (attrs only) bind info - we will be comparing all
      # supplied binds against this for sanity
      $serialized_bind_type_by_col_idx->{$col_idx} = serialize [ map { $_->[0] } @$resolved_bind ];

      $proto_data->{$colname} = \[ $sql, map { [
        # inject slice order to use for $proto_bind construction
          { %{$resolved_bind->[$_][0]}, _bind_data_slice_idx => $col_idx, _literal_bind_subindex => $_+1 }
            =>
          $resolved_bind->[$_][1]
        ] } (0 .. $#bind)
      ];
    }
    else {
      $serialized_bind_type_by_col_idx->{$col_idx} = undef;

      $proto_data->{$colname} = \[ '?', [
        { dbic_colname => $colname, _bind_data_slice_idx => $col_idx }
          =>
        $data->[0][$col_idx]
      ] ];
    }
  }

  my ($sql, $proto_bind) = $self->_prep_for_execute (
    'insert',
    $source,
    [ $proto_data ],
  );

  if (! @$proto_bind and keys %$serialized_bind_type_by_col_idx) {
    # if the bindlist is empty and we had some dynamic binds, this means the
    # storage ate them away (e.g. the NoBindVars component) and interpolated
    # them directly into the SQL. This obviously can't be good for multi-inserts
    $self->throw_exception('Unable to invoke fast-path insert without storage placeholder support');
  }

  # sanity checks
  # FIXME - devise a flag "no babysitting" or somesuch to shut this off
  #
  # use an error reporting closure for convenience (less to pass)
  my $bad_slice_report_cref = sub {
    my ($msg, $r_idx, $c_idx) = @_;
    # the row and the columns, never a value (ADR 0075)
    $self->throw_exception(sprintf
      "%s for column '%s' in row %d of the populate data (columns: %s)",
      $msg,
      $cols->[$c_idx],
      $r_idx + 1,
      join(', ', @$cols),
    );
  };

  for my $col_idx (0..$#$cols) {
    my $reference_val = $data->[0][$col_idx];

    for my $row_idx (1..$#$data) {  # we are comparing against what we got from [0] above, hence start from 1
      my $val = $data->[$row_idx][$col_idx];

      if (! exists $serialized_bind_type_by_col_idx->{$col_idx}) { # literal no binds
        if (ref $val ne 'SCALAR') {
          $bad_slice_report_cref->(
            "Incorrect value (expecting SCALAR-ref \\'$$reference_val')",
            $row_idx,
            $col_idx,
          );
        }
        elsif ($$val ne $$reference_val) {
          $bad_slice_report_cref->(
            "Inconsistent literal SQL value (expecting \\'$$reference_val')",
            $row_idx,
            $col_idx,
          );
        }
      }
      elsif (! defined $serialized_bind_type_by_col_idx->{$col_idx} ) {  # regular non-literal value
        if (is_literal_value($val)) {
          $bad_slice_report_cref->("Literal SQL found where a plain bind value is expected", $row_idx, $col_idx);
        }
      }
      else {  # binds from a \[], compare type and attrs
        if (ref $val ne 'REF' or ref $$val ne 'ARRAY') {
          $bad_slice_report_cref->(
            "Incorrect value (expecting ARRAYREF-ref \\['${$reference_val}->[0]', ... ])",
            $row_idx,
            $col_idx,
          );
        }
        # start drilling down and bail out early on identical refs
        elsif (
          $reference_val != $val
            or
          $$reference_val != $$val
        ) {
          if (${$val}->[0] ne ${$reference_val}->[0]) {
            $bad_slice_report_cref->(
              "Inconsistent literal/bind SQL (expecting \\['${$reference_val}->[0]', ... ])",
              $row_idx,
              $col_idx,
            );
          }
          # need to check the bind attrs - a bind will happen only once for
          # the entire dataset, so any changes further down will be ignored.
          elsif (
            $serialized_bind_type_by_col_idx->{$col_idx}
              ne
            serialize [
              map
              { $_->[0] }
              @{$self->_resolve_bindattrs(
                $source, [ @{$$val}[1 .. $#$$val] ], $colinfos,
              )}
            ]
          ) {
            $bad_slice_report_cref->(
              'Differing bind attributes on literal/bind values not supported',
              $row_idx,
              $col_idx,
            );
          }
        }
      }
    }
  }

  # neither _dbh_execute_for_fetch, nor _dbh_execute_inserts_with_no_binds
  # are atomic (even if execute_for_fetch is a single call). Thus a safety
  # scope guard
  my $guard = $self->txn_scope_guard;

  $self->_query_start( $sql, @$proto_bind ? [[undef => '__BULK_INSERT__' ]] : () );
  my $sth = $self->_prepare_sth($self->_dbh, $sql);
  my $rv = do {
    if (@$proto_bind) {
      # proto bind contains the information on which pieces of $data to pull
      # $cols is passed in only for prettier error-reporting
      $self->_dbh_execute_for_fetch( $source, $sth, $proto_bind, $cols, $data );
    }
    else {
      # bind_param_array doesn't work if there are no binds
      $self->_dbh_execute_inserts_with_no_binds( $sth, scalar @$data );
    }
  };

  $self->_query_end( $sql, @$proto_bind ? [[ undef => '__BULK_INSERT__' ]] : () );

  $guard->commit;

  return wantarray ? ($rv, $sth, @$proto_bind) : $rv;
}

# execute_for_fetch is capable of returning data just fine (it means it
# can be used for INSERT...RETURNING and UPDATE...RETURNING. Since this
# is the void-populate fast-path we will just ignore this altogether
# for the time being.
sub _dbh_execute_for_fetch {
  my ($self, $source, $sth, $proto_bind, $cols, $data) = @_;

  # If we have any bind attributes to take care of, we will bind the
  # proto-bind data (which will never be used by execute_for_fetch)
  # However since column bindtypes are "sticky", this is sufficient
  # to get the DBD to apply the bindtype to all values later on.
  # Only the attributes stay this way; the values of each row are run
  # through _adjust_bind_values below, as _bind_sth_params does
  my $bind_attrs = $self->_dbi_attrs_for_bind($source, $proto_bind);

  for my $i (0 .. $#$proto_bind) {
    $sth->bind_param (
      $i+1, # DBI bind indexes are 1-based
      $proto_bind->[$i][1],
      $bind_attrs->[$i],
    ) if defined $bind_attrs->[$i];
  }

  # At this point $data slots named in the _bind_data_slice_idx of
  # each piece of $proto_bind are either \[]s or plain values to be
  # passed in. Construct the dispensing coderef. *NOTE* the order
  # of $data will differ from this of the ?s in the SQL (due to
  # alphabetical ordering by colname). We actually do want to
  # preserve this behavior so that prepare_cached has a better
  # chance of matching on unrelated calls

  my $fetch_row_idx = -1; # saner loop this way
  my $fetch_tuple = sub {
    return undef if ++$fetch_row_idx > $#$data;

    my $row_bind = [ map {
      [
        $_,
        ! defined $_->{_literal_bind_subindex}

          ? $data->[ $fetch_row_idx ]->[ $_->{_bind_data_slice_idx} ]

          # There are no attributes to resolve here - we already did everything
          # when we constructed proto_bind. However we still want to sanity-check
          # what the user supplied, so pass stuff through to the resolver *anyway*
          : $self->_resolve_bindattrs (
              undef,  # a fake rsrc
              [ ${ $data->[ $fetch_row_idx ]->[ $_->{_bind_data_slice_idx} ]}->[ $_->{_literal_bind_subindex} ] ],
              {},     # a fake column_info bag
            )->[0][1]
      ]
    } map { $_->[0] } @$proto_bind ];

    return [ map {
      my $v = $_->[1];

      # FIXME SUBOPTIMAL - DBI needs fixing to always stringify regardless of DBD
      # For the time being forcibly stringify whatever is stringifiable
      (length ref $v and is_plain_value $v)
        ? "$v"
        : $v
      ;
    } @{ $self->_adjust_bind_values($sth, $row_bind, $bind_attrs) } ];
  };

  my $tuple_status = [];
  my ($rv, $err);
  {
    # an error the handle reports while the rows run is masked with the
    # values of every row: which row it is, the handle does not say
    local $self->{_values_in_flight} = [ map { $self->_populate_row_values($_) } @$data ];

    try {
      $rv = $sth->execute_for_fetch(
        $fetch_tuple,
        $tuple_status,
      );
    }
    catch {
      $err = shift;
    };
  }

  # Not all DBDs are create equal. Some throw on error, some return
  # an undef $rv, and some set $sth->err - try whatever we can
  $err = ($sth->errstr || 'UNKNOWN ERROR ($sth->errstr is unset)') if (
    ! defined $err
      and
    ( !defined $rv or $sth->err )
  );

  # Statement must finish even if there was an exception.
  try {
    $sth->finish
  }
  catch {
    $err = shift unless defined $err
  };

  if (defined $err) {
    my $i = 0;
    ++$i while $i <= $#$tuple_status && !ref $tuple_status->[$i];

    # the engine text loses the values of the row that failed; where no
    # row is known, those of every row (ADR 0075)
    my $values = _plain_error_values(
      $i > $#$tuple_status
        ? ( map { $self->_populate_row_values($_) } @$data )
        : $self->_populate_row_values($data->[$i])
    );

    $self->throw_exception(
      'Unexpected populate error: '
      . $self->_mask_error_values("$err", $values, undef)
    ) if ($i > $#$tuple_status);

    $self->throw_exception(sprintf
      "execute_for_fetch() aborted with '%s' at row %d of the populate data (columns: %s)",
      $self->_mask_error_values(
        '' . ($tuple_status->[$i][1] || $err), $values, undef,
      ),
      $i + 1,
      join(', ', @$cols),
    );
  }

  return $rv;
}

# The values a row of populate data binds, raw: a plain cell is its own value,
# a \[ $sql, @bind ] cell holds the values of its binds, a literal \$sql none.
sub _populate_row_values {
  my ($self, $row) = @_;

  return map {
    ( ref $_ eq 'REF' and ref $$_ eq 'ARRAY' )
      ? ( map { ref $_ eq 'ARRAY' && @$_ == 2 ? $_->[1] : $_ } @{$$_}[ 1 .. $#{$$_} ] )
      : ref $_ eq 'SCALAR' ? ()
      : $_
  } @{ $row || [] };
}

sub _dbh_execute_inserts_with_no_binds {
  my ($self, $sth, $count) = @_;

  my $err;
  try {
    my $dbh = $self->_get_dbh;
    local $dbh->{RaiseError} = 1;
    local $dbh->{PrintError} = 0;

    $sth->execute foreach 1..$count;
  }
  catch {
    $err = shift;
  };

  # Make sure statement is finished even if there was an exception.
  try {
    $sth->finish
  }
  catch {
    $err = shift unless defined $err;
  };

  # the statements carry no bound value; the hook is asked all the same, a
  # driver's own rules apply to the text of the engine
  $self->throw_exception(
    ref $err ? $err : $self->_mask_error_values($err, [], undef)
  ) if defined $err;

  return $count;
}

sub update {
  #my ($self, $source, @args) = @_;
  shift->_execute('update', @_);
}


sub delete {
  #my ($self, $source, @args) = @_;
  shift->_execute('delete', @_);
}

sub _select {
  my $self = shift;
  $self->_execute($self->_select_args(@_));
}

sub _select_args_to_query {
  my $self = shift;

  $self->throw_exception(
    "Unable to generate limited query representation with 'software_limit' enabled"
  ) if ($_[3]->{software_limit} and ($_[3]->{offset} or $_[3]->{rows}) );

  # my ($op, $ident, $select, $cond, $rs_attrs, $rows, $offset)
  #  = $self->_select_args($ident, $select, $cond, $attrs);
  my ($op, $ident, @args) =
    $self->_select_args(@_);

  # my ($sql, $prepared_bind) = $self->_gen_sql_bind($op, $ident, [ $select, $cond, $rs_attrs, $rows, $offset ]);
  my ($sql, $bind) = $self->_gen_sql_bind($op, $ident, \@args);

  # reuse the bind arrayref
  unshift @{$bind}, "($sql)";
  \$bind;
}

sub _select_args {
  my ($self, $ident, $select, $where, $orig_attrs) = @_;

  # FIXME - that kind of caching would be nice to have
  # however currently we *may* pass the same $orig_attrs
  # with different ident/select/where
  # the whole interface needs to be rethought, since it
  # was centered around the flawed SQLMaker API. We can do
  # soooooo much better now. But that is also another
  # battle...
  #return (
  #  'select', $orig_attrs->{!args_as_stored_at_the_end_of_this_method!}
  #) if $orig_attrs->{!args_as_stored_at_the_end_of_this_method!};

  my $sql_maker = $self->sql_maker;

  my $attrs = {
    %$orig_attrs,
    select => $select,
    from => $ident,
    where => $where,
  };

  # Sanity check the attributes (SQLMaker does it too, but
  # in case of a software_limit we'll never reach there)
  if (defined $attrs->{offset}) {
    $self->throw_exception('A supplied offset attribute must be a non-negative integer')
      if ( $attrs->{offset} =~ /\D/ or $attrs->{offset} < 0 );
  }

  if (defined $attrs->{rows}) {
    $self->throw_exception("The rows attribute must be a positive integer if present")
      if ( $attrs->{rows} =~ /\D/ or $attrs->{rows} <= 0 );
  }
  elsif ($attrs->{offset}) {
    # MySQL actually recommends this approach.  I cringe.
    $attrs->{rows} = $sql_maker->__max_int;
  }

  # see if we will need to tear the prefetch apart to satisfy group_by == select
  # this is *extremely tricky* to get right, I am still not sure I did
  #
  my ($prefetch_needs_subquery, @limit_args);

  if ( $attrs->{_grouped_by_distinct} and $attrs->{collapse} ) {
    # we already know there is a valid group_by (we made it) and we know it is
    # intended to be based *only* on non-multi stuff
    # short circuit the group_by parsing below
    $prefetch_needs_subquery = 1;
  }
  elsif (
    # The rationale is that even if we do *not* have collapse, we still
    # need to wrap the core grouped select/group_by in a subquery
    # so that databases that care about group_by/select equivalence
    # are happy (this includes MySQL in strict_mode)
    # If any of the other joined tables are referenced in the group_by
    # however - the user is on their own
    ( $prefetch_needs_subquery or ! $attrs->{_simple_passthrough_construction} )
      and
    $attrs->{group_by}
      and
    @{$attrs->{group_by}}
      and
    my $grp_aliases = try { # try{} because $attrs->{from} may be unreadable
      $self->_resolve_aliastypes_from_select_args({ from => $attrs->{from}, group_by => $attrs->{group_by} })
    }
  ) {
    # no aliases other than our own in group_by
    # if there are - do not allow subquery even if limit is present
    $prefetch_needs_subquery = ! scalar grep { $_ ne $attrs->{alias} } keys %{ $grp_aliases->{grouping} || {} };
  }
  elsif ( $attrs->{rows} && $attrs->{collapse} ) {
    # active collapse with a limit - that one is a no-brainer unless
    # overruled by a group_by above
    $prefetch_needs_subquery = 1;
  }

  if ($prefetch_needs_subquery) {
    $attrs = $self->_adjust_select_args_for_complex_prefetch ($attrs);
  }
  elsif (! $attrs->{software_limit} ) {
    push @limit_args, (
      $attrs->{rows} || (),
      $attrs->{offset} || (),
    );
  }

  # try to simplify the joinmap further (prune unreferenced type-single joins)
  if (
    ! $prefetch_needs_subquery  # already pruned
      and
    ref $attrs->{from}
      and
    reftype $attrs->{from} eq 'ARRAY'
      and
    @{$attrs->{from}} != 1
  ) {
    ($attrs->{from}, $attrs->{_aliastypes}) = $self->_prune_unused_joins ($attrs);
  }

  # FIXME this is a gross, inefficient, largely incorrect and fragile hack
  # during the result inflation stage we *need* to know what was the aliastype
  # map as sqla saw it when the final pieces of SQL were being assembled
  # Originally we simply carried around the entirety of $attrs, but this
  # resulted in resultsets that are being reused growing continuously, as
  # the hash in question grew deeper and deeper.
  # Instead hand-pick what to take with us here (we actually don't need much
  # at this point just the map itself)
  $orig_attrs->{_last_sqlmaker_alias_map} = $attrs->{_aliastypes};

###
  #   my $alias2source = $self->_resolve_ident_sources ($ident);
  #
  # This would be the point to deflate anything found in $attrs->{where}
  # (and leave $attrs->{bind} intact). Problem is - inflators historically
  # expect a result object. And all we have is a resultsource (it is trivial
  # to extract deflator coderefs via $alias2source above).
  #
  # I don't see a way forward other than changing the way deflators are
  # invoked, and that's just bad...
###

  return ( 'select', @{$attrs}{qw(from select where)}, $attrs, @limit_args );
}

# Returns a counting SELECT for a simple count
# query. Abstracted so that a storage could override
# this to { count => 'firstcol' } or whatever makes
# sense as a performance optimization
sub _count_select {
  #my ($self, $source, $rs_attrs) = @_;
  return { count => '*' };
}


sub select {
  my $self = shift;
  my ($ident, $select, $condition, $attrs) = @_;
  return $self->cursor_class->new($self, \@_, $attrs);
}

sub select_single {
  my $self = shift;
  my ($rv, $sth, @bind) = $self->_select(@_);
  my @row = $sth->fetchrow_array;
  my @nextrow = $sth->fetchrow_array if @row;
  if(@row && @nextrow) {
    carp "Query returned more than one row.  SQL that returns multiple rows is DEPRECATED for ->find and ->single";
  }
  # Need to call finish() to work round broken DBDs
  $sth->finish();
  return @row;
}

sub _dbh_columns_info_for {
  my ($self, $dbh, $table) = @_;

  if ($dbh->can('column_info')) {
    my %result;
    my $caught;
    try {
      my ($schema,$tab) = $table =~ /^(.+?)\.(.+)$/ ? ($1,$2) : (undef,$table);
      my $sth = $dbh->column_info( undef,$schema, $tab, '%' );
      $sth->execute();
      while ( my $info = $sth->fetchrow_hashref() ){
        my %column_info;
        $column_info{data_type}   = $info->{TYPE_NAME};
        $column_info{size}      = $info->{COLUMN_SIZE};
        $column_info{is_nullable}   = $info->{NULLABLE} ? 1 : 0;
        $column_info{default_value} = $info->{COLUMN_DEF};
        my $col_name = $info->{COLUMN_NAME};
        $col_name =~ s/^\"(.*)\"$/$1/;

        $result{$col_name} = \%column_info;
      }
    } catch {
      $caught = 1;
    };
    return \%result if !$caught && scalar keys %result;
  }

  my %result;
  my $sth = $dbh->prepare($self->sql_maker->select($table, undef, \'1 = 0'));
  $sth->execute;
  my @columns = @{$sth->{NAME_lc}};
  for my $i ( 0 .. $#columns ){
    my %column_info;
    $column_info{data_type} = $sth->{TYPE}->[$i];
    $column_info{size} = $sth->{PRECISION}->[$i];
    $column_info{is_nullable} = $sth->{NULLABLE}->[$i] ? 1 : 0;

    if ($column_info{data_type} =~ m/^(.*?)\((.*?)\)$/) {
      $column_info{data_type} = $1;
      $column_info{size}    = $2;
    }

    $result{$columns[$i]} = \%column_info;
  }
  $sth->finish;

  foreach my $col (keys %result) {
    my $colinfo = $result{$col};
    my $type_num = $colinfo->{data_type};
    my $type_name;
    if(defined $type_num && $dbh->can('type_info')) {
      my $type_info = $dbh->type_info($type_num);
      $type_name = $type_info->{TYPE_NAME} if $type_info;
      $colinfo->{data_type} = $type_name if $type_name;
    }
  }

  return \%result;
}

sub columns_info_for {
  my ($self, $table) = @_;
  $self->_dbh_columns_info_for ($self->_get_dbh, $table);
}


sub _dbh_last_insert_id {
    my ($self, $dbh, $source, $col) = @_;

    my $id = try { $dbh->last_insert_id (undef, undef, $source->name, $col) };

    return $id if defined $id;

    my $class = ref $self;
    $self->throw_exception ("No storage specific _dbh_last_insert_id() method implemented in $class, and the generic DBI::last_insert_id() failed");
}

sub last_insert_id {
  my $self = shift;
  $self->_dbh_last_insert_id ($self->_dbh, @_);
}


sub _random_function { 'RANDOM()' }


sub _explain_query {
  my ($self, $sql, $bind) = @_;

  my (undef, $sth) = $self->_execute_rendered("EXPLAIN $sql", $bind);

  return $sth->fetchall_arrayref;
}


sub _exists_value_sql { "SELECT CASE WHEN EXISTS $_[1] THEN 1 ELSE 0 END" }


my %SET_OPERATION_KEYWORD = (
  union         => 'UNION',
  union_all     => 'UNION ALL',
  intersect     => 'INTERSECT',
  intersect_all => 'INTERSECT ALL',
  except        => 'EXCEPT',
  except_all    => 'EXCEPT ALL',
);

sub _set_operation_keyword {
  my ($self, $op) = @_;

  my $keyword = defined $op ? $SET_OPERATION_KEYWORD{$op} : undef;

  $self->throw_exception(
    "Unknown set operation '" . (defined $op ? $op : '(undef)') . "' -- "
  . 'valid operations are: ' . join(', ', sort keys %SET_OPERATION_KEYWORD)
  ) unless defined $keyword;

  return $keyword;
}


sub _execute_rendered {
  my ($self, $sql, $bind) = @_;

  ($sql, $bind) = $self->_prep_rendered_for_execute($sql, $bind);

  $self->_populate_dbh unless $self->_dbh;

  $self->dbh_do( _dbh_execute =>     # retry over disconnects
    $sql,
    $bind,
    $self->_dbi_attrs_for_bind(undef, $bind),
  );
}


sub _prepare_rendered {
  my ($self, $sql, $bind) = @_;

  ($sql, $bind) = $self->_prep_rendered_for_execute($sql, $bind);

  $self->_populate_dbh unless $self->_dbh;

  my $sth = $self->dbh_do( _dbh_prepare =>    # retry over disconnects
    $sql,
    $bind,
    $self->_dbi_attrs_for_bind(undef, $bind),
  );

  return $sth;
}


sub _prep_rendered_for_execute { return ($_[1], $_[2]) }

# Check if placeholders are supported at all
sub _determine_supports_placeholders {
  my $self = shift;
  my $dbh  = $self->_get_dbh;

  # some drivers provide a $dbh attribute (e.g. Sybase and $dbh->{syb_dynamic_supported})
  # but it is inaccurate more often than not
  return try {
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 1;
    $dbh->do('select ?', {}, 1);
    1;
  }
  catch {
    0;
  };
}

# Check if placeholders bound to non-string types throw exceptions
#
sub _determine_supports_typeless_placeholders {
  my $self = shift;
  my $dbh  = $self->_get_dbh;

  return try {
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 1;
    # this specifically tests a bind that is NOT a string
    $dbh->do('select 1 where 1 = ?', {}, 1);
    1;
  }
  catch {
    0;
  };
}


sub sqlt_type {
  shift->_get_dbh->{Driver}->{Name};
}


sub bind_attribute_by_data_type {
    return;
}


sub is_datatype_numeric {
  #my ($self, $dt) = @_;

  return 0 unless $_[1];

  $_[1] =~ /^ (?:
    numeric | int(?:eger)? | (?:tiny|small|medium|big)int | dec(?:imal)? | real | float | double (?: \s+ precision)? | (?:big)?serial
  ) $/ix;
}



sub create_ddl_dir {
  my ($self, $schema, $databases, $version, $dir, $preversion, $sqltargs) = @_;
  $self->throw_exception("create_ddl_dir() is deprecated. "
    . "Use the native Deploy class on your storage instead.");
}


sub deployment_statements {
  my ($self, $schema, $type, $version, $dir, $sqltargs) = @_;
  $type ||= $self->sqlt_type;
  $version ||= $schema->schema_version || '1.x';
  $dir ||= './';
  my $filename = $schema->ddl_filename($type, $version, $dir);
  if(-f $filename)
  {
      # FIXME replace this block when a proper sane sql parser is available
      my $file;
      open($file, '<', $filename)
        or $self->throw_exception("Can't open $filename ($!)");
      my @rows = <$file>;
      close($file);
      return join('', @rows);
  }

  $self->throw_exception("deployment_statements() requires a pre-existing DDL file; "
    . "native Deploy classes handle SQL generation. "
    . "Use \$schema->deploy with a storage that provides a native Deploy class.");
}


sub deploy_defaults { () }


sub deploy_setup { }


# FIXME deploy() currently does not accurately report sql errors
# Will always return true while errors are warned
sub deploy {
  my ($self, $schema, $type, $sqltargs, $dir) = @_;

  if (blessed($schema) and $schema->isa('DBIO::Schema')) {
    # driver determination decides which dbio_deploy_class answers
    $self->ensure_connected;
    if ($self->can('dbio_deploy_class')
        and my $deploy_class = $self->dbio_deploy_class) {
      $self->ensure_class_loaded($deploy_class);
      return $deploy_class->new(
        schema => $schema, DBIO::Deploy::Base->deploy_args($sqltargs),
      )->install;
    }
  }

  my $deploy = sub {
    my $line = shift;
    return if(!$line);
    return if($line =~ /^--/);
    # next if($line =~ /^DROP/m);
    return if($line =~ /^BEGIN TRANSACTION/m);
    return if($line =~ /^COMMIT/m);
    return if $line =~ /^\s+$/; # skip whitespace only
    $self->_query_start($line);
    # a statement that fails ends the deploy, as in Deploy::Base::_execute_ddl
    $self->dbh_do (sub { $_[1]->do($line) });
    $self->_query_end($line);
  };
  my @statements = $schema->deployment_statements($type, undef, $dir, { %{ $sqltargs || {} }, no_comments => 1 } );
  if (@statements > 1) {
    foreach my $statement (@statements) {
      $deploy->( $statement );
    }
  }
  elsif (@statements == 1) {
    # split on single line comments and end of statements
    foreach my $line ( split(/\s*--.*\n|;\n/, $statements[0])) {
      $deploy->( $line );
    }
  }
}


sub datetime_parser {
  my $self = shift;
  return $self->{datetime_parser} ||= do {
    $self->build_datetime_parser(@_);
  };
}


sub build_datetime_parser {
  my $self = shift;
  my $type = $self->datetime_parser_type(@_);
  return $type;
}



sub is_replicating {
    return;

}


sub lag_behind_master {
    return;
}


sub relname_to_table_alias {
  my ($self, $relname, $join_count) = @_;

  my $alias = ($join_count && $join_count > 1 ?
    join('_', $relname, $join_count) : $relname);

  return $alias;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI - DBI storage handler

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  my $schema = MySchema->connect('dbi:SQLite:my.db');

  $schema->storage->debug(1);

  my @stuff = $schema->storage->dbh_do(
    sub {
      my ($storage, $dbh, @args) = @_;
      $dbh->do("DROP TABLE authors");
    },
    @column_list
  );

  my $rs = $schema->resultset('Book')->search({
     written_on => $schema->storage->datetime_parser->format_datetime(DateTime->now)
  });

See F<t/test/04_query_capture.t> for a runnable example.

=head1 DESCRIPTION

This is DBIO's common storage backend for L<DBI>-based databases. It owns the
live database handle, transaction state, SQL maker integration, and driver
determination.

A schema declares its driver (L<DBIO::Schema/storage_type>, pinned by the
driver's component or shortcut), so its storage is the driver's base class
from the start -- L<DBIO::PostgreSQL::Storage>, L<DBIO::MySQL::Storage>,
L<DBIO::SQLite::Storage>. At the first use that needs the driver it adapts
itself to the access path of the connection (L</_adapt_to_access_path>) and
stays within its driver; what does not fit is reported through
L</_driver_mismatch>. This generic class itself has no driver: a schema
whose storage would be of it is refused at connect, and a storage of it built
by hand is refused at the first use that needs the driver (ADR 0067). Which
driver a DSN leads to is answered by L<DBIO/driver_for>.

See L<DBIO::Storage> for the storage API shared across all backends. This POD
focuses on the DBI-specific layer, including connection handling, capability
checks, and the hooks that driver subclasses build on.

=head1 METHODS

=head2 connect_info

This method is normally called by L<DBIO::Schema/connection>, which
encapsulates its argument list in an arrayref before passing them here.

The argument list may contain:

=over

=item *

The same 4-element argument set one would normally pass to
L<DBI/connect>, optionally followed by
L<extra attributes|/DBIO specific connection attributes>
recognized by DBIO:

  $connect_info_args = [ $dsn, $user, $password, \%dbi_attributes?, \%extra_attributes? ];

=item *

A single code reference which returns a connected
L<DBI database handle|DBI/connect> optionally followed by
L<extra attributes|/DBIO specific connection attributes> recognized
by DBIO:

  $connect_info_args = [ sub { DBI->connect (...) }, \%extra_attributes? ];

=item *

A single hashref with all the attributes and the dsn/user/password
mixed together:

  $connect_info_args = [{
    dsn => $dsn,
    user => $user,
    password => $pass,
    %dbi_attributes,
    %extra_attributes,
  }];

  $connect_info_args = [{
    dbh_maker => sub { DBI->connect (...) },
    %dbi_attributes,
    %extra_attributes,
  }];

This is particularly useful for L<Catalyst> based applications, allowing the
following config (L<Config::General> style):

  <Model::DB>
    schema_class   App::DB
    <connect_info>
      dsn          dbi:mysql:database=test
      user         testuser
      password     TestPass
      AutoCommit   1
    </connect_info>
  </Model::DB>

The C<dsn>/C<user>/C<password> combination can be substituted by the
C<dbh_maker> key whose value is a coderef that returns a connected
L<DBI database handle|DBI/connect>

In place of C<dsn> the hash may name the database by its parts -- a C<dbname>
key, optionally with C<host> and C<port>:

  $connect_info_args = [{
    dbname => $dbname,
    host => $host,
    port => $port,
    user => $user,
    password => $pass,
    %dbi_attributes,
    %extra_attributes,
  }];

The DSN is then built for the DBD the storage class is registered for
(L</_connect_params_dsn>), the driver the schema declares: the generic
storage, which has no driver, throws, and so does a storage whose DBD has no DSN form these parts can fill
(L<DBIO::Storage::DBI::ODBC>). It is the C<dbname> key that selects this
form. A hash with C<host> or C<port> and neither a C<dsn> nor a C<dbname> key
throws: there is no DSN to build them into, and they are never passed on as
L<DBI> attributes.

=item *

A L<DBIO::AccessBroker>, which answers the connection details -- asked again
for every new connection -- optionally followed by the connect options of
this connection:

  $connect_info_args = [ $broker ];
  $connect_info_args = [ $broker, \%dbi_attributes_and_extra_attributes ];

  $connect_info_args = [ $broker, {
    async         => 'future_io',
    quote_names   => 0,
    on_connect_do => [ 'SET search_path TO app' ],
    pg_enable_utf8 => 1,
  } ];

The hash beside the broker takes what the attribute hash of every other form
takes: L<DBI> attributes, the
L</DBIO specific connection attributes>, the L<async mode|/async> and
C<pool_size>. It does not take the connection itself -- C<dsn>, C<user>,
C<password>, C<dbh_maker>, C<dbname>, C<host>, C<port> throw -- which
database, and as whom, is the broker's answer (ADR 0013). This is how a
broker that answers a hash of connection parameters
(L<DBIO::AccessBroker::Static>) gets them at all.

An answer that names no database -- no DSN, and no C<dbname> to build one
from -- throws, naming the broker class. With a broker the storage never
falls back to C<$ENV{DBI_DSN}>: the broker's credentials go to the database
the broker names (L<DBIO::AccessBroker/connect_info_for_storage>).

The storage does not open a connection without a parameter it was given and
would not apply. Of a hash answer only C<dbname>, C<host> and C<port> are
built into the DSN, and what stands beside the broker joins the L<DBI>
attributes, so a parameter of the database client (C<sslmode>,
C<connect_timeout>, ...) in either place would reach C<< DBI->connect >> as an
attribute the DBD does not read. What passes are the connect options, and
L<DBI> attributes by their name -- an uppercase first letter, C<private_>,
C<dbi_>, C<dbd_>, or the prefix of the DBD the answer's DSN names
(L</_dbd_attribute_prefixes>). With any other key set to a value, in a hash
answer or beside the broker, the storage throws when it is to connect, naming
the broker class, the keys and which of the two places they stand in. That is
at the first use of its C<dbh> and at every reconnect, not here:
C<connect_info> configures the storage with such an answer, since it may be
for an async backend alone -- a transport that takes the hash opens its pooled
connections with the parameter, and this storage's own connection throws only
once something asks for it. A parameter of the database client is the broker's
to answer, never a connect option beside it: inside the DSN of the DBI form,
or by the storage that asks
(L<DBIO::AccessBroker/connect_info_for_storage>).

A broker answering a code reference (C<dbh_maker>) opens the connection by
that code, and the storage applies no L<DBI> attribute and no client parameter
to it. So beside such a broker every key the storage does not consume itself
-- a DBI attribute such as C<LongReadLen> as much as C<sslmode> -- throws when
the storage is to connect; the connect options, the SQL maker
options, C<async>, C<pool_size> and C<ignore_version> pass. The options are
judged before they are set against the broker's answer.

A broker answering the DBI form may carry some of the same settings among its
attributes (L<DBIO::AccessBroker::Vault>'s C<dbi_attrs>). A setting given in
both places must have the same value in both, or the connect throws naming
it -- when the storage is configured, and again whenever the broker is asked
for a new connection.

With an async mode, the settings a backend applies itself -- the DBI
attributes and C<pool_size> -- are handed to the async backend beside the
broker. C<pool_size> sizes its pool. The DBI attributes are treated as that
transport treats the same keys in DBI-form connect info: a transport that
opens its pooled connections through a DBD (the C<future_io> adapters) opens
them with these attributes too; one whose client is no DBD (the C<ev>
transports) drops them, so there they apply to this storage's own connection
only -- a parameter of that client (C<sslmode>, C<charset>, ...) reaches a
pooled connection only as part of the broker's answer. A transport that does
not take the settings at all (it does not declare C<broker_connect_options>,
see L<DBIO::Storage::Async/transport_capabilities>) throws at its first use
rather than open its pool without them. Every other setting is this storage's
own, exactly as when it comes with a DSN; the pooled connections replay
C<on_connect_do>/C<on_connect_call> from it.

A C<pool_size> in the broker's answer sizes the backend's pool as well, and
stays out of this storage's own C<< DBI->connect >>. Given both there and
beside the broker, the two must be the same value; the backend compares them
when it is built (L<DBIO::Storage::Async/_access_broker_pool_size>).

=back

Static connect info -- the forms above without a broker -- carries its DSN:
the DSN names the driver. Connect info without one throws here, naming its
shape and never a value of it: no arguments at all, the DBI form with an
undefined or an empty DSN, a hash whose C<dsn> is undefined or empty, and a
hash with neither a C<dsn> nor a C<dbname> key. C<$ENV{DBI_DSN}> does not
stand in for it -- the storage connects to the DSN it is given and to no
other, and a storage that never got connect info has nothing to connect from.
A hash with a C<dbname> key has a DSN, the one built from its parts. The code
reference forms open the connection themselves and need none; a broker's
answer has the rule described with it above. A schema that is only to
generate SQL names its DSN like any other: nothing is opened before the first
use that needs a connection.

Static connect info is not judged for client parameters. C<sslmode> (and any other parameter of the database client)
in the hash form, or in the attribute hash of the DBI form, is passed on
unchanged to C<< DBI->connect >> as a DBI attribute, so it is also kept in
the connect attributes. L<DBI> and the DBD decide: a driver that knows the
name applies it, another one rejects it or ignores it. The strict rule above
is for a broker, where the storage knows which parameters it
would leave unapplied.

A connection that cannot be opened throws C<DBI Connection failed: ...>, with
L<DBI>'s own error after it. L<DBI> quotes the DSN there, and a driver may
repeat more of what it was given. The password is not part of the message, in
whichever form the connect info came: the password argument, a C<Password>
among the DBI attributes and a password inside the DSN -- the value of a
C<password>, C<passwd>, C<pwd> or C<pass> key, or the password of a URI --
are shown as C<***>, while the key, the user name and the rest of the DSN
stay. When L<DBI>'s error comes with a stack trace of L<Carp> -- as every
C<croak> does under C<$Carp::Verbose> -- they are masked among the arguments
of its frames too, escaped or shortened as Carp shows an argument. The same
holds wherever DBIO writes connect info into a message: the
warning about a driver that cannot be determined, and the trace of
L<DBIO::Replicated>. It holds for the arguments of a stack trace as well
(L<DBIO::Schema/stacktrace>), where the connect info is an argument of
L<DBIO::Schema/connect>.

Please note that the L<DBI> docs recommend that you always explicitly
set C<AutoCommit> to either I<0> or I<1>.  L<DBIO> further
recommends that it be set to I<1>, and that you perform transactions
via our L<DBIO::Schema/txn_do> method.  L<DBIO> will set it
to I<1> if you do not do explicitly set it to zero.  This is the default
for most DBDs. See L</DBIO and AutoCommit> for details.

=head3 DBIO specific connection attributes

In addition to the standard L<DBI|DBI/ATTRIBUTES COMMON TO ALL HANDLES>
L<connection|DBI/Database Handle Attributes> attributes, DBIO recognizes
the following connection options. These options can be mixed in with your other
L<DBI> connection attributes, or placed in a separate hashref
(C<\%extra_attributes>) as shown above.

B<Unknown attributes are refused>. Without a broker the whole
connect info is known at C<connect_info>, so a key that is neither one of the
options below nor a L<DBI> attribute by its name throws there, naming the key
(never the value) -- C<< { limit_dialect => 'Top' } >> used to be handed to
C<< DBI->connect >> and dropped without a trace. What passes: the options
below, a L<DBI> attribute by name (an uppercase first letter, C<private_>,
C<dbi_>, C<dbd_>, or the prefix of the DBD the DSN names,
L</_dbd_attribute_prefixes>), C<sslmode> (handed to the DBD, which
reads it or not), and a key with an undefined or empty value. A parameter of
the database client belongs in the DSN. The code reference forms
(C<dbh_maker>) have no DSN and apply no attribute, and are not checked.
With a broker the rules described with the AccessBroker form above stand.

B<Each C<connect_info> call is a full reconfiguration of the storage, not a
merge> (ADR 0050). Options named in the call are applied; every other
storage option -- including C<on_connect_do>/C<on_connect_call> and their
C<disconnect> counterparts, and any option a driver adds -- reverts to its
default first. C<cursor_class> is the one exception: it reverts to its
class default rather than to C<undef>. This diverges deliberately from
upstream DBIx::Class, which only ever set options that were present in a
given call and silently left an absent option (e.g. a previously-set
C<on_connect_do>) active on the next connect -- a fossil of how the
option-picker was written in 2006, never a designed "options persist"
behavior. If you rely on an option across repeated C<connect_info> calls,
restate it every time, or set it via its accessor afterwards.

=over

=item schema

The namespace this connection works in, and the one a deploy over it installs
into: a single name, nothing else (ADR 0065). Core defines the word and the
contract; what a namespace is, is the driver's -- PostgreSQL's C<search_path>,
Oracle's C<CURRENT_SCHEMA>, DB2's C<SET SCHEMA>, DuckDB's C<USE>. A driver gives
it meaning by overriding C<_set_connection_schema($name)>, which runs on every
new connection (sync, and each async pool connection) before the
C<on_connect_*> actions. A driver without namespaces keeps the default, which
throws a L<DBIO::Exception> naming the storage class. The seam also gets the
activation of the declared database extensions as its second argument
(C<_set_connection_schema($name, $activation)>), or C<undef>.

The name is an B<identifier> (ADR 0077). Core refuses a name with C<;>, a line
break, CR or NUL (a L<DBIO::Exception> that names the key and never the
value); the rest of what it holds -- a quote, a blank, a backslash -- is the
driver's. The driver sets the name only through its identifier quoting (or as
a bind), or refuses it with a L<DBIO::Exception>; it never builds the
statement by joining the name into it. The same holds for the extension
names and libraries of C<_activate_extensions>. The Names list of
L<DBIO::Test::Conformance> checks it per driver.

Before the seam, core
asks the driver C<_extension_activation($name)> -- C<undef> by default, else
C<< { load => [ ... ], search_path => [ ... ] } >> (ADR 0066) -- and, when
there is one, hands it to C<_activate_extensions($activation, $name)>, which
writes the driver's statements (PostgreSQL: C<LOAD>, and without a namespace
the appending to the C<search_path>). Both default to nothing. The same
sequence runs for the sync connection and for every async pool connection. The key never selects or
changes the driver, and is kept on the storage as C<connection_schema> (the
C<schema> accessor is the back-reference to the schema class).

=item on_connect_do

Specifies things to do immediately after connecting or re-connecting to
the database.  Its value may contain:

=over

=item a scalar

This contains one SQL statement to execute.

=item an array reference

This contains SQL statements to execute in order.  Each element is a
string, an array reference C<[ $sql, \%dbi_attrs, @bind ]> holding the
arguments to L<DBI/do>, or a code reference.  A code reference is called
as C<< $code->($storage) >> and returns one SQL string, an array reference
of such elements, or nothing.

=item a code reference

This contains some code to execute.  Unlike code references within an
array reference, its return value is ignored.

=back

An error about a statement that fails does not quote what the statement
carries as a secret: the value of a C<key>, C<token>, C<secret> or
C<password> (C<PRAGMA key = '...'>, C<ATTACH '...?token=...'>) is shown as
C<***>, also where the database repeats a part of it in its own error
text (L<DBIO::Util/mask_statement_secrets>).

=item on_disconnect_do

Takes arguments in the same form as L</on_connect_do> and executes them
immediately before disconnecting from the database.

Note, this only runs if you explicitly call L</disconnect> on the
storage object.

=item on_connect_call

A more generalized form of L</on_connect_do> that calls the specified
C<connect_call_METHOD> methods in your storage driver.

  on_connect_do => 'select 1'

is equivalent to:

  on_connect_call => [ [ do_sql => 'select 1' ] ]

Its values may contain:

=over

=item a scalar

Will call the C<connect_call_METHOD> method.

=item a code reference

Will execute C<< $code->($storage) >>

=item an array reference

Each value can be a method name or code reference.

=item an array of arrays

For each array, the first item is taken to be the C<connect_call_> method name
or code reference, and the rest are parameters to it.

=back

Some predefined storage methods you may use:

=over

=item do_sql

Executes a SQL string, or the statements a code reference returns. This is
what L</on_connect_do> and L</on_disconnect_do> use.

It can take:

=over

=item a scalar

Will execute the scalar as SQL.

=item an arrayref

Taken to be arguments to L<DBI/do>, the SQL string optionally followed by the
attributes hashref and bind values.

=item a code reference

Will execute C<< $code->($storage) >>, which returns one SQL string (a
single statement), an arrayref of statements -- each a scalar or an arrayref
as above -- or nothing, and execute them in order.

=back

=item datetime_setup

Execute any statements necessary to initialize the database session to return
and accept datetime/timestamp values used with
L<DBIO::InflateColumn::DateTime>.

Only necessary for some databases, see your specific storage driver for
implementation details.

=back

=item on_disconnect_call

Takes arguments in the same form as L</on_connect_call> and executes them
immediately before disconnecting from the database.

Calls the C<disconnect_call_METHOD> methods as opposed to the
C<connect_call_METHOD> methods called by L</on_connect_call>.

Note, this only runs if you explicitly call L</disconnect> on the
storage object.

=item disable_sth_caching

If set to a true value, this option will disable the caching of
statement handles via L<DBI/prepare_cached>.

=item quote_names

B<On by default in DBIO> (unlike upstream DBIx::Class, where it defaults off).
Automatically sets L</quote_char> and L</name_sep> to the characters appropriate
for your particular RDBMS, so generated SQL always quotes table and column
identifiers. This is a security-hardening default: it makes reserved words and
unusual identifiers safe and removes a class of SQL-injection footguns. This
option is preferred over specifying L</quote_char> directly.

Pass C<< quote_names => 0 >> in your connect_info to opt out and emit unquoted
identifiers. An explicitly supplied L</quote_char> / L</name_sep> is always
respected.

=item quote_char

Specifies what characters to use to quote table and column names.

C<quote_char> expects either a single character, in which case is it
is placed on either side of the table/column name, or an arrayref of length
2 in which case the table/column name is placed between the elements.

For example under MySQL you should use C<< quote_char => '`' >>, and for
SQL Server you should use C<< quote_char => [qw/[ ]/] >>.

=item name_sep

This parameter is only useful in conjunction with C<quote_char>, and is used to
specify the character that separates elements (schemas, tables, columns) from
each other. If unspecified it defaults to the most commonly used C<.>.

=item unsafe

This Storage driver normally installs its own C<HandleError> and makes
sure C<RaiseError> is on, on all database handles, including those supplied
by a coderef.  On the handles it opens itself it also defaults
C<PrintError> to off; your connect_info DBI options override that, and a
handle supplied by a coderef keeps it as the coderef set it.  It does this so
that it can have consistent and useful error behavior.  C<ShowErrorStatement>
is always off, whatever connect_info says: an error text carries the
statement and the number of its bind values, never the values themselves
(see L<DBIO::Exception/Error texts carry no bind values>).

If you set this option to a true value, Storage will not do its usual
modifications to the database handle's attributes, and instead relies on
the settings in your connect_info DBI options (or the values you set in
your connection coderef, in the case that you are connecting via coderef).

Note that your custom settings can cause Storage to malfunction,
especially if you set a C<HandleError> handler that suppresses exceptions
and/or disable C<RaiseError>.

=item auto_savepoint

If this option is true, L<DBIO> will use savepoints when nesting
transactions, making it possible to recover from failure in the inner
transaction without having to abort all outer transactions.

=item cursor_class

Use this argument to supply a cursor class other than the default
L<DBIO::Storage::DBI::Cursor>.

=item async

The async mode of this connection, by name: C<immediate>, C<future_io>, or a
mode an add-on registered -- C<forked>, C<ev>, ... (see
L</register_async_mode> and L<DBIO::Manual::AsyncStorage>). It decides how the
C<*_async> methods of this storage are answered; a mode that is not available
throws at its first use. Without it the connection is synchronous and the
C<*_async> methods throw. The mode is DBIO's own and never reaches
C<< DBI->connect >>.

=item pool_size

With an async mode, the size of the async backend's connection pool -- a
positive integer, default 5 -- kept out of this storage's own
C<< DBI->connect >>. A mode without a pool (C<immediate>, C<forked>) has
nothing to size. Without an async mode it is no DBIO option: it is passed to
the DBD like any other attribute.

=item acquire_timeout, max_waiters, txn_timeout, reset_timeout

The other async options. With an async mode they go to the
async backend and stay out of this storage's own C<< DBI->connect >>:
C<acquire_timeout> is the seconds a caller waits for a pool connection
(default 30, C<0> for no timeout), C<max_waiters> the number of callers that
may be queued for one, C<txn_timeout> the seconds a C<txn_do_async> may take,
C<reset_timeout> the seconds the reset of a released connection may take
(default 10, C<0> for no bound; ADR 0079).
The list of async options is declared, not open: the four above and
C<pool_size> are the core's, and a mode's backend adds the names it takes
(L<DBIO::Storage::Async/async_option_names>). Any other name that is no DBI
attribute is refused like every unknown attribute. Without an async mode they
are no DBIO options and the DBD gives its verdict, like for C<pool_size>.
L<DBIO::Manual::AsyncStorage> describes them.

=back

Some real-life examples of arguments to L</connect_info> and
L<DBIO::Schema/connect>

  # Simple SQLite connection
  ->connect_info([ 'dbi:SQLite:./foo.db' ]);

  # Connect via subref
  ->connect_info([ sub { DBI->connect(...) } ]);

  # Connect via subref in hashref
  ->connect_info([{
    dbh_maker => sub { DBI->connect(...) },
    on_connect_do => 'alter session ...',
  }]);

  # A bit more complicated
  ->connect_info(
    [
      'dbi:Pg:dbname=foo',
      'postgres',
      'my_pg_password',
      { AutoCommit => 1 },
      { quote_char => q{"} },
    ]
  );

  # Equivalent to the previous example
  ->connect_info(
    [
      'dbi:Pg:dbname=foo',
      'postgres',
      'my_pg_password',
      { AutoCommit => 1, quote_char => q{"}, name_sep => q{.} },
    ]
  );

  # Same, but with hashref as argument
  ->connect_info(
    [{
      dsn         => 'dbi:Pg:dbname=foo',
      user        => 'postgres',
      password    => 'my_pg_password',
      AutoCommit  => 1,
      quote_char  => q{"},
      name_sep    => q{.},
    }]
  );

  # Subref + DBIO-specific connection options
  ->connect_info(
    [
      sub { DBI->connect(...) },
      {
          quote_char => q{`},
          name_sep => q{@},
          on_connect_do => ['SET search_path TO myschema,otherschema,public'],
          disable_sth_caching => 1,
      },
    ]
  );

=head2 _connect_params_dsn

  sub _connect_params_dsn {
    my ($self, $driver, $params) = @_;
    ...
    return $dsn;
  }

The per-driver seam for the B<form> of the DSN built from connection
parameters that carry none (ADR 0057) -- C<dbname>, C<host> and
C<port>, as L<DBIO::AccessBroker::Static> answers them, or a connect-info hash
that has a C<dbname> key and no C<dsn>. Override it in the driver's storage
class when its DBD does not take the default form; everything else stays
core's.

The C<dbname> key decides, not its value: Static answers it as C<undef> when
no C<dbname> was given, and the DSN is then built from the other parts. An
empty C<dbname> (C<''>) is no such case: it names no database and is refused.
A hash with neither a C<dsn> nor a C<dbname> key never reaches this seam: with
C<host> or C<port> in it, it is refused before -- in static connect info and
as a broker's answer alike -- so they do not become DBI attributes of a
connection that has no DSN.

It receives C<$driver>, the DBD name the storage class is registered for
(L</register_driver>) -- the default puts it into the DSN; an override may
name another DBD when its engine is reached through one (MSSQL through
C<DBD::Sybase>). And it receives C<$params>, a fresh hashref holding only the
parts given: C<dbname>, C<host>, C<port> -- each key present only when its
value is defined and not empty, and no value contains C<;>. It returns the
DSN string, and nothing else. The default:

  dbi:<driver>:dbname=<dbname>;host=<host>;port=<port>

in that order, leaving out the parts not given -- a form DBD::Pg,
DBD::mysql, DBD::MariaDB, DBD::SQLite, DBD::Firebird and DBD::DuckDB take.

An override does B<not> remove the parts from the connect info, check for
C<;>, resolve the driver or handle a C<dbname> that is a whole DSN (taken as
the DSN before this seam is asked): core does all of that first, the same for
every driver, so the C<dbname>, C<host> and C<port> of such a hash never reach
C<< DBI->connect >> as attributes. It is asked only on a storage registered
for exactly one DBD driver: a storage that is not -- the generic class, which
has no driver -- refuses the parameters before it is asked.

A driver whose DBD has no form these parts can fill throws here, naming what
its DBD needs instead (L<DBIO::Storage::DBI::ODBC> does). It is called at
L</connect_info> and again for every new connection, since a broker is asked
anew each time.

=head2 _bind_host_into_dsn

  sub _bind_host_into_dsn {
    my ($self, $driver, $dsn, $host, $port) = @_;
    ...
    return $bound_dsn;                 # bound
    return (undef, $form);             # declined
  }

The per-driver seam for putting a host (and port) into a DSN that is already
written (ADR 0013, addendum 2026-10-09) -- what a
L<DBIO::AccessBroker::HostBound> view does with a DBI-form answer. How a DSN
names its server is a question of the DBD; the view asks the driver's storage
class, and core's default knows one form. Override it in the driver's storage
class when its DBD names the server another way (libpq's C<hostaddr=>, DB2's
C<HOSTNAME=>, Sybase's C<server=>, Oracle Easy Connect, ...).

It is a class or an instance method and needs no instance data. C<$driver> is
the DBD name read off the DSN; C<$dsn> is the whole DSN string, with its
C<dbi:Driver:> prefix; C<$host> and C<$port> are the view's, C<$port>
C<undef> when the view has none, and neither contains C<;> -- the view refuses
that before it asks. It returns the DSN with the host (and the port, when
defined) bound, and nothing else, or B<declines> by returning the list
C<(undef, $form)>, with C<$form> a short description of the form it cannot
translate: a key name or a dialect, B<never> a value of the DSN. The view
refuses the connection with that form in its message, rather than let a
replicant connect to the host the answer named.

The default translates the C<dbi:Driver:> form (the prefix may carry
C<(attr)> parentheses) whose parts, separated by C<;>, are all C<key=value>
with a key of word characters: it replaces a C<host=> or C<port=> token where
it stands, whatever its case, and puts a missing one in front of the others.
It declines

=over

=item * a DSN without a C<dbi:Driver:> prefix;

=item * a non-empty part that is not C<key=value> -- Oracle Easy Connect
(C<//host:port/service>), a TNS descriptor (C<(DESCRIPTION=...>), an ODBC data
source name, the positional C<DBD::mysql> form;

=item * a part whose key names a server another way, whatever its case:
C<hostaddr>, C<hostname>, C<server>, C<servername>, C<address>, C<addr>,
C<dsn>;

=item * a C<db>, C<dbname> or C<database> part whose value begins with
C<host:> or C<host/port:> (Firebird's C<db=host:path>). A local path
(C<dbname=/var/db/x>) and a Windows drive (C<db=C:\data\x.fdb>) stay local and
translatable.

=back

An override that does not know a form delegates to
C<< $self->next::method(@_) >>, which declines it the same way. Called at
every connection a view makes, since a broker is asked anew each time.

=head2 _dbd_attribute_prefixes

  sub _dbd_attribute_prefixes {
    my ($self, $driver) = @_;
    ...
    return @prefixes;
  }

The prefixes the private attributes of DBD C<$driver> start with -- C<pg_> for
C<Pg>, C<mysql_> for C<mysql> -- or nothing when they are not known. C<$driver>
is the DBD name read off the DSN of a connection, and is undefined when the
DSN names none.

It is asked when the storage is to connect through an
L<AccessBroker|DBIO::AccessBroker> and a lowercase key it does not consume
stands in the broker's hash answer or beside the broker: with one of these
prefixes the key is an attribute of that DBD and goes to C<< DBI->connect >>;
without, it cannot be told from a parameter of the database client that C<<
DBI->connect >> would silently not apply, and the storage throws rather than
connect
(L<DBIO::Storage::DBI::AccessBroker/_assert_access_broker_parameters_apply>,
L<DBIO::Storage::DBI::AccessBroker/_assert_access_broker_options_apply>).

The default asks L<DBI>'s own registry of driver prefixes
(C<< DBI->driver_prefix >>), which needs no DBD loaded and knows the DBDs
registered with L<DBI>. Override it in the storage class of a driver whose DBD
is not among them (DBD::Firebird, DBD::DuckDB), or takes attributes under more
than one prefix, and delegate every other C<$driver> to
C<< $self->next::method($driver) >>.

=head2 register_async_mode

  DBIO::Storage::DBI->register_async_mode( forked    => 'DBIO::Forked::Storage' );
  DBIO::PostgreSQL::Storage->register_async_mode( ev   => 'DBIO::PostgreSQL::EV::Storage' );

Registers an async I<mode> name against the embedded backend class that answers
the C<*_async> methods for a connection opened with C<< { async => $mode } >>.
Generic modes register on a base storage class (inherited by every driver);
native modes register on a concrete driver storage class, so the same logical
mode name (e.g. C<ev>) resolves to a DB-specific backend. After lazy loading,
every target must be a L<DBIO::Storage::Async> subclass except the literal
C<immediate> mode, whose C<DBIO::Future::Immediate> target deliberately enables
synchronous dispatch. A loaded wrong-type target for any other mode croaks
rather than falling back. See ADR 0030.

The C<future_io> mode is the exception: it is resolved B<by convention>, not
from this registry. Rather than a registered class, its transport adapter is
found by walking the concrete storage's linearised ISA most-specific first and
taking the first C<< <class>::Async >> that loads (stopping before the generic
C<DBIO::Storage::DBI> base), so an extension C<storage_type> subclass without
its own adapter inherits the nearest parent driver's one. An explicit
C<< register_async_mode(future_io => ...) >> on a concrete class still wins over
the walk; a same-named adapter that loads but is not a L<DBIO::Storage::Async>
croaks rather than degrading to a parent. See ADR 0030.

=head2 register_access_path_dbd

  __PACKAGE__->register_access_path_dbd('mysql', 'MariaDB');

Arguments: C<@dbd_names>. Return value: none.

Declares, on the storage class of a driver, the DBDs of B<other> drivers that
this driver takes as its own access path -- the transport it talks to its
engine through. It is for a driver whose transport is the DBD of a foreign
driver and which, deliberately, does not inherit that driver's storage
(a ClickHouse driver speaking the MySQL protocol over C<DBD::mysql> is the
case this exists for).

The check a declared storage runs against the DBD of its DSN
(L</_adapt_to_access_path>, ADR 0059) asks L</register_driver> which driver a
DBD belongs to and reports a DBD registered for a class that is neither an
ancestor of the storage nor a subclass of the declared class. A DBD declared
here is not judged at all: the check returns without a finding, under
C<driver_strict> too. Anything not declared is judged as before, so a
mistaken DSN through a DBD the driver does not use is still reported.

The declaration belongs to the class it is made on and is inherited by its
subclasses, as class inheritance goes -- never by a sibling, never by a
parent. It is not global: another driver's declaration does not make a DBD
acceptable to you. When the driver's storage B<does> inherit the class the DBD
is registered for, the inheritance already says so and nothing needs to be
declared; that stays the normal way. Call this once at load time, beside
L</register_driver>. The declaration does not change driver detection, the
C<@ISA> of any class or the L</_adapt_to_access_path> hook.

=head2 _adapt_to_access_path

  sub _adapt_to_access_path {
    my ($self, $dbd) = @_;

    if (defined $dbd and $dbd eq 'ODBC') {
      $self->ensure_class_loaded('DBIO::MyDB::Storage::ODBC');
      bless $self, 'DBIO::MyDB::Storage::ODBC';
    }
  }

The hook through which a B<declared> driver storage adapts itself to the
access path of a connection -- the DBD and client library the DSN leads
through (ADR 0059). A schema declares its driver: its driver
component, or a driver shortcut (L<DBIO/apply_driver>), pins the driver's base
storage class as L<DBIO::Schema/storage_type>. That class stands: it never
becomes the class of another driver (ADR 0059, ADR 0067). What may still differ within one driver is the class for the access
path -- the same engine over its native DBD, over ODBC, over another client
library -- and that is the driver's own to decide, here.

Core calls it once per storage instance, during driver determination, on a
storage whose class is not the generic one, before C<_init> -- so C<_init>
runs on the class the hook chose. Driver determination is lazy: it runs at the
first use that needs the driver, not at C<connect>. The generic storage has
no driver and is refused there instead (ADR 0067).

C<$dbd> is the name of the DBD as far as core knows it B<without connecting>:
that of the live handle when there is one, else the one the DSN names; a DSN
with an empty driver part is refused, and C<$ENV{DBI_DRIVER}> stands in for
nothing. It is undefined when the connect info is a code reference
that has not been run, and when there is no DSN at all. Core opens no
connection for the hook and asks the server nothing. A hook that needs more
gets it itself -- C<< $self->_get_dbh >> connects, and connection actions
(C<on_connect_do>, C<on_connect_call>) then run once, after C<_init> -- and
that cost is the driver's decision.

The hook works on the instance: it reblesses C<$self>, may call itself again on
the new class, and may set options. The one rule is that it specialises
B<within its own driver>: afterwards the storage must still be an instance of
the declared class. If it is not, core puts the storage back into the class it
had and throws, naming both classes -- whatever L<DBIO::Schema/driver_strict>
and L<DBIO::Schema/driver_warnings> say, since that is a defect of the driver
and no mismatch. A server that turns out to be another product is reported
through L</_driver_mismatch>; the storage does not move into that product's
class. Storage layers (L<DBIO::Schema/register_storage_layer>) survive: when
the hook reblesses a layered storage into a plain class, core composes the
same layers over it. An exception from the hook, or from C<_init> after it,
leaves the storage in the class it had and without a connection -- no
connection action has run on the one a connect or the hook had opened -- and
determination is tried again at the next use.

After the hook core checks the DBD once more, if it is known: when
L</register_driver> maps it to a storage class that is no ancestor of the
adapted storage and no subclass of the declared class, the DSN leads through
the DBD of another driver, and core reports it through L</_driver_mismatch>.
A DBD nothing is registered for is not judged, and neither is a declared class
none of whose ancestors is registered for a DBD -- a private subclass of this
generic storage, set as C<storage_type> by hand, has no driver to compare the
DBD with. A subclass of a registered driver class is judged. The inheritance
of the adapted class is the whole declaration, and the normal one: there is no
list of "my DBDs" to keep. The one exception is a driver whose transport is
the DBD of a foreign driver and which does not inherit that driver's storage;
it declares those DBDs with L</register_access_path_dbd>.

A class of another distribution that inherits the declared class passes that
inheritance rule (C<DBIO::MSSQL::Storage::Sybase> inherits
C<DBIO::Sybase::Storage>). Moving the storage there is the driver's own
breach of its declaration, and nothing here catches it.

The default does nothing; a driver without access paths of its own needs no
hook, and its storage stays the declared class as before.

=head2 _driver_mismatch

  $self->_driver_mismatch(
    'the server answers as Microsoft SQL Server, not as Sybase ASE'
  );

The one place a declared driver that does not fit what it meets is reported
(ADR 0059). Core calls it when the DSN leads through the DBD of
another driver (see L</_adapt_to_access_path>). A driver calls it when it
notices, from what it knows anyway, that the server is not its engine -- in
its C<_adapt_to_access_path>, or wherever that knowledge turns up. Neither
asks the server a question for the sake of the check.

What happens is the schema's to say:

=over 4

=item * L<DBIO::Schema/driver_strict> true -- throws;

=item * otherwise L<DBIO::Schema/driver_warnings> false -- nothing;

=item * otherwise, the default -- warns.

=back

C<driver_strict> wins over C<< driver_warnings(0) >>. The switches are those
of the storage's schema. A storage without a schema -- a writer or bulk
storage a driver builds with C<< (ref $self)->new >> -- reads them off the
schema of the nearest parent storage along C<_parent_storage>, a plain
accessor the driver sets to the storage it was built from (the chain is
walked a bounded number of steps, and a cycle ends it). With no schema found
it gets the default: not strict, warns. The message is prefixed with the declared storage
class and, in a warning, followed by the two switches; pass the finding
alone, and never connect info -- a DBD or class name says enough.

=head2 _finish_connect_dsn

  sub _finish_connect_dsn {
    my ($self, $dsn) = @_;
    return "$dsn;maxConnect=$n";
  }

The per-driver seam for the last word on the DSN of a connection.
C<_connect> asks it for the DSN string of B<every> connect, after the connect
info is formed -- from a broker's answer or from the stored connect info, the
same place for both -- and connects with what it returns. Without it, whatever
a driver appended to the stored DSN would be lost for a broker, whose answer
forms the DSN anew for each connection.

It is not asked for a connection coderef or any other reference in place of the
DSN. The stored connect info is not touched: the seam works on a copy, so it
B<must be idempotent> -- it is called again at every reconnect and has to
return the same DSN for the same input, not append a second time. The default
returns the DSN unchanged. It returns the DSN string, and nothing else.

=head2 _mask_error_values

  my $text = $storage->_mask_error_values($text, \@values, $statement);

The one seam through which the text an engine writes into an error passes
before it is thrown (ADR 0075). C<$text> is that text, C<\@values> the values
bound to the statement that was running as plain values -- C<undef> and a
reference that is no plain value are left out, an object with a
stringification counts as its string; the list may be empty -- and
C<$statement> the statement in placeholder form, or C<undef>. It answers
C<$text> with every value it recognises replaced by C<***>. It never connects
and never throws.

The base implementation hands the values to L<DBIO::Util/mask_bound_values>:
each value of at least four characters, as it was written and as the handle
quotes it (when the storage has a connection). A driver whose engine writes
values in a form of its own, or rules for the shorter ones, overrides the
method and calls C<next::method>:

  sub _mask_error_values {
    my ($self, $text, $values, $statement) = @_;
    $text = $self->next::method($text, $values, $statement);
    $text =~ s/\(value\)=\(.*?\)/(value)=(***)/g;   # the engine's own form
    return $text;
  }

Core calls it wherever engine text reaches an exception: the error handler of
every handle (C<_dbi_handle_error>), the statement run by C<_dbh_execute>, the
statements of the connection actions, and the errors of a bulk C<populate>.

=head2 _dbi_error_fields

  my $fields = $storage->_dbi_error_fields($handle);   # { sqlstate => ... }

The machine-readable part of a DBI error, as a hashref with the keys of
L<DBIO::Exception::Server> -- C<sqlstate>, C<constraint>, C<table>,
C<detail>; one the handle did not report is left out. C<$handle> is the handle
DBI passed to C<HandleError>. The base class answers C<sqlstate> only, from
C<< $handle->state >>: DBI's own C<S1000>, C<00000> and the empty string mean
"no SQLSTATE" and give no C<sqlstate>. A driver whose DBD names more -- the
constraint, the table -- overrides this, calls C<next::method> and adds the
keys. It invents nothing and never connects or queries.

=head2 _execute_sth

  my ($rv, $messages) = $self->_execute_sth($dbh, $sth);

The execute verb of C<_dbh_execute>, wrapped so a driver can collect the
B<server messages> a statement produced during its execution -- the channel
engines answer on when the answer is not a result set (Sybase ASE's showplan,
Transact-SQL C<print>, PostgreSQL C<NOTICE>). The base implementation is the
bare execute:

  my $rv = $sth->execute;
  return ($rv, undef);

C<$dbh> is the handle the statement actually runs on -- the one
C<_dbh_execute> received. On a L<DBIO::Replicated::Storage> that is the
handle of the backend the statement was routed to: the read handler's for the
reading paths (C<_select>, L</_execute_rendered>), the master's for
C<insert>, C<update> and C<delete>. A driver that can collect server messages
installs its handler on that C<$dbh>, executes, and returns the collected
messages as the second value; core stores them where the driver can read them
back (C<_server_messages>). The base returns C<undef> for the messages, which
is the "this engine does not collect" answer. The shape a driver
(DBD::Sybase / C<syb_err_handler>) writes:

  sub _execute_sth {
    my ($self, $dbh, $sth) = @_;
    my $messages = [];
    my $old     = $dbh->{syb_err_handler};
    $dbh->{syb_err_handler} = sub { push @$messages, $_[3]; 0 };

    # restore the prior handler even if $sth->execute dies (DBIO has
    # RaiseError=1, so that is the normal error path, not an edge case)
    my $guard = DBIO::Util::scope_guard {
      $dbh->{syb_err_handler} = $old;
    };

    my $rv = $sth->execute;
    return ($rv, $messages);
  }

The restore MUST run on every exit path -- success, exception, die.
C<DBIO::Util::scope_guard> (or CPAN C<Scope::Guard>) is the standard pattern;
the guard's C<DESTROY> fires the restore ref as the sub unwinds, so a dying
C<$sth->execute> still reaches it. Doing it by hand with
C<eval { ... }; ... = $old;> works but is easy to forget at the bottom of
the sub, and C<$sth->execute> dying is the normal error case under
RaiseError=1, not an edge case -- skip the guard and the next statement on
the same handle inherits the dead handler.

On a failed C<_dbh_execute> (C<$sth->execute> returns false, C<throw_exception>
runs before C<_server_messages($messages)> is reached) the old value is kept:
C<_server_messages> only overwrites after the success check, so a driver
reading it after a failed statement sees the messages from the last
C<successful> statement, not the most recent one. Drivers that read
C<_server_messages> must not assume it tracks the most recent statement --
only the most recent successful one. (ADR 0040 section 7.)

The seam keeps everything L</_execute_rendered> keeps: the execute still
happens inside C<_query_start> / C<_query_end>, so the trace and therefore
L</redact_bind_value> (ADR 0025) still see the statement; C<dbh_do> still
retries over a dropped connection, and each retry re-runs this method, so the
handler is installed fresh on the handle the retry executes on; and the driver
never reaches for C<< $self->dbh >>, so the read handler of a replicated
storage is preserved. ADR 0040 section 7 records the shape.

=head2 _adjust_bind_values

  my $bind = $self->_adjust_bind_values($sth, $bind, $bind_attrs);

The one seam for a driver that changes the values it binds -- encoding a
character string for a client library that wants bytes, turning a boolean or a
number into the form the engine takes, and the like. C<$bind> is the list of
C<[ $meta, $value ]> pairs of the statement (C<$meta> carries
C<sqlt_datatype>, C<dbic_colname>, ...), C<$bind_attrs> the DBI attribute for
each position as L</_dbi_attrs_for_bind> resolved it. The answer is an arrayref
of pairs of the same form and length. The base implementation returns C<$bind>
unchanged.

Both ways values reach the database run through it: C<_bind_sth_params>, for
every statement bound one by one (C<create>, C<search>, C<update>), and
C<_dbh_execute_for_fetch>, for each row of a C<populate> in void context. The
two therefore bind the same values. A driver adjusts values here and overrides
neither of those methods for that purpose.

A driver that changes a value returns a new list of new pairs: the values
belong to the caller and are never written to. A scalar reference in the value
slot is a C<bind_param_inout> target; keep it the very same reference. The
attributes are not adjusted here -- they stay as C<_dbi_attrs_for_bind>
resolved them.

=head2 _random_function

  my $func = $storage->_random_function;

The function call this engine spells "give me a random number" with, for
L<DBIO::ResultSet/rand>, which drops it into an C<order_by> literal.

The base implementation returns C<RANDOM()> -- correct on PostgreSQL, SQLite
and DuckDB. B<This is the declaration site: a driver whose engine spells it
differently overrides this hook, and one that does not inherit a call its
engine will reject.> The drivers whose engine spells it differently override
it -- C<NEWID()> on SQL Server, C<RAND()> on MySQL / MariaDB,
C<DBMS_RANDOM.VALUE> on Oracle, which has no C<RANDOM()> at all (ORA-00904),
among others.

Static, like L</_exists_value_sql>: string out, no C<$dbh>, no version probe.
It is on the driver-determination list at the top of this class, so a
never-connected storage already answers with the spelling of the driver its
DSN names, and L<DBIO::Replicated::Storage> delegates it to the master backend
next to C<sqlt_type>.

There is no capability flag beside it. The failure mode is loud -- an engine
that does not know the function names it in its own error -- and a caller who
learned "unsupported" would have no second call to make: ordering rows at
random has no portable fallback in the ORM. This is the same cut ADR 0037
section 1 made for set difference and ADR 0039 generalised to all six set
operations in L</_set_operation_keyword>.

=head2 _explain_query

  my $rows = $storage->_explain_query($sql, \@bind);

The B<whole operation> of obtaining a query plan on this engine, for
L<DBIO::ResultSet/explain>. C<$sql> is the query to be explained, already
stripped of the parentheses L<DBIO::ResultSet/as_query> wraps it in; C<\@bind>
are that query's bind values in the native C<< [ \%attrs, $value ] >> pair
format. The return value is the plan as an arrayref of row arrayrefs -- the
shape C<< $sth->fetchall_arrayref >> produces, whatever the engine had to do to
get there. Its I<contents> are engine-specific and always were: no two engines
in this family name the same plan columns.

The base implementation is the prefix form:

  my (undef, $sth) = $self->_execute_rendered("EXPLAIN $sql", $bind);
  return $sth->fetchall_arrayref;

correct on PostgreSQL, MySQL / MariaDB, ClickHouse and DuckDB. B<This is the
declaration site: a driver whose engine does it differently overrides this
hook, and one that does not inherit an operation its engine will reject -- or,
worse, accept and answer wrongly.> Known so far:

=over 4

=item *

B<SQLite> accepts a bare C<EXPLAIN> but answers with VM bytecode rather than a
query plan -- the one B<silent> wrong answer in this family. It wants
C<EXPLAIN QUERY PLAN>. (Measured, on libsqlite 3.51.1.)

=item *

B<Oracle> needs C<EXPLAIN PLAN FOR>, which returns no rows at all because it
writes into C<PLAN_TABLE>, so the plan comes from a I<second> statement,
C<< SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY) >>. (Vendor documentation.)

=item *

B<DB2> is the same two-statement shape into its C<EXPLAIN_*> tables, spelled
C<EXPLAIN PLAN SELECTION FOR>. (Vendor documentation; no engine has confirmed
it.)

=item *

B<SQL Server> has no C<EXPLAIN> statement at all and drives the plan through a
session setting -- C<SET SHOWPLAN_ALL ON>, which must stand alone in its batch
and B<suppresses execution>, so the query itself answers with the plan; then
C<OFF>, and from a guard, or the setting outlives the failure and every later
query on that connection silently returns a plan instead of its rows. Three
round-trips plus session state. (Vendor documentation.)

=item *

B<Sybase ASE> is B<not> the same case, despite both being Transact-SQL. Its
setting is C<set showplan on>, it does B<not> suppress execution -- the query
runs as well, so C<set noexec on> / C<off> has to bracket it, five statements
in all -- and the plan comes back as server B<messages> rather than rows, on
the channel C<DBD::Sybase> exposes only through C<syb_err_handler>. Nothing
reaches C<< $sth->fetchall_arrayref >>, so the driver collects the messages
through the L</_execute_sth> seam instead: it installs its handler on the
handle the statement runs on, executes, and reads the messages back from
C<_server_messages>, wrapping them as a single-column rowset. ADR 0040
section 7 records the shape. (SAP documentation plus C<DBD::Sybase>'s own
POD.)

=item *

B<Firebird> has no statement of its own: the plan is a property of the
B<prepared statement> (C<isc_info_sql_get_plan>), read through the DBD's
private C<< $sth->func('ib_plan') >> -- see L</_prepare_rendered>.
(C<DBD::Firebird> XS and POD.)

=back

This hook is a method rather than a string precisely so those shapes can be
expressed (ADR 0040).

B<The parenthesised note on each entry is its evidence, and it is there because
three of these were wrong when first written.> Core runs no database: every
engine claim above is vendor documentation, DBD documentation or a driver's
own measurement, never core's. Check your engine before implementing against
one of them, and report back if it does not hold -- that is how the ASE entry
and the Firebird one came to be correct.

B<Every statement an override issues MUST go through the storage's statement
path> -- L</_execute_rendered> when the statement is executed,
L</_prepare_rendered> when the engine's answer is an attribute of the
B<prepared> statement and nothing is executed at all. This is a requirement of
the contract, not advice, and it has B<no engine-named exceptions>. Reaching
for C<< $self->dbh >> directly loses C<_query_start> / C<_query_end> tracing
and therefore L</redact_bind_value> (ADR 0025), C<dbh_do> retry over
disconnects, L<DBIO::Storage::DBI::NoBindVars> bind interpolation, and -- on a
L<DBIO::Replicated::Storage> -- the read handler, sending the C<EXPLAIN> of a
read query to the master's handle instead. That is exactly the set of
regressions routing C<explain> through this seam removed; owning
the execution is what makes it possible to reintroduce them. A driver that
needs a session setting or a second query issues each of them through
L</_execute_rendered> too; Firebird, which issues nothing at all, prepares
through L</_prepare_rendered> and keeps the same guarantees up to the execute
that never happens (ADR 0040 section 6).

B<When the engine's plan is one opaque string> rather than a table -- Firebird's
C<< $sth->func('ib_plan') >> is the case in this family -- the driver wraps it
as a single row of a single column, C<< [ [ $plan ] ] >>, and does not invent
columns to fill. That is a wrapping, not a fit, and it is fine: section 2 of
ADR 0040 already says the I<contents> of these rows are engine-specific and
never were portable.

Unlike L</_random_function> this hook is B<not> static -- it connects and it
executes. It is still on the driver-determination list at the top of this
class, for the same reason as before: a never-connected storage must answer
with the operation of the driver its DSN names. On
L<DBIO::Replicated::Storage> it is a B<reader>, delegated to the read handler
beside C<_select> and L</_execute_rendered>, because it now performs the read
rather than merely spelling it.

=head2 _exists_value_sql

  my $stmt = $storage->_exists_value_sql($inner_sql);

Engine-specific rendering seam for L<DBIO::ResultSet/results_exist> and its
two siblings (ADR 0037). C<$inner_sql> is the parenthesised subquery whose
existence is being asked about; the return value is a B<complete statement>
that yields C<1> or C<0>.

The base implementation is the standard-conforming spelling:

  SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END

which is correct on PostgreSQL, MySQL/MariaDB, SQLite, DuckDB, SQL Server and
Sybase. Only the engines that also refuse a C<FROM>-less C<SELECT> override
this hook, each appending its own dummy table -- Oracle C<FROM DUAL>, DB2
C<FROM SYSIBM.SYSDUMMY1>, Firebird C<FROM RDB$DATABASE>. The driver renders
the B<whole> fragment: core never composes it from parts and holds no
dummy-table knowledge.

Overriding the hook does not by itself enable the feature: the driver also
declares the C<supports_exists_query> capability (see
L<DBIO::Storage::DBI::Capabilities>), which is what
L<DBIO::ResultSet/results_exist> probes.

Static, like L</_random_function>: no C<$dbh>, no version probe. It is on the
driver-determination list at the top of this class, so a never-connected
storage still answers with the rendering of the driver its DSN names.

=head2 _set_operation_keyword

  my $keyword = $storage->_set_operation_keyword('except');

The keyword this engine spells one of the six SQL set operations with, for
L<DBIO::ResultSet/union> and its five siblings (ADR 0039; it replaces the
single-operation C<_except_operator> of ADR 0037 section 3). C<$op> is the
B<canonical operation name>, which is the ResultSet method's own name:
C<union>, C<union_all>, C<intersect>, C<intersect_all>, C<except>,
C<except_all>. The base implementation answers with the ANSI spelling of each
-- C<UNION>, C<UNION ALL>, C<INTERSECT>, C<INTERSECT ALL>, C<EXCEPT>,
C<EXCEPT ALL>.

The hook has B<two jobs, deliberately in one place>:

=over 4

=item * B<spell> the operation for this engine. C<DBIO::Oracle::Storage>
answers C<MINUS> for C<except>.

=item * B<refuse> it, for an engine that does not have the operation at all --
by throwing, from the driver, with a message naming the engine and the version
(via C<< $self->throw_exception >>, F21 -- never a bare C<croak>). Known gaps,
as B<reported by the driver repos> rather than verified here: Oracle has no
C<MINUS ALL> / C<EXCEPT ALL> before 21c, and SQLite and SQL Server have no
C<EXCEPT ALL> / C<INTERSECT ALL>.

=back

Rendering and refusal stay together because the driver is the only place that
knows both, and a refusal that has to name a version can only be written where
that version is known. The shape of an override is therefore:

  sub _set_operation_keyword {
    my ($self, $op) = @_;
    return $self->next::method($op) unless defined $op;   # let the base throw
    return 'MINUS' if $op eq 'except';
    $self->throw_exception("...") if $op eq 'except_all';
    return $self->next::method($op);
  }

The C<defined> guard on the first line is not decoration. The base below
handles an undefined C<$op> correctly -- that is the core programming error it
throws for -- but it only ever sees one if the override passes it down, and an
override that opens with C<< $op eq 'except' >> emits an uninitialized-value
warning before it gets there. Reported from the dbio-firebird rollout, where
the example was copied literally, which is what an example is for.

An override handles the operations it has an opinion about and hands the rest
to C<< $self->next::method($op) >>, so it inherits every base keyword it did
not name -- and an unknown C<$op> reaching the base is a B<core programming
error>, not an engine fact, so the base throws and lists the six valid names
rather than letting a bare token through into the SQL.

There is no capability flag beside it, deliberately: there is nothing to branch
on (no set operation has a portable fallback in the ORM, so a caller who
learned "unsupported" would have no second call to make); the hook is already
the refusal seam and the driver writes a better message than core could; and a
gate defaulting to C<0> would regress every engine that has these operations
today. ADR 0037 section 3 gave a fourth reason -- a boolean cannot carry a
keyword -- which applies to C<except> but B<not> to the C<... ALL> family,
where availability really is a yes/no question; ADR 0039 section 3 records why
a capability is still the wrong shape there.

Must be a B<static class fact>: no C<$dbh>, no version probe. That binds the
B<refusal> too, and every known gap is version-bounded (Oracle gained
C<MINUS ALL> in 21c), so a driver cannot ask which version it is talking to
here. It refuses unconditionally and says so in the message, or reads a
class-level opt-in a deployment sets when it knows its server -- ADR 0039
section 7.
C<DBIO::ResultSet::_set_operation> bakes the keyword into a literal C<from>
clause at construction time, so a runtime-resolved keyword is not expressible
at all -- and asking the database which word to use is what made
C<< $rs->except($other)->as_query >> open a connection before this hook's
predecessor existed. It is on the driver-determination list at the top of this
class for the same reason L</_exists_value_sql> is, and
L<DBIO::Replicated::Storage> delegates it to the master backend.

=head2 _execute_rendered

  my ($rv, $sth) = $storage->_execute_rendered($sql, \@bind);

Run an B<already-rendered> statement and its (already bind-attribute-resolved)
binds. Everything C<_execute> does below the SQL-generation step happens here
too -- C<dbh_do> retry over disconnects, C<_query_start> / C<_query_end>
tracing and therefore L</redact_bind_value> -- but no C<sql_maker> op is
invoked, because there is nothing left to generate.

One caller is L<DBIO::ResultSet/results_exist>, whose statement comes out of
L</_exists_value_sql> as a complete statement (ADR 0037 section 2): its base
form has no C<FROM> at all, so it cannot be expressed as an
C<< sql_maker->select >> call, and wrapping it in one
(C<SELECT * FROM ( ... ) AS ...>) is exactly the derived-table decoration that
ADR made illegal. The other is L</_explain_query>: its base implementation,
and each statement a driver override executes, as that hook's contract
requires (ADR 0040).

=head2 _prepare_rendered

  my $sth = $storage->_prepare_rendered($sql, \@bind);

L</_execute_rendered> stopped one verb short: the same already-rendered
statement is reshaped, the connection is established, the handle is prepared
and the binds are bound -- and then the live C<$sth> is handed back B<without
being executed>. Nothing is sent to the engine beyond the prepare itself.

This exists because on some engines the answer to a question is a property of
the prepared statement rather than the result of running it. Firebird's query
plan is the case that forced it (C<isc_info_sql_get_plan>, reached through
L<DBD::Firebird>'s private statement-handle function once the statement is
prepared), so its L</_explain_query> reads:

  my $sth  = $self->_prepare_rendered($sql, $bind);
  my $plan = $sth->func('ib_plan');
  return [ [ $plan ] ];

C<func> and not C<< $sth->{ib_plan} >>: C<ib_plan> is a private XSUB of the
statement handle in both L<DBD::Firebird> and L<DBD::InterBase>, and neither
serves it as a fetchable attribute. Asking for the attribute does not throw --
DBI answers C<undef> -- so the wrong spelling returns a plan row nothing can
tell from a real one. B<Ask the DBD's own documentation which of the two forms
a given value has> before reading it off a handle here; that is the one thing
this seam cannot check for a driver.

Without this seam that driver would have to reach for C<< $self->dbh >>, which
is exactly the bypass L</_explain_query> forbids -- committed by the one engine
that could not otherwise obey (ADR 0040 section 6).

B<What the seam still buys>, all of it the same code L</_execute_rendered>
runs:

=over 4

=item *

C<_query_start> / C<_query_end> B<tracing>, and therefore the
L</redact_bind_value> hook (ADR 0025). The bind values of the query being
prepared are the caller's real data and must not reach a trace sink raw.

=item *

C<dbh_do> B<retry over a dropped connection> -- and a prepare is a far better
citizen there than an execute, because re-running it leaves nothing behind.

=item *

L</_prep_rendered_for_execute>, hence L<DBIO::Storage::DBI::NoBindVars>
interpolation: on an engine with no usable placeholders the statement is
prepared with its values already substituted and an empty bind list, instead of
arriving with its C<?> intact.

=item *

C<_dbi_attrs_for_bind> plus C<_bind_sth_params> -- resolved DBI bind
attributes, C<bind_param_inout> for scalar-ref binds, and the silent-failure
check in C<_prepare_sth> for a C<< $dbh->prepare >> that returns false without
raising.

=item *

on a L<DBIO::Replicated::Storage>, the B<read handler> rather than the master's
handle: it is on C<@reader_methods> beside L</_execute_rendered>, with the
matching forwarder on L<DBIO::Replicated::Balancer>.

=back

B<What it does not buy, stated rather than assumed:>

=over 4

=item *

B<No execute.> Attributes some DBDs only populate after C<execute> (row counts,
and on several engines C<< $sth->{NAME} >> and friends) are not there yet.
Only ask the handle for what your engine answers at prepare time.

=item *

B<The retry window closes when the handle is returned.> C<dbh_do> covers the
prepare; whatever the caller then does with the C<$sth> happens outside it. That
is not new -- L</_execute_rendered> hands back a C<$sth> that is fetched from
after C<dbh_do> has returned in exactly the same way -- but a prepare-only
caller does more with its handle, so it is worth saying.

=item *

B<The handle may come out of DBI's statement cache.> C<_prepare_sth> uses
C<prepare_cached> unless L</disable_sth_caching> is set. Use the handle and let
it go; do not hold it across other statements on the same connection.

=item *

B<The trace does not distinguish a prepare from an execute.> The statement
appears in C<debugcb> exactly as an executed one would. It did go to the
server; it did not run.

=back

=head2 _prep_rendered_for_execute

  my ($sql, $bind) = $self->_prep_rendered_for_execute($sql, $bind);

The pre-rendered counterpart of the post-generation half of
C<_prep_for_execute>: the last chance a driver has to reshape a statement core
rendered itself, on the way into L</_execute_rendered> or
L</_prepare_rendered>. The identity by
default; L<DBIO::Storage::DBI::NoBindVars> overrides it to interpolate the bind
values into the SQL, which is the whole reason that class exists -- without the
seam, an engine with no usable placeholders would receive the one statement
core does not build through C<sql_maker> with its C<?> intact.

=head2 deploy_defaults

Returns a hash of default arguments merged into every C<< $schema->deploy() >>
call made by L<DBIO::Test>.  The base implementation returns an empty list;
drivers override this to declare their requirements without hard-coding driver
names in test infrastructure.

  # DBIO::MySQL::Storage
  sub deploy_defaults { return (add_drop_table => 1) }

=head2 deploy_setup

  $storage->deploy_setup($schema);

Called by L<DBIO::Test> immediately before C<< $schema->deploy() >>.  The
default implementation is a no-op.  Drivers override this to perform any
one-time database-level setup that must happen before the schema is installed
(for example, stripping incompatible C<sql_mode> flags on MySQL).

=head2 on_connect_do

This method is deprecated in favour of setting via L</connect_info>.

=head2 on_disconnect_do

This method is deprecated in favour of setting via L</connect_info>.

=head2 dbh_do

Arguments: ($subref | $method_name), @extra_coderef_args?

Execute the given $subref or $method_name using the new exception-based
connection management.

The first two arguments will be the storage object that C<dbh_do> was called
on and a database handle to use.  Any additional arguments will be passed
verbatim to the called subref as arguments 2 and onwards.

Using this (instead of $self->_dbh or $self->dbh) ensures correct
exception handling and reconnection (or failover in future subclasses).

Your subref should have no side-effects outside of the database, as
there is the potential for your subref to be partially double-executed
if the database connection was stale/dysfunctional.

Example:

  my @stuff = $schema->storage->dbh_do(
    sub {
      my ($storage, $dbh, @cols) = @_;
      my $cols = join(q{, }, @cols);
      $dbh->selectrow_array("SELECT $cols FROM foo");
    },
    @column_list
  );

=head2 async

Returns the embedded async backend storage (a L<DBIO::Storage::Async>) for an
instance connected with an event-loop async mode (C<< { async => 'forked' } >>,
C<'future_io'>, C<'ev'>, ...), or C<undef> for a sync or C<immediate>-mode
instance. It is a thin public alias over the lazy C<_async_storage> resolver
that also feeds the six CRUD C<*_async> methods, so it shares their backend
discovery and caching. An unavailable mode, or a loaded non-
L<DBIO::Storage::Async> target other than literal C<immediate>, croaks (see
L</register_async_mode> and ADR 0030). For C<future_io> the backend class is
resolved by convention:
the concrete storage's linearised ISA is walked most-specific first for a
C<< <class>::Async >> adapter, stopping before the generic C<DBIO::Storage::DBI>
base, so extension C<storage_type> subclasses (AGE, PostGIS) reach async CRUD
through the nearest parent driver's adapter.

Use it to reach async API that the CRUD C<*_async> methods do not cover --
C<listen>/C<notify> (core LISTEN/NOTIFY, ADR 0056, on every transport that
declares it) and driver features such as PostgreSQL's C<pipeline> and
C<copy_in> -- on the very same schema that serves your synchronous queries:

  $schema->storage->async->listen(channel => sub {
    my ($channel, $payload, $sender_pid) = @_;
    ...
  });

=head2 disconnect

Our C<disconnect> method also performs a rollback first if the
database is not in C<AutoCommit> mode.

=head2 with_deferred_fk_checks

=over 4

=item Arguments: C<$coderef>

=item Return Value: The return value of $coderef

=back

Storage specific method to run the code ref with FK checks deferred or
in MySQL's case disabled entirely.

=head2 connected

=over

=item Arguments: none

=item Return Value: 1|0

=back

Verifies that the current database handle is active and ready to execute
an SQL statement (e.g. the connection did not get stale, server is still
answering, etc.) This method is used internally by L</dbh>.

=head2 dbh

Returns a C<$dbh> - a data base handle of class L<DBI>. The returned handle
is guaranteed to be healthy by implicitly calling L</connected>, and if
necessary performing a reconnection before returning. Keep in mind that this
is very B<expensive> on some database engines. Consider using L</dbh_do>
instead.

=head2 register_driver

=over 4

=item Arguments: $dbd_driver_name, $storage_class

=item Return value: none

=back

Registers a mapping from a DBI driver name (for example C<Pg>, C<mysql>,
C<SQLite>) to a DBIO storage class.

Called by driver distributions at load time. The registry says which driver
a DBD belongs to, in two places: L<DBIO/driver_for> answers the driver of a
connection with it (the C<E<lt>NameE<gt>> of the C<DBIO::E<lt>NameE<gt>::Storage>
class the DBD is registered for), and a B<declared> storage is checked against
the DBD of its DSN with it (L</_adapt_to_access_path>). A driver that takes
another driver's DBD as its own transport, without inheriting that driver's
storage, says so with L</register_access_path_dbd>. The registry moves no
storage into a class: a storage is its driver's from the start (ADR 0067).

Example:

  __PACKAGE__->register_driver('Pg' => 'DBIO::PostgreSQL::Storage');

=head2 register_connector_driver

Retired (ADR 0067). It filled a registry from which a storage connected
through ODBC was moved into the class of whatever engine the server named. A
storage is never moved into another driver's class: a schema declares its
driver, and a driver that runs over ODBC adapts itself to it
(L</_adapt_to_access_path>). Calling it throws.

=head2 connect_call_datetime_setup

A no-op stub method, provided so that one can always safely supply the
L<connection option|/DBIO specific connection attributes>

 on_connect_call => 'datetime_setup'

This way one does not need to know in advance whether the underlying
storage requires any sort of hand-holding when dealing with calendar
data.

=head2 connect_call_rebase_sqlmaker

This on-connect call takes as a single argument the name of a class to "rebase"
the SQLMaker inheritance hierarchy upon. For this to work properly the target
class B<MUST> inherit from L<DBIO::SQLMaker::ClassicExtensions> and
either L<SQL::Abstract> or L<SQL::Abstract::Classic> as shown below.

This infrastructure is provided to aid recent activity around experimental new
aproaches to SQL generation within DBIO. You can (and are encouraged to)
mix and match old and new within the same codebase as follows:

  package DBIO::Awesomer::SQLMaker;
  # you MUST inherit in this order to get the composition right
  # you are free to override-without-next::method any part you need
  use base qw(
    DBIO::SQLMaker::ClassicExtensions
    << OPTIONAL::AWESOME::Class::Implementing::ExtraRainbowSauce >>
    SQL::Abstract
  );
  << your new code goes here >>


  ... and then ...


  my $experimental_schema = $original_schema->connect(
    sub {
      $original_schema->storage->dbh
    },
    {
      # the nested arrayref is important, as per
      # https://metacpan.org/pod/DBIO::Storage::DBI#on_connect_call
      on_connect_call => [ [ rebase_sqlmaker => 'DBIO::Awesomer::SQLMaker' ] ],
    },
  );

=head2 redact_bind_value

Class-level accessor for a coderef that decides how each bind value appears
in the trace output. The coderef is invoked as

  $redactor->($column_name, $value, $bindattrs)

where C<$column_name> is the column name attached to the bind slot by the
SQL generator (or C<undef> for binds that carry no column metadata, such as
positional placeholders in literal SQL such as
C<< \[ 'name = ?', $value ] >>) and C<$bindattrs> is the bind attribute hash
of the slot (or C<undef>). The coderef
returns the value to interpolate into the trace string. The raw bind value
sent to the database is not modified - only its representation in the trace
sink is.

The default redactor shows the bind of every column that has C<encode_column>
(L<DBIO::EncodedColumn>) as C<***> -- the bind attributes of such a column
carry C<< redact =E<gt> 1 >> -- and every other value as it is. Install a custom
redactor to scrub further credential or PII columns, e.g.:

  DBIO::Storage::DBI->redact_bind_value(sub {
      my ($colname, $value) = @_;
      return defined $colname && $colname eq 'password' ? '***' : $value;
  });

An C<undef> bind value is rendered as C<NULL> without the redactor being
called. What the redactor returns is put between single quotes as it is --
DBIO does not validate it: return a defined string without line breaks
(C<undef> renders as an empty string and warns).

The redactor is asked for every bind value from trace level 2 on
(C<DBIO_TRACE=2>, C<debug(2)>); level 1 traces the statement alone. What it
returns is cut to 32 characters, with C<...> marking the cut.

The redactor is a single class-level slot; setting it on a subclass does
not affect the parent or sibling classes. If you need per-instance
behavior, install a closure that consults C<$self> on the storage object
(via a dispatcher closure captured at connect time).

=head2 select

=over 4

=item Arguments: $ident, $select, $condition, $attrs

=back

Handle a SQL select statement.

=head2 last_insert_id

Return the row id of the last insert. Returns the autoincrement values for the
columns requested by the insert codepaths.

=head2 sqlt_type

Returns the database driver name.

=head2 bind_attribute_by_data_type

Given a datatype from column info, returns a database specific bind
attribute for C<< $dbh->bind_param($val,$attribute) >> or nothing if we will
let the database planner just handle it.

This method is always called after the driver has been determined and a DBI
connection has been established. Therefore you can refer to C<DBI::$constant>
and/or C<DBD::$driver::$constant> directly, without worrying about loading
the correct modules.

=head2 is_datatype_numeric

Given a datatype from column_info, returns a boolean value indicating if
the current RDBMS considers it a numeric value. This controls how
L<DBIO::Row/set_column> decides whether to mark the column as
dirty - when the datatype is deemed numeric a C<< != >> comparison will
be performed instead of the usual C<eq>.

=head2 create_ddl_dir

=over 4

=item Arguments: $schema, \@databases, $version, $directory, $preversion, \%sqlt_args

=back

B<DEPRECATED:> This method is deprecated and will throw an
exception if called. Use the native Deploy class on your storage instead
(see L<DBIO::Schema/deploy>).

Historically this created SQL DDL files for each requested database engine,
plus C<ALTER TABLE> upgrade scripts between schema versions, via
L<SQL::Translator>. Core no longer generates SQL on the fly; the native Deploy
classes (e.g. L<DBIO::PostgreSQL::Deploy>) handle introspection, diff and
deployment. The original signature is retained only for the deprecation throw.

=head2 deployment_statements

=over 4

=item Arguments: $schema, $type, $version, $directory, $sqlt_args

=back

Returns the SQL statements for deploying the schema.

If the DDL file L<DBIO::Schema/ddl_filename> names for these arguments
exists in the directory, reads and returns its contents. Otherwise, throws
an exception. There is no on-the-fly SQL generation here, and core does not
write that file either: L</create_ddl_dir> only throws.

For deployments, use L<DBIO::Schema/deploy> instead, which routes to the
storage's native Deploy class if available.

=head2 deploy

=over 4

=item Arguments: $schema, $type, \%sqlt_args, $directory

=back

Installs the schema. A storage that names a native Deploy class through
C<dbio_deploy_class> hands the schema to it (C<< ->new(schema => $schema, %args)->install >>);
C<%args> come from C<\%sqlt_args> (L<DBIO::Deploy::Base/deploy_args>): the option
C<add_drop_table> drops the declared views and tables before the install, every
other key, C<version> included, throws; C<$type> and C<$directory> are ignored on
this route;
this is the one place every driver, and L<DBIO::Replicated::Storage> through its
master, takes that route, and L<DBIO::Schema/deploy> ends here the same way.
A DDL file in the directory is not executed in its place. The driver storage
owns C<dbio_deploy_class>; a storage layer does not define it
(L<DBIO::Storage::Composed/The Deploy class belongs to the driver>).

A storage without a native Deploy class runs the statements of an existing DDL
file (see L</deployment_statements>) and throws when there is none. The
native route needs a L<DBIO::Schema>; any other first argument takes the
DDL-file route.

=head2 datetime_parser

Returns the datetime parser class

=head2 datetime_parser_type

Defines the datetime parser class - currently defaults to L<DateTime::Format::MySQL>

=head2 build_datetime_parser

See L</datetime_parser>

=head2 is_replicating

A boolean that reports if a particular L<DBIO::Storage::DBI> is set to
replicate from a master database.  Default is undef, which is the result
returned by databases that don't support replication.

=head2 lag_behind_master

Returns a number that represents a certain amount of lag behind a master db
when a given storage is replicating.  The number is database dependent, but
starts at zero and increases with the amount of lag. Default in undef

=head2 relname_to_table_alias

=over 4

=item Arguments: $relname, $join_count

=item Return Value: $alias

=back

L<DBIO> uses L<DBIO::Relationship> names as table aliases in
queries.

This hook is to allow specific L<DBIO::Storage> drivers to change the
way these aliases are named.

The default behavior is C<< "$relname_$join_count" if $join_count > 1 >>,
otherwise C<"$relname">.

=head1 USAGE NOTES

=head2 DBIO and AutoCommit

DBIO can do some wonderful magic with handling exceptions,
disconnections, and transactions when you use C<< AutoCommit => 1 >>
(the default) combined with L<txn_do|DBIO::Storage/txn_do> for
transaction support.

If you set C<< AutoCommit => 0 >> in your connect info, then you are always
in an assumed transaction between commits, and you're telling us you'd
like to manage that manually.  A lot of the magic protections offered by
this module will go away.  We can't protect you from exceptions due to database
disconnects because we don't know anything about how to restart your
transactions.  You're on your own for handling all sorts of exceptional
cases if you choose the C<< AutoCommit => 0 >> path, just as you would
be with raw DBI.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
