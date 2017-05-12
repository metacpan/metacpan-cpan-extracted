package MyApp::Model::Foo;
use base qw( MyApp::Base::RDBO );
__PACKAGE__->config(
    object_class => 'MyApp::Object',
    name         => My::Foo,
    load_with    => [qw( bar bars )]
);
use MRO::Compat;
use mro 'c3';

1;
