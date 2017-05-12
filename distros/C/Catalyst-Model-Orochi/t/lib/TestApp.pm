package TestApp;
use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;
use Catalyst qw(-Debug);

extends 'Catalyst';

__PACKAGE__->config(
    name => 'TestApp',
    'Model::Orochi' => {
        injections => {
            foo => 'foo_001',
            bar => 'bar_001',
        },
        classes => [
            'TestApp::Component::Foo',
        ]
    }
);

__PACKAGE__->setup();

1;