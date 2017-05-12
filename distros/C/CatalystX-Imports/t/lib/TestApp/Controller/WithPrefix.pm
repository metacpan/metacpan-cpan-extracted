package TestApp::Controller::WithPrefix;
use warnings;
use strict;

use base 'Catalyst::Controller';

use CatalystX::Imports Context => [qw( model )];

__PACKAGE__->config(
    component_prefix => {
        model => [qw(NotThere Prefix)],
    },
);

sub test_model_w_prefix: Global {
    my ($self, $c) = @_;
    $c->res->body( model('Foo')->foo );
}

1;
