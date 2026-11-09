package DBIO::DeploymentHandler::DeployMethod::Native;
# ABSTRACT: Native DBIO driver deploy (no SQL::Translator needed)

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Exception;
use DBIO::Util ();
use DBIO::Deploy::Base ();

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
  return $self->_driver_deploy->upgrade(
    defined $args && exists $args->{allow_destructive}
      ? (allow_destructive => $args->{allow_destructive}) : ()
  );
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

  my $storage = DBIO::Deploy::Base::driver_storage($self->schema->storage);

  if ($storage->can('dbio_deploy_class')) {
    my $deploy_class = $storage->dbio_deploy_class;
    DBIO::Util::assert_class_name($deploy_class);
    DBIO::Exception->throw("Cannot load deploy class $deploy_class: $@")
      unless eval "require $deploy_class; 1";
    return $deploy_class->new(schema => $self->schema);
  }

  $storage->_determine_driver if $storage->can('_determine_driver');

  my $driver_class = ref($storage);
  (my $deploy_class = $driver_class) =~ s{::Storage$}{::Deploy};

  DBIO::Util::assert_class_name($deploy_class);
  DBIO::Exception->throw(
    "Cannot find native deploy class for storage $driver_class "
    . "(tried $deploy_class). Set dbio_deploy_class on the storage, or "
    . "provide a native Deploy class at $deploy_class."
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

version 0.900004

=head1 DESCRIPTION

The deploy method used by L<DBIO::DeploymentHandler>. It hands all DDL work to
the driver's native Deploy class, which introspects the live database and
reconciles it against the code in one shot, so no SQL::Translator and no
prepared per-version DDL files are needed. The Deploy class is taken from
the storage's C<dbio_deploy_class> if it has one; otherwise it is derived
from the (driver-resolved) storage class by replacing a trailing C<::Storage>
with C<::Deploy>. Throws if that class cannot be loaded.

Implements L<DBIO::DeploymentHandler::HandlesDeploy>.

=head1 ATTRIBUTES

=head2 schema

The schema to deploy.

=head1 METHODS

=head2 new

  my $dm = DBIO::DeploymentHandler::DeployMethod::Native->new({
    schema   => $schema,
    txn_wrap => 1,
  });

Takes a hashref or a flat list and keeps every key.

=head2 deploy

Runs the driver Deploy class's C<install>.

=head2 upgrade

Runs the driver Deploy class's C<upgrade> and returns its result (the diff).
The key C<allow_destructive> of the argument hash is handed on
(L<DBIO::Deploy::Base/apply>); without it a diff that drops or may alter
stored data does not run.

=head2 diff

Returns the driver Deploy class's C<diff> without applying it.

=head2 prepare_deploy

=head2 prepare_upgrade

=head2 prepare_resultsource_install

=head2 initialize

=head2 install_resultsource

No-ops. The native driver introspects and reconciles in one shot, so there is
nothing to prepare in advance; these exist for callers written against the
L<DBIx::Class::DeploymentHandler> contract.

=head2 txn_do

  my $rv = $dm->txn_do(sub { ... });

Runs the coderef inside a C<< $schema->txn_scope_guard >> and commits, or
runs it bare when C<txn_wrap> is false (which it is unless given;
L<DBIO::DeploymentHandler> passes 1 by default). Returns the coderef's
result.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
