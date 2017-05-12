package MyCRUD::Album::Form;
use strict;
use warnings;
use base qw( MyCRUD::Form );
use Carp;

sub init_with_album {
    my $self  = shift;
    my $album = shift;
    if ( !$album or !$album->isa('MyCRUD::Main::Album') ) {
        croak "need MyCRUD::Main::Album object";
    }
    return $self->init_with_object($album);
}

sub album_from_form {
    my $self  = shift;
    my $album = shift;
    if ( !$album or !$album->isa('MyCRUD::Main::Album') ) {
        croak "need MyCRUD::Main::Album object";
    }
    $self->object_from_form($album);
    return $album;
}

sub build_form {
    my $self = shift;
    $self->add_fields(
        title => {
            type      => 'text',
            size      => 30,
            required  => 1,
            label     => 'Title',
            maxlength => 128,
        },
        artist => {
            type      => 'text',
            size      => 30,
            required  => 1,
            label     => 'Artist',
            maxlength => 128,
        },
    );
    $self->SUPER::build_form(@_);
}

1;
