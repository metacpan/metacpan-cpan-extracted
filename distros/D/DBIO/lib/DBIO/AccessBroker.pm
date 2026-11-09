# ABSTRACT: Credential lifecycle for DBIO connections
package DBIO::AccessBroker;

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp qw(croak);
use Scalar::Util qw(blessed weaken refaddr);
use DBIO::Exception ();
use namespace::clean;


# A CredentialSource: supplies connect info for exactly one backend identity.
# It provides credentials — it does NOT route. Read/write routing and the
# host topology belong to DBIO::Replicated, never here.
#
# Storage-agnostic: works with both Storage::DBI and Storage::Async. The
# primary interface is connect_info_for_storage($storage), which returns
# storage-native connection parameters. Legacy connect_info_for() remains
# available for DBI-shaped broker subclasses.
#
# Subclasses must implement:
#   connect_info_for_storage($storage) — returns storage-native connect info
#   connect_info_for()      — legacy DBI-shaped connect info
#   needs_refresh()         — returns true if credentials need rotation
#   refresh()               — perform credential rotation
#
# The $mode argument ('read'/'write') is vestigial: under a single-identity
# CredentialSource there is nothing to route on. It is accepted for
# backward compatibility and ignored by all built-in brokers.

use Class::Accessor::Grouped;
use base 'Class::Accessor::Grouped';

# HostBound is a subclass of this class, so it can only be compiled once this
# package is itself a Class::Accessor::Grouped subclass — hence loaded here,
# after the line above, not at the top of the file. for_host() builds one.
use DBIO::AccessBroker::HostBound ();

sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  return $self;
}


# Set by Storage when broker is attached
sub set_storage {
  my ($self, $storage) = @_;
  if (ref $storage) {
    my $refs = $self->{_attached_storages} ||= {};
    my $key  = refaddr($storage);
    unless (defined $refs->{$key} and refaddr($refs->{$key}) == $key) {
      $refs->{$key} = $storage;
      weaken $refs->{$key};
    }
  }
  return $storage;
}


sub unset_storage {
  my ($self, $storage) = @_;
  if (ref $storage and my $refs = $self->{_attached_storages}) {
    delete $refs->{ refaddr($storage) };
  }
  return $storage;
}

# The live storages this broker is attached to. Storages that have been freed
# are dropped on the way. Private: asking the broker which storages it has is
# not an interface; current_connect_info_for is the reader.
sub _attached_storages {
  my $self = shift;
  my $refs = $self->{_attached_storages} or return;
  for my $key (keys %$refs) {
    delete $refs->{$key} unless defined $refs->{$key};
  }
  return values %$refs;
}


# Legacy DBI-shaped interface retained for built-in brokers and compatibility.
sub connect_info_for {
  croak ref($_[0]) . " must implement connect_info_for()";
}


# Primary storage-aware interface. Built-in brokers can often derive
# storage-native info from the legacy DBI-shaped form, so we provide that
# bridge here.
sub connect_info_for_storage {
  my ($self, $storage, $mode) = @_;
  $mode //= 'write';
  # Subclasses with storage-native formats override this.
  # Default: delegate to connect_info_for (DBI-shaped).
  return $self->connect_info_for($mode);
}


# Do credentials need rotation?
sub needs_refresh { 0 }


# Perform credential rotation
sub refresh { }


# Does this broker rotate credentials over time?
sub has_rotating_credentials { 0 }


# Can transactions safely run through this broker without an explicit override?
# A broker only supplies credentials, so the sole safety hazard is credential
# rotation mid-transaction. Routing is not a broker concern (see Replicated).
sub is_transaction_safe {
  my $self = shift;
  return $self->has_rotating_credentials ? 0 : 1;
}


# Check refresh and return connect info — legacy convenience for DBI-shaped
# callers or brokers already attached to a storage.
sub current_connect_info_for {
  my ($self, $mode, $storage) = @_;
  $mode //= 'write';

  unless ($storage) {
    my @attached = $self->_attached_storages;
    DBIO::Exception->throw(sprintf(
      '%s is attached to %d storages and cannot tell which one '
      . 'current_connect_info_for is asked for: pass the storage as the '
      . 'second argument, or use current_connect_info_for_storage($storage)',
      ref($self), scalar @attached,
    )) if @attached > 1;
    $storage = $attached[0];
  }

  if ($self->needs_refresh) {
    $self->refresh;
  }
  return $storage
    ? $self->connect_info_for_storage($storage, $mode)
    : $self->connect_info_for($mode);
}


# Pair this single credential identity with one host, returning a HostBound
# view. The view shares this broker's credentials and rotation lifecycle but
# reports the given host in its connect info, so one credential can serve many
# servers without this broker ever knowing the host list. Accepts a plain host
# string or a hashref ({ host => ..., port => ... }).
sub for_host {
  my ($self, @args) = @_;
  my %host_args =
      @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] }
    : @args == 1                            ? (host => $args[0])
    :                                         @args;
  return DBIO::AccessBroker::HostBound->new(broker => $self, %host_args);
}


# Check refresh and return storage-native connect info.
sub current_connect_info_for_storage {
  my ($self, $storage, $mode) = @_;
  $mode //= 'write';
  if ($self->needs_refresh) {
    $self->refresh;
  }
  return $self->connect_info_for_storage($storage, $mode);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::AccessBroker - Credential lifecycle for DBIO connections

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    # Static — one fixed set of connection parameters
    use DBIO::AccessBroker::Static;
    my $broker = DBIO::AccessBroker::Static->new(
        dbname => 'myapp',
        username => 'app', password => 'secret',
    );
    # Storage gets storage-native connect info
    my $info = $broker->current_connect_info_for_storage($schema->storage);

    # Vault — rotating credentials from OpenBao/Vault
    use DBIO::AccessBroker::Vault;
    my $broker = DBIO::AccessBroker::Vault->new(
        vault     => WWW::OpenBao->new(endpoint => 'http://vault:8200', token => $token),
        dsn       => 'dbi:Pg:dbname=myapp;host=db',
        cred_path => 'database/creds/myapp',
        ttl       => 3600,         # credentials valid for 1 hour
        refresh_margin => 900,     # refresh 15 min before expiry
    );
    # DBIO can now connect directly with a broker
    my $schema = MyApp::Schema->connect($broker);

    # the async mode is the connect call's, beside the broker
    my $async_schema = MyApp::Schema->connect($broker, { async => 'future_io' });

    # so are the other connect options -- the broker answers which database,
    # and as whom (see DBIO::Storage::DBI/connect_info)
    my $schema = MyApp::Schema->connect($broker, {
        quote_names   => 0,
        on_connect_do => [ 'SET search_path TO app' ],
    });

See F<t/access_broker/> for a runnable example.

=head1 DESCRIPTION

AccessBroker is a B<CredentialSource>: it supplies the connect info for
exactly one backend identity (one set of credentials). It is
B<storage-agnostic> — it returns connection parameters, not handles —
so it works with both C<Storage::DBI> (sync) and C<Storage::Async>
(async/Future-based). It handles:

=over 4

=item * B<Credential lifecycle> — fetching, rotating, and caching database credentials

=back

A broker does B<not> route, and it does B<not> own a host list. Read/write
routing and the master/replicant topology belong to L<DBIO::Replicated>. One
credential can serve many servers via a L</for_host> view, which pairs this
single identity with one host at connect time.

=head1 METHODS

=head2 set_storage

    $broker->set_storage($storage);

Attaches this broker to a storage instance, so that a subsequent
L</current_connect_info_for> knows which storage to hand to
C<connect_info_for_storage>. (L</current_connect_info_for_storage> is given
its storage as an argument and does not read this one.) Called by C<Storage>
when the broker is attached; not normally called directly.

A broker keeps a reference to B<every> storage it is attached to:
a synchronous owner and its embedded async backend, or the master and the
replicants of L<DBIO::Replicated>, are several storages of one broker.
Setting a storage adds it; storages already attached stay. Setting the same
storage again changes nothing.

The storages are held B<weakly>: the storage holds its broker, not the other
way round. Held strongly, the two would keep each other alive, and a storage
dropped with a broker attached would never close its connection.
A storage that is gone is no longer attached to the broker.

=head2 unset_storage

    $broker->unset_storage($storage);

Detaches this broker from exactly this storage; the other storages it is
attached to are left as they are. Called by C<Storage> when it detaches the
broker (L<DBIO::Storage/clear_access_broker>) or is given another
(L<DBIO::Storage/set_access_broker>), before its broker slot changes. A
storage the broker is not attached to is ignored. Returns the storage.

=head2 connect_info_for

    my $info = $broker->connect_info_for;

Optional legacy DBI-shaped connect info. The base implementation throws;
built-in brokers implement it, and the default L</connect_info_for_storage>
delegates to it.

=head2 connect_info_for_storage

    my $info = $broker->connect_info_for_storage($storage);

Returns storage-native connect info -- the primary interface subclasses
implement. The default delegates to L</connect_info_for>; brokers with a
storage-native format override it.

A storage takes two shapes of answer:

=over 4

=item * a hashref of connection parameters, C<< { dbname, host, port, user,
password } >>, as L<DBIO::AccessBroker::Static> answers. A
L<DBIO::Storage::DBI> reads it as the single-hash form of
L<DBIO::Storage::DBI/connect_info>, so a C<dsn> in place of C<dbname>, C<host>
and C<port>, and DBI attributes beside them, are taken too.

=item * an arrayref in a form L<DBIO::Storage::DBI/connect_info> takes --
usually the DBI form C<< [ $dsn, $user, $password, \%attrs ] >>, as
L<DBIO::AccessBroker::Vault> answers.

=back

Anything else that is something -- a plain string (a bare DSN), a code
reference, an object -- is refused by the sync and the async storage alike,
with an error naming the broker class and the shape of the answer, never a
value of it. An answer of nothing -- C<undef>, an empty hash or array, a
false value -- is refused too, naming the broker
(L<DBIO::Storage/current_access_broker_connect_info>); a storage never falls
back to an earlier answer.

An answer that names no database is refused by the sync storage as well: the
DBI form or a hash with an undefined or empty DSN, and a hash with neither a
C<dsn> nor a C<dbname> key -- credentials alone, or C<host> and C<port>, which
are never passed on as DBI attributes. The error names the broker class and
the shape of the answer, and no connection is opened: the credentials are for
the database the broker names, so a storage with a broker attached never
connects to C<$ENV{DBI_DSN}> instead. Answer a C<dsn> or a C<dbname>.

A L<DBIO::Storage::DBI> connects with a hash answer only when it applies all
of it. Beside the connection itself that is: the connect options
of L<DBIO::Storage::DBI/connect_info> and L<DBI> attributes -- a name starting
with an uppercase letter, with C<private_>, C<dbi_> or C<dbd_>, or with the
prefix of the DBD the DSN names (C<pg_> for C<dbi:Pg:>). Any other key set to
a value is a parameter of the database client -- C<sslmode>,
C<connect_timeout>, C<sslrootcert>, ... -- which an async transport hands to
its client, while the sync storage builds only C<dbname>, C<host> and C<port>
into the DSN and C<< DBI->connect >> would silently not apply the rest. The
sync storage never opens a connection without such a parameter: when it is to
connect with the answer it throws instead, the error naming the broker class
and the keys.

That is when the storage opens a connection of its own -- the first use of its
C<dbh>, and every reconnect -- not when it is configured. A schema connected
with an async mode whose transport takes the hash is configured with such an
answer, and its pooled connections are opened with the parameter; only the
owning storage's own connection throws, once something asks for it. There are
two ways to give the parameter to both. Answer the DBI form, with it inside
the DSN:

    [ 'dbi:Pg:dbname=myapp;host=db;sslmode=require', $user, $password, \%attrs ]

The attribute hash of the DBI form is not looked into, so a DBD attribute the
storage does not recognise as one goes there. Or answer by the C<$storage>
that asks -- the transport the hash with its client's parameters, a
L<DBIO::Storage::DBI> an answer it applies in full:

    sub connect_info_for_storage {
      my ($self, $storage, $mode) = @_;
      return $storage->isa('DBIO::Storage::DBI')
        ? [ 'dbi:Pg:dbname=myapp;host=db;sslmode=require', $user, $password ]
        : { dbname => 'myapp', host => 'db', user => $user, password => $password,
            sslmode => 'require' };
    }

The same holds for a key given beside the broker,
C<< $schema->connect($broker, { sslmode => 'require' }) >>: it
joins the L<DBI> attributes of every answer, so the sync storage throws when
it is to connect, naming the keys as standing beside the broker. A parameter
of the database client is the broker's to answer, in one of the two ways
above.

An answer in one of the two shapes that the sync storage still cannot connect
with -- a libpq keyword/value string where the DSN belongs, as an C<ev>
transport takes it -- is not refused here: C<< DBI->connect >> fails on it, and
the error is L<DBI>'s. No message about a connection quotes the password,
though: in that error, as everywhere DBIO writes connect info into a message,
it is shown as C<***> (L<DBIO::Storage::DBI/connect_info>).

=head2 needs_refresh

Returns true if credentials should be rotated. Default: false.

=head2 refresh

Performs credential rotation. Default: does nothing.

=head2 has_rotating_credentials

Returns true if credentials rotate across connections. Default: false.

=head2 is_transaction_safe

Returns true if DBIO may open transactions through this broker. Default: true
unless L</has_rotating_credentials>; see L</TRANSACTION SAFETY>.

=head2 current_connect_info_for

    my $info = $broker->current_connect_info_for($mode);
    my $info = $broker->current_connect_info_for($mode, $storage);

Legacy DBI-shaped convenience: calls C<refresh> first if C<needs_refresh> is
true, then returns C<< $self->connect_info_for_storage($storage, $mode) >>.

Given C<$storage>, it answers for that storage, whether or not the broker is
attached to it. Without it the broker answers for the storage it is attached
to (L</set_storage>): C<< $self->connect_info_for($mode) >> when it is
attached to none, and the answer for that storage when it is attached to one.
A broker attached to B<several> storages cannot tell which one is meant, and
throws -- naming its class and the count, no credential -- before it refreshes
anything. Pass the storage, or use L</current_connect_info_for_storage>.

=head2 for_host

    my $view = $broker->for_host('db1.example.com');
    my $view = $broker->for_host({ host => 'db1.example.com', port => 5433 });

Pairs this single credential identity with one host, returning a
L<DBIO::AccessBroker::HostBound> view. The view shares this broker's
credentials and rotation lifecycle but reports the given host in its connect
info, so one credential can serve many servers without this broker ever
knowing the host list. Accepts a plain host string or a hashref.

The application builds the views and hands each to the connection on that
host -- the master's C<connect>, a replicant's entry in
L<DBIO::Replicated::Storage/connect_replicants> as C<< [ $view ] >>.
L<DBIO::Replicated> passes a view through like any broker; it builds none.

=head2 current_connect_info_for_storage

    my $info = $broker->current_connect_info_for_storage($storage, $mode);

Storage-aware convenience: calls C<refresh> first if C<needs_refresh> is
true, then returns C<< $self->connect_info_for_storage($storage, $mode) >>.

=head1 TRANSACTION SAFETY

A broker only supplies credentials, so the sole hazard to a running
transaction is credentials rotating mid-flight. DBIO distinguishes:

=over 4

=item * C<has_rotating_credentials()> — new connections may need refreshed credentials

=item * C<is_transaction_safe()> — DBIO may start a transaction through this broker without an explicit override

=back

The default implementation treats brokers as transaction-safe unless they
rotate credentials.

This means:

=over 4

=item * L<DBIO::AccessBroker::Static> is transaction-safe

=item * L<DBIO::AccessBroker::Vault> is not transaction-safe by default

=back

Starting a transaction through a broker marked as unsafe will throw by default.
If you intentionally want to allow this, set
C<DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS=1>. DBIO will then proceed, but emit a
warning on transaction start.

The check is made where a transaction starts. The synchronous
L<DBIO::Storage/txn_begin> throws, and with it C<txn_do> and
C<txn_scope_guard>. C<txn_do_async> does not throw: in every async mode it
returns a failed Future carrying the same refusal, and on an async backend
(L<DBIO::Storage::Async/txn_do_async>) no connection is taken from the pool
for it. L<DBIO::Storage::Async/deploy_async> is refused the same way where it
runs its DDL in a transaction. L<DBIO::Storage::Async/pipeline> is refused
the same way, as a failed Future before a connection is taken: a batch is work
meant to stand as a unit, and on PostgreSQL it is an implicit transaction.

=head1 SUBCLASSING

Implement these methods, each documented under L</METHODS>:
L</connect_info_for_storage>, L</connect_info_for> (optional, legacy),
L</needs_refresh>, L</refresh>, L</has_rotating_credentials> and
L</is_transaction_safe>.

=head2 The C<$mode> argument

The broker methods accept a trailing C<$mode> argument (C<'read'> or
C<'write'>) for backward compatibility. It is B<vestigial>: a broker is a
single-identity B<CredentialSource> with nothing to route on, so all
built-in brokers ignore it. Routing decides read versus write — see
L<DBIO::Replicated> — not the broker. New broker subclasses should not
branch on C<$mode>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
