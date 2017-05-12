package MyCRUD::Song::Form;
use strict;
use warnings;
use base qw( MyCRUD::Form );
use Carp;

sub init_with_song {
    my $self = shift;
    my $song = shift;
    if ( !$song or !$song->isa('MyCRUD::Main::Song') ) {
        croak "need MyCRUD::Main::Song object";
    }
    $self->init_with_object($song);
}

sub song_from_form {
    my $self = shift;
    my $song = shift;
    if ( !$song or !$song->isa('MyCRUD::Main::Song') ) {
        croak "need MyCRUD::Main::Song object";
    }
    $self->object_from_form($song);
    return $song;
}

sub build_form {
    my $self = shift;
    $self->add_fields(
        title => {
            type      => 'text',
            size      => 30,
            required  => 1,
            label     => 'Song Title',
            maxlength => 128,
        },
        artist => {
            type      => 'text',
            size      => 30,
            required  => 1,
            label     => 'Artist',
            maxlength => 128,
        },
        length => {
            type      => 'text',
            size      => 16,
            maxlength => 16,
            required  => 1,
            label     => 'Song Length'
        }
    );
    $self->SUPER::build_form(@_);
}

1;

