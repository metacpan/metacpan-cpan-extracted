package DBIO::Replicated::Storage;
# ABSTRACT: Replicated DBI storage coordinator

use strict;
use warnings;

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
);

my @reader_methods = qw(
  select select_single columns_info_for _dbh_columns_info_for _select
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
  $self->{debug} = 1
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
  return $type->new(%args);
}

sub create_balancer {
  my ($self, %args) = @_;
  my $type = $self->balancer_type;
  $self->ensure_class_loaded($type);
  return $type->new(%args);
}

sub _build_master {
  my $self = shift;
  my $storage_class = $self->backend_storage_class;
  $self->ensure_class_loaded($storage_class);

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

sub _rebless {
  my $self = shift;
  $_->_rebless(@_) for $self->all_storages;
}

sub _determine_driver {
  my $self = shift;
  $_->_determine_driver(@_) for $self->all_storages;
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

      %master_opts = %{ $self->_merge_hashrefs(\%copy, \%master_opts) };
      delete $master_opts{dsn};

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

  # A broker-backed replicant ([$broker]) is a CredentialSource, not an
  # options arrayref. Pass it through untouched — never merge master
  # connect opts into it, which would shred the blessed object. The
  # replicant Storage::DBI detects and consumes the broker on connect.
  if (@$connect_info == 1 && DBIO::Util::is_access_broker($connect_info->[0])) {
    return [ $connect_info->[0] ];
  }

  $self->throw_exception('coderef replicant connect_info not supported')
    if ref $connect_info->[0] && reftype($connect_info->[0]) eq 'CODE';

  my @copy = @$connect_info;
  my $i = 0;
  $i++ while $i < @copy && (reftype($copy[$i]) || '') ne 'HASH';
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

  my %master_opts = %{ $self->_master_connect_info_opts || {} };
  if (exists $opts{dbh_maker}) {
    delete @master_opts{qw/dsn user password/};
  }
  delete $master_opts{dbh_maker};

  %opts = %{ $self->_merge_hashrefs(\%opts, \%master_opts) };
  $copy[$i] = \%opts;

  return \@copy;
}

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

version 0.900000

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
replicant connect info is merged later.

=head2 connect_replicants

  $storage->connect_replicants(
    [ $dsn_1, $user, $pass ],
    [ $dsn_2, $user, $pass, { RaiseError => 1 } ],
  );

Connects one or more replicant backends and adds them to the pool.

Any connect attributes captured from the master connection are merged into each
replicant connect-info hashref unless explicitly overridden.

=head2 execute_reliably

  $storage->execute_reliably(sub { ... });

Temporarily forces reads to use the master backend while the supplied coderef
runs.

=head2 set_reliable_storage

Persistently switches the current read handler to the master backend.

=head2 set_balanced_storage

Restores the balancer as the current read handler after
L</set_reliable_storage>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
