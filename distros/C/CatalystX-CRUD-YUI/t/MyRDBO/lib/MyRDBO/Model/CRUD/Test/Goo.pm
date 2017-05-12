package MyRDBO::Model::CRUD::Test::Goo;
use strict;
use base qw( MyRDBO::Base::Model::RDBO );
__PACKAGE__->config(
    name                    => 'YUI::Test::Goo',
    page_size               => 50,
);

1;

