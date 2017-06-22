package DBIx::Class::DeploymentHandler::VersionStorage::WithSchema::VersionResultSet;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Try::Tiny;

sub version_storage_is_installed {
    my $self = shift;
    try { $self->count; 1 } catch { undef }
}

1;
