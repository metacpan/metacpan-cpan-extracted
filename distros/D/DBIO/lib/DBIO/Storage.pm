package DBIO::Storage;
# ABSTRACT: Generic Storage Handler

use strict;
use warnings;

use base qw/DBIO::Base/;
use mro 'c3';

{
  package # Hide from PAUSE
    DBIO::Storage::NESTED_ROLLBACK_EXCEPTION;
  use base 'DBIO::Exception';
}

use DBIO::Carp;
use DBIO::Storage::BlockRunner;
use Scalar::Util qw/blessed weaken/;
use DBIO::Storage::TxnScopeGuard;
use Try::Tiny;
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  debug schema transaction_depth deferred_rollback auto_savepoint savepoints
  access_broker access_broker_mode
/);
__PACKAGE__->mk_group_accessors(component_class => 'cursor_class');

__PACKAGE__->cursor_class('DBIO::Cursor');

sub cursor { shift->cursor_class(@_); }



sub new {
  my ($self, $schema) = @_;

  $self = ref $self if ref $self;

  my $new = bless( {
    transaction_depth => 0,
    savepoints => [],
  }, $self);

  $new->set_schema($schema);
  $new->debug(1)
    if $ENV{DBIO_TRACE};

  $new;
}



sub set_schema {
  my ($self, $schema) = @_;
  $self->schema($schema);
  weaken $self->{schema} if ref $self->{schema};
}


sub set_access_broker {
  my ($self, $broker, $mode) = @_;

  $self->throw_exception('set_access_broker() requires a broker object')
    unless blessed($broker);

  $self->throw_exception(
    'set_access_broker() requires a DBIO::AccessBroker instance'
  ) unless $broker->isa('DBIO::AccessBroker');

  $self->access_broker($broker);
  $self->access_broker_mode($mode || 'write');
  $broker->set_storage($self);

  return $self;
}


sub clear_access_broker {
  my $self = shift;
  $self->access_broker(undef);
  $self->access_broker_mode(undef);
  return $self;
}


sub current_access_broker_connect_info {
  my ($self, $mode) = @_;
  my $broker = $self->access_broker or return;
  $mode ||= $self->access_broker_mode || 'write';
  return $broker->current_connect_info_for_storage($self, $mode);
}


sub connected { die "Virtual method!" }


sub disconnect { die "Virtual method!" }


sub ensure_connected { die "Virtual method!" }



sub throw_exception {
  my $self = shift;

  if (ref $self and $self->schema) {
    $self->schema->throw_exception(@_);
  }
  else {
    DBIO::Exception->throw(@_);
  }
}



sub txn_do {
  my $self = shift;
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  DBIO::Storage::BlockRunner->new(
    storage => $self,
    wrap_txn => 1,
    retry_handler => sub {
      $_[0]->failed_attempt_count == 1
        and
      ! $_[0]->storage->connected
    },
  )->run(@_);
}



sub txn_begin {
  my $self = shift;
  $self->_throw_deferred_rollback if $self->deferred_rollback;
  $self->_assert_transaction_safe_access_broker;

  if($self->transaction_depth == 0) {
    $self->debugobj->txn_begin()
      if $self->debug;
    $self->_exec_txn_begin;
  }
  elsif ($self->auto_savepoint) {
    $self->svp_begin;
  }
  $self->{transaction_depth}++;

}

sub _assert_transaction_safe_access_broker {
  my $self = shift;

  return if $self->{_access_broker_txn_safety_checked};
  return if $self->transaction_depth;

  my $broker = $self->access_broker or return;
  return if $broker->is_transaction_safe;

  my @reasons;
  push @reasons, 'credential rotation' if $broker->has_rotating_credentials;
  my $reason = @reasons
    ? join(' and ', @reasons)
    : 'broker-specific transaction safety constraints';

  if ($ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS}) {
    carp sprintf(
      'Starting a transaction with unsafe AccessBroker %s via override: %s',
      ref($broker) || $broker,
      $reason,
    );
    return;
  }

  $self->throw_exception(sprintf(
    'Refusing to start a transaction with unsafe AccessBroker %s: %s can break transactional consistency',
    ref($broker) || $broker,
    $reason,
  ));
}



sub txn_commit {
  my $self = shift;
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  if ($self->transaction_depth == 1) {
    $self->debugobj->txn_commit() if $self->debug;
    $self->_exec_txn_commit;
    $self->{transaction_depth}--;
    $self->savepoints([]);
  }
  elsif($self->transaction_depth > 1) {
    $self->{transaction_depth}--;
    $self->svp_release if $self->auto_savepoint;
  }
  else {
    $self->throw_exception( 'Refusing to commit without a started transaction' );
  }
}



sub txn_rollback {
  my $self = shift;

  if ($self->transaction_depth == 1) {
    $self->debugobj->txn_rollback() if $self->debug;
    $self->_exec_txn_rollback;
    $self->{transaction_depth}--;
    $self->savepoints([]);
    $self->deferred_rollback(undef);
  }
  elsif ($self->transaction_depth > 1) {
    $self->{transaction_depth}--;

    if ($self->auto_savepoint) {
      $self->svp_rollback;
      $self->svp_release;
    }
    else {
      $self->deferred_rollback(1);
      DBIO::Storage::NESTED_ROLLBACK_EXCEPTION->throw(
        "A txn_rollback in nested transaction is ineffective! (depth $self->{transaction_depth})"
      );
    }
  }
  else {
    $self->throw_exception( 'Refusing to roll back without a started transaction' );
  }
}


sub _throw_deferred_rollback {
  DBIO::Storage::NESTED_ROLLBACK_EXCEPTION->throw(
    "You are in the middle of a deferred rollback from a nested transaction."
    ." No further statements can be executed until the rollback is complete."
  );
}



sub svp_begin {
  my ($self, $name) = @_;

  $self->throw_exception ("You can't use savepoints outside a transaction")
    unless $self->transaction_depth;

  my $exec = $self->can('_exec_svp_begin')
    or $self->throw_exception ("Your Storage implementation doesn't support savepoints");

  # This could happen if savepoints were not enabled at the time rollback was called
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  $name = $self->_svp_generate_name
    unless defined $name;

  push @{ $self->{savepoints} }, $name;

  $self->debugobj->svp_begin($name) if $self->debug;

  $exec->($self, $name);
}


sub _svp_generate_name {
  my ($self) = @_;
  return 'savepoint_'.scalar(@{ $self->{'savepoints'} });
}




sub svp_release {
  my ($self, $name) = @_;

  $self->throw_exception ("You can't use savepoints outside a transaction")
    unless $self->transaction_depth;

  my $exec = $self->can('_exec_svp_release')
    or $self->throw_exception ("Your Storage implementation doesn't support savepoints");

  # This could happen if savepoints were not enabled at the time rollback was called
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  if (defined $name) {
    my @stack = @{ $self->savepoints };
    my $svp = '';

    while( $svp ne $name ) {

      $self->throw_exception ("Savepoint '$name' does not exist")
        unless @stack;

      $svp = pop @stack;
    }

    $self->savepoints(\@stack); # put back what's left
  }
  else {
    $name = pop @{ $self->savepoints }
      or $self->throw_exception('No savepoints to release');;
  }

  $self->debugobj->svp_release($name) if $self->debug;

  $exec->($self, $name);
}



sub svp_rollback {
  my ($self, $name) = @_;

  $self->throw_exception ("You can't use savepoints outside a transaction")
    unless $self->transaction_depth;

  my $exec = $self->can('_exec_svp_rollback')
    or $self->throw_exception ("Your Storage implementation doesn't support savepoints");

  # This could happen if savepoints were not enabled at the time rollback was called
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  if (defined $name) {
    my @stack = @{ $self->savepoints };
    my $svp;

    # a rollback doesn't remove the named savepoint,
    # only everything after it
    while (@stack and $stack[-1] ne $name) {
      pop @stack
    };

    $self->throw_exception ("Savepoint '$name' does not exist")
      unless @stack;

    $self->savepoints(\@stack); # put back what's left
  }
  else {
    $name = $self->savepoints->[-1]
      or $self->throw_exception('No savepoints to rollback');;
  }

  $self->debugobj->svp_rollback($name) if $self->debug;

  $exec->($self, $name);
}



sub txn_scope_guard {
  return DBIO::Storage::TxnScopeGuard->new($_[0]);
}


sub sql_maker { die "Virtual method!" }



sub debugfh {
    my $self = shift;

    if ($self->debugobj->can('debugfh')) {
        return $self->debugobj->debugfh(@_);
    }
}



sub debugobj {
  my $self = shift;

  if (@_) {
    return $self->{debugobj} = $_[0];
  }

  $self->{debugobj} ||= do {
    if (my $profile = $ENV{DBIO_TRACE_PROFILE}) {
      require DBIO::Storage::Debug::PrettyTrace;
      my @pp_args;

      if ($profile =~ /^\.?\//) {
        require Config::Any;

        my $cfg = try {
          Config::Any->load_files({ files => [$profile], use_ext => 1 });
        } catch {
          # sanitize the error message a bit
          $_ =~ s/at \s+ .+ Storage\.pm \s line \s \d+ $//x;
          $self->throw_exception("Failure processing \$ENV{DBIO_TRACE_PROFILE}: $_");
        };

        @pp_args = values %{$cfg->[0]};
      }
      else {
        @pp_args = { profile => $profile };
      }

      # FIXME - FRAGILE
      # Hash::Merge is a sorry piece of shit and tramples all over $@
      # *without* throwing an exception
      # This is a rather serious problem in the debug codepath
      # Insulate the condition here with a try{} until a review of
      # DBIO::Storage::Debug::PrettyTrace takes place
      # we do rethrow the error unconditionally, the only reason
      # to try{} is to preserve the precise state of $@ (down
      # to the scalar (if there is one) address level)
      #
      # Yes I am aware this is fragile and TxnScopeGuard needs
      # a better fix. This is another yak to shave... :(
      try {
        DBIO::Storage::Debug::PrettyTrace->new(@pp_args);
      } catch {
        $self->throw_exception($_);
      }
    }
    else {
      require DBIO::Storage::Statistics;
      DBIO::Storage::Statistics->new
    }
  };
}



sub debugcb {
    my $self = shift;

    if ($self->debugobj->can('callback')) {
        return $self->debugobj->callback(@_);
    }
}



sub deploy { die "Virtual method!" }


sub connect_info { die "Virtual method!" }


sub select { die "Virtual method!" }


sub insert { die "Virtual method!" }


sub update { die "Virtual method!" }


sub delete { die "Virtual method!" }


sub select_single { die "Virtual method!" }


sub select_async {
  my $self = shift;
  my $fc = $self->future_class;
  my @r = eval { $self->select(@_) };
  return $@ ? $fc->fail($@) : $fc->done(@r);
}


sub select_single_async {
  my $self = shift;
  my $fc = $self->future_class;
  my @r = eval { $self->select_single(@_) };
  return $@ ? $fc->fail($@) : $fc->done(@r);
}


sub insert_async {
  my $self = shift;
  my $fc = $self->future_class;
  my @r = eval { $self->insert(@_) };
  return $@ ? $fc->fail($@) : $fc->done(@r);
}


sub update_async {
  my $self = shift;
  my $fc = $self->future_class;
  my @r = eval { $self->update(@_) };
  return $@ ? $fc->fail($@) : $fc->done(@r);
}


sub delete_async {
  my $self = shift;
  my $fc = $self->future_class;
  my @r = eval { $self->delete(@_) };
  return $@ ? $fc->fail($@) : $fc->done(@r);
}


sub txn_do_async {
  my $self = shift;
  my $fc = $self->future_class;
  my @r = eval { $self->txn_do(@_) };
  return $@ ? $fc->fail($@) : $fc->done(@r);
}


sub future_class {
  require DBIO::Test::Future;
  'DBIO::Test::Future';
}


sub columns_info_for { die "Virtual method!" }

# Type registry: maps type names to behavior descriptors, keyed by class so
# subclasses can add or override entries. Use type_info() for MRO-aware lookup.
my %_type_registry;


sub register_type {
  my ($class, $type_name, $info) = @_;
  $_type_registry{$class}{$type_name} = $info;
}


sub type_info {
  my ($class, $type_name) = @_;
  for my $pkg (@{ mro::get_linear_isa($class) }) {
    return $_type_registry{$pkg}{$type_name}
      if exists $_type_registry{$pkg}
      && exists $_type_registry{$pkg}{$type_name};
  }
  return undef;
}


sub all_type_names {
  my ($class) = @_;
  my %seen;
  for my $pkg (@{ mro::get_linear_isa($class) }) {
    $seen{$_}++ for keys %{ $_type_registry{$pkg} || {} };
  }
  return keys %seen;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage - Generic Storage Handler

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

L<DBIO::Storage> is the abstract base class for storage backends. It contains
the generic transaction, exception, and cursor plumbing shared by concrete
storage implementations.

Most real applications use L<DBIO::Storage::DBI> or a driver-specific subclass
such as PostgreSQL, MySQL, or SQLite storage. This module is where the common
storage contract is defined.

=head1 METHODS

=head2 new

Arguments: $schema

Instantiates the Storage object.

=head2 new

=head2 set_schema

=head2 throw_exception

=head2 txn_do

=head2 txn_begin

=head2 txn_commit

=head2 txn_rollback

=head2 _throw_deferred_rollback

=head2 svp_begin

=head2 _svp_generate_name

=head2 svp_release

=head2 svp_rollback

=head2 txn_scope_guard

=head2 debugfh

=head2 debugobj

=head2 debugcb

=head2 register_type

  DBIO::PostgreSQL::Storage->register_type('jsonb', {
    cake_options => [qw(inflate_json inflate_jsonb)],
    components   => ['InflateColumn::Serializer'],
    col_attrs    => { serializer_class => 'JSON' },
  });

Registers type metadata for use by L<DBIO::Cake> and other DBIO subsystems.
Driver distributions call this in their module body to declare how their
specific types should be handled. Subclass registrations inherit from and
can override parent class registrations via normal MRO lookup.

=head2 type_info

  my $info = DBIO::PostgreSQL::Storage->type_info('jsonb');

Returns the type metadata for a given type name, walking up the MRO
so subclasses inherit and can override base type definitions.
Returns C<undef> if the type is not registered.

=head2 all_type_names

  my @types = DBIO::PostgreSQL::Storage->all_type_names;

Returns all type names registered for this class and its ancestors
(deduplicated, most-derived class wins).

=head2 set_schema

Used to reset the schema class or object which owns this
storage object, such as during L<DBIO::Schema/clone>.

=head2 set_access_broker

Attach an L<DBIO::AccessBroker> instance to this storage and set the
default broker mode (defaults to C<write>).

=head2 clear_access_broker

Detach any currently attached broker from this storage.

=head2 current_access_broker_connect_info

Return the current storage-native connect info for the requested mode.

=head2 connected

Returns true if we have an open storage connection, false
if it is not (yet) open.

=head2 disconnect

Closes any open storage connection unconditionally.

=head2 ensure_connected

Initiate a connection to the storage if one isn't already open.

=head2 throw_exception

Throws an exception - croaks.

=head2 txn_do

=over 4

=item Arguments: C<$coderef>, @coderef_args?

=item Return Value: The return value of $coderef

=back

Executes C<$coderef> with (optional) arguments C<@coderef_args> atomically,
returning its result (if any). If an exception is caught, a rollback is issued
and the exception is rethrown. If the rollback fails, (i.e. throws an
exception) an exception is thrown that includes a "Rollback failed" message.

For example,

  my $author_rs = $schema->resultset('Author')->find(1);
  my @titles = qw/Night Day It/;

  my $coderef = sub {
    # If any one of these fails, the entire transaction fails
    $author_rs->create_related('books', {
      title => $_
    }) foreach (@titles);

    return $author->books;
  };

  my $rs;
  try {
    $rs = $schema->txn_do($coderef);
  } catch {
    my $error = shift;
    # Transaction failed
    die "something terrible has happened!"
      if ($error =~ /Rollback failed/);          # Rollback failed

    deal_with_failed_transaction();
  };

In a nested transaction (calling txn_do() from within a txn_do() coderef) only
the outermost transaction will issue a L</txn_commit>, and txn_do() can be
called in void, scalar and list context and it will behave as expected.

Please note that all of the code in your coderef, including non-DBIO
code, is part of a transaction.  This transaction may fail out halfway, or
it may get partially double-executed (in the case that our DB connection
failed halfway through the transaction, in which case we reconnect and
restart the txn).  Therefore it is best that any side-effects in your coderef
are idempotent (that is, can be re-executed multiple times and get the
same result), and that you check up on your side-effects in the case of
transaction failure.

=head2 txn_begin

Starts a transaction.

See the preferred L</txn_do> method, which allows for
an entire code block to be executed transactionally.

=head2 txn_commit

Issues a commit of the current transaction.

It does I<not> perform an actual storage commit unless there's a DBIO
transaction currently in effect (i.e. you called L</txn_begin>).

=head2 txn_rollback

Issues a rollback of the current transaction (or savepoint, if
auto_savepoint is enabled, and you are in a nested transaction).

If you are in a nested transaction without auto_savepoint, rollback will
put the storage into a "deferred rollback" state and throw a
L<DBIO::Storage::NESTED_ROLLBACK_EXCEPTION> exception
to help you unwind to the outer-most transaction's scope.
Until the "deferred rollback" condition is resolved,
the storage engine will throw exceptions on any attempt to begin, commit,
or rollback a transaction.

=head2 svp_begin

Arguments: $savepoint_name?

Created a new savepoint using the name provided as argument. If no name
is provided, a random name will be used.

=head2 svp_release

Arguments: $savepoint_name?

Release the savepoint provided as argument. If none is provided,
release the savepoint created most recently. This will implicitly
release all savepoints created after the one explicitly released as well.

=head2 svp_rollback

Arguments: $savepoint_name?

Rollback to the savepoint provided as argument. If none is provided,
rollback to the savepoint created most recently. This will implicitly
release all savepoints created after the savepoint we rollback to.

=head2 txn_scope_guard

An alternative way of transaction handling based on
L<DBIO::Storage::TxnScopeGuard>:

 my $txn_guard = $storage->txn_scope_guard;

 $result->col1("val1");
 $result->update;

 $txn_guard->commit;

If an exception occurs, or the guard object otherwise leaves the scope
before C<< $txn_guard->commit >> is called, the transaction will be rolled
back by an explicit L</txn_rollback> call. In essence this is akin to
using a L</txn_begin>/L</txn_commit> pair, without having to worry
about calling L</txn_rollback> at the right places. Note that since there
is no defined code closure, there will be no retries and other magic upon
database disconnection. If you need such functionality see L</txn_do>.

=head2 sql_maker

Returns a C<sql_maker> object - normally an object of class
C<DBIO::SQLMaker>.

=head2 debug

Causes trace information to be emitted on the L</debugobj> object.
(or C<STDERR> if L</debugobj> has not specifically been set).

This is the equivalent to setting C<DBIO_TRACE> in your
shell environment.

=head2 debugfh

An opportunistic proxy to L<< ->debugobj->debugfh(@_)
|DBIO::Storage::Statistics/debugfh >>
If the currently set L</debugobj> does not have a L</debugfh> method, caling
this is a no-op.

=head2 debugobj

Sets or retrieves the object used for metric collection. Defaults to an instance
of L<DBIO::Storage::Statistics> that is compatible with the original
method of using a coderef as a callback.  See the aforementioned Statistics
class for more information.

=head2 debugcb

Sets a callback to be executed each time a statement is run; takes a sub
reference.  Callback is executed as $sub->($op, $info) where $op is
SELECT/INSERT/UPDATE/DELETE and $info is what would normally be printed.

See L</debugobj> for a better way.

=head2 cursor_class

The cursor class for this Storage object.

=head2 deploy

Deploy the tables to storage (CREATE TABLE and friends in a SQL-based
Storage class). This would normally be called through
L<DBIO::Schema/deploy>.

=head2 connect_info

The arguments of C<connect_info> are always a single array reference,
and are Storage-handler specific.

This is normally accessed via L<DBIO::Schema/connection>, which
encapsulates its argument list in an arrayref before calling
C<connect_info> here.

=head2 select

Handle a select statement.

=head2 insert

Handle an insert statement.

=head2 update

Handle an update statement.

=head2 delete

Handle a delete statement.

=head2 select_single

Performs a select, fetch and return of data - handles a single row
only.

=head2 select_async

Async variant of L</select>. Returns a L<DBIO::Future> that resolves
with the query results. Default implementation executes synchronously
and returns an immediately-resolved Future via L</future_class>.

=head2 select_single_async

Async variant of L</select_single>.

=head2 insert_async

Async variant of L</insert>.

=head2 update_async

Async variant of L</update>.

=head2 delete_async

Async variant of L</delete>.

=head2 txn_do_async

Async variant of L</txn_do>. Returns a L<DBIO::Future> that resolves
after COMMIT or rejects after ROLLBACK.

=head2 future_class

Returns the class name used to construct Future objects. Defaults to
L<DBIO::Test::Future> which resolves synchronously. Async storage
drivers override this to return their event loop's Future class.

=head2 columns_info_for

Returns metadata for the given source's columns.  This
is *deprecated*, and will be removed before 1.0.  You should
be specifying the metadata yourself if you need it.

=head1 ENVIRONMENT VARIABLES

=head2 DBIO_TRACE

If C<DBIO_TRACE> is set then trace information
is produced (as when the L</debug> method is set).

If the value is of the form C<1=/path/name> then the trace output is
written to the file C</path/name>.

This environment variable is checked when the storage object is first
created (when you call connect on your schema).  So, run-time changes
to this environment variable will not take effect unless you also
re-connect on your schema.

=head2 DBIO_TRACE_PROFILE

If C<DBIO_TRACE_PROFILE> is set,
L<DBIO::Storage::Debug::PrettyTrace> will be used to format the output
from C<DBIO_TRACE>.  The value it
is set to is the C<profile> that it will be used.  If the value is a
filename the file is read with L<Config::Any> and the results are
used as the configuration for tracing.  See L<SQL::Abstract::Tree/new>
for what that structure should look like.

=head1 SEE ALSO

L<DBIO::Storage::DBI> - reference storage implementation using
DBI and a subclass of SQL::Abstract ( or similar )

1;

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
