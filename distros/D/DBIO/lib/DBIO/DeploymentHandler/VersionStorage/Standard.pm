package DBIO::DeploymentHandler::VersionStorage::Standard;
# ABSTRACT: Standard version storage implementation

use strict;
use warnings;

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

version 0.900002

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
