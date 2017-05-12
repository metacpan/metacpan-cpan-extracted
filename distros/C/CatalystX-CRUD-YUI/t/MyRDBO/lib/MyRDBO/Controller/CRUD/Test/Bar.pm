package MyRDBO::Controller::CRUD::Test::Bar;
use strict;
use base qw( MyRDBO::Base::Controller::RHTMLO );
use YUI::Test::Bar::Form;

__PACKAGE__->config(
    form_class            => 'YUI::Test::Bar::Form',
    init_form             => 'init_with_bar',
    init_object           => 'bar_from_form',
    default_template      => 'crud/test/bar/edit.tt',
    model_name            => 'CRUD::Test::Bar',
    primary_key           => ['id'],
    view_on_single_result => 1,
    page_size             => 50,
);

1;

