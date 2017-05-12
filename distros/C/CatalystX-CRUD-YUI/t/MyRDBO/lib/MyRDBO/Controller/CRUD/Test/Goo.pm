package MyRDBO::Controller::CRUD::Test::Goo;
use strict;
use base qw( MyRDBO::Base::Controller::RHTMLO );
use YUI::Test::Goo::Form;

__PACKAGE__->config(
    form_class              => 'YUI::Test::Goo::Form',
    init_form               => 'init_with_goo',
    init_object             => 'goo_from_form',
    default_template        => 'crud/test/goo/edit.tt',
    model_name              => 'CRUD::Test::Goo',
    primary_key             => ['id'],
    view_on_single_result   => 1,
    page_size               => 50,
);

1;
    
