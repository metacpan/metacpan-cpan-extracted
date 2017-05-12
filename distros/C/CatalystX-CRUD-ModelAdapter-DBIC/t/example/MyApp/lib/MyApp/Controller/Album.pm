package MyApp::Controller::Album;
use strict;
use warnings;
use base qw( CatalystX::CRUD::REST CatalystX::CRUD::Controller::RHTMLO );
use MyCRUD::Album::Form;
use Class::C3;

__PACKAGE__->config(
    form_class       => 'MyCRUD::Album::Form',
    init_form        => 'init_with_album',
    init_object      => 'album_from_form',
    default_template => 'album/edit.tt',          # you must create this!
    model_name       => 'Main',
    model_adapter    => 'MyCRUD::ModelAdapter',
    model_meta       => {
        dbic_schema    => 'Album',
        resultset_opts => {}
    },
    primary_key           => 'id',
    view_on_single_result => 1,
);

1;
