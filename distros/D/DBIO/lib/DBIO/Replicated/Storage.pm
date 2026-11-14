package DBIO::Replicated::Storage;
# ABSTRACT: Replicated DBI storage coordinator

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::Storage::DBI';

use Scalar::Util qw/blessed reftype weaken/;
use List::Util ();
use Sub::Util 'set_subname';
use DBIO::Util ();
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  pool_type
  pool_args
  balancer_type
  balancer_args
  backend_storage_class
  _master_connect_info_opts
/);

# ADR 0037 / ADR 0039: _exists_value_sql and _set_operation_keyword are engine
# facts the driver storage owns, so they have to reach the master backend
# exactly like sqlt_type and sql_maker do. Without the delegation a replicated
# setup would answer them from the generic base class and lose the driver's
# rendering -- and except() works here today *because* sqlt_type is delegated,
# so leaving the hooks out would turn this fix into a regression. For
# _set_operation_keyword the delegation carries the driver's *refusal* too: an
# engine that has no EXCEPT ALL must say so through a replicated storage as
# well, or the one setup that hides the driver would be the one that emits the
# broken SQL. _execute_rendered is the statement path results_exist runs on; it
# is a read, so it sits with _select.
#
# _random_function is the same shape as those two -- a static class
# fact of the driver, string out, no $dbh -- so it goes where they go, next to
# sqlt_type. Not with the readers: what rides on the reader list is the
# statement *path* (_select, _execute_rendered), and a spelling is not a path.
# rand() drops the returned function name into an order_by literal; the SELECT
# built around it reaches the read handler on its own.
#
# ADR 0040: its old companion _explain_sql does NOT sit here any
# more, and the move is the point rather than a tidy-up. While the hook only
# produced the *spelling* the master's driver dictates, a writer was right --
# execution went separately through _execute_rendered, which is a reader, so
# the EXPLAIN still ran on the read handler. _explain_query owns the whole
# operation, so the same classification would run the EXPLAIN of a READ query
# on the master and undo exactly that read routing. It is a read; it goes
# with _select and _execute_rendered. Note that adding it to @reader_methods is
# only half of it: the read handler is a DBIO::Replicated::Balancer, which is
# not a storage and forwards only the methods it names explicitly -- so
# DBIO::Replicated::Balancer::_explain_query exists too, routing like
# _execute_rendered (master inside a transaction, a replicant otherwise).
#
# The four capability entry points ride with them. A capability is a
# fact about the engine on the other end of a connection -- either declared by
# the driver storage class (_use_X) or probed from the live $dbh (_supports_X,
# memoised in _dbh_details). This object has neither a driver class nor a $dbh,
# so answering for itself could only ever produce the conservative default,
# which is a plausible-looking lie. Both tiers therefore go to the master: it
# owns DDL and the write path, and the engine whose version decides a
# capability is the master's. Both *setters* go with them, or a declaration
# made on the replicated storage would be written here and read from there.
my @writer_methods = qw(
  sql_maker sqlt_type datetime_parser datetime_parser_type
  build_datetime_parser last_insert_id insert update delete dbh
  txn_begin txn_do txn_commit txn_rollback txn_scope_guard
  deploy with_deferred_fk_checks dbh_do _prep_for_execute
  is_datatype_numeric svp_rollback svp_begin svp_release
  relname_to_table_alias _dbh_last_insert_id _dbi_connect_info
  _dbio_connect_attributes auto_savepoint bind_attribute_by_data_type
  transaction_depth deferred_rollback _throw_deferred_rollback
  savepoints _sql_maker _sql_maker_opts _dbh_autocommit _get_dbh
  sql_maker_class insert_bulk _insert_bulk _execute _do_query
  _dbh_execute _server_info _get_server_version
  _exists_value_sql _set_operation_keyword
  _random_function
  get_dbms_capability set_dbms_capability
  get_use_dbms_capability set_use_dbms_capability
  connection_schema
);

# ADR 0040 section 6: _prepare_rendered is _execute_rendered
# stopped one verb short -- the same statement path, handing back a prepared
# handle instead of an executed one, for engines whose answer is an attribute
# of the PREPARED statement (Firebird's query plan). It rides with the path it
# is half of. Its one caller in the family is _explain_query, which is already
# a reader and therefore already runs on the replicant by the time it preps --
# but leaving a statement path off both lists is the failure mode ADR 0040
# section 4 documented and it is SILENT: the generic base class answers, the
# statement goes to whatever handle that finds, and nothing errors. The
# Balancer forwarder is not optional either, for the same reason as
# _explain_query's.
my @reader_methods = qw(
  select select_single columns_info_for _dbh_columns_info_for _select
  _execute_rendered _explain_query _prepare_rendered
);



sub new {
  my ($class, $schema, $args) = @_;
  $args ||= {};

  my $self = bless {
    transaction_depth => 0,
    savepoints        => [],
  }, $class;

  $self->schema($schema);
  weaken $self->{schema} if ref $self->{schema};
  $self->{debug} = $class->_trace_level_of($ENV{DBIO_TRACE})
    if $ENV{DBIO_TRACE};

  $self->pool_type($args->{pool_type} || 'DBIO::Replicated::Pool');
  $self->pool_args($args->{pool_args} || {});
  $self->balancer_type($class->_normalize_balancer_type($args->{balancer_type} || 'DBIO::Replicated::Balancer::First'));
  $self->balancer_args($args->{balancer_args} || {});
  $self->backend_storage_class($args->{backend_storage_class} || 'DBIO::Storage::DBI');
  $self->_master_connect_info_opts({});

  return $self;
}

sub _normalize_balancer_type {
  my ($class, $type) = @_;
  $type =~ s/\A::/DBIO::Replicated::Balancer::/;
  return $type;
}


sub master {
  my $self = shift;
  if (@_) {
    $self->{master} = $_[0];
  }
  elsif (!$self->{master}) {
    $self->{master} = $self->_build_master;
  }
  return $self->{master};
}


sub pool {
  my $self = shift;
  if (@_) {
    $self->{pool} = $_[0];
  }
  elsif (!$self->{pool}) {
    $self->{pool} = $self->_build_pool;
  }
  return $self->{pool};
}


sub balancer {
  my $self = shift;
  if (@_) {
    $self->{balancer} = $_[0];
  }
  elsif (!$self->{balancer}) {
    $self->{balancer} = $self->_build_balancer;
  }
  return $self->{balancer};
}


sub read_handler {
  my $self = shift;
  if (@_) {
    $self->{read_handler} = $_[0];
  }
  elsif (!$self->{read_handler}) {
    $self->{read_handler} = $self->_build_read_handler;
  }
  return $self->{read_handler};
}


sub write_handler {
  my $self = shift;
  if (@_) {
    $self->{write_handler} = $_[0];
  }
  elsif (!$self->{write_handler}) {
    $self->{write_handler} = $self->_build_write_handler;
  }
  return $self->{write_handler};
}


sub create_pool {
  my ($self, %args) = @_;
  my $type = $self->pool_type;
  $self->ensure_class_loaded($type);
  DBIO::Util::assert_class_isa(pool_type => $type, 'DBIO::Replicated::Pool');
  return $type->new(%args);
}

sub create_balancer {
  my ($self, %args) = @_;
  my $type = $self->balancer_type;
  $self->ensure_class_loaded($type);
  DBIO::Util::assert_class_isa(balancer_type => $type, 'DBIO::Replicated::Balancer');
  return $type->new(%args);
}

sub _build_master {
  my $self = shift;
  my $storage_class = $self->backend_storage_class;
  $self->ensure_class_loaded($storage_class);
  DBIO::Util::assert_class_isa(
    backend_storage_class => $storage_class, 'DBIO::Storage::DBI',
  );

  my $storage = $storage_class->new($self->schema);

  require DBIO::Replicated::Backend::Master;
  return DBIO::Replicated::Backend::Master->new(
    storage => $storage,
  );
}

sub _build_pool {
  my $self = shift;
  return $self->create_pool(
    master        => $self->master,
    storage_class => $self->backend_storage_class,
    %{ $self->pool_args || {} },
  );
}

sub _build_balancer {
  my $self = shift;
  return $self->create_balancer(
    pool   => $self->pool,
    master => $self->master,
    %{ $self->balancer_args || {} },
  );
}

sub _build_write_handler { shift->master }
sub _build_read_handler  { shift->balancer }

sub connect_info {
  my ($self, $info, @extra) = @_;

  $self->throw_exception(
    'connect_info can not be retrieved from a replicated storage - accessor must be called on a specific backend instance'
  ) unless defined $info;

  my ($filtered_info, $opts) = $self->_parse_connect_info($info);

  if (exists $opts->{pool_type}) {
    $self->pool_type($opts->{pool_type});
    delete $self->{pool};
  }

  if (exists $opts->{pool_args}) {
    $self->pool_args($self->_merge_hashrefs($opts->{pool_args}, $self->pool_args || {}));
    delete $self->{pool};
  }

  if (exists $opts->{balancer_type}) {
    $self->balancer_type($self->_normalize_balancer_type($opts->{balancer_type}));
    delete $self->{balancer};
    delete $self->{read_handler};
  }

  if (exists $opts->{balancer_args}) {
    $self->balancer_args($self->_merge_hashrefs($opts->{balancer_args}, $self->balancer_args || {}));
    delete $self->{balancer};
    delete $self->{read_handler};
  }

  if (exists $opts->{backend_storage_class}) {
    $self->backend_storage_class($opts->{backend_storage_class});
    delete @{$self}{qw(master pool balancer read_handler write_handler)};
  }

  $self->_master_connect_info_opts($opts->{master_connect_opts} || {});

  my $rv = $self->master->connect_info($filtered_info, @extra);
  $self->master->storage->_determine_driver if $self->master->storage->can('_determine_driver');
  $self->master->install_debug_proxy($self->master->storage->debugobj);

  if ($self->{pool}) {
    $self->pool->master($self->master);
  }

  return $rv;
}


sub connect_replicants {
  my ($self, @replicants) = @_;
  my @merged = map { $self->_merge_replicant_connect_info($_) } @replicants;
  return $self->pool->connect_replicants($self->schema, @merged);
}



sub replicants {
  my $self = shift;
  return $self->pool->replicants;
}

sub has_replicants {
  my $self = shift;
  return $self->pool->has_replicants;
}

sub all_storages {
  my $self = shift;
  return grep { defined $_ && blessed $_ } ($self->master, values %{ $self->replicants });
}

sub execute_reliably {
  my ($self, $coderef, @args) = @_;
  $self->throw_exception('Second argument must be a coderef')
    unless ref $coderef eq 'CODE';

  local $self->{read_handler} = $self->master;
  return $coderef->(@args);
}


# The lookup of find_or_create, find_or_new, update_or_create, update_or_new
# and the upsert fallback reads where its write goes (DBIO::Storage).
sub _read_pool_for_read_modify_write { 'master' }

sub set_reliable_storage {
  my $self = shift;
  $self->read_handler($self->write_handler);
}


sub set_balanced_storage {
  my $self = shift;
  $self->read_handler($self->balancer);
}



sub connected {
  my $self = shift;
  return $self->master->connected && $self->pool->connected_replicants;
}

sub ensure_connected {
  my $self = shift;
  $_->ensure_connected(@_) for $self->all_storages;
}

sub set_schema {
  my ($self, @args) = @_;
  $self->SUPER::set_schema(@args);
  $_->set_schema(@args) for $self->all_storages;
}


sub debug {
  my $self = shift;
  if (@_) {
    $_->debug(@_) for $self->all_storages;
  }
  return $self->master->debug;
}

sub debugobj {
  my $self = shift;
  return $self->master->debugobj(@_);
}

sub debugfh {
  my $self = shift;
  return $self->master->debugfh(@_);
}

sub debugcb {
  my $self = shift;
  return $self->master->debugcb(@_);
}

sub disconnect {
  my $self = shift;
  $_->disconnect(@_) for $self->all_storages;
}

sub cursor_class {
  my ($self, $cursor_class) = @_;
  if ($cursor_class) {
    $_->cursor_class($cursor_class) for $self->all_storages;
  }
  return $self->master->cursor_class;
}

sub cursor {
  my ($self, $cursor_class) = @_;
  if ($cursor_class) {
    $_->cursor($cursor_class) for $self->all_storages;
  }
  return $self->master->cursor;
}

sub unsafe {
  my $self = shift;
  if (@_) {
    $_->unsafe(@_) for $self->all_storages;
  }
  return $self->master->unsafe;
}

sub disable_sth_caching {
  my $self = shift;
  if (@_) {
    $_->disable_sth_caching(@_) for $self->all_storages;
  }
  return $self->master->disable_sth_caching;
}


sub lag_behind_master {
  my $self = shift;
  my @replicants = $self->pool->all_replicants;
  return unless @replicants;
  return List::Util::max(map { $_->lag_behind_master } @replicants);
}

sub is_replicating {
  my $self = shift;
  my @replicants = $self->pool->all_replicants;
  return 0 unless @replicants;
  return (grep { $_->is_replicating } @replicants) == @replicants;
}

sub connect_call_datetime_setup {
  my $self = shift;
  $_->connect_call_datetime_setup(@_) for $self->all_storages;
}

sub connect_call_rebase_sqlmaker {
  my ($self, @args) = @_;
  $_->connect_call_rebase_sqlmaker(@args) for $self->all_storages;
}

sub _populate_dbh {
  my $self = shift;
  $_->_populate_dbh(@_) for $self->all_storages;
}

sub _connect {
  my $self = shift;
  $_->_connect(@_) for $self->all_storages;
}

sub _determine_driver {
  my $self = shift;
  $_->_determine_driver(@_) for $self->all_storages;

  # ... and record it on THIS object too. The parameterized around at the top
  # of DBIO::Storage::DBI guards on the raw hash slot ($_[0]{_driver_determined},
  # not the accessor) and, when it is false, calls _determine_driver and then
  # re-enters the wrapped method with goto. Our _driver_determined accessor
  # forwards to the backends and never touches this object's slot, so the guard
  # stayed false forever and the wrapped method span in an unbounded goto loop
  # (constant stack, no recursion warning) the moment it was called on a
  # replicated storage with connect info. DBIO::Test::Storage sets the same raw
  # slot for the same reason.
  #
  # Delegating a wrapped method takes it out of the loop's reach --
  # the glob installed at the bottom of this file overrides the around, so
  # sqlt_type, the capability entry points and friends never enter it on this
  # invocant (the master runs its own around). The marker is still load-bearing
  # for the methods on that list which are *not* delegated: cursor_class (every
  # ResultSet asks the schema storage for it) and deployment_statements.
  $self->{_driver_determined} = 1;
}

sub _driver_determined {
  my $self = shift;
  if (@_) {
    $_->_driver_determined(@_) for $self->all_storages;
  }
  return $self->master->_driver_determined;
}

sub _init {
  my $self = shift;
  $_->_init(@_) for $self->all_storages;
}

sub _run_connection_actions {
  my $self = shift;
  $_->_run_connection_actions(@_) for $self->all_storages;
}

sub _do_connection_actions {
  my $self = shift;
  if (@_) {
    $_->_do_connection_actions(@_) for $self->all_storages;
  }
}

sub _parse_connect_info {
  my ($self, $info) = @_;

  my %replicated_opts;
  my %master_opts;
  my @filtered;

  foreach my $arg (@{$info || []}) {
    # An AccessBroker is a CredentialSource, not an options hash. It is a
    # blessed object whose reftype happens to be HASH, so it must be passed
    # through untouched — never copied/merged, or its guts get splatted into
    # master_opts. The master Storage::DBI detects and consumes it downstream.
    if (DBIO::Util::is_access_broker($arg)) {
      push @filtered, $arg;
      next;
    }
    if ((reftype($arg) || '') eq 'HASH') {
      my %copy = %$arg;

      for my $key (qw(pool_type balancer_type backend_storage_class)) {
        $replicated_opts{$key} = delete $copy{$key} if exists $copy{$key};
      }

      for my $key (qw(pool_args balancer_args)) {
        if (exists $copy{$key}) {
          $replicated_opts{$key} = $self->_merge_hashrefs(delete $copy{$key}, $replicated_opts{$key} || {});
        }
      }

      # What is kept here is every replicant's defaults. Of the keys naming
      # the connection itself, none that names the master's server passes
      # on -- a replicant is a different server, and given a dsn of its own
      # it would take the master's dbname, host and port as DBI attributes
      # (karr k248). The master's credentials stay: a hash-form replicant
      # naming none inherits them (_merge_replicant_connect_info decides).
      %master_opts = %{ $self->_merge_hashrefs(\%copy, \%master_opts) };
      my %credential = map { $_ => 1 } $self->_replicant_inherited_credential_keys;
      delete @master_opts{ grep { !$credential{$_} } $self->_access_broker_identity_keys };

      push @filtered, \%copy;
    }
    else {
      push @filtered, $arg;
    }
  }

  $replicated_opts{master_connect_opts} = \%master_opts;
  return (\@filtered, \%replicated_opts);
}

sub _merge_replicant_connect_info {
  my ($self, $connect_info) = @_;
  $connect_info = [ $connect_info ] if reftype($connect_info) ne 'ARRAY';

  # A broker-backed replicant ([ $broker ] or [ $broker, \%options ]): the
  # broker is a CredentialSource, not an options hash, and passes through by
  # identity -- merged into a hash, the blessed object would be shredded. The
  # master's connect options go beside it, where the replicant Storage::DBI
  # reads them (ADR 0030 addendum II, karr k243/k246), under the replicant's
  # own -- the same defaults a DSN replicant gets below. Those naming the
  # connection itself stay behind: which database, and as whom, is this
  # broker's answer.
  if (DBIO::Util::is_access_broker($connect_info->[0])) {
    $self->throw_exception(
      'A broker-backed replicant takes [ $broker ] or [ $broker, \%options ]'
    ) unless $self->_is_access_broker_connect_info($connect_info);

    my %master_opts = %{ $self->_master_connect_info_opts || {} };
    delete @master_opts{ $self->_access_broker_identity_keys };

    my $opts = $self->_merge_hashrefs($connect_info->[1], \%master_opts);
    return %$opts ? [ $connect_info->[0], $opts ] : [ $connect_info->[0] ];
  }

  $self->throw_exception('coderef replicant connect_info not supported')
    if ref $connect_info->[0] && reftype($connect_info->[0]) eq 'CODE';

  my @copy = @$connect_info;
  my $i = 0;
  $i++ while $i < @copy && (reftype($copy[$i]) || '') ne 'HASH';
  # A DBI-form replicant without an options hash gets one in the attributes
  # position, after its dsn, user and password, given or not. Appended to a
  # short [ $dsn ] or [ $dsn, $user ], it took the place of a credential, and
  # the master's options -- a hash-form master's password among them -- went
  # to DBI->connect as the replicant's user or password (karr k248).
  $i = 3 if $i == @copy && $i > 0 && $i < 3;
  $copy[$i] = {} unless $copy[$i];

  my @hashes = @copy[$i .. $#copy];
  $self->throw_exception('invalid connect_info options')
    if grep { (reftype($_) || '') ne 'HASH' } @hashes;
  $self->throw_exception('too many hashrefs in connect_info')
    if @hashes > 2;

  my %opts;
  for my $hash (reverse @hashes) {
    %opts = %{ $self->_merge_hashrefs($hash, \%opts) };
  }

  splice @copy, $i + 1, $#copy - $i, ();

  # The master's options, under the replicant's own. Nothing naming the
  # master's server is among them (_parse_connect_info); its user and
  # password are, and where they go depends on the replicant's form. Given
  # in hash form ({ dsn => ... }), this hash is read for its credentials: one
  # naming none inherits the master's -- unless it brings its own dbh_maker,
  # which takes none. Given in DBI form ([ $dsn, $user, $pass, \%attrs ]),
  # its credentials are positional and this hash is its DBI attributes: the
  # master's password would reach its DBI->connect as one (karr k248).
  my $positional = $i > 0;
  my %master_opts = %{ $self->_master_connect_info_opts || {} };
  delete @master_opts{ $self->_replicant_inherited_credential_keys }
    if $positional || exists $opts{dbh_maker};

  %opts = %{ $self->_merge_hashrefs(\%opts, \%master_opts) };
  $copy[$i] = \%opts;

  return \@copy;
}

# The keys naming the master's connection that a replicant may inherit: its
# credentials, and only into a hash-form replicant's hash. Every other key of
# _access_broker_identity_keys stays the master's.
sub _replicant_inherited_credential_keys { qw( user password ) }

sub _merge_hashrefs {
  my ($self, $left, $right) = @_;
  $left  ||= {};
  $right ||= {};

  my %merged = %{$right};
  for my $key (keys %{$left}) {
    if (ref($left->{$key}) eq 'HASH' && ref($merged{$key}) eq 'HASH') {
      $merged{$key} = $self->_merge_hashrefs($left->{$key}, $merged{$key});
    }
    else {
      $merged{$key} = $left->{$key};
    }
  }

  return \%merged;
}


for my $method (@writer_methods) {
  no strict 'refs';
  my $orig = __PACKAGE__->can($method);
  *{__PACKAGE__ . "::$method"} = set_subname $method => sub {
      my $self = shift;
      return $orig->($self, @_) if !ref $self && $orig;
      my $handler = $self->write_handler;
      return $handler->$method(@_);
    };
}

for my $method (@reader_methods) {
  no strict 'refs';
  my $orig = __PACKAGE__->can($method);
  *{__PACKAGE__ . "::$method"} = set_subname $method => sub {
      my $self = shift;
      return $orig->($self, @_) if !ref $self && $orig;
      my $handler = $self->read_handler;
      return $handler->$method(@_);
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated::Storage - Replicated DBI storage coordinator

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

  my $schema = MyApp::Schema->connect($master_dsn, $user, $pass, {
    storage_type  => '+DBIO::Replicated::Storage',
    balancer_type => 'DBIO::Replicated::Balancer::First',
  });

  $schema->storage->connect_replicants(
    [ $replica_dsn_1, $user, $pass ],
    [ $replica_dsn_2, $user, $pass ],
  );

  # Temporarily force reads to the master
  $schema->storage->execute_reliably(sub {
    my $artist = $schema->resultset('Artist')->find(1);
    ...
  });

See F<t/test/08_replicated.t> for a runnable example.

=head1 DESCRIPTION

L<DBIO::Replicated::Storage> coordinates one master backend plus zero or more
replicant backends.

The master backend handles write-oriented work such as inserts, updates,
deletes, transactions, deploy operations, and connection-time setup.
Read-oriented methods are delegated to the current read handler, which is a
balancer by default.

Replicants are managed through L<DBIO::Replicated::Pool>. The pool can use
replication hooks such as C<is_replicating> and C<lag_behind_master> when the
underlying driver storage provides them.

The replicated layer consumes a small set of connect-info options for itself:
C<pool_type>, C<pool_args>, C<balancer_type>, C<balancer_args>, and
C<backend_storage_class>. All remaining connect attributes are passed through
to the master backend.

=head1 METHODS

=head2 new

  my $storage = DBIO::Replicated::Storage->new($schema, \%args);

Normally created by the schema from C<storage_type>. C<%args> may set
C<pool_type> (default L<DBIO::Replicated::Pool>), C<pool_args>,
C<balancer_type> (default L<DBIO::Replicated::Balancer::First>; a leading
C<::> is expanded to C<DBIO::Replicated::Balancer::>), C<balancer_args> and
C<backend_storage_class>, the class every backend storage is built from:
the storage class of the driver the schema declares, which
L<DBIO::Replicated/connection> passes here (ADR 0067). Left out, it is the
generic L<DBIO::Storage::DBI>, which has no driver and is refused at the
first use of a backend. Each is also a plain read/write accessor of
the same name. The same options are usually given in the connect info
instead, see L</connect_info>.

=head2 master

The master L<DBIO::Replicated::Backend::Master>, built on first use from
C<backend_storage_class>. Also a setter.

=head2 pool

The L<DBIO::Replicated::Pool> of replicants, built on first use through
L</create_pool> with the master, C<backend_storage_class> and C<pool_args>.
Also a setter.

=head2 balancer

The read balancer, built on first use through L</create_balancer> with the
pool, the master and C<balancer_args>. Also a setter.

=head2 read_handler

The object every read method is sent to (see L</DELEGATED METHODS>). Defaults
to L</balancer>; L</set_reliable_storage> and L</execute_reliably> point it
at the master. Also a setter.

=head2 write_handler

The object every write method is sent to. Defaults to L</master>. Also a
setter.

=head2 create_pool

=head2 create_balancer

  my $pool     = $storage->create_pool(%args);
  my $balancer = $storage->create_balancer(%args);

Load C<pool_type> / C<balancer_type> and call its C<new> with C<%args>.

=head2 connect_info

Accepts the normal DBI connect-info arrayref used for the master connection.

Replicated-specific options can be supplied in connect-info hashrefs:

=over 4

=item *

C<pool_type> / C<pool_args>

=item *

C<balancer_type> / C<balancer_args>

=item *

C<backend_storage_class>

=back

These options are consumed by the replicated layer. Remaining DBI attributes
are passed through to the master backend and are also used as defaults when
replicant connect info is merged later; L</connect_replicants> says which.

=head2 connect_replicants

  $storage->connect_replicants(
    [ $dsn_1, $user, $pass ],
    [ $dsn_2, $user, $pass, { RaiseError => 1 } ],
  );

Connects one or more replicant backends and adds them to the pool.

Every replicant inherits the options the master was connected with -- its DBI
attributes, C<on_connect_do> / C<on_connect_call>, C<quote_names> and the other
storage and SQL maker options -- merged into the replicant's connect-info
hashref under its own, which win.

What names the master's server is never inherited: C<dsn>, C<dbh_maker>,
C<dbname>, C<host> and C<port>. A replicant is a different server; it says
which in its own connect info.

The master's C<user> and C<password> (given when the master was connected in
hash form, C<< { dsn => ..., user => ..., password => ... } >>) depend on the
replicant's form:

=over 4

=item *

A replicant in hash form, C<< { dsn => $dsn, ... } >>, reads C<user> and
C<password> from its hash as its credentials. One that names none of its own
inherits the master's; one with its own keeps them. One with its own
C<dbh_maker> inherits neither.

=item *

A replicant in DBI form, C<< [ $dsn, $user, $pass, \%attrs ] >>, connects with
the credentials in its positions, or none. Its hash is its DBI attributes, so
the master's C<user> and C<password> are never put there.

=back

A replicant whose connection comes from a L<DBIO::AccessBroker> is given as
C<< [ $broker ] >> or C<< [ $broker, \%options ] >>. It gets the master's
connect attributes the same way, in the hash beside its broker -- except
C<dsn>, C<user>, C<password>, C<dbh_maker>, C<dbname>, C<host> and C<port>:
which database, and as whom, is its broker's answer
(L<DBIO::Storage::DBI/connect_info>).

=head2 replicants

The pool's hashref of replicant backends, keyed by name.

=head2 has_replicants

The number of replicants in the pool.

=head2 all_storages

The master followed by every replicant backend.

=head2 execute_reliably

  $storage->execute_reliably(sub { ... });

Temporarily forces reads to use the master backend while the supplied coderef
runs.

=head2 set_reliable_storage

Persistently switches the current read handler to the master backend.

=head2 set_balanced_storage

Restores the balancer as the current read handler after
L</set_reliable_storage>.

=head2 connected

True when the master is connected and at least one replicant is.

=head2 ensure_connected

=head2 set_schema

=head2 disconnect

=head2 connect_call_datetime_setup

=head2 connect_call_rebase_sqlmaker

Run on every backend (L</all_storages>); C<set_schema> also sets the schema
on this object.

=head2 debug

=head2 cursor_class

=head2 cursor

=head2 unsafe

=head2 disable_sth_caching

With an argument, set it on every backend; always return the master's value.

=head2 debugobj

=head2 debugfh

=head2 debugcb

Forwarded to the master only.

=head2 lag_behind_master

The largest C<lag_behind_master> of all replicants, or nothing when there
are none.

=head2 is_replicating

True when there is at least one replicant and every replicant reports
C<is_replicating>.

=head1 CAPABILITIES ARE THE MASTER'S

A capability (see L<DBIO::Storage::DBI::Capabilities>) is a fact about the
engine on the other end of a connection: either declared outright by the driver
storage class (C<_use_X>) or probed from the live C<$dbh> and memoised per
connection (C<_supports_X>). A replicated storage has neither a driver class nor
a handle of its own, so B<every capability question is answered by the master
backend> -- reads and writes both, C<_use_X> and C<_supports_X> alike:

  # answers with the master's driver storage, not with the base-class default
  $schema->storage->_use_supports_upsert;

  # ... and a declaration lands on the master, where the answer is read from
  $schema->storage->_use_supports_if_exists(1);

The master is the right authority because it owns DDL and the whole write path,
and the engine whose version decides a capability is the one the master is
connected to. This is the same reason C<sqlt_type> and C<sql_maker> are
delegated to it.

The connection's namespace follows the same line: C<connection_schema> -- the
C<schema> connect key, which reaches the master and every replicant -- is
answered by the master backend, C<undef> when the connection names none.

=head2 Mixed pools

The consequence is deliberate and worth stating outright: if the master and a
replicant run engine versions that B<disagree> about a capability, DBIO answers
with the master's and never notices the difference. Nothing in this class
reconciles the two, and nothing warns.

A pool whose members disagree about a capability is a misconfiguration, not a
supported topology. A replicant is expected to be a replica of the master --
same engine, same major version, same feature set. When it is not, the
divergence has to be resolved at the deployment level (upgrade the odd node out,
or take it out of the pool), because a query planned against the master's
capabilities can be dispatched to any replicant in the pool at any time.

=head1 DELEGATED METHODS

The storage methods below are not answered by this object. Called on an
instance, each is forwarded to L</write_handler> (the master) or
L</read_handler> (by default the L<DBIO::Replicated::Balancer>, which picks
a replicant, see L<DBIO::Replicated::Balancer/select>); called on the class,
the inherited L<DBIO::Storage::DBI> method runs instead. See
L<DBIO::Storage::DBI> for what each does.

Sent to the master -- the write path, transactions, DDL, SQL generation and
every capability question (see L</CAPABILITIES ARE THE MASTER'S>):

=over 4

=item sql_maker

=item sql_maker_class

=item sqlt_type

=item datetime_parser

=item datetime_parser_type

=item build_datetime_parser

=item last_insert_id

=item insert

=item insert_bulk

=item update

=item delete

=item dbh

=item dbh_do

=item txn_begin

=item txn_do

=item txn_commit

=item txn_rollback

=item txn_scope_guard

=item transaction_depth

=item deferred_rollback

=item auto_savepoint

=item savepoints

=item svp_begin

=item svp_release

=item svp_rollback

=item deploy

=item with_deferred_fk_checks

=item is_datatype_numeric

=item relname_to_table_alias

=item bind_attribute_by_data_type

=item get_dbms_capability

=item set_dbms_capability

=item get_use_dbms_capability

=item set_use_dbms_capability

=item connection_schema

=back

plus the private statement, connection and engine-fact hooks listed in
C<@writer_methods> in the source.

Sent to the read handler:

=over 4

=item select

=item select_single

=item columns_info_for

=back

plus the private read paths C<_select>, C<_dbh_columns_info_for>,
C<_execute_rendered>, C<_explain_query> and C<_prepare_rendered>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
