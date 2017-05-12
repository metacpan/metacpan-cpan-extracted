#!/usr/bin/perl
# Warnings.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
 
package TestApp::Controller::Warnings;
use base qw(Catalyst::Controller);
use strict;

sub index : Private {
    my ($self, $c, @args) = @_;
    $c->response->{body} = 'Hello, warnings!';
};

sub do_warn : Local {
    my ($self, $c, @args) = @_;
    warn 'Let this be a warning to you';
    $c->response->{body} = 'Hello, warnings!';
};


1;
