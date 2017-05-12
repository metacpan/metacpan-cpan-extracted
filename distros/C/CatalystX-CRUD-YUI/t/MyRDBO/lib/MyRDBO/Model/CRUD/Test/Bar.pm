package MyRDBO::Model::CRUD::Test::Bar;
use strict;
use base qw( MyRDBO::Base::Model::RDBO );
__PACKAGE__->config(
    name                    => 'YUI::Test::Bar',
    page_size               => 50,
);

1;

