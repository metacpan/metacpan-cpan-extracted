package RRDGraphTest003::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#

__PACKAGE__->config->{namespace} = '';

sub zero_byte_error :Local {
    my ($self, $c) = @_;
    
    RRDs::error("RRDgraph is 0 bytes");
    $c->stash->{'graph'} = [];

    $c->forward('RRDGraphTest003::View::RRDOnServe');
}

sub image_error :Local {
    my ($self, $c) = @_;

    RRDs::error("Unknown option");
    $c->stash->{'graph'} = [ ];

    $c->forward('RRDGraphTest003::View::RRDOnServe');
}


sub zero_byte_error_function :Local {
    my ($self, $c) = @_;

    RRDs::error("RRDgraph is 0 bytes");
    $c->stash->{'graph'} = [];

    $c->forward('RRDGraphTest003::View::RRDOnServeFunction');
}

sub image_error_function :Local {
    my ($self, $c) = @_;

    RRDs::error("Unknown option");
    $c->stash->{'graph'} = [ ];

    $c->forward('RRDGraphTest003::View::RRDOnServeFunction');
}


sub zero_byte_error_normal :Local {
    my ($self, $c) = @_;

    RRDs::error("RRDgraph is 0 bytes");
    $c->stash->{'graph'} = [];

    $c->forward('RRDGraphTest003::View::RRDNormal');
}

sub image_error_normal :Local {
    my ($self, $c) = @_;

    RRDs::error("Unknown option");
    $c->stash->{'graph'} = [ ];

    $c->forward('RRDGraphTest003::View::RRDNormal');
}


1;
