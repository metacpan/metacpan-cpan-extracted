# ABSTRACT: One credential identity pinned to one host
package DBIO::AccessBroker::HostBound;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use base 'DBIO::AccessBroker';
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

sub connect_info_for {
  my ($self, $mode) = @_;
  return $self->_bind_host($self->_broker->connect_info_for($mode));
}

sub connect_info_for_storage {
  my ($self, $storage, $mode) = @_;
  return $self->_bind_host(
    $self->_broker->connect_info_for_storage($storage, $mode)
  );
}

# Inject this view's host into whatever connect-info shape the wrapped broker
# produces, without the broker ever knowing the host list. Two shapes occur
# in the wild: the hashref form ({host,port,dbname,...}, e.g. Static) and the
# DBI-arrayref form ([$dsn,$user,$pass,\%attrs], e.g. Vault).
sub _bind_host {
  my ($self, $info) = @_;
  my $host = $self->_host;
  my $port = $self->_port;

  if (ref $info eq 'HASH') {
    my %bound = %$info;
    $bound{host} = $host;
    $bound{port} = $port if defined $port;
    return \%bound;
  }

  if (ref $info eq 'ARRAY') {
    my @bound = @$info;
    $bound[0] = $self->_inject_host_into_dsn($bound[0], $host, $port)
      if defined $bound[0] && !ref $bound[0];
    return \@bound;
  }

  return $info;
}

# Rewrite (or insert) the host/port tokens in a DBI DSN string, leaving the
# rest of the DSN — driver, dbname, every other attribute — untouched.
sub _inject_host_into_dsn {
  my ($self, $dsn, $host, $port) = @_;
  return $dsn unless defined $dsn && length $dsn;

  $dsn = $self->_set_dsn_attr($dsn, host => $host);
  $dsn = $self->_set_dsn_attr($dsn, port => $port) if defined $port;
  return $dsn;
}

sub _set_dsn_attr {
  my ($self, $dsn, $key, $val) = @_;

  # Replace an existing "key=...;" token in place.
  return $dsn
    if $dsn =~ s/(^|[:;])\Q$key\E=[^;]*/$1$key=$val/i;

  # No such token: splice it into the attribute section after "dbi:Driver:".
  if ($dsn =~ /^(dbi:[^:]*:)(.*)$/i) {
    my ($prefix, $rest) = ($1, $2);
    $rest = length $rest ? "$key=$val;$rest" : "$key=$val";
    return $prefix . $rest;
  }

  return $dsn;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::AccessBroker::HostBound - One credential identity pinned to one host

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

    my $broker = DBIO::AccessBroker::Vault->new(...);   # one Vault lease

    my $primary = $broker->for_host('db-primary');
    my $replica = $broker->for_host({ host => 'db-replica', port => 5433 });

    # $primary and $replica share one credential lease; only the host differs.

See F<t/access_broker/06-replicated-passthrough.t> for a runnable example.

=head1 DESCRIPTION

A C<HostBound> view pairs one B<CredentialSource> (a wrapped
L<DBIO::AccessBroker>) with one host. It is how a single credential can serve
many servers: L<DBIO::Replicated> owns the host list and asks the broker for a
host-bound view per backend via C<< $broker->for_host($host) >>, while the
broker itself never learns the host list.

The view holds B<no credentials of its own>. Every credential operation —
C<needs_refresh>, C<refresh>, C<has_rotating_credentials>,
C<is_transaction_safe> — delegates to the wrapped broker, so all views built
from one broker share a single lease and a single rotation schedule. The view
adds exactly one thing: it injects its host (and optional port) into the
connect info the broker returns, handling both the hashref form
(C<< {host,port,dbname,...} >>) and the DBI-arrayref/DSN form.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
