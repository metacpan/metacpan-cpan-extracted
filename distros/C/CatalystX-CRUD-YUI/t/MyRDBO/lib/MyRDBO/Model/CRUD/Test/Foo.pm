package MyRDBO::Model::CRUD::Test::Foo;
use strict;
use base qw( MyRDBO::Base::Model::RDBO );
__PACKAGE__->config(
    name                    => 'YUI::Test::Foo',
    page_size               => 50,
);

1;

