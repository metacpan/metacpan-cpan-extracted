package MyRDBO::Controller::CRUD::Test::FooNoWrite;
use strict;
use base qw( MyRDBO::Base::Controller::RHTMLO );
use YUI::Test::Foo::Form;

__PACKAGE__->config(
    form_class            => 'YUI::Test::Foo::Form',
    init_form             => 'init_with_foo',
    init_object           => 'foo_from_form',
    default_template      => 'crud/test/foo/edit.tt',
    model_name            => 'CRUD::Test::Foo',
    primary_key           => ['id'],
    view_on_single_result => 1,
    page_size             => 50,
);

sub can_write {0}    # test 0.018 feature

1;

