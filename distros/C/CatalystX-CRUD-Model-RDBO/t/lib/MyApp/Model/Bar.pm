package MyApp::Model::Bar;
use base qw( MyApp::Base::RDBO );
__PACKAGE__->config(
    object_class => 'MyApp::Object',
    name         => 'My::Bar',
);
use MRO::Compat;
use mro 'c3';

1;
