package OIDCExample::Controller::OpenIDConnect;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Plugin::OpenIDConnect::Controller::Root' }

__PACKAGE__->meta->make_immutable;

1;
