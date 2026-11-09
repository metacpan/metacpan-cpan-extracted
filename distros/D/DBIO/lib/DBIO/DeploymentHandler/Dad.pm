package DBIO::DeploymentHandler::Dad;
# ABSTRACT: Parent class for DeploymentHandlers

use strict;
use warnings;

our $VERSION = '0.900004';

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
  $self->_assert_step_method('upgrade_single_step');
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
  $self->_assert_step_method('downgrade_single_step');
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

# The step loops are a template: nothing DBIO ships supplies the step methods
# (karr k214). Refuse before the transaction opens, naming the hook, instead of
# dying on an unresolved method call from inside it.
sub _assert_step_method {
  my ($self, $method) = @_;
  return if $self->can($method);
  DBIO::Exception->throw(
    ref($self) . " has no $method: the generic step loop of "
    . 'DBIO::DeploymentHandler::Dad needs a subclass that supplies it '
    . '(DBIO::DeploymentHandler replaces the loop with a native reconcile)'
  );
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

version 0.900004

=head1 DESCRIPTION

Base class of L<DBIO::DeploymentHandler>: the version-independent attributes
and the generic C<install>/C<upgrade>/C<downgrade>/C<backup> flow. The flow
methods call methods the subclass supplies -- C<txn_do>, C<deploy>,
C<add_database_version>, C<delete_database_version>,
C<version_storage_is_installed>, C<next_version_set>,
C<previous_version_set>, and for the step loops C<upgrade_single_step> /
C<downgrade_single_step>. L<DBIO::DeploymentHandler> overrides C<upgrade> and
C<downgrade> and does not use the step loops, and no deploy method shipped with
DBIO supplies the two step methods (they are not part of
L<DBIO::DeploymentHandler::HandlesDeploy>); the loops stay as a template for a
subclass that brings its own, and throw a L<DBIO::Exception> naming the missing
step method otherwise.

=head1 ATTRIBUTES

=head2 schema

The schema to deploy.

=head2 backup_directory

Directory handed to the storage's C<backup> by L</backup>. Optional.

=head2 to_version

Target version. Defaults to L</schema_version>, numified if it is a version
object; computed once and cached.

=head2 schema_version

The version the code declares. Defaults to C<< $schema->schema_version >>;
computed once and cached.

=head1 METHODS

=head2 new

  my $dh = $class->new({ schema => $schema, %attrs });

Takes a hashref or a flat list and copies every key into the object.

=head2 has_backup_directory

True if a L</backup_directory> was given.

=head2 install

  $dh->install;
  $dh->install({ version => 2 });

Throws if the version table already exists. Otherwise, inside C<txn_do>,
calls C<deploy> and records the version (default L</to_version>) with the
DDL C<deploy> returned.

=head2 upgrade

Generic step loop: inside C<txn_do>, for every version set
C<next_version_set> returns, calls C<upgrade_single_step> and records the
last version of the set. Carps when there was nothing to do. Throws a
L<DBIO::Exception> up front when the class has no C<upgrade_single_step>.
L<DBIO::DeploymentHandler> replaces this with a single-shot reconcile.

=head2 downgrade

Generic step loop: inside C<txn_do>, for every version set
C<previous_version_set> returns, calls C<downgrade_single_step> and deletes
the first version of the set. Carps when there was nothing to do. Throws a
L<DBIO::Exception> up front when the class has no C<downgrade_single_step>.
L<DBIO::DeploymentHandler> replaces this with a method that always throws.

=head2 backup

Calls C<< $schema->storage->backup($self->backup_directory) >>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
