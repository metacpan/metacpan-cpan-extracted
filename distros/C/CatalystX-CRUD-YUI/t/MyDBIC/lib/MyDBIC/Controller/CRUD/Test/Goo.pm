package MyDBIC::Controller::CRUD::Test::Goo;
use strict;
use base qw( MyDBIC::Base::Controller::RHTMLO );
use MyDBIC::Form::Goo;
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config(
    form_class       => 'MyDBIC::Form::Goo',
    init_form        => 'init_with_goo',
    init_object      => 'goo_from_form',
    default_template => 'crud/test/goo/edit.tt',
    model_name       => 'DB',
    model_adapter    => 'MyDBIC::ModelAdapter',
    model_meta       => {
        dbic_schema    => 'Goo',
        resultset_opts => {}
    },
    primary_key           => ['id'],
    view_on_single_result => 1,
    page_size             => 50,

    #garden_class            => 'YUI',
);

1;
