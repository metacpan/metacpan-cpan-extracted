# ABSTRACT: Credential rotation with TTL
package DBIO::AccessBroker::Vault;

use strict;
use warnings;

our $VERSION = '0.900005';

use Carp qw(croak);
use Scalar::Util qw(blessed reftype);
use base 'DBIO::AccessBroker';
use namespace::clean;

__PACKAGE__->mk_group_accessors('simple' => qw(
  vault dsn dbi_attrs cred_path ttl refresh_margin
  _current_username _current_password _expires_at
));



sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);

  $self->vault($args{vault})           // croak "Vault broker requires 'vault'";
  $self->dsn($args{dsn})               // croak "Vault broker requires 'dsn'";
  $self->cred_path($args{cred_path})   // croak "Vault broker requires 'cred_path'";
  $self->ttl($args{ttl}                // 3600);
  $self->refresh_margin($args{refresh_margin} // 900);  # 15 min before expiry
  $self->dbi_attrs($args{dbi_attrs}    // {});
  $self->_expires_at(0);

  # Fetch initial credentials
  $self->_fetch_credentials;

  return $self;
}

# Reads the secret and takes its username and password. A secret that lacks a
# defined username or a defined password (an empty string is a value) -- nothing,
# an empty hash, a hash with other keys only, a half secret -- or that is
# no hash croaks, naming cred_path and the shape, never a value: a plain string
# from a vault may be the secret itself (karr k270). It croaks before anything
# is replaced, so a failed refresh leaves the credentials of before whole.
sub _fetch_credentials {
  my ($self) = @_;
  my $creds = $self->vault->read_secret($self->cred_path);
  croak "Vault returned no credentials for " . $self->cred_path unless $creds;

  unless ((reftype($creds) // '') eq 'HASH') {
    my $shape = !ref $creds           ? 'a plain scalar'
              : blessed($creds)       ? 'an object of class ' . ref $creds
              : ref $creds eq 'ARRAY' ? 'an ARRAY reference'
              :                         'a ' . ref($creds) . ' reference';
    croak 'Vault returned credentials for ' . $self->cred_path
        . " that are not a hash ($shape)";
  }

  croak "Vault returned no credentials for " . $self->cred_path
      . ' (a hash with neither a username nor a password)'
    unless defined $creds->{username} or defined $creds->{password};

  for my $key (qw(username password)) {
    croak "Vault returned incomplete credentials for " . $self->cred_path
        . " (the hash has no defined $key)"
      unless defined $creds->{$key};
  }

  $self->_current_username($creds->{username});
  $self->_current_password($creds->{password});
  $self->_expires_at(time() + $self->ttl);
}


sub connect_info_for {
  my ($self, $mode) = @_;
  return [$self->dsn, $self->_current_username, $self->_current_password, $self->dbi_attrs];
}


sub needs_refresh {
  my ($self) = @_;
  return time() > ($self->_expires_at - $self->refresh_margin);
}


sub refresh {
  my ($self) = @_;
  $self->_fetch_credentials;
}


sub has_rotating_credentials { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::AccessBroker::Vault - Credential rotation with TTL

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

Vault-backed brokers rotate credentials over time and are therefore not
transaction-safe by default. See
L<DBIO::AccessBroker/TRANSACTION SAFETY>.

=head1 METHODS

=head2 new

    my $broker = DBIO::AccessBroker::Vault->new(
        vault     => $vault_client,
        dsn       => 'dbi:Pg:dbname=myapp;host=db',
        cred_path => 'database/creds/myapp',
        ttl       => 3600,
        refresh_margin => 900,
    );

Constructs the broker and fetches the initial credentials from C<vault>
immediately. C<vault>, C<dsn> and C<cred_path> are required; C<ttl> defaults
to 3600 seconds and C<refresh_margin> to 900.

C<dbi_attrs> (optional, default C<{}>) is a hashref of connect attributes,
answered as the fourth element of the connect info. A setting given both
there and beside the broker in the connect call must have the same value
(L<DBIO::Storage::DBI/connect_info>).

C<vault> is any object answering C<< $vault->read_secret($cred_path) >> with
a hash that holds both C<username> and C<password>, defined (an empty string
is a value). A secret that is nothing, is no hash, or lacks either of the two
croaks, naming C<cred_path> and the shape of the secret or the missing key,
never a value of it.

=head2 connect_info_for

    my ($dsn, $user, $pass, $attrs) = @{ $broker->connect_info_for($mode) };

Returns the legacy DBI-shaped connect info arrayref using the most recently
fetched credentials. C<$mode> is ignored (see
L<DBIO::AccessBroker/The C<$mode> argument>).

=head2 needs_refresh

    if ($broker->needs_refresh) { ... }

Returns true once the current credentials are within C<refresh_margin>
seconds of C<ttl> expiry.

=head2 refresh

    $broker->refresh;

Re-fetches credentials from C<vault> and resets the expiry clock. Called
automatically by L<DBIO::AccessBroker/current_connect_info_for> and
L<DBIO::AccessBroker/current_connect_info_for_storage> when L</needs_refresh>
is true.

A refresh that fails -- the vault throws, or answers a secret L</new> would
refuse -- croaks and leaves the credentials and the expiry of before as they
were, so the next ask reads the vault again. A storage asking for a
connection gets that error and opens none.

=head2 has_rotating_credentials

Always true: a Vault broker's credentials rotate over time, which is also why
it is not transaction-safe by default (see
L<DBIO::AccessBroker/TRANSACTION SAFETY>).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
