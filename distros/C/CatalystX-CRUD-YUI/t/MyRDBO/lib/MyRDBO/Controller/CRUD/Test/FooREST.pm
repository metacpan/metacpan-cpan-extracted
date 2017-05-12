package MyRDBO::Controller::CRUD::Test::FooREST;
use strict;
use base qw(
    CatalystX::CRUD::REST
    MyRDBO::Base::Controller::RHTMLO
);
use MRO::Compat;
use mro 'c3';

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

sub chain_test : PathPart Chained('fetch') Args(0) {
    my ( $self, $c ) = @_;
    
    #Data::Dump::dump $self;
    
    $c->log->debug("chain test") if $c->debug;
    $c->res->status(200);
    $c->res->body('chain_test worked');
}

1;

