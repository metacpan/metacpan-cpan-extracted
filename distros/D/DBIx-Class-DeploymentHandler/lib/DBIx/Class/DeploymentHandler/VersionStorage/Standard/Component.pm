package DBIx::Class::DeploymentHandler::VersionStorage::Standard::Component;
$DBIx::Class::DeploymentHandler::VersionStorage::Standard::Component::VERSION = '0.002234';
# ABSTRACT: Attach this component to your schema to ensure you stay up to date

use strict;
use warnings;

use Carp 'carp';
use DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResult;

sub attach_version_storage {
   $_[0]->register_class(
      __VERSION => 'DBIx::Class::DeploymentHandler::VersionStorage::Standard::VersionResult'
   );
}

sub connection  {
  my $self = shift;
  $self->next::method(@_);

  $self->attach_version_storage;

  my $args = $self->storage->_dbic_connect_attributes;

  unless ( $args->{ignore_version} || $ENV{DBIC_NO_VERSION_CHECK}) {
    my $versions = $self->resultset('__VERSION');

    if (!$versions->version_storage_is_installed) {
       carp "Your DB is currently unversioned. Please call upgrade on your schema to sync the DB.\n";
    } elsif ($versions->database_version ne $self->schema_version) {
      carp 'Versions out of sync. This is ' . $self->schema_version .
        ', your database contains version ' . $versions->database_version . ", please call upgrade on your Schema.\n";
    }
  }

  return $self;
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=head1 NAME

DBIx::Class::DeploymentHandler::VersionStorage::Standard::Component - Attach this component to your schema to ensure you stay up to date

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
