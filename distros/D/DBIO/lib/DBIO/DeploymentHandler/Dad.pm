package DBIO::DeploymentHandler::Dad;
# ABSTRACT: Parent class for DeploymentHandlers

use strict;
use warnings;

use base 'DBIO::Base';

use DBIO::Carp;
use DBIO::Exception;

use namespace::clean;

sub new {
  my ($class, @args) = @_;
  my $args = @args == 1 ? $args[0] : { @args };
  my $self = bless({}, $class);
  $self->{_dad_attrs} ||= {};
  %$self = (%$self, %$args);
  $self;
}

sub schema {
  my $self = shift;
  return $self->{schema} if exists $self->{schema};
  return $self->{_dad_attrs}{schema} if exists $self->{_dad_attrs}{schema};
  return undef;
}

sub backup_directory {
  my $self = shift;
  return $self->{backup_directory} if exists $self->{backup_directory};
  return $self->{_dad_attrs}{backup_directory} if exists $self->{_dad_attrs}{backup_directory};
  return undef;
}

sub has_backup_directory {
  my $self = shift;
  return exists $self->{backup_directory} || exists $self->{_dad_attrs}{backup_directory};
}

sub to_version {
  my $self = shift;
  return $self->{to_version} if exists $self->{to_version};
  my $version = $self->schema_version;
  $self->{to_version} = ref($version) ? $version->numify : $version;
  return $self->{to_version};
}

sub schema_version {
  my $self = shift;
  return $self->{schema_version} if exists $self->{schema_version};
  $self->{schema_version} = $self->schema->schema_version;
  return $self->{schema_version};
}

sub install {
  my $self = shift;

  my $version = (shift @_ || {})->{version} || $self->to_version;
  carp "installing version $version";
  DBIO::Exception->throw(
    'Install not possible as versions table already exists in database'
  ) if $self->version_storage_is_installed;

  $self->txn_do(sub {
     my $ddl = $self->deploy({ version=> $version });

     $self->add_database_version({
       version     => $version,
       ddl         => $ddl,
     });
  });
}

sub upgrade {
  carp 'upgrading';
  my $self = shift;
  my $ran_once = 0;
  $self->txn_do(sub {
     while ( my $version_list = $self->next_version_set ) {
       $ran_once = 1;
       my ($ddl, $upgrade_sql) = @{
         $self->upgrade_single_step({ version_set => $version_list })
       ||[]};

       $self->add_database_version({
         version     => $version_list->[-1],
         ddl         => $ddl,
         upgrade_sql => $upgrade_sql,
       });
     }
  });

  carp 'no need to run upgrade' unless $ran_once;
}

sub downgrade {
  carp 'downgrading';
  my $self = shift;
  my $ran_once = 0;
  $self->txn_do(sub {
     while ( my $version_list = $self->previous_version_set ) {
       $ran_once = 1;
       $self->downgrade_single_step({ version_set => $version_list });

       $self->delete_database_version({ version => $version_list->[0] });
     }
  });
  carp 'no version to run downgrade' unless $ran_once;
}

sub backup {
  my $self = shift;
  carp 'backing up';
  $self->schema->storage->backup($self->backup_directory)
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::Dad - Parent class for DeploymentHandlers

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
