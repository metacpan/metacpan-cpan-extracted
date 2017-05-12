package MyDBIC::Controller::CRUD::Test::Bar;
use strict;
use base qw( MyDBIC::Base::Controller::RHTMLO );
use MyDBIC::Form::Bar;
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config(
    form_class       => 'MyDBIC::Form::Bar',
    init_form        => 'init_with_bar',
    init_object      => 'bar_from_form',
    default_template => 'crud/test/bar/edit.tt',
    model_name       => 'DB',
    model_adapter    => 'MyDBIC::ModelAdapter',
    model_meta       => {
        dbic_schema    => 'Bar',
        resultset_opts => {}
    },
    primary_key           => ['id'],
    view_on_single_result => 1,
    page_size             => 50,

    #garden_class          => 'YUI',
);

1;

