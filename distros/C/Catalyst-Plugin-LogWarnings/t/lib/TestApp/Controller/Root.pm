#!/usr/bin/perl
# Root.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package TestApp::Controller::Root;
use strict;
use warnings;
use base qw(Catalyst::Controller);

__PACKAGE__->config->{namespace} = q{}; 


sub default : Private {
    warn "default";
    return 1;
}

1;
