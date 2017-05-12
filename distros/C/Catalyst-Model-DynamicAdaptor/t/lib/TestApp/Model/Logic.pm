package TestApp::Model::Logic;

use strict;
use warnings;
use base qw/Catalyst::Model::DynamicAdaptor/;

__PACKAGE__->config({
    class => 'TestApp::Logic',
    config => { who => 'Jon' },
});

1;
