package MyDBIC::Controller::CRUD::Test::FooGoo;
use strict;
use base qw( MyDBIC::Base::Controller::RHTMLO );
use MyDBIC::Form::FooGoo;
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config(
    form_class    => 'MyDBIC::Form::FooGoo',
    init_form     => 'init_with_foogoo',
    init_object   => 'foogoo_from_form',
    model_name    => 'DB',
    model_adapter => 'MyDBIC::ModelAdapter',
    model_meta    => {
        dbic_schema    => 'FooGoo',
        resultset_opts => {}
    },
    primary_key => [qw( foo_id goo_id )],
);

1;

