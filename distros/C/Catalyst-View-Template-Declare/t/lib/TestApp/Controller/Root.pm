#!perl

package TestApp::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');

sub action_name :Local {}

sub test_stash :Local {
    my ($self, $c, @args) = @_;
    $c->stash(world => "World");
    $c->stash(template => 'stash');
}

sub test_magic_stash :Local {
    my ($self, $c, @args) = @_;
    $c->stash(world => 'Terra');
    $c->stash(template => 'magic_stash');
}

sub test_sub :Local {
    my ($self, $c, @args) = @_;
    $c->stash(template => 'subtemplate');
}

sub test_includeother :Local {
    my ($self, $c, @args) = @_;
    $c->view('TD')->template('includeother');
}

sub myapp_methods :Local {
    my ($self, $c, @args) = @_;
    $c->view('TD')->template('methods');
}

sub end :Private {
    my ($self, $c, @args) = @_;
    $c->detach('View::TD');
}

1;

