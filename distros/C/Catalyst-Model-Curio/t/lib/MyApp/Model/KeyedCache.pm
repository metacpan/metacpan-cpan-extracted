package MyApp::Model::KeyedCache;

use Moo;
use strictures 2;
use namespace::clean;

extends 'Catalyst::Model::Curio';

__PACKAGE__->config(
    class => 'MyApp::Service::MultiCache',
    key   => 'test_keyed',
);

1;
