package FlashTestApp::Controller::Root;
use strict;
use warnings;
use Data::Dumper;

use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

no warnings 'uninitialized';

sub default : Private {
    my ($self, $c) = @_;
    $c->session;
}
    
sub first : Global {
    my ( $self, $c ) = @_;
    if ( ! $c->flash->{is_set}) {
        $c->stash->{message} = "flash is not set";
        $c->flash->{is_set} = 1;
    }
}

sub second : Global {
    my ( $self, $c ) = @_;
    if ($c->flash->{is_set} == 1){
        $c->stash->{message} = "flash set first time";
        $c->flash->{is_set}++;
    }
}

sub third : Global {
    my ( $self, $c ) = @_;
    if ($c->flash->{is_set} == 2) {
        $c->stash->{message} = "flash set second time";
        $c->keep_flash("is_set");
    }
}

sub fourth : Global {
    my ( $self, $c ) = @_;
    if ($c->flash->{is_set} == 2) {
        $c->stash->{message} = "flash set 3rd time, same val as prev."
    }
}

sub fifth : Global {
    my ( $self, $c ) = @_;
    $c->forward('/first');
}

sub end : Private {
    my ($self, $c) = @_;
    $c->res->output($c->stash->{message});
}

1;
