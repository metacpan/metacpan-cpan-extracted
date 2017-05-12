package TestApp::Controller::File;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Controller::PSGI'; }

use Plack::App::File;

has 'app_file' => (
    is      => 'ro',
    default => sub {
        return Plack::App::File->new(
            file            => __FILE__,
            content_type    => 'text/plain',
        )->to_app;
    },
);

sub call {
    my ( $self, $env ) = @_;

    $self->app_file->( $env );
}

__PACKAGE__->meta->make_immutable;
