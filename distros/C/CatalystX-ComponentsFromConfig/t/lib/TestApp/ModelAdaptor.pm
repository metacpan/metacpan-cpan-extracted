package TestApp::ModelAdaptor;
use Moose;
extends 'CatalystX::ComponentsFromConfig::ModelAdaptor';

our @calls;

__PACKAGE__->config(
    args => {
        callback => sub { push @calls,$_[0] },
    },
);

__PACKAGE__->meta->make_immutable;

1;
