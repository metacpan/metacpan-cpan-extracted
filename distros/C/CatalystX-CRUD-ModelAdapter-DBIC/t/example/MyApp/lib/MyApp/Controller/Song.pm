package MyApp::Controller::Song;
use strict;
use warnings;
use base qw( CatalystX::CRUD::REST CatalystX::CRUD::Controller::RHTMLO );
use MyCRUD::Song::Form;
use Class::C3;

__PACKAGE__->config(
    form_class       => 'MyCRUD::Song::Form',
    init_form        => 'init_with_song',
    init_object      => 'song_from_form',
    default_template => 'song/edit.tt',           # you must create this!
    model_name       => 'Main',
    model_adapter    => 'MyCRUD::ModelAdapter',
    model_meta       => {
        dbic_schema    => 'Song',
        resultset_opts => {}
    },
    primary_key           => 'id',
    view_on_single_result => 1,
);

1;
