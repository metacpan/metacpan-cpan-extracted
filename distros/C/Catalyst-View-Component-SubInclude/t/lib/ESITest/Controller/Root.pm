package ESITest::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub index :Path Args(0) {}

sub base : Chained('/') PathPart('') CaptureArgs(0) {}

sub time_include : Chained('base') PathPart('time') Args(0) {
    my ( $self, $c ) = @_;
    my $params = $c->req->params;

    $c->stash->{current_time} = localtime();
    
    my $additional = '';
    for my $key (keys %$params) {
        $additional .= "| $key = $params->{$key} | "
    }

    $c->stash->{additional} = $additional;
    
}

sub capture : Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $arg ) = @_;
    $c->log->debug("Capture: $arg") if $c->debug;
    $c->stash->{additional} = "Capture Arg: $arg";
}

sub time_args : Chained('capture') PathPart('time') Args(0) {
    my ( $self, $c ) = @_;
    my $params = $c->req->params;

    $c->stash->{current_time} = localtime();

    my $additional = $c->stash->{additional};
    for my $key (keys %$params) {
        $additional .= "| $key = $params->{$key} | "
    }

    $c->stash->{additional} = $additional;

    $c->stash->{template} = 'time_include.tt';
}

sub time_args_with_args : Chained('capture') PathPart('time') Args(1) {
    my ( $self, $c, $arg ) = @_;
    my $params = $c->req->params;

    $c->stash->{current_time} = localtime();

    my $additional = $c->stash->{additional};
    for my $key (keys %$params) {
        $additional .= " | $key = $params->{$key} | "
    }

    $additional .= " Action Arg: $arg ";

    $c->stash->{additional} = $additional;

    $c->stash->{template} = 'time_include.tt';
}

sub time_args_without_capture : Chained('base') PathPart('time') Args(1) {
    my ( $self, $c, $arg ) = @_;
    my $params = $c->req->params;

    $c->stash->{current_time} = localtime();

    my $additional = '';
    for my $key (keys %$params) {
        $additional .= " | $key = $params->{$key} | "
    }

    $additional .= " Action Arg: $arg ";

    $c->stash->{additional} = $additional;

    $c->stash->{template} = 'time_include.tt';
}

sub time_args_no_chained : Path('time_args_no_chained') Args {
    my ($self, $c, @args) = @_;

    my $params = $c->req->params;

    $c->stash->{current_time} = localtime();

    my $additional = '';
    for my $key (keys %$params) {
        $additional .= " | $key = $params->{$key} | "
    }

    $additional .= " No Chained Args: " . join ', ', @args;

    $c->stash->{additional} = $additional;

    $c->stash->{template} = 'time_include.tt';
}

sub http_cpan : Chained('base') Args(0) {}

sub http_github : Chained('base') Args(0) {}

sub end : ActionClass('RenderView') {}

1;
