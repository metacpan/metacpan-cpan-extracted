package MyCMS::Controller::CMS;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( CatalystX::CMS::Controller );

__PACKAGE__->config(
    cms => { use_editor => 0 },    # ignored. just to test config merge
);

sub page : Path Args {
    my ( $self, $c, @arg ) = @_;
    $c->stash( template => $self->cms_template_for( $c, @arg ) );
}

sub get : Chained('/') CaptureArgs(1) {
    my ( $self, $c, $thing ) = @_;
    $c->stash( thing => $thing );
}

sub linked : Chained('get') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(
        template => $self->cms_template_for( $c, $c->stash->{thing} ) );
}

1;
