# ABSTRACT: One credential identity pinned to one host
package DBIO::AccessBroker::HostBound;

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp qw(croak);
use Scalar::Util qw(blessed);
use base 'DBIO::AccessBroker';
use DBIO::Storage::DBI ();
use namespace::clean;


__PACKAGE__->mk_group_accessors('simple' => qw(
  _broker _host _port
));


sub new {
  my ($class, %args) = @_;

  my $broker = $args{broker};
  croak "HostBound requires 'broker'" unless defined $broker;
  croak "HostBound 'broker' must be a DBIO::AccessBroker instance"
    unless blessed($broker) && $broker->isa('DBIO::AccessBroker');
  croak "HostBound requires 'host'" unless defined $args{host};

  my $self = $class->SUPER::new(%args);
  $self->_broker($broker);
  $self->_host($args{host});
  $self->_port($args{port}) if defined $args{port};
  return $self;
}


# The wrapped broker is the real CredentialSource. The view holds no
# credentials of its own; callers that need the underlying identity
# (e.g. to compare two views sharing one lease) read it here.
sub underlying_broker { $_[0]->_broker }

sub host { $_[0]->_host }
sub port { $_[0]->_port }


# Lifecycle delegates entirely to the wrapped CredentialSource: one lease,
# one rotation schedule, shared across every host this credential serves.
sub needs_refresh            { $_[0]->_broker->needs_refresh }
sub refresh                  { $_[0]->_broker->refresh }
sub has_rotating_credentials { $_[0]->_broker->has_rotating_credentials }
sub is_transaction_safe      { $_[0]->_broker->is_transaction_safe }


# Attaching the view to a storage must also reach the underlying broker, so
# storage-aware credential lookups and storage-tied rotation keep working.
sub set_storage {
  my ($self, $storage) = @_;
  $self->SUPER::set_storage($storage);
  $self->_broker->set_storage($storage);
  return $self;
}

sub unset_storage {
  my ($self, $storage) = @_;
  $self->SUPER::unset_storage($storage);
  $self->_broker->unset_storage($storage);
  return $storage;
}


sub connect_info_for {
  my ($self, $mode) = @_;
  # The storage whose class may bind the host: the view's one storage, when
  # it has exactly one. With none or several there is no class to ask.
  my @attached = $self->_attached_storages;
  return $self->_bind_host(
    $self->_broker->connect_info_for($mode), @attached == 1 ? $attached[0] : undef
  );
}

sub connect_info_for_storage {
  my ($self, $storage, $mode) = @_;
  return $self->_bind_host(
    $self->_broker->connect_info_for_storage($storage, $mode), $storage
  );
}

# Inject this view's host into whatever connect-info shape the wrapped broker
# produces, without the broker ever knowing the host list. Two shapes occur
# in the wild: the hashref form ({host,port,dbname,...}, e.g. Static) and the
# DBI-arrayref form ([$dsn,$user,$pass,\%attrs], e.g. Vault). A DSN string is
# bound through the driver seam (_bind_host_into_dsn); what cannot be bound
# is refused, naming the form and never the DSN (karr k276).
sub _bind_host {
  my ($self, $info, $storage) = @_;
  my $host = $self->_host;
  my $port = $self->_port;

  # An empty hash is no answer: binding a host into it would make it one,
  # and the storage would open a connection with host and port alone instead
  # of refusing the broker (karr k253). Hand it on as it came.
  if (ref $info eq 'HASH') {
    return $info unless %$info;

    $self->_cannot_bind('dbh_maker: code opens the connection')
      if defined $info->{dbh_maker};

    my %bound = %$info;
    if (defined $bound{dsn} && !ref $bound{dsn} && length $bound{dsn}) {
      $bound{dsn} = $self->_bind_host_into_dsn($bound{dsn}, $storage);
      return \%bound;
    }

    $bound{host} = $host;
    $bound{port} = $port if defined $port;
    return \%bound;
  }

  if (ref $info eq 'ARRAY') {
    my @bound = @$info;
    if (ref $bound[0]) {
      $self->_cannot_bind('a code reference in place of a DSN')
        if ref $bound[0] eq 'CODE';
    }
    elsif (defined $bound[0] && length $bound[0]) {
      $bound[0] = $self->_bind_host_into_dsn($bound[0], $storage);
    }
    return \@bound;
  }

  return $info;
}

# The DSN with this view's host and port bound, by the first driver seam that
# is not core's default; else by the default; or a refusal naming the form.
sub _bind_host_into_dsn {
  my ($self, $dsn, $storage) = @_;
  my ($host, $port) = ($self->_host, $self->_port);

  # Before any seam is asked: a driver never sees a value that would split
  # the DSN.
  $self->_cannot_bind("host/port containing ';'")
    if $host =~ /;/ || (defined $port && $port =~ /;/);

  my ($dbd) = $dsn =~ /^dbi:([^:(]*)/i;
  $dbd //= '';

  my $default = \&DBIO::Storage::DBI::_bind_host_into_dsn;
  my @candidates;
  push @candidates, ref $storage || $storage
    if defined $storage && blessed($storage) && $storage->can('_bind_host_into_dsn');
  if (length $dbd) {
    my $class = DBIO::Storage::DBI->driver_storage_class($dbd);
    push @candidates, $class
      if defined $class && $class->can('_bind_host_into_dsn');
  }

  my $seam_class = 'DBIO::Storage::DBI';
  for my $candidate (@candidates) {
    next if $candidate->can('_bind_host_into_dsn') == $default;
    $seam_class = $candidate;
    last;
  }

  my ($bound, $form) = $seam_class->_bind_host_into_dsn($dbd, $dsn, $host, $port);
  return $bound if defined $bound;

  $self->_cannot_bind($form // 'a DSN form the driver does not name');
}

# Refuse; the form is a key or a dialect, never a value of the answer.
sub _cannot_bind {
  my ($self, $form) = @_;
  croak 'HostBound view over ' . ref($self->_broker)
    . " cannot bind its host into the answer: $form. The storage's driver "
    . 'seam _bind_host_into_dsn (ADR 0013, addendum 2026-10-09) translates '
    . 'the DSN forms its DBD takes; give the answer as connection parameters '
    . 'or a DSN naming its server with host=/port=.';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::AccessBroker::HostBound - One credential identity pinned to one host

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    my $broker = DBIO::AccessBroker::Vault->new(...);   # one Vault lease

    my $primary = $broker->for_host('db-primary');
    my $replica = $broker->for_host({ host => 'db-replica', port => 5433 });

    # $primary and $replica share one credential lease; only the host differs.

See F<t/access_broker/06-replicated-passthrough.t> for a runnable example.

=head1 DESCRIPTION

A C<HostBound> view pairs one B<CredentialSource> (a wrapped
L<DBIO::AccessBroker>) with one host. It is how a single credential can serve
many servers: the application builds one view per server with
C<< $broker->for_host($host) >> and hands each to the connection on that host
-- the master's C<connect>, a replicant's entry in
L<DBIO::Replicated::Storage/connect_replicants> as C<< [ $view ] >>.
L<DBIO::Replicated> passes the views through; it does not build them, and the
broker itself never learns the host list.

The view holds B<no credentials of its own>. Every credential operation —
C<needs_refresh>, C<refresh>, C<has_rotating_credentials>,
C<is_transaction_safe> — delegates to the wrapped broker, so all views built
from one broker share a single lease and a single rotation schedule. The view
adds exactly one thing: it injects its host (and optional port) into the
connect info the broker returns, handling both the hashref form
(C<< {host,port,dbname,...} >>) and the DBI-arrayref/DSN form, the latter through the driver seam
L<DBIO::Storage::DBI/_bind_host_into_dsn>.

=head1 METHODS

=head2 new

    my $view = DBIO::AccessBroker::HostBound->new(
      broker => $broker,          # required, a DBIO::AccessBroker
      host   => 'db-replica',     # required
      port   => 5433,             # optional
    );

Builds a host-bound view over C<broker>. Croaks if C<broker> is missing or
not a L<DBIO::AccessBroker> instance, or if C<host> is missing. Normally not
called directly -- use L<DBIO::AccessBroker/for_host>.

=head2 underlying_broker

Returns the wrapped L<DBIO::AccessBroker> -- the real CredentialSource behind
this view. Two views sharing one lease return the same broker here.

=head2 host

Returns the host this view is pinned to.

=head2 port

Returns the port this view is pinned to, or C<undef> when none was given (the
wrapped broker's port, if any, is then passed through unchanged).

=head2 needs_refresh

=head2 refresh

=head2 has_rotating_credentials

=head2 is_transaction_safe

All four delegate to the wrapped broker unchanged: every view built from one
broker shares a single lease and a single rotation schedule. See
L<DBIO::AccessBroker/TRANSACTION SAFETY>.

=head2 set_storage

    $view->set_storage($storage);

Attaches the view to C<$storage> (via L<DBIO::AccessBroker/set_storage>) and
also attaches the wrapped broker, so storage-aware credential lookups and
storage-tied rotation keep working. The storage is added to what the wrapped
broker is attached to: several views over one broker, each given its own
storage, leave the wrapped broker attached to all of them.
Returns the view.

=head2 unset_storage

    $view->unset_storage($storage);

Detaches the view from C<$storage> and the wrapped broker from it as well
(L<DBIO::AccessBroker/unset_storage>). Only that storage: the others the
wrapped broker is attached to through other views stay. Returns the storage.

=head2 connect_info_for

    my $info = $view->connect_info_for($mode);

Asks the wrapped broker for its connect info and injects this view's host
(and port, if set). Handles both shapes a broker may return: the hashref form
(C<< {host, port, dbname, ...} >>, whose C<host>/C<port> keys are overwritten)
and the DBI-arrayref form (C<< [$dsn, $user, $pass, \%attrs] >>, whose DSN
gets its C<host=>/C<port=> tokens rewritten or inserted after
C<dbi:Driver:>). Any other shape is returned untouched.

How a DSN names its server is the DBD's business, so a DSN string is not
rewritten by the view itself: it asks the storage's driver seam
L<DBIO::Storage::DBI/_bind_host_into_dsn> (ADR 0013, addendum 2026-10-09). The
candidates are the class of the storage, when one is given, and the storage
class registered for the DBD named in the DSN
(L<DBIO::Storage::DBI/register_driver>) -- a storage is still the generic
class before its first connection; the first whose seam is not core's default
answers. Core's default translates the C<host=>/C<port=> form and declines the
rest. A driver that names its server another way overrides the seam in its
storage class.

What nobody can translate is B<refused>, never passed on: the connection
dies with a message naming the form (a key, a dialect) -- never the DSN, never
a credential -- because a replicant given the view would otherwise connect to
the host the answer named. That covers a DSN naming its server another way
that no driver seam translates (Oracle Easy Connect or a TNS descriptor,
DB2's C<HOSTNAME=>, Sybase's C<server=>, an ODBC data source, C<hostaddr=>);
an array starting with a code reference, and a hash carrying a C<dbh_maker>,
whose code opens the connection with no DSN for the view to rewrite; and a
view's host or port containing C<;>, which would add tokens to a DSN -- that
is refused before any seam is asked, so no driver ever sees it. A hash
carrying a C<dsn> has the host and port bound into that DSN the same way and
gets no C<host>/C<port> keys. Where the view was not given a storage
(L</connect_info_for>) the core default is the only candidate besides the
registry.

An answer that is nothing -- C<undef>, an empty hash or array, a false value
-- is handed on as it came: an empty hash does B<not> become
C<< { host => ..., port => ... } >>. The storage then refuses it, naming the
wrapped broker that answered nothing and this view
(L<DBIO::Storage/current_access_broker_connect_info>).

=head2 connect_info_for_storage

    my $info = $view->connect_info_for_storage($storage, $mode);

Storage-aware variant of L</connect_info_for>: calls the wrapped broker's
C<connect_info_for_storage> and injects the host the same way.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
