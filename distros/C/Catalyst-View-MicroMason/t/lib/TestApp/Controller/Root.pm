#!/usr/bin/perl
# Root.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package TestApp::Controller::Root;
use base qw(Catalyst::Controller);
__PACKAGE__->config->{namespace} = q{};

sub default : Private {
    my ($self, $c, @args) = @_;
    $c->stash->{arguments} = [@args];
    $c->forward('TestApp::View::MicroMason');    
}

sub foo : Global('foo') {
    my ($self, $c, @args) = @_;
    $c->stash->{template} = 'foo';
    $c->stash->{foo} = 'foo';
    $c->forward('TestApp::View::MicroMason');    
}

sub bar : Global('bar') {
    my ($self, $c, @args) = @_;
    $c->view->template('foo');
    $c->stash->{foo} = 'this is bar';
    $c->detach('TestApp::View::MicroMason');    
}

1;
