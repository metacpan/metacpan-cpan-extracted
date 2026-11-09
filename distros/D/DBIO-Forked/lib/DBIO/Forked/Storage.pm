package DBIO::Forked::Storage;
# ABSTRACT: Fork-per-query async storage - make any sync DBIO driver async

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::Async';

# ADR 0030: register the generic 'forked' async mode on the core base storage
# class so every DBIO driver inherits it. A connection opened with
# { async => 'forked' } then resolves its embedded async backend to this class.
# DBIO::Storage::Async extends DBIO::Storage (not ::DBI), so load ::DBI
# explicitly to reach register_async_mode, and register on it (not via __PACKAGE__,
# which does not inherit the method).
use DBIO::Storage::DBI ();
DBIO::Storage::DBI->register_async_mode( forked => __PACKAGE__ );

use Carp 'croak';
use Scalar::Util ();
use POSIX ();
use Storable ();
use DBIO::Forked::Future;
use namespace::clean;


# --- Constructor ---


sub new {
  my ($class, $schema, $args) = @_;
  my $self = bless {
    schema       => $schema,
    connect_form => undef,
    debug        => $ENV{DBIO_TRACE} || 0,
  }, $class;
  Scalar::Util::weaken($self->{schema}) if ref $self->{schema};
  $self;
}


sub future_class { 'DBIO::Forked::Future' }

# --- Connect Info ---


sub connect_info {
  my ($self, $info) = @_;
  if (defined $info) {
    # Takes the async options (async_option_names) out of the info and keeps
    # them for async_option; the access data is not kept.
    $self->_strip_private_connect_attrs($info);
    $self->{connect_form} = {
      broker   => $self->_is_access_broker_connect_info(
        ref $info eq 'ARRAY' && @$info ? [ $info->[0] ] : []
      ) ? 1 : 0,
      elements => ref $info eq 'ARRAY' ? scalar @$info : 1,
    };
  }
  return $self->{connect_form};
}


sub async_option_names { qw( statement_timeout max_in_flight ) }

# The core checks the values of its own options; this backend checks the two it
# declares.
sub _assert_async_option {
  my ($self, $name, $value) = @_;
  $self->SUPER::_assert_async_option($name, $value);
  return unless $name eq 'statement_timeout' or $name eq 'max_in_flight';

  my $valid = !ref $value && defined $value && (
    $name eq 'max_in_flight'
      ? $value =~ /\A[1-9][0-9]*\z/
      : Scalar::Util::looks_like_number($value) && $value == $value
        && abs($value) != 9**9**9 && $value > 0
  );
  croak "DBIO::Forked: connect option '$name' takes "
      . ($name eq 'max_in_flight' ? 'a positive integer' : 'a number of seconds above 0')
    unless $valid;
  return;
}


sub transport_capabilities { qw( broker_connect_options ) }

# --- Schema / introspection ---

sub schema { $_[0]->{schema} }
sub debug  { $_[0]->{debug} }

# Model A forks one short-lived child per query, so there is no persistent
# connection pool to expose (unlike DBIO::Async). Override the inherited
# abstract pool() with an explicit "not applicable" rather than the misleading
# "subclass must override" croak.
sub pool {
  croak 'DBIO::Forked uses fork-per-query (Model A); there is no connection pool';
}


sub deploy_async {
  croak 'DBIO::Forked does not support deploy_async: the forked backend carries no '
      . 'DDL deploy (fork-per-query, Model A); deploy through the sync owner with '
      . '$schema->deploy';
}

# --- Async CRUD ---


sub select_async        { my $self = shift; $self->_run_forked('select',        @_) }
sub select_single_async { my $self = shift; $self->_run_forked('select_single', @_) }
sub insert_async        { my $self = shift; $self->_run_forked('insert',        @_) }
sub update_async        { my $self = shift; $self->_run_forked('update',        @_) }
sub delete_async        { my $self = shift; $self->_run_forked('delete',        @_) }

# txn_do_async is just _run_forked('txn_do', $body, @args): the child runs the
# inherited sync storage's txn_do($body, @args), so BEGIN/body/COMMIT all happen
# in the child on its freshly-reconnected connection. See the method POD for the
# return-value and sync-only limits.
sub txn_do_async        { my $self = shift; $self->_run_forked('txn_do',        @_) }

# --- Fork-per-query seam (Model A) ---
#
# The single point where Model A is realized. One short-lived fork per query:
#
#   1. pipe() a read/write pair, then fork().
#   2. Child: run the inherited primary sync storage's ORDINARY sync CRUD via
#      L</_forked_child_run> ($schema->storage->$op, shaped to the async row
#      contract -- see that method). The sync storage handles the fork trap
#      itself -- DBIO::Storage::DBI's _verify_pid sets InactiveDestroy on PID
#      change and _get_dbh reconnects fresh before the op -- so we never touch a
#      DBI handle, set no InactiveDestroy, and replay no connect_info. Crucially
#      we call the SYNC method (e.g. select), never select_async: sync does not
#      route to the async backend (core ADR 0030), so there is no re-fork. The
#      result rows (or the error) are Storable-frozen onto the write end; then
#      _exit (NOT exit -- no DESTROY/END in the child, which would tear down
#      resources shared with the parent).
#   3. Parent: close the write end and return a DBIO::Forked::Future bound to
#      the read fd and the child pid (is_ready peeks to EOF, get blocks + thaws
#      + reaps).
#
# EOF-framed: one frozen blob per child; the child closes its write end and the
# parent reads to EOF. No length prefix, no streaming.
sub _run_forked {
  my ($self, $op, @args) = @_;

  my $max = $self->async_option('max_in_flight');
  croak 'DBIO::Forked: max_in_flight reached, the call was refused before forking'
    if defined $max && $self->_in_flight_count >= $max;

  pipe(my $rh, my $wh) or croak "DBIO::Forked: pipe failed: $!";

  my $pid = fork();
  croak "DBIO::Forked: fork failed: $!" unless defined $pid;

  if (!$pid) {
    # --- Child ---
    close $rh;
    my @res = eval { $self->_forked_child_run($op, @args) };
    my $payload = $@ ? { error => "$@" } : { rows => \@res };
    my $blob = eval { Storable::freeze($payload) };
    if (!defined $blob) {
      # The result itself would not freeze (e.g. a txn_do body returned a live
      # Row object or a closure). Send a helpful error instead of a corrupt blob.
      $blob = Storable::freeze({ error => $self->_serialization_error($op, "$@") });
    }
    print {$wh} $blob;
    close $wh;
    POSIX::_exit(0);
  }

  # --- Parent ---
  close $wh;
  my $future = DBIO::Forked::Future->new(
    read_fh => $rh,
    pid     => $pid,
    timeout => $self->async_option('statement_timeout'),
  );
  $self->_track_in_flight($future) if defined $max;
  return $future;
}

# The futures this process has forked and that may still be unresolved, held
# weakly: a dropped future is gone from the list. Only the process that forked
# them counts them; a process forked from it starts with none.
sub _track_in_flight {
  my ($self, $future) = @_;
  $self->_in_flight_count;   # prune, and reset in a new process
  push @{ $self->{in_flight} }, $future;
  Scalar::Util::weaken($self->{in_flight}[-1]);
}

# Polling each future also settles those whose child has finished or whose
# deadline has passed.
sub _in_flight_count {
  my $self = shift;
  if (($self->{in_flight_pid} || 0) != $$) {
    $self->{in_flight}     = [];
    $self->{in_flight_pid} = $$;
    return 0;
  }
  my @live = grep { defined $_ && !$_->is_ready } @{ $self->{in_flight} };
  Scalar::Util::weaken($_) for @live;
  $self->{in_flight} = \@live;
  return scalar @live;
}

# Run $op against the inherited primary sync storage in the child and shape its
# return value to the async backend contract the core *_async consumers expect
# (ADR 0031). The sync CRUD return shapes do not all match what the Future must
# resolve to, so two reads are adapted here, at the seam:
#
#   * select        -- sync select() returns an *unexecuted cursor*; draining it
#                      with ->all materializes the flat list of raw row arrayrefs
#                      a real cursor yields, which is exactly what select_async
#                      must resolve to (consumed by ResultSet::all_async /
#                      first_async, which feed the rows back through the ordinary
#                      collapse/inflate path). A storage whose select() already
#                      returns materialized rows (e.g. a fake) is passed through
#                      unchanged -- only a single blessed cursor is drained.
#   * select_single -- sync select_single() returns a flat list of column values;
#                      wrap it into a single raw-row arrayref (or empty), which is
#                      what select_single_async must resolve to (consumed by
#                      single_async / count_async, each reading one row).
#   * insert        -- sync insert() already returns the returned-columns HASHREF
#                      that Row::insert_async folds back into the object; pass it
#                      through (ADR 0031 contract).
#   * update/delete -- sync update()/delete() return ($rv, $sth, @bind) in list
#                      context and the affected-row count in scalar context. The
#                      Future resolves with the count alone (the async contract,
#                      DBIO::Storage::Async::update_async), and the statement
#                      handle would not freeze: ask for the scalar.
#   * txn_do -- pass the sync return through unchanged.
sub _forked_child_run {
  my ($self, $op, @args) = @_;
  my $storage = $self->{schema}->storage;

  if ($op eq 'select') {
    my @r = $storage->select(@args);
    return ( @r == 1 && Scalar::Util::blessed($r[0]) && $r[0]->can('all') )
      ? $r[0]->all   # real cursor -> raw rows
      : @r;          # already-materialized rows (fake storage)
  }
  elsif ($op eq 'select_single') {
    my @row = $storage->select_single(@args);
    return @row ? [ @row ] : ();
  }

  elsif ($op eq 'update' or $op eq 'delete') {
    my $count = $storage->$op(@args);
    return $count;
  }

  return $storage->$op(@args);
}

# Build a helpful error for a result that will not Storable-freeze. For txn_do
# the unserializable value is whatever the user's body returned, so the hint is
# return-value specific; for CRUD it is the driver's own rows.
sub _serialization_error {
  my ($self, $op, $err) = @_;
  return $op eq 'txn_do'
    ? 'DBIO::Forked: txn_do_async body must return Storable-serializable data '
      . '(scalars or plain array/hash refs), not live Row/ResultSet objects or '
      . "code refs: $err"
    : "DBIO::Forked: cannot serialize $op result over the pipe "
      . "(it must be plain serializable data): $err";
}

# --- Sync wrappers ---
# The sync entry points block on the forked result: run the query in a child
# and wait for it via ->get.

sub select        { my $self = shift; $self->select_async(@_)->get        }
sub select_single { my $self = shift; $self->select_single_async(@_)->get }
sub insert        { my $self = shift; $self->insert_async(@_)->get        }
sub update        { my $self = shift; $self->update_async(@_)->get        }
sub delete        { my $self = shift; $self->delete_async(@_)->get        }
sub txn_do        { my $self = shift; $self->txn_do_async(@_)->get        }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Forked::Storage - Fork-per-query async storage - make any sync DBIO driver async

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fork-based async storage backend subclassing core L<DBIO::Storage::Async>. It
makes B<any> sync DBIO driver async without an async-capable client and without
an event loop, via C<fork()>-per-query (Model A, see L<DBIO::Forked>): the
child runs the driver's B<ordinary> sync CRUD through the inherited sync storage,
which reconnects itself in the child (see C<docs/adr/0002>; the backend
holds no connect info, see L</connect_info>) -- no SQL is
re-implemented here --
serializes the result rows back over a pipe with L<Storable>, and exits; the
parent returns a L<DBIO::Forked::Future> bound to the pipe read fd.

=head1 METHODS

=head2 new

  my $storage = DBIO::Forked::Storage->new($schema);

Construct the fork-based async backend for C<$schema>. The schema reference is
weakened (the schema owns the storage, not the other way round). Connect info
is supplied separately via L</connect_info>.

=head2 future_class

Returns C<'DBIO::Forked::Future'> -- the loop-free, pipe-backed Future this
backend hands out.

=head2 connect_info

  $storage->connect_info([ $dsn, $user, $pass, \%attrs, \%dbio_opts ]);
  $storage->connect_info([ $broker ]);
  $storage->connect_info([ $broker, \%options ]);

Take the connect info the core resolver hands over (the sync storage's
C<< _connect_info >>) and keep its B<form> only: whether it is an
L<DBIO::AccessBroker> invocation, and how many elements it has. The backend
holds no access data -- no DSN, user, password, attribute, broker object or
options hash. Returns the form, a hash reference

  { broker => 0|1, elements => $n }

and the same again when called without an argument; before the first call it
returns C<undef>.

The form is all there is to keep because the forked child runs the inherited
sync storage's own CRUD, and that storage reconnects itself in the child via
its inherited fork handling (see C<docs/adr/0002>), asking the broker again
and applying the options beside it itself.

=head2 async_option_names

  my @names = DBIO::Forked::Storage->async_option_names;   # statement_timeout max_in_flight

The connect options this backend takes beside the core's (see
L<DBIO::Storage::Async/async_option_names>), given at connect time in the hash
form, the DBI form's attribute hash or beside an AccessBroker:

  MyApp::Schema->connect($dsn, $user, $pass, {
    async => 'forked', statement_timeout => 5, max_in_flight => 4,
  });

=over 4

=item * C<statement_timeout>

A number of seconds above 0; the default is none. Every forked call carries the
deadline from the moment it forks. A future still unresolved when it runs out is
ended the way L<DBIO::Forked::Future/cancel> ends it (SIGTERM, SIGKILL after one
second, reaped) and fails with C<statement_timeout exceeded>. The future checks
the clock when it is asked (C<get>, C<is_ready>, C<is_failed>), so the deadline
holds for whoever collects the result. The database decides what becomes of the
statement whose client was ended; a transaction that had not committed is rolled
back by the server.

=item * C<max_in_flight>

A positive integer; the default is no limit. The number of forked calls that may
be unresolved at once. A call made when that many are running fails, before
anything is forked, with C<max_in_flight reached>; it takes a slot again when one
of them has resolved, been cancelled or been dropped. The limit is per
connection and per process: a process forked by the application counts its own.

=back

B<Processes and connections per call.> Every C<*_async> call (and every C<txn_do_async>)
forks one child, and that child opens one database connection of its own and
runs the connection actions (C<on_connect_do> / C<on_connect_call>) on it. N
unresolved calls are N processes and N connections beside the parent's own, and
the server sees N logins at once. C<max_in_flight> bounds N.

Both values are checked when the connect info is read, which is at first async
use. An invalid value fails with a message that names the option and leaves the
value out.

=head2 transport_capabilities

  my @caps = DBIO::Forked::Storage->transport_capabilities;

Returns C<broker_connect_options>, and nothing else.

C<broker_connect_options> is the one capability core reads itself rather than
an async layer: a transport declaring it takes the connect options given
beside an L<DBIO::AccessBroker> -- C<< connect($broker, \%options) >> -- and
has them on every connection it opens. Without the declaration core refuses a
broker-backed connection whose options carry DBD attributes or C<pool_size>
at its first async use (L<DBIO::Storage::DBI/_async_storage>).

Model A keeps that promise with no code of its own. The only connection a
query ever runs on is the one the sync storage opens in the forked child, and
that storage asks the broker again and joins the options beside it into the
answer on every connect -- the same arguments its connection in the parent
got. C<pool_size> sizes nothing here, with a broker as with a DSN: there is no
pool (C<pool> croaks); it is accepted and stays out of the child's
C<< DBI->connect >>.

Still B<no> capability an async layer could require; see
L</TRANSPORT CAPABILITIES AND ASYNC LAYERS>.

=head2 deploy_async

Refused, synchronously, at the call: the C<forked> backend does not deploy. The
inherited C<deploy> runs through C<deploy_async>, so it is refused with the same
message. Deploy through the sync owner instead, C<< $schema->deploy >>, which
works on a connection opened with C<< { async => 'forked' } >> as on any other.
Without this override core would refuse with C<Subclass must override
_ddl_class>, an instruction to transport authors that says nothing to a caller.

=head2 select_async

  my $future = $storage->select_async($source, $select, $where, $attrs);

Run a SELECT in a forked child and return a L<DBIO::Forked::Future> of the
result rows.

=head2 select_single_async

Like L</select_async> but resolves to the first row only.

=head2 insert_async

  my $future = $storage->insert_async($source, \%vals);

=head2 update_async

  my $future = $storage->update_async($source, \%vals, \%where);

=head2 delete_async

  my $future = $storage->delete_async($source, \%where);

=head2 txn_do_async

  my $future = $storage->txn_do_async(sub { ... }, @args);

Run a whole transaction in a single forked child. Mechanically identical to the
CRUD path: the child runs the inherited sync storage's ordinary
C<< txn_do($body, @args) >> (core wraps BEGIN / body / COMMIT|ROLLBACK + retry
in a C<BlockRunner>), so BEGIN, the body and COMMIT/ROLLBACK all execute on the
child's own freshly-reconnected sync connection. The C<$body> closure does not
cross the process boundary as data -- it is inherited through C<fork()> from
parent memory and runs in the child; it is called as C<< $body->(@args) >> and
receives no storage argument (it closes over C<$schema>/C<$storage>).

B<Two limits the caller must respect:>

=over 4

=item *

B<The body's return value must be Storable-serializable> -- scalars or plain
array/hash refs of scalars. It is frozen back over the pipe, so a live
C<Row>/C<ResultSet> object (which drags its storage and live DB handle along)
cannot cross: such a return surfaces as a B<failed Future> with a clear message
from L<DBIO::Forked::Future/get> (see C<_serialization_error>). Return plain
data (ids, hashrefs of column values), not live result objects.

=item *

B<The body must use sync operations only.> Calling a C<*_async> method inside
the body would fork again from within the child. Nothing refuses that, and the
nested statement then runs in a child of its own, on a connection of its own
that never saw the C<BEGIN> -- outside the transaction. Use the ordinary sync
CRUD (C<< $schema->resultset(...)->... >>) inside a C<txn_do_async> body.

=back

=head1 ACTIVATION

Loading this module (or L<DBIO::Forked>) registers a generic C<forked> async
I<mode> on the core base storage class (ADR 0030):

  DBIO::Storage::DBI->register_async_mode( forked => 'DBIO::Forked::Storage' );

so every DBIO driver inherits it. A connection then opts in per-connection, at
C<connect> time:

  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'forked' });

Nothing is auto-wired: a connection opened without C<< { async => 'forked' } >>
stays fully synchronous (its C<*_async> methods croak). When the mode is chosen,
the core resolver in L<DBIO::Storage::DBI> constructs
C<< __PACKAGE__->new($schema) >> as the embedded async backend and feeds it the
sync storage's DBI-form connect info via L</connect_info>; that backend then
answers the six C<*_async> methods.

=head1 STATUS

All six C<*_async> entry points are implemented (with their sync C<< ->get >>
wrappers): each forks per query and roundtrips through C<_run_forked> and
L<DBIO::Forked::Future>. L</txn_do_async> runs the whole transaction in one
child; see the two caller-facing limits documented on it.

=head1 TRANSPORT CAPABILITIES AND ASYNC LAYERS

This backend advertises B<no> transport capability an async layer could
require. That is deliberate, not an omission. The one name
L</transport_capabilities> returns, C<broker_connect_options>, is read by core
and not by layers (L<DBIO::Storage::Async/transport_capabilities>): it says
that the connect options given beside an L<DBIO::AccessBroker> reach every
connection a query runs on, which Model A gets from the sync storage in the
child. It describes no query path and gives a layer nothing to compose on;
everything below is about the capabilities layers ask for.

Async storage layers -- the async mirrors of a driver extension -- declare what
they need from a transport via C<required_transport_capabilities>, and the
capability gate in C<< DBIO::Storage::DBI->_async_storage >> refuses to compose
a layer onto a transport that is missing one (ADR 0032 section 5 and its addendum).
Under C<< { async => 'forked' } >> that gate therefore croaks for B<every> layer
that declares a requirement -- B<and>, since the addendum, for every layer that
declares B<nothing> at all: silence is now read as "needs the default seam
C<_query_async>", not as "needs nothing". The only opt-out is an explicit
B<empty> C<required_transport_capabilities> -- an assertion the layer's author
makes and is responsible for, not something the gate infers from silence. It
is right to croak in both cases.

The reason is the execution seam, not a missing feature. Those layers compose on
the pooled-transport seam: they wrap C<_query_async> on a backend that owns the
query path -- and only that; C<_transform_sql> is transport-internal dialect
shaping that no layer ever calls (ADR 0032 section 6). Model A has no such
seam. It overrides the six C<*_async> methods directly and runs the driver's
B<ordinary sync CRUD> in the forked child (see L</txn_do_async> and
C<docs/adr/0002>), so there is no C<_query_async> for a layer to wrap: a layer
composed here would load, compose and then quietly do nothing -- exactly the
silent feature loss the gate exists to prevent.

The question is therefore not "which capability should C<DBIO::Forked> declare"
but "can an async layer compose onto Model A at all", and as things stand the
answer is no -- C<forked> serves a different seam. Note also which side owns
what: B<engine> capabilities belong to the driver's sync storage (an async
backend reaches them through C<_owner_storage>), while B<transport>
capabilities describe what the backend's own query path offers. Model A has no
query path of its own to describe, and that is the point.

For callers:

=over 4

=item *

An extension whose async mirror declares C<required_transport_capabilities>
cannot ride the C<forked> mode. Use a transport that owns the query path
(C<future_io>, C<ev>), or run that extension's work synchronously.

=item *

Do not "fix" the croak by advertising a capability here. Advertising one that
this backend cannot honour lets the layer compose and then not work, turning a
loud and accurate refusal into a silent failure. C<broker_connect_options> is
no precedent for it: that one is honoured, and no layer asks for it.

=item *

Making Model A layerable at all would need its own capability axis -- a name for
"the child runs the driver's sync CRUD" -- that a forked-aware layer would
require. That is a core / family-wide decision, and only worth making once
somebody actually builds such a layer.

=item *

A layer that genuinely needs nothing from the transport can say so with an
explicit B<empty> C<required_transport_capabilities> list -- that declaration,
not silence, is what the gate now accepts as "compose me anywhere". It is the
only route by which this distribution could ever carry a layer without first
needing the capability axis from the previous point.

=back

=head1 CONNECTION ACTIONS IN THE CHILD

Connection actions configured on the sync storage -- C<on_connect_do> and
C<on_connect_call> -- run again in every forked child, with no code in this
distribution and nothing for the caller to enable. It falls out of Model A: the
child's first DB op goes through the inherited sync storage, whose C<_verify_pid>
sees the new PID and makes C<_get_dbh> reconnect; that reconnect is the ordinary
C<_connect>, which calls C<_run_connection_actions>. Every child therefore starts
from a connection set up exactly like the parent's -- session settings, encodings,
C<SET search_path>, a C<connect_call_*> method (see C<docs/adr/0002> and its
addendum, covered by C<t/05-sqlite-live.t>).

This is B<not> the C<on_connect_replay> transport capability, and this backend
does not advertise it. That capability makes a different promise -- a pooled
transport replaying connect actions onto connections it opens outside the sync
connect path -- and advertising it here would let layers compose that cannot work
over Model A (see L</TRANSPORT CAPABILITIES AND ASYNC LAYERS>).

=head1 ROTATING BROKERS AND AN EXPIRED LEASE

The child asks the L<DBIO::AccessBroker> again for the connection it opens, and
whatever it fetches dies with it: the child is a copy, so a refresh done there
never reaches the parent. If the parent holds a lease that has run out
(C<needs_refresh> true in the parent) and issues only C<*_async> calls, every
forked query therefore refreshes the broker itself -- with
L<DBIO::AccessBroker::Vault>, one vault read and one new lease per query -- while
the parent's broker stays unchanged and still considers its lease expired. Only
a reconnect of the parent (which asks the broker itself) ends that; its later
children inherit the new lease and read nothing. While the lease is good, no
child reads the vault. This follows from Model A (one connection per child, no
pool, no shared state) and is pinned in C<t/09-broker-in-child.t>, section 3.
An alternative, the parent refreshing before it forks, is not implemented.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
