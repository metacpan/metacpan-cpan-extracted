package #
    TestApp::Model::CPI;
use base 'Catalyst::Model::CPI';

__PACKAGE__->config(
    gateway => {
        TestGateway1 => {
            user => 'a',
            key  => '123',
        },
        TestGateway2 => {
            user => 'b',
            key  => '456',
        }
    },
);

1;
