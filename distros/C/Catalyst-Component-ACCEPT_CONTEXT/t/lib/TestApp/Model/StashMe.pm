#!/usr/bin/perl
# StashMe.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package TestApp::Model::StashMe;
use strict;
use warnings;
use base qw(Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model);

sub test {
    my $self = shift;
    $self->context->stash(stashme => $self);
}

sub foo {
    return "it worked";
}

1;
