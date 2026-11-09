package DBIO::DeploymentHandler::VersionStorage::Standard;
# ABSTRACT: Standard version storage implementation

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Base';

use DBIO::DeploymentHandler::VersionStorage::Standard::Component;


sub new {
  my ($class, @args) = @_;
  my $args = @args == 1 ? $args[0] : { @args };
  my $self = bless({}, $class);
  $self->{_version_storage_attrs} ||= {};
  %$self = (%$self, %$args);
  $self;
}


sub schema {
  my $self = shift;
  return $self->{schema} if exists $self->{schema};
  return $self->{_version_storage_attrs}{schema};
}


sub version_source {
  my $self = shift;
  return $self->{version_source} if exists $self->{version_source};
  return '__VERSION';
}


sub version_class {
  my $self = shift;
  return $self->{version_class} if exists $self->{version_class};
  return 'DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult';
}


sub version_rs {
  my $self = shift;
  return $self->schema->resultset($self->version_source);
}


sub version_storage_is_installed {
  my $self = shift;
  $self->version_rs->version_storage_is_installed;
}

sub database_version {
  my $self = shift;
  $self->version_rs->database_version;
}


sub add_database_version {
  my $self = shift;
  my $args = shift;

  $self->version_rs->create({
    version => $args->{version},
    ddl => $args->{ddl},
    upgrade_sql => $args->{upgrade_sql},
  });
}


sub delete_database_version {
  my $self = shift;
  my $args = shift;

  my $rs = $self->version_rs->search({ version => $args->{version} });
  $rs->delete if $rs->can('delete');
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::VersionStorage::Standard - Standard version storage implementation

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Stores the deployed versions as rows of a result source (by default
C<__VERSION>, the table
L<DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult>). The
schema must load L<DBIO::DeploymentHandler::VersionStorage::Standard::Component>
so that source exists. Implements
L<DBIO::DeploymentHandler::HandlesVersionStorage>.

=head1 ATTRIBUTES

=head2 schema

The schema whose version table is used.

=head2 version_source

Name of the version result source; defaults to C<__VERSION>.

=head2 version_class

Result class of the version table; defaults to
L<DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult>.

=head1 METHODS

=head2 new

  my $vs = DBIO::DeploymentHandler::VersionStorage::Standard->new({
    schema => $schema,
  });

Takes a hashref or a flat list and keeps every key.

=head2 version_rs

Returns the resultset of L</version_source>.

=head2 version_storage_is_installed

=head2 database_version

Delegate to the version resultset; see
L<DBIO::DeploymentHandler::VersionStorage::Standard::VersionResultSet>.

=head2 add_database_version

  $vs->add_database_version({ version => 2, ddl => $ddl, upgrade_sql => $sql });

Creates one version row from C<version>, C<ddl> and C<upgrade_sql>.

=head2 delete_database_version

  $vs->delete_database_version({ version => 2 });

Deletes the version row(s) for C<version>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
