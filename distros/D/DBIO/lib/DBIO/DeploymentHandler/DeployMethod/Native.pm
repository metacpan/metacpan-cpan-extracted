package DBIO::DeploymentHandler::DeployMethod::Native;
# ABSTRACT: Native DBIO driver deploy (no SQL::Translator needed)

use strict;
use warnings;

use DBIO::Exception;

use namespace::clean;

sub new {
  my ($class, @args) = @_;
  my $args = @args == 1 ? $args[0] : { @args };
  bless +{%$args}, $class;
}

sub schema { $_[0]->{schema} }

sub deploy {
  my ($self, $args) = @_;
  $self->_driver_deploy->install;
}

sub upgrade {
  my ($self, $args) = @_;
  $self->_driver_deploy->upgrade;
}

sub diff {
  my ($self, $args) = @_;
  $self->_driver_deploy->diff;
}

# The native driver introspects + reconciles in one shot, so there is
# nothing to "prepare" in advance. These exist to satisfy callers that
# still expect the old DBIx::Class::DeploymentHandler contract.
sub prepare_deploy { }
sub prepare_upgrade { }
sub prepare_resultsource_install { }
sub initialize { }

sub install_resultsource {
  my ($self, $args) = @_;
  # Handled by the driver's install
}

sub txn_do {
  my ($self, $code) = @_;
  my $txn_wrap = $self->{txn_wrap};
  return $code->() unless $txn_wrap;
  my $guard = $self->schema->txn_scope_guard;
  my $rv = $code->();
  $guard->commit;
  return $rv;
}

sub _driver_deploy {
  my ($self) = @_;

  my $storage = $self->schema->storage;

  if ($storage->can('dbio_deploy_class')) {
    my $deploy_class = $storage->dbio_deploy_class;
    DBIO::Exception->throw("Cannot load deploy class $deploy_class: $@")
      unless eval "require $deploy_class; 1";
    return $deploy_class->new(schema => $self->schema);
  }

  $storage->_determine_driver if $storage->can('_determine_driver');

  my $driver_class = ref($storage);
  (my $deploy_class = $driver_class) =~ s{::Storage$}{::Deploy};

  DBIO::Exception->throw(
    "Cannot find native deploy class for storage $driver_class "
    . "(tried $deploy_class). Either set dbio_deploy_class on the storage "
    . "or use the SQL::Translator-based DeployMethod."
  ) unless eval "require $deploy_class; 1";

  return $deploy_class->new(schema => $self->schema);
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::DeployMethod::Native - Native DBIO driver deploy (no SQL::Translator needed)

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
