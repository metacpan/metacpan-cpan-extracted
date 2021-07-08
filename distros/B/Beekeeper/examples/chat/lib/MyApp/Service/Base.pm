package MyApp::Service::Base;

use strict;
use warnings;

use Beekeeper::Worker ':log';
use Beekeeper::Logger ':log_levels';
use base 'Beekeeper::Worker';

use Exporter 'import';

our @EXPORT = (
    @Beekeeper::Worker::EXPORT,
    @Beekeeper::Worker::EXPORT_OK,
    @Beekeeper::Logger::EXPORT_OK,
);


# Base class for all MyApp services

sub authorize_request {
    my ($self, $req) = @_;

    my $uuid = $self->get_authentication_data;

    # Require an user logged in
    return unless $uuid;

    # Create a per request stash 
    $self->{stash} = { uuid => $uuid };

    return BKPR_REQUEST_AUTHORIZED;
}

sub init_persistent_connections {
    my ($self) = @_;

    # $self->{dbh} = DBI->connect ...
    # $self->{cache} = Cache->new ...
}

sub dbh   { $_[0]->{dbh}   }
sub cache { $_[0]->{cache} }
sub stash { $_[0]->{stash} }
sub uuid  { $_[0]->{stash}->{uuid} }

1;
