package DBIO::Forked::Storage;
# ABSTRACT: Fork-based async storage skeleton — make any sync DBIO driver async

use strict;
use warnings;
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
    connect_info => undef,
    debug        => $ENV{DBIO_TRACE} || 0,
  }, $class;
  Scalar::Util::weaken($self->{schema}) if ref $self->{schema};
  $self;
}


sub future_class { 'DBIO::Forked::Future' }

# --- Connect Info ---


sub connect_info {
  my ($self, $info) = @_;
  $self->{connect_info} = $info if defined $info;
  return $self->{connect_info};
}

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
  return DBIO::Forked::Future->new(read_fh => $rh, pid => $pid);
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
#   * update/delete/txn_do -- pass the sync return through unchanged.
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

DBIO::Forked::Storage - Fork-based async storage skeleton — make any sync DBIO driver async

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fork-based async storage backend subclassing core L<DBIO::Storage::Async>. It
makes B<any> sync DBIO driver async without an async-capable client and without
an event loop, via C<fork()>-per-query (Model A, see L<DBIO::Forked>): the
child reconnects the sync driver fresh from the stored DBI-form connect info,
runs the driver's B<ordinary> sync CRUD (no SQL is re-implemented here),
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

Store the DBI-form connect info verbatim (the core resolver passes the sync
storage's C<< _connect_info >> straight through). Returns the stored value.

B<Informational in Model A>: the forked child runs the inherited sync storage's
own CRUD, and that storage reconnects itself in the child via its inherited
fork handling (see C<docs/adr/0002>). This stored connect info is therefore
B<not consumed> on the query path -- it is kept as latent diagnostics / raw
material for a possible future "fresh storage" variant.

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
from L</get> (see L</_serialization_error>). Return plain data (ids, hashrefs of
column values), not live result objects.

=item *

B<The body must use sync operations only.> Calling a C<*_async> method inside
the body would fork again from within the child. Use the ordinary sync CRUD
(C<< $schema->resultset(...)->... >>) inside a C<txn_do_async> body.

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
wrappers): each forks per query and roundtrips through L</_run_forked> and
L<DBIO::Forked::Future>. L</txn_do_async> runs the whole transaction in one
child; see the two caller-facing limits documented on it.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
