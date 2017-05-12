package TestApp::Web::Model::Logic;
use strict;
use warnings;
use base 'Catalyst::Model::MultiAdaptor';

__PACKAGE__->config(
    package   => 'TestApp::Logic',
    lifecycle => 'Singleton',
    config    => {
        'SomeClass' => {
            id => 1,
        },
        'AnotherClass' => {
            id => 2,
        }
    }
);

1;
