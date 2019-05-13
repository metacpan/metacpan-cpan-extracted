package MyApp::Model::SingleCache;

use Moo;
use strictures 2;
use namespace::clean;

extends 'Catalyst::Model::Curio';

__PACKAGE__->config(
    class => 'MyApp::Service::SingleCache',
);

1;
