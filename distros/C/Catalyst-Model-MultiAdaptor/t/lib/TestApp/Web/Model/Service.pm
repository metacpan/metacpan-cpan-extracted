package TestApp::Web::Model::Service;
use strict;
use warnings;
use base 'Catalyst::Model::MultiAdaptor';

__PACKAGE__->config(
    package   => 'TestApp::Service',
    lifecycle => 'Singleton',
    config    => {
        'SomeClass' => {
            uid => 1,
        },
        'AnotherClass' => {
            uid => 2,
        }
    },
    except => ['ExceptClass'],
);

1;
