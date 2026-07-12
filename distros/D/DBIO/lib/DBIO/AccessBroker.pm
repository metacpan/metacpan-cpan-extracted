# ABSTRACT: Credential lifecycle for DBIO connections
package DBIO::AccessBroker;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
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

__PACKAGE__->mk_group_accessors('simple' => qw(
  _storage
));

sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  return $self;
}

# Set by Storage when broker is attached
sub set_storage {
  my ($self, $storage) = @_;
  $self->_storage($storage);
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
  my ($self, $mode) = @_;
  $mode //= 'write';
  if ($self->needs_refresh) {
    $self->refresh;
  }
  return $self->_storage
    ? $self->connect_info_for_storage($self->_storage, $mode)
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

version 0.900001

=head1 SYNOPSIS

    # Static — same as traditional connect, one DSN
    use DBIO::AccessBroker::Static;
    my $broker = DBIO::AccessBroker::Static->new(
        dsn => 'dbi:Pg:dbname=myapp',
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

=head1 NAME

DBIO::AccessBroker - Credential lifecycle for DBIO connections

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

=head1 SUBCLASSING

Implement these methods:

=over 4

=item C<connect_info_for_storage($storage)> — Return storage-native connect info

=item C<connect_info_for()> — Optional legacy DBI-shaped connect info

=item C<needs_refresh()> — Return true if credentials should be rotated

=item C<refresh()> — Perform credential rotation

=item C<has_rotating_credentials()> — Return true if credentials rotate across connections

=item C<is_transaction_safe()> — Return true if DBIO may open transactions through this broker

=back

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
