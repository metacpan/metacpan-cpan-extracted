package MyDBIC::Controller::CRUD::Test::Foo;
use strict;
use base qw( MyDBIC::Base::Controller::RHTMLO );
use MyDBIC::Form::Foo;
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config(
    form_class       => 'MyDBIC::Form::Foo',
    init_form        => 'init_with_foo',
    init_object      => 'foo_from_form',
    default_template => 'crud/test/foo/edit.tt',
    model_name       => 'DB',
    model_adapter    => 'MyDBIC::ModelAdapter',
    model_meta       => {
        dbic_schema    => 'Foo',
        resultset_opts => {}
    },
    primary_key           => ['id'],
    view_on_single_result => 1,
    page_size             => 50,

    #garden_class          => 'YUI',
);

1;

